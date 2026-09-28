import { randomUUID } from 'node:crypto';
import { and, eq, inArray } from 'drizzle-orm';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import {
  auditLogs,
  couponRedemptionFailures,
  couponRedemptions,
  coupons,
  entitlements,
  users,
} from '@plengo/db';
import { endOfBusinessDay } from '../src/lib/business-time.js';
import { subjectScope, trackScope } from '../src/services/access-service.js';
import { createFreeRuleService, type FreeContentSource } from '../src/services/free-rule-service.js';
import {
  body,
  createTestApp,
  enrolledAdminSession,
  levelId,
  tokensFor,
  type TestContext,
} from './helpers.js';

let t: TestContext;
let admin: Record<string, string>;

beforeAll(async () => {
  t = await createTestApp();
  admin = (await enrolledAdminSession(t)).headers;
});
afterAll(async () => {
  await t.close();
});

const slug = (p: string) => `${p}-${randomUUID().slice(0, 8)}`;
const DAY = 86_400_000;
/** Each test gets its own client IP so the per-IP limit (§9.5) never leaks between tests. */
const freshIp = () =>
  `10.${Math.floor(Math.random() * 250)}.${Math.floor(Math.random() * 250)}.${Math.floor(Math.random() * 250)}`;

type Json = Record<string, unknown>;

async function adminCall<T = Json>(
  method: 'GET' | 'POST' | 'PATCH' | 'PUT' | 'DELETE',
  url: string,
  payload?: object,
) {
  const res = await t.app.inject({
    method,
    url: `/api/v1/admin${url}`,
    headers: admin,
    ...(payload ? { payload } : {}),
  });
  return { status: res.statusCode, raw: res, ...body<T>(res) };
}

interface Student {
  id: string;
  token: string;
  ip: string;
}

async function student(): Promise<Student> {
  const { email, accessToken } = await tokensFor(t);
  const [u] = await t.c.db.select({ id: users.id }).from(users).where(eq(users.email, email));
  return { id: u!.id, token: accessToken, ip: freshIp() };
}

async function studentCall<T = Json>(s: Student, method: 'GET' | 'POST', url: string, payload?: object) {
  const res = await t.app.inject({
    method,
    url: `/api/v1${url}`,
    headers: { authorization: `Bearer ${s.token}` },
    remoteAddress: s.ip,
    ...(payload ? { payload } : {}),
  });
  return { status: res.statusCode, ...body<T>(res) };
}

const redeem = (s: Student, code: string) =>
  studentCall<{ entitlement: { id: string; state: string; isPermanent: boolean }; upgraded: boolean }>(
    s,
    'POST',
    '/coupons/redeem',
    { code },
  );

async function subjectWithTrack() {
  const subj = (
    await adminCall<{ id: string }>('POST', '/subjects', {
      educationLevelId: await levelId(t, 'grade-12'),
      code: slug('phys'),
      nameAr: 'الفيزياء',
    })
  ).data;
  const teacher = (
    await adminCall<{ id: string }>('POST', '/teachers', { nameAr: 'أ. أحمد', slug: slug('t') })
  ).data;
  const track = (
    await adminCall<{ id: string }>('POST', '/teacher-tracks', {
      teacherId: teacher.id,
      subjectId: subj.id,
      titleAr: 'أ. أحمد — فيزياء بكالوريا',
      slug: slug('track'),
    })
  ).data;
  return { subjectId: subj.id, trackId: track.id };
}

type Term = { permanentAccess?: boolean; accessDurationDays?: number; accessExpiresOn?: string };

/** Creates a batch, runs the generation job, and returns the plaintext codes from the CSV export. */
async function batch(
  scope: { subjectId?: string; teacherTrackId?: string },
  quantity: number,
  term: Term = { permanentAccess: true },
  extra: Json = {},
) {
  const created = await adminCall<{ id: string; generatedCount: number }>('POST', '/coupon-batches', {
    name: slug('batch'),
    distributorName: 'مكتبة النور',
    scopeType: scope.subjectId ? 'subject' : 'teacher_track',
    ...scope,
    quantity,
    ...term,
    ...extra,
  });
  expect(created.status).toBe(200);
  expect(created.data.generatedCount).toBe(0);
  await t.queue.drain(t.c.jobHandlers);
  const csv = await t.app.inject({
    method: 'GET',
    url: `/api/v1/admin/coupon-batches/${created.data.id}/export?format=csv`,
    headers: admin,
  });
  expect(csv.statusCode).toBe(200);
  const codes = csv.body
    .split('\r\n')
    .slice(1)
    .filter(Boolean)
    .map((line) => line.split(',')[0]!);
  return { id: created.data.id, codes };
}

describe('coupon batches (§9.6)', () => {
  it('generates codes in a job, exports CSV/XLSX, and audits', async () => {
    const { subjectId } = await subjectWithTrack();
    const { id, codes } = await batch({ subjectId }, 12);
    expect(codes).toHaveLength(12);
    for (const code of codes)
      expect(code).toMatch(/^[2-9A-HJKMNP-Z]{4}-[2-9A-HJKMNP-Z]{4}-[2-9A-HJKMNP-Z]{2}$/);
    expect(new Set(codes).size).toBe(12);

    // The batch's codes page by cursor (§30.1).
    type Page = { items: { codeLast4: string }[]; nextCursor: string | null };
    const p1 = await adminCall<Page>('GET', `/coupon-batches/${id}/coupons?limit=5`);
    const p2 = await adminCall<Page>(
      'GET',
      `/coupon-batches/${id}/coupons?limit=5&cursor=${p1.data.nextCursor}`,
    );
    const p3 = await adminCall<Page>(
      'GET',
      `/coupon-batches/${id}/coupons?limit=5&cursor=${p2.data.nextCursor}`,
    );
    expect([p1, p2, p3].map((p) => p.data.items.length)).toEqual([5, 5, 2]);
    expect(p3.data.nextCursor).toBeNull();

    const got = await adminCall<{
      generatedCount: number;
      redeemedCount: number;
      scope: { subjectNameAr: string };
    }>('GET', `/coupon-batches/${id}`);
    expect(got.data).toMatchObject({
      generatedCount: 12,
      redeemedCount: 0,
      scope: { subjectNameAr: 'الفيزياء' },
    });

    const stored = await t.c.db.select().from(coupons).where(eq(coupons.batchId, id));
    expect(stored).toHaveLength(12);
    // Plaintext is never stored.
    for (const row of stored) {
      expect(row.codeEncrypted).not.toContain(row.codeLast4);
      expect(row.codeHash).toMatch(/^[0-9a-f]{64}$/);
    }

    const xlsx = await t.app.inject({
      method: 'GET',
      url: `/api/v1/admin/coupon-batches/${id}/export?format=xlsx`,
      headers: admin,
    });
    expect(xlsx.statusCode).toBe(200);
    expect(xlsx.headers['content-type']).toContain('spreadsheetml');
    expect(xlsx.rawPayload.subarray(0, 2).toString()).toBe('PK');

    const logs = await t.c.db.select().from(auditLogs).where(eq(auditLogs.resourceId, id));
    expect(logs.map((l) => l.action).sort()).toEqual([
      'coupon_batch.exported',
      'coupon_batch.exported',
      'coupon_batch.generated',
    ]);
  });

  it('validates the access term and quantity', async () => {
    const { subjectId } = await subjectWithTrack();
    const base = { name: 'x', scopeType: 'subject', subjectId, quantity: 1 };
    expect((await adminCall('POST', '/coupon-batches', base)).status).toBe(400);
    expect(
      (await adminCall('POST', '/coupon-batches', { ...base, permanentAccess: true, accessDurationDays: 30 }))
        .status,
    ).toBe(400);
    expect(
      (await adminCall('POST', '/coupon-batches', { ...base, permanentAccess: true, quantity: 5001 })).status,
    ).toBe(400);
    expect(
      (
        await adminCall('POST', '/coupon-batches', {
          ...base,
          scopeType: 'teacher_track',
          permanentAccess: true,
        })
      ).status,
    ).toBe(400);
  });

  it('finds coupons by full code or last four characters', async () => {
    const { subjectId } = await subjectWithTrack();
    const { codes } = await batch({ subjectId }, 2);
    const full = await adminCall<{ codeLast4: string }[]>(
      'GET',
      `/coupons?q=${encodeURIComponent(codes[0]!.toLowerCase())}`,
    );
    expect(full.data).toHaveLength(1);
    expect(full.data[0]!.codeLast4).toBe(codes[0]!.replace(/-/g, '').slice(-4));
    const byLast4 = await adminCall<unknown[]>('GET', `/coupons?q=${codes[1]!.replace(/-/g, '').slice(-4)}`);
    expect(byLast4.data.length).toBeGreaterThanOrEqual(1);
  });
});

describe('redemption (§9.4)', () => {
  it('grants a subject entitlement, which does not unlock the tracks of that subject', async () => {
    const { subjectId, trackId } = await subjectWithTrack();
    const { id: batchId, codes } = await batch({ subjectId }, 1);
    const s = await student();

    // Lowercase, spaces and Arabic-Indic digits are accepted (§9.3).
    const typed = codes[0]!
      .toLowerCase()
      .replace(/-/g, ' ')
      .replace(/[0-9]/g, (d) => String.fromCharCode(0x0660 + Number(d)));
    const res = await redeem(s, typed);
    expect(res.status).toBe(200);
    expect(res.data.entitlement).toMatchObject({ state: 'active', isPermanent: true, source: 'coupon' });
    expect(res.data.upgraded).toBe(false);

    const outline = await studentCall<{ access: Json; tracks: { id: string; hasAccess: boolean }[] }>(
      s,
      'GET',
      `/subjects/${subjectId}`,
    );
    expect(outline.data.access).toMatchObject({ hasAccess: true, reason: 'entitlement', isPermanent: true });
    expect(outline.data.tracks.find((x) => x.id === trackId)?.hasAccess).toBe(false);
    const trackPage = await studentCall<{ access: Json }>(s, 'GET', `/teacher-tracks/${trackId}`);
    expect(trackPage.data.access).toMatchObject({ hasAccess: false, reason: null });

    const mine = await studentCall<{ scope: { subjectId: string }; state: string }[]>(s, 'GET', '/access');
    expect(mine.data).toHaveLength(1);
    expect(mine.data[0]).toMatchObject({ scope: { subjectId, scopeType: 'subject' }, state: 'active' });

    const [coupon] = await t.c.db.select().from(coupons).where(eq(coupons.batchId, batchId));
    expect(coupon).toMatchObject({ currentUses: 1, status: 'redeemed' });
    const redemptions = await t.c.db
      .select()
      .from(couponRedemptions)
      .where(eq(couponRedemptions.couponId, coupon!.id));
    expect(redemptions).toHaveLength(1);
    expect(redemptions[0]!.userId).toBe(s.id);

    // A used code fails for everyone else and is logged.
    const other = await student();
    expect((await redeem(other, codes[0]!)).error?.code).toBe('COUPON_ALREADY_USED');
    const failures = await t.c.db
      .select()
      .from(couponRedemptionFailures)
      .where(eq(couponRedemptionFailures.userId, other.id));
    expect(failures).toMatchObject([{ reason: 'COUPON_ALREADY_USED', codeLast4: coupon!.codeLast4 }]);
    expect(failures[0]!.ipHash).toMatch(/^[0-9a-f]{32}$/);
  });

  it('grants a track entitlement, which does not unlock general subject content', async () => {
    const { subjectId, trackId } = await subjectWithTrack();
    const { codes } = await batch({ teacherTrackId: trackId }, 1, { accessDurationDays: 30 });
    const s = await student();
    const res = await redeem(s, codes[0]!);
    expect(res.data.entitlement).toMatchObject({ isPermanent: false, state: 'active' });

    const ctx = await t.c.access.context(s.id);
    expect(ctx.canAccessItem({ subjectId, teacherTrackId: trackId })).toBe(true);
    expect(ctx.canAccessItem({ subjectId, teacherTrackId: null })).toBe(false);
    expect(ctx.canAccessItem({ subjectId, teacherTrackId: null, isFree: true })).toBe(true);
    await expect(
      t.c.access.assertCanAccessItem(s.id, { subjectId, teacherTrackId: null }),
    ).rejects.toMatchObject({
      code: 'CONTENT_LOCKED',
    });

    const page = await studentCall<{ access: Json }>(s, 'GET', `/teacher-tracks/${trackId}`);
    expect(page.data.access).toMatchObject({ hasAccess: true, reason: 'entitlement', isPermanent: false });
  });

  it('revoking a batch refuses unused codes but keeps entitlements already granted (§9.6)', async () => {
    const { subjectId } = await subjectWithTrack();
    const b = await batch({ subjectId }, 2);
    const s = await student();
    const used = await redeem(s, b.codes[0]!);
    expect(used.status).toBe(200);
    await adminCall('POST', `/coupon-batches/${b.id}/revoke`);
    const [e] = await t.c.db.select().from(entitlements).where(eq(entitlements.id, used.data.entitlement.id));
    expect(e!.status).toBe('active');
    expect(await t.c.access.canAccessItem(s.id, { subjectId, teacherTrackId: null })).toBe(true);
    expect((await redeem(await student(), b.codes[1]!)).error?.code).toBe('COUPON_REVOKED');
  });

  it('a burst of parallel attempts from one student cannot pass the per-minute limit (§9.5)', async () => {
    const s = await student();
    const results = await Promise.all(Array.from({ length: 8 }, () => redeem(s, 'ZZZZ-ZZZZ-ZZ')));
    const codes = results.map((r) => r.error?.code);
    expect(codes.filter((c) => c === 'COUPON_NOT_FOUND')).toHaveLength(5);
    expect(codes.filter((c) => c === 'RATE_LIMITED')).toHaveLength(3);
  });

  it('answers COUPON_NOT_FOUND for malformed and unknown codes, and logs both', async () => {
    const s = await student();
    expect((await redeem(s, 'ABC')).error?.code).toBe('COUPON_NOT_FOUND');
    expect((await redeem(s, 'ZZZZ-ZZZZ-ZZ')).error?.code).toBe('COUPON_NOT_FOUND');
    const failures = await t.c.db
      .select()
      .from(couponRedemptionFailures)
      .where(eq(couponRedemptionFailures.userId, s.id));
    expect(failures.map((f) => f.reason)).toEqual(['COUPON_NOT_FOUND', 'COUPON_NOT_FOUND']);
  });

  it('rejects revoked batches and codes outside their validity window', async () => {
    const { subjectId } = await subjectWithTrack();
    const revoked = await batch({ subjectId }, 2);
    const res = await adminCall<{ status: string }>('POST', `/coupon-batches/${revoked.id}/revoke`);
    expect(res.data.status).toBe('revoked');
    const s = await student();
    expect((await redeem(s, revoked.codes[0]!)).error?.code).toBe('COUPON_REVOKED');

    const expired = await batch({ subjectId }, 1);
    await t.c.db
      .update(coupons)
      .set({ expiresAt: new Date(Date.now() - 1000) })
      .where(eq(coupons.batchId, expired.id));
    expect((await redeem(s, expired.codes[0]!)).error?.code).toBe('COUPON_EXPIRED');

    const future = new Date(Date.now() + 10 * DAY).toISOString().slice(0, 10);
    const notYet = await batch({ subjectId }, 1, { permanentAccess: true }, { validFrom: future });
    expect((await redeem(s, notYet.codes[0]!)).error?.code).toBe('COUPON_EXPIRED');
  });

  it('refuses a second grant for an active scope without consuming the code', async () => {
    const { subjectId } = await subjectWithTrack();
    const first = await batch({ subjectId }, 1, { accessDurationDays: 10 });
    const second = await batch({ subjectId }, 1, { accessDurationDays: 30 });
    const s = await student();
    expect((await redeem(s, first.codes[0]!)).status).toBe(200);
    const res = await redeem(s, second.codes[0]!);
    expect(res.status).toBe(409);
    expect(res.error?.code).toBe('ALREADY_ENTITLED');
    const [unused] = await t.c.db.select().from(coupons).where(eq(coupons.batchId, second.id));
    expect(unused).toMatchObject({ currentUses: 0, status: 'active' });
    // Still redeemable by someone else.
    expect((await redeem(await student(), second.codes[0]!)).status).toBe(200);
  });

  it('upgrades temporary to permanent, unless the setting is off (§8.3)', async () => {
    const { subjectId } = await subjectWithTrack();
    const temp = await batch({ subjectId }, 2, { accessDurationDays: 10 });
    const perm = await batch({ subjectId }, 2);
    const s = await student();
    const firstGrant = await redeem(s, temp.codes[0]!);
    const upgraded = await redeem(s, perm.codes[0]!);
    expect(upgraded.data).toMatchObject({
      upgraded: true,
      entitlement: { isPermanent: true, state: 'active' },
    });
    const [old] = await t.c.db
      .select()
      .from(entitlements)
      .where(eq(entitlements.id, firstGrant.data.entitlement.id));
    expect(old!.status).toBe('superseded');
    // Permanent over permanent is refused.
    expect((await redeem(s, perm.codes[1]!)).error?.code).toBe('ALREADY_ENTITLED');
    // Superseded rows are hidden from "My access".
    expect((await studentCall<unknown[]>(s, 'GET', '/access')).data).toHaveLength(1);

    const setting = await adminCall('PUT', '/settings/access', { allowTemporaryToPermanentUpgrade: false });
    expect(setting.status).toBe(200);
    try {
      const other = await student();
      await redeem(other, temp.codes[1]!);
      expect((await redeem(other, perm.codes[1]!)).error?.code).toBe('ALREADY_ENTITLED');
    } finally {
      await adminCall('PUT', '/settings/access', { allowTemporaryToPermanentUpgrade: true });
    }
  });

  it('expires stale entitlements inside the transaction so a new code works (§8.3)', async () => {
    const { subjectId } = await subjectWithTrack();
    const first = await batch({ subjectId }, 1, { accessDurationDays: 5 });
    const second = await batch({ subjectId }, 1, { accessDurationDays: 5 });
    const s = await student();
    const granted = await redeem(s, first.codes[0]!);
    // Time passes: the row is still stored as active but its expiry is behind us.
    await t.c.db
      .update(entitlements)
      .set({ expiresAt: new Date(Date.now() - 1000) })
      .where(eq(entitlements.id, granted.data.entitlement.id));
    expect((await t.c.access.scopeAccess(s.id, subjectScope(subjectId))).hasAccess).toBe(false);
    expect((await redeem(s, second.codes[0]!)).status).toBe(200);
    const [old] = await t.c.db
      .select()
      .from(entitlements)
      .where(eq(entitlements.id, granted.data.entitlement.id));
    expect(old!.status).toBe('expired');
    const mine = await studentCall<{ state: string }[]>(s, 'GET', '/access');
    expect(mine.data.map((m) => m.state)).toEqual(['active', 'expired']);
  });
});

describe('concurrency (§9.7)', () => {
  it('20 concurrent redemptions of one code: 1 success, 19 failures, 1 entitlement, 1 redemption', async () => {
    const { subjectId } = await subjectWithTrack();
    const { id, codes } = await batch({ subjectId }, 1);
    const students = await Promise.all(Array.from({ length: 20 }, () => student()));
    const results = await Promise.all(students.map((s) => redeem(s, codes[0]!)));
    expect(results.filter((r) => r.status === 200)).toHaveLength(1);
    const failures = results.filter((r) => r.status !== 200);
    expect(failures).toHaveLength(19);
    for (const f of failures) expect(f.error?.code).toBe('COUPON_ALREADY_USED');

    const [coupon] = await t.c.db.select().from(coupons).where(eq(coupons.batchId, id));
    expect(coupon).toMatchObject({ currentUses: 1, status: 'redeemed' });
    const granted = await t.c.db.select().from(entitlements).where(eq(entitlements.couponId, coupon!.id));
    expect(granted).toHaveLength(1);
    const redemptions = await t.c.db
      .select()
      .from(couponRedemptions)
      .where(eq(couponRedemptions.couponId, coupon!.id));
    expect(redemptions).toHaveLength(1);
  });

  it('two different codes for the same user and scope at once: one entitlement, loser untouched', async () => {
    const { subjectId } = await subjectWithTrack();
    const a = await batch({ subjectId }, 1);
    const b = await batch({ subjectId }, 1);
    const s = await student();
    const [ra, rb] = await Promise.all([redeem(s, a.codes[0]!), redeem(s, b.codes[0]!)]);
    const statuses = [ra.status, rb.status].sort();
    expect(statuses).toEqual([200, 409]);
    const loser = ra.status === 409 ? ra : rb;
    expect(loser.error?.code).toBe('ALREADY_ENTITLED');

    const rows = await t.c.db
      .select()
      .from(entitlements)
      .where(and(eq(entitlements.userId, s.id), eq(entitlements.subjectId, subjectId)));
    expect(rows).toHaveLength(1);
    const loserBatch = ra.status === 409 ? a.id : b.id;
    const [loserCoupon] = await t.c.db.select().from(coupons).where(eq(coupons.batchId, loserBatch));
    expect(loserCoupon).toMatchObject({ currentUses: 0, status: 'active' });
    const redemptions = await t.c.db
      .select()
      .from(couponRedemptions)
      .where(eq(couponRedemptions.couponId, loserCoupon!.id));
    expect(redemptions).toHaveLength(0);
  });

  it('maps a concurrent admin-grant race to ALREADY_ENTITLED', async () => {
    const { subjectId } = await subjectWithTrack();
    const s = await student();
    const payload = { scopeType: 'subject', subjectId, permanentAccess: true };
    const results = await Promise.all(
      Array.from({ length: 4 }, () => adminCall('POST', `/students/${s.id}/entitlements`, payload)),
    );
    expect(results.filter((r) => r.status === 200)).toHaveLength(1);
    for (const r of results.filter((x) => x.status !== 200)) expect(r.error?.code).toBe('ALREADY_ENTITLED');
  });
});

describe('abuse protection (§9.5)', () => {
  const fail = (s: Student) => redeem(s, 'ZZZZ-ZZZZ-ZZ');

  it('allows 5 attempts per minute per user', async () => {
    const s = await student();
    for (let i = 0; i < 5; i++) expect((await fail(s)).error?.code).toBe('COUPON_NOT_FOUND');
    const limited = await fail(s);
    expect(limited.status).toBe(429);
    expect(limited.error?.code).toBe('RATE_LIMITED');
    // Rate-limited attempts are not logged as failures.
    const rows = await t.c.db
      .select()
      .from(couponRedemptionFailures)
      .where(eq(couponRedemptionFailures.userId, s.id));
    expect(rows).toHaveLength(5);
  });

  it('allows 20 attempts per hour per user', async () => {
    const s = await student();
    // 40 minutes ago: outside the one-minute window and past the consecutive-failure cooldown, so only
    // the hourly limit applies.
    const earlier = new Date(Date.now() - 40 * 60_000);
    await t.c.db
      .insert(couponRedemptionFailures)
      .values(
        Array.from({ length: 20 }, () => ({ userId: s.id, reason: 'COUPON_NOT_FOUND', createdAt: earlier })),
      );
    expect((await fail(s)).error?.code).toBe('RATE_LIMITED');
  });

  it('starts a 30-minute cooldown after 10 consecutive failures', async () => {
    const s = await student();
    const at = (minutesAgo: number) => new Date(Date.now() - minutesAgo * 60_000);
    await t.c.db
      .insert(couponRedemptionFailures)
      .values(
        Array.from({ length: 10 }, () => ({ userId: s.id, reason: 'COUPON_NOT_FOUND', createdAt: at(20) })),
      );
    expect((await fail(s)).error?.code).toBe('RATE_LIMITED');

    const later = await student();
    await t.c.db.insert(couponRedemptionFailures).values(
      Array.from({ length: 10 }, () => ({
        userId: later.id,
        reason: 'COUPON_NOT_FOUND',
        createdAt: at(31),
      })),
    );
    expect((await fail(later)).error?.code).toBe('COUPON_NOT_FOUND');
  });

  it('allows 60 attempts per hour per IP', async () => {
    const ip = freshIp();
    const ipHash = t.c.hashIp(ip);
    await t.c.db.insert(couponRedemptionFailures).values(
      Array.from({ length: 60 }, () => ({
        ipHash,
        reason: 'COUPON_NOT_FOUND',
        createdAt: new Date(Date.now() - 10 * 60_000),
      })),
    );
    const s = { ...(await student()), ip };
    expect((await fail(s)).error?.code).toBe('RATE_LIMITED');

    const report = await adminCall<{ ips: { ipHash: string; failures: number }[] }>(
      'GET',
      '/coupon-failures',
    );
    expect(report.data.ips.find((x) => x.ipHash === ipHash)?.failures).toBe(60);
  });
});

describe('entitlement lifecycle', () => {
  it('locks immediately after 23:59:59 Asia/Damascus on a date-only expiry', async () => {
    const { subjectId } = await subjectWithTrack();
    const s = await student();
    const future = new Date(Date.now() + 40 * DAY);
    const date = future.toISOString().slice(0, 10);
    const granted = await adminCall<{ id: string; expiresAt: string }>(
      'POST',
      `/students/${s.id}/entitlements`,
      {
        scopeType: 'subject',
        subjectId,
        accessExpiresOn: date,
      },
    );
    expect(granted.status).toBe(200);
    const boundary = endOfBusinessDay(date, 'Asia/Damascus');
    expect(granted.data.expiresAt).toBe(boundary.toISOString());

    const at = (ms: number) => {
      t.clock.offsetMs = ms - Date.now();
    };
    try {
      at(boundary.getTime() - 1000);
      expect((await t.c.access.scopeAccess(s.id, subjectScope(subjectId))).hasAccess).toBe(true);
      at(boundary.getTime());
      expect((await t.c.access.scopeAccess(s.id, subjectScope(subjectId))).hasAccess).toBe(false);
      // The nightly job only brings the stored status in line.
      at(boundary.getTime() + 60_000);
      expect(await t.c.access.expireAllStale()).toBeGreaterThanOrEqual(1);
      const [row] = await t.c.db.select().from(entitlements).where(eq(entitlements.id, granted.data.id));
      expect(row!.status).toBe('expired');
    } finally {
      t.clock.offsetMs = 0;
    }
  });

  it('lets admins grant, refuse duplicates, extend and revoke — all audited', async () => {
    const { subjectId, trackId } = await subjectWithTrack();
    const s = await student();
    const grant = await adminCall<{ id: string; isPermanent: boolean }>(
      'POST',
      `/students/${s.id}/entitlements`,
      {
        scopeType: 'teacher_track',
        teacherTrackId: trackId,
        accessDurationDays: 7,
      },
    );
    expect(grant.data.isPermanent).toBe(false);
    const dup = await adminCall('POST', `/students/${s.id}/entitlements`, {
      scopeType: 'teacher_track',
      teacherTrackId: trackId,
      accessDurationDays: 30,
    });
    expect(dup.error?.code).toBe('ALREADY_ENTITLED');

    const later = new Date(Date.now() + 90 * DAY).toISOString().slice(0, 10);
    const extended = await adminCall<{ expiresAt: string; state: string }>(
      'POST',
      `/entitlements/${grant.data.id}/extend`,
      {
        expiresOn: later,
      },
    );
    expect(extended.data.expiresAt).toBe(endOfBusinessDay(later, 'Asia/Damascus').toISOString());
    const permanent = await adminCall<{ isPermanent: boolean; expiresAt: null }>(
      'POST',
      `/entitlements/${grant.data.id}/extend`,
      {
        makePermanent: true,
      },
    );
    expect(permanent.data).toMatchObject({ isPermanent: true, expiresAt: null });
    expect(
      (await adminCall('POST', `/entitlements/${grant.data.id}/extend`, { expiresOn: '2000-01-01' })).status,
    ).toBe(400);

    const revoked = await adminCall<{ state: string; revokeReason: string }>(
      'POST',
      `/entitlements/${grant.data.id}/revoke`,
      {
        reason: 'استرداد',
      },
    );
    expect(revoked.data).toMatchObject({ state: 'revoked', revokeReason: 'استرداد' });
    expect((await t.c.access.scopeAccess(s.id, trackScope(trackId))).hasAccess).toBe(false);
    expect((await studentCall<{ state: string }[]>(s, 'GET', '/access')).data[0]!.state).toBe('revoked');

    // An expired entitlement can be brought back by extending it.
    const general = await adminCall<{ id: string }>('POST', `/students/${s.id}/entitlements`, {
      scopeType: 'subject',
      subjectId,
      accessDurationDays: 3,
    });
    await t.c.db
      .update(entitlements)
      .set({ expiresAt: new Date(Date.now() - 1000) })
      .where(eq(entitlements.id, general.data.id));
    const revived = await adminCall<{ state: string }>('POST', `/entitlements/${general.data.id}/extend`, {
      expiresOn: later,
    });
    expect(revived.data.state).toBe('active');

    const logs = await t.c.db
      .select()
      .from(auditLogs)
      .where(inArray(auditLogs.resourceId, [grant.data.id, general.data.id]));
    expect(logs.map((l) => l.action).sort()).toEqual([
      'entitlement.extended',
      'entitlement.extended',
      'entitlement.extended',
      'entitlement.granted',
      'entitlement.granted',
      'entitlement.revoked',
    ]);

    const detail = await adminCall<{ student: { activeEntitlementCount: number }; entitlements: unknown[] }>(
      'GET',
      `/students/${s.id}`,
    );
    expect(detail.data.student.activeEntitlementCount).toBe(1);
    expect(detail.data.entitlements).toHaveLength(2);
  });

  it('searches students', async () => {
    const s = await student();
    const [u] = await t.c.db.select({ email: users.email }).from(users).where(eq(users.id, s.id));
    const res = await adminCall<{ items: { id: string }[] }>(
      'GET',
      `/students?q=${encodeURIComponent(u!.email)}`,
    );
    expect(res.data.items.map((x) => x.id)).toEqual([s.id]);
    // Cursor pagination (§30.1).
    await student();
    await student();
    const first = await adminCall<{ items: { id: string }[]; nextCursor: string | null }>(
      'GET',
      '/students?limit=2',
    );
    expect(first.data.items).toHaveLength(2);
    expect(first.data.nextCursor).not.toBeNull();
    const second = await adminCall<{ items: { id: string }[] }>(
      'GET',
      `/students?limit=2&cursor=${first.data.nextCursor}`,
    );
    expect(second.data.items.some((x) => first.data.items.some((y) => y.id === x.id))).toBe(false);
    expect((await adminCall('GET', `/students/${randomUUID()}`)).status).toBe(404);
  });
});

describe('canAccessItem matrix (§8.6, §37.1)', () => {
  it('free / promoted / subject-entitled / track-entitled / none × general / track content', async () => {
    const { subjectId, trackId } = await subjectWithTrack();
    const general = { subjectId, teacherTrackId: null };
    const track = { subjectId, teacherTrackId: trackId };
    const none = await student();
    const bySubject = await student();
    const byTrack = await student();
    const promoted = await student();
    await adminCall('POST', `/students/${bySubject.id}/entitlements`, {
      scopeType: 'subject',
      subjectId,
      permanentAccess: true,
    });
    await adminCall('POST', `/students/${byTrack.id}/entitlements`, {
      scopeType: 'teacher_track',
      teacherTrackId: trackId,
      permanentAccess: true,
    });
    const can = (s: Student, item: object) => t.c.access.canAccessItem(s.id, item as never);
    const row = async (s: Student) => [
      await can(s, { ...general, isFree: false }),
      await can(s, { ...track, isFree: false }),
      await can(s, { ...general, isFree: true }),
      await can(s, { ...track, isFree: true }),
    ];
    // [premium general, premium track, free general, free track]
    expect(await row(none)).toEqual([false, false, true, true]);
    expect(await row(bySubject)).toEqual([true, false, true, true]);
    expect(await row(byTrack)).toEqual([false, true, true, true]);

    // A running promotion on the general scope opens it for everyone, and only it.
    const now = Date.now();
    await adminCall('POST', '/promotions', {
      scopeType: 'subject',
      subjectId,
      titleAr: 'عرض',
      startsAt: new Date(now - DAY).toISOString(),
      endsAt: new Date(now + DAY).toISOString(),
    });
    expect(await row(promoted)).toEqual([true, false, true, true]);
    expect(await row(byTrack)).toEqual([true, true, true, true]);
  });
});

describe('promotions (§8.5)', () => {
  it('opens a scope to every student while running, without entitlement rows', async () => {
    const { subjectId, trackId } = await subjectWithTrack();
    const s = await student();
    const now = Date.now();
    const promo = await adminCall<{ id: string; state: string }>('POST', '/promotions', {
      scopeType: 'teacher_track',
      teacherTrackId: trackId,
      titleAr: 'أسبوع مجاني',
      startsAt: new Date(now - DAY).toISOString(),
      endsAt: new Date(now + DAY).toISOString(),
    });
    expect(promo.data.state).toBe('running');
    const page = await studentCall<{ access: Json }>(s, 'GET', `/teacher-tracks/${trackId}`);
    expect(page.data.access).toMatchObject({
      hasAccess: true,
      reason: 'promotion',
      promotionTitleAr: 'أسبوع مجاني',
    });
    expect(await t.c.access.isPromoted(trackScope(trackId))).toBe(true);
    expect(await t.c.access.canAccessItem(s.id, { subjectId, teacherTrackId: null })).toBe(false);
    expect((await t.c.db.select().from(entitlements).where(eq(entitlements.userId, s.id))).length).toBe(0);

    const disabled = await adminCall<{ state: string }>('PATCH', `/promotions/${promo.data.id}`, {
      isActive: false,
    });
    expect(disabled.data.state).toBe('disabled');
    expect((await t.c.access.scopeAccess(s.id, trackScope(trackId))).hasAccess).toBe(false);

    const past = await adminCall<{ state: string }>('POST', '/promotions', {
      scopeType: 'subject',
      subjectId,
      titleAr: 'عرض سابق',
      startsAt: new Date(now - 10 * DAY).toISOString(),
      endsAt: new Date(now - 5 * DAY).toISOString(),
    });
    expect(past.data.state).toBe('ended');
    expect((await t.c.access.scopeAccess(s.id, subjectScope(subjectId))).hasAccess).toBe(false);
    expect((await adminCall('DELETE', `/promotions/${promo.data.id}`)).status).toBe(200);

    const bad = await adminCall('POST', '/promotions', {
      scopeType: 'subject',
      subjectId,
      titleAr: 'x',
      startsAt: new Date(now).toISOString(),
      endsAt: new Date(now - 1).toISOString(),
    });
    expect(bad.status).toBe(400);
  });
});

describe('free rules (§8.4)', () => {
  it('saves one rule per scope and kind with preview counts in the audit log, and queues a recompute', async () => {
    const { subjectId } = await subjectWithTrack();
    const payload = {
      scopeType: 'subject',
      subjectId,
      contentKind: 'all',
      ruleType: 'first_n_items',
      ruleValue: 5,
    };
    const preview = await adminCall<{ freeCount: number; paidCount: number }>(
      'POST',
      '/free-rules/preview',
      payload,
    );
    expect(preview.data).toMatchObject({ freeCount: 0, paidCount: 0 });
    const saved = await adminCall<{ id: string }>('PUT', '/free-rules', payload);
    const again = await adminCall<{ id: string; ruleValue: number }>('PUT', '/free-rules', {
      ...payload,
      ruleValue: 8,
    });
    expect(again.data).toMatchObject({ id: saved.data.id, ruleValue: 8 });
    expect(t.queue.pending.filter((j) => j.name === 'access.recompute-free')).toHaveLength(2);
    await t.queue.drain(t.c.jobHandlers);

    const logs = await t.c.db.select().from(auditLogs).where(eq(auditLogs.resourceId, saved.data.id));
    expect(logs.map((l) => l.action)).toEqual(['free_rule.changed', 'free_rule.changed']);
    expect(logs.map((l) => l.metadata)).toContainEqual(
      expect.objectContaining({
        preview: { freeCount: 0, paidCount: 0 },
        to: { ruleType: 'first_n_items', ruleValue: 8 },
      }),
    );

    expect(
      (await adminCall('PUT', '/free-rules', { ...payload, ruleType: 'manual', ruleValue: 3 })).status,
    ).toBe(400);
    expect(
      (await adminCall('PUT', '/free-rules', { ...payload, ruleType: 'percentage', ruleValue: 101 })).status,
    ).toBe(400);
    expect((await adminCall('DELETE', `/free-rules/${saved.data.id}`)).status).toBe(200);
  });

  it('recomputes rule-sourced items through registered content sources', async () => {
    const { subjectId } = await subjectWithTrack();
    const unit = (
      await adminCall<{ id: string }>('POST', '/units', { subjectId, code: slug('u'), titleAr: 'الوحدة' })
    ).data;
    const lesson = (
      await adminCall<{ id: string }>('POST', '/lessons', {
        subjectId,
        unitId: unit.id,
        code: slug('l'),
        titleAr: 'الدرس',
      })
    ).data;
    const items = [
      { id: 'a', unitId: unit.id, lessonId: lesson.id, sortOrder: 1, isFree: false, manual: false },
      { id: 'b', unitId: unit.id, lessonId: lesson.id, sortOrder: 2, isFree: false, manual: false },
      { id: 'c', unitId: null, lessonId: null, sortOrder: 1, isFree: true, manual: true },
    ];
    let applied: string[] = [];
    const source: FreeContentSource = {
      kind: 'questions',
      items: async () => items,
      applyRule: async (_scope, ids) => {
        applied = [...ids];
      },
    };
    const service = createFreeRuleService({
      db: t.c.db,
      accessRepo: (await import('../src/repositories/access-repository.js')).createAccessRepository(t.c.db),
      structureRepo: t.c.structureRepo,
      audit: t.c.audit,
      jobs: t.queue,
      sources: [source],
    });
    const scope = subjectScope(subjectId);
    const input = {
      scope,
      contentKind: 'questions' as const,
      ruleType: 'first_n_items' as const,
      ruleValue: 1,
    };
    expect(await service.preview(input)).toMatchObject({ freeCount: 2, paidCount: 1 });
    await service.upsert({ adminId: (await t.c.db.select().from(users).limit(1))[0]!.id, ip: null }, input);
    await service.recompute(scope);
    expect(applied).toEqual(['a']);
    expect(await service.isFreeOnPublish(scope, 'questions', 'b')).toBe(false);
  });
});

describe('authorization', () => {
  it('keeps admin access endpoints away from students', async () => {
    const s = await student();
    const res = await t.app.inject({
      method: 'GET',
      url: '/api/v1/admin/coupon-batches',
      headers: { authorization: `Bearer ${s.token}` },
    });
    expect(res.statusCode).toBe(403);
    expect((await t.app.inject({ method: 'GET', url: '/api/v1/access' })).statusCode).toBe(401);
  });
});
