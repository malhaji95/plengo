import { sql } from 'drizzle-orm';
import type { FastifyPluginAsyncZod } from 'fastify-type-provider-zod';
import { z } from 'zod';
import type { Container } from '../container.js';

export function healthRoutes(c: Container): FastifyPluginAsyncZod {
  return async (app) => {
    app.get('/health', { schema: { hide: true } }, async () => ({ status: 'ok' }));

    app.get(
      '/ready',
      {
        schema: {
          hide: true,
          response: {
            200: z.object({ status: z.literal('ready') }),
            503: z.object({ status: z.literal('unavailable') }),
          },
        },
      },
      async (_request, reply) => {
        try {
          await c.db.execute(sql`select 1`);
        } catch {
          return reply.status(503).send({ status: 'unavailable' as const });
        }
        return { status: 'ready' as const };
      },
    );
  };
}
