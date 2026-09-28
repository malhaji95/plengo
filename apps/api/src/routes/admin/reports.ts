import type { FastifyRequest } from 'fastify';
import type { FastifyPluginAsyncZod } from 'fastify-type-provider-zod';
import { z } from 'zod';
import {
  adminReportPageSchema,
  adminReportQuerySchema,
  adminReportSchema,
  resolveReportBodySchema,
  successEnvelope,
} from '@plengo/contracts';
import { authOf } from '../../authorization/guards.js';
import { ok } from '../../lib/app-error.js';
import type { Container } from '../../container.js';
import type { AdminActor } from '../../services/structure-service.js';

const idParams = z.object({ id: z.uuid() });
const actor = (request: FastifyRequest): AdminActor => ({ adminId: authOf(request).userId, ip: request.ip });

/** Content report inbox (spec §21, §26.1). */
export function adminReportRoutes(c: Container): FastifyPluginAsyncZod {
  const tags = ['admin-reports'];
  return async (app) => {
    app.addHook('onRequest', c.guards.requireAdmin);

    app.get(
      '/reports',
      {
        schema: {
          operationId: 'adminListReports',
          tags,
          querystring: adminReportQuerySchema,
          response: { 200: successEnvelope(adminReportPageSchema) },
        },
      },
      async (request) => {
        const { cursor, limit, ...filter } = request.query;
        return ok(await c.reports.adminList(filter, cursor, limit));
      },
    );
    app.get(
      '/reports/:id',
      {
        schema: {
          operationId: 'adminGetReport',
          tags,
          params: idParams,
          response: { 200: successEnvelope(adminReportSchema) },
        },
      },
      async (request) => ok(await c.reports.adminGet(request.params.id)),
    );
    app.post(
      '/reports/:id/resolve',
      {
        schema: {
          operationId: 'adminResolveReport',
          tags,
          params: idParams,
          body: resolveReportBodySchema,
          response: { 200: successEnvelope(adminReportSchema) },
        },
      },
      async (request) => ok(await c.reports.resolve(actor(request), request.params.id, request.body)),
    );
  };
}
