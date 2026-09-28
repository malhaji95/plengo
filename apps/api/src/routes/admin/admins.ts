import type { FastifyRequest } from 'fastify';
import type { FastifyPluginAsyncZod } from 'fastify-type-provider-zod';
import { z } from 'zod';
import {
  adminAccountListSchema,
  adminAccountSchema,
  attemptListQuerySchema,
  attemptSummaryPageSchema,
  createAdminBodySchema,
  revokedSchema,
  sessionListSchema,
  successEnvelope,
} from '@plengo/contracts';
import { authOf } from '../../authorization/guards.js';
import { ok } from '../../lib/app-error.js';
import type { Container } from '../../container.js';
import type { AdminActor } from '../../services/structure-service.js';

const idParams = z.object({ id: z.uuid() });
const actor = (request: FastifyRequest): AdminActor => ({ adminId: authOf(request).userId, ip: request.ip });

/** Admin accounts and the student sessions/attempts views (spec §11.3, §26.2). */
export function adminAccountRoutes(c: Container): FastifyPluginAsyncZod {
  return async (app) => {
    app.addHook('onRequest', c.guards.requireAdmin);

    const tags = ['admin-admins'];
    app.get(
      '/admins',
      {
        schema: {
          operationId: 'adminListAdmins',
          tags,
          response: { 200: successEnvelope(adminAccountListSchema) },
        },
      },
      async () => ok(await c.admins.list()),
    );
    app.post(
      '/admins',
      {
        schema: {
          operationId: 'adminCreateAdmin',
          tags,
          body: createAdminBodySchema,
          response: { 200: successEnvelope(adminAccountSchema) },
        },
      },
      async (request) => ok(await c.admins.create(actor(request), request.body)),
    );
    for (const [path, operationId, run] of [
      ['deactivate', 'adminDeactivateAdmin', c.admins.deactivate],
      ['reactivate', 'adminReactivateAdmin', c.admins.reactivate],
      ['reset-2fa', 'adminResetAdminTwoFactor', c.admins.resetTwoFactor],
    ] as const) {
      app.post(
        `/admins/:id/${path}`,
        {
          schema: {
            operationId,
            tags,
            params: idParams,
            response: { 200: successEnvelope(adminAccountSchema) },
          },
        },
        async (request) => ok(await run(actor(request), request.params.id)),
      );
    }

    const studentTags = ['admin-students'];
    app.get(
      '/students/:id/sessions',
      {
        schema: {
          operationId: 'adminListStudentSessions',
          tags: studentTags,
          params: idParams,
          response: { 200: successEnvelope(sessionListSchema) },
        },
      },
      async (request) => ok(await c.admins.studentSessions(request.params.id)),
    );
    app.delete(
      '/students/:id/sessions/:sessionId',
      {
        schema: {
          operationId: 'adminRevokeStudentSession',
          tags: studentTags,
          params: z.object({ id: z.uuid(), sessionId: z.uuid() }),
          response: { 200: successEnvelope(revokedSchema) },
        },
      },
      async (request) =>
        ok(await c.admins.revokeStudentSession(actor(request), request.params.id, request.params.sessionId)),
    );
    app.get(
      '/students/:id/attempts',
      {
        schema: {
          operationId: 'adminListStudentAttempts',
          tags: studentTags,
          params: idParams,
          querystring: attemptListQuerySchema,
          response: { 200: successEnvelope(attemptSummaryPageSchema) },
        },
      },
      async (request) => ok(await c.attempts.list(request.params.id, request.query)),
    );
  };
}
