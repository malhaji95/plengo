import { afterAll, beforeAll, describe, expect, it, vi } from 'vitest';
import { z } from 'zod';
import type { FastifyPluginAsyncZod } from 'fastify-type-provider-zod';
import { serializerCompiler, validatorCompiler } from 'fastify-type-provider-zod';
import { createFastify } from '../src/app.js';
import { AppError } from '../src/lib/app-error.js';
import { registerErrorHandling } from '../src/plugins/error-handler.js';
import { createTestApp, type TestContext } from './helpers.js';

const captured = vi.hoisted(() => [] as unknown[]);
vi.mock('@sentry/node', () => ({ captureException: (err: unknown) => captured.push(err) }));

describe('HSTS (§31)', () => {
  let staging: TestContext;
  let local: TestContext;
  beforeAll(async () => {
    staging = await createTestApp({ env: { APP_ENV: 'staging' } });
    local = await createTestApp();
  });
  afterAll(async () => {
    await staging.close();
    await local.close();
  });

  it('is sent by deployed environments on every response, errors included', async () => {
    for (const url of ['/api/v1/config', '/api/v1/does-not-exist']) {
      const res = await staging.app.inject({ method: 'GET', url });
      expect(res.headers['strict-transport-security']).toBe('max-age=31536000; includeSubDomains');
    }
  });

  it('is not sent locally, where the API runs over plain HTTP', async () => {
    const res = await local.app.inject({ method: 'GET', url: '/api/v1/config' });
    expect(res.headers['strict-transport-security']).toBeUndefined();
  });
});

describe('error reporting (§30.3, Sentry)', () => {
  const app = createFastify({ logger: { level: 'silent' } });
  beforeAll(async () => {
    app.setValidatorCompiler(validatorCompiler);
    app.setSerializerCompiler(serializerCompiler);
    registerErrorHandling(app);
    const routes: FastifyPluginAsyncZod = async (r) => {
      r.get('/boom', async () => {
        throw new Error('database password is hunter2');
      });
      r.get('/expected', async () => {
        throw new AppError('CONTENT_LOCKED');
      });
      r.get('/bad-response', { schema: { response: { 200: z.object({ n: z.number() }) } } }, async () => ({
        n: 'not a number' as unknown as number,
      }));
      r.post('/validated', { schema: { body: z.object({ n: z.number() }) } }, async () => ({ ok: true }));
    };
    await app.register(routes);
    await app.ready();
  });
  afterAll(() => app.close());

  it('reports unexpected failures and answers with the generic envelope, never internals', async () => {
    captured.length = 0;
    const res = await app.inject({ method: 'GET', url: '/boom' });
    expect(res.statusCode).toBe(500);
    expect(res.json()).toEqual({
      success: false,
      data: null,
      error: { code: 'SERVER_ERROR', message: expect.stringMatching(/[؀-ۿ]/) },
    });
    expect(res.body).not.toContain('hunter2');
    expect(res.body).not.toContain('at ');
    expect(captured).toHaveLength(1);
    expect((captured[0] as Error).message).toContain('hunter2');
  });

  it('reports a response that breaks its own schema (a server bug)', async () => {
    captured.length = 0;
    const res = await app.inject({ method: 'GET', url: '/bad-response' });
    expect(res.statusCode).toBe(500);
    expect(captured).toHaveLength(1);
  });

  it('does not report expected errors or client mistakes', async () => {
    captured.length = 0;
    const locked = await app.inject({ method: 'GET', url: '/expected' });
    expect(locked.statusCode).toBe(403);
    expect(locked.json().error.code).toBe('CONTENT_LOCKED');
    const invalid = await app.inject({ method: 'POST', url: '/validated', payload: { n: 'x' } });
    expect(invalid.statusCode).toBe(400);
    expect(invalid.json().error.code).toBe('VALIDATION_ERROR');
    const malformed = await app.inject({
      method: 'POST',
      url: '/validated',
      headers: { 'content-type': 'application/json' },
      payload: '{nope',
    });
    expect(malformed.statusCode).toBe(400);
    expect(captured).toHaveLength(0);
  });
});
