import type { FastifyRequest } from 'fastify';
import type { FastifyPluginAsyncZod } from 'fastify-type-provider-zod';
import { z } from 'zod';
import {
  adminQuestionPageSchema,
  adminQuestionQuerySchema,
  adminQuestionSchema,
  createQuestionBodySchema,
  deletedSchema,
  normalizePreviewBodySchema,
  normalizePreviewSchema,
  questionFreeBodySchema,
  questionReorderBodySchema,
  questionStatusBodySchema,
  reorderedSchema,
  successEnvelope,
  updateQuestionBodySchema,
} from '@plengo/contracts';
import { authOf } from '../../authorization/guards.js';
import { ok } from '../../lib/app-error.js';
import type { Container } from '../../container.js';
import type { AdminActor } from '../../services/structure-service.js';

const idParams = z.object({ id: z.uuid() });
const actor = (request: FastifyRequest): AdminActor => ({ adminId: authOf(request).userId, ip: request.ip });

/** Question authoring (spec §14, §26.2). */
export function adminQuestionRoutes(c: Container): FastifyPluginAsyncZod {
  const tags = ['admin-questions'];
  const q = c.questions;

  return async (app) => {
    app.addHook('onRequest', c.guards.requireAdmin);

    app.get(
      '/questions',
      {
        schema: {
          operationId: 'adminListQuestions',
          tags,
          querystring: adminQuestionQuerySchema,
          response: { 200: successEnvelope(adminQuestionPageSchema) },
        },
      },
      async (request) => {
        const { cursor, limit, ...filter } = request.query;
        return ok(await q.adminList(filter, cursor, limit));
      },
    );
    app.get(
      '/questions/:id',
      {
        schema: {
          operationId: 'adminGetQuestion',
          tags,
          params: idParams,
          response: { 200: successEnvelope(adminQuestionSchema) },
        },
      },
      async (request) => ok(await q.adminGet(request.params.id)),
    );
    app.post(
      '/questions',
      {
        schema: {
          operationId: 'adminCreateQuestion',
          tags,
          body: createQuestionBodySchema,
          response: { 200: successEnvelope(adminQuestionSchema) },
        },
      },
      async (request) => ok(await q.create(actor(request), request.body)),
    );
    app.patch(
      '/questions/:id',
      {
        schema: {
          operationId: 'adminUpdateQuestion',
          tags,
          params: idParams,
          body: updateQuestionBodySchema,
          response: { 200: successEnvelope(adminQuestionSchema) },
        },
      },
      async (request) => ok(await q.update(actor(request), request.params.id, request.body)),
    );
    app.post(
      '/questions/:id/status',
      {
        schema: {
          operationId: 'adminSetQuestionStatus',
          tags,
          params: idParams,
          body: questionStatusBodySchema,
          response: { 200: successEnvelope(adminQuestionSchema) },
        },
      },
      async (request) => ok(await q.setStatus(actor(request), request.params.id, request.body.status)),
    );
    app.put(
      '/questions/:id/free',
      {
        schema: {
          operationId: 'adminSetQuestionFree',
          tags,
          params: idParams,
          body: questionFreeBodySchema,
          response: { 200: successEnvelope(adminQuestionSchema) },
        },
      },
      async (request) => ok(await q.setFree(actor(request), request.params.id, request.body.mode)),
    );
    app.post(
      '/questions/reorder',
      {
        schema: {
          operationId: 'adminReorderQuestions',
          tags,
          body: questionReorderBodySchema,
          response: { 200: successEnvelope(reorderedSchema) },
        },
      },
      async (request) => ok(await q.reorder(actor(request), request.body.ids)),
    );
    app.delete(
      '/questions/:id',
      {
        schema: {
          operationId: 'adminDeleteQuestion',
          tags,
          params: idParams,
          response: { 200: successEnvelope(deletedSchema) },
        },
      },
      async (request) => ok(await q.remove(actor(request), request.params.id)),
    );
    app.post(
      '/questions/normalize',
      {
        schema: {
          operationId: 'adminNormalizePreview',
          tags,
          body: normalizePreviewBodySchema,
          response: { 200: successEnvelope(normalizePreviewSchema) },
        },
      },
      async (request) => ok(q.normalizePreview(request.body.answers)),
    );
  };
}
