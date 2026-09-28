import type { FastifyRequest } from 'fastify';
import type { FastifyPluginAsyncZod } from 'fastify-type-provider-zod';
import { z } from 'zod';
import {
  adminSearchQuerySchema,
  adminSearchResultSchema,
  auditLogPageSchema,
  auditLogQuerySchema,
  questionAnalyticsDetailSchema,
  questionAnalyticsPageSchema,
  questionAnalyticsQuerySchema,
  successEnvelope,
} from '@plengo/contracts';
import { authOf } from '../../authorization/guards.js';
import { ok } from '../../lib/app-error.js';
import type { Container } from '../../container.js';
import type { AdminActor } from '../../services/structure-service.js';

const idParams = z.object({ id: z.uuid() });
const actor = (request: FastifyRequest): AdminActor => ({ adminId: authOf(request).userId, ip: request.ip });

/** Audit log, global search and question analytics (spec §26.2, §32). */
export function adminToolsRoutes(c: Container): FastifyPluginAsyncZod {
  return async (app) => {
    app.addHook('onRequest', c.guards.requireAdmin);

    app.get(
      '/audit-logs',
      {
        schema: {
          operationId: 'adminListAuditLogs',
          tags: ['admin-audit'],
          querystring: auditLogQuerySchema,
          response: { 200: successEnvelope(auditLogPageSchema) },
        },
      },
      async (request) => {
        const { cursor, limit, ...filter } = request.query;
        return ok(await c.adminTools.auditLog(filter, cursor, limit));
      },
    );

    app.get(
      '/search',
      {
        schema: {
          operationId: 'adminSearch',
          tags: ['admin-search'],
          querystring: adminSearchQuerySchema,
          response: { 200: successEnvelope(adminSearchResultSchema) },
        },
      },
      async (request) => ok(await c.adminTools.search(request.query.q)),
    );

    const tags = ['admin-analytics'];
    app.get(
      '/question-analytics',
      {
        schema: {
          operationId: 'adminQuestionAnalytics',
          tags,
          querystring: questionAnalyticsQuerySchema,
          response: { 200: successEnvelope(questionAnalyticsPageSchema) },
        },
      },
      async (request) => {
        const { cursor, limit, sort, ...filter } = request.query;
        return ok(await c.adminTools.analytics(filter, sort, cursor, limit));
      },
    );
    app.get(
      '/question-analytics/:id',
      {
        schema: {
          operationId: 'adminQuestionAnalyticsDetail',
          tags,
          params: idParams,
          response: { 200: successEnvelope(questionAnalyticsDetailSchema) },
        },
      },
      async (request) => ok(await c.adminTools.analyticsDetail(request.params.id)),
    );
    app.post(
      '/question-analytics/:id/clear-flag',
      {
        schema: {
          operationId: 'adminClearQuestionFlag',
          tags,
          params: idParams,
          response: { 200: successEnvelope(questionAnalyticsDetailSchema) },
        },
      },
      async (request) => ok(await c.adminTools.clearFlag(actor(request), request.params.id)),
    );
  };
}
