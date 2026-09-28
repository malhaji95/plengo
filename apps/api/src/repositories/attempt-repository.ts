import { and, desc, eq, inArray, isNotNull, lt, sql } from 'drizzle-orm';
import { quizAttemptAnswers, quizAttempts, type Db, type Tx } from '@plengo/db';
import { decodeCursor, encodeCursor } from './question-repository.js';

export type AttemptRow = typeof quizAttempts.$inferSelect;
export type AnswerRow = typeof quizAttemptAnswers.$inferSelect;

type Conn = Db | Tx;

export function createAttemptRepository(db: Db) {
  return {
    /** Inserts once per (user, client id); a repeated start returns null and the caller reads the first. */
    async insert(tx: Tx, values: typeof quizAttempts.$inferInsert) {
      const [row] = await tx
        .insert(quizAttempts)
        .values(values)
        .onConflictDoNothing({ target: [quizAttempts.userId, quizAttempts.clientAttemptId] })
        .returning();
      return row ?? null;
    },

    /**
     * Serializes starts of one student's attempts at one quiz for the rest of the transaction, then
     * counts the attempts that use up `max_attempts`.
     */
    async lockAndCountUsed(tx: Tx, userId: string, quizId: string) {
      await tx.execute(sql`select pg_advisory_xact_lock(hashtext(${`${userId}:${quizId}`}))`);
      const [row] = await tx
        .select({ n: sql<number>`count(*)::int` })
        .from(quizAttempts)
        .where(
          and(
            eq(quizAttempts.userId, userId),
            eq(quizAttempts.quizId, quizId),
            sql`${quizAttempts.status} <> 'abandoned'`,
          ),
        );
      return row!.n;
    },

    async byClientId(userId: string, clientAttemptId: string, conn: Conn = db) {
      const [row] = await conn
        .select()
        .from(quizAttempts)
        .where(and(eq(quizAttempts.userId, userId), eq(quizAttempts.clientAttemptId, clientAttemptId)));
      return row ?? null;
    },

    async get(id: string, userId: string, conn: Conn = db) {
      const [row] = await conn
        .select()
        .from(quizAttempts)
        .where(and(eq(quizAttempts.id, id), eq(quizAttempts.userId, userId)));
      return row ?? null;
    },

    async getForUpdate(tx: Tx, id: string, userId: string) {
      const [row] = await tx
        .select()
        .from(quizAttempts)
        .where(and(eq(quizAttempts.id, id), eq(quizAttempts.userId, userId)))
        .for('update');
      return row ?? null;
    },

    async update(conn: Conn, id: string, values: Partial<typeof quizAttempts.$inferInsert>) {
      const [row] = await conn.update(quizAttempts).set(values).where(eq(quizAttempts.id, id)).returning();
      return row!;
    },

    answers: (attemptId: string, conn: Conn = db) =>
      conn.select().from(quizAttemptAnswers).where(eq(quizAttemptAnswers.attemptId, attemptId)),

    async answerCounts(attemptIds: string[]) {
      if (!attemptIds.length) return new Map<string, number>();
      const rows = await db
        .select({ attemptId: quizAttemptAnswers.attemptId, n: sql<number>`count(*)::int` })
        .from(quizAttemptAnswers)
        .where(
          and(
            inArray(quizAttemptAnswers.attemptId, attemptIds),
            sql`(${quizAttemptAnswers.selectedOptionId} is not null or ${quizAttemptAnswers.writtenAnswer} is not null)`,
          ),
        )
        .groupBy(quizAttemptAnswers.attemptId);
      return new Map(rows.map((r) => [r.attemptId, r.n]));
    },

    async upsertAnswer(
      tx: Tx,
      values: typeof quizAttemptAnswers.$inferInsert,
      set: Partial<typeof quizAttemptAnswers.$inferInsert>,
    ) {
      const [row] = await tx
        .insert(quizAttemptAnswers)
        .values(values)
        .onConflictDoUpdate({ target: [quizAttemptAnswers.attemptId, quizAttemptAnswers.questionId], set })
        .returning();
      return row!;
    },

    async list(
      userId: string,
      f: { status?: AttemptRow['status'] | undefined; quizId?: string | undefined },
      cursor: string | undefined,
      limit: number,
    ) {
      const offset = decodeCursor(cursor);
      const rows = await db
        .select()
        .from(quizAttempts)
        .where(
          and(
            eq(quizAttempts.userId, userId),
            f.status ? eq(quizAttempts.status, f.status) : undefined,
            f.quizId ? eq(quizAttempts.quizId, f.quizId) : undefined,
          ),
        )
        .orderBy(desc(quizAttempts.lastActivityAt), desc(quizAttempts.id))
        .limit(limit + 1)
        .offset(offset);
      return {
        items: rows.slice(0, limit),
        nextCursor: rows.length > limit ? encodeCursor(offset + limit) : null,
      };
    },

    /** Per quiz: attempts that count against `max_attempts`, best score, and the latest unfinished one. */
    async quizStats(userId: string, quizIds: string[]) {
      const out = new Map<string, { used: number; best: number | null; inProgressId: string | null }>();
      if (!quizIds.length) return out;
      const rows = await db
        .select({
          quizId: quizAttempts.quizId,
          used: sql<number>`count(*) filter (where ${quizAttempts.status} <> 'abandoned')::int`,
          best: sql<
            number | null
          >`max(${quizAttempts.scorePercent}) filter (where ${quizAttempts.status} = 'submitted')`,
          inProgressId: sql<
            string | null
          >`(array_agg(${quizAttempts.id} order by ${quizAttempts.lastActivityAt} desc) filter (where ${quizAttempts.status} = 'in_progress'))[1]`,
        })
        .from(quizAttempts)
        .where(and(eq(quizAttempts.userId, userId), inArray(quizAttempts.quizId, quizIds)))
        .groupBy(quizAttempts.quizId);
      for (const r of rows) out.set(r.quizId!, { used: r.used, best: r.best, inProgressId: r.inProgressId });
      return out;
    },

    /** Whether the question is part of one of the student's unfinished exams (§15.2). */
    async inOpenExam(userId: string, questionId: string) {
      const [row] = await db
        .select({ id: quizAttempts.id })
        .from(quizAttempts)
        .where(
          and(
            eq(quizAttempts.userId, userId),
            eq(quizAttempts.status, 'in_progress'),
            eq(quizAttempts.mode, 'exam'),
            sql`${quizAttempts.questionOrder} @> ${JSON.stringify([questionId])}::jsonb`,
          ),
        )
        .limit(1);
      return Boolean(row);
    },

    /** Per question the student has a graded answer for: whether any of them was correct. */
    async correctnessByQuestion(userId: string, questionIds: string[]) {
      if (!questionIds.length) return [];
      return db
        .select({
          id: quizAttemptAnswers.questionId,
          ok: sql<boolean>`bool_or(${quizAttemptAnswers.isCorrect})`,
        })
        .from(quizAttemptAnswers)
        .where(
          and(
            eq(quizAttemptAnswers.userId, userId),
            isNotNull(quizAttemptAnswers.gradedAt),
            inArray(quizAttemptAnswers.questionId, questionIds),
          ),
        )
        .groupBy(quizAttemptAnswers.questionId);
    },

    /** Of the given quizzes, those the student has submitted an attempt at. */
    async submittedQuizIds(userId: string, quizIds: string[]) {
      if (!quizIds.length) return [];
      return db
        .selectDistinct({ id: quizAttempts.quizId })
        .from(quizAttempts)
        .where(
          and(
            eq(quizAttempts.userId, userId),
            eq(quizAttempts.status, 'submitted'),
            inArray(quizAttempts.quizId, quizIds),
          ),
        );
    },

    /** The student's unfinished attempts at the given quizzes, latest activity first. */
    async inProgressFor(userId: string, quizIds: string[]) {
      if (!quizIds.length) return [];
      return db
        .select({ id: quizAttempts.id, quizId: quizAttempts.quizId })
        .from(quizAttempts)
        .where(
          and(
            eq(quizAttempts.userId, userId),
            eq(quizAttempts.status, 'in_progress'),
            inArray(quizAttempts.quizId, quizIds),
          ),
        )
        .orderBy(desc(quizAttempts.lastActivityAt));
    },

    /** Job (§15.5): unfinished attempts without activity since `before` become abandoned. */
    async abandonStale(before: Date) {
      const rows = await db
        .update(quizAttempts)
        .set({ status: 'abandoned' })
        .where(and(eq(quizAttempts.status, 'in_progress'), lt(quizAttempts.lastActivityAt, before)))
        .returning({ id: quizAttempts.id });
      return rows.length;
    },
  };
}

export type AttemptRepository = ReturnType<typeof createAttemptRepository>;
