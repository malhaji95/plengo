import type { FastifyPluginAsyncZod } from 'fastify-type-provider-zod';
import type { FastifyRequest } from 'fastify';
import { z } from 'zod';
import {
  createUploadBodySchema,
  createUploadResponseSchema,
  mediaFileSchema,
  successEnvelope,
} from '@plengo/contracts';
import { authOf } from '../authorization/guards.js';
import { ok } from '../lib/app-error.js';
import type { Container } from '../container.js';
import type { UploadActor } from '../services/upload-service.js';

const HOUR = 60 * 60 * 1000;

function actorOf(request: FastifyRequest): UploadActor {
  const auth = authOf(request);
  return { role: auth.role, userId: auth.userId };
}

/**
 * Uploads for students (`/api/v1/uploads`) and admins (`/api/v1/admin/uploads`). The guard decides
 * who the actor is; the service decides which kinds and sizes that actor may upload.
 */
export function uploadRoutes(c: Container, audience: 'student' | 'admin'): FastifyPluginAsyncZod {
  const guard = audience === 'admin' ? c.guards.requireAdmin : c.guards.requireUser;
  const tags = [audience === 'admin' ? 'admin-uploads' : 'uploads'];
  const prefix = audience === 'admin' ? 'admin' : 'student';

  return async (app) => {
    app.addHook('onRequest', guard);

    app.post(
      '/uploads',
      {
        config: {
          rateLimit: {
            max: 60,
            timeWindow: HOUR,
            keyGenerator: (request: FastifyRequest) => request.auth?.userId ?? request.ip,
          },
        },
        schema: {
          operationId: `${prefix}CreateUpload`,
          tags,
          body: createUploadBodySchema,
          response: { 200: successEnvelope(createUploadResponseSchema) },
        },
      },
      async (request) => ok(await c.uploadService.create(actorOf(request), request.body)),
    );

    app.post(
      '/uploads/:id/complete',
      {
        schema: {
          operationId: `${prefix}CompleteUpload`,
          tags,
          params: z.object({ id: z.uuid() }),
          response: { 200: successEnvelope(mediaFileSchema) },
        },
      },
      async (request) => ok(await c.uploadService.complete(actorOf(request), request.params.id)),
    );

    app.get(
      '/uploads/:id',
      {
        schema: {
          operationId: `${prefix}GetUpload`,
          tags,
          params: z.object({ id: z.uuid() }),
          response: { 200: successEnvelope(mediaFileSchema) },
        },
      },
      async (request) => ok(await c.uploadService.get(actorOf(request), request.params.id)),
    );
  };
}
