import type { FastifyPluginAsyncZod } from 'fastify-type-provider-zod';
import { z } from 'zod';
import {
  meSchema,
  updateProfileBodySchema,
  revokedSchema,
  sessionListSchema,
  successEnvelope,
} from '@plengo/contracts';
import { authOf } from '../authorization/guards.js';
import { AppError, ok } from '../lib/app-error.js';
import type { Container } from '../container.js';

export function meRoutes(c: Container): FastifyPluginAsyncZod {
  return async (app) => {
    app.addHook('preHandler', c.guards.requireUser);

    app.get(
      '/me',
      { schema: { operationId: 'getMe', tags: ['me'], response: { 200: successEnvelope(meSchema) } } },
      async (request) => {
        return ok(await c.catalog.me(authOf(request).userId));
      },
    );

    app.patch(
      '/me',
      {
        schema: {
          operationId: 'updateMe',
          tags: ['me'],
          body: updateProfileBodySchema,
          response: { 200: successEnvelope(meSchema) },
        },
      },
      async (request) => ok(await c.catalog.updateProfile(authOf(request).userId, request.body)),
    );

    app.get(
      '/sessions',
      {
        schema: {
          operationId: 'listSessions',
          tags: ['sessions'],
          response: { 200: successEnvelope(sessionListSchema) },
        },
      },
      async (request) => {
        const auth = authOf(request);
        const rows = await c.sessionsRepo.listActive(auth.userId);
        return ok(
          rows.map((s) => ({
            id: s.id,
            platform: s.platform,
            appVersion: s.appVersion,
            userAgent: s.userAgent,
            createdAt: s.createdAt.toISOString(),
            lastSeenAt: s.lastSeenAt.toISOString(),
            current: s.id === auth.sessionId,
          })),
        );
      },
    );

    app.delete(
      '/sessions/:id',
      {
        schema: {
          operationId: 'revokeSession',
          tags: ['sessions'],
          params: z.object({ id: z.uuid() }),
          response: { 200: successEnvelope(revokedSchema) },
        },
      },
      async (request) => {
        const auth = authOf(request);
        const own = await c.sessionsRepo.listActive(auth.userId);
        if (!own.some((s) => s.id === request.params.id)) throw new AppError('NOT_FOUND');
        await c.sessionsRepo.revoke(request.params.id);
        return ok({ revoked: true });
      },
    );
  };
}
