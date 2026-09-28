import { randomUUID } from 'node:crypto';
import { eq } from 'drizzle-orm';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { auditLogs, coupons, users } from '@plengo/db';
import {
  body,
  createTestApp,
  enrolledAdminSession,
  levelId,
  registerVerifiedStudent,
  tokensFor,
  type TestContext,
} from './helpers.js';

let t: TestContext;
let admin: Record<string, string>;
let adminId: string;
beforeAll(async () => {
  t = await createTestApp();
  const session = await enrolledAdminSession(t);
  admin = session.headers;
  const [me] = await t.c.db.select({ id: users.id }).from(users).where(eq(users.email, session.email));
  adminId = me!.id;
});
afterAll(async () => {
  await t.close();
});

type Json = Record<string, unknown>;
const slug = (p: string) => `${p}-${randomUUID().slice(0, 8)}`;

async function adminCall<T = Json>(method: 'GET' | 'POST' | 'PUT', url: string, payload?: object) {
  const res = await t.app.inject({
    method,
    url: `/api/v1/admin${url}`,
    headers: admin,
    ...(payload ? { payload } : {}),
  });
  return { status: res.statusCode, ...body<T>(res) };
}

type Hit = { type: string; id: string; title: string; subtitle: string | null; parentId: string | null };
const search = async (q: string) =>
  (await adminCall<{ items: Hit[] }>('GET', `/search?q=${encodeURIComponent(q)}`)).data.items;

describe('global admin search (§26.2)', () => {
  it('finds admins, students, teachers, tracks, subjects, questions, batches and coupons', async () => {
    const tag = randomUUID().slice(0, 6);
    const subject = (
      await adminCall<{ id: string }>('POST', '/subjects', {
        educationLevelId: await levelId(t),
        code: `chem-${tag}`,
        nameAr: `الكيمياء ${tag}`,
      })
    ).data;
    const teacher = (
      await adminCall<{ id: string }>('POST', '/teachers', { nameAr: `أ. خالد ${tag}`, slug: slug('khaled') })
    ).data;
    const track = (
      await adminCall<{ id: string }>('POST', '/teacher-tracks', {
        teacherId: teacher.id,
        subjectId: subject.id,
        titleAr: `مسار الكيمياء ${tag}`,
        slug: slug('track'),
      })
    ).data;
    const question = (
      await adminCall<{ id: string }>('POST', '/questions', {
        type: 'true_false',
        subjectId: subject.id,
        questionText: `الماء مركب كيميائي ${tag}`,
        trueFalseAnswer: true,
      })
    ).data;
    const batch = (
      await adminCall<{ id: string }>('POST', '/coupon-batches', {
        name: `دفعة ${tag}`,
        distributorName: 'مكتبة النور',
        scopeType: 'subject',
        subjectId: subject.id,
        quantity: 2,
        permanentAccess: true,
      })
    ).data;
    await t.queue.drain(t.c.jobHandlers);
    const studentEmail = `searchable-${tag}@example.com`;
    await registerVerifiedStudent(t, studentEmail);

    const hits = await search(tag);
    const types = (type: string) => hits.filter((h) => h.type === type).map((h) => h.id);
    expect(types('subject')).toEqual([subject.id]);
    expect(types('teacher')).toEqual([teacher.id]);
    expect(types('track')).toEqual([track.id]);
    expect(hits.find((h) => h.type === 'track')!.parentId).toBe(teacher.id);
    expect(types('question')).toEqual([question.id]);
    expect(types('batch')).toEqual([batch.id]);
    expect(types('student')).toHaveLength(1);
    expect(hits.find((h) => h.type === 'student')!.subtitle).toBe(studentEmail);

    // Admins by email; the student is not listed as an admin.
    const [me] = await t.c.db.select().from(users).where(eq(users.id, adminId));
    expect((await search(me!.email)).filter((h) => h.type === 'admin').map((h) => h.id)).toEqual([adminId]);

    // Coupons by last four characters, pointing at their batch; an id matches exactly.
    const [code] = await t.c.db.select().from(coupons).where(eq(coupons.batchId, batch.id));
    const byLast4 = (await search(code!.codeLast4)).filter((h) => h.type === 'coupon');
    expect(byLast4.map((h) => h.id)).toContain(code!.id);
    expect(byLast4.find((h) => h.id === code!.id)!.parentId).toBe(batch.id);
    expect((await search(subject.id)).map((h) => h.id)).toContain(subject.id);

    // Wildcards are literal; too-short queries are rejected.
    expect(await search('%%')).toEqual([]);
    expect((await adminCall('GET', '/search?q=a')).status).toBe(400);
  });
});

describe('audit log (§32)', () => {
  it('lists entries newest first with the actor, and filters them', async () => {
    const teacher = (
      await adminCall<{ id: string }>('POST', '/teachers', { nameAr: 'أ. سامر', slug: slug('samer') })
    ).data;
    type Page = {
      items: {
        action: string;
        resourceType: string;
        resourceId: string | null;
        actorAdminId: string | null;
        actorEmail: string | null;
        metadata: Json;
        createdAt: string;
      }[];
      nextCursor: string | null;
    };
    const page = async (query: string) => (await adminCall<Page>('GET', `/audit-logs?${query}`)).data;

    const forTeacher = await page(`resourceId=${teacher.id}`);
    expect(forTeacher.items).toHaveLength(1);
    expect(forTeacher.items[0]).toMatchObject({
      action: 'structure.teacher.created',
      resourceType: 'teacher',
      actorAdminId: adminId,
    });
    expect(forTeacher.items[0]!.actorEmail).toMatch(/@/);

    // Action prefix, actor, and paging.
    const structure = await page(`action=structure.&actorAdminId=${adminId}&limit=1`);
    expect(structure.items).toHaveLength(1);
    expect(structure.items[0]!.action.startsWith('structure.')).toBe(true);
    expect(structure.nextCursor).not.toBeNull();
    const next = await page(
      `action=structure.&actorAdminId=${adminId}&limit=1&cursor=${structure.nextCursor}`,
    );
    expect(next.items[0]!.createdAt <= structure.items[0]!.createdAt).toBe(true);
    // An exact action does not match as a prefix.
    expect((await page('action=structure')).items).toEqual([]);

    // Damascus calendar days: today includes the entry, a past range does not.
    const today = new Intl.DateTimeFormat('en-CA', { timeZone: 'Asia/Damascus' }).format(t.clock.now());
    expect((await page(`resourceId=${teacher.id}&from=${today}&to=${today}`)).items).toHaveLength(1);
    expect((await page(`resourceId=${teacher.id}&to=2020-01-01`)).items).toHaveLength(0);

    const count = (await t.c.db.select().from(auditLogs).where(eq(auditLogs.resourceId, teacher.id))).length;
    expect(count).toBe(1);
    expect((await adminCall('GET', '/audit-logs?from=not-a-date')).status).toBe(400);
  });

  it('is admin-only', async () => {
    const { accessToken } = await tokensFor(t);
    const res = await t.app.inject({
      method: 'GET',
      url: '/api/v1/admin/audit-logs',
      headers: { authorization: `Bearer ${accessToken}` },
    });
    expect(res.statusCode).toBe(403);
  });
});
