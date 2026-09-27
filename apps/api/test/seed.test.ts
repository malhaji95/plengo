import { eq } from 'drizzle-orm';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { entitlements, users } from '@plengo/db';
import { seedAccess, seedStructure, seedTeachers } from '../src/scripts/seed.js';
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
      return seedAccess(t.c, t.queue);
    };
    const first = await run();
    const second = await run();
    expect(first.codes).toHaveLength(10);
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
    const promos = await t.c.promotions.list();
    expect(promos.filter((p) => p.titleAr === 'عرض تجريبي منتهٍ')).toMatchObject([{ state: 'disabled' }]);
  });
});
