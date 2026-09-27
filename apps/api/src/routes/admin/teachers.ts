import type { FastifyRequest } from 'fastify';
import type { FastifyPluginAsyncZod } from 'fastify-type-provider-zod';
import { z } from 'zod';
import {
  adminTeacherListSchema,
  adminTeacherSchema,
  adminTrackListSchema,
  adminTrackSchema,
  createTeacherBodySchema,
  createTrackBodySchema,
  deletedSchema,
  reorderBodySchema,
  reorderedSchema,
  successEnvelope,
  trackListQuerySchema,
  updateTeacherBodySchema,
  updateTrackBodySchema,
} from '@plengo/contracts';
import { authOf } from '../../authorization/guards.js';
import { ok } from '../../lib/app-error.js';
import type { Container } from '../../container.js';
import type { AdminActor } from '../../services/structure-service.js';

const idParams = z.object({ id: z.uuid() });
const actor = (request: FastifyRequest): AdminActor => ({ adminId: authOf(request).userId, ip: request.ip });

/** Admin management of teachers and their tracks (spec §7, §26.2). */
export function adminTeacherRoutes(c: Container): FastifyPluginAsyncZod {
  const tags = ['admin-teachers'];
  const t = c.teachers;

  return async (app) => {
    app.addHook('onRequest', c.guards.requireAdmin);

    app.get(
      '/teachers',
      {
        schema: {
          operationId: 'adminListTeachers',
          tags,
          response: { 200: successEnvelope(adminTeacherListSchema) },
        },
      },
      async () => ok(await t.adminListTeachers()),
    );
    app.get(
      '/teachers/:id',
      {
        schema: {
          operationId: 'adminGetTeacher',
          tags,
          params: idParams,
          response: { 200: successEnvelope(adminTeacherSchema) },
        },
      },
      async (request) => ok(await t.adminGetTeacher(request.params.id)),
    );
    app.post(
      '/teachers',
      {
        schema: {
          operationId: 'adminCreateTeacher',
          tags,
          body: createTeacherBodySchema,
          response: { 200: successEnvelope(adminTeacherSchema) },
        },
      },
      async (request) => ok(await t.createTeacher(actor(request), request.body)),
    );
    app.patch(
      '/teachers/:id',
      {
        schema: {
          operationId: 'adminUpdateTeacher',
          tags,
          params: idParams,
          body: updateTeacherBodySchema,
          response: { 200: successEnvelope(adminTeacherSchema) },
        },
      },
      async (request) => ok(await t.updateTeacher(actor(request), request.params.id, request.body)),
    );
    app.delete(
      '/teachers/:id',
      {
        schema: {
          operationId: 'adminDeleteTeacher',
          tags,
          params: idParams,
          response: { 200: successEnvelope(deletedSchema) },
        },
      },
      async (request) => ok(await c.structure.remove(actor(request), 'teachers', request.params.id)),
    );
    app.put(
      '/teachers/reorder',
      {
        schema: {
          operationId: 'adminReorderTeachers',
          tags,
          body: reorderBodySchema,
          response: { 200: successEnvelope(reorderedSchema) },
        },
      },
      async (request) => ok(await c.structure.reorder(actor(request), 'teachers', request.body.ids)),
    );

    app.get(
      '/teacher-tracks',
      {
        schema: {
          operationId: 'adminListTracks',
          tags,
          querystring: trackListQuerySchema,
          response: { 200: successEnvelope(adminTrackListSchema) },
        },
      },
      async (request) => ok(await t.adminListTracks(request.query)),
    );
    app.post(
      '/teacher-tracks',
      {
        schema: {
          operationId: 'adminCreateTrack',
          tags,
          body: createTrackBodySchema,
          response: { 200: successEnvelope(adminTrackSchema) },
        },
      },
      async (request) => ok(await t.createTrack(actor(request), request.body)),
    );
    app.patch(
      '/teacher-tracks/:id',
      {
        schema: {
          operationId: 'adminUpdateTrack',
          tags,
          params: idParams,
          body: updateTrackBodySchema,
          response: { 200: successEnvelope(adminTrackSchema) },
        },
      },
      async (request) => ok(await t.updateTrack(actor(request), request.params.id, request.body)),
    );
    app.delete(
      '/teacher-tracks/:id',
      {
        schema: {
          operationId: 'adminDeleteTrack',
          tags,
          params: idParams,
          response: { 200: successEnvelope(deletedSchema) },
        },
      },
      async (request) => ok(await c.structure.remove(actor(request), 'teacherTracks', request.params.id)),
    );
    app.put(
      '/teacher-tracks/reorder',
      {
        schema: {
          operationId: 'adminReorderTracks',
          tags,
          body: reorderBodySchema,
          response: { 200: successEnvelope(reorderedSchema) },
        },
      },
      async (request) => ok(await c.structure.reorder(actor(request), 'teacherTracks', request.body.ids)),
    );
  };
}
