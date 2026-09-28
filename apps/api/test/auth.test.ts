import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import {
  ADMIN_ORIGIN,
  PASSWORD,
  WEB_ORIGIN,
  body,
  cookieHeader,
  createTestApp,
  csrfHeaders,
  lastOtp,
  levelId,
  mobileLogin,
  registerVerifiedStudent,
  tokensFor,
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

const me = (accessToken: string) =>
  t.app.inject({ method: 'GET', url: '/api/v1/me', headers: { authorization: `Bearer ${accessToken}` } });
const refresh = (refreshToken: string) =>
  t.app.inject({ method: 'POST', url: '/api/v1/auth/mobile/refresh', payload: { refreshToken } });

describe('registration and email OTP', () => {
  it('registers, rejects login before verification, verifies by OTP, then logs in', async () => {
    const email = uniqueEmail();
    const reg = await t.app.inject({
      method: 'POST',
      url: '/api/v1/auth/register',
      payload: { fullName: 'سارة', email, password: PASSWORD, educationLevelId: await levelId(t) },
    });
    expect(reg.statusCode).toBe(200);
    expect(body(reg)).toEqual({ success: true, data: { verificationRequired: true }, error: null });

    const early = await mobileLogin(t, email);
    expect(early.statusCode).toBe(403);
    expect(body(early).error?.code).toBe('AUTH_EMAIL_NOT_VERIFIED');

    const wrong = await t.app.inject({
      method: 'POST',
      url: '/api/v1/auth/verify-email',
      payload: { email, otp: '000000' === lastOtp(t.email, email) ? '111111' : '000000' },
    });
    expect(body(wrong).error?.code).toBe('AUTH_OTP_INVALID');

    const verify = await t.app.inject({
      method: 'POST',
      url: '/api/v1/auth/verify-email',
      payload: { email, otp: lastOtp(t.email, email) },
    });
    expect(verify.statusCode).toBe(200);

    const login = await mobileLogin(t, email);
    expect(login.statusCode).toBe(200);
    const tokens = body<{ accessToken: string }>(login).data;
    const profile = await me(tokens.accessToken);
    expect(body(profile).data).toMatchObject({
      email,
      fullName: 'سارة',
      role: 'student',
      emailVerified: true,
    });
  });

  it('answers a duplicate email like a new one without touching the account', async () => {
    const email = await registerVerifiedStudent(t);
    const outboxBefore = t.email.outbox.length;
    const dup = await t.app.inject({
      method: 'POST',
      url: '/api/v1/auth/register',
      payload: {
        fullName: 'مكرر',
        email,
        password: 'another-password-9',
        educationLevelId: await levelId(t),
      },
    });
    expect(body(dup)).toEqual({ success: true, data: { verificationRequired: true }, error: null });
    expect(t.email.outbox.length).toBe(outboxBefore);
    expect((await mobileLogin(t, email)).statusCode).toBe(200);
    expect((await mobileLogin(t, email, 'another-password-9')).statusCode).toBe(401);
  });

  it('rejects an unknown education level', async () => {
    const badLevel = await t.app.inject({
      method: 'POST',
      url: '/api/v1/auth/register',
      payload: {
        fullName: 'x y',
        email: uniqueEmail(),
        password: PASSWORD,
        educationLevelId: '00000000-0000-4000-8000-000000000000',
      },
    });
    expect(body(badLevel).error?.code).toBe('VALIDATION_ERROR');
  });

  it('returns the §30.3 envelope with Arabic messages for validation errors', async () => {
    const res = await t.app.inject({
      method: 'POST',
      url: '/api/v1/auth/register',
      payload: { email: 'nope' },
    });
    expect(res.statusCode).toBe(400);
    const b = body(res);
    expect(b.success).toBe(false);
    expect(b.data).toBeNull();
    expect(b.error).toMatchObject({ code: 'VALIDATION_ERROR', message: 'البيانات المدخلة غير صحيحة' });
    expect(res.headers['x-request-id']).toBeTruthy();
  });
});

describe('mobile login', () => {
  it('rejects a wrong password and an unknown email identically', async () => {
    const email = await registerVerifiedStudent(t);
    const wrong = await mobileLogin(t, email, 'wrong-password-123');
    const unknown = await mobileLogin(t, uniqueEmail(), PASSWORD);
    for (const res of [wrong, unknown]) {
      expect(res.statusCode).toBe(401);
      expect(body(res).error?.code).toBe('AUTH_INVALID_CREDENTIALS');
    }
  });

  it('issues a 15-minute access token and a 30-day refresh token', async () => {
    const email = await registerVerifiedStudent(t);
    const res = await mobileLogin(t, email);
    const data = body<{ accessTokenExpiresAt: string; refreshTokenExpiresAt: string; refreshToken: string }>(
      res,
    ).data;
    const accessMs = Date.parse(data.accessTokenExpiresAt) - Date.now();
    const refreshMs = Date.parse(data.refreshTokenExpiresAt) - Date.now();
    expect(accessMs).toBeGreaterThan(14 * 60_000);
    expect(accessMs).toBeLessThanOrEqual(15 * 60_000);
    expect(refreshMs).toBeGreaterThan(29 * 86_400_000);
    expect(data.refreshToken.length).toBeGreaterThanOrEqual(43);
  });

  it('rate-limits login attempts per IP + email', async () => {
    const email = uniqueEmail();
    const codes: number[] = [];
    for (let i = 0; i < 11; i++) codes.push((await mobileLogin(t, email, 'x')).statusCode);
    expect(codes.slice(0, 10).every((c) => c === 401)).toBe(true);
    const limited = await mobileLogin(t, email, 'x');
    expect(limited.statusCode).toBe(429);
    expect(body(limited).error?.code).toBe('RATE_LIMITED');
  });
});

describe('refresh token rotation', () => {
  it('rotates on every refresh and the new pair works', async () => {
    const first = await tokensFor(t);
    const res = await refresh(first.refreshToken);
    expect(res.statusCode).toBe(200);
    const second = body<{ accessToken: string; refreshToken: string }>(res).data;
    expect(second.refreshToken).not.toBe(first.refreshToken);
    expect((await me(second.accessToken)).statusCode).toBe(200);
    expect((await refresh(second.refreshToken)).statusCode).toBe(200);
  });

  it('allows a duplicate refresh inside the 30 s grace window', async () => {
    const first = await tokensFor(t);
    const [a, b] = await Promise.all([refresh(first.refreshToken), refresh(first.refreshToken)]);
    expect(a.statusCode).toBe(200);
    expect(b.statusCode).toBe(200);
    // Both successors remain usable.
    expect((await refresh(body<{ refreshToken: string }>(a).data.refreshToken)).statusCode).toBe(200);
    expect((await refresh(body<{ refreshToken: string }>(b).data.refreshToken)).statusCode).toBe(200);
  });

  it('treats reuse after the grace window as replay and revokes the whole family', async () => {
    const first = await tokensFor(t);
    const rotated = body<{ accessToken: string; refreshToken: string }>(
      await refresh(first.refreshToken),
    ).data;

    t.clock.advance(31_000);
    try {
      const replay = await refresh(first.refreshToken);
      expect(replay.statusCode).toBe(401);
      expect(body(replay).error?.code).toBe('AUTH_SESSION_EXPIRED');

      // The legitimate successor and its access token die with the family.
      expect((await refresh(rotated.refreshToken)).statusCode).toBe(401);
      expect((await me(rotated.accessToken)).statusCode).toBe(401);
    } finally {
      t.clock.advance(-31_000);
    }
  });

  it('rejects unknown refresh tokens', async () => {
    const res = await refresh('x'.repeat(43));
    expect(res.statusCode).toBe(401);
  });

  it('expires access tokens after 15 minutes and refresh tokens after 30 days', async () => {
    const tokens = await tokensFor(t);
    t.clock.advance(16 * 60_000);
    try {
      const res = await me(tokens.accessToken);
      expect(res.statusCode).toBe(401);
      expect(body(res).error?.code).toBe('AUTH_SESSION_EXPIRED');
      expect((await refresh(tokens.refreshToken)).statusCode).toBe(200);
    } finally {
      t.clock.advance(-16 * 60_000);
    }

    const other = await tokensFor(t);
    t.clock.advance(31 * 86_400_000);
    try {
      expect((await refresh(other.refreshToken)).statusCode).toBe(401);
    } finally {
      t.clock.advance(-31 * 86_400_000);
    }
  });
});

describe('logout and session revocation', () => {
  it('logout revokes the refresh token and the access token', async () => {
    const tokens = await tokensFor(t);
    const out = await t.app.inject({
      method: 'POST',
      url: '/api/v1/auth/mobile/logout',
      payload: { refreshToken: tokens.refreshToken },
    });
    expect(out.statusCode).toBe(200);
    expect((await refresh(tokens.refreshToken)).statusCode).toBe(401);
    expect((await me(tokens.accessToken)).statusCode).toBe(401);
  });

  it('lists sessions and revokes another device', async () => {
    const phone = await tokensFor(t);
    const tablet = await tokensFor(t, phone.email);
    const list = await t.app.inject({
      method: 'GET',
      url: '/api/v1/sessions',
      headers: { authorization: `Bearer ${phone.accessToken}` },
    });
    const sessions = body<{ id: string; current: boolean; platform: string }[]>(list).data;
    expect(sessions).toHaveLength(2);
    const other = sessions.find((s) => !s.current)!;
    expect(other.platform).toBe('android');

    const del = await t.app.inject({
      method: 'DELETE',
      url: `/api/v1/sessions/${other.id}`,
      headers: { authorization: `Bearer ${phone.accessToken}` },
    });
    expect(del.statusCode).toBe(200);
    expect((await me(tablet.accessToken)).statusCode).toBe(401);
    expect((await refresh(tablet.refreshToken)).statusCode).toBe(401);
    expect((await me(phone.accessToken)).statusCode).toBe(200);
  });

  it("cannot revoke another user's session", async () => {
    const a = await tokensFor(t);
    const b = await tokensFor(t);
    const listB = await t.app.inject({
      method: 'GET',
      url: '/api/v1/sessions',
      headers: { authorization: `Bearer ${b.accessToken}` },
    });
    const bSession = body<{ id: string }[]>(listB).data[0]!;
    const del = await t.app.inject({
      method: 'DELETE',
      url: `/api/v1/sessions/${bSession.id}`,
      headers: { authorization: `Bearer ${a.accessToken}` },
    });
    expect(del.statusCode).toBe(404);
    expect((await me(b.accessToken)).statusCode).toBe(200);
  });
});

describe('password reset by OTP', () => {
  it('resets the password and ends existing sessions', async () => {
    const tokens = await tokensFor(t);
    const req = await t.app.inject({
      method: 'POST',
      url: '/api/v1/auth/forgot-password',
      payload: { email: tokens.email },
    });
    expect(req.statusCode).toBe(200);
    const reset = await t.app.inject({
      method: 'POST',
      url: '/api/v1/auth/reset-password',
      payload: {
        email: tokens.email,
        otp: lastOtp(t.email, tokens.email),
        newPassword: 'a-brand-new-password',
      },
    });
    expect(reset.statusCode).toBe(200);
    expect((await refresh(tokens.refreshToken)).statusCode).toBe(401);
    expect((await mobileLogin(t, tokens.email)).statusCode).toBe(401);
    expect((await mobileLogin(t, tokens.email, 'a-brand-new-password')).statusCode).toBe(200);
  });

  it('does not reveal whether an email exists', async () => {
    const res = await t.app.inject({
      method: 'POST',
      url: '/api/v1/auth/forgot-password',
      payload: { email: uniqueEmail('ghost') },
    });
    expect(body(res)).toEqual({ success: true, data: { sent: true }, error: null });
  });
});

describe('student web cookie sessions', () => {
  it('requires Origin + X-Requested-With on cookie login (CSRF)', async () => {
    const email = await registerVerifiedStudent(t);
    const noHeaders = await t.app.inject({
      method: 'POST',
      url: '/api/v1/auth/web/login',
      payload: { email, password: PASSWORD },
    });
    expect(noHeaders.statusCode).toBe(403);

    const evil = await t.app.inject({
      method: 'POST',
      url: '/api/v1/auth/web/login',
      headers: csrfHeaders('https://evil.example'),
      payload: { email, password: PASSWORD },
    });
    expect(evil.statusCode).toBe(403);
  });

  it('logs in with an httpOnly SameSite=Lax cookie that authenticates /me', async () => {
    const email = await registerVerifiedStudent(t);
    const login = await t.app.inject({
      method: 'POST',
      url: '/api/v1/auth/web/login',
      headers: csrfHeaders(WEB_ORIGIN),
      payload: { email, password: PASSWORD },
    });
    expect(login.statusCode).toBe(200);
    const session = login.cookies.find((c) => c.name.endsWith('session_token'))!;
    expect(session.httpOnly).toBe(true);
    expect(session.sameSite).toBe('Lax');
    const cookie = cookieHeader(login);

    const profile = await t.app.inject({ method: 'GET', url: '/api/v1/me', headers: { cookie } });
    expect(body(profile).data).toMatchObject({ email });

    const list = await t.app.inject({ method: 'GET', url: '/api/v1/sessions', headers: { cookie } });
    expect(body<{ platform: string }[]>(list).data[0]?.platform).toBe('web');

    // Mutations with a cookie but no CSRF headers are refused.
    const out = await t.app.inject({ method: 'POST', url: '/api/v1/auth/web/logout', headers: { cookie } });
    expect(out.statusCode).toBe(403);

    const out2 = await t.app.inject({
      method: 'POST',
      url: '/api/v1/auth/web/logout',
      headers: { cookie, ...csrfHeaders(WEB_ORIGIN) },
    });
    expect(out2.statusCode).toBe(200);
    const after = await t.app.inject({ method: 'GET', url: '/api/v1/me', headers: { cookie } });
    expect(after.statusCode).toBe(401);
  });

  it('refuses student web login from the admin form and vice versa', async () => {
    const email = await registerVerifiedStudent(t);
    const asAdmin = await t.app.inject({
      method: 'POST',
      url: '/api/v1/admin/auth/login',
      headers: csrfHeaders(ADMIN_ORIGIN),
      payload: { email, password: PASSWORD },
    });
    expect(body(asAdmin).error?.code).toBe('AUTH_INVALID_CREDENTIALS');
  });
});

describe('remote config and force update', () => {
  it('serves remote config without payment-related values', async () => {
    const res = await t.app.inject({ method: 'GET', url: '/api/v1/config' });
    const data = body<Record<string, unknown>>(res).data;
    expect(data).toHaveProperty('minSupportedVersion');
    expect(JSON.stringify(data)).not.toMatch(/coupon/i);
  });

  it('answers APP_UPDATE_REQUIRED below the minimum version, except on /config', async () => {
    await t.c.configService.setRemoteConfig(
      { minSupportedVersion: { android: '1.2.0', ios: '1.0.0', web: '1.0.0' } },
      null,
    );
    const headers = { 'x-app-platform': 'android', 'x-app-version': '1.1.9' };
    const blocked = await t.app.inject({ method: 'GET', url: '/api/v1/levels', headers });
    expect(blocked.statusCode).toBe(426);
    expect(body(blocked).error?.code).toBe('APP_UPDATE_REQUIRED');
    expect((await t.app.inject({ method: 'GET', url: '/api/v1/config', headers })).statusCode).toBe(200);
    const fine = await t.app.inject({
      method: 'GET',
      url: '/api/v1/levels',
      headers: { 'x-app-platform': 'android', 'x-app-version': '1.2.0' },
    });
    expect(fine.statusCode).toBe(200);
    await t.c.configService.setRemoteConfig({}, null);
  });

  it('lists the three education levels in order', async () => {
    const res = await t.app.inject({ method: 'GET', url: '/api/v1/levels' });
    expect(body<{ code: string }[]>(res).data.map((l) => l.code)).toEqual(['grade-9', 'grade-12', 'college']);
  });
});

describe('CORS', () => {
  it('lets the admin and web origins send every method the API uses, with credentials', async () => {
    for (const method of ['PATCH', 'PUT', 'DELETE']) {
      const res = await t.app.inject({
        method: 'OPTIONS',
        url: '/api/v1/admin/universities/00000000-0000-4000-8000-000000000000',
        headers: {
          origin: ADMIN_ORIGIN,
          'access-control-request-method': method,
          'access-control-request-headers': 'content-type,x-requested-with',
        },
      });
      expect(res.statusCode).toBe(204);
      expect(res.headers['access-control-allow-origin']).toBe(ADMIN_ORIGIN);
      expect(res.headers['access-control-allow-credentials']).toBe('true');
      expect(String(res.headers['access-control-allow-methods'])).toContain(method);
    }
  });

  it('does not allow unknown origins', async () => {
    const res = await t.app.inject({
      method: 'OPTIONS',
      url: '/api/v1/me',
      headers: { origin: 'https://evil.example', 'access-control-request-method': 'GET' },
    });
    expect(res.headers['access-control-allow-origin']).toBeUndefined();
  });
});

describe('health', () => {
  it('reports liveness and readiness', async () => {
    expect((await t.app.inject({ method: 'GET', url: '/health' })).json()).toEqual({ status: 'ok' });
    expect((await t.app.inject({ method: 'GET', url: '/ready' })).json()).toEqual({ status: 'ready' });
  });
});
