import type { FastifyRequest } from 'fastify';
import type { FastifyPluginAsyncZod } from 'fastify-type-provider-zod';
import { z } from 'zod';
import {
  academicYearListSchema,
  academicYearSchema,
  createAcademicYearBodySchema,
  createFacultyBodySchema,
  createLessonBodySchema,
  createSubjectBodySchema,
  createUniversityBodySchema,
  createUnitBodySchema,
  deletedSchema,
  educationLevelListSchema,
  educationLevelSchema,
  facultyIdQuerySchema,
  facultyListSchema,
  facultySchema,
  lessonListQuerySchema,
  lessonListSchema,
  lessonSchema,
  reorderBodySchema,
  reorderedSchema,
  subjectIdQuerySchema,
  subjectListQuerySchema,
  subjectListSchema,
  subjectSchema,
  successEnvelope,
  universityIdQuerySchema,
  universityListSchema,
  universitySchema,
  unitListSchema,
  unitSchema,
  updateAcademicYearBodySchema,
  updateFacultyBodySchema,
  updateLessonBodySchema,
  updateLevelBodySchema,
  updateSubjectBodySchema,
  updateUniversityBodySchema,
  updateUnitBodySchema,
} from '@plengo/contracts';
import { authOf } from '../../authorization/guards.js';
import { ok } from '../../lib/app-error.js';
import type { OrderedTableName } from '../../repositories/structure-repository.js';
import type { Container } from '../../container.js';
import type { AdminActor } from '../../services/structure-service.js';

const idParams = z.object({ id: z.uuid() });

function actor(request: FastifyRequest): AdminActor {
  return { adminId: authOf(request).userId, ip: request.ip };
}

/** Admin CRUD for levels, the college hierarchy, subjects, units and lessons (spec §26.2). */
export function adminStructureRoutes(c: Container): FastifyPluginAsyncZod {
  const tags = ['admin-structure'];
  const s = c.structure;

  return async (app) => {
    app.addHook('onRequest', c.guards.requireAdmin);

    /** DELETE /<path>/:id and PUT /<path>/reorder, shared by every ordered entity. */
    function deleteAndReorder(path: string, name: OrderedTableName, opName: string) {
      app.delete(
        `/${path}/:id`,
        {
          schema: {
            operationId: `adminDelete${opName}`,
            tags,
            params: idParams,
            response: { 200: successEnvelope(deletedSchema) },
          },
        },
        async (request) => ok(await s.remove(actor(request), name, request.params.id)),
      );
      app.put(
        `/${path}/reorder`,
        {
          schema: {
            operationId: `adminReorder${opName}s`,
            tags,
            body: reorderBodySchema,
            response: { 200: successEnvelope(reorderedSchema) },
          },
        },
        async (request) => ok(await s.reorder(actor(request), name, request.body.ids)),
      );
    }

    // ---- levels ----
    app.get(
      '/levels',
      {
        schema: {
          operationId: 'adminListLevels',
          tags,
          response: { 200: successEnvelope(educationLevelListSchema) },
        },
      },
      async () => ok(await c.catalog.levels()),
    );
    app.patch(
      '/levels/:id',
      {
        schema: {
          operationId: 'adminUpdateLevel',
          tags,
          params: idParams,
          body: updateLevelBodySchema,
          response: { 200: successEnvelope(educationLevelSchema) },
        },
      },
      async (request) => {
        const row = await s.updateLevel(actor(request), request.params.id, request.body);
        return ok({
          id: row.id,
          code: row.code,
          nameAr: row.nameAr,
          sortOrder: row.sortOrder,
          isCollege: row.code === 'college',
        });
      },
    );

    // ---- universities ----
    app.get(
      '/universities',
      {
        schema: {
          operationId: 'adminListUniversities',
          tags,
          response: { 200: successEnvelope(universityListSchema) },
        },
      },
      async () => ok(await s.listUniversities()),
    );
    app.post(
      '/universities',
      {
        schema: {
          operationId: 'adminCreateUniversity',
          tags,
          body: createUniversityBodySchema,
          response: { 200: successEnvelope(universitySchema) },
        },
      },
      async (request) => ok(await s.createUniversity(actor(request), request.body)),
    );
    app.patch(
      '/universities/:id',
      {
        schema: {
          operationId: 'adminUpdateUniversity',
          tags,
          params: idParams,
          body: updateUniversityBodySchema,
          response: { 200: successEnvelope(universitySchema) },
        },
      },
      async (request) => ok(await s.updateUniversity(actor(request), request.params.id, request.body)),
    );
    deleteAndReorder('universities', 'universities', 'University');

    // ---- faculties ----
    app.get(
      '/faculties',
      {
        schema: {
          operationId: 'adminListFaculties',
          tags,
          querystring: universityIdQuerySchema,
          response: { 200: successEnvelope(facultyListSchema) },
        },
      },
      async (request) => ok(await s.listFaculties(request.query.universityId)),
    );
    app.post(
      '/faculties',
      {
        schema: {
          operationId: 'adminCreateFaculty',
          tags,
          body: createFacultyBodySchema,
          response: { 200: successEnvelope(facultySchema) },
        },
      },
      async (request) => ok(await s.createFaculty(actor(request), request.body)),
    );
    app.patch(
      '/faculties/:id',
      {
        schema: {
          operationId: 'adminUpdateFaculty',
          tags,
          params: idParams,
          body: updateFacultyBodySchema,
          response: { 200: successEnvelope(facultySchema) },
        },
      },
      async (request) => ok(await s.updateFaculty(actor(request), request.params.id, request.body)),
    );
    deleteAndReorder('faculties', 'faculties', 'Faculty');

    // ---- academic years ----
    app.get(
      '/academic-years',
      {
        schema: {
          operationId: 'adminListAcademicYears',
          tags,
          querystring: facultyIdQuerySchema,
          response: { 200: successEnvelope(academicYearListSchema) },
        },
      },
      async (request) => ok(await s.listAcademicYears(request.query.facultyId)),
    );
    app.post(
      '/academic-years',
      {
        schema: {
          operationId: 'adminCreateAcademicYear',
          tags,
          body: createAcademicYearBodySchema,
          response: { 200: successEnvelope(academicYearSchema) },
        },
      },
      async (request) => ok(await s.createAcademicYear(actor(request), request.body)),
    );
    app.patch(
      '/academic-years/:id',
      {
        schema: {
          operationId: 'adminUpdateAcademicYear',
          tags,
          params: idParams,
          body: updateAcademicYearBodySchema,
          response: { 200: successEnvelope(academicYearSchema) },
        },
      },
      async (request) => ok(await s.updateAcademicYear(actor(request), request.params.id, request.body)),
    );
    deleteAndReorder('academic-years', 'academicYears', 'AcademicYear');

    // ---- subjects ----
    app.get(
      '/subjects',
      {
        schema: {
          operationId: 'adminListSubjects',
          tags,
          querystring: subjectListQuerySchema,
          response: { 200: successEnvelope(subjectListSchema) },
        },
      },
      async (request) => ok(await s.listSubjects(request.query)),
    );
    app.post(
      '/subjects',
      {
        schema: {
          operationId: 'adminCreateSubject',
          tags,
          body: createSubjectBodySchema,
          response: { 200: successEnvelope(subjectSchema) },
        },
      },
      async (request) => ok(await s.createSubject(actor(request), request.body)),
    );
    app.patch(
      '/subjects/:id',
      {
        schema: {
          operationId: 'adminUpdateSubject',
          tags,
          params: idParams,
          body: updateSubjectBodySchema,
          response: { 200: successEnvelope(subjectSchema) },
        },
      },
      async (request) => ok(await s.updateSubject(actor(request), request.params.id, request.body)),
    );
    deleteAndReorder('subjects', 'subjects', 'Subject');

    // ---- units ----
    app.get(
      '/units',
      {
        schema: {
          operationId: 'adminListUnits',
          tags,
          querystring: subjectIdQuerySchema,
          response: { 200: successEnvelope(unitListSchema) },
        },
      },
      async (request) => ok(await s.listUnits(request.query.subjectId)),
    );
    app.post(
      '/units',
      {
        schema: {
          operationId: 'adminCreateUnit',
          tags,
          body: createUnitBodySchema,
          response: { 200: successEnvelope(unitSchema) },
        },
      },
      async (request) => ok(await s.createUnit(actor(request), request.body)),
    );
    app.patch(
      '/units/:id',
      {
        schema: {
          operationId: 'adminUpdateUnit',
          tags,
          params: idParams,
          body: updateUnitBodySchema,
          response: { 200: successEnvelope(unitSchema) },
        },
      },
      async (request) => ok(await s.updateUnit(actor(request), request.params.id, request.body)),
    );
    deleteAndReorder('units', 'units', 'Unit');

    // ---- lessons ----
    app.get(
      '/lessons',
      {
        schema: {
          operationId: 'adminListLessons',
          tags,
          querystring: lessonListQuerySchema,
          response: { 200: successEnvelope(lessonListSchema) },
        },
      },
      async (request) => ok(await s.listLessons(request.query.subjectId, request.query.unitId)),
    );
    app.post(
      '/lessons',
      {
        schema: {
          operationId: 'adminCreateLesson',
          tags,
          body: createLessonBodySchema,
          response: { 200: successEnvelope(lessonSchema) },
        },
      },
      async (request) => ok(await s.createLesson(actor(request), request.body)),
    );
    app.patch(
      '/lessons/:id',
      {
        schema: {
          operationId: 'adminUpdateLesson',
          tags,
          params: idParams,
          body: updateLessonBodySchema,
          response: { 200: successEnvelope(lessonSchema) },
        },
      },
      async (request) => ok(await s.updateLesson(actor(request), request.params.id, request.body)),
    );
    deleteAndReorder('lessons', 'lessons', 'Lesson');
  };
}
