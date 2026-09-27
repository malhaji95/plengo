import { NORMALIZATION_VERSION, normalizeArabic } from '@plengo/arabic-normalizer';
import type { AdminQuestion, CheckResult, StudentQuestion } from '@plengo/contracts';
import { type Db } from '@plengo/db';
import { AppError } from '../lib/app-error.js';
import type { Scope } from '../repositories/access-repository.js';
import type {
  QuestionFilter,
  QuestionRepository,
  QuestionRow,
  QuestionWithContent,
} from '../repositories/question-repository.js';
import type { StructureRepository } from '../repositories/structure-repository.js';
import type { TeacherRepository } from '../repositories/teacher-repository.js';
import { scopeOf, type AccessService } from './access-service.js';
import { assertVisibleScope, invalid, resolvePlacement, validateContentScope } from './content-placement.js';
import type { AuditService } from './audit-service.js';
import type { FreeContentSource, FreeRuleService } from './free-rule-service.js';
import { grade, type AnswerInput } from './grading.js';
import type { AdminActor } from './structure-service.js';

/** Fixed options of a true/false question (§14.1). */
export const TRUE_FALSE_OPTIONS = ['صح', 'خطأ'] as const;

type OptionInput = { id?: string | undefined; text: string; isCorrect: boolean };

interface ContentInput {
  unitId?: string | null | undefined;
  lessonId?: string | null | undefined;
  questionText?: string | undefined;
  explanation?: string | null | undefined;
  difficulty?: QuestionRow['difficulty'] | undefined;
  options?: OptionInput[] | undefined;
  trueFalseAnswer?: boolean | undefined;
  acceptedAnswers?: string[] | undefined;
}

/** A question's scope: the track when it has one, otherwise the subject's general content (§8.1). */
export const questionScope = (q: { subjectId: string; teacherTrackId: string | null }): Scope => scopeOf(q);

/** The free-content source that plugs questions into the free-rule engine (§8.4). */
export function questionFreeSource(repo: QuestionRepository): FreeContentSource {
  return {
    kind: 'questions',
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
 * Questions (spec §14): admin authoring and the student read/check endpoints. Student payloads never
 * include correctness or accepted answers; locked questions are metadata only (§8.6, §14.3).
 */
export function createQuestionService(deps: {
  db: Db;
  repo: QuestionRepository;
  structureRepo: StructureRepository;
  teacherRepo: TeacherRepository;
  access: AccessService;
  freeRules: FreeRuleService;
  audit: AuditService;
  now?: () => Date;
}) {
  const { db, repo, structureRepo, teacherRepo, access, freeRules, audit } = deps;
  const now = deps.now ?? (() => new Date());
  const notFound = (): never => {
    throw new AppError('NOT_FOUND');
  };

  /** Options and accepted answers for a type; throws VALIDATION_ERROR with the offending field. */
  function content(type: QuestionRow['type'], input: ContentInput, existingOptions: { id: string }[]) {
    if (type === 'mcq') {
      const options = input.options ?? [];
      if (options.length < 2 || options.length > 6) invalid('options', 'count');
      if (options.filter((o) => o.isCorrect).length !== 1) invalid('options', 'one_correct');
      if (new Set(options.map((o) => o.text.trim())).size !== options.length) invalid('options', 'duplicate');
      return { options, answers: [] };
    }
    if (type === 'true_false') {
      if (input.trueFalseAnswer === undefined) invalid('trueFalseAnswer');
      const options = TRUE_FALSE_OPTIONS.map((text, i) => ({
        id: existingOptions[i]?.id,
        text,
        isCorrect: (i === 0) === input.trueFalseAnswer,
      }));
      return { options, answers: [] };
    }
    const accepted = (input.acceptedAnswers ?? []).map((original) => ({
      original: original.trim(),
      normalized: normalizeArabic(original),
    }));
    if (accepted.length < 1 || accepted.length > 10) invalid('acceptedAnswers', 'count');
    if (accepted.some((a) => !a.normalized)) invalid('acceptedAnswers', 'empty');
    if (new Set(accepted.map((a) => a.normalized)).size !== accepted.length)
      invalid('acceptedAnswers', 'duplicate');
    return { options: [], answers: accepted };
  }

  const placement = (subjectId: string, unitId: string | null, lessonId: string | null) =>
    resolvePlacement(structureRepo, subjectId, unitId, lessonId);

  async function toAdmin(rows: QuestionWithContent[]): Promise<AdminQuestion[]> {
    const names = await repo.names(
      [...new Set(rows.map((r) => r.subjectId))],
      [...new Set(rows.flatMap((r) => (r.teacherTrackId ? [r.teacherTrackId] : [])))],
    );
    return rows.map((q) => ({
      id: q.id,
      type: q.type,
      subjectId: q.subjectId,
      subjectNameAr: names.subjects.get(q.subjectId) ?? '',
      teacherTrackId: q.teacherTrackId,
      trackTitleAr: q.teacherTrackId ? (names.tracks.get(q.teacherTrackId) ?? null) : null,
      unitId: q.unitId,
      lessonId: q.lessonId,
      questionText: q.questionText,
      explanation: q.explanation,
      difficulty: q.difficulty,
      isFree: q.isFree,
      freeSource: q.freeSource,
      status: q.status,
      sortOrder: q.sortOrder,
      contentVersion: q.contentVersion,
      options: q.options.map((o) => ({
        id: o.id,
        text: o.text,
        isCorrect: o.isCorrect,
        sortOrder: o.sortOrder,
      })),
      acceptedAnswers: q.answers.map((a) => ({
        id: a.id,
        answerOriginal: a.answerOriginal,
        answerNormalized: a.answerNormalized,
        normalizationVersion: a.normalizationVersion,
      })),
      createdAt: q.createdAt.toISOString(),
      updatedAt: q.updatedAt.toISOString(),
    }));
  }

  async function adminGet(id: string) {
    return (await toAdmin([(await repo.get(id)) ?? notFound()]))[0]!;
  }

  /** Free flag for a question being published or put back on the rule (§8.4). */
  async function ruleFree(q: QuestionRow) {
    return q.status === 'published' ? freeRules.isFreeOnPublish(questionScope(q), 'questions', q.id) : false;
  }

  const record = (actor: AdminActor, action: string, id: string, metadata: Record<string, unknown> = {}) =>
    audit.record({
      actorAdminId: actor.adminId,
      action,
      resourceType: 'question',
      resourceId: id,
      metadata,
      ip: actor.ip,
    });

  /**
   * Publishing evaluates the scope's free rule for this question only; other items never change
   * when content is added (§8.4). Archived questions disappear for students.
   */
  async function setStatus(
    actor: AdminActor,
    id: string,
    status: QuestionRow['status'],
  ): Promise<AdminQuestion> {
    const current = (await repo.get(id)) ?? notFound();
    if (current.status === status) return adminGet(id);
    if (status === 'published') {
      // Content saved before a validation change must still be complete.
      content(
        current.type,
        {
          options: current.options,
          trueFalseAnswer: current.options[0]?.isCorrect,
          acceptedAnswers: current.answers.map((a) => a.answerOriginal),
        },
        current.options,
      );
    }
    await repo.update(db, id, { status, updatedByAdminId: actor.adminId, updatedAt: now() });
    if (status === 'published' && current.freeSource === 'rule') {
      await repo.update(db, id, { isFree: await ruleFree({ ...current, status }) });
    }
    await record(
      actor,
      `question.${status === 'published' ? 'published' : status === 'archived' ? 'archived' : 'unpublished'}`,
      id,
    );
    return adminGet(id);
  }

  // ---- student helpers ----

  const visibleScope = (subjectId: string, trackId: string | null) =>
    assertVisibleScope({ structureRepo, teacherRepo }, subjectId, trackId);

  async function publishedQuestion(id: string) {
    const q = await repo.get(id);
    if (!q || q.status !== 'published') notFound();
    await visibleScope(q!.subjectId, q!.teacherTrackId);
    return q!;
  }

  const toStudent = (
    q: QuestionRow,
    locked: boolean,
    options?: QuestionWithContent['options'],
  ): StudentQuestion => ({
    id: q.id,
    type: q.type,
    subjectId: q.subjectId,
    teacherTrackId: q.teacherTrackId,
    unitId: q.unitId,
    lessonId: q.lessonId,
    sortOrder: q.sortOrder,
    difficulty: q.difficulty,
    isFree: q.isFree,
    locked,
    questionText: locked ? null : q.questionText,
    // Never `isCorrect` (§14.3).
    options: locked || !options ? null : options.map((o) => ({ id: o.id, text: o.text })),
  });

  return {
    // ---- admin ----

    async adminList(filter: QuestionFilter, cursor: string | undefined, limit: number) {
      const page = await repo.page(filter, cursor, limit);
      return {
        items: await toAdmin(await repo.attachContent(page.items)),
        nextCursor: page.nextCursor,
        totalCount: page.total,
      };
    },

    adminGet,

    normalizePreview: (answers: string[]) => ({
      normalizationVersion: NORMALIZATION_VERSION,
      items: answers.map((original) => ({ original, normalized: normalizeArabic(original) })),
    }),

    async create(
      actor: AdminActor,
      input: ContentInput & {
        type: QuestionRow['type'];
        subjectId: string;
        teacherTrackId?: string | null | undefined;
        questionText: string;
        publish?: boolean | undefined;
      },
    ): Promise<AdminQuestion> {
      const trackId = input.teacherTrackId ?? null;
      await validateContentScope({ structureRepo, teacherRepo }, input.subjectId, trackId);
      const place = await placement(input.subjectId, input.unitId ?? null, input.lessonId ?? null);
      const body = content(input.type, input, []);
      const scope = questionScope({ subjectId: input.subjectId, teacherTrackId: trackId });
      const at = now();

      const id = await db.transaction(async (tx) => {
        const q = await repo.insert(tx, {
          type: input.type,
          subjectId: input.subjectId,
          teacherTrackId: trackId,
          ...place,
          questionText: input.questionText,
          explanation: input.explanation ?? null,
          difficulty: input.difficulty ?? null,
          sortOrder: await repo.nextSortOrder(tx, scope),
          createdByAdminId: actor.adminId,
          updatedByAdminId: actor.adminId,
          createdAt: at,
          updatedAt: at,
        });
        if (body.options.length) await repo.syncOptions(tx, q.id, body.options);
        if (body.answers.length) await repo.syncAnswers(tx, q.id, body.answers, NORMALIZATION_VERSION);
        await audit.record(
          {
            actorAdminId: actor.adminId,
            action: 'question.created',
            resourceType: 'question',
            resourceId: q.id,
            metadata: { type: input.type, ...scope },
            ip: actor.ip,
          },
          tx,
        );
        return q.id;
      });
      if (input.publish) return setStatus(actor, id, 'published');
      return adminGet(id);
    },

    /**
     * Edits content or placement. Any change to text, explanation, difficulty, options or accepted
     * answers bumps `content_version` (§22.3). Publishing re-uses the same validation.
     */
    async update(actor: AdminActor, id: string, patch: ContentInput): Promise<AdminQuestion> {
      const current = (await repo.get(id)) ?? notFound();
      const merged: ContentInput = {
        unitId: patch.unitId !== undefined ? patch.unitId : current.unitId,
        lessonId: patch.lessonId !== undefined ? patch.lessonId : current.lessonId,
        questionText: patch.questionText ?? current.questionText,
        explanation: patch.explanation !== undefined ? patch.explanation : current.explanation,
        difficulty: patch.difficulty !== undefined ? patch.difficulty : current.difficulty,
        options: patch.options ?? current.options,
        trueFalseAnswer:
          patch.trueFalseAnswer ??
          (current.type === 'true_false' ? current.options[0]?.isCorrect : undefined),
        acceptedAnswers: patch.acceptedAnswers ?? current.answers.map((a) => a.answerOriginal),
      };
      // Moving between units/lessons is placement only and does not bump the version.
      const place = await placement(current.subjectId, merged.unitId ?? null, merged.lessonId ?? null);
      const body = content(current.type, merged, current.options);

      const sameOptions =
        current.type === 'written' ||
        (body.options.length === current.options.length &&
          body.options.every(
            (o, i) => o.text === current.options[i]!.text && o.isCorrect === current.options[i]!.isCorrect,
          ));
      const sameAnswers =
        current.type !== 'written' ||
        (body.answers.length === current.answers.length &&
          body.answers.every(
            (a, i) =>
              a.original === current.answers[i]!.answerOriginal &&
              current.answers[i]!.normalizationVersion === NORMALIZATION_VERSION,
          ));
      const contentChanged =
        merged.questionText !== current.questionText ||
        (merged.explanation ?? null) !== current.explanation ||
        (merged.difficulty ?? null) !== current.difficulty ||
        !sameOptions ||
        !sameAnswers;
      const placementChanged = place.unitId !== current.unitId || place.lessonId !== current.lessonId;
      if (!contentChanged && !placementChanged) return adminGet(id);

      await db.transaction(async (tx) => {
        const locked = (await repo.getForUpdate(tx, id)) ?? notFound();
        await repo.update(tx, id, {
          ...place,
          questionText: merged.questionText!,
          explanation: merged.explanation ?? null,
          difficulty: merged.difficulty ?? null,
          contentVersion: contentChanged ? locked.contentVersion + 1 : locked.contentVersion,
          updatedByAdminId: actor.adminId,
          updatedAt: now(),
        });
        if (!sameOptions) await repo.syncOptions(tx, id, body.options);
        if (!sameAnswers) await repo.syncAnswers(tx, id, body.answers, NORMALIZATION_VERSION);
        await audit.record(
          {
            actorAdminId: actor.adminId,
            action: 'question.updated',
            resourceType: 'question',
            resourceId: id,
            metadata: {
              contentChanged,
              placementChanged,
              contentVersion: locked.contentVersion + (contentChanged ? 1 : 0),
            },
            ip: actor.ip,
          },
          tx,
        );
      });
      return adminGet(id);
    },

    setStatus,

    /** Manual free/paid override, or back to the scope's rule (§8.4). Audited. */
    async setFree(actor: AdminActor, id: string, mode: 'rule' | 'free' | 'paid'): Promise<AdminQuestion> {
      const current = (await repo.get(id)) ?? notFound();
      const values =
        mode === 'rule'
          ? { freeSource: 'rule' as const, isFree: await ruleFree(current) }
          : { freeSource: 'manual_override' as const, isFree: mode === 'free' };
      await repo.update(db, id, { ...values, updatedByAdminId: actor.adminId, updatedAt: now() });
      await record(actor, 'question.free_override', id, { mode, isFree: values.isFree });
      return adminGet(id);
    },

    /** `ids` must be every live sibling (same subject, track, unit and lesson) in the new order. */
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
        for (const [i, qid] of ids.entries()) await repo.update(tx, qid, { sortOrder: i });
        await audit.record(
          {
            actorAdminId: actor.adminId,
            action: 'question.reordered',
            resourceType: 'question',
            resourceId: first.id,
            metadata: { ids },
            ip: actor.ip,
          },
          tx,
        );
      });
      return { reordered: true };
    },

    /** Soft delete; student history keeps its snapshots (§33). Audited. */
    async remove(actor: AdminActor, id: string) {
      if (!(await repo.get(id))) notFound();
      await repo.update(db, id, { deletedAt: now(), updatedByAdminId: actor.adminId });
      await record(actor, 'question.deleted', id);
      return { deleted: true };
    },

    /** Job (§14.5): recompute accepted answers stored by another normalizer version. */
    async renormalizeAnswers() {
      const stale = await repo.staleAnswers(NORMALIZATION_VERSION);
      for (const questionId of new Set(stale.map((a) => a.questionId))) {
        await db.transaction(async (tx) => {
          const q = (await repo.get(questionId, tx))!;
          const seen = new Set<string>();
          const answers = q.answers
            .map((a) => ({ original: a.answerOriginal, normalized: normalizeArabic(a.answerOriginal) }))
            .filter((a) => a.normalized && !seen.has(a.normalized) && seen.add(a.normalized));
          await repo.syncAnswers(tx, questionId, answers, NORMALIZATION_VERSION);
        });
      }
      return stale.length;
    },

    // ---- student ----

    counts: (scope: Scope) => repo.scopeCounts(scope),

    async studentList(
      userId: string,
      query: {
        subjectId: string;
        teacherTrackId?: string | undefined;
        unitId?: string | undefined;
        lessonId?: string | undefined;
        cursor?: string | undefined;
        limit: number;
      },
    ) {
      await visibleScope(query.subjectId, query.teacherTrackId ?? null);
      const filter: QuestionFilter = {
        subjectId: query.subjectId,
        teacherTrackId: query.teacherTrackId,
        generalOnly: !query.teacherTrackId,
        unitId: query.unitId,
        lessonId: query.lessonId,
        status: 'published',
      };
      const [page, counts, ctx] = await Promise.all([
        repo.page(filter, query.cursor, query.limit),
        repo.publishedCounts(filter),
        access.context(userId),
      ]);
      const scopeOpen = ctx.scopeAccess(
        questionScope({ subjectId: query.subjectId, teacherTrackId: query.teacherTrackId ?? null }),
      ).hasAccess;
      const accessible = page.items.filter((q) => ctx.canAccessItem(q));
      const withOptions = new Map((await repo.attachContent(accessible)).map((q) => [q.id, q.options]));
      return {
        items: page.items.map((q) => toStudent(q, !withOptions.has(q.id), withOptions.get(q.id))),
        nextCursor: page.nextCursor,
        totalCount: counts.total,
        accessibleCount: scopeOpen ? counts.total : counts.free,
      };
    },

    /** spec §37.5: a locked question answers CONTENT_LOCKED with no payload. */
    async studentGet(userId: string, id: string): Promise<StudentQuestion> {
      const q = await publishedQuestion(id);
      await access.assertCanAccessItem(userId, q);
      return toStudent(q, false, q.options);
    },

    async check(userId: string, id: string, input: AnswerInput): Promise<CheckResult> {
      const q = await publishedQuestion(id);
      await access.assertCanAccessItem(userId, q);
      return grade(q, input);
    },
  };
}

export type QuestionService = ReturnType<typeof createQuestionService>;
