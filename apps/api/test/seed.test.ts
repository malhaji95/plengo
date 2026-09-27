import { eq } from 'drizzle-orm';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { entitlements, users } from '@plengo/db';
import { seedAccess, seedQuestions, seedStructure, seedTeachers } from '../src/scripts/seed.js';
import { createTestApp, type TestContext } from './helpers.js';

let t: TestContext;
beforeAll(async () => {
  t = await createTestApp();
});
afterAll(async () => {
  await t.close();
});

describe('development seed (§40)', () => {
  it('is idempotent and creates the access fixtures', async () => {
    const run = async () => {
      await seedStructure(t.c.db);
      await seedTeachers(t.c.db);
      const access = await seedAccess(t.c, t.queue);
      return { ...access, questions: await seedQuestions(t.c) };
    };
    const first = await run();
    const second = await run();
    expect(first.codes).toHaveLength(10);
    expect(first.questions).toBe(11);
    expect(second.questions).toBe(0);
    expect(second.codes.map((c) => c.code)).toEqual(first.codes.map((c) => c.code));
    for (const { code } of first.codes) expect(code).toMatch(/^[2-9A-Z]{4}-[2-9A-Z]{4}-[2-9A-Z]{2}$/);

    const [s1] = await t.c.db.select().from(users).where(eq(users.email, 'student1@example.com'));
    const [s2] = await t.c.db.select().from(users).where(eq(users.email, 'student2@example.com'));
    const e1 = await t.c.db.select().from(entitlements).where(eq(entitlements.userId, s1!.id));
    const e2 = await t.c.db.select().from(entitlements).where(eq(entitlements.userId, s2!.id));
    expect(e1).toMatchObject([{ isPermanent: true, scopeType: 'subject', status: 'active' }]);
    expect(e2).toMatchObject([{ isPermanent: false, scopeType: 'teacher_track', status: 'active' }]);

    const rules = (await t.c.freeRules.list()).map((r) => [
      r.scope.trackTitleAr ?? r.scope.subjectNameAr,
      r.ruleType,
    ]);
    expect(rules).toContainEqual(['الفيزياء', 'first_n_items']);
    expect(rules).toContainEqual(['أ. سارة — رياضيات تاسع', 'manual']);
    // first_n_items 5 on Grade 12 Physics: five of the seven published general questions are free.
    const physics = await t.c.catalog.subjects({});
    const g12 = physics.find((s) => s.code === 'g12-physics')!;
    expect(
      await t.c.questions.counts({ scopeType: 'subject', subjectId: g12.id, teacherTrackId: null }),
    ).toEqual({
      total: 7,
      free: 5,
    });
    const promos = await t.c.promotions.list();
    expect(promos.filter((p) => p.titleAr === 'عرض تجريبي منتهٍ')).toMatchObject([{ state: 'disabled' }]);
  });
});
