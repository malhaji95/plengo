import type { FastifyPluginAsyncZod } from 'fastify-type-provider-zod';
import { z } from 'zod';
import {
  goalSettingsSchema,
  homeSchema,
  notificationPageSchema,
  notificationPreferencesSchema,
  notificationQuerySchema,
  pushTokenBodySchema,
  readResultSchema,
  registeredSchema,
  revokedSchema,
  revokePushTokenBodySchema,
  successEnvelope,
  updateNotificationPreferencesSchema,
} from '@plengo/contracts';
import { authOf } from '../authorization/guards.js';
import { ok } from '../lib/app-error.js';
import type { Container } from '../container.js';

const idParams = z.object({ id: z.uuid() });

/** Home, daily goal, notifications inbox and push tokens (spec §19, §20). */
export function homeRoutes(c: Container): FastifyPluginAsyncZod {
  return async (app) => {
    app.addHook('onRequest', c.guards.requireUser);
    const user = (request: Parameters<typeof authOf>[0]) => authOf(request).userId;

    app.get(
      '/home',
      { schema: { operationId: 'getHome', tags: ['home'], response: { 200: successEnvelope(homeSchema) } } },
      async (request) => ok(await c.home.home(user(request))),
    );
    app.get(
      '/me/settings',
      {
        schema: {
          operationId: 'getGoalSettings',
          tags: ['home'],
          response: { 200: successEnvelope(goalSettingsSchema) },
        },
      },
      async (request) => ok(await c.home.goal(user(request))),
    );
    app.put(
      '/me/settings',
      {
        schema: {
          operationId: 'updateGoalSettings',
          tags: ['home'],
          body: goalSettingsSchema,
          response: { 200: successEnvelope(goalSettingsSchema) },
        },
      },
      async (request) => ok(await c.home.setGoal(user(request), request.body.dailyGoal)),
    );

    const tags = ['notifications'];
    app.get(
      '/notifications',
      {
        schema: {
          operationId: 'listNotifications',
          tags,
          querystring: notificationQuerySchema,
          response: { 200: successEnvelope(notificationPageSchema) },
        },
      },
      async (request) =>
        ok(await c.notifications.inbox(user(request), request.query.cursor, request.query.limit)),
    );
    app.post(
      '/notifications/:id/read',
      {
        schema: {
          operationId: 'markNotificationRead',
          tags,
          params: idParams,
          response: { 200: successEnvelope(readResultSchema) },
        },
      },
      async (request) => ok(await c.notifications.markRead(user(request), request.params.id)),
    );
    app.post(
      '/notifications/read-all',
      {
        schema: {
          operationId: 'markAllNotificationsRead',
          tags,
          response: { 200: successEnvelope(readResultSchema) },
        },
      },
      async (request) => ok(await c.notifications.markAllRead(user(request))),
    );
    app.get(
      '/notifications/preferences',
      {
        schema: {
          operationId: 'getNotificationPreferences',
          tags,
          response: { 200: successEnvelope(notificationPreferencesSchema) },
        },
      },
      async (request) => ok(await c.notifications.preferences(user(request))),
    );
    app.put(
      '/notifications/preferences',
      {
        schema: {
          operationId: 'updateNotificationPreferences',
          tags,
          body: updateNotificationPreferencesSchema,
          response: { 200: successEnvelope(notificationPreferencesSchema) },
        },
      },
      async (request) => ok(await c.notifications.setPreferences(user(request), request.body)),
    );
    app.post(
      '/push-tokens',
      {
        schema: {
          operationId: 'registerPushToken',
          tags,
          body: pushTokenBodySchema,
          response: { 200: successEnvelope(registeredSchema) },
        },
      },
      async (request) => ok(await c.notifications.registerToken(user(request), request.body)),
    );
    app.post(
      '/push-tokens/revoke',
      {
        schema: {
          operationId: 'revokePushToken',
          tags,
          body: revokePushTokenBodySchema,
          response: { 200: successEnvelope(revokedSchema) },
        },
      },
      async (request) => ok(await c.notifications.revokeToken(user(request), request.body.token)),
    );
  };
}
