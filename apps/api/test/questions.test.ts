import { randomUUID } from 'node:crypto';
import { eq, sql } from 'drizzle-orm';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { auditLogs, questionAnswers, users } from '@plengo/db';
import { questionSnapshot } from '../src/services/grading.js';
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
type Json = Record<string, unknown>;
type Q = {
  id: string;
  status: string;
  isFree: boolean;
  freeSource: string;
  contentVersion: number;
  unitId: string | null;
  lessonId: string | null;
  options: { id: string; text: string; isCorrect: boolean }[];
  acceptedAnswers: { answerOriginal: string; answerNormalized: string; normalizationVersion: number }[];
};

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
  return { status: res.statusCode, ...body<T>(res) };
}

interface Student {
  id: string;
  token: string;
}
async function student(): Promise<Student> {
  const { email, accessToken } = await tokensFor(t);
  const [u] = await t.c.db.select({ id: users.id }).from(users).where(eq(users.email, email));
  return { id: u!.id, token: accessToken };
}
async function studentCall<T = Json>(s: Student, method: 'GET' | 'POST', url: string, payload?: object) {
  const res = await t.app.inject({
    method,
    url: `/api/v1${url}`,
    headers: { authorization: `Bearer ${s.token}` },
    ...(payload ? { payload } : {}),
  });
  return { status: res.statusCode, raw: res.body, ...body<T>(res) };
}

/** A Grade 12 subject with one unit (two lessons) and a teacher track. */
async function world() {
  const subject = (
    await adminCall<{ id: string }>('POST', '/subjects', {
      educationLevelId: await levelId(t, 'grade-12'),
      code: slug('phys'),
      nameAr: 'الفيزياء',
    })
  ).data;
  const unit = (
    await adminCall<{ id: string }>('POST', '/units', {
      subjectId: subject.id,
      code: slug('u'),
      titleAr: 'الميكانيك',
    })
  ).data;
  const lesson1 = (
    await adminCall<{ id: string }>('POST', '/lessons', {
      subjectId: subject.id,
      unitId: unit.id,
      code: slug('l'),
      titleAr: 'الحركة',
    })
  ).data;
  const lesson2 = (
    await adminCall<{ id: string }>('POST', '/lessons', {
      subjectId: subject.id,
      unitId: unit.id,
      code: slug('l'),
      titleAr: 'القوى',
    })
  ).data;
  const teacher = (
    await adminCall<{ id: string }>('POST', '/teachers', { nameAr: 'أ. أحمد', slug: slug('t') })
  ).data;
  const track = (
    await adminCall<{ id: string }>('POST', '/teacher-tracks', {
      teacherId: teacher.id,
      subjectId: subject.id,
      titleAr: 'مسار',
      slug: slug('track'),
    })
  ).data;
  return {
    subjectId: subject.id,
    unitId: unit.id,
    lesson1: lesson1.id,
    lesson2: lesson2.id,
    trackId: track.id,
  };
}

const mcq = (subjectId: string, extra: Json = {}) => ({
  type: 'mcq',
  subjectId,
  questionText: 'ما وحدة القوة؟',
  explanation: 'النيوتن وحدة القوة في النظام الدولي',
  options: [
    { text: 'النيوتن', isCorrect: true },
    { text: 'الجول', isCorrect: false },
    { text: 'الواط', isCorrect: false },
  ],
  ...extra,
});

async function create(payload: Json) {
  const res = await adminCall<Q>('POST', '/questions', payload);
  if (res.status !== 200) throw new Error(`create failed: ${JSON.stringify(res.error)}`);
  return res.data;
}

describe('admin authoring (§14)', () => {
  it('creates the three types and validates their content', async () => {
    const w = await world();
    const q1 = await create(mcq(w.subjectId, { lessonId: w.lesson1 }));
    // A lesson implies its unit (§6.1).
    expect(q1).toMatchObject({ status: 'draft', unitId: w.unitId, lessonId: w.lesson1, contentVersion: 1 });
    expect(q1.options.filter((o) => o.isCorrect)).toHaveLength(1);

    const tf = await create({
      type: 'true_false',
      subjectId: w.subjectId,
      questionText: 'الضوء أسرع من الصوت',
      trueFalseAnswer: true,
    });
    expect(tf.options.map((o) => [o.text, o.isCorrect])).toEqual([
      ['صح', true],
      ['خطأ', false],
    ]);

    const written = await create({
      type: 'written',
      subjectId: w.subjectId,
      teacherTrackId: w.trackId,
      questionText: 'من صاحب قوانين الحركة؟',
      acceptedAnswers: ['نيوتن', 'إسحاق نيوتن'],
    });
    expect(written.acceptedAnswers.map((a) => a.answerNormalized)).toEqual(['نيوتن', 'اسحاق نيوتن']);
    expect(written.acceptedAnswers[0]!.normalizationVersion).toBe(1);

    const bad = async (payload: Json) => (await adminCall('POST', '/questions', payload)).error?.code;
    expect(await bad(mcq(w.subjectId, { options: [{ text: 'أ', isCorrect: true }] }))).toBe(
      'VALIDATION_ERROR',
    );
    expect(
      await bad(
        mcq(w.subjectId, {
          options: [
            { text: 'أ', isCorrect: true },
            { text: 'ب', isCorrect: true },
          ],
        }),
      ),
    ).toBe('VALIDATION_ERROR');
    expect(await bad({ type: 'true_false', subjectId: w.subjectId, questionText: 'x' })).toBe(
      'VALIDATION_ERROR',
    );
    // Duplicates after normalization are refused so the admin sees them.
    expect(
      await bad({
        type: 'written',
        subjectId: w.subjectId,
        questionText: 'x',
        acceptedAnswers: ['أحمد', 'احمد'],
      }),
    ).toBe('VALIDATION_ERROR');
    expect(
      await bad({ type: 'written', subjectId: w.subjectId, questionText: 'x', acceptedAnswers: ['؟!'] }),
    ).toBe('VALIDATION_ERROR');
  });

  it('keeps unit, lesson and track inside the question subject (§6.1, §7.3)', async () => {
    const a = await world();
    const b = await world();
    const code = async (payload: Json) => (await adminCall('POST', '/questions', payload)).error?.code;
    expect(await code(mcq(a.subjectId, { lessonId: b.lesson1 }))).toBe('VALIDATION_ERROR');
    expect(await code(mcq(a.subjectId, { unitId: b.unitId }))).toBe('VALIDATION_ERROR');
    expect(await code(mcq(a.subjectId, { teacherTrackId: b.trackId }))).toBe('VALIDATION_ERROR');

    // The database refuses it too.
    await expect(
      t.c.db.execute(
        sql`insert into questions (type, subject_id, lesson_id, question_text) values ('mcq', ${a.subjectId}, ${b.lesson1}, 'x')`,
      ),
    ).rejects.toMatchObject({ cause: { code: '23503' } });
    await expect(
      t.c.db.execute(
        sql`insert into questions (type, subject_id, teacher_track_id, question_text) values ('mcq', ${a.subjectId}, ${b.trackId}, 'x')`,
      ),
    ).rejects.toMatchObject({ cause: { code: '23503' } });
  });

  it('bumps content_version on content edits only, and keeps option ids', async () => {
    const w = await world();
    const q = await create(mcq(w.subjectId, { lessonId: w.lesson1 }));
    const moved = await adminCall<Q>('PATCH', `/questions/${q.id}`, { lessonId: w.lesson2 });
    expect(moved.data).toMatchObject({ lessonId: w.lesson2, contentVersion: 1 });

    const edited = await adminCall<Q>('PATCH', `/questions/${q.id}`, {
      options: [
        { id: q.options[0]!.id, text: 'النيوتن', isCorrect: false },
        { id: q.options[1]!.id, text: 'الجول', isCorrect: true },
        { text: 'الباسكال', isCorrect: false },
      ],
    });
    expect(edited.data.contentVersion).toBe(2);
    expect(edited.data.options.map((o) => o.id).slice(0, 2)).toEqual([q.options[0]!.id, q.options[1]!.id]);
    expect(edited.data.options.find((o) => o.isCorrect)?.text).toBe('الجول');

    const same = await adminCall<Q>('PATCH', `/questions/${q.id}`, { questionText: 'ما وحدة القوة؟' });
    expect(same.data.contentVersion).toBe(2);
    expect(
      (await adminCall<Q>('PATCH', `/questions/${q.id}`, { explanation: 'شرح' })).data.contentVersion,
    ).toBe(3);

    const logs = await t.c.db.select().from(auditLogs).where(eq(auditLogs.resourceId, q.id));
    expect(logs.map((l) => l.action)).toContain('question.updated');
  });

  it('previews normalization of accepted answers', async () => {
    const res = await adminCall<{ normalizationVersion: number; items: { normalized: string }[] }>(
      'POST',
      '/questions/normalize',
      { answers: ['دِمَشْق', 'أحمد', '٣٫٥'] },
    );
    expect(res.data.normalizationVersion).toBe(1);
    expect(res.data.items.map((i) => i.normalized)).toEqual(['دمشق', 'احمد', '3.5']);
  });

  it('reorders siblings only, and refuses deleting structure that still has questions', async () => {
    const w = await world();
    const a = await create(mcq(w.subjectId, { lessonId: w.lesson1 }));
    const b = await create(mcq(w.subjectId, { lessonId: w.lesson1, questionText: 'ثاني' }));
    const other = await create(mcq(w.subjectId, { lessonId: w.lesson2 }));
    expect((await adminCall('POST', '/questions/reorder', { ids: [b.id, a.id] })).status).toBe(200);
    const list = await adminCall<{ items: Q[] }>('GET', `/questions?lessonId=${w.lesson1}`);
    expect(list.data.items.map((q) => q.id)).toEqual([b.id, a.id]);
    expect((await adminCall('POST', '/questions/reorder', { ids: [a.id, other.id] })).error?.code).toBe(
      'VALIDATION_ERROR',
    );

    expect((await adminCall('DELETE', `/lessons/${w.lesson2}`)).error?.code).toBe('RESOURCE_IN_USE');
    expect((await adminCall('DELETE', `/questions/${other.id}`)).status).toBe(200);
    expect((await adminCall('DELETE', `/lessons/${w.lesson2}`)).status).toBe(200);
  });
});

describe('free status (§8.4)', () => {
  it('evaluates the rule on publish, supports overrides, and recomputes on rule change', async () => {
    const w = await world();
    await adminCall('PUT', '/free-rules', {
      scopeType: 'subject',
      subjectId: w.subjectId,
      contentKind: 'questions',
      ruleType: 'first_n_items',
      ruleValue: 1,
    });
    await t.queue.drain(t.c.jobHandlers);

    const first = await create(mcq(w.subjectId, { lessonId: w.lesson1, publish: true }));
    const second = await create(
      mcq(w.subjectId, { lessonId: w.lesson1, questionText: 'ثاني', publish: true }),
    );
    expect(first).toMatchObject({ status: 'published', isFree: true, freeSource: 'rule' });
    expect(second.isFree).toBe(false);

    // A new question placed first does not change existing items.
    const unitLevel = await create(
      mcq(w.subjectId, { unitId: w.unitId, questionText: 'عام', publish: true }),
    );
    expect(unitLevel.isFree).toBe(true);
    expect((await adminCall<Q>('GET', `/questions/${first.id}`)).data.isFree).toBe(true);

    const forced = await adminCall<Q>('PUT', `/questions/${second.id}/free`, { mode: 'free' });
    expect(forced.data).toMatchObject({ isFree: true, freeSource: 'manual_override' });

    // Changing the rule recomputes rule-sourced items and leaves overrides alone.
    await adminCall('PUT', '/free-rules', {
      scopeType: 'subject',
      subjectId: w.subjectId,
      contentKind: 'questions',
      ruleType: 'manual',
    });
    await t.queue.drain(t.c.jobHandlers);
    expect((await adminCall<Q>('GET', `/questions/${first.id}`)).data.isFree).toBe(false);
    expect((await adminCall<Q>('GET', `/questions/${unitLevel.id}`)).data.isFree).toBe(false);
    expect((await adminCall<Q>('GET', `/questions/${second.id}`)).data.isFree).toBe(true);

    const back = await adminCall<Q>('PUT', `/questions/${second.id}/free`, { mode: 'rule' });
    expect(back.data).toMatchObject({ isFree: false, freeSource: 'rule' });
    const logs = await t.c.db.select().from(auditLogs).where(eq(auditLogs.resourceId, second.id));
    expect(logs.map((l) => l.action)).toEqual(
      expect.arrayContaining(['question.created', 'question.published', 'question.free_override']),
    );
  });
});

describe('student access (§8.6, §14.3)', () => {
  async function published() {
    const w = await world();
    await adminCall('PUT', '/free-rules', {
      scopeType: 'subject',
      subjectId: w.subjectId,
      contentKind: 'all',
      ruleType: 'first_n_items',
      ruleValue: 1,
    });
    await t.queue.drain(t.c.jobHandlers);
    const free = await create(mcq(w.subjectId, { lessonId: w.lesson1, publish: true }));
    const premium = await create({
      type: 'written',
      subjectId: w.subjectId,
      lessonId: w.lesson1,
      questionText: 'ما عاصمة سوريا؟',
      acceptedAnswers: ['دِمَشْق'],
      publish: true,
    });
    const trackQ = await create({
      type: 'true_false',
      subjectId: w.subjectId,
      teacherTrackId: w.trackId,
      questionText: 'السرعة كمية متجهة',
      trueFalseAnswer: false,
      publish: true,
    });
    const draft = await create(mcq(w.subjectId, { questionText: 'مسودة' }));
    return { w, free, premium, trackQ, draft };
  }

  it('lists metadata for locked questions and never exposes correctness', async () => {
    const { w, free, premium } = await published();
    const s = await student();
    const page = await studentCall<{
      items: { id: string; locked: boolean; questionText: string | null; options: unknown[] | null }[];
      totalCount: number;
      accessibleCount: number;
    }>(s, 'GET', `/questions?subjectId=${w.subjectId}`);
    expect(page.status).toBe(200);
    expect(page.data).toMatchObject({ totalCount: 2, accessibleCount: 1 });
    expect(page.data.items.find((q) => q.id === free.id)).toMatchObject({
      locked: false,
      questionText: 'ما وحدة القوة؟',
    });
    expect(page.data.items.find((q) => q.id === premium.id)).toMatchObject({
      locked: true,
      questionText: null,
      options: null,
    });
    expect(page.raw).not.toContain('isCorrect');
    expect(page.raw).not.toContain('النيوتن وحدة القوة'); // explanation only after grading
    expect(page.raw).not.toContain('دمشق');

    const outline = await studentCall<{ questionCount: { total: number; free: number } }>(
      s,
      'GET',
      `/subjects/${w.subjectId}`,
    );
    expect(outline.data.questionCount).toEqual({ total: 2, free: 1 });

    const locked = await studentCall(s, 'GET', `/questions/${premium.id}`);
    expect(locked.status).toBe(403);
    expect(locked.error?.code).toBe('CONTENT_LOCKED');
    expect(locked.data).toBeNull();
    expect(
      (await studentCall(s, 'POST', `/questions/${premium.id}/check`, { writtenAnswer: 'دمشق' })).error?.code,
    ).toBe('CONTENT_LOCKED');
  });

  it('subject and track entitlements never unlock each other (§37.5)', async () => {
    const { w, premium, trackQ } = await published();
    const s = await student();
    await adminCall('POST', `/students/${s.id}/entitlements`, {
      scopeType: 'subject',
      subjectId: w.subjectId,
      permanentAccess: true,
    });
    expect((await studentCall(s, 'GET', `/questions/${premium.id}`)).status).toBe(200);
    const trackLocked = await studentCall(s, 'GET', `/questions/${trackQ.id}`);
    expect(trackLocked.error?.code).toBe('CONTENT_LOCKED');
    expect(trackLocked.raw).not.toContain('السرعة');

    const other = await student();
    await adminCall('POST', `/students/${other.id}/entitlements`, {
      scopeType: 'teacher_track',
      teacherTrackId: w.trackId,
      permanentAccess: true,
    });
    expect((await studentCall(other, 'GET', `/questions/${trackQ.id}`)).status).toBe(200);
    expect((await studentCall(other, 'GET', `/questions/${premium.id}`)).error?.code).toBe('CONTENT_LOCKED');
    const trackList = await studentCall<{ items: { locked: boolean }[]; accessibleCount: number }>(
      other,
      'GET',
      `/questions?subjectId=${w.subjectId}&teacherTrackId=${w.trackId}`,
    );
    expect(trackList.data.items).toMatchObject([{ locked: false }]);
    expect(trackList.data.accessibleCount).toBe(1);
  });

  it('grades MCQ, true/false and written answers after normalization', async () => {
    const { w, free, premium, trackQ } = await published();
    const s = await student();
    await adminCall('POST', `/students/${s.id}/entitlements`, {
      scopeType: 'subject',
      subjectId: w.subjectId,
      permanentAccess: true,
    });
    await adminCall('POST', `/students/${s.id}/entitlements`, {
      scopeType: 'teacher_track',
      teacherTrackId: w.trackId,
      permanentAccess: true,
    });
    const check = (id: string, payload: Json) =>
      studentCall<{
        isCorrect: boolean;
        correctOptionId: string | null;
        correctAnswer: string | null;
        explanation: string | null;
      }>(s, 'POST', `/questions/${id}/check`, payload);

    const got = await studentCall<{ options: { id: string; text: string }[] }>(
      s,
      'GET',
      `/questions/${free.id}`,
    );
    const correct = got.data.options.find((o) => o.text === 'النيوتن')!.id;
    const wrong = got.data.options.find((o) => o.text === 'الجول')!.id;
    expect((await check(free.id, { selectedOptionId: wrong })).data).toMatchObject({
      isCorrect: false,
      correctOptionId: correct,
      explanation: 'النيوتن وحدة القوة في النظام الدولي',
    });
    expect((await check(free.id, { selectedOptionId: correct })).data.isCorrect).toBe(true);
    expect((await check(free.id, { selectedOptionId: randomUUID() })).error?.code).toBe('VALIDATION_ERROR');
    expect((await check(free.id, { writtenAnswer: 'x' })).error?.code).toBe('VALIDATION_ERROR');

    expect((await check(premium.id, { writtenAnswer: '  دمشق ' })).data).toMatchObject({
      isCorrect: true,
      correctAnswer: 'دِمَشْق',
    });
    expect((await check(premium.id, { writtenAnswer: 'الشام' })).data.isCorrect).toBe(false);
    expect((await check(premium.id, { writtenAnswer: '' })).data.isCorrect).toBe(false);

    const tf = await studentCall<{ options: { id: string; text: string }[] }>(
      s,
      'GET',
      `/questions/${trackQ.id}`,
    );
    const falseId = tf.data.options.find((o) => o.text === 'خطأ')!.id;
    expect((await check(trackQ.id, { selectedOptionId: falseId })).data.isCorrect).toBe(true);
  });

  it('hides drafts, archived questions and questions of hidden subjects', async () => {
    const { w, free, draft } = await published();
    const s = await student();
    expect((await studentCall(s, 'GET', `/questions/${draft.id}`)).status).toBe(404);
    await adminCall('POST', `/questions/${free.id}/status`, { status: 'archived' });
    expect((await studentCall(s, 'GET', `/questions/${free.id}`)).status).toBe(404);
    await adminCall('POST', `/questions/${free.id}/status`, { status: 'published' });
    expect((await studentCall(s, 'GET', `/questions/${free.id}`)).status).toBe(200);
    await adminCall('PATCH', `/subjects/${w.subjectId}`, { isActive: false });
    expect((await studentCall(s, 'GET', `/questions/${free.id}`)).status).toBe(404);
    expect((await studentCall(s, 'GET', `/questions?subjectId=${w.subjectId}`)).status).toBe(404);
  });

  it('keeps admin question endpoints away from students', async () => {
    const s = await student();
    const res = await t.app.inject({
      method: 'GET',
      url: '/api/v1/admin/questions',
      headers: { authorization: `Bearer ${s.token}` },
    });
    expect(res.statusCode).toBe(403);
  });
});

describe('normalization versions and snapshots (§14.5, §14.6)', () => {
  it('regenerates accepted answers stored by another normalizer version', async () => {
    const w = await world();
    const q = await create({
      type: 'written',
      subjectId: w.subjectId,
      questionText: 'x',
      acceptedAnswers: ['أحمد', 'سوريا'],
      publish: true,
    });
    await t.c.db
      .update(questionAnswers)
      .set({ normalizationVersion: 0, answerNormalized: sql`'stale-' || ${questionAnswers.id}` })
      .where(eq(questionAnswers.questionId, q.id));
    // Grading already ignores stale values.
    const loaded = (await t.c.questions.adminGet(q.id)).acceptedAnswers;
    expect(loaded.every((a) => a.normalizationVersion === 0)).toBe(true);
    expect(await t.c.questions.renormalizeAnswers()).toBeGreaterThanOrEqual(2);
    const after = await adminCall<Q>('GET', `/questions/${q.id}`);
    expect(after.data.acceptedAnswers.map((a) => [a.answerNormalized, a.normalizationVersion])).toEqual([
      ['احمد', 1],
      ['سوريا', 1],
    ]);
  });

  it('snapshots what the student saw, including the correct option', async () => {
    const w = await world();
    const q = await create(mcq(w.subjectId));
    const full = (await t.c.questions.adminGet(q.id)) as unknown as Q;
    const row = await (
      await import('../src/repositories/question-repository.js')
    )
      .createQuestionRepository(t.c.db)
      .get(full.id);
    const snap = questionSnapshot(row!);
    expect(snap).toMatchObject({
      questionId: q.id,
      contentVersion: 1,
      type: 'mcq',
      questionText: 'ما وحدة القوة؟',
      explanation: 'النيوتن وحدة القوة في النظام الدولي',
    });
    expect(snap.options.find((o) => o.isCorrect)?.text).toBe('النيوتن');
    // Later edits do not change a stored snapshot.
    await adminCall('PATCH', `/questions/${q.id}`, { questionText: 'نص جديد' });
    expect(snap.questionText).toBe('ما وحدة القوة؟');
  });
});
