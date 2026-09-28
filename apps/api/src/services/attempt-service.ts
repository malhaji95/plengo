import { randomInt } from 'node:crypto';
import type { AttemptQuestion, AttemptSummary, AttemptView, CheckResult } from '@plengo/contracts';
import type { AttemptFilters, Db, Tx } from '@plengo/db';
import { AppError } from '../lib/app-error.js';
import type { AnswerRow, AttemptRepository, AttemptRow } from '../repositories/attempt-repository.js';
import type { GradedAnswer, LearningRepository } from '../repositories/learning-repository.js';
import type { QuestionRepository, QuestionWithContent } from '../repositories/question-repository.js';
import type { QuizRepository } from '../repositories/quiz-repository.js';
import type { StructureRepository } from '../repositories/structure-repository.js';
import type { TeacherRepository } from '../repositories/teacher-repository.js';
import { scopeOf, type AccessService } from './access-service.js';
import type { ConfigService } from './config-service.js';
import { assertVisibleScope, invalid } from './content-placement.js';
import { grade, questionSnapshot, type AnswerInput, type QuestionSnapshot } from './grading.js';
import { quizAccess, type QuizService } from './quiz-service.js';

/** Timed exams: submissions later than this after the deadline are marked late (§15.5). */
export const LATE_GRACE_MS = 2 * 60_000;
/** Unfinished attempts without activity this long become abandoned (§15.5). */
export const ABANDON_AFTER_MS = 7 * 24 * 3600_000;
export const DEFAULT_PRACTICE_COUNT = 20;
const MAX_TIME_MS = 86_400_000;
/** Per-answer time counted in statistics: longer pauses are not time spent on the question. */
export const MAX_STATS_TIME_MS = 30 * 60_000;

type Answer = {
  selectedOptionId?: string | null | undefined;
  writtenAnswer?: string | null | undefined;
  timeSpentMs?: number | null | undefined;
};

export function shuffle<T>(items: T[]): T[] {
  const out = [...items];
  for (let i = out.length - 1; i > 0; i--) {
    const j = randomInt(i + 1);
    [out[i], out[j]] = [out[j]!, out[i]!];
  }
  return out;
}

const given = (a: { selectedOptionId?: string | null; writtenAnswer?: string | null }) =>
  (a.selectedOptionId ?? null) !== null || (a.writtenAnswer ?? null) !== null;

/** The same answer as stored (idempotent retries after a connection drop). */
const sameAnswer = (stored: AnswerRow | undefined, a: Answer) =>
  (stored?.selectedOptionId ?? null) === (a.selectedOptionId ?? null) &&
  (stored?.writtenAnswer ?? null) === (a.writtenAnswer ?? null);

/**
 * Attempts (spec §15.2–§15.5): curated quizzes, random practice and mistake reviews share one
 * machine. Practice grades one answer per check; exams save freely and grade on submit. Grading
 * writes the answer with its snapshot, the mistake bank, subject and question statistics and the
 * progress pointer in one transaction.
 */
export function createAttemptService(deps: {
  db: Db;
  repo: AttemptRepository;
  questionRepo: QuestionRepository;
  learningRepo: LearningRepository;
  quizRepo: QuizRepository;
  quizService: QuizService;
  structureRepo: StructureRepository;
  teacherRepo: TeacherRepository;
  access: AccessService;
  config: ConfigService;
  now?: () => Date;
}) {
  const {
    db,
    repo,
    questionRepo,
    learningRepo,
    quizRepo,
    quizService,
    structureRepo,
    teacherRepo,
    access,
    config,
  } = deps;
  const now = deps.now ?? (() => new Date());
  const notFound = (): never => {
    throw new AppError('NOT_FOUND');
  };
  const visible = (subjectId: string, trackId: string | null) =>
    assertVisibleScope({ structureRepo, teacherRepo }, subjectId, trackId)
      .then(() => true)
      .catch(() => false);

  async function withContent(ids: string[], conn: Db | Tx = db) {
    const rows = await questionRepo.attachContent(await questionRepo.byIds(ids, conn), conn);
    return new Map(rows.map((q) => [q.id, q]));
  }

  /** Option display order: shuffled once at start unless the quiz keeps it (true/false never). */
  const optionOrders = (qs: QuestionWithContent[], shuffleOptions: boolean) =>
    Object.fromEntries(
      qs.map((q) => {
        const ids = q.options.map((o) => o.id);
        return [q.id, shuffleOptions && q.type === 'mcq' ? shuffle(ids) : ids];
      }),
    );

  // ---- views ----

  function resultFrom(snap: QuestionSnapshot, a: AnswerRow | undefined): CheckResult {
    return {
      isCorrect: a?.isCorrect ?? false,
      correctOptionId: snap.options.find((o) => o.isCorrect)?.id ?? null,
      correctAnswer: snap.acceptedAnswers[0] ?? null,
      explanation: snap.explanation,
    };
  }

  function orderOptions<T extends { id: string }>(options: T[], order: string[] | undefined) {
    if (!order) return options;
    const rank = new Map(order.map((id, i) => [id, i]));
    return [...options].sort((x, y) => (rank.get(x.id) ?? 1e6) - (rank.get(y.id) ?? 1e6));
  }

  function summary(a: AttemptRow, answered: number, passing: number | null): AttemptSummary {
    const done = a.status === 'submitted';
    const correct = done ? (a.correctCount ?? 0) : null;
    const skipped = done ? a.totalCount - answered : null;
    return {
      id: a.id,
      clientAttemptId: a.clientAttemptId,
      quizId: a.quizId,
      source: a.source,
      mode: a.mode,
      titleAr: a.titleAr,
      subjectId: a.subjectId,
      teacherTrackId: a.teacherTrackId,
      filters: a.filters,
      status: a.status,
      startedAt: a.startedAt.toISOString(),
      deadlineAt: a.deadlineAt?.toISOString() ?? null,
      submittedAt: a.submittedAt?.toISOString() ?? null,
      submittedLate: a.submittedLate,
      totalCount: a.totalCount,
      answeredCount: answered,
      correctCount: correct,
      wrongCount: done ? answered - correct! : null,
      skippedCount: skipped,
      scorePercent: a.scorePercent,
      passingScorePercent: passing,
      passed: done && passing !== null ? (a.scorePercent ?? 0) >= passing : null,
      timeSpentMs: a.timeSpentMs,
    };
  }

  async function passingOf(a: AttemptRow) {
    if (!a.quizId) return null;
    return quizRepo.passingScore(a.quizId);
  }

  async function view(a: AttemptRow): Promise<AttemptView> {
    const answers = new Map((await repo.answers(a.id)).map((r) => [r.questionId, r]));
    const live = await withContent(a.questionOrder);
    const submitted = a.status === 'submitted';
    const items: AttemptQuestion[] = a.questionOrder.flatMap((qid) => {
      const ans = answers.get(qid);
      const snap = ans?.questionSnapshot as QuestionSnapshot | null | undefined;
      const revealed = (submitted || ans?.gradedAt) && snap;
      const q = live.get(qid);
      if (!revealed && !q) return [];
      const base = revealed
        ? { type: snap.type, questionText: snap.questionText, options: snap.options }
        : { type: q!.type, questionText: q!.questionText, options: q!.options.map((o) => ({ ...o })) };
      return [
        {
          questionId: qid,
          type: base.type,
          unitId: q?.unitId ?? null,
          lessonId: q?.lessonId ?? null,
          questionText: base.questionText,
          options: orderOptions(base.options, a.optionOrders[qid]).map((o) => ({
            id: o.id,
            text: o.text,
            // Never before grading (§14.3).
            isCorrect: revealed ? o.isCorrect : null,
          })),
          selectedOptionId: ans?.selectedOptionId ?? null,
          writtenAnswer: ans?.writtenAnswer ?? null,
          flagged: ans?.flagged ?? false,
          answeredAt: ans?.answeredAt?.toISOString() ?? null,
          timeSpentMs: ans?.timeSpentMs ?? null,
          result: revealed ? resultFrom(snap, ans) : null,
        },
      ];
    });
    const answered = [...answers.values()].filter(given).length;
    return {
      attempt: summary(a, answered, await passingOf(a)),
      questions: items,
      serverTime: now().toISOString(),
    };
  }

  async function owned(userId: string, id: string) {
    return (await repo.get(id, userId)) ?? notFound();
  }

  // ---- grading ----

  /** Grades a stored answer. An option that no longer exists grades as wrong rather than failing. */
  function gradeStored(q: QuestionWithContent, a: Answer): CheckResult {
    const input: AnswerInput =
      q.type === 'written'
        ? { writtenAnswer: a.writtenAnswer ?? '' }
        : { selectedOptionId: a.selectedOptionId ?? undefined };
    if (q.type !== 'written' && !q.options.some((o) => o.id === a.selectedOptionId)) {
      return {
        isCorrect: false,
        correctOptionId: q.options.find((o) => o.isCorrect)?.id ?? null,
        correctAnswer: null,
        explanation: q.explanation,
      };
    }
    return grade(q, input);
  }

  /** The answer's shape matches the question type. */
  function checkShape(q: QuestionWithContent, a: Answer) {
    if (q.type === 'written' && a.selectedOptionId) invalid('selectedOptionId');
    if (q.type !== 'written' && a.writtenAnswer !== undefined && a.writtenAnswer !== null)
      invalid('writtenAnswer');
    if (q.type !== 'written' && a.selectedOptionId && !q.options.some((o) => o.id === a.selectedOptionId))
      invalid('selectedOptionId');
  }

  /** Writes the grade and every aggregate that depends on it (§16, §18, §28.1). */
  async function applyGrade(
    tx: Tx,
    attempt: AttemptRow,
    q: QuestionWithContent,
    a: Answer & { flagged?: boolean | undefined },
    result: CheckResult,
    at: Date,
    masteryStreak: number,
  ) {
    const timeMs = Math.min(Math.max(a.timeSpentMs ?? 0, 0), MAX_STATS_TIME_MS);
    const values = {
      selectedOptionId: a.selectedOptionId ?? null,
      writtenAnswer: a.writtenAnswer ?? null,
      isCorrect: result.isCorrect,
      gradedAt: at,
      answeredAt: at,
      timeSpentMs: a.timeSpentMs ?? null,
      questionSnapshot: questionSnapshot(q) as unknown as Record<string, unknown>,
    };
    await repo.upsertAnswer(
      tx,
      {
        attemptId: attempt.id,
        questionId: q.id,
        userId: attempt.userId,
        flagged: a.flagged ?? false,
        ...values,
      },
      { ...values, ...(a.flagged !== undefined ? { flagged: a.flagged } : {}) },
    );
    const g: GradedAnswer = {
      userId: attempt.userId,
      question: q,
      correctOptionId: result.correctOptionId,
      selectedOptionId: q.type === 'written' ? null : (a.selectedOptionId ?? null),
      isCorrect: result.isCorrect,
      timeMs,
      at,
    };
    await learningRepo.recordMistake(tx, g, masteryStreak);
    await learningRepo.addSubjectStats(tx, g);
    await learningRepo.addQuestionStats(tx, g);
    await learningRepo.touchProgress(tx, {
      userId: attempt.userId,
      subjectId: q.subjectId,
      teacherTrackId: q.teacherTrackId,
      unitId: q.unitId,
      lessonId: q.lessonId,
      type: attempt.quizId ? 'quiz' : 'question',
      itemId: attempt.quizId ?? q.id,
      at,
    });
  }

  // ---- building attempts ----

  async function curated(userId: string, quizId: string | undefined, mode: AttemptRow['mode']) {
    if (!quizId) invalid('quizId');
    const quiz = await quizService.publishedQuiz(quizId!);
    if (quiz.allowedModes !== 'both' && quiz.allowedModes !== mode) invalid('mode', 'not_allowed');
    const [members, ctx] = await Promise.all([
      quizRepo.publishedMembers([quiz.id]).then((rows) => rows.map((r) => r.question)),
      access.context(userId),
    ]);
    const { accessible, locked } = quizAccess(ctx, quiz, members);
    if (locked) throw new AppError('CONTENT_LOCKED');
    if (quiz.maxAttempts !== null) {
      const used = (await repo.quizStats(userId, [quiz.id])).get(quiz.id)?.used ?? 0;
      if (used >= quiz.maxAttempts) invalid('quizId', 'max_attempts');
    }
    const content = await withContent(accessible.map((q) => q.id));
    const ordered = accessible.map((q) => content.get(q.id)!);
    const list = quiz.shuffleQuestions ? shuffle(ordered) : ordered;
    return {
      quizId: quiz.id,
      quizContentVersion: quiz.contentVersion,
      maxAttempts: quiz.maxAttempts,
      titleAr: quiz.titleAr,
      subjectId: quiz.subjectId,
      teacherTrackId: quiz.teacherTrackId,
      filters: null,
      questions: list,
      shuffleOptions: quiz.shuffleOptions,
      timeLimitSeconds: mode === 'exam' ? quiz.timeLimitSeconds : null,
      progress: { unitId: quiz.unitId, lessonId: quiz.lessonId },
    };
  }

  /** Random practice (§15.3): published questions the student can open, drawn server-side. */
  async function random(userId: string, f: AttemptFilters) {
    if (!f.subjectId) invalid('filters.subjectId');
    const trackId = f.teacherTrackId ?? null;
    if (!(await visible(f.subjectId!, trackId))) notFound();
    const ctx = await access.context(userId);
    const scopeOpen = ctx.scopeAccess(
      scopeOf({ subjectId: f.subjectId!, teacherTrackId: trackId }),
    ).hasAccess;
    const rows = await questionRepo.randomPublishedIds(
      {
        subjectId: f.subjectId!,
        teacherTrackId: trackId,
        unitId: f.unitId,
        lessonId: f.lessonId,
        types: f.types,
        freeOnly: !scopeOpen,
      },
      f.count ?? DEFAULT_PRACTICE_COUNT,
    );
    if (!rows.length) invalid('filters', 'no_questions');
    const content = await withContent(rows.map((r) => r.id));
    return {
      quizId: null,
      quizContentVersion: null,
      maxAttempts: null,
      titleAr: 'تدريب عشوائي',
      subjectId: f.subjectId!,
      teacherTrackId: trackId,
      filters: f,
      questions: rows.map((r) => content.get(r.id)!),
      shuffleOptions: true,
      timeLimitSeconds: null,
      progress: { unitId: f.unitId ?? null, lessonId: f.lessonId ?? null },
    };
  }

  /** "اختبر أخطائي" (§16.1): active mistakes the student can still open. */
  async function mistakes(userId: string, f: AttemptFilters) {
    const rows = await learningRepo.activeMistakeQuestions(userId, f);
    const ctx = await access.context(userId);
    const scopes = new Map<string, boolean>();
    const open = [];
    for (const { q } of rows) {
      const key = `${q.subjectId}:${q.teacherTrackId}`;
      if (!scopes.has(key)) scopes.set(key, await visible(q.subjectId, q.teacherTrackId));
      if (scopes.get(key) && ctx.canAccessItem(q)) open.push(q);
    }
    const picked = shuffle(open).slice(0, f.count ?? DEFAULT_PRACTICE_COUNT);
    if (!picked.length) invalid('filters', 'no_questions');
    const content = await withContent(picked.map((q) => q.id));
    const subjects = new Set(picked.map((q) => q.subjectId));
    const only = subjects.size === 1 ? picked[0]! : null;
    return {
      quizId: null,
      quizContentVersion: null,
      maxAttempts: null,
      titleAr: 'مراجعة الأخطاء',
      subjectId: only?.subjectId ?? null,
      teacherTrackId:
        only && new Set(picked.map((q) => q.teacherTrackId)).size === 1 ? only.teacherTrackId : null,
      filters: f,
      questions: picked.map((q) => content.get(q.id)!),
      shuffleOptions: true,
      timeLimitSeconds: null,
      progress: null,
    };
  }

  return {
    /** Idempotent by `clientAttemptId`: a retried start returns the first attempt. */
    async start(
      userId: string,
      body: {
        clientAttemptId: string;
        source: AttemptRow['source'];
        mode: AttemptRow['mode'];
        quizId?: string | undefined;
        filters?: AttemptFilters | undefined;
      },
    ): Promise<AttemptView> {
      const existing = await repo.byClientId(userId, body.clientAttemptId);
      if (existing) return view(existing);
      const f = body.filters ?? {};
      const built =
        body.source === 'curated'
          ? await curated(userId, body.quizId, body.mode)
          : body.source === 'random'
            ? await random(userId, f)
            : await mistakes(userId, f);
      const at = now();
      const row = await db.transaction(async (tx) => {
        if (built.quizId && built.maxAttempts !== null) {
          // Re-checked under a lock: concurrent starts cannot both take the last attempt.
          const used = await repo.lockAndCountUsed(tx, userId, built.quizId);
          if (used >= built.maxAttempts && !(await repo.byClientId(userId, body.clientAttemptId, tx))) {
            invalid('quizId', 'max_attempts');
          }
        }
        const inserted = await repo.insert(tx, {
          clientAttemptId: body.clientAttemptId,
          userId,
          quizId: built.quizId,
          quizContentVersion: built.quizContentVersion,
          source: body.source,
          mode: body.mode,
          titleAr: built.titleAr,
          subjectId: built.subjectId,
          teacherTrackId: built.teacherTrackId,
          filters: built.filters,
          questionOrder: built.questions.map((q) => q.id),
          optionOrders: optionOrders(built.questions, built.shuffleOptions),
          startedAt: at,
          deadlineAt: built.timeLimitSeconds ? new Date(at.getTime() + built.timeLimitSeconds * 1000) : null,
          totalCount: built.questions.length,
          lastActivityAt: at,
        });
        if (inserted && built.subjectId && built.progress) {
          await learningRepo.touchProgress(tx, {
            userId,
            subjectId: built.subjectId,
            teacherTrackId: built.teacherTrackId,
            ...built.progress,
            type: built.quizId ? 'quiz' : 'question',
            itemId: built.quizId,
            at,
          });
        }
        return inserted;
      });
      return view(row ?? (await repo.byClientId(userId, body.clientAttemptId))!);
    },

    async get(userId: string, id: string) {
      return view(await owned(userId, id));
    },

    async list(
      userId: string,
      q: {
        status?: AttemptRow['status'] | undefined;
        quizId?: string | undefined;
        cursor?: string | undefined;
        limit: number;
      },
    ) {
      const page = await repo.list(userId, q, q.cursor, q.limit);
      const counts = await repo.answerCounts(page.items.map((a) => a.id));
      const items = await Promise.all(
        page.items.map(async (a) => summary(a, counts.get(a.id) ?? 0, await passingOf(a))),
      );
      return { items, nextCursor: page.nextCursor };
    },

    /** Exam autosave (§15.5): answers and flags change freely until submission. */
    async save(
      userId: string,
      id: string,
      questionId: string,
      body: Answer & { flagged?: boolean | undefined },
    ) {
      const attempt = await owned(userId, id);
      if (attempt.status === 'submitted') throw new AppError('ATTEMPT_ALREADY_SUBMITTED');
      if (attempt.status !== 'in_progress') invalid('attempt', 'abandoned');
      if (attempt.mode !== 'exam') invalid('mode', 'practice_uses_check');
      if (!attempt.questionOrder.includes(questionId)) notFound();
      const q = (await withContent([questionId])).get(questionId)!;
      checkShape(q, body);
      const at = now();
      const hasAnswer = given(body);
      const values = {
        selectedOptionId: body.selectedOptionId ?? null,
        writtenAnswer: body.writtenAnswer ?? null,
        answeredAt: hasAnswer ? at : null,
        timeSpentMs: body.timeSpentMs ?? null,
      };
      const row = await db.transaction(async (tx) => {
        const saved = await repo.upsertAnswer(
          tx,
          { attemptId: id, questionId, userId, flagged: body.flagged ?? false, ...values },
          { ...values, ...(body.flagged !== undefined ? { flagged: body.flagged } : {}) },
        );
        await repo.update(tx, id, { lastActivityAt: at });
        return saved;
      });
      return {
        questionId,
        selectedOptionId: row.selectedOptionId,
        writtenAnswer: row.writtenAnswer,
        flagged: row.flagged,
        answeredAt: row.answeredAt?.toISOString() ?? null,
      };
    },

    /** Practice check (§15.2): grades once; the same answer sent again returns the stored result. */
    async check(userId: string, id: string, questionId: string, body: Answer): Promise<CheckResult> {
      const attempt = await owned(userId, id);
      if (attempt.status === 'submitted') throw new AppError('ATTEMPT_ALREADY_SUBMITTED');
      if (attempt.status !== 'in_progress') invalid('attempt', 'abandoned');
      if (attempt.mode !== 'practice') invalid('mode', 'exam_grades_on_submit');
      if (!attempt.questionOrder.includes(questionId)) notFound();
      if (!given(body)) invalid('answer');
      const q = (await withContent([questionId])).get(questionId)!;
      checkShape(q, body);
      const { mistakeMasteryStreak } = await config.getLearningSettings();
      return db.transaction(async (tx) => {
        const locked = (await repo.getForUpdate(tx, id, userId))!;
        const stored = (await repo.answers(id, tx)).find((a) => a.questionId === questionId);
        if (stored?.gradedAt) {
          if (!sameAnswer(stored, body)) invalid('answer', 'already_checked');
          return resultFrom(stored.questionSnapshot as unknown as QuestionSnapshot, stored);
        }
        const result = gradeStored(q, body);
        const at = now();
        await applyGrade(tx, locked, q, body, result, at, mistakeMasteryStreak);
        await repo.update(tx, id, { lastActivityAt: at });
        return result;
      });
    },

    /**
     * Grades every answered, ungraded question (exam answers, and practice answers graded on the
     * device, §15.2), snapshots skipped ones, and closes the attempt. A repeat with the same answers
     * returns the stored result; different answers → ATTEMPT_ALREADY_SUBMITTED (§15.5).
     */
    async submit(
      userId: string,
      id: string,
      body: {
        answers: (Answer & { questionId: string; flagged?: boolean | undefined })[];
        timeSpentMs?: number | undefined;
      },
    ): Promise<AttemptView> {
      const attempt = await owned(userId, id);
      const inAttempt = new Set(attempt.questionOrder);
      if (new Set(body.answers.map((a) => a.questionId)).size !== body.answers.length)
        invalid('answers', 'duplicate');
      if (body.answers.some((a) => !inAttempt.has(a.questionId))) invalid('answers', 'unknown_question');
      const content = await withContent(attempt.questionOrder);
      for (const a of body.answers) {
        const q = content.get(a.questionId);
        if (q && (a.selectedOptionId || a.writtenAnswer != null)) {
          if (q.type === 'written' && a.selectedOptionId) invalid('selectedOptionId');
          if (q.type !== 'written' && a.writtenAnswer != null) invalid('writtenAnswer');
        }
      }
      const { mistakeMasteryStreak } = await config.getLearningSettings();

      const final = await db.transaction(async (tx) => {
        const locked = (await repo.getForUpdate(tx, id, userId))!;
        const stored = new Map((await repo.answers(id, tx)).map((a) => [a.questionId, a]));
        if (locked.status === 'submitted') {
          const differs = body.answers.some((a) => {
            const s = stored.get(a.questionId);
            return (given(a) || given(s ?? {})) && !sameAnswer(s, a);
          });
          if (differs) throw new AppError('ATTEMPT_ALREADY_SUBMITTED');
          return locked;
        }
        const at = now();
        const incoming = new Map(body.answers.map((a) => [a.questionId, a]));
        let correct = 0;
        for (const qid of locked.questionOrder) {
          const q = content.get(qid);
          const prev = stored.get(qid);
          if (prev?.gradedAt) {
            if (prev.isCorrect) correct += 1;
            continue;
          }
          // Practice answers already checked keep their grade; everything else uses the latest answer.
          const a: Answer & { flagged?: boolean | undefined } = incoming.get(qid) ?? {
            selectedOptionId: prev?.selectedOptionId ?? null,
            writtenAnswer: prev?.writtenAnswer ?? null,
            timeSpentMs: prev?.timeSpentMs ?? null,
          };
          if (!q) continue;
          if (given(a)) {
            const result = gradeStored(q, a);
            await applyGrade(tx, locked, q, a, result, at, mistakeMasteryStreak);
            if (result.isCorrect) correct += 1;
          } else {
            // Skipped: keep what the question looked like for the results screen.
            const snap = questionSnapshot(q) as unknown as Record<string, unknown>;
            await repo.upsertAnswer(
              tx,
              {
                attemptId: id,
                questionId: qid,
                userId,
                flagged: a.flagged ?? false,
                selectedOptionId: null,
                writtenAnswer: null,
                questionSnapshot: snap,
              },
              {
                selectedOptionId: null,
                writtenAnswer: null,
                questionSnapshot: snap,
                ...(a.flagged !== undefined ? { flagged: a.flagged } : {}),
              },
            );
          }
        }
        const late = locked.deadlineAt !== null && at.getTime() > locked.deadlineAt.getTime() + LATE_GRACE_MS;
        const elapsed = at.getTime() - locked.startedAt.getTime();
        return repo.update(tx, id, {
          status: 'submitted',
          submittedAt: at,
          submittedLate: late,
          correctCount: correct,
          scorePercent: locked.totalCount ? Math.round((correct * 100) / locked.totalCount) : 0,
          timeSpentMs: Math.min(body.timeSpentMs ?? elapsed, MAX_TIME_MS),
          lastActivityAt: at,
        });
      });
      return view(final);
    },

    /** Nightly job (§15.5). */
    abandonStale: () => repo.abandonStale(new Date(now().getTime() - ABANDON_AFTER_MS)),
  };
}

export type AttemptService = ReturnType<typeof createAttemptService>;
