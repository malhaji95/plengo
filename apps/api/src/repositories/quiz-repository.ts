import { and, asc, count, eq, getTableColumns, inArray, isNull, sql, type SQL } from 'drizzle-orm';
import { lessons, questions, quizQuestions, quizzes, units, type Db, type Tx } from '@plengo/db';
import type { Scope } from './access-repository.js';

export type QuizRow = typeof quizzes.$inferSelect;
export type QuizWithCount = QuizRow & { questionCount: number };

type Conn = Db | Tx;

const liveQuiz = isNull(quizzes.deletedAt);

export function quizScopeWhere(scope: Scope): SQL {
  return scope.scopeType === 'subject'
    ? and(eq(quizzes.subjectId, scope.subjectId), isNull(quizzes.teacherTrackId))!
    : eq(quizzes.teacherTrackId, scope.teacherTrackId);
}

export interface QuizFilter {
  subjectId?: string | undefined;
  teacherTrackId?: string | undefined;
  generalOnly?: boolean | undefined;
  unitId?: string | undefined;
  lessonId?: string | undefined;
  status?: QuizRow['status'] | undefined;
}

/** Published live member questions. Raw SQL with aliases: single-table selects drop qualifiers. */
const questionCount = sql<number>`(select count(*)::int from quiz_questions qq join questions q on q.id = qq.question_id where qq.quiz_id = "quizzes"."id" and q.deleted_at is null and q.status = 'published')`;

export function createQuizRepository(db: Db) {
  return {
    async get(id: string, conn: Conn = db): Promise<QuizWithCount | null> {
      const [row] = await conn
        .select({ ...getTableColumns(quizzes), questionCount })
        .from(quizzes)
        .where(and(eq(quizzes.id, id), liveQuiz));
      return row ?? null;
    },

    async getForUpdate(tx: Tx, id: string) {
      const [row] = await tx
        .select()
        .from(quizzes)
        .where(and(eq(quizzes.id, id), liveQuiz))
        .for('update');
      return row ?? null;
    },

    /** Quizzes in reading order (the order free rules use, §8.4). */
    list: (f: QuizFilter): Promise<QuizWithCount[]> =>
      db
        .select({ ...getTableColumns(quizzes), questionCount })
        .from(quizzes)
        .leftJoin(units, eq(units.id, quizzes.unitId))
        .leftJoin(lessons, eq(lessons.id, quizzes.lessonId))
        .where(
          and(
            liveQuiz,
            f.subjectId ? eq(quizzes.subjectId, f.subjectId) : undefined,
            f.teacherTrackId ? eq(quizzes.teacherTrackId, f.teacherTrackId) : undefined,
            f.generalOnly ? isNull(quizzes.teacherTrackId) : undefined,
            f.unitId ? eq(quizzes.unitId, f.unitId) : undefined,
            f.lessonId ? eq(quizzes.lessonId, f.lessonId) : undefined,
            f.status ? eq(quizzes.status, f.status) : undefined,
          ),
        )
        .orderBy(
          asc(quizzes.subjectId),
          sql`case when ${quizzes.unitId} is not null then 0 when ${quizzes.lessonId} is not null then 1 else 2 end`,
          asc(units.sortOrder),
          asc(units.id),
          sql`case when ${quizzes.lessonId} is null then 0 else 1 end`,
          asc(lessons.sortOrder),
          asc(lessons.id),
          asc(quizzes.sortOrder),
          asc(quizzes.id),
        ),

    async scopeCounts(scope: Scope) {
      const [row] = await db
        .select({ total: count(), free: sql<number>`count(*) filter (where ${quizzes.isFree})::int` })
        .from(quizzes)
        .where(and(liveQuiz, eq(quizzes.status, 'published'), quizScopeWhere(scope)));
      return { total: row!.total, free: row!.free };
    },

    publishedInScope: (scope: Scope) =>
      db
        .select({
          id: quizzes.id,
          unitId: quizzes.unitId,
          lessonId: quizzes.lessonId,
          sortOrder: quizzes.sortOrder,
          isFree: quizzes.isFree,
          freeSource: quizzes.freeSource,
        })
        .from(quizzes)
        .where(and(liveQuiz, eq(quizzes.status, 'published'), quizScopeWhere(scope))),

    async applyRule(scope: Scope, freeIds: Set<string>) {
      const ids = [...freeIds];
      await db
        .update(quizzes)
        .set({ isFree: ids.length ? inArray(quizzes.id, ids) : sql`false` })
        .where(
          and(
            liveQuiz,
            eq(quizzes.status, 'published'),
            eq(quizzes.freeSource, 'rule'),
            quizScopeWhere(scope),
          ),
        );
    },

    async nextSortOrder(conn: Conn, scope: Scope) {
      const [row] = await conn
        .select({ max: sql<number | null>`max(${quizzes.sortOrder})` })
        .from(quizzes)
        .where(and(liveQuiz, quizScopeWhere(scope)));
      return (row?.max ?? -1) + 1;
    },

    async insert(conn: Conn, values: typeof quizzes.$inferInsert) {
      const [row] = await conn.insert(quizzes).values(values).returning();
      return row!;
    },

    async update(conn: Conn, id: string, values: Partial<typeof quizzes.$inferInsert>) {
      const [row] = await conn.update(quizzes).set(values).where(eq(quizzes.id, id)).returning();
      return row!;
    },

    siblings: (q: QuizRow) =>
      db
        .select({ id: quizzes.id })
        .from(quizzes)
        .where(
          and(
            liveQuiz,
            eq(quizzes.subjectId, q.subjectId),
            q.teacherTrackId ? eq(quizzes.teacherTrackId, q.teacherTrackId) : isNull(quizzes.teacherTrackId),
            q.unitId ? eq(quizzes.unitId, q.unitId) : isNull(quizzes.unitId),
            q.lessonId ? eq(quizzes.lessonId, q.lessonId) : isNull(quizzes.lessonId),
          ),
        ),

    /** Member questions in quiz order, including unpublished or deleted ones (admin view). */
    memberQuestions: (quizId: string, conn: Conn = db) =>
      conn
        .select(getTableColumns(questions))
        .from(quizQuestions)
        .innerJoin(questions, eq(questions.id, quizQuestions.questionId))
        .where(eq(quizQuestions.quizId, quizId))
        .orderBy(asc(quizQuestions.sortOrder), asc(questions.id)),

    /** Published live member questions of several quizzes, in quiz order. */
    async publishedMembers(quizIds: string[]) {
      if (!quizIds.length) return [];
      return db
        .select({ quizId: quizQuestions.quizId, question: questions })
        .from(quizQuestions)
        .innerJoin(questions, eq(questions.id, quizQuestions.questionId))
        .where(
          and(
            inArray(quizQuestions.quizId, quizIds),
            isNull(questions.deletedAt),
            eq(questions.status, 'published'),
          ),
        )
        .orderBy(asc(quizQuestions.sortOrder), asc(questions.id));
    },

    async setMembers(tx: Tx, quizId: string, questionIds: string[]) {
      await tx.delete(quizQuestions).where(eq(quizQuestions.quizId, quizId));
      if (questionIds.length) {
        await tx
          .insert(quizQuestions)
          .values(questionIds.map((questionId, i) => ({ quizId, questionId, sortOrder: i })));
      }
    },
  };
}

export type QuizRepository = ReturnType<typeof createQuizRepository>;
