import { eq } from 'drizzle-orm';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { entitlements, users } from '@plengo/db';
import {
  seedAccess,
  seedFlashcards,
  seedHome,
  seedLearning,
  seedQuestions,
  seedStructure,
  seedStudentContent,
  seedTeachers,
} from '../src/scripts/seed.js';
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
      return {
        ...access,
        questions: await seedQuestions(t.c),
        decks: await seedFlashcards(t.c),
        quizzes: await seedLearning(t.c),
        studentContent: await seedStudentContent(t.c),
        home: await seedHome(t.c, t.queue),
      };
    };
    const first = await run();
    const second = await run();
    expect(first.codes).toHaveLength(10);
    expect(first.questions).toBe(11);
    expect(second.questions).toBe(0);
    expect(first.decks).toBe(2);
    expect(second.decks).toBe(0);
    expect(first.quizzes).toBe(3);
    expect(first.home).toEqual({ banners: 1, countdowns: 1, notifications: 1 });
    expect(second.home).toEqual({ banners: 0, countdowns: 0, notifications: 0 });
    expect(second.quizzes).toBe(0);
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
    // Quizzes (§40). Neither student is entitled to Grade 12 Physics: the mock exam is locked
    // (all-or-nothing) and the mixed quiz shows only its free questions.
    const list = async (userId: string) =>
      Object.fromEntries(
        (await t.c.quizzes.studentList(userId, { subjectId: g12.id })).map((q) => [q.titleAr, q]),
      );
    const q1 = await list(s1!.id);
    expect(q1['امتحان تجريبي — فيزياء البكالوريا']).toMatchObject({ locked: true, totalCount: 7 });
    expect(q1['اختبار شامل في الفيزياء']).toMatchObject({ totalCount: 7, accessibleCount: 5, locked: false });
    expect(q1['مراجعة درس الحركة']).toMatchObject({ locked: false, isFree: true });
    const mistakes = await t.c.learning.mistakes(s1!.id, { status: 'active' });
    expect(mistakes.activeCount).toBeGreaterThan(0);
    expect(await t.c.learning.bookmarkKeys(s1!.id)).toHaveLength(2);

    // Student 1's private deck (§13.9) and an open report (§21); the second run changes nothing.
    expect(first.studentContent).toMatchObject({ appliedDecks: 1, appliedCards: 3, rejected: [] });
    expect(second.studentContent).toMatchObject({ appliedDecks: 0, appliedCards: 0, rejected: [] });
    expect(await t.c.userContent.listDecks(s1!.id)).toMatchObject([
      { name: 'قوانين الفيزياء', cardCount: 3 },
    ]);
    expect(await t.c.reports.mine(s1!.id)).toMatchObject([{ status: 'open', reason: 'unclear' }]);

    const promos = await t.c.promotions.list();
    expect(promos.filter((p) => p.titleAr === 'عرض تجريبي منتهٍ')).toMatchObject([{ state: 'disabled' }]);
  });
});
