import type { FastifyPluginAsyncZod } from 'fastify-type-provider-zod';
import { educationLevelListSchema, remoteConfigSchema, successEnvelope } from '@plengo/contracts';
import { ok } from '../lib/app-error.js';
import type { Container } from '../container.js';

export function configRoutes(c: Container): FastifyPluginAsyncZod {
  return async (app) => {
    app.get(
      '/config',
      {
        schema: {
          operationId: 'getConfig',
          tags: ['config'],
          response: { 200: successEnvelope(remoteConfigSchema) },
        },
      },
      async () => ok(await c.configService.getRemoteConfig()),
    );

    // Public: registration needs the level list before sign-in.
    app.get(
      '/levels',
      {
        schema: {
          operationId: 'listLevels',
          tags: ['structure'],
          response: { 200: successEnvelope(educationLevelListSchema) },
        },
      },
      async () => ok(await c.catalog.levels()),
    );
  };
}
