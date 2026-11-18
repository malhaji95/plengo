import { and, asc, eq, inArray, isNull, or, sql, type SQL } from 'drizzle-orm';
import { questionCategories, questions, subjects, type Db } from '@plengo/db';
import type { Scope } from './access-repository.js';
import { questionScopeWhere } from './question-repository.js';

export type CategoryRow = typeof questionCategories.$inferSelect;

const live = isNull(questionCategories.deletedAt);

/** Live questions filed directly under the category (children not included). */
const questionCount = sql<number>`(select count(*)::int from questions q where q.category_id = "question_categories"."id" and q.deleted_at is null)`;

/** Question categories (v3 §3): global (no subject) or of one subject; soft-deleted. */
export function createQuestionCategoryRepository(db: Db) {
  return {
    /**
     * Live categories. `subjectId` alone: that subject's and the global ones; `subjectOnly`: only
     * the subject's; `globalOnly`: only the global ones. Global first, then by sort order.
     */
    list: (f: { subjectId?: string | undefined; subjectOnly?: boolean; globalOnly?: boolean } = {}) => {
      let where: SQL | undefined;
      if (f.globalOnly) where = isNull(questionCategories.subjectId);
      else if (f.subjectId && f.subjectOnly) where = eq(questionCategories.subjectId, f.subjectId);
      else if (f.subjectId)
        where = or(isNull(questionCategories.subjectId), eq(questionCategories.subjectId, f.subjectId));
      return db
        .select({ category: questionCategories, subjectNameAr: subjects.nameAr, questionCount })
        .from(questionCategories)
        .leftJoin(subjects, eq(subjects.id, questionCategories.subjectId))
        .where(and(live, where))
        .orderBy(
          sql`${questionCategories.subjectId} is not null`,
          asc(questionCategories.sortOrder),
          asc(questionCategories.nameAr),
          asc(questionCategories.id),
        );
    },

    async get(id: string) {
      const [row] = await db
        .select()
        .from(questionCategories)
        .where(and(eq(questionCategories.id, id), live));
      return row ?? null;
    },

    /** Live categories by id. */
    byIds: async (ids: string[]) =>
      ids.length
        ? db
            .select()
            .from(questionCategories)
            .where(and(inArray(questionCategories.id, ids), live))
        : [],

    /** Every live category usable in these subjects (theirs and the global ones), for imports. */
    usableIn: (subjectIds: string[]) =>
      db
        .select()
        .from(questionCategories)
        .where(
          and(
            live,
            subjectIds.length
              ? or(isNull(questionCategories.subjectId), inArray(questionCategories.subjectId, subjectIds))
              : isNull(questionCategories.subjectId),
          ),
        ),

    async nextSortOrder(subjectId: string | null) {
      const [row] = await db
        .select({ max: sql<number | null>`max(${questionCategories.sortOrder})` })
        .from(questionCategories)
        .where(
          and(
            live,
            subjectId ? eq(questionCategories.subjectId, subjectId) : isNull(questionCategories.subjectId),
          ),
        );
      return (row?.max ?? 0) + 1;
    },

    async insert(values: typeof questionCategories.$inferInsert) {
      const [row] = await db.insert(questionCategories).values(values).returning();
      return row!;
    },

    async update(id: string, values: Partial<typeof questionCategories.$inferInsert>) {
      const [row] = await db
        .update(questionCategories)
        .set(values)
        .where(eq(questionCategories.id, id))
        .returning();
      return row!;
    },

    /** Soft delete; its live questions keep existing without a category. */
    async remove(id: string, at: Date) {
      await db.transaction(async (tx) => {
        await tx.update(questions).set({ categoryId: null }).where(eq(questions.categoryId, id));
        await tx
          .update(questionCategories)
          .set({ deletedAt: at, updatedAt: at })
          .where(eq(questionCategories.id, id));
      });
    },

    /** Live categories whose parent is `id`. */
    children: (id: string) =>
      db
        .select({ id: questionCategories.id })
        .from(questionCategories)
        .where(and(live, eq(questionCategories.parentId, id))),

    /**
     * Published questions of a scope (and optionally a unit or lesson) per category; the null key
     * counts questions without a category.
     */
    publishedCounts: (
      scope: Scope,
      placement: { unitId?: string | undefined; lessonId?: string | undefined },
    ) =>
      db
        .select({
          categoryId: questions.categoryId,
          total: sql<number>`count(*)::int`,
          free: sql<number>`count(*) filter (where ${questions.isFree})::int`,
        })
        .from(questions)
        .where(
          and(
            isNull(questions.deletedAt),
            eq(questions.status, 'published'),
            questionScopeWhere(scope),
            placement.unitId ? eq(questions.unitId, placement.unitId) : undefined,
            placement.lessonId ? eq(questions.lessonId, placement.lessonId) : undefined,
          ),
        )
        .groupBy(questions.categoryId),
  };
}

export type QuestionCategoryRepository = ReturnType<typeof createQuestionCategoryRepository>;
