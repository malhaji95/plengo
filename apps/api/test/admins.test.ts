import { and, eq, inArray, ne } from 'drizzle-orm';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { adminTwoFactor, auditLogs, sessions, users } from '@plengo/db';
import {
  ADMIN_ORIGIN,
  body,
  createTestApp,
  csrfHeaders,
  enrolledAdminSession,
  PASSWORD,
  tokensFor,
  uniqueEmail,
  type TestContext,
} from './helpers.js';

let t: TestContext;
let admin: { email: string; headers: Record<string, string> };

beforeAll(async () => {
  t = await createTestApp();
  admin = await enrolledAdminSession(t);
});
afterAll(async () => {
  await t.close();
});

type Account = { id: string; email: string; status: string; twoFactorEnabled: boolean };

const call = async <T = Record<string, unknown>>(
  method: 'GET' | 'POST' | 'PUT' | 'DELETE',
  url: string,
  payload?: object,
  headers = admin.headers,
) => {
  const res = await t.app.inject({
    method,
    url: `/api/v1/admin${url}`,
    headers,
    ...(payload ? { payload } : {}),
  });
  return { status: res.statusCode, ...body<T>(res) };
};

async function idOf(email: string) {
  const [u] = await t.c.db.select({ id: users.id }).from(users).where(eq(users.email, email));
  return u!.id;
}

describe('admin accounts (§11.3, §26.2)', () => {
  it('admins create admins, who enroll in 2FA at first login', async () => {
    const email = uniqueEmail('new-admin');
    const created = await call<Account>('POST', '/admins', {
      email,
      fullName: 'مشرف جديد',
      password: PASSWORD,
    });
    expect(created.status).toBe(200);
    expect(created.data).toMatchObject({ email, status: 'active', twoFactorEnabled: false });
    expect((await call('POST', '/admins', { email, fullName: 'مكرر', password: PASSWORD })).error?.code).toBe(
      'AUTH_EMAIL_TAKEN',
    );
    const login = await t.app.inject({
      method: 'POST',
      url: '/api/v1/admin/auth/login',
      headers: csrfHeaders(ADMIN_ORIGIN),
      payload: { email, password: PASSWORD },
    });
    expect(body<{ next: string }>(login).data.next).toBe('enroll');
    const list = await call<Account[]>('GET', '/admins');
    expect(list.data.some((a) => a.email === email)).toBe(true);
    const [audit] = await t.c.db
      .select()
      .from(auditLogs)
      .where(and(eq(auditLogs.action, 'admin.created'), eq(auditLogs.resourceId, created.data.id)));
    expect(audit).toBeDefined();
  });

  it('students cannot manage admins', async () => {
    const { accessToken } = await tokensFor(t);
    const res = await t.app.inject({
      method: 'GET',
      url: '/api/v1/admin/admins',
      headers: { authorization: `Bearer ${accessToken}` },
    });
    expect(res.statusCode).toBeGreaterThanOrEqual(401);
  });

  it('deactivation ends sessions and blocks login; reactivation restores it', async () => {
    const other = await enrolledAdminSession(t);
    const id = await idOf(other.email);
    const res = await call<Account>('POST', `/admins/${id}/deactivate`);
    expect(res.data.status).toBe('disabled');
    // Its session no longer works and it cannot log in again.
    expect((await call('GET', '/admins', undefined, other.headers)).status).toBe(401);
    const login = await t.app.inject({
      method: 'POST',
      url: '/api/v1/admin/auth/login',
      headers: csrfHeaders(ADMIN_ORIGIN),
      payload: { email: other.email, password: PASSWORD },
    });
    expect(body(login).error?.code).toBe('AUTH_INVALID_CREDENTIALS');
    expect((await call<Account>('POST', `/admins/${id}/reactivate`)).data.status).toBe('active');
    const again = await t.app.inject({
      method: 'POST',
      url: '/api/v1/admin/auth/login',
      headers: csrfHeaders(ADMIN_ORIGIN),
      payload: { email: other.email, password: PASSWORD },
    });
    expect(again.statusCode).toBe(200);
  });

  it('the last active admin cannot be deactivated', async () => {
    const selfId = await idOf(admin.email);
    const others = await t.c.db
      .select({ id: users.id })
      .from(users)
      .where(and(eq(users.role, 'admin'), eq(users.status, 'active'), ne(users.id, selfId)));
    const ids = others.map((o) => o.id);
    if (ids.length) await t.c.db.update(users).set({ status: 'disabled' }).where(inArray(users.id, ids));
    try {
      const res = await call('POST', `/admins/${selfId}/deactivate`);
      expect(res.error?.code).toBe('VALIDATION_ERROR');
      expect(res.error?.details).toMatchObject({ reason: 'last_active_admin' });
    } finally {
      if (ids.length) await t.c.db.update(users).set({ status: 'active' }).where(inArray(users.id, ids));
    }
  });

  it('another admin resets 2FA (audited); nobody resets their own', async () => {
    const other = await enrolledAdminSession(t);
    const id = await idOf(other.email);
    expect((await call('POST', `/admins/${await idOf(admin.email)}/reset-2fa`)).error?.code).toBe(
      'NOT_AUTHORIZED',
    );
    const res = await call<Account>('POST', `/admins/${id}/reset-2fa`);
    expect(res.data.twoFactorEnabled).toBe(false);
    expect(await t.c.db.select().from(adminTwoFactor).where(eq(adminTwoFactor.userId, id))).toHaveLength(0);
    expect((await call('GET', '/admins', undefined, other.headers)).status).toBe(401);
    const login = await t.app.inject({
      method: 'POST',
      url: '/api/v1/admin/auth/login',
      headers: csrfHeaders(ADMIN_ORIGIN),
      payload: { email: other.email, password: PASSWORD },
    });
    expect(body<{ next: string }>(login).data.next).toBe('enroll');
    const audits = await t.c.db
      .select()
      .from(auditLogs)
      .where(and(eq(auditLogs.action, 'admin.2fa_reset'), eq(auditLogs.resourceId, id)));
    expect(audits).toHaveLength(1);
  });
});

describe('admin student tools (§26.2)', () => {
  it('lists and revokes a student session; shows the attempts summary', async () => {
    const { email, accessToken } = await tokensFor(t);
    const studentId = await idOf(email);
    const list = await call<{ id: string; platform: string }[]>('GET', `/students/${studentId}/sessions`);
    expect(list.data).toHaveLength(1);
    const revoke = await call('DELETE', `/students/${studentId}/sessions/${list.data[0]!.id}`);
    expect(revoke.data).toEqual({ revoked: true });
    const [row] = await t.c.db.select().from(sessions).where(eq(sessions.id, list.data[0]!.id));
    expect(row!.expiresAt.getTime()).toBeLessThanOrEqual(Date.now());
    const me = await t.app.inject({
      method: 'GET',
      url: '/api/v1/me',
      headers: { authorization: `Bearer ${accessToken}` },
    });
    expect(me.statusCode).toBe(401);
    const attempts = await call<{ items: unknown[] }>('GET', `/students/${studentId}/attempts`);
    expect(attempts.data.items).toEqual([]);
    // Admin accounts are not students.
    expect((await call('GET', `/students/${await idOf(admin.email)}/sessions`)).error?.code).toBe(
      'NOT_FOUND',
    );
  });

  it('remote config is editable, validated and audited (§10.2)', async () => {
    const current = await call<Record<string, unknown>>('GET', '/settings/remote-config');
    try {
      const next = { ...current.data, minSupportedVersion: { android: '1.1.0', ios: '1.0.0', web: '1.0.0' } };
      const saved = await call<{ minSupportedVersion: { android: string } }>(
        'PUT',
        '/settings/remote-config',
        next,
      );
      expect(saved.data.minSupportedVersion.android).toBe('1.1.0');
      const pub = await t.app.inject({ method: 'GET', url: '/api/v1/config' });
      expect(body<{ minSupportedVersion: { android: string } }>(pub).data.minSupportedVersion.android).toBe(
        '1.1.0',
      );
      const bad = { ...current.data, minSupportedVersion: { android: 'latest', ios: '1.0.0', web: '1.0.0' } };
      expect((await call('PUT', '/settings/remote-config', bad)).error?.code).toBe('VALIDATION_ERROR');
      const audits = await t.c.db.select().from(auditLogs).where(eq(auditLogs.resourceId, 'remote_config'));
      expect(audits.length).toBeGreaterThan(0);
    } finally {
      await call('PUT', '/settings/remote-config', current.data);
    }
  });
});
