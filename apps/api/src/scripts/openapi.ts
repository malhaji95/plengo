/** Writes packages/contracts/openapi.json from the route schemas (spec §30.1). CI fails if it drifts. */
import { writeFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { buildApp, createFastify } from '../app.js';
import { createContainer } from '../container.js';
import { loadEnv } from '../env.js';
import { InlineQueue } from '../jobs/queue.js';

type Doc = { paths?: unknown; components?: { schemas?: Record<string, unknown> } };

const REF = /#\/components\/schemas\/([A-Za-z0-9]+)"/g;

/**
 * The Zod provider emits an `<Name>Input` twin for every component. Collapse twins that only
 * differ by `additionalProperties`, drop components nothing references, and give surviving
 * input-only twins the plain name, so generated clients get one readable type per concept.
 */
function tidyComponents<T extends Doc>(input: T): T {
  let doc = input;
  const schemas = () => doc.components?.schemas ?? {};
  const shape = (value: unknown) =>
    JSON.stringify(value, (key, v: unknown) => (key === 'additionalProperties' ? undefined : v)).replace(
      /#\/components\/schemas\/([A-Za-z0-9]+?)(Input)?"/g,
      '#/components/schemas/$1"',
    );

  for (let changed = true; changed;) {
    changed = false;
    for (const name of Object.keys(schemas())) {
      const base = name.endsWith('Input') ? name.slice(0, -5) : null;
      if (!base || !(base in schemas()) || shape(schemas()[name]) !== shape(schemas()[base])) continue;
      delete schemas()[name];
      doc = JSON.parse(
        JSON.stringify(doc).replaceAll(`#/components/schemas/${name}"`, `#/components/schemas/${base}"`),
      );
      changed = true;
    }
  }

  const used = new Set<string>();
  const visit = (value: unknown) => {
    for (const [, name] of JSON.stringify(value).matchAll(REF)) {
      if (name && !used.has(name)) {
        used.add(name);
        visit(schemas()[name]);
      }
    }
  };
  visit(doc.paths);
  for (const name of Object.keys(schemas())) if (!used.has(name)) delete schemas()[name];

  for (const name of Object.keys(schemas())) {
    const base = name.endsWith('Input') ? name.slice(0, -5) : null;
    if (!base || base in schemas()) continue;
    schemas()[base] = schemas()[name];
    delete schemas()[name];
    doc = JSON.parse(
      JSON.stringify(doc).replaceAll(`#/components/schemas/${name}"`, `#/components/schemas/${base}"`),
    );
  }
  assertNoNameCollisions(schemas());
  const sorted = Object.fromEntries(Object.entries(schemas()).sort(([a], [b]) => a.localeCompare(b)));
  if (doc.components) doc.components.schemas = sorted;
  return doc;
}

/**
 * Client generators name an inline object after its property (`teacher` → `Teacher`). If that name
 * is also a component, the generated class silently loses fields, so register such objects instead.
 */
function assertNoNameCollisions(schemas: Record<string, unknown>) {
  const pascal = (s: string) => s.charAt(0).toUpperCase() + s.slice(1);
  const walk = (node: unknown, where: string) => {
    if (!node || typeof node !== 'object') return;
    const props = (node as { properties?: Record<string, { type?: unknown; properties?: unknown }> })
      .properties;
    for (const [name, child] of Object.entries(props ?? {})) {
      if (child.properties && pascal(name) in schemas) {
        throw new Error(
          `Inline object ${where}.${name} collides with component ${pascal(name)}; register it with an id`,
        );
      }
      walk(child, `${where}.${name}`);
    }
  };
  for (const [name, schema] of Object.entries(schemas)) walk(schema, name);
}

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
writeFileSync(out, `${JSON.stringify(tidyComponents(app.swagger() as Doc), null, 2)}\n`);
await app.close();
await c.pool.end();
console.log(`wrote ${out}`);
