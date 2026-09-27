import type { FastifyPluginAsyncZod } from 'fastify-type-provider-zod';
import { z } from 'zod';
import {
  checkAnswerBodySchema,
  checkResultSchema,
  questionListQuerySchema,
  studentQuestionPageSchema,
  studentQuestionSchema,
  successEnvelope,
} from '@plengo/contracts';
import { authOf } from '../authorization/guards.js';
import { ok } from '../lib/app-error.js';
import type { Container } from '../container.js';

const idParams = z.object({ id: z.uuid() });

/** Published questions for students (spec §14). Locked questions are metadata only (§8.6). */
export function questionRoutes(c: Container): FastifyPluginAsyncZod {
  const tags = ['questions'];

  return async (app) => {
    app.addHook('onRequest', c.guards.requireUser);

    app.get(
      '/questions',
      {
        schema: {
          operationId: 'listQuestions',
          tags,
          querystring: questionListQuerySchema,
          response: { 200: successEnvelope(studentQuestionPageSchema) },
        },
      },
      async (request) => ok(await c.questions.studentList(authOf(request).userId, request.query)),
    );
    app.get(
      '/questions/:id',
      {
        schema: {
          operationId: 'getQuestion',
          tags,
          params: idParams,
          response: { 200: successEnvelope(studentQuestionSchema) },
        },
      },
      async (request) => ok(await c.questions.studentGet(authOf(request).userId, request.params.id)),
    );
    app.post(
      '/questions/:id/check',
      {
        schema: {
          operationId: 'checkQuestionAnswer',
          tags,
          params: idParams,
          body: checkAnswerBodySchema,
          response: { 200: successEnvelope(checkResultSchema) },
        },
      },
      async (request) => ok(await c.questions.check(authOf(request).userId, request.params.id, request.body)),
    );
  };
}
