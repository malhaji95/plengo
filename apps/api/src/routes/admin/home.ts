import type { FastifyRequest } from 'fastify';
import type { FastifyPluginAsyncZod } from 'fastify-type-provider-zod';
import { z } from 'zod';
import {
  adminBannerListSchema,
  adminBannerSchema,
  adminCountdownListSchema,
  adminCountdownSchema,
  adminNotificationPageSchema,
  adminNotificationSchema,
  bannerReorderBodySchema,
  createBannerBodySchema,
  createCountdownBodySchema,
  createNotificationBodySchema,
  deletedSchema,
  notificationQuerySchema,
  reorderedSchema,
  successEnvelope,
  updateBannerBodySchema,
  updateCountdownBodySchema,
} from '@plengo/contracts';
import { authOf } from '../../authorization/guards.js';
import { ok } from '../../lib/app-error.js';
import type { Container } from '../../container.js';
import type { AdminActor } from '../../services/structure-service.js';

const idParams = z.object({ id: z.uuid() });
const actor = (request: FastifyRequest): AdminActor => ({ adminId: authOf(request).userId, ip: request.ip });

/** Banners, exam countdowns and notifications (spec §19, §20, §26.1). */
export function adminHomeRoutes(c: Container): FastifyPluginAsyncZod {
  return async (app) => {
    app.addHook('onRequest', c.guards.requireAdmin);
    const tags = ['admin-home'];

    app.get(
      '/banners',
      {
        schema: {
          operationId: 'adminListBanners',
          tags,
          response: { 200: successEnvelope(adminBannerListSchema) },
        },
      },
      async () => ok(await c.home.banners()),
    );
    app.post(
      '/banners',
      {
        schema: {
          operationId: 'adminCreateBanner',
          tags,
          body: createBannerBodySchema,
          response: { 200: successEnvelope(adminBannerSchema) },
        },
      },
      async (request) => ok(await c.home.createBanner(actor(request), request.body)),
    );
    app.patch(
      '/banners/:id',
      {
        schema: {
          operationId: 'adminUpdateBanner',
          tags,
          params: idParams,
          body: updateBannerBodySchema,
          response: { 200: successEnvelope(adminBannerSchema) },
        },
      },
      async (request) => ok(await c.home.updateBanner(actor(request), request.params.id, request.body)),
    );
    app.delete(
      '/banners/:id',
      {
        schema: {
          operationId: 'adminDeleteBanner',
          tags,
          params: idParams,
          response: { 200: successEnvelope(deletedSchema) },
        },
      },
      async (request) => ok(await c.home.removeBanner(actor(request), request.params.id)),
    );
    app.post(
      '/banners/reorder',
      {
        schema: {
          operationId: 'adminReorderBanners',
          tags,
          body: bannerReorderBodySchema,
          response: { 200: successEnvelope(reorderedSchema) },
        },
      },
      async (request) => ok(await c.home.reorderBanners(actor(request), request.body.ids)),
    );

    app.get(
      '/countdowns',
      {
        schema: {
          operationId: 'adminListCountdowns',
          tags,
          response: { 200: successEnvelope(adminCountdownListSchema) },
        },
      },
      async () => ok(await c.home.countdowns()),
    );
    app.post(
      '/countdowns',
      {
        schema: {
          operationId: 'adminCreateCountdown',
          tags,
          body: createCountdownBodySchema,
          response: { 200: successEnvelope(adminCountdownSchema) },
        },
      },
      async (request) => ok(await c.home.createCountdown(actor(request), request.body)),
    );
    app.patch(
      '/countdowns/:id',
      {
        schema: {
          operationId: 'adminUpdateCountdown',
          tags,
          params: idParams,
          body: updateCountdownBodySchema,
          response: { 200: successEnvelope(adminCountdownSchema) },
        },
      },
      async (request) => ok(await c.home.updateCountdown(actor(request), request.params.id, request.body)),
    );
    app.delete(
      '/countdowns/:id',
      {
        schema: {
          operationId: 'adminDeleteCountdown',
          tags,
          params: idParams,
          response: { 200: successEnvelope(deletedSchema) },
        },
      },
      async (request) => ok(await c.home.removeCountdown(actor(request), request.params.id)),
    );

    const ntags = ['admin-notifications'];
    app.get(
      '/notifications',
      {
        schema: {
          operationId: 'adminListNotifications',
          tags: ntags,
          querystring: notificationQuerySchema,
          response: { 200: successEnvelope(adminNotificationPageSchema) },
        },
      },
      async (request) => ok(await c.notifications.list(request.query.cursor, request.query.limit)),
    );
    app.post(
      '/notifications',
      {
        schema: {
          operationId: 'adminSendNotification',
          tags: ntags,
          body: createNotificationBodySchema,
          response: { 200: successEnvelope(adminNotificationSchema) },
        },
      },
      async (request) => ok(await c.notifications.create(actor(request), request.body)),
    );
  };
}
