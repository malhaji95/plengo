import type { FastifyPluginAsyncZod } from 'fastify-type-provider-zod';
import { educationLevelListSchema, remoteConfigSchema, successEnvelope } from '@plengo/contracts';
import { asc } from 'drizzle-orm';
import { educationLevels } from '@plengo/db';
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

    // Registration needs the level list before sign-in; Phase 2 extends /levels with subjects.
    app.get(
      '/levels',
      {
        schema: {
          operationId: 'listLevels',
          tags: ['structure'],
          response: { 200: successEnvelope(educationLevelListSchema) },
        },
      },
      async () =>
        ok(
          await c.db
            .select({
              id: educationLevels.id,
              code: educationLevels.code,
              nameAr: educationLevels.nameAr,
              sortOrder: educationLevels.sortOrder,
            })
            .from(educationLevels)
            .orderBy(asc(educationLevels.sortOrder)),
        ),
    );
  };
}
