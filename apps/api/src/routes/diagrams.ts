import type { FastifyPluginAsyncZod } from 'fastify-type-provider-zod';
import { z } from 'zod';
import {
  checkDiagramBodySchema,
  diagramCheckResultSchema,
  diagramListQuerySchema,
  diagramPracticeBodySchema,
  diagramPracticeSchema,
  studentDiagramListSchema,
  successEnvelope,
} from '@plengo/contracts';
import { authOf } from '../authorization/guards.js';
import { ok } from '../lib/app-error.js';
import type { Container } from '../container.js';

const idParams = z.object({ id: z.uuid() });

/** «رسمات العلوم» for students (v3 §9). */
export function diagramRoutes(c: Container): FastifyPluginAsyncZod {
  return async (app) => {
    app.addHook('onRequest', c.guards.requireUser);
    const tags = ['diagrams'];

    app.get(
      '/diagrams',
      {
        schema: {
          operationId: 'listDiagrams',
          description:
            'Published diagrams of a scope: the subject (general content or a track), a unit with its lessons, or some lessons. Locked ones are listed with `locked: true` and no content.',
          tags,
          querystring: diagramListQuerySchema,
          response: { 200: successEnvelope(studentDiagramListSchema) },
        },
      },
      async (request) => ok(await c.diagrams.studentList(authOf(request).userId, request.query)),
    );
    app.post(
      '/diagrams/practice',
      {
        schema: {
          operationId: 'startDiagramPractice',
          description:
            'Up to `count` random accessible diagrams of the scope with signed image URLs and their labels (numbers and marker positions, never answers).',
          tags,
          body: diagramPracticeBodySchema,
          response: { 200: successEnvelope(diagramPracticeSchema) },
        },
      },
      async (request) => ok(await c.diagrams.practice(authOf(request).userId, request.body)),
    );
    app.post(
      '/diagrams/:id/check',
      {
        schema: {
          operationId: 'checkDiagram',
          description:
            'Grades the typed names (normalised like written answers) and reveals every label’s accepted answers. Counts toward the daily goal.',
          tags,
          params: idParams,
          body: checkDiagramBodySchema,
          response: { 200: successEnvelope(diagramCheckResultSchema) },
        },
      },
      async (request) => ok(await c.diagrams.check(authOf(request).userId, request.params.id, request.body)),
    );
  };
}
