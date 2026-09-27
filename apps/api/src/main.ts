import * as Sentry from '@sentry/node';
import { buildApp, createFastify, loggerOptions } from './app.js';
import { createContainer } from './container.js';
import { loadEnv } from './env.js';
import { PgBossQueue } from './jobs/queue.js';

const env = loadEnv();
if (env.SENTRY_DSN) Sentry.init({ dsn: env.SENTRY_DSN, environment: env.APP_ENV, tracesSampleRate: 0.1 });

const app = createFastify({ logger: loggerOptions(env.LOG_LEVEL, env.NODE_ENV === 'development') });
const queue = new PgBossQueue(env.DATABASE_URL, app.log);
const container = createContainer(env, app.log, { jobs: queue });
await buildApp(app, container);
await queue.start(container.jobHandlers, { workers: env.JOBS_ENABLED });

const shutdown = async (signal: string) => {
  app.log.info({ signal }, 'shutting down');
  await app.close();
  await queue.stop();
  await container.pool.end();
  process.exit(0);
};
process.on('SIGTERM', () => void shutdown('SIGTERM'));
process.on('SIGINT', () => void shutdown('SIGINT'));

await app.listen({ host: env.HOST, port: env.PORT });
