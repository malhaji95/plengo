import { and, desc, eq, inArray, lt, sql } from 'drizzle-orm';
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
