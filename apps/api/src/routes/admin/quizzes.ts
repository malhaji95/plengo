import type { FastifyRequest } from 'fastify';
import type { FastifyPluginAsyncZod } from 'fastify-type-provider-zod';
import { z } from 'zod';
import {
  adminQuizDetailSchema,
  adminQuizListSchema,
  adminQuizQuerySchema,
  createQuizBodySchema,
  deletedSchema,
  questionFreeBodySchema,
  questionReorderBodySchema,
  questionStatusBodySchema,
  quizQuestionsBodySchema,
  reorderedSchema,
  successEnvelope,
  updateQuizBodySchema,
} from '@plengo/contracts';
import { authOf } from '../../authorization/guards.js';
import { ok } from '../../lib/app-error.js';
import type { Container } from '../../container.js';
import type { AdminActor } from '../../services/structure-service.js';

const idParams = z.object({ id: z.uuid() });
const actor = (request: FastifyRequest): AdminActor => ({ adminId: authOf(request).userId, ip: request.ip });

/** Curated quizzes (spec §15.1, §26.2). Status, free and reorder bodies match questions. */
export function adminQuizRoutes(c: Container): FastifyPluginAsyncZod {
  const tags = ['admin-quizzes'];
  const q = c.quizzes;

  return async (app) => {
    app.addHook('onRequest', c.guards.requireAdmin);

    app.get(
      '/quizzes',
      {
        schema: {
          operationId: 'adminListQuizzes',
          tags,
          querystring: adminQuizQuerySchema,
          response: { 200: successEnvelope(adminQuizListSchema) },
        },
      },
      async (request) => ok(await q.adminList(request.query)),
    );
    app.get(
      '/quizzes/:id',
      {
        schema: {
          operationId: 'adminGetQuiz',
          tags,
          params: idParams,
          response: { 200: successEnvelope(adminQuizDetailSchema) },
        },
      },
      async (request) => ok(await q.adminGet(request.params.id)),
    );
    app.post(
      '/quizzes',
      {
        schema: {
          operationId: 'adminCreateQuiz',
          tags,
          body: createQuizBodySchema,
          response: { 200: successEnvelope(adminQuizDetailSchema) },
        },
      },
      async (request) => ok(await q.create(actor(request), request.body)),
    );
    app.patch(
      '/quizzes/:id',
      {
        schema: {
          operationId: 'adminUpdateQuiz',
          tags,
          params: idParams,
          body: updateQuizBodySchema,
          response: { 200: successEnvelope(adminQuizDetailSchema) },
        },
      },
      async (request) => ok(await q.update(actor(request), request.params.id, request.body)),
    );
    app.put(
      '/quizzes/:id/questions',
      {
        schema: {
          operationId: 'adminSetQuizQuestions',
          tags,
          params: idParams,
          body: quizQuestionsBodySchema,
          response: { 200: successEnvelope(adminQuizDetailSchema) },
        },
      },
      async (request) =>
        ok(await q.setQuestions(actor(request), request.params.id, request.body.questionIds)),
    );
    app.post(
      '/quizzes/:id/status',
      {
        schema: {
          operationId: 'adminSetQuizStatus',
          tags,
          params: idParams,
          body: questionStatusBodySchema,
          response: { 200: successEnvelope(adminQuizDetailSchema) },
        },
      },
      async (request) => ok(await q.setStatus(actor(request), request.params.id, request.body.status)),
    );
    app.put(
      '/quizzes/:id/free',
      {
        schema: {
          operationId: 'adminSetQuizFree',
          tags,
          params: idParams,
          body: questionFreeBodySchema,
          response: { 200: successEnvelope(adminQuizDetailSchema) },
        },
      },
      async (request) => ok(await q.setFree(actor(request), request.params.id, request.body.mode)),
    );
    app.post(
      '/quizzes/reorder',
      {
        schema: {
          operationId: 'adminReorderQuizzes',
          tags,
          body: questionReorderBodySchema,
          response: { 200: successEnvelope(reorderedSchema) },
        },
      },
      async (request) => ok(await q.reorder(actor(request), request.body.ids)),
    );
    app.delete(
      '/quizzes/:id',
      {
        schema: {
          operationId: 'adminDeleteQuiz',
          tags,
          params: idParams,
          response: { 200: successEnvelope(deletedSchema) },
        },
      },
      async (request) => ok(await q.remove(actor(request), request.params.id)),
    );
  };
}
