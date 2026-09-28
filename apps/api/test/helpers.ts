import { randomUUID } from 'node:crypto';
import { eq } from 'drizzle-orm';
import type { LightMyRequestResponse } from 'fastify';
import { educationLevels, users } from '@plengo/db';
import { buildApp, createFastify, type App } from '../src/app.js';
import { ConsoleEmailSender } from '../src/auth/email.js';
import { createContainer, type Container } from '../src/container.js';
import { loadEnv } from '../src/env.js';
import { InlineQueue } from '../src/jobs/queue.js';
import { MemoryStorage } from '../src/storage/memory-storage.js';

export const WEB_ORIGIN = 'http://app.test.local';
export const ADMIN_ORIGIN = 'http://admin.test.local';

export class TestClock {
  offsetMs = 0;
  now = () => new Date(Date.now() + this.offsetMs);
  advance(ms: number) {
    this.offsetMs += ms;
  }
}

export interface TestContext {
  app: App;
  c: Container;
  email: ConsoleEmailSender;
  storage: MemoryStorage;
  queue: InlineQueue;
  clock: TestClock;
  close(): Promise<void>;
}

export async function createTestApp(opts: { storage?: MemoryStorage } = {}): Promise<TestContext> {
  const url = process.env.TEST_DB_URL;
  if (!url) throw new Error('TEST_DB_URL not set; global setup did not run');
  const env = loadEnv({
    NODE_ENV: 'test',
    APP_ENV: 'test',
    LOG_LEVEL: 'silent',
    DATABASE_URL: url,
    DATABASE_POOL_MAX: '5',
    BETTER_AUTH_SECRET: 'test-better-auth-secret-0123456789abcdef',
    BETTER_AUTH_URL: 'http://api.test.local',
    APP_WEB_ORIGIN: WEB_ORIGIN,
    ADMIN_ORIGIN: ADMIN_ORIGIN,
    MOBILE_ACCESS_JWT_SECRET: 'test-access-secret-0123456789abcdef0123',
    MOBILE_REFRESH_TOKEN_PEPPER: 'test-refresh-pepper-0123456789abcdef012',
    COUPON_HMAC_SECRET: 'test-coupon-hmac-secret-0123456789abcdef',
    COUPON_ENCRYPTION_KEY: Buffer.alloc(32, 7).toString('base64'),
    STORAGE_DRIVER: 'memory',
    EMAIL_PROVIDER: 'console',
    JOBS_ENABLED: 'false',
  });
  const app = createFastify({ logger: { level: 'silent' } });
  const email = new ConsoleEmailSender();
  const storage = opts.storage ?? new MemoryStorage();
  const queue = new InlineQueue();
  const clock = new TestClock();
  const c = createContainer(env, app.log, { email, storage, jobs: queue, now: clock.now });
  await buildApp(app, c);
  await app.ready();
  return {
    app,
    c,
    email,
    storage,
    queue,
    clock,
    async close() {
      await app.close();
      await c.pool.end();
    },
  };
}

export function uniqueEmail(prefix = 'student'): string {
  return `${prefix}-${randomUUID().slice(0, 8)}@example.com`;
}

export function body<T = Record<string, unknown>>(
  res: LightMyRequestResponse,
): {
  success: boolean;
  data: T;
  error: { code: string; message: string; details?: unknown } | null;
} {
  return res.json();
}

export function lastOtp(email: ConsoleEmailSender, to: string): string {
  const msg = [...email.outbox].reverse().find((m) => m.to === to);
  const match = msg?.text.match(/\b(\d{6})\b/);
  if (!match) throw new Error(`no OTP email for ${to}`);
  return match[1]!;
}

export const PASSWORD = 'correct-horse-battery';

export async function levelId(t: TestContext, code = 'grade-12'): Promise<string> {
  const [row] = await t.c.db.select().from(educationLevels).where(eq(educationLevels.code, code));
  return row!.id;
}

/** Registers and verifies a student through the public endpoints. */
export async function registerVerifiedStudent(t: TestContext, emailAddr = uniqueEmail()) {
  const reg = await t.app.inject({
    method: 'POST',
    url: '/api/v1/auth/register',
    payload: {
      fullName: 'طالب تجريبي',
      email: emailAddr,
      password: PASSWORD,
      educationLevelId: await levelId(t),
    },
  });
  if (reg.statusCode !== 200) throw new Error(`register failed: ${reg.body}`);
  const verify = await t.app.inject({
    method: 'POST',
    url: '/api/v1/auth/verify-email',
    payload: { email: emailAddr, otp: lastOtp(t.email, emailAddr) },
  });
  if (verify.statusCode !== 200) throw new Error(`verify failed: ${verify.body}`);
  return emailAddr;
}

export async function mobileLogin(t: TestContext, emailAddr: string, password = PASSWORD) {
  const res = await t.app.inject({
    method: 'POST',
    url: '/api/v1/auth/mobile/login',
    payload: { email: emailAddr, password, platform: 'android', appVersion: '1.0.0' },
  });
  return res;
}

export async function tokensFor(t: TestContext, emailAddr?: string) {
  const addr = emailAddr ?? (await registerVerifiedStudent(t));
  const res = await mobileLogin(t, addr);
  if (res.statusCode !== 200) throw new Error(`login failed: ${res.body}`);
  return { email: addr, ...body<{ accessToken: string; refreshToken: string }>(res).data };
}

export async function makeAdmin(t: TestContext, emailAddr = uniqueEmail('admin')) {
  await t.c.auth.api.signUpEmail({ body: { name: 'Admin', email: emailAddr, password: PASSWORD } });
  await t.c.db.update(users).set({ role: 'admin', emailVerified: true }).where(eq(users.email, emailAddr));
  return emailAddr;
}

export function cookieHeader(res: LightMyRequestResponse, previous = ''): string {
  const jar = new Map<string, string>();
  for (const part of previous.split('; ').filter(Boolean)) {
    const [k, ...v] = part.split('=');
    jar.set(k!, v.join('='));
  }
  for (const c of res.cookies) {
    if (c.value === '' || (c.maxAge !== undefined && c.maxAge <= 0)) jar.delete(c.name);
    else jar.set(c.name, c.value);
  }
  return [...jar].map(([k, v]) => `${k}=${v}`).join('; ');
}

export const csrfHeaders = (origin: string) => ({ origin, 'x-requested-with': 'XMLHttpRequest' });

/** A fresh admin that has completed TOTP enrollment; returns its session cookie and CSRF headers. */
export async function enrolledAdminSession(t: TestContext) {
  const { generateSync } = await import('otplib');
  const email = await makeAdmin(t);
  const h = csrfHeaders(ADMIN_ORIGIN);
  const login = await t.app.inject({
    method: 'POST',
    url: '/api/v1/admin/auth/login',
    headers: h,
    payload: { email, password: PASSWORD },
  });
  let cookie = cookieHeader(login);
  const enroll = await t.app.inject({
    method: 'POST',
    url: '/api/v1/admin/auth/2fa/enroll',
    headers: { cookie, ...h },
    payload: { password: PASSWORD },
  });
  const secret = new URL(body<{ totpUri: string }>(enroll).data.totpUri).searchParams.get('secret')!;
  const confirm = await t.app.inject({
    method: 'POST',
    url: '/api/v1/admin/auth/2fa/confirm',
    headers: { cookie, ...h },
    payload: { code: generateSync({ secret }) },
  });
  cookie = cookieHeader(confirm, cookie);
  return { email, headers: { cookie, ...h } };
}
