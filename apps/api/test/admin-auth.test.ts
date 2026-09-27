import { eq } from 'drizzle-orm';
import { generateSync } from 'otplib';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { auditLogs, sessions } from '@plengo/db';
import {
  ADMIN_ORIGIN,
  PASSWORD,
  body,
  cookieHeader,
  createTestApp,
  csrfHeaders,
  makeAdmin,
  mobileLogin,
  tokensFor,
  type TestContext,
} from './helpers.js';

let t: TestContext;
beforeAll(async () => {
  t = await createTestApp();
});
afterAll(async () => {
  await t.close();
});

const h = csrfHeaders(ADMIN_ORIGIN);

async function adminLogin(email: string, password = PASSWORD) {
  return t.app.inject({
    method: 'POST',
    url: '/api/v1/admin/auth/login',
    headers: h,
    payload: { email, password },
  });
}

const adminMe = (cookie: string) =>
  t.app.inject({ method: 'GET', url: '/api/v1/admin/me', headers: { cookie } });

function secretFromUri(uri: string): string {
  return new URL(uri).searchParams.get('secret')!;
}

/** Walks a fresh admin through first login + TOTP enrollment; returns the cookie and secret. */
async function enrolledAdmin() {
  const email = await makeAdmin(t);
  const login = await adminLogin(email);
  expect(body(login).data).toEqual({ next: 'enroll' });
  let cookie = cookieHeader(login);

  const enroll = await t.app.inject({
    method: 'POST',
    url: '/api/v1/admin/auth/2fa/enroll',
    headers: { cookie, ...h },
    payload: { password: PASSWORD },
  });
  expect(enroll.statusCode).toBe(200);
  const { totpUri, backupCodes } = body<{ totpUri: string; backupCodes: string[] }>(enroll).data;
  expect(backupCodes.length).toBeGreaterThanOrEqual(8);
  const secret = secretFromUri(totpUri);

  const confirm = await t.app.inject({
    method: 'POST',
    url: '/api/v1/admin/auth/2fa/confirm',
    headers: { cookie, ...h },
    payload: { code: generateSync({ secret }) },
  });
  expect(confirm.statusCode).toBe(200);
  cookie = cookieHeader(confirm, cookie);
  return { email, cookie, secret, backupCodes };
}

describe('admin 2FA', () => {
  it('blocks admin endpoints until TOTP enrollment is complete', async () => {
    const email = await makeAdmin(t);
    const login = await adminLogin(email);
    const cookie = cookieHeader(login);
    const res = await adminMe(cookie);
    expect(res.statusCode).toBe(403);
    expect(body(res).error?.code).toBe('AUTH_2FA_REQUIRED');
  });

  it('enrolls, then admin endpoints work and the enrollment is audited', async () => {
    const { cookie, email } = await enrolledAdmin();
    const res = await adminMe(cookie);
    expect(res.statusCode).toBe(200);
    expect(body(res).data).toMatchObject({ email, role: 'admin' });
    const me = body<{ id: string }>(res).data;
    const logs = await t.c.db.select().from(auditLogs).where(eq(auditLogs.actorAdminId, me.id));
    expect(logs.map((l) => l.action)).toContain('admin.2fa_enrolled');
  });

  it('requires a TOTP code on every later login', async () => {
    const { email, secret } = await enrolledAdmin();
    const login = await adminLogin(email);
    expect(body(login).data).toEqual({ next: 'totp' });
    let cookie = cookieHeader(login);
    expect((await adminMe(cookie)).statusCode).toBe(401);

    const bad = await t.app.inject({
      method: 'POST',
      url: '/api/v1/admin/auth/2fa/verify',
      headers: { cookie, ...h },
      payload: { code: '000000' },
    });
    expect(body(bad).error?.code).toBe('AUTH_OTP_INVALID');

    const good = await t.app.inject({
      method: 'POST',
      url: '/api/v1/admin/auth/2fa/verify',
      headers: { cookie, ...h },
      payload: { code: generateSync({ secret }) },
    });
    expect(good.statusCode).toBe(200);
    cookie = cookieHeader(good, cookie);
    expect((await adminMe(cookie)).statusCode).toBe(200);
  });

  it('accepts a recovery code instead of TOTP', async () => {
    const { email, backupCodes } = await enrolledAdmin();
    const login = await adminLogin(email);
    let cookie = cookieHeader(login);
    const res = await t.app.inject({
      method: 'POST',
      url: '/api/v1/admin/auth/2fa/backup',
      headers: { cookie, ...h },
      payload: { code: backupCodes[0] },
    });
    expect(res.statusCode).toBe(200);
    cookie = cookieHeader(res, cookie);
    expect((await adminMe(cookie)).statusCode).toBe(200);
  });

  it('expires admin sessions after 12 hours of inactivity', async () => {
    const { cookie } = await enrolledAdmin();
    const me = body<{ id: string }>(await adminMe(cookie)).data;
    const stale = new Date(Date.now() - 12 * 3600_000 - 60_000);
    await t.c.db.update(sessions).set({ lastSeenAt: stale }).where(eq(sessions.userId, me.id));
    const res = await adminMe(cookie);
    expect(res.statusCode).toBe(401);
    expect(body(res).error?.code).toBe('AUTH_SESSION_EXPIRED');
  });

  it('rejects wrong admin passwords and admin mobile logins', async () => {
    const { email } = await enrolledAdmin();
    expect(body(await adminLogin(email, 'wrong-password')).error?.code).toBe('AUTH_INVALID_CREDENTIALS');
    expect(body(await mobileLogin(t, email)).error?.code).toBe('AUTH_INVALID_CREDENTIALS');
  });

  it('never lets a student reach admin endpoints', async () => {
    const student = await tokensFor(t);
    const res = await t.app.inject({
      method: 'GET',
      url: '/api/v1/admin/me',
      headers: { authorization: `Bearer ${student.accessToken}` },
    });
    expect(res.statusCode).toBe(403);
    expect(body(res).error?.code).toBe('NOT_AUTHORIZED');
  });
});
