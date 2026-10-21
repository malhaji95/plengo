import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { loadEnv } from '../src/env.js';
import {
  ADMIN_ORIGIN,
  PASSWORD,
  body,
  cookieHeader,
  createTestApp,
  csrfHeaders,
  makeAdmin,
  type TestContext,
} from './helpers.js';

const h = csrfHeaders(ADMIN_ORIGIN);

describe('admin 2FA turned off for a pre-launch demo (ADMIN_2FA_REQUIRED=false)', () => {
  let t: TestContext;
  beforeAll(async () => {
    t = await createTestApp({ env: { ADMIN_2FA_REQUIRED: 'false' } });
  });
  afterAll(async () => {
    await t.close();
  });

  it('signs an un-enrolled admin straight in, and the admin routes accept the session', async () => {
    const email = await makeAdmin(t);
    const login = await t.app.inject({
      method: 'POST',
      url: '/api/v1/admin/auth/login',
      headers: h,
      payload: { email, password: PASSWORD },
    });
    expect(login.statusCode).toBe(200);
    expect(body(login).data).toEqual({ next: 'done' });

    const cookie = cookieHeader(login);
    const me = await t.app.inject({ method: 'GET', url: '/api/v1/admin/me', headers: { cookie } });
    expect(me.statusCode).toBe(200);
    expect(body<{ email: string }>(me).data.email).toBe(email);
  });

  it('still rejects a wrong password', async () => {
    const email = await makeAdmin(t);
    const login = await t.app.inject({
      method: 'POST',
      url: '/api/v1/admin/auth/login',
      headers: h,
      payload: { email, password: 'wrong-password-123' },
    });
    expect(login.statusCode).toBe(401);
  });
});

describe('ADMIN_2FA_REQUIRED safety', () => {
  const base = {
    DATABASE_URL: 'postgres://x',
    BETTER_AUTH_SECRET: 'x'.repeat(32),
    BETTER_AUTH_URL: 'https://api.example.com',
    APP_WEB_ORIGIN: 'https://app.example.com',
    ADMIN_ORIGIN: 'https://admin.example.com',
    MOBILE_ACCESS_JWT_SECRET: 'x'.repeat(32),
    MOBILE_REFRESH_TOKEN_PEPPER: 'x'.repeat(32),
    COUPON_HMAC_SECRET: 'x'.repeat(32),
    COUPON_ENCRYPTION_KEY: Buffer.alloc(32, 1).toString('base64'),
    STORAGE_DRIVER: 'memory',
    EMAIL_PROVIDER: 'console',
  };

  it('is on by default', () => {
    expect(loadEnv({ ...base, APP_ENV: 'staging' }).ADMIN_2FA_REQUIRED).toBe(true);
  });

  it('can be turned off on staging but production refuses to start without it', () => {
    expect(loadEnv({ ...base, APP_ENV: 'staging', ADMIN_2FA_REQUIRED: 'false' }).ADMIN_2FA_REQUIRED).toBe(
      false,
    );
    expect(() =>
      loadEnv({
        ...base,
        APP_ENV: 'production',
        STORAGE_DRIVER: 'r2',
        R2_ACCOUNT_ID: 'a',
        R2_ACCESS_KEY_ID: 'a',
        R2_SECRET_ACCESS_KEY: 'a',
        R2_PRIVATE_BUCKET: 'a',
        R2_PUBLIC_BUCKET: 'b',
        R2_PUBLIC_BASE_URL: 'https://cdn.example.com',
        EMAIL_PROVIDER: 'resend',
        EMAIL_PROVIDER_API_KEY: 'k',
        ADMIN_2FA_REQUIRED: 'false',
      }),
    ).toThrow(/production requires admin 2FA/);
  });
});
