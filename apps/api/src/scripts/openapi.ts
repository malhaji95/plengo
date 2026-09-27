/** Writes packages/contracts/openapi.json from the route schemas (spec §30.1). CI fails if it drifts. */
import { writeFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { buildApp, createFastify } from '../app.js';
import { createContainer } from '../container.js';
import { loadEnv } from '../env.js';
import { InlineQueue } from '../jobs/queue.js';

const env = loadEnv({
  NODE_ENV: 'test',
  APP_ENV: 'test',
  DATABASE_URL: 'postgres://unused@localhost/unused',
  BETTER_AUTH_SECRET: 'openapi-generation-secret-0123456789abcdef',
  BETTER_AUTH_URL: 'http://localhost:4000',
  APP_WEB_ORIGIN: 'http://localhost:3001',
  ADMIN_ORIGIN: 'http://localhost:3000',
  MOBILE_ACCESS_JWT_SECRET: 'openapi-generation-secret-0123456789abcdef',
  MOBILE_REFRESH_TOKEN_PEPPER: 'openapi-generation-secret-0123456789abcdef',
  STORAGE_DRIVER: 'memory',
});
const app = createFastify({ logger: false });
const c = createContainer(env, app.log, { jobs: new InlineQueue() });
await buildApp(app, c);
await app.ready();
const out = fileURLToPath(new URL('../../../../packages/contracts/openapi.json', import.meta.url));
writeFileSync(out, `${JSON.stringify(app.swagger(), null, 2)}\n`);
await app.close();
await c.pool.end();
console.log(`wrote ${out}`);
