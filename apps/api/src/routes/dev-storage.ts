import type { FastifyInstance, FastifyReply, FastifyRequest } from 'fastify';
import { AppError } from '../lib/app-error.js';
import type { MemoryStorage } from '../storage/memory-storage.js';
import type { BucketName } from '../storage/storage.js';

const MAX_BYTES = 11 * 1024 * 1024;

/**
 * Dev-only stand-in for R2 presigned URLs when STORAGE_DRIVER=memory (ADR-012). Registered only
 * outside production. Uploads and private reads need a signature issued by the MemoryStorage.
 */
export function devStorageRoutes(storage: MemoryStorage) {
  return async (app: FastifyInstance) => {
    app.addContentTypeParser('*', { parseAs: 'buffer', bodyLimit: MAX_BYTES }, (_req, body, done) =>
      done(null, body),
    );

    const target = (request: FastifyRequest) => {
      const { bucket, '*': key } = request.params as { bucket: string; '*': string };
      if (bucket !== 'public' && bucket !== 'private') throw new AppError('NOT_FOUND');
      if (!key || key.includes('..')) throw new AppError('NOT_FOUND');
      const q = request.query as Record<string, string | undefined>;
      return { bucket: bucket as BucketName, key, q };
    };

    app.put('/:bucket/*', { schema: { hide: true } }, async (request, reply: FastifyReply) => {
      const { bucket, key, q } = target(request);
      const len = Number(q.len);
      if (!storage.verify(bucket, key, 'PUT', len, Number(q.exp), q.sig ?? ''))
        throw new AppError('NOT_AUTHORIZED');
      const body = request.body as Buffer | undefined;
      if (!Buffer.isBuffer(body) || body.length !== len) {
        throw new AppError('VALIDATION_ERROR', { details: { reason: 'size_mismatch' } });
      }
      await storage.put(bucket, key, body, request.headers['content-type'] ?? 'application/octet-stream');
      return reply.status(200).send();
    });

    app.get('/:bucket/*', { schema: { hide: true } }, async (request, reply: FastifyReply) => {
      const { bucket, key, q } = target(request);
      if (bucket === 'private' && !storage.verify(bucket, key, 'GET', 0, Number(q.exp), q.sig ?? '')) {
        throw new AppError('NOT_AUTHORIZED');
      }
      const obj = await storage.getWithType(bucket, key);
      if (!obj) throw new AppError('NOT_FOUND');
      return reply
        .header('content-type', obj.contentType)
        .header('cache-control', 'no-store')
        .send(obj.bytes);
    });
  };
}
