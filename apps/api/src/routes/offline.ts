import type { FastifyPluginAsyncZod } from 'fastify-type-provider-zod';
import {
  offlineCatalogSchema,
  offlineItemsPageSchema,
  offlineItemsQuerySchema,
  offlineLeasesSchema,
  offlineManifestSchema,
  offlineScopeCatalogSchema,
  offlineScopeQuerySchema,
  offlineSyncBodySchema,
  offlineSyncResultSchema,
  packKeyParamsSchema,
  refreshLeasesBodySchema,
  successEnvelope,
} from '@plengo/contracts';
import { authOf } from '../authorization/guards.js';
import { ok } from '../lib/app-error.js';
import type { Container } from '../container.js';

/** Offline packs (spec §22.10). */
export function offlineRoutes(c: Container): FastifyPluginAsyncZod {
  return async (app) => {
    app.addHook('onRequest', c.guards.requireUser);
    const tags = ['offline'];
    const user = (request: Parameters<typeof authOf>[0]) => authOf(request).userId;

    app.get(
      '/offline/catalog',
      {
        schema: {
          operationId: 'offlineCatalog',
          tags,
          response: { 200: successEnvelope(offlineCatalogSchema) },
        },
      },
      async (request) => ok(await c.offline.catalog(user(request))),
    );
    app.get(
      '/offline/catalog/scope',
      {
        schema: {
          operationId: 'offlineScopeCatalog',
          tags,
          querystring: offlineScopeQuerySchema,
          response: { 200: successEnvelope(offlineScopeCatalogSchema) },
        },
      },
      async (request) => ok(await c.offline.scopeCatalog(user(request), request.query)),
    );
    app.get(
      '/offline/packs/:packKey/manifest',
      {
        schema: {
          operationId: 'offlineManifest',
          tags,
          params: packKeyParamsSchema,
          response: { 200: successEnvelope(offlineManifestSchema) },
        },
      },
      async (request) => ok(await c.offline.manifest(user(request), request.params.packKey)),
    );
    app.get(
      '/offline/packs/:packKey/items',
      {
        schema: {
          operationId: 'offlineItems',
          tags,
          params: packKeyParamsSchema,
          querystring: offlineItemsQuerySchema,
          response: { 200: successEnvelope(offlineItemsPageSchema) },
        },
      },
      async (request) => ok(await c.offline.items(user(request), request.params.packKey, request.query)),
    );
    app.post(
      '/offline/licenses/refresh',
      {
        schema: {
          operationId: 'refreshOfflineLicenses',
          tags,
          body: refreshLeasesBodySchema,
          response: { 200: successEnvelope(offlineLeasesSchema) },
        },
      },
      async (request) => {
        const auth = authOf(request);
        return ok(await c.offline.refreshLeases(auth.userId, auth.sessionId, request.body.scopes));
      },
    );
    app.post(
      '/offline/sync',
      {
        schema: {
          operationId: 'syncOffline',
          tags,
          body: offlineSyncBodySchema,
          response: { 200: successEnvelope(offlineSyncResultSchema) },
        },
      },
      async (request) => ok(await c.offline.sync(user(request), request.body)),
    );
  };
}
