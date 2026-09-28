import type { AdminQuiz, AdminQuizDetail, StudentQuiz } from '@plengo/contracts';
import type { Db, Tx } from '@plengo/db';
import { AppError } from '../lib/app-error.js';
import type { Scope } from '../repositories/access-repository.js';
import type { AttemptRepository } from '../repositories/attempt-repository.js';
import type { QuestionRepository, QuestionRow } from '../repositories/question-repository.js';
import type { QuizFilter, QuizRepository, QuizRow, QuizWithCount } from '../repositories/quiz-repository.js';
import type { StructureRepository } from '../repositories/structure-repository.js';
import type { TeacherRepository } from '../repositories/teacher-repository.js';
import { scopeOf, type AccessService } from './access-service.js';
import type { AuditService } from './audit-service.js';
import { assertVisibleScope, invalid, resolvePlacement, validateContentScope } from './content-placement.js';
import type { FreeContentSource, FreeRuleService } from './free-rule-service.js';
import type { AdminActor } from './structure-service.js';

type AccessContext = Awaited<ReturnType<AccessService['context']>>;

/** Plugs quizzes into the free-rule engine (§8.4). */
export function quizFreeSource(repo: QuizRepository): FreeContentSource {
  return {
    kind: 'quizzes',
    items: async (scope) =>
      (await repo.publishedInScope(scope)).map((r) => ({
        id: r.id,
        unitId: r.unitId,
        lessonId: r.lessonId,
        sortOrder: r.sortOrder,
        isFree: r.isFree,
        manual: r.freeSource === 'manual_override',
      })),
    applyRule: (scope, freeIds) => repo.applyRule(scope, freeIds),
  };
}

/**
 * Which of a quiz's published questions a student can open (§8.8). A quiz the student can open
 * (free, promoted or entitled) opens all its questions: they share its scope (§15.1.1). Otherwise
 * only free questions count. A mock exam is all-or-nothing.
 */
export function quizAccess(ctx: AccessContext, quiz: QuizRow, members: QuestionRow[]) {
  const quizOpen = ctx.canAccessItem(quiz);
  const open = members.filter((q) => quizOpen || ctx.canAccessItem(q));
  const locked = quiz.isMockExam ? open.length === 0 || open.length !== members.length : open.length === 0;
  const accessible = locked ? [] : open;
  return { total: members.length, accessible, locked };
}

interface QuizSettings {
  unitId?: string | null | undefined;
  lessonId?: string | null | undefined;
  titleAr?: string | undefined;
  description?: string | null | undefined;
  allowedModes?: QuizRow['allowedModes'] | undefined;
  timeLimitSeconds?: number | null | undefined;
  shuffleQuestions?: boolean | undefined;
  shuffleOptions?: boolean | undefined;
  passingScorePercent?: number | null | undefined;
  maxAttempts?: number | null | undefined;
  isMockExam?: boolean | undefined;
  allowOffline?: boolean | undefined;
}

const SETTING_KEYS = [
  'unitId',
  'lessonId',
  'titleAr',
  'description',
  'allowedModes',
  'timeLimitSeconds',
  'shuffleQuestions',
  'shuffleOptions',
  'passingScorePercent',
  'maxAttempts',
  'isMockExam',
  'allowOffline',
] as const;

/**
 * Curated quizzes (spec §15.1): admin authoring with the quiz-question scope invariant (§15.1.1) and
 * the student quiz lists with mixed-quiz counts (§8.8). Metadata, `allow_offline`, membership and
 * question order changes bump `content_version` (§22.3).
 */
export function createQuizService(deps: {
  db: Db;
  repo: QuizRepository;
  questionRepo: QuestionRepository;
  attemptRepo: AttemptRepository;
  structureRepo: StructureRepository;
  teacherRepo: TeacherRepository;
  access: AccessService;
  freeRules: FreeRuleService;
  audit: AuditService;
  now?: () => Date;
}) {
  const { db, repo, questionRepo, attemptRepo, structureRepo, teacherRepo, access, freeRules, audit } = deps;
  const now = deps.now ?? (() => new Date());
  const notFound = (): never => {
    throw new AppError('NOT_FOUND');
  };
  const record = (
    actor: AdminActor,
    action: string,
    id: string,
    metadata: Record<string, unknown> = {},
    tx?: Tx,
  ) =>
    audit.record(
      { actorAdminId: actor.adminId, action, resourceType: 'quiz', resourceId: id, metadata, ip: actor.ip },
      tx,
    );
  const quizScope = (q: { subjectId: string; teacherTrackId: string | null }): Scope => scopeOf(q);

  /** Settings that only make sense together. */
  function checkSettings(s: {
    allowedModes: QuizRow['allowedModes'];
    timeLimitSeconds: number | null;
    isMockExam: boolean;
  }) {
    if (s.timeLimitSeconds !== null && s.allowedModes === 'practice')
      invalid('timeLimitSeconds', 'exam_only');
    if (s.isMockExam && s.allowedModes !== 'exam') invalid('allowedModes', 'mock_exam_is_exam_only');
  }

  /**
   * §15.1.1: every question has the quiz's subject and exactly its track (both null for general
   * quizzes). Returns VALIDATION_ERROR listing the offending ids rather than including them.
   */
  async function assertMembers(quiz: { subjectId: string; teacherTrackId: string | null }, ids: string[]) {
    if (new Set(ids).size !== ids.length) invalid('questionIds', 'duplicate');
    if (!ids.length) return;
    const found = new Map((await questionRepo.byIds(ids)).map((q) => [q.id, q]));
    const bad = ids.filter((id) => {
      const q = found.get(id);
      return !q || q.deletedAt || q.subjectId !== quiz.subjectId || q.teacherTrackId !== quiz.teacherTrackId;
    });
    if (bad.length) {
      throw new AppError('VALIDATION_ERROR', {
        details: { field: 'questionIds', reason: 'scope_mismatch', questionIds: bad },
      });
    }
  }

  async function toAdmin(rows: QuizWithCount[]): Promise<AdminQuiz[]> {
    const names = await questionRepo.names(
      [...new Set(rows.map((r) => r.subjectId))],
      [...new Set(rows.flatMap((r) => (r.teacherTrackId ? [r.teacherTrackId] : [])))],
    );
    return rows.map((q) => ({
      id: q.id,
      subjectId: q.subjectId,
      subjectNameAr: names.subjects.get(q.subjectId) ?? '',
      teacherTrackId: q.teacherTrackId,
      trackTitleAr: q.teacherTrackId ? (names.tracks.get(q.teacherTrackId) ?? null) : null,
      unitId: q.unitId,
      lessonId: q.lessonId,
      titleAr: q.titleAr,
      description: q.description,
      allowedModes: q.allowedModes,
      timeLimitSeconds: q.timeLimitSeconds,
      shuffleQuestions: q.shuffleQuestions,
      shuffleOptions: q.shuffleOptions,
      passingScorePercent: q.passingScorePercent,
      maxAttempts: q.maxAttempts,
      isMockExam: q.isMockExam,
      allowOffline: q.allowOffline,
      isFree: q.isFree,
      freeSource: q.freeSource,
      status: q.status,
      sortOrder: q.sortOrder,
      contentVersion: q.contentVersion,
      questionCount: q.questionCount,
      createdAt: q.createdAt.toISOString(),
      updatedAt: q.updatedAt.toISOString(),
    }));
  }

  async function adminGet(id: string): Promise<AdminQuizDetail> {
    const quiz = (await repo.get(id)) ?? notFound();
    const members = await repo.memberQuestions(id);
    return {
      quiz: (await toAdmin([quiz]))[0]!,
      questions: members.map((q) => ({
        id: q.id,
        type: q.type,
        questionText: q.questionText,
        status: q.status,
        isFree: q.isFree,
        unitId: q.unitId,
        lessonId: q.lessonId,
        deleted: q.deletedAt !== null,
      })),
    };
  }

  const bump = (tx: Tx, quiz: QuizRow, actor: AdminActor) =>
    repo.update(tx, quiz.id, {
      contentVersion: quiz.contentVersion + 1,
      updatedByAdminId: actor.adminId,
      updatedAt: now(),
    });

  async function setStatus(actor: AdminActor, id: string, status: QuizRow['status']) {
    const quiz = (await repo.get(id)) ?? notFound();
    if (quiz.status === status) return adminGet(id);
    if (status === 'published') {
      // Re-validate the whole quiz before publishing (§15.1.1).
      const members = await repo.memberQuestions(id);
      if (!members.length) invalid('questionIds', 'empty_quiz');
      await assertMembers(
        quiz,
        members.map((m) => m.id),
      );
      const unpublished = members.filter((m) => m.status !== 'published').map((m) => m.id);
      if (unpublished.length) {
        throw new AppError('VALIDATION_ERROR', {
          details: { field: 'questionIds', reason: 'unpublished_questions', questionIds: unpublished },
        });
      }
      checkSettings(quiz);
    }
    await repo.update(db, id, { status, updatedByAdminId: actor.adminId, updatedAt: now() });
    if (status === 'published' && quiz.freeSource === 'rule') {
      await repo.update(db, id, { isFree: await freeRules.isFreeOnPublish(quizScope(quiz), 'quizzes', id) });
    }
    await record(
      actor,
      `quiz.${status === 'published' ? 'published' : status === 'archived' ? 'archived' : 'unpublished'}`,
      id,
    );
    return adminGet(id);
  }

  // ---- student ----

  async function toStudent(
    userId: string,
    ctx: AccessContext,
    quizzes: QuizWithCount[],
  ): Promise<StudentQuiz[]> {
    const ids = quizzes.map((q) => q.id);
    const [members, stats] = await Promise.all([
      repo.publishedMembers(ids),
      attemptRepo.quizStats(userId, ids),
    ]);
    return quizzes.map((quiz) => {
      const qs = members.filter((m) => m.quizId === quiz.id).map((m) => m.question);
      const a = quizAccess(ctx, quiz, qs);
      const s = stats.get(quiz.id);
      return {
        id: quiz.id,
        subjectId: quiz.subjectId,
        teacherTrackId: quiz.teacherTrackId,
        unitId: quiz.unitId,
        lessonId: quiz.lessonId,
        titleAr: quiz.titleAr,
        description: quiz.description,
        allowedModes: quiz.allowedModes,
        timeLimitSeconds: quiz.timeLimitSeconds,
        passingScorePercent: quiz.passingScorePercent,
        maxAttempts: quiz.maxAttempts,
        isMockExam: quiz.isMockExam,
        allowOffline: quiz.allowOffline,
        isFree: quiz.isFree,
        sortOrder: quiz.sortOrder,
        contentVersion: quiz.contentVersion,
        totalCount: a.total,
        accessibleCount: a.accessible.length,
        lockedCount: a.total - a.accessible.length,
        locked: a.locked,
        attemptsUsed: s?.used ?? 0,
        bestScorePercent: s?.best ?? null,
        inProgressAttemptId: s?.inProgressId ?? null,
      };
    });
  }

  async function publishedQuiz(id: string) {
    const quiz = await repo.get(id);
    if (!quiz || quiz.status !== 'published') notFound();
    await assertVisibleScope({ structureRepo, teacherRepo }, quiz!.subjectId, quiz!.teacherTrackId);
    return quiz!;
  }

  return {
    counts: (scope: Scope) => repo.scopeCounts(scope),
    publishedQuiz,

    // ---- admin ----

    async adminList(filter: QuizFilter) {
      return toAdmin(await repo.list(filter));
    },
    adminGet,

    async create(
      actor: AdminActor,
      input: QuizSettings & {
        subjectId: string;
        teacherTrackId?: string | null | undefined;
        titleAr: string;
        questionIds?: string[] | undefined;
      },
    ) {
      const trackId = input.teacherTrackId ?? null;
      await validateContentScope({ structureRepo, teacherRepo }, input.subjectId, trackId);
      const place = await resolvePlacement(
        structureRepo,
        input.subjectId,
        input.unitId ?? null,
        input.lessonId ?? null,
      );
      const isMockExam = input.isMockExam ?? false;
      const settings = {
        allowedModes: input.allowedModes ?? (isMockExam ? ('exam' as const) : ('both' as const)),
        timeLimitSeconds: input.timeLimitSeconds ?? null,
        isMockExam,
      };
      checkSettings(settings);
      const scoped = { subjectId: input.subjectId, teacherTrackId: trackId };
      await assertMembers(scoped, input.questionIds ?? []);
      const id = await db.transaction(async (tx) => {
        const row = await repo.insert(tx, {
          ...scoped,
          ...place,
          ...settings,
          titleAr: input.titleAr,
          description: input.description ?? null,
          shuffleQuestions: input.shuffleQuestions ?? false,
          shuffleOptions: input.shuffleOptions ?? false,
          passingScorePercent: input.passingScorePercent ?? null,
          maxAttempts: input.maxAttempts ?? null,
          // Mock exams stay out of offline packs unless the admin says otherwise (§22.2).
          allowOffline: input.allowOffline ?? !isMockExam,
          sortOrder: await repo.nextSortOrder(tx, quizScope(scoped)),
          createdByAdminId: actor.adminId,
          updatedByAdminId: actor.adminId,
        });
        await repo.setMembers(tx, row.id, input.questionIds ?? []);
        await record(actor, 'quiz.created', row.id, { ...quizScope(scoped) }, tx);
        return row.id;
      });
      return adminGet(id);
    },

    async update(actor: AdminActor, id: string, patch: QuizSettings) {
      const current = (await repo.get(id)) ?? notFound();
      const place = await resolvePlacement(
        structureRepo,
        current.subjectId,
        patch.unitId !== undefined ? patch.unitId : current.unitId,
        patch.lessonId !== undefined ? patch.lessonId : current.lessonId,
      );
      const next = { ...current, ...place };
      for (const key of SETTING_KEYS) {
        if (key === 'unitId' || key === 'lessonId' || patch[key] === undefined) continue;
        (next as Record<string, unknown>)[key] = patch[key];
      }
      checkSettings(next);
      const changed = SETTING_KEYS.filter((k) => next[k] !== current[k]);
      if (!changed.length) return adminGet(id);
      await db.transaction(async (tx) => {
        const locked = (await repo.getForUpdate(tx, id)) ?? notFound();
        await repo.update(tx, id, {
          ...Object.fromEntries(changed.map((k) => [k, next[k]])),
          contentVersion: locked.contentVersion + 1,
          updatedByAdminId: actor.adminId,
          updatedAt: now(),
        });
        await record(actor, 'quiz.updated', id, { changed, contentVersion: locked.contentVersion + 1 }, tx);
      });
      return adminGet(id);
    },

    /** Replaces membership and order (add, import, remove, reorder), checking §15.1.1. */
    async setQuestions(actor: AdminActor, id: string, questionIds: string[]) {
      const current = (await repo.get(id)) ?? notFound();
      await assertMembers(current, questionIds);
      const before = (await repo.memberQuestions(id)).map((q) => q.id);
      if (before.length === questionIds.length && before.every((q, i) => q === questionIds[i]))
        return adminGet(id);
      if (current.status === 'published') {
        if (!questionIds.length) invalid('questionIds', 'empty_quiz');
        const rows = await questionRepo.byIds(questionIds);
        const unpublished = rows.filter((q) => q.status !== 'published').map((q) => q.id);
        if (unpublished.length) {
          throw new AppError('VALIDATION_ERROR', {
            details: { field: 'questionIds', reason: 'unpublished_questions', questionIds: unpublished },
          });
        }
      }
      await db.transaction(async (tx) => {
        const locked = (await repo.getForUpdate(tx, id)) ?? notFound();
        await repo.setMembers(tx, id, questionIds);
        await bump(tx, locked, actor);
        await record(actor, 'quiz.questions_set', id, { count: questionIds.length }, tx);
      });
      return adminGet(id);
    },

    setStatus,

    async setFree(actor: AdminActor, id: string, mode: 'rule' | 'free' | 'paid') {
      const quiz = (await repo.get(id)) ?? notFound();
      const values =
        mode === 'rule'
          ? {
              freeSource: 'rule' as const,
              isFree:
                quiz.status === 'published'
                  ? await freeRules.isFreeOnPublish(quizScope(quiz), 'quizzes', id)
                  : false,
            }
          : { freeSource: 'manual_override' as const, isFree: mode === 'free' };
      await repo.update(db, id, { ...values, updatedByAdminId: actor.adminId, updatedAt: now() });
      await record(actor, 'quiz.free_override', id, { mode, isFree: values.isFree });
      return adminGet(id);
    },

    /** `ids` must be every live sibling quiz (same subject, track, unit and lesson) in the new order. */
    async reorder(actor: AdminActor, ids: string[]) {
      const first = (await repo.get(ids[0]!)) ?? notFound();
      const siblings = new Set((await repo.siblings(first)).map((s) => s.id));
      if (
        siblings.size !== ids.length ||
        new Set(ids).size !== ids.length ||
        ids.some((i) => !siblings.has(i))
      ) {
        invalid('ids', 'not_all_siblings');
      }
      await db.transaction(async (tx) => {
        for (const [i, id] of ids.entries()) await repo.update(tx, id, { sortOrder: i });
      });
      await record(actor, 'quiz.reordered', first.id, { ids });
      return { reordered: true };
    },

    /** Soft delete; attempts keep their snapshots. */
    async remove(actor: AdminActor, id: string) {
      if (!(await repo.get(id))) notFound();
      await repo.update(db, id, { deletedAt: now(), updatedByAdminId: actor.adminId });
      await record(actor, 'quiz.deleted', id);
      return { deleted: true };
    },

    // ---- student ----

    async studentList(
      userId: string,
      q: {
        subjectId: string;
        teacherTrackId?: string | undefined;
        unitId?: string | undefined;
        lessonId?: string | undefined;
      },
    ) {
      await assertVisibleScope({ structureRepo, teacherRepo }, q.subjectId, q.teacherTrackId ?? null);
      const [quizzes, ctx] = await Promise.all([
        repo.list({
          subjectId: q.subjectId,
          teacherTrackId: q.teacherTrackId,
          generalOnly: !q.teacherTrackId,
          unitId: q.unitId,
          lessonId: q.lessonId,
          status: 'published',
        }),
        access.context(userId),
      ]);
      return toStudent(userId, ctx, quizzes);
    },

    async studentGet(userId: string, id: string): Promise<StudentQuiz> {
      const quiz = await publishedQuiz(id);
      return (await toStudent(userId, await access.context(userId), [quiz]))[0]!;
    },
  };
}

export type QuizService = ReturnType<typeof createQuizService>;
