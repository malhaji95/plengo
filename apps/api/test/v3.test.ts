import { randomUUID } from 'node:crypto';
import { and, eq } from 'drizzle-orm';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { mediaFiles, questionStats, userMistakes, userSubjectStats, users } from '@plengo/db';
import { newCardState, schedule } from '@plengo/srs';
import { toCsv } from '../src/lib/tabular.js';
import {
  body,
  createTestApp,
  enrolledAdminSession,
  levelId,
  tokensFor,
  type TestContext,
} from './helpers.js';

/*
 * v3 owner edits (docs/redesign/V3_PLAN.md): question categories, the practice setup, written answers
 * marked correct, free lessons by default, Plengo decks with a locked preview, single-face cards,
 * student deck templates and bookmark grouping.
 */

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
async function call<T = Json>(
  s: Student,
  method: 'GET' | 'POST' | 'PUT' | 'DELETE',
  url: string,
  payload?: object,
) {
  const res = await t.app.inject({
    method,
    url: `/api/v1${url}`,
    headers: { authorization: `Bearer ${s.token}`, 'x-app-platform': 'android' },
    ...(payload ? { payload } : {}),
  });
  return { status: res.statusCode, ...body<T>(res) };
}

async function image(kind: 'flashcard' | 'cover' = 'flashcard') {
  const id = randomUUID();
  const bucket = kind === 'cover' ? 'public' : 'private';
  const variants = {
    full: { key: `test/${kind}/${id}/full.webp`, width: 1080, height: 720, size: 10 },
    thumb: { key: `test/${kind}/${id}/thumb.webp`, width: 360, height: 240, size: 5 },
  };
  for (const v of Object.values(variants))
    await t.storage.put(bucket, v.key, Buffer.from('img'), 'image/webp');
  await t.c.db.insert(mediaFiles).values({
    id,
    bucket,
    storageKey: `test/${kind}/${id}/original`,
    kind,
    mimeType: 'image/png',
    originalSize: 100,
    variants,
    status: 'ready',
  });
  return id;
}

/** A subject with two units (two lessons each), one loose lesson and a teacher track. */
async function world(level = 'grade-12') {
  const subject = (
    await adminCall<{ id: string; code: string }>('POST', '/subjects', {
      educationLevelId: await levelId(t, level),
      code: slug('sub'),
      nameAr: 'الفيزياء',
    })
  ).data;
  const unit = async (titleAr: string) =>
    (await adminCall<{ id: string }>('POST', '/units', { subjectId: subject.id, code: slug('u'), titleAr }))
      .data.id;
  const lesson = async (unitId: string | null, titleAr: string) =>
    (
      await adminCall<{ id: string }>('POST', '/lessons', {
        subjectId: subject.id,
        unitId,
        code: slug('l'),
        titleAr,
      })
    ).data.id;
  const u1 = await unit('الوحدة الأولى');
  const u2 = await unit('الوحدة الثانية');
  const l1 = await lesson(u1, 'الدرس 1');
  const l2 = await lesson(u1, 'الدرس 2');
  const l3 = await lesson(u2, 'الدرس 3');
  const l4 = await lesson(u2, 'الدرس 4');
  const loose = await lesson(null, 'درس حر');
  const teacher = (
    await adminCall<{ id: string }>('POST', '/teachers', { nameAr: 'أ. سامر', slug: slug('t') })
  ).data;
  const track = (
    await adminCall<{ id: string }>('POST', '/teacher-tracks', {
      teacherId: teacher.id,
      subjectId: subject.id,
      titleAr: 'مسار',
      slug: slug('tr'),
    })
  ).data;
  return {
    subjectId: subject.id,
    subjectCode: subject.code,
    u1,
    u2,
    l1,
    l2,
    l3,
    l4,
    loose,
    trackId: track.id,
  };
}

type AdminQ = { id: string; isFree: boolean; categoryId: string | null; categoryNameAr: string | null };
async function question(payload: Json, publish = true) {
  const res = await adminCall<AdminQ>('POST', '/questions', {
    type: 'mcq',
    questionText: `سؤال ${randomUUID().slice(0, 6)}`,
    options: [
      { text: 'أ', isCorrect: true },
      { text: 'ب', isCorrect: false },
    ],
    publish,
    ...payload,
  });
  expect(res.status, JSON.stringify(res.error)).toBe(200);
  return res.data;
}
const written = (payload: Json) =>
  question({ type: 'written', options: undefined, acceptedAnswers: ['الجاذبية'], ...payload });

async function deck(payload: Json, cards = 2, publish = true) {
  const d = (await adminCall<{ id: string }>('POST', '/decks', { titleAr: 'بطاقات', ...payload })).data;
  for (let i = 0; i < cards; i++)
    await adminCall('POST', `/decks/${d.id}/cards`, {
      frontMediaId: await image(),
      backMediaId: await image(),
    });
  if (publish)
    expect((await adminCall('POST', `/decks/${d.id}/status`, { status: 'published' })).status).toBe(200);
  return (await adminCall<{ id: string; isFree: boolean; freeSource: string }>('GET', `/decks/${d.id}`)).data;
}

const grant = (s: Student, scope: Json) =>
  adminCall('POST', `/students/${s.id}/entitlements`, { ...scope, permanentAccess: true });

async function setDefaultFreeLessons(n: number) {
  const res = await adminCall('PUT', '/settings/access', {
    allowTemporaryToPermanentUpgrade: true,
    defaultFreeLessons: n,
  });
  expect(res.status).toBe(200);
  await t.queue.drain(t.c.jobHandlers);
}

// ---------------------------------------------------------------------------------------------

describe('question categories (v3 §3, §5)', () => {
  it('seeds the global defaults and lets admins add per-subject categories with children', async () => {
    const globals = await adminCall<{ code: string; nameAr: string; subjectId: string | null }[]>(
      'GET',
      '/question-categories?globalOnly=true',
    );
    expect(globals.status).toBe(200);
    const codes = globals.data.map((c) => c.code);
    for (const code of ['explain', 'what-results', 'compare', 'order', 'define', 'fill-blank', 'true-false'])
      expect(codes).toContain(code);
    expect(globals.data.find((c) => c.code === 'explain')!.nameAr).toBe('علل');

    const w = await world();
    const explain = globals.data.find((c) => c.code === 'explain') as unknown as { id: string };
    const child = await adminCall<{ id: string; parentId: string; subjectId: string }>(
      'POST',
      '/question-categories',
      { subjectId: w.subjectId, parentId: explain.id, code: 'explain-physics', nameAr: 'علل فيزيائياً' },
    );
    expect(child.status).toBe(200);
    expect(child.data).toMatchObject({ parentId: explain.id, subjectId: w.subjectId });
    // Same code in the same subject → CODE_TAKEN; in another subject it is fine.
    const dup = await adminCall('POST', '/question-categories', {
      subjectId: w.subjectId,
      code: 'explain-physics',
      nameAr: 'مكرر',
    });
    expect(dup.error?.code).toBe('CODE_TAKEN');
    const other = await world();
    expect(
      (
        await adminCall('POST', '/question-categories', {
          subjectId: other.subjectId,
          code: 'explain-physics',
          nameAr: 'آخر',
        })
      ).status,
    ).toBe(200);
    // A parent of another subject, and a cycle, are refused.
    const foreign = await adminCall<{ id: string }>('POST', '/question-categories', {
      subjectId: other.subjectId,
      code: slug('x'),
      nameAr: 'أجنبي',
    });
    expect(
      (
        await adminCall('POST', '/question-categories', {
          subjectId: w.subjectId,
          parentId: foreign.data.id,
          code: slug('y'),
          nameAr: 'ابن',
        })
      ).status,
    ).toBe(400);
    const grand = await adminCall<{ id: string }>('POST', '/question-categories', {
      subjectId: w.subjectId,
      parentId: child.data.id,
      code: slug('g'),
      nameAr: 'حفيد',
    });
    expect(
      (await adminCall('PATCH', `/question-categories/${child.data.id}`, { parentId: grand.data.id })).status,
    ).toBe(400);

    // The subject's list has the globals and its own, parents before children.
    const list = await adminCall<{ id: string }[]>('GET', `/question-categories?subjectId=${w.subjectId}`);
    const ids = list.data.map((c) => c.id);
    expect(ids).toContain(child.data.id);
    expect(ids).not.toContain(foreign.data.id);
    expect(ids.indexOf(explain.id)).toBeLessThan(ids.indexOf(child.data.id));
    expect(ids.indexOf(child.data.id)).toBeLessThan(ids.indexOf(grand.data.id));

    // Deleting a category that has children is refused.
    expect((await adminCall('DELETE', `/question-categories/${child.data.id}`)).error?.code).toBe(
      'RESOURCE_IN_USE',
    );
  });

  it('files questions under categories; admin and student lists filter by them (children included)', async () => {
    const w = await world();
    const parent = (
      await adminCall<{ id: string }>('POST', '/question-categories', {
        subjectId: w.subjectId,
        code: slug('p'),
        nameAr: 'قارن',
      })
    ).data;
    const kid = (
      await adminCall<{ id: string }>('POST', '/question-categories', {
        subjectId: w.subjectId,
        parentId: parent.id,
        code: slug('k'),
        nameAr: 'قارن بين قوتين',
      })
    ).data;
    const q1 = await question({ subjectId: w.subjectId, lessonId: w.l1, categoryId: parent.id });
    const q2 = await question({ subjectId: w.subjectId, lessonId: w.l1, categoryId: kid.id });
    const q3 = await question({ subjectId: w.subjectId, lessonId: w.l1 });
    await question({ subjectId: w.subjectId, lessonId: w.l2, categoryId: kid.id });
    expect(q1.categoryNameAr).toBe('قارن');

    // A category of another subject cannot be used.
    const other = await world();
    const foreign = (
      await adminCall<{ id: string }>('POST', '/question-categories', {
        subjectId: other.subjectId,
        code: slug('f'),
        nameAr: 'غريب',
      })
    ).data;
    const bad = await adminCall('POST', '/questions', {
      type: 'mcq',
      subjectId: w.subjectId,
      categoryId: foreign.id,
      questionText: 'س',
      options: [
        { text: 'أ', isCorrect: true },
        { text: 'ب', isCorrect: false },
      ],
    });
    expect(bad.status).toBe(400);

    // Moving a question to another category is placement only (no version bump).
    const moved = await adminCall<AdminQ & { contentVersion: number }>('PATCH', `/questions/${q3.id}`, {
      categoryId: kid.id,
    });
    expect(moved.data).toMatchObject({ categoryId: kid.id, contentVersion: 1 });
    await adminCall('PATCH', `/questions/${q3.id}`, { categoryId: null });

    const adminList = await adminCall<{ items: { id: string }[] }>(
      'GET',
      `/questions?subjectId=${w.subjectId}&categoryId=${parent.id}`,
    );
    expect(adminList.data.items).toHaveLength(3);
    const uncategorized = await adminCall<{ items: { id: string }[] }>(
      'GET',
      `/questions?subjectId=${w.subjectId}&uncategorized=true`,
    );
    expect(uncategorized.data.items.map((i) => i.id)).toEqual([q3.id]);

    const s = await student();
    const page = await call<{ items: { id: string; categoryId: string | null }[]; totalCount: number }>(
      s,
      'GET',
      `/questions?subjectId=${w.subjectId}&lessonId=${w.l1}&categoryIds=${kid.id}`,
    );
    expect(page.status).toBe(200);
    expect(page.data.items.map((i) => i.id)).toEqual([q2.id]);
    expect(page.data.items[0]!.categoryId).toBe(kid.id);
    const both = await call<{ items: { id: string }[] }>(
      s,
      'GET',
      `/questions?subjectId=${w.subjectId}&lessonId=${w.l1}&categoryIds=${parent.id}`,
    );
    expect(both.data.items.map((i) => i.id).sort()).toEqual([q1.id, q2.id].sort());
    expect((await call(s, 'GET', `/questions?subjectId=${w.subjectId}&categoryIds=nope`)).status).toBe(400);

    // Lesson view: per-category counts for the lesson (none of them free, the student has no access).
    const cats = await call<{
      items: { id: string; questionCount: number; accessibleCount: number; subjectId: string | null }[];
      uncategorized: { questionCount: number; accessibleCount: number };
    }>(s, 'GET', `/question-categories?subjectId=${w.subjectId}&lessonId=${w.l1}`);
    expect(cats.status).toBe(200);
    expect(cats.data.items.find((c) => c.id === parent.id)).toMatchObject({
      questionCount: 1,
      accessibleCount: 0,
    });
    expect(cats.data.items.find((c) => c.id === kid.id)).toMatchObject({ questionCount: 1 });
    expect(cats.data.uncategorized.questionCount).toBe(1);
    expect(cats.data.items.some((c) => c.subjectId === null)).toBe(true);
    await grant(s, { scopeType: 'subject', subjectId: w.subjectId });
    const opened = await call<{ items: { id: string; accessibleCount: number }[] }>(
      s,
      'GET',
      `/question-categories?subjectId=${w.subjectId}`,
    );
    expect(opened.data.items.find((c) => c.id === kid.id)!.accessibleCount).toBe(2);

    // Deleting a leaf category leaves its questions uncategorized.
    expect((await adminCall('DELETE', `/question-categories/${kid.id}`)).status).toBe(200);
    expect((await adminCall<AdminQ>('GET', `/questions/${q2.id}`)).data.categoryId).toBeNull();
  });

  it('imports and exports category_code; an unknown code is a row error', async () => {
    const w = await world();
    const own = (
      await adminCall<{ id: string; code: string }>('POST', '/question-categories', {
        subjectId: w.subjectId,
        code: slug('own'),
        nameAr: 'خاص',
      })
    ).data;
    const header = [
      'education_level_code',
      'subject_code',
      'unit_code',
      'lesson_code',
      'teacher_track_code',
      'question',
      'correct_answer',
      'category_code',
    ];
    const upload = async (rows: string[][]) => {
      const created = await adminCall<{ id: string }>('POST', '/imports', {
        kind: 'true_false',
        format: 'csv',
        fileName: 'q.csv',
        contentBase64: toCsv({ header, rows }).toString('base64'),
      });
      await t.queue.drain(t.c.jobHandlers);
      return (
        await adminCall<{
          id: string;
          status: string;
          errorCount: number;
          errors: { field: string | null }[];
        }>('GET', `/imports/${created.data.id}`)
      ).data;
    };
    const failed = await upload([['grade-12', w.subjectCode, '', '', '', 'سؤال', 'صح', 'no-such-code']]);
    expect(failed.errorCount).toBe(1);
    expect(failed.errors[0]!.field).toBe('category_code');

    const job = await upload([
      ['grade-12', w.subjectCode, '', '', '', 'سؤال عام', 'صح', 'true-false'],
      ['grade-12', w.subjectCode, '', '', '', 'سؤال خاص', 'خطأ', own.code],
      ['grade-12', w.subjectCode, '', '', '', 'بلا تصنيف', 'صح', ''],
    ]);
    expect(job.errorCount).toBe(0);
    expect((await adminCall('POST', `/imports/${job.id}/confirm`, { publish: false })).status).toBe(200);
    await t.queue.drain(t.c.jobHandlers);
    const list = await adminCall<{
      items: { questionText: string; categoryId: string | null; categoryNameAr: string | null }[];
    }>('GET', `/questions?subjectId=${w.subjectId}`);
    const byText = new Map(list.data.items.map((q) => [q.questionText, q]));
    expect(byText.get('سؤال عام')!.categoryNameAr).toBe('صح أم خطأ');
    expect(byText.get('سؤال خاص')!.categoryId).toBe(own.id);
    expect(byText.get('بلا تصنيف')!.categoryId).toBeNull();

    const res = await t.app.inject({
      method: 'GET',
      url: `/api/v1/admin/questions/export?kind=true_false&format=csv&subjectId=${w.subjectId}`,
      headers: admin,
    });
    expect(res.statusCode).toBe(200);
    const csv = res.body;
    expect(csv.split('\n')[0]).toContain('category_code');
    expect(csv).toContain(own.code);
    expect(csv).toContain('true-false');
  });
});

describe('practice setup (v3 §5)', () => {
  it('draws from several lessons, categories and types; «all» takes every match', async () => {
    const w = await world();
    const cat = (
      await adminCall<{ id: string }>('POST', '/question-categories', {
        subjectId: w.subjectId,
        code: slug('c'),
        nameAr: 'عرّف',
      })
    ).data;
    const inL1 = await question({ subjectId: w.subjectId, lessonId: w.l1, categoryId: cat.id });
    const inL3 = await question({ subjectId: w.subjectId, lessonId: w.l3, categoryId: cat.id });
    const writtenL3 = await written({ subjectId: w.subjectId, lessonId: w.l3, categoryId: cat.id });
    await question({ subjectId: w.subjectId, lessonId: w.l1 }); // no category
    await question({ subjectId: w.subjectId, lessonId: w.l2, categoryId: cat.id }); // other lesson
    const s = await student();
    await grant(s, { scopeType: 'subject', subjectId: w.subjectId });

    const start = (filters: Json) =>
      call<{ attempt: { totalCount: number; filters: Json }; questions: { questionId: string }[] }>(
        s,
        'POST',
        '/attempts',
        {
          clientAttemptId: randomUUID(),
          source: 'random',
          mode: 'practice',
          filters: { subjectId: w.subjectId, ...filters },
        },
      );
    const all = await start({ lessonIds: [w.l1, w.l3], categoryIds: [cat.id], allQuestions: true });
    expect(all.status).toBe(200);
    expect(all.data.questions.map((q) => q.questionId).sort()).toEqual(
      [inL1.id, inL3.id, writtenL3.id].sort(),
    );
    expect(all.data.attempt.filters).toMatchObject({ lessonIds: [w.l1, w.l3], allQuestions: true });

    const mcqOnly = await start({
      lessonIds: [w.l1, w.l3],
      categoryIds: [cat.id],
      types: ['mcq'],
      count: 10,
    });
    expect(mcqOnly.data.questions.map((q) => q.questionId).sort()).toEqual([inL1.id, inL3.id].sort());
    const two = await start({ lessonIds: [w.l1, w.l2, w.l3], count: 2 });
    expect(two.data.attempt.totalCount).toBe(2);
    expect((await start({ lessonIds: [w.l4] })).error?.code).toBe('VALIDATION_ERROR');
  });
});

describe('written answers marked correct by the student (v3 §5)', () => {
  async function setup() {
    const w = await world();
    const q = await written({ subjectId: w.subjectId, lessonId: w.l1 });
    const mcq = await question({ subjectId: w.subjectId, lessonId: w.l1 });
    const s = await student();
    await grant(s, { scopeType: 'subject', subjectId: w.subjectId });
    return { w, q, mcq, s };
  }
  const startPractice = (s: Student, subjectId: string, mode: 'practice' | 'exam' = 'practice') =>
    call<{ attempt: { id: string }; questions: { questionId: string }[] }>(s, 'POST', '/attempts', {
      clientAttemptId: randomUUID(),
      source: 'random',
      mode,
      filters: { subjectId },
    });
  const mistake = async (userId: string, questionId: string) =>
    (
      await t.c.db
        .select()
        .from(userMistakes)
        .where(and(eq(userMistakes.userId, userId), eq(userMistakes.questionId, questionId)))
    )[0];
  const subjectStats = async (userId: string, subjectId: string) =>
    (
      await t.c.db
        .select()
        .from(userSubjectStats)
        .where(and(eq(userSubjectStats.userId, userId), eq(userSubjectStats.subjectId, subjectId)))
    )[0];

  it('counts a wrong written answer as correct: answer, score, mistake bank and statistics', async () => {
    const { w, q, mcq, s } = await setup();
    const a = await startPractice(s, w.subjectId);
    const id = a.data.attempt.id;
    const wrong = await call<{ isCorrect: boolean }>(s, 'POST', `/attempts/${id}/answers/${q.id}/check`, {
      writtenAnswer: 'قوة الجذب',
    });
    expect(wrong.data.isCorrect).toBe(false);
    expect((await mistake(s.id, q.id))?.status).toBe('active');
    expect(await subjectStats(s.id, w.subjectId)).toMatchObject({ answered: 1, correct: 0 });

    // Not for multiple-choice questions, nor before grading.
    expect((await call(s, 'POST', `/attempts/${id}/answers/${mcq.id}/mark-correct`)).status).toBe(400);
    await call(s, 'POST', `/attempts/${id}/answers/${mcq.id}/check`, {
      selectedOptionId: (
        await adminCall<{ options: { id: string; isCorrect: boolean }[] }>('GET', `/questions/${mcq.id}`)
      ).data.options.find((o) => !o.isCorrect)!.id,
    });
    expect((await call(s, 'POST', `/attempts/${id}/answers/${mcq.id}/mark-correct`)).status).toBe(400);

    const marked = await call<{
      questionId: string;
      result: { isCorrect: boolean; correctAnswer: string };
      attempt: { status: string };
    }>(s, 'POST', `/attempts/${id}/answers/${q.id}/mark-correct`);
    expect(marked.status).toBe(200);
    expect(marked.data.result).toMatchObject({ isCorrect: true, correctAnswer: 'الجاذبية' });
    expect(await mistake(s.id, q.id)).toBeUndefined();
    expect(await subjectStats(s.id, w.subjectId)).toMatchObject({ answered: 2, correct: 1 });
    const [qs] = await t.c.db.select().from(questionStats).where(eq(questionStats.questionId, q.id));
    expect(qs).toMatchObject({ attemptCount: 1, correctCount: 1 });
    // Idempotent.
    expect((await call(s, 'POST', `/attempts/${id}/answers/${q.id}/mark-correct`)).status).toBe(200);
    expect(await subjectStats(s.id, w.subjectId)).toMatchObject({ answered: 2, correct: 1 });

    const view = await call<{
      questions: { questionId: string; markedCorrectByStudent: boolean; result: { isCorrect: boolean } }[];
    }>(s, 'GET', `/attempts/${id}`);
    expect(view.data.questions.find((x) => x.questionId === q.id)).toMatchObject({
      markedCorrectByStudent: true,
      result: { isCorrect: true },
    });
    const submitted = await call<{ attempt: { correctCount: number; scorePercent: number } }>(
      s,
      'POST',
      `/attempts/${id}/submit`,
      { answers: [] },
    );
    expect(submitted.data.attempt).toMatchObject({ correctCount: 1, scorePercent: 50 });
  });

  it('after submission it raises the score; a mistake renewed by the wrong answer counts a correct one', async () => {
    const { w, q, s } = await setup();
    // An earlier wrong answer: the mistake exists before this attempt.
    await call(s, 'POST', `/questions/${q.id}/check`, { writtenAnswer: 'x' });
    const first = await startPractice(s, w.subjectId);
    await call(s, 'POST', `/attempts/${first.data.attempt.id}/answers/${q.id}/check`, {
      writtenAnswer: 'خطأ',
    });
    await call(s, 'POST', `/attempts/${first.data.attempt.id}/submit`, { answers: [] });
    expect((await mistake(s.id, q.id))?.wrongCount).toBe(1);

    const second = await startPractice(s, w.subjectId);
    const id = second.data.attempt.id;
    await call(s, 'POST', `/attempts/${id}/answers/${q.id}/check`, { writtenAnswer: 'خطأ ثانٍ' });
    const done = await call<{ attempt: { correctCount: number; scorePercent: number } }>(
      s,
      'POST',
      `/attempts/${id}/submit`,
      { answers: [] },
    );
    expect(done.data.attempt.correctCount).toBe(0);
    expect((await mistake(s.id, q.id))?.wrongCount).toBe(2);
    const marked = await call<{ attempt: { correctCount: number; scorePercent: number } }>(
      s,
      'POST',
      `/attempts/${id}/answers/${q.id}/mark-correct`,
    );
    expect(marked.data.attempt).toMatchObject({ correctCount: 1, scorePercent: 50 });
    expect(await mistake(s.id, q.id)).toMatchObject({ wrongCount: 1, correctStreak: 1, status: 'active' });
  });

  it('is refused in exam mode', async () => {
    const { w, q, s } = await setup();
    const exam = await startPractice(s, w.subjectId, 'exam');
    const id = exam.data.attempt.id;
    await call(s, 'POST', `/attempts/${id}/submit`, {
      answers: [{ questionId: q.id, writtenAnswer: 'خطأ' }],
    });
    const res = await call(s, 'POST', `/attempts/${id}/answers/${q.id}/mark-correct`);
    expect(res.status).toBe(400);
    expect(res.error?.code).toBe('VALIDATION_ERROR');
  });
});

describe('free lessons by default (v3 §3)', () => {
  afterAll(async () => {
    await setDefaultFreeLessons(0);
  });

  it('makes content of the first N lessons free when a scope has no rule; rules and overrides win', async () => {
    const w = await world();
    const ql1 = await question({ subjectId: w.subjectId, lessonId: w.l1 });
    const ql2 = await question({ subjectId: w.subjectId, lessonId: w.l2 });
    const ql3 = await question({ subjectId: w.subjectId, lessonId: w.l3 });
    const qLoose = await question({ subjectId: w.subjectId, lessonId: w.loose });
    const qUnit = await question({ subjectId: w.subjectId, unitId: w.u1 });
    const qManual = await question({ subjectId: w.subjectId, lessonId: w.l3 });
    await adminCall('PUT', `/questions/${qManual.id}/free`, { mode: 'free' });
    const qPaid = await question({ subjectId: w.subjectId, lessonId: w.l1 });
    await adminCall('PUT', `/questions/${qPaid.id}/free`, { mode: 'paid' });
    const dl2 = await deck({ subjectId: w.subjectId, lessonId: w.l2 });
    const dl4 = await deck({ subjectId: w.subjectId, lessonId: w.l4 });
    const quizId = (
      await adminCall<{ quiz: { id: string } }>('POST', '/quizzes', {
        subjectId: w.subjectId,
        lessonId: w.l1,
        titleAr: 'اختبار الدرس',
        questionIds: [ql1.id],
      })
    ).data.quiz.id;
    expect((await adminCall('POST', `/quizzes/${quizId}/status`, { status: 'published' })).status).toBe(200);
    const trackQ1 = await question({ subjectId: w.subjectId, teacherTrackId: w.trackId, lessonId: w.l1 });
    const trackQ3 = await question({ subjectId: w.subjectId, teacherTrackId: w.trackId, lessonId: w.l3 });

    const isFree = async (id: string) => (await adminCall<AdminQ>('GET', `/questions/${id}`)).data.isFree;
    expect(await isFree(ql1.id)).toBe(false);

    await setDefaultFreeLessons(2);
    expect(await isFree(ql1.id)).toBe(true);
    expect(await isFree(ql2.id)).toBe(true);
    expect(await isFree(ql3.id)).toBe(false);
    expect(await isFree(qLoose.id)).toBe(false);
    expect(await isFree(qUnit.id)).toBe(false);
    expect(await isFree(qManual.id)).toBe(true); // manual override
    expect(await isFree(qPaid.id)).toBe(false); // manual override
    expect(await isFree(trackQ1.id)).toBe(true); // each track follows the default too
    expect(await isFree(trackQ3.id)).toBe(false);
    expect((await adminCall<{ isFree: boolean }>('GET', `/decks/${dl2.id}`)).data.isFree).toBe(true);
    expect((await adminCall<{ isFree: boolean }>('GET', `/decks/${dl4.id}`)).data.isFree).toBe(false);
    expect(
      (await adminCall<{ quiz: { isFree: boolean } }>('GET', `/quizzes/${quizId}`)).data.quiz.isFree,
    ).toBe(true);

    // Newly published content follows the default; loose lessons come after the units.
    const later = await question({ subjectId: w.subjectId, lessonId: w.l2 });
    expect(later.isFree).toBe(true);
    await setDefaultFreeLessons(5);
    expect(await isFree(qLoose.id)).toBe(true);
    await setDefaultFreeLessons(2);

    // Students see it through the usual access computation.
    const s = await student();
    const page = await call<{ items: { id: string; locked: boolean }[]; accessibleCount: number }>(
      s,
      'GET',
      `/questions?subjectId=${w.subjectId}`,
    );
    const locked = new Map(page.data.items.map((i) => [i.id, i.locked]));
    expect(locked.get(ql1.id)).toBe(false);
    expect(locked.get(ql3.id)).toBe(true);
    const decks = await call<{ id: string; locked: boolean }[]>(s, 'GET', `/decks?subjectId=${w.subjectId}`);
    expect(decks.data.find((d) => d.id === dl2.id)!.locked).toBe(false);
    expect(decks.data.find((d) => d.id === dl4.id)!.locked).toBe(true);
    const quizzes = await call<{ id: string; locked: boolean }[]>(
      s,
      'GET',
      `/quizzes?subjectId=${w.subjectId}`,
    );
    expect(quizzes.data.find((z) => z.id === quizId)!.locked).toBe(false);
    expect((await call(s, 'GET', `/questions/${ql1.id}`)).status).toBe(200);
    expect((await call(s, 'GET', `/questions/${ql3.id}`)).error?.code).toBe('CONTENT_LOCKED');

    // An explicit rule (even «manual») replaces the default for its kind only.
    const rule = await adminCall<{ id: string }>('PUT', '/free-rules', {
      scopeType: 'subject',
      subjectId: w.subjectId,
      contentKind: 'questions',
      ruleType: 'manual',
    });
    expect(rule.status).toBe(200);
    await t.queue.drain(t.c.jobHandlers);
    expect(await isFree(ql1.id)).toBe(false);
    expect(await isFree(qManual.id)).toBe(true);
    expect((await adminCall<{ isFree: boolean }>('GET', `/decks/${dl2.id}`)).data.isFree).toBe(true);
    expect(await isFree(trackQ1.id)).toBe(true); // the track has no rule
    // Removing the rule falls back to the default again.
    await adminCall('DELETE', `/free-rules/${rule.data.id}`);
    await t.queue.drain(t.c.jobHandlers);
    expect(await isFree(ql1.id)).toBe(true);

    // Offline packs use the same flags: without access only the free deck (in unit 1) is offered.
    const catalog = await call<{ packs: { kind: string; unitId: string | null; itemCount: number }[] }>(
      s,
      'GET',
      `/offline/catalog/scope?subjectId=${w.subjectId}`,
    );
    expect(catalog.status).toBe(200);
    const deckPacks = catalog.data.packs.filter((p) => p.kind === 'decks');
    expect(deckPacks).toEqual([expect.objectContaining({ unitId: w.u1, itemCount: 3 })]);
  });
});

describe('Plengo decks and the locked preview (v3 §6)', () => {
  it('lists the level’s decks grouped by subject and previews five cards of a locked deck', async () => {
    const w = await world('grade-9');
    const cover = await image('cover');
    const locked = await deck({ subjectId: w.subjectId, lessonId: w.l3, coverMediaId: cover }, 7);
    const free = await deck({ subjectId: w.subjectId, lessonId: w.l1 }, 2);
    await adminCall('PUT', `/decks/${free.id}/free`, { mode: 'free' });
    await deck({ subjectId: w.subjectId, teacherTrackId: w.trackId }, 1); // track decks are not listed
    await deck({ subjectId: w.subjectId }, 1, false); // drafts neither

    const s = await student();
    const list = await call<{
      groups: {
        subjectId: string;
        subjectNameAr: string;
        decks: { id: string; locked: boolean; isFree: boolean; cardCount: number; coverUrl: string | null }[];
      }[];
    }>(s, 'GET', `/decks/plengo?educationLevelId=${await levelId(t, 'grade-9')}&subjectId=${w.subjectId}`);
    expect(list.status).toBe(200);
    expect(list.data.groups).toHaveLength(1);
    const g = list.data.groups[0]!;
    expect(g).toMatchObject({ subjectId: w.subjectId, subjectNameAr: 'الفيزياء' });
    expect(g.decks.map((d) => d.id).sort()).toEqual([locked.id, free.id].sort());
    expect(g.decks.find((d) => d.id === locked.id)).toMatchObject({ locked: true, cardCount: 7 });
    expect(g.decks.find((d) => d.id === locked.id)!.coverUrl).toBeTruthy();
    expect(g.decks.find((d) => d.id === free.id)).toMatchObject({ locked: false, isFree: true });
    // The student's own level (grade-12) has no such subject.
    const mine = await call<{ groups: { subjectId: string }[] }>(s, 'GET', '/decks/plengo');
    expect(mine.data.groups.some((x) => x.subjectId === w.subjectId)).toBe(false);

    const preview = await call<{
      cards: unknown[];
      previewOnly: boolean;
      previewLimit: number | null;
      deck: { locked: boolean };
    }>(s, 'GET', `/decks/${locked.id}/cards`);
    expect(preview.status).toBe(200);
    expect(preview.data).toMatchObject({ previewOnly: true, previewLimit: 5, deck: { locked: true } });
    expect(preview.data.cards).toHaveLength(5);
    await grant(s, { scopeType: 'subject', subjectId: w.subjectId });
    const full = await call<{ cards: unknown[]; previewOnly: boolean; previewLimit: number | null }>(
      s,
      'GET',
      `/decks/${locked.id}/cards`,
    );
    expect(full.data).toMatchObject({ previewOnly: false, previewLimit: null });
    expect(full.data.cards).toHaveLength(7);
  });
});

describe('single-face cards (v3 §6)', () => {
  it('creates cards without a back (single and bulk); students get back: null and SRS works', async () => {
    const w = await world();
    const d = (
      await adminCall<{ id: string }>('POST', '/decks', { subjectId: w.subjectId, titleAr: 'جاهزة' })
    ).data;
    const single = await adminCall<{ id: string; back: unknown }>('POST', `/decks/${d.id}/cards`, {
      frontMediaId: await image(),
    });
    expect(single.status).toBe(200);
    expect(single.data.back).toBeNull();
    const bulk = await adminCall<{ id: string; back: unknown }[]>('POST', `/decks/${d.id}/cards/bulk`, {
      cards: [
        { frontMediaId: await image(), backMediaId: null },
        { frontMediaId: await image(), backMediaId: await image() },
      ],
    });
    expect(bulk.status).toBe(200);
    expect(bulk.data.map((c) => c.back === null)).toEqual([true, false]);
    // A double-face card can lose its back, and get one again.
    const twoFaced = bulk.data[1]!;
    expect(
      (await adminCall<{ back: unknown }>('PATCH', `/cards/${twoFaced.id}`, { backMediaId: null })).data.back,
    ).toBeNull();
    expect(
      (await adminCall<{ back: unknown }>('PATCH', `/cards/${twoFaced.id}`, { backMediaId: await image() }))
        .data.back,
    ).not.toBeNull();
    await adminCall('POST', `/decks/${d.id}/status`, { status: 'published' });
    await adminCall('PUT', `/decks/${d.id}/free`, { mode: 'free' });

    const s = await student();
    const cards = await call<{ cards: { id: string; back: unknown; front: { fullUrl: string } }[] }>(
      s,
      'GET',
      `/decks/${d.id}/cards`,
    );
    expect(cards.data.cards).toHaveLength(3);
    expect(cards.data.cards[0]!.back).toBeNull();
    expect(cards.data.cards[0]!.front.fullUrl).toBeTruthy();

    const at = Date.now() - 60_000;
    const base = newCardState(at);
    const next = schedule(base, 'good', at, single.data.id);
    const iso = (x: typeof base) => ({
      ...x,
      dueAt: new Date(x.dueAt).toISOString(),
      lastReviewedAt: x.lastReviewedAt === null ? null : new Date(x.lastReviewedAt).toISOString(),
    });
    const sync = await call<{ acceptedLogs: number }>(s, 'POST', '/srs/sync', {
      logs: [
        {
          id: randomUUID(),
          flashcardId: single.data.id,
          rating: 'good',
          stateBefore: iso(base),
          stateAfter: iso(next),
          reviewedAt: new Date(at).toISOString(),
        },
      ],
      states: [],
    });
    expect(sync.status).toBe(200);
    expect(sync.data.acceptedLogs).toBe(1);

    // Offline packs carry the card with no back image.
    const catalog = await call<{ packs: { kind: string; packKey: string }[] }>(
      s,
      'GET',
      `/offline/catalog/scope?subjectId=${w.subjectId}`,
    );
    const deckPack = catalog.data.packs.find((p) => p.kind === 'decks')!;
    const items = await call<{ items: { type: string; card: { id: string; back: unknown } | null }[] }>(
      s,
      'GET',
      `/offline/packs/${deckPack.packKey}/items`,
    );
    expect(items.status).toBe(200);
    const offlineCards = items.data.items.filter((i) => i.type === 'card');
    expect(offlineCards).toHaveLength(3);
    expect(offlineCards.find((i) => i.card!.id === single.data.id)!.card!.back).toBeNull();
  });
});

describe('student deck templates (v3 §7)', () => {
  it('syncs subjectId and templateKey and refuses malformed keys', async () => {
    const w = await world();
    const s = await student();
    const now = new Date().toISOString();
    const deckId = randomUUID();
    const res = await call<{ appliedDecks: number }>(s, 'POST', '/my-decks/sync', {
      decks: [
        {
          id: deckId,
          name: 'مجموعة الفيزياء',
          subjectId: w.subjectId,
          templateKey: 'physics',
          sortOrder: 0,
          createdAt: now,
          updatedAt: now,
        },
      ],
      cards: [],
    });
    expect(res.data.appliedDecks).toBe(1);
    const decks = await call<{ id: string; subjectId: string; templateKey: string | null }[]>(
      s,
      'GET',
      '/my-decks',
    );
    expect(decks.data.find((d) => d.id === deckId)).toMatchObject({
      subjectId: w.subjectId,
      templateKey: 'physics',
    });
    const changes = await call<{ decks: { id: string; templateKey: string | null }[] }>(
      s,
      'GET',
      '/my-decks/changes',
    );
    expect(changes.data.decks.find((d) => d.id === deckId)!.templateKey).toBe('physics');
    const bad = await call(s, 'POST', '/my-decks/sync', {
      decks: [
        {
          id: randomUUID(),
          name: 'x',
          templateKey: 'Bad Key!',
          sortOrder: 0,
          createdAt: now,
          updatedAt: now,
        },
      ],
      cards: [],
    });
    expect(bad.status).toBe(400);
  });
});

describe('bookmark grouping (v3 §8)', () => {
  it('files official cards under subject → unit → deck and own cards under their deck', async () => {
    const w = await world();
    const d = await deck({ subjectId: w.subjectId, lessonId: w.l3 }, 1);
    await adminCall('PUT', `/decks/${d.id}/free`, { mode: 'free' });
    const s = await student();
    const cards = await call<{ cards: { id: string }[] }>(s, 'GET', `/decks/${d.id}/cards`);
    const cardId = cards.data.cards[0]!.id;
    expect((await call(s, 'PUT', '/bookmarks', { itemType: 'flashcard', itemId: cardId })).status).toBe(200);

    const now = new Date().toISOString();
    const ownDeck = randomUUID();
    const ownCard = randomUUID();
    await call(s, 'POST', '/my-decks/sync', {
      decks: [
        {
          id: ownDeck,
          name: 'مراجعتي',
          subjectId: w.subjectId,
          sortOrder: 0,
          createdAt: now,
          updatedAt: now,
        },
      ],
      cards: [
        {
          id: ownCard,
          deckId: ownDeck,
          kind: 'custom',
          frontText: 'وجه',
          backText: 'ظهر',
          sortOrder: 0,
          createdAt: now,
          updatedAt: now,
        },
      ],
    });
    expect((await call(s, 'PUT', '/bookmarks', { itemType: 'user_card', itemId: ownCard })).status).toBe(200);

    const list = await call<{
      items: { itemType: string; itemId: string; subjectId: string | null; group: Json | null }[];
    }>(s, 'GET', '/bookmarks');
    const official = list.data.items.find((b) => b.itemId === cardId)!;
    expect(official.group).toMatchObject({
      subjectId: w.subjectId,
      subjectNameAr: 'الفيزياء',
      unitId: w.u2,
      unitTitleAr: 'الوحدة الثانية',
      lessonId: w.l3,
      lessonTitleAr: 'الدرس 3',
      deckId: d.id,
      deckTitle: 'بطاقات',
      ownDeck: false,
    });
    const own = list.data.items.find((b) => b.itemId === ownCard)!;
    expect(own.subjectId).toBe(w.subjectId);
    expect(own.group).toMatchObject({
      subjectId: w.subjectId,
      subjectNameAr: 'الفيزياء',
      unitId: null,
      deckId: ownDeck,
      deckTitle: 'مراجعتي',
      ownDeck: true,
    });
  });
});
