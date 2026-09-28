import { readFileSync } from 'node:fs';
import { eq } from 'drizzle-orm';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { ERROR_MESSAGES } from '@plengo/contracts';
import { sessions, users } from '@plengo/db';
import { createFastify } from '../src/app.js';
import { WindowLimiter } from '../src/lib/window-limiter.js';
import {
  ADMIN_ORIGIN,
  PASSWORD,
  WEB_ORIGIN,
  body,
  cookieHeader,
  createTestApp,
  csrfHeaders,
  enrolledAdminSession,
  levelId,
  registerVerifiedStudent,
  uniqueEmail,
  type TestContext,
} from './helpers.js';

let t: TestContext;
beforeAll(async () => {
  t = await createTestApp();
});
afterAll(async () => {
  await t.close();
});

describe('§30.4 error codes', () => {
  it('match the spec table code for code and message', () => {
    const spec = readFileSync(new URL('../../../docs/spec.md', import.meta.url), 'utf8');
    const section = spec.slice(spec.indexOf('## 30.4 Error codes'), spec.indexOf('# 31. Security'));
    const rows = [...section.matchAll(/^\| ([A-Z_0-9]+) \| (.+?) \|$/gm)].map((m) => [
      m[1]!,
      m[2]!.replace(/\s*\(reserved\)$/, ''),
    ]);
    expect(rows.length).toBeGreaterThan(15);
    for (const [code, message] of rows) {
      expect(ERROR_MESSAGES[code as keyof typeof ERROR_MESSAGES], code).toBe(message);
    }
  });
});

describe('§30.1 conventions', () => {
  it('answers unknown routes with the NOT_FOUND envelope and a request id', async () => {
    const res = await t.app.inject({ method: 'GET', url: '/api/v1/nope' });
    expect(res.statusCode).toBe(404);
    expect(body(res)).toMatchObject({ success: false, data: null, error: { code: 'NOT_FOUND' } });
    expect(res.headers['x-request-id']).toBeTruthy();
  });

  it('echoes a well-formed client request id and replaces a malformed one', async () => {
    const good = await t.app.inject({
      method: 'GET',
      url: '/api/v1/config',
      headers: { 'x-request-id': 'client-req-12345' },
    });
    expect(good.headers['x-request-id']).toBe('client-req-12345');
    const bad = await t.app.inject({
      method: 'GET',
      url: '/api/v1/config',
      headers: { 'x-request-id': 'bad id!' },
    });
    expect(bad.headers['x-request-id']).not.toBe('bad id!');
  });
});

describe('§31 security', () => {
  it('trusts only the nearest proxy for the client IP', async () => {
    const app = createFastify({ logger: false, proxyHops: 1 });
    app.get('/ip', async (request) => ({ ip: request.ip }));
    await app.ready();
    const res = await app.inject({
      method: 'GET',
      url: '/ip',
      remoteAddress: '10.0.0.2',
      headers: { 'x-forwarded-for': '6.6.6.6, 203.0.113.9' },
    });
    // The spoofed leftmost entry is ignored; the address our proxy appended is used.
    expect(res.json()).toEqual({ ip: '203.0.113.9' });
    await app.close();
  });

  it('limits OTP emails to 5 per hour per address across register, resend and reset', async () => {
    const email = await registerVerifiedStudent(t);
    const send = (url: string) =>
      t.app.inject({ method: 'POST', url: `/api/v1/auth/${url}`, payload: { email } });
    // Registration already sent one code to this address this hour.
    const codes = [];
    for (const url of ['forgot-password', 'resend-otp', 'forgot-password', 'resend-otp', 'forgot-password']) {
      codes.push((await send(url)).statusCode);
    }
    expect(codes).toEqual([200, 200, 200, 200, 429]);
    // Another address is unaffected.
    const other = await registerVerifiedStudent(t);
    expect(
      (await t.app.inject({ method: 'POST', url: '/api/v1/auth/forgot-password', payload: { email: other } }))
        .statusCode,
    ).toBe(200);
  });

  it('WindowLimiter resets after its window', () => {
    let now = 0;
    const limiter = new WindowLimiter(2, 1000, () => now);
    expect([limiter.hit('a'), limiter.hit('a'), limiter.hit('a')]).toEqual([true, true, false]);
    expect(limiter.hit('b')).toBe(true);
    now = 1001;
    expect(limiter.hit('a')).toBe(true);
  });

  it('refuses cookie mutations without X-Requested-With or from another origin (CSRF)', async () => {
    const email = await registerVerifiedStudent(t);
    const login = await t.app.inject({
      method: 'POST',
      url: '/api/v1/auth/web/login',
      headers: csrfHeaders(WEB_ORIGIN),
      payload: { email, password: PASSWORD },
    });
    const cookie = cookieHeader(login);
    const patch = (headers: Record<string, string>) =>
      t.app.inject({
        method: 'PATCH',
        url: '/api/v1/me',
        headers: { cookie, ...headers },
        payload: { fullName: 'اسم جديد' },
      });
    expect((await patch({ origin: WEB_ORIGIN })).statusCode).toBe(403);
    expect((await patch(csrfHeaders('https://evil.example'))).statusCode).toBe(403);
    expect((await patch(csrfHeaders(WEB_ORIGIN))).statusCode).toBe(200);
  });

  it('cookie sessions keep a hashed IP, a user-agent summary and the app version, never the raw IP', async () => {
    const email = await registerVerifiedStudent(t);
    await t.app.inject({
      method: 'POST',
      url: '/api/v1/auth/web/login',
      remoteAddress: '198.51.100.7',
      headers: {
        ...csrfHeaders(WEB_ORIGIN),
        'user-agent': `Mozilla/5.0 ${'x'.repeat(400)}`,
        'x-app-version': '1.2.3',
      },
      payload: { email, password: PASSWORD },
    });
    const [u] = await t.c.db.select({ id: users.id }).from(users).where(eq(users.email, email));
    const [s] = await t.c.db.select().from(sessions).where(eq(sessions.userId, u!.id));
    expect(s!.ipAddress ?? '').toBe('');
    expect(s!.ipHash).toMatch(/^[0-9a-f]{16,}$/);
    expect(s!.ipHash).not.toContain('198.51.100.7');
    expect(s!.userAgent!.length).toBeLessThanOrEqual(200);
    expect(s!.appVersion).toBe('1.2.3');
    expect(s!.platform).toBe('web');
  });

  it('admin sessions also store no raw IP', async () => {
    const { email } = await enrolledAdminSession(t);
    const [u] = await t.c.db.select({ id: users.id }).from(users).where(eq(users.email, email));
    const rows = await t.c.db.select().from(sessions).where(eq(sessions.userId, u!.id));
    expect(rows.length).toBeGreaterThan(0);
    expect(rows.every((r) => !r.ipAddress)).toBe(true);
    void ADMIN_ORIGIN;
  });
});

describe('§11.1 registration', () => {
  it('requires an education level', async () => {
    const res = await t.app.inject({
      method: 'POST',
      url: '/api/v1/auth/register',
      payload: { fullName: 'سارة', email: uniqueEmail(), password: PASSWORD },
    });
    expect(body(res).error?.code).toBe('VALIDATION_ERROR');
    const ok = await t.app.inject({
      method: 'POST',
      url: '/api/v1/auth/register',
      payload: {
        fullName: 'سارة',
        email: uniqueEmail(),
        password: PASSWORD,
        educationLevelId: await levelId(t),
      },
    });
    expect(ok.statusCode).toBe(200);
  });
});
