import type { FastifyPluginAsyncZod } from 'fastify-type-provider-zod';
import { z } from 'zod';
import {
  followResultSchema,
  successEnvelope,
  teacherListSchema,
  teacherProfileSchema,
  trackDetailSchema,
} from '@plengo/contracts';
import { authOf } from '../authorization/guards.js';
import { ok } from '../lib/app-error.js';
import type { Container } from '../container.js';

const idParams = z.object({ id: z.uuid() });

/** Teachers, teacher tracks and following for students (spec §7, §30.2). */
export function teacherRoutes(c: Container): FastifyPluginAsyncZod {
  const tags = ['teachers'];
  const t = c.teachers;

  return async (app) => {
    app.addHook('onRequest', c.guards.requireUser);

    app.get(
      '/teachers',
      {
        schema: { operationId: 'listTeachers', tags, response: { 200: successEnvelope(teacherListSchema) } },
      },
      async (request) => ok(await t.listTeachers(authOf(request).userId)),
    );
    app.get(
      '/teachers/following',
      {
        schema: {
          operationId: 'listFollowedTeachers',
          tags,
          response: { 200: successEnvelope(teacherListSchema) },
        },
      },
      async (request) => ok(await t.followedTeachers(authOf(request).userId)),
    );
    app.get(
      '/teachers/:id',
      {
        schema: {
          operationId: 'getTeacherProfile',
          tags,
          params: idParams,
          response: { 200: successEnvelope(teacherProfileSchema) },
        },
      },
      async (request) => ok(await t.profile(authOf(request).userId, request.params.id)),
    );
    app.put(
      '/teachers/:id/follow',
      {
        schema: {
          operationId: 'followTeacher',
          tags,
          params: idParams,
          response: { 200: successEnvelope(followResultSchema) },
        },
      },
      async (request) => ok(await t.setFollowing(authOf(request).userId, request.params.id, true)),
    );
    app.delete(
      '/teachers/:id/follow',
      {
        schema: {
          operationId: 'unfollowTeacher',
          tags,
          params: idParams,
          response: { 200: successEnvelope(followResultSchema) },
        },
      },
      async (request) => ok(await t.setFollowing(authOf(request).userId, request.params.id, false)),
    );
    app.get(
      '/teacher-tracks/:id',
      {
        schema: {
          operationId: 'getTrack',
          tags,
          params: idParams,
          response: { 200: successEnvelope(trackDetailSchema) },
        },
      },
      async (request) => ok(await t.track(authOf(request).userId, request.params.id)),
    );
  };
}
