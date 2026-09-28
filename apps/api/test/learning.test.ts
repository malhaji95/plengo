import { randomUUID } from 'node:crypto';
import { and, eq } from 'drizzle-orm';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { auditLogs, entitlements, questionStats, quizAttempts, userMistakes, users } from '@plengo/db';
import { streak } from '../src/services/stats-service.js';
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
type Method = 'GET' | 'POST' | 'PATCH' | 'PUT' | 'DELETE';

async function adminCall<T = Json>(method: Method, url: string, payload?: object) {
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
async function call<T = Json>(s: Student, method: Method, url: string, payload?: object) {
  const res = await t.app.inject({
    method,
    url: `/api/v1${url}`,
    headers: { authorization: `Bearer ${s.token}` },
    ...(payload ? { payload } : {}),
  });
  return { status: res.statusCode, raw: res.body, ...body<T>(res) };
}

const entitle = (s: Student, scope: Json) =>
  adminCall('POST', `/students/${s.id}/entitlements`, { ...scope, permanentAccess: true });

type AttemptQ = {
  questionId: string;
  type: string;
  options: { id: string; text: string; isCorrect: boolean | null }[];
  selectedOptionId: string | null;
  flagged: boolean;
  result: { isCorrect: boolean; correctOptionId: string | null; correctAnswer: string | null } | null;
};
type Attempt = {
  attempt: {
    id: string;
    status: string;
    totalCount: number;
    answeredCount: number;
    correctCount: number | null;
    wrongCount: number | null;
    skippedCount: number | null;
    scorePercent: number | null;
    submittedLate: boolean;
    deadlineAt: string | null;
    passed: boolean | null;
  };
  questions: AttemptQ[];
};
type Quiz = {
  id: string;
  totalCount: number;
  accessibleCount: number;
  lockedCount: number;
  locked: boolean;
  attemptsUsed: number;
  inProgressAttemptId: string | null;
};

/** A subject with a unit/lesson and a track; the first published question of the subject is free. */
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
  const lesson = (
    await adminCall<{ id: string }>('POST', '/lessons', {
      subjectId: subject.id,
      unitId: unit.id,
      code: slug('l'),
      titleAr: 'الحركة',
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
  await adminCall('PUT', '/free-rules', {
    scopeType: 'subject',
    subjectId: subject.id,
    contentKind: 'questions',
    ruleType: 'first_n_items',
    ruleValue: 1,
  });
  await t.queue.drain(t.c.jobHandlers);

  const create = async (payload: Json) => {
    const res = await adminCall<{
      id: string;
      isFree: boolean;
      options: { id: string; isCorrect: boolean }[];
    }>('POST', '/questions', {
      subjectId: subject.id,
      unitId: unit.id,
      lessonId: lesson.id,
      publish: true,
      ...payload,
    });
    if (res.status !== 200) throw new Error(JSON.stringify(res.error));
    return res.data;
  };
  const mcq = (text: string) =>
    create({
      type: 'mcq',
      questionText: text,
      explanation: 'شرح',
      options: [
        { text: 'صحيح', isCorrect: true },
        { text: 'خطأ ١', isCorrect: false },
        { text: 'خطأ ٢', isCorrect: false },
      ],
    });
  const free = await mcq('سؤال مجاني');
  const premium = await mcq('سؤال مدفوع');
  const written = await create({
    type: 'written',
    questionText: 'عاصمة سوريا؟',
    acceptedAnswers: ['دِمَشْق'],
  });
  const tf = await create({ type: 'true_false', questionText: 'الضوء أسرع من الصوت', trueFalseAnswer: true });
  const trackQ = await create({
    type: 'true_false',
    teacherTrackId: track.id,
    unitId: null,
    lessonId: null,
    questionText: 'سؤال المسار',
    trueFalseAnswer: false,
  });
  const correct = (q: { options: { id: string; isCorrect: boolean }[] }) =>
    q.options.find((o) => o.isCorrect)!.id;
  const wrong = (q: { options: { id: string; isCorrect: boolean }[] }) =>
    q.options.find((o) => !o.isCorrect)!.id;
  return {
    subjectId: subject.id,
    unitId: unit.id,
    lessonId: lesson.id,
    trackId: track.id,
    free,
    premium,
    written,
    tf,
    trackQ,
    correct,
    wrong,
  };
}
type World = Awaited<ReturnType<typeof world>>;

async function quiz(w: World, payload: Json, publish = true) {
  const res = await adminCall<{ quiz: { id: string; contentVersion: number; allowOffline: boolean } }>(
    'POST',
    '/quizzes',
    { subjectId: w.subjectId, titleAr: 'اختبار', ...payload },
  );
  if (res.status !== 200) throw new Error(JSON.stringify(res.error));
  if (publish) {
    const pub = await adminCall('POST', `/quizzes/${res.data.quiz.id}/status`, { status: 'published' });
    if (pub.status !== 200) throw new Error(JSON.stringify(pub.error));
  }
  return res.data.quiz;
}

const start = (s: Student, payload: Json, clientAttemptId: string = randomUUID()) =>
  call<Attempt>(s, 'POST', '/attempts', { clientAttemptId, ...payload });

describe('admin quizzes (§15.1)', () => {
  it('keeps every question in the quiz scope (§15.1.1) and versions changes', async () => {
    const w = await world();
    const bad = await adminCall('POST', '/quizzes', {
      subjectId: w.subjectId,
      titleAr: 'عام',
      questionIds: [w.free.id, w.trackQ.id],
    });
    expect(bad.error?.code).toBe('VALIDATION_ERROR');
    expect(bad.error?.details).toMatchObject({ reason: 'scope_mismatch', questionIds: [w.trackQ.id] });

    const q = await quiz(w, { questionIds: [] }, false);
    expect(
      (await adminCall('POST', `/quizzes/${q.id}/status`, { status: 'published' })).error?.details,
    ).toMatchObject({
      reason: 'empty_quiz',
    });
    const set = await adminCall<{ quiz: { contentVersion: number }; questions: { id: string }[] }>(
      'PUT',
      `/quizzes/${q.id}/questions`,
      { questionIds: [w.premium.id, w.free.id] },
    );
    expect(set.data.quiz.contentVersion).toBe(2);
    expect(set.data.questions.map((x) => x.id)).toEqual([w.premium.id, w.free.id]);
    expect(
      (await adminCall('PUT', `/quizzes/${q.id}/questions`, { questionIds: [w.trackQ.id] })).error?.code,
    ).toBe('VALIDATION_ERROR');

    // A draft question blocks publishing until it is published too.
    const draft = await adminCall<{ id: string }>('POST', '/questions', {
      type: 'true_false',
      subjectId: w.subjectId,
      questionText: 'مسودة',
      trueFalseAnswer: true,
    });
    await adminCall('PUT', `/quizzes/${q.id}/questions`, { questionIds: [w.free.id, draft.data.id] });
    expect(
      (await adminCall('POST', `/quizzes/${q.id}/status`, { status: 'published' })).error?.details,
    ).toMatchObject({
      reason: 'unpublished_questions',
    });
    await adminCall('PUT', `/quizzes/${q.id}/questions`, { questionIds: [w.free.id] });
    const pub = await adminCall<{ quiz: { status: string; contentVersion: number } }>(
      'POST',
      `/quizzes/${q.id}/status`,
      { status: 'published' },
    );
    expect(pub.data.quiz.status).toBe('published');
    const updated = await adminCall<{ quiz: { contentVersion: number; allowOffline: boolean } }>(
      'PATCH',
      `/quizzes/${q.id}`,
      { allowOffline: false },
    );
    expect(updated.data.quiz).toMatchObject({
      allowOffline: false,
      contentVersion: pub.data.quiz.contentVersion + 1,
    });

    // Mock exams are exam-only and stay out of offline packs by default (§22.2).
    const mock = await quiz(w, { isMockExam: true, questionIds: [w.free.id], timeLimitSeconds: 600 }, false);
    expect(mock).toMatchObject({ allowOffline: false });
    expect(
      (
        await adminCall('POST', '/quizzes', {
          subjectId: w.subjectId,
          titleAr: 'x',
          timeLimitSeconds: 60,
          allowedModes: 'practice',
        })
      ).error?.code,
    ).toBe('VALIDATION_ERROR');

    // Structure nodes with live quizzes cannot be deleted.
    await adminCall('PUT', `/quizzes/${mock.id}`, {});
    expect((await adminCall('DELETE', `/lessons/${w.lessonId}`)).status).not.toBe(200);
  });
});

describe('student quizzes and access (§8.8)', () => {
  it('mixed quiz without entitlement: only free questions, correct counts', async () => {
    const w = await world();
    const q = await quiz(w, { questionIds: [w.free.id, w.premium.id, w.written.id] });
    const s = await student();
    const list = await call<Quiz[]>(s, 'GET', `/quizzes?subjectId=${w.subjectId}`);
    expect(list.data.find((x) => x.id === q.id)).toMatchObject({
      totalCount: 3,
      accessibleCount: 1,
      lockedCount: 2,
      locked: false,
    });
    const a = await start(s, { source: 'curated', mode: 'practice', quizId: q.id });
    expect(a.status).toBe(200);
    expect(a.data.attempt.totalCount).toBe(1);
    expect(a.data.questions.map((x) => x.questionId)).toEqual([w.free.id]);
    // Before grading: no correctness, no accepted answers (§37.5).
    expect(a.data.questions[0]!.options.every((o) => o.isCorrect === null)).toBe(true);
    expect(a.raw).not.toContain('"isCorrect":true');
    expect(a.raw).not.toContain('سؤال مدفوع');

    await entitle(s, { scopeType: 'subject', subjectId: w.subjectId });
    const open = await call<Quiz>(s, 'GET', `/quizzes/${q.id}`);
    expect(open.data).toMatchObject({ accessibleCount: 3, locked: false, attemptsUsed: 1 });
  });

  it('mock exam with one premium question is locked for everyone without access', async () => {
    const w = await world();
    const mock = await quiz(w, {
      isMockExam: true,
      questionIds: [w.free.id, w.premium.id],
      timeLimitSeconds: 600,
    });
    const s = await student();
    expect((await call<Quiz>(s, 'GET', `/quizzes/${mock.id}`)).data).toMatchObject({
      locked: true,
      accessibleCount: 0,
      totalCount: 2,
    });
    const locked = await start(s, { source: 'curated', mode: 'exam', quizId: mock.id });
    expect(locked.error?.code).toBe('CONTENT_LOCKED');
    expect(locked.data).toBeNull();
    // Exam-only.
    await entitle(s, { scopeType: 'subject', subjectId: w.subjectId });
    expect((await start(s, { source: 'curated', mode: 'practice', quizId: mock.id })).error?.code).toBe(
      'VALIDATION_ERROR',
    );
    const ok = await start(s, { source: 'curated', mode: 'exam', quizId: mock.id });
    expect(ok.data.attempt.totalCount).toBe(2);
    expect(ok.data.attempt.deadlineAt).not.toBeNull();
  });

  it('a free quiz opens its questions; a quiz with nothing accessible is locked', async () => {
    const w = await world();
    const q = await quiz(w, { questionIds: [w.premium.id, w.tf.id] });
    const s = await student();
    expect((await call<Quiz>(s, 'GET', `/quizzes/${q.id}`)).data).toMatchObject({
      locked: true,
      accessibleCount: 0,
    });
    expect((await start(s, { source: 'curated', mode: 'practice', quizId: q.id })).error?.code).toBe(
      'CONTENT_LOCKED',
    );
    await adminCall('PUT', `/quizzes/${q.id}/free`, { mode: 'free' });
    expect((await call<Quiz>(s, 'GET', `/quizzes/${q.id}`)).data).toMatchObject({
      locked: false,
      accessibleCount: 2,
    });
  });

  it('starting is idempotent by clientAttemptId and max_attempts is enforced', async () => {
    const w = await world();
    const q = await quiz(w, { questionIds: [w.free.id], maxAttempts: 1 });
    const s = await student();
    const id = randomUUID();
    const a = await start(s, { source: 'curated', mode: 'practice', quizId: q.id }, id);
    const again = await start(s, { source: 'curated', mode: 'practice', quizId: q.id }, id);
    expect(again.data.attempt.id).toBe(a.data.attempt.id);
    expect(
      (await start(s, { source: 'curated', mode: 'practice', quizId: q.id })).error?.details,
    ).toMatchObject({
      reason: 'max_attempts',
    });
    expect((await call<Quiz>(s, 'GET', `/quizzes/${q.id}`)).data.inProgressAttemptId).toBe(a.data.attempt.id);
  });
});

describe('practice mode (§15.2)', () => {
  it('grades once per question, records mistakes and masters them after two correct answers', async () => {
    const w = await world();
    const s = await student();
    await entitle(s, { scopeType: 'subject', subjectId: w.subjectId });
    const q = await quiz(w, { questionIds: [w.premium.id, w.written.id] });
    const a = (await start(s, { source: 'curated', mode: 'practice', quizId: q.id })).data;
    const url = (qid: string) => `/attempts/${a.attempt.id}/answers/${qid}/check`;

    const wrong = await call<{ isCorrect: boolean; correctOptionId: string }>(s, 'POST', url(w.premium.id), {
      selectedOptionId: w.wrong(w.premium),
    });
    expect(wrong.data).toMatchObject({ isCorrect: false, correctOptionId: w.correct(w.premium) });
    // Retrying the same answer returns the stored result; changing it is refused.
    expect(
      (await call(s, 'POST', url(w.premium.id), { selectedOptionId: w.wrong(w.premium) })).data,
    ).toMatchObject({
      isCorrect: false,
    });
    expect(
      (await call(s, 'POST', url(w.premium.id), { selectedOptionId: w.correct(w.premium) })).error?.details,
    ).toMatchObject({ reason: 'already_checked' });
    const written = await call<{ isCorrect: boolean; correctAnswer: string }>(s, 'POST', url(w.written.id), {
      writtenAnswer: 'دمشق',
    });
    expect(written.data).toMatchObject({ isCorrect: true, correctAnswer: 'دِمَشْق' });
    expect((await call(s, 'PUT', `/attempts/${a.attempt.id}/answers/${w.written.id}`, {})).error?.code).toBe(
      'VALIDATION_ERROR',
    );

    const view = await call<Attempt>(s, 'GET', `/attempts/${a.attempt.id}`);
    expect(view.data.questions.find((x) => x.questionId === w.premium.id)!.result).toMatchObject({
      isCorrect: false,
    });
    const done = await call<Attempt>(s, 'POST', `/attempts/${a.attempt.id}/submit`, { answers: [] });
    expect(done.data.attempt).toMatchObject({
      status: 'submitted',
      correctCount: 1,
      wrongCount: 1,
      scorePercent: 50,
    });
    // "أعد الأخطاء فقط": a mistakes attempt limited to this attempt's wrong questions.
    const retry = await start(s, {
      source: 'mistakes',
      mode: 'practice',
      filters: { questionIds: [w.premium.id, w.written.id] },
    });
    expect(retry.data.questions.map((x) => x.questionId)).toEqual([w.premium.id]);

    const mistakes = await call<{ items: { questionId: string; wrongCount: number }[]; activeCount: number }>(
      s,
      'GET',
      '/mistakes',
    );
    expect(mistakes.data.items.map((m) => m.questionId)).toEqual([w.premium.id]);

    // "اختبر أخطائي": two correct answers in a row master the mistake (§16.1).
    for (let i = 0; i < 2; i++) {
      const m = await start(s, { source: 'mistakes', mode: 'practice', filters: { subjectId: w.subjectId } });
      expect(m.data.questions.map((x) => x.questionId)).toEqual([w.premium.id]);
      await call(s, 'POST', `/attempts/${m.data.attempt.id}/answers/${w.premium.id}/check`, {
        selectedOptionId: w.correct(w.premium),
      });
    }
    const [row] = await t.c.db
      .select()
      .from(userMistakes)
      .where(and(eq(userMistakes.userId, s.id), eq(userMistakes.questionId, w.premium.id)));
    expect(row).toMatchObject({ status: 'mastered', correctStreak: 2, wrongCount: 1 });
    expect((await start(s, { source: 'mistakes', mode: 'practice' })).error?.details).toMatchObject({
      reason: 'no_questions',
    });

    // Removing hides it; a new wrong answer re-activates it.
    await call(s, 'DELETE', `/mistakes/${w.premium.id}`);
    const again = (
      await start(s, { source: 'random', mode: 'practice', filters: { subjectId: w.subjectId, count: 50 } })
    ).data;
    await call(s, 'POST', `/attempts/${again.attempt.id}/answers/${w.premium.id}/check`, {
      selectedOptionId: w.wrong(w.premium),
    });
    const after = await call<{ activeCount: number; masteredCount: number }>(s, 'GET', '/mistakes');
    expect(after.data).toMatchObject({ activeCount: 1, masteredCount: 0 });
  });

  it('hides mistakes the student can no longer open', async () => {
    const w = await world();
    const s = await student();
    const q = await quiz(w, { questionIds: [w.free.id] });
    const a = (await start(s, { source: 'curated', mode: 'practice', quizId: q.id })).data;
    await call(s, 'POST', `/attempts/${a.attempt.id}/answers/${w.free.id}/check`, {
      selectedOptionId: w.wrong(w.free),
    });
    expect((await call<{ activeCount: number }>(s, 'GET', '/mistakes')).data.activeCount).toBe(1);
    await adminCall('PUT', `/questions/${w.free.id}/free`, { mode: 'paid' });
    expect((await call<{ activeCount: number }>(s, 'GET', '/mistakes')).data.activeCount).toBe(0);
  });
});

describe('exam mode (§15.2, §15.5)', () => {
  it('saves without grading, submits idempotently and reveals results only afterwards', async () => {
    const w = await world();
    const s = await student();
    await entitle(s, { scopeType: 'subject', subjectId: w.subjectId });
    const q = await quiz(w, {
      questionIds: [w.free.id, w.premium.id, w.written.id, w.tf.id],
      allowedModes: 'exam',
      passingScorePercent: 50,
    });
    const a = (await start(s, { source: 'curated', mode: 'exam', quizId: q.id })).data;
    const save = (qid: string, payload: Json) =>
      call(s, 'PUT', `/attempts/${a.attempt.id}/answers/${qid}`, payload);
    expect((await save(w.free.id, { selectedOptionId: w.wrong(w.free) })).status).toBe(200);
    expect(
      (await save(w.free.id, { selectedOptionId: w.correct(w.free), flagged: true })).data,
    ).toMatchObject({
      flagged: true,
    });
    expect((await save(w.written.id, { selectedOptionId: w.correct(w.free) })).error?.code).toBe(
      'VALIDATION_ERROR',
    );
    expect(
      (
        await call(s, 'POST', `/attempts/${a.attempt.id}/answers/${w.free.id}/check`, {
          selectedOptionId: w.correct(w.free),
        })
      ).error?.code,
    ).toBe('VALIDATION_ERROR');

    const mid = await call<Attempt>(s, 'GET', `/attempts/${a.attempt.id}`);
    expect(mid.data.questions.every((x) => x.result === null)).toBe(true);
    expect(mid.raw).not.toContain('"isCorrect":true');
    expect(mid.data.attempt.answeredCount).toBe(1);

    const answers = [
      { questionId: w.premium.id, selectedOptionId: w.wrong(w.premium) },
      { questionId: w.written.id, writtenAnswer: 'دمشق' },
    ];
    const done = await call<Attempt>(s, 'POST', `/attempts/${a.attempt.id}/submit`, {
      answers,
      timeSpentMs: 90_000,
    });
    expect(done.data.attempt).toMatchObject({
      status: 'submitted',
      correctCount: 2,
      wrongCount: 1,
      skippedCount: 1,
      scorePercent: 50,
      passed: true,
      submittedLate: false,
    });
    const free = done.data.questions.find((x) => x.questionId === w.free.id)!;
    expect(free).toMatchObject({ flagged: true, result: { isCorrect: true } });
    expect(free.options.find((o) => o.id === w.correct(w.free))!.isCorrect).toBe(true);
    const skipped = done.data.questions.find((x) => x.questionId === w.tf.id)!;
    expect(skipped.result).toMatchObject({ isCorrect: false });
    expect(skipped.selectedOptionId).toBeNull();

    // Same answers again: same result. Different answers: ATTEMPT_ALREADY_SUBMITTED.
    const repeat = await call<Attempt>(s, 'POST', `/attempts/${a.attempt.id}/submit`, { answers });
    expect(repeat.data.attempt.scorePercent).toBe(50);
    expect(
      (
        await call(s, 'POST', `/attempts/${a.attempt.id}/submit`, {
          answers: [{ questionId: w.premium.id, selectedOptionId: w.correct(w.premium) }],
        })
      ).error?.code,
    ).toBe('ATTEMPT_ALREADY_SUBMITTED');
    expect((await save(w.tf.id, { selectedOptionId: w.correct(w.tf) })).error?.code).toBe(
      'ATTEMPT_ALREADY_SUBMITTED',
    );

    const stats = await t.c.db.select().from(questionStats).where(eq(questionStats.questionId, w.premium.id));
    expect(stats[0]).toMatchObject({ attemptCount: 1, correctCount: 0 });
    expect(stats[0]!.optionDistribution).toEqual({ [w.wrong(w.premium)]: 1 });
  });

  it('exam offline mid-attempt: answers sent only at submit are all graded (§37.5)', async () => {
    const w = await world();
    const s = await student();
    await entitle(s, { scopeType: 'subject', subjectId: w.subjectId });
    const q = await quiz(w, { questionIds: [w.premium.id, w.tf.id], allowedModes: 'exam' });
    const a = (await start(s, { source: 'curated', mode: 'exam', quizId: q.id })).data;
    const done = await call<Attempt>(s, 'POST', `/attempts/${a.attempt.id}/submit`, {
      answers: [
        { questionId: w.premium.id, selectedOptionId: w.correct(w.premium), flagged: true },
        { questionId: w.tf.id, selectedOptionId: w.correct(w.tf) },
      ],
    });
    expect(done.data.attempt).toMatchObject({ correctCount: 2, scorePercent: 100 });
    expect(done.data.questions[0]!.flagged || done.data.questions[1]!.flagged).toBe(true);
  });

  it('marks submissions after deadline + 2 minutes as late, without penalty', async () => {
    const w = await world();
    const s = await student();
    const q = await quiz(w, { questionIds: [w.free.id], allowedModes: 'exam', timeLimitSeconds: 60 });
    const onTime = (await start(s, { source: 'curated', mode: 'exam', quizId: q.id })).data;
    const late = (await start(s, { source: 'curated', mode: 'exam', quizId: q.id })).data;
    t.clock.advance(60_000 + 90_000);
    const a = await call<Attempt>(s, 'POST', `/attempts/${onTime.attempt.id}/submit`, {
      answers: [{ questionId: w.free.id, selectedOptionId: w.correct(w.free) }],
    });
    expect(a.data.attempt).toMatchObject({ submittedLate: false, scorePercent: 100 });
    t.clock.advance(60_000);
    const b = await call<Attempt>(s, 'POST', `/attempts/${late.attempt.id}/submit`, {
      answers: [{ questionId: w.free.id, selectedOptionId: w.correct(w.free) }],
    });
    expect(b.data.attempt).toMatchObject({ submittedLate: true, scorePercent: 100 });
    t.clock.offsetMs = 0;
  });

  it('abandons attempts idle for 7 days', async () => {
    const w = await world();
    const s = await student();
    const q = await quiz(w, { questionIds: [w.free.id] });
    const a = (await start(s, { source: 'curated', mode: 'exam', quizId: q.id })).data;
    t.clock.advance(8 * 24 * 3600_000);
    await t.c.jobHandlers['attempts.abandon-stale']({});
    t.clock.offsetMs = 0;
    const [row] = await t.c.db.select().from(quizAttempts).where(eq(quizAttempts.id, a.attempt.id));
    expect(row!.status).toBe('abandoned');
    expect((await call<Quiz>(s, 'GET', `/quizzes/${q.id}`)).data.inProgressAttemptId).toBeNull();
  });
});

describe('random practice (§15.3)', () => {
  it('draws only accessible published questions matching the filters', async () => {
    const w = await world();
    const s = await student();
    const r = await start(s, {
      source: 'random',
      mode: 'practice',
      filters: { subjectId: w.subjectId, count: 50 },
    });
    expect(r.data.questions.map((q) => q.questionId)).toEqual([w.free.id]);
    expect(
      (
        await start(s, {
          source: 'random',
          mode: 'exam',
          filters: { subjectId: w.subjectId, types: ['written'] },
        })
      ).error?.details,
    ).toMatchObject({ reason: 'no_questions' });

    await entitle(s, { scopeType: 'subject', subjectId: w.subjectId });
    const all = await start(s, {
      source: 'random',
      mode: 'practice',
      filters: { subjectId: w.subjectId, count: 50 },
    });
    expect(new Set(all.data.questions.map((q) => q.questionId))).toEqual(
      new Set([w.free.id, w.premium.id, w.written.id, w.tf.id]),
    );
    const written = await start(s, {
      source: 'random',
      mode: 'practice',
      filters: { subjectId: w.subjectId, types: ['written'] },
    });
    expect(written.data.questions.map((q) => q.questionId)).toEqual([w.written.id]);
    // The track stays locked: a subject entitlement never opens it.
    expect(
      (
        await start(s, {
          source: 'random',
          mode: 'practice',
          filters: { subjectId: w.subjectId, teacherTrackId: w.trackId },
        })
      ).error?.details,
    ).toMatchObject({ reason: 'no_questions' });
    const two = await start(s, {
      source: 'random',
      mode: 'practice',
      filters: { subjectId: w.subjectId, count: 2 },
    });
    expect(two.data.attempt.totalCount).toBe(2);
  });
});

describe('statistics, bookmarks and progress (§16.2–§18)', () => {
  it('reports totals, breakdowns, trend and progress after grading', async () => {
    const w = await world();
    const s = await student();
    await entitle(s, { scopeType: 'subject', subjectId: w.subjectId });
    const q = await quiz(w, { questionIds: [w.free.id, w.premium.id, w.tf.id] });
    const a = (await start(s, { source: 'curated', mode: 'exam', quizId: q.id })).data;
    await call(s, 'POST', `/attempts/${a.attempt.id}/submit`, {
      answers: [
        { questionId: w.free.id, selectedOptionId: w.correct(w.free), timeSpentMs: 4000 },
        { questionId: w.premium.id, selectedOptionId: w.wrong(w.premium), timeSpentMs: 2000 },
      ],
    });

    const overview = await call<{
      totals: { answered: number; correct: number; accuracyPercent: number };
      quizzesCompleted: number;
      studyDays: number;
      currentStreak: number;
      averageTimeMs: number;
      mistakes: { active: number };
      subjects: { subjectId: string; answered: number }[];
      byType: { type: string; answered: number }[];
      mostMissed: { questionId: string }[];
    }>(s, 'GET', '/stats/overview');
    expect(overview.data).toMatchObject({
      totals: { answered: 2, correct: 1, accuracyPercent: 50 },
      quizzesCompleted: 1,
      studyDays: 1,
      currentStreak: 1,
      averageTimeMs: 3000,
      mistakes: { active: 1 },
      subjects: [{ subjectId: w.subjectId, answered: 2 }],
      byType: [{ type: 'mcq', answered: 2 }],
      mostMissed: [{ questionId: w.premium.id }],
    });

    const subject = await call<{
      totals: { answered: number };
      units: { unitId: string; answered: number; lessons: { answered: number }[] }[];
    }>(s, 'GET', `/stats/subjects/${w.subjectId}`);
    expect(subject.data.totals.answered).toBe(2);
    expect(subject.data.units).toMatchObject([{ unitId: w.unitId, answered: 2, lessons: [{ answered: 2 }] }]);

    const trend = await call<{ weeks: { answered: number }[] }>(s, 'GET', '/stats/trend?weeks=4');
    expect(trend.data.weeks).toHaveLength(4);
    expect(trend.data.weeks[3]!.answered).toBe(2);

    const fc = await call<{ forecast: unknown[]; reviewsPerDay: unknown[]; retentionPercent: number | null }>(
      s,
      'GET',
      '/stats/flashcards',
    );
    expect(fc.data.forecast).toHaveLength(7);
    expect(fc.data.reviewsPerDay).toHaveLength(30);

    const progress = await call<{
      questionsAttempted: number;
      questionsCorrect: number;
      questionsTotal: number;
      quizzesCompleted: number;
      quizzesTotal: number;
      completionPercent: number;
      units: { unitId: string; questionsAttempted: number }[];
    }>(s, 'GET', `/progress?subjectId=${w.subjectId}`);
    expect(progress.data).toMatchObject({
      questionsAttempted: 2,
      questionsCorrect: 1,
      questionsTotal: 4,
      quizzesCompleted: 1,
      quizzesTotal: 1,
      completionPercent: 60,
    });
    expect(progress.data.units).toMatchObject([{ unitId: w.unitId, questionsAttempted: 2 }]);

    const resume = await call<
      { subjectId: string; activityType: string; itemId: string; itemTitleAr: string }[]
    >(s, 'GET', '/progress/resume');
    expect(resume.data[0]).toMatchObject({
      subjectId: w.subjectId,
      activityType: 'quiz',
      itemId: q.id,
      itemTitleAr: 'اختبار',
    });
  });

  it('bookmarks items and shows locked ones as locked', async () => {
    const w = await world();
    const s = await student();
    const add = await call<{ locked: boolean; question: { questionText: string | null } }>(
      s,
      'PUT',
      '/bookmarks',
      {
        itemType: 'question',
        itemId: w.premium.id,
      },
    );
    expect(add.data).toMatchObject({ locked: true, question: { questionText: null } });
    expect(add.raw).not.toContain('سؤال مدفوع');
    await call(s, 'PUT', '/bookmarks', { itemType: 'question', itemId: w.premium.id });
    await call(s, 'PUT', '/bookmarks', { itemType: 'question', itemId: w.free.id });
    const list = await call<{ items: { itemId: string; locked: boolean }[] }>(s, 'GET', '/bookmarks');
    expect(list.data.items).toHaveLength(2);
    expect(
      (await call(s, 'PUT', '/bookmarks', { itemType: 'question', itemId: randomUUID() })).error?.code,
    ).toBe('NOT_FOUND');
    expect(
      (await call(s, 'PUT', '/bookmarks', { itemType: 'user_card', itemId: randomUUID() })).error?.code,
    ).toBe('NOT_FOUND');
    await call(s, 'DELETE', `/bookmarks/question/${w.premium.id}`);
    expect((await call<{ itemId: string }[]>(s, 'GET', '/bookmarks/keys')).data).toEqual([
      { itemType: 'question', itemId: w.free.id },
    ]);
  });

  it('auto-flags a question for review at 30 attempts with low accuracy', async () => {
    const w = await world();
    await t.c.db.insert(questionStats).values({ questionId: w.free.id, attemptCount: 29, correctCount: 3 });
    const s = await student();
    const q = await quiz(w, { questionIds: [w.free.id] });
    const a = (await start(s, { source: 'curated', mode: 'practice', quizId: q.id })).data;
    await call(s, 'POST', `/attempts/${a.attempt.id}/answers/${w.free.id}/check`, {
      selectedOptionId: w.wrong(w.free),
    });
    const [row] = await t.c.db.select().from(questionStats).where(eq(questionStats.questionId, w.free.id));
    expect(row).toMatchObject({ attemptCount: 30, flaggedForReview: true });
  });
});

describe('question analytics (§26.2)', () => {
  type Row = {
    questionId: string;
    attempts: number;
    correctPercent: number | null;
    averageTimeMs: number | null;
    flagged: boolean;
    openReports: number;
    offlineMismatches: number;
  };
  type Detail = Row & {
    options: { optionId: string; isCorrect: boolean; count: number; percent: number }[];
    flagReasons: string[];
  };

  it('lists attempts, accuracy, option spread, reports; flags, clears and re-flags after 30 more', async () => {
    const w = await world();
    const wrongId = w.wrong(w.free);
    await t.c.db.insert(questionStats).values({
      questionId: w.free.id,
      attemptCount: 29,
      correctCount: 9,
      totalTimeMs: 29_000,
      optionDistribution: { [w.correct(w.free)]: 9, [wrongId]: 20 },
    });
    const s = await student();
    const q = await quiz(w, { questionIds: [w.free.id] });
    const a = (await start(s, { source: 'curated', mode: 'practice', quizId: q.id })).data;
    await call(s, 'POST', `/attempts/${a.attempt.id}/answers/${w.free.id}/check`, {
      selectedOptionId: wrongId,
    });
    await call(s, 'POST', '/reports', { itemType: 'question', itemId: w.free.id, reason: 'wrong_answer' });

    const list = (query: string) =>
      adminCall<{ items: Row[]; nextCursor: string | null }>(
        'GET',
        `/question-analytics?subjectId=${w.subjectId}${query}`,
      );
    const flagged = (await list('&flagged=true')).data.items;
    expect(flagged.map((r) => r.questionId)).toEqual([w.free.id]);
    expect(flagged[0]).toMatchObject({ attempts: 30, correctPercent: 30, flagged: true, openReports: 1 });
    // Every published question of the subject appears; unanswered ones have no accuracy.
    const all = (await list('&sort=correct')).data.items;
    expect(all.length).toBe(5); // general and track questions of the subject
    expect(all.find((r) => r.questionId === w.premium.id)).toMatchObject({
      attempts: 0,
      correctPercent: null,
    });
    const paged = await list('&limit=2');
    expect(paged.data.items).toHaveLength(2);
    expect(paged.data.nextCursor).not.toBeNull();

    const detail = (await adminCall<Detail>('GET', `/question-analytics/${w.free.id}`)).data;
    expect(detail.flagReasons).toEqual(['wrong_option_preferred']);
    expect(detail.options.find((o) => o.optionId === wrongId)).toMatchObject({ count: 21, percent: 70 });
    expect(detail.options.find((o) => o.isCorrect)).toMatchObject({ count: 9, percent: 30 });

    // Reports can be listed for this one question.
    const reports = await adminCall<{ items: { itemId: string }[] }>('GET', `/reports?itemId=${w.free.id}`);
    expect(reports.data.items.map((r) => r.itemId)).toEqual([w.free.id]);

    // Reviewed: cleared, audited, and not flagged again by the very next attempt.
    const cleared = await adminCall<Detail>('POST', `/question-analytics/${w.free.id}/clear-flag`);
    expect(cleared.data.flagged).toBe(false);
    const logs = await t.c.db.select().from(auditLogs).where(eq(auditLogs.resourceId, w.free.id));
    expect(logs.map((l) => l.action)).toContain('question.flag_cleared');
    const again = (await start(s, { source: 'curated', mode: 'practice', quizId: q.id })).data;
    await call(s, 'POST', `/attempts/${again.attempt.id}/answers/${w.free.id}/check`, {
      selectedOptionId: wrongId,
    });
    const [row] = await t.c.db.select().from(questionStats).where(eq(questionStats.questionId, w.free.id));
    expect(row).toMatchObject({ attemptCount: 31, flaggedForReview: false, flagReviewedAttempts: 30 });
    // 30 attempts after the review, the rule looks again.
    await t.c.db
      .update(questionStats)
      .set({ attemptCount: 59 })
      .where(eq(questionStats.questionId, w.free.id));
    const third = (await start(s, { source: 'curated', mode: 'practice', quizId: q.id })).data;
    await call(s, 'POST', `/attempts/${third.attempt.id}/answers/${w.free.id}/check`, {
      selectedOptionId: wrongId,
    });
    const [after] = await t.c.db.select().from(questionStats).where(eq(questionStats.questionId, w.free.id));
    expect(after!.flaggedForReview).toBe(true);

    expect((await adminCall('POST', `/question-analytics/${randomUUID()}/clear-flag`)).status).toBe(404);
    expect((await adminCall('GET', `/question-analytics/${randomUUID()}`)).status).toBe(404);
    expect((await call(s, 'GET', '/admin/question-analytics')).status).toBe(403);
  });
});

describe('audit follow-ups', () => {
  it('refuses the stateless question check while the question is in an open exam (§15.2)', async () => {
    const w = await world();
    const s = await student();
    const q = await quiz(w, { questionIds: [w.free.id], allowedModes: 'exam' });
    expect(
      (await call(s, 'POST', `/questions/${w.free.id}/check`, { selectedOptionId: w.correct(w.free) }))
        .status,
    ).toBe(200);
    const a = (await start(s, { source: 'curated', mode: 'exam', quizId: q.id })).data;
    const blocked = await call(s, 'POST', `/questions/${w.free.id}/check`, {
      selectedOptionId: w.correct(w.free),
    });
    expect(blocked.error?.details).toMatchObject({ reason: 'exam_in_progress' });
    expect(blocked.raw).not.toContain('correctOptionId');
    await call(s, 'POST', `/attempts/${a.attempt.id}/submit`, { answers: [] });
    expect(
      (await call(s, 'POST', `/questions/${w.free.id}/check`, { selectedOptionId: w.correct(w.free) }))
        .status,
    ).toBe(200);
  });

  it('bumps the quiz version when a member question is unpublished or deleted (§22.3)', async () => {
    const w = await world();
    const q = await quiz(w, { questionIds: [w.free.id, w.premium.id] });
    const version = async () =>
      (await adminCall<{ quiz: { contentVersion: number } }>('GET', `/quizzes/${q.id}`)).data.quiz
        .contentVersion;
    const v0 = await version();
    await adminCall('POST', `/questions/${w.premium.id}/status`, { status: 'archived' });
    expect(await version()).toBe(v0 + 1);
    await adminCall('DELETE', `/questions/${w.free.id}`);
    expect(await version()).toBe(v0 + 2);
  });

  it('max_attempts holds under concurrent starts', async () => {
    const w = await world();
    const q = await quiz(w, { questionIds: [w.free.id], maxAttempts: 2 });
    const s = await student();
    const results = await Promise.all(
      Array.from({ length: 5 }, () => start(s, { source: 'curated', mode: 'practice', quizId: q.id })),
    );
    expect(results.filter((r) => r.status === 200)).toHaveLength(2);
    const rows = await t.c.db.select().from(quizAttempts).where(eq(quizAttempts.quizId, q.id));
    expect(rows).toHaveLength(2);
  });

  it('attempt payloads never carry accepted answers before grading (§37.5)', async () => {
    const w = await world();
    const s = await student();
    await entitle(s, { scopeType: 'subject', subjectId: w.subjectId });
    const q = await quiz(w, { questionIds: [w.written.id], allowedModes: 'exam' });
    const a = await start(s, { source: 'curated', mode: 'exam', quizId: q.id });
    expect(a.raw).not.toContain('دمشق');
    expect(a.raw).not.toContain('دِمَشْق');
    expect((await call(s, 'GET', `/attempts/${a.data.attempt.id}`)).raw).not.toContain('دِمَشْق');
  });

  it('mastery streak comes from the admin learning setting (§16.1, §26.2)', async () => {
    const before = await adminCall<{ mistakeMasteryStreak: number }>('GET', '/settings/learning');
    expect(before.data.mistakeMasteryStreak).toBe(2);
    await adminCall('PUT', '/settings/learning', { mistakeMasteryStreak: 1 });
    try {
      const w = await world();
      const s = await student();
      const q = await quiz(w, { questionIds: [w.free.id] });
      const a = (await start(s, { source: 'curated', mode: 'practice', quizId: q.id })).data;
      await call(s, 'POST', `/attempts/${a.attempt.id}/answers/${w.free.id}/check`, {
        selectedOptionId: w.wrong(w.free),
      });
      const m = (await start(s, { source: 'mistakes', mode: 'practice' })).data;
      await call(s, 'POST', `/attempts/${m.attempt.id}/answers/${w.free.id}/check`, {
        selectedOptionId: w.correct(w.free),
      });
      const list = await call<{ activeCount: number; masteredCount: number; masteryStreak: number }>(
        s,
        'GET',
        '/mistakes',
      );
      expect(list.data).toMatchObject({ activeCount: 0, masteredCount: 1, masteryStreak: 1 });
      expect((await adminCall('PUT', '/settings/learning', { mistakeMasteryStreak: 0 })).error?.code).toBe(
        'VALIDATION_ERROR',
      );
    } finally {
      await adminCall('PUT', '/settings/learning', { mistakeMasteryStreak: 2 });
    }
  });

  it('pages the mistake bank and bookmarks by cursor (§30.1)', async () => {
    const w = await world();
    const s = await student();
    await entitle(s, { scopeType: 'subject', subjectId: w.subjectId });
    const q = await quiz(w, { questionIds: [w.free.id, w.premium.id, w.tf.id], allowedModes: 'exam' });
    const a = (await start(s, { source: 'curated', mode: 'exam', quizId: q.id })).data;
    await call(s, 'POST', `/attempts/${a.attempt.id}/submit`, {
      answers: [
        { questionId: w.free.id, selectedOptionId: w.wrong(w.free) },
        { questionId: w.premium.id, selectedOptionId: w.wrong(w.premium) },
        { questionId: w.tf.id, selectedOptionId: w.wrong(w.tf) },
      ],
    });
    type Page = { items: { questionId: string }[]; nextCursor: string | null };
    const p1 = await call<Page>(s, 'GET', '/mistakes?limit=2');
    const p2 = await call<Page>(s, 'GET', `/mistakes?limit=2&cursor=${p1.data.nextCursor}`);
    expect([p1.data.items.length, p2.data.items.length, p2.data.nextCursor]).toEqual([2, 1, null]);
    for (const id of [w.free.id, w.premium.id, w.tf.id])
      await call(s, 'PUT', '/bookmarks', { itemType: 'question', itemId: id });
    const b1 = await call<{ items: unknown[]; nextCursor: string | null }>(s, 'GET', '/bookmarks?limit=2');
    const b2 = await call<{ items: unknown[]; nextCursor: string | null }>(
      s,
      'GET',
      `/bookmarks?limit=2&cursor=${b1.data.nextCursor}`,
    );
    expect([b1.data.items.length, b2.data.items.length, b2.data.nextCursor]).toEqual([2, 1, null]);
  });

  it('statistics: weakest units need 10 answers; mistake counts match the bank', async () => {
    const w = await world();
    const s = await student();
    await entitle(s, { scopeType: 'subject', subjectId: w.subjectId });
    const ids = [w.free.id, w.premium.id, w.tf.id];
    const answerAll = async (right: boolean) => {
      const q = await quiz(w, { questionIds: ids, allowedModes: 'exam' });
      const a = (await start(s, { source: 'curated', mode: 'exam', quizId: q.id })).data;
      await call(s, 'POST', `/attempts/${a.attempt.id}/submit`, {
        answers: [
          { questionId: w.free.id, selectedOptionId: right ? w.correct(w.free) : w.wrong(w.free) },
          { questionId: w.premium.id, selectedOptionId: w.wrong(w.premium) },
          { questionId: w.tf.id, selectedOptionId: w.correct(w.tf) },
        ],
      });
    };
    type Overview = {
      weakestUnits: { unitId: string; answered: number; accuracyPercent: number }[];
      mistakes: { active: number };
    };
    for (let i = 0; i < 3; i++) await answerAll(false);
    expect((await call<Overview>(s, 'GET', '/stats/overview')).data.weakestUnits).toEqual([]); // 9 answers
    await answerAll(true);
    const o = (await call<Overview>(s, 'GET', '/stats/overview')).data;
    expect(o.weakestUnits).toMatchObject([{ unitId: w.unitId, answered: 12, accuracyPercent: 42 }]);
    const bank = await call<{ activeCount: number }>(s, 'GET', '/mistakes');
    expect(o.mistakes.active).toBe(bank.data.activeCount);
    // Losing access hides mistakes from the bank and from the statistics alike.
    await t.c.db.update(entitlements).set({ status: 'revoked' }).where(eq(entitlements.userId, s.id));
    const after = (await call<Overview>(s, 'GET', '/stats/overview')).data;
    expect(after.mistakes.active).toBe(
      (await call<{ activeCount: number }>(s, 'GET', '/mistakes')).data.activeCount,
    );
  });

  it('time totals are bigint: huge sums do not overflow the grading transaction', async () => {
    const w = await world();
    await t.c.db
      .insert(questionStats)
      .values({ questionId: w.free.id, attemptCount: 1, correctCount: 1, totalTimeMs: 2_147_000_000 });
    const s = await student();
    const q = await quiz(w, { questionIds: [w.free.id] });
    const a = (await start(s, { source: 'curated', mode: 'practice', quizId: q.id })).data;
    const res = await call(s, 'POST', `/attempts/${a.attempt.id}/answers/${w.free.id}/check`, {
      selectedOptionId: w.correct(w.free),
      timeSpentMs: 20 * 60_000,
    });
    expect(res.status).toBe(200);
    const [row] = await t.c.db.select().from(questionStats).where(eq(questionStats.questionId, w.free.id));
    expect(row!.totalTimeMs).toBe(2_147_000_000 + 20 * 60_000);
  });
});

describe('streak', () => {
  it('counts consecutive business days ending today or yesterday', () => {
    expect(streak(new Set([10, 9, 8, 6]), 10)).toBe(3);
    expect(streak(new Set([9, 8]), 10)).toBe(2);
    expect(streak(new Set([8]), 10)).toBe(0);
  });
});
