import type { FastifyPluginAsyncZod } from 'fastify-type-provider-zod';
import { z } from 'zod';
import {
  academicYearListSchema,
  facultyIdQuerySchema,
  facultyListSchema,
  lessonSchema,
  subjectListQuerySchema,
  subjectListSchema,
  subjectOutlineSchema,
  successEnvelope,
  universityIdQuerySchema,
  universityListSchema,
  unitWithLessonsSchema,
} from '@plengo/contracts';
import { authOf } from '../authorization/guards.js';
import { ok } from '../lib/app-error.js';
import type { Container } from '../container.js';

const idParams = z.object({ id: z.uuid() });

/**
 * Public reference lists of the college hierarchy: registration offers them before sign-in, like
 * `/levels`. They carry names only, no content.
 */
export function collegeReferenceRoutes(c: Container): FastifyPluginAsyncZod {
  const tags = ['structure'];
  return async (app) => {
    app.get(
      '/universities',
      {
        schema: {
          operationId: 'listUniversities',
          tags,
          response: { 200: successEnvelope(universityListSchema) },
        },
      },
      async () => ok(await c.catalog.universities()),
    );

    app.get(
      '/faculties',
      {
        schema: {
          operationId: 'listFaculties',
          tags,
          querystring: universityIdQuerySchema,
          response: { 200: successEnvelope(facultyListSchema) },
        },
      },
      async (request) => ok(await c.catalog.faculties(request.query.universityId)),
    );

    app.get(
      '/academic-years',
      {
        schema: {
          operationId: 'listAcademicYears',
          tags,
          querystring: facultyIdQuerySchema,
          response: { 200: successEnvelope(academicYearListSchema) },
        },
      },
      async (request) => ok(await c.catalog.academicYears(request.query.facultyId)),
    );
  };
}

/**
 * Student browsing of subjects and their outline (spec §8.9, §30.2). Requires sign-in: content is
 * behind login (§24). Bounded reference lists are returned whole (ADR-011).
 */
export function catalogRoutes(c: Container): FastifyPluginAsyncZod {
  const tags = ['structure'];
  return async (app) => {
    app.addHook('onRequest', c.guards.requireUser);

    app.get(
      '/subjects',
      {
        schema: {
          operationId: 'listSubjects',
          tags,
          querystring: subjectListQuerySchema,
          response: { 200: successEnvelope(subjectListSchema) },
        },
      },
      async (request) => ok(await c.catalog.subjects(request.query)),
    );

    app.get(
      '/subjects/:id',
      {
        schema: {
          operationId: 'getSubjectOutline',
          tags,
          params: idParams,
          response: { 200: successEnvelope(subjectOutlineSchema) },
        },
      },
      async (request) => ok(await c.catalog.outline(authOf(request).userId, request.params.id)),
    );

    app.get(
      '/units/:id',
      {
        schema: {
          operationId: 'getUnit',
          tags,
          params: idParams,
          response: { 200: successEnvelope(unitWithLessonsSchema) },
        },
      },
      async (request) => ok(await c.catalog.unit(request.params.id)),
    );

    app.get(
      '/lessons/:id',
      {
        schema: {
          operationId: 'getLesson',
          tags,
          params: idParams,
          response: { 200: successEnvelope(lessonSchema) },
        },
      },
      async (request) => ok(await c.catalog.lesson(request.params.id)),
    );
  };
}
