import { and, asc, count, eq, getTableColumns, ilike, inArray, isNull, ne, sql, type SQL } from 'drizzle-orm';
import {
  lessons,
  questionAnswers,
  questionOptions,
  questions,
  subjects,
  teacherTracks,
  units,
  type Db,
  type Tx,
} from '@plengo/db';
import type { Scope } from './access-repository.js';

export type QuestionRow = typeof questions.$inferSelect;
export type OptionRow = typeof questionOptions.$inferSelect;
export type AnswerRow = typeof questionAnswers.$inferSelect;
export type QuestionWithContent = QuestionRow & { options: OptionRow[]; answers: AnswerRow[] };

type Conn = Db | Tx;

/** Opaque cursor: the offset of the next page in reading order. */
export const encodeCursor = (offset: number) => Buffer.from(`o:${offset}`).toString('base64url');

export function decodeCursor(cursor: string | undefined): number {
  if (!cursor) return 0;
  const match = /^o:(\d{1,9})$/.exec(Buffer.from(cursor, 'base64url').toString('utf8'));
  return match ? Number(match[1]) : 0;
}

const live = isNull(questions.deletedAt);

/** A question's access scope as stored: general subject content has no track (§8.1). */
export function questionScopeWhere(scope: Scope): SQL {
  return scope.scopeType === 'subject'
    ? and(eq(questions.subjectId, scope.subjectId), isNull(questions.teacherTrackId))!
    : eq(questions.teacherTrackId, scope.teacherTrackId);
}

export interface QuestionFilter {
  subjectId?: string | undefined;
  teacherTrackId?: string | undefined;
  generalOnly?: boolean | undefined;
  unitId?: string | undefined;
  lessonId?: string | undefined;
  status?: QuestionRow['status'] | undefined;
  type?: QuestionRow['type'] | undefined;
  q?: string | undefined;
}

function filterWhere(f: QuestionFilter): SQL {
  return and(
    live,
    f.subjectId ? eq(questions.subjectId, f.subjectId) : undefined,
    f.teacherTrackId ? eq(questions.teacherTrackId, f.teacherTrackId) : undefined,
    f.generalOnly ? isNull(questions.teacherTrackId) : undefined,
    f.unitId ? eq(questions.unitId, f.unitId) : undefined,
    f.lessonId ? eq(questions.lessonId, f.lessonId) : undefined,
    f.status ? eq(questions.status, f.status) : undefined,
    f.type ? eq(questions.type, f.type) : undefined,
    f.q ? ilike(questions.questionText, `%${f.q.replace(/[\\%_]/g, (c) => `\\${c}`)}%`) : undefined,
  )!;
}

export function createQuestionRepository(db: Db) {
  async function attachContent(rows: QuestionRow[], conn: Conn = db): Promise<QuestionWithContent[]> {
    if (!rows.length) return [];
    const ids = rows.map((r) => r.id);
    const [options, answers] = await Promise.all([
      conn
        .select()
        .from(questionOptions)
        .where(inArray(questionOptions.questionId, ids))
        .orderBy(asc(questionOptions.sortOrder)),
      conn
        .select()
        .from(questionAnswers)
        .where(and(inArray(questionAnswers.questionId, ids), eq(questionAnswers.isActive, true)))
        .orderBy(asc(questionAnswers.createdAt)),
    ]);
    return rows.map((r) => ({
      ...r,
      options: options.filter((o) => o.questionId === r.id),
      answers: answers.filter((a) => a.questionId === r.id),
    }));
  }

  return {
    attachContent,

    async get(id: string, conn: Conn = db): Promise<QuestionWithContent | null> {
      const [row] = await conn
        .select()
        .from(questions)
        .where(and(eq(questions.id, id), live));
      return row ? (await attachContent([row], conn))[0]! : null;
    },

    /** Rows by id, including deleted ones (attempt history and membership checks). */
    byIds: async (ids: string[], conn: Conn = db): Promise<QuestionRow[]> =>
      ids.length ? conn.select().from(questions).where(inArray(questions.id, ids)) : [],

    async getForUpdate(tx: Tx, id: string) {
      const [row] = await tx
        .select()
        .from(questions)
        .where(and(eq(questions.id, id), live))
        .for('update');
      return row ?? null;
    },

    /** One page in (sort_order, id) order plus the filter's total. */
    /**
     * One page in reading order (the order free rules use, §8.4): each unit in order with its
     * unit-level questions first, then its lessons; then lessons directly under the subject; then
     * questions attached to neither. Within a slot, by `sort_order`.
     */
    async page(filter: QuestionFilter, cursor: string | undefined, limit: number) {
      const offset = decodeCursor(cursor);
      const where = filterWhere(filter);
      const rows = await db
        .select(getTableColumns(questions))
        .from(questions)
        .leftJoin(units, eq(units.id, questions.unitId))
        .leftJoin(lessons, eq(lessons.id, questions.lessonId))
        .where(where)
        .orderBy(
          asc(questions.subjectId),
          sql`case when ${questions.unitId} is not null then 0 when ${questions.lessonId} is not null then 1 else 2 end`,
          asc(units.sortOrder),
          asc(units.id),
          sql`case when ${questions.lessonId} is null then 0 else 1 end`,
          asc(lessons.sortOrder),
          asc(lessons.id),
          asc(questions.sortOrder),
          asc(questions.id),
        )
        .limit(limit + 1)
        .offset(offset);
      const [total] = await db.select({ n: count() }).from(questions).where(where);
      const items = rows.slice(0, limit);
      return {
        items,
        nextCursor: rows.length > limit ? encodeCursor(offset + limit) : null,
        total: total!.n,
      };
    },

    /** Published totals for a filter: all, and how many are free. */
    async publishedCounts(filter: QuestionFilter) {
      const [row] = await db
        .select({ total: count(), free: sql<number>`count(*) filter (where ${questions.isFree})::int` })
        .from(questions)
        .where(filterWhere({ ...filter, status: 'published' }));
      return { total: row!.total, free: row!.free };
    },

    async scopeCounts(scope: Scope) {
      const [row] = await db
        .select({ total: count(), free: sql<number>`count(*) filter (where ${questions.isFree})::int` })
        .from(questions)
        .where(and(live, eq(questions.status, 'published'), questionScopeWhere(scope)));
      return { total: row!.total, free: row!.free };
    },

    /** Published questions of a scope in their stored order, for the free-rule engine (§8.4). */
    publishedInScope: (scope: Scope) =>
      db
        .select({
          id: questions.id,
          unitId: questions.unitId,
          lessonId: questions.lessonId,
          sortOrder: questions.sortOrder,
          isFree: questions.isFree,
          freeSource: questions.freeSource,
        })
        .from(questions)
        .where(and(live, eq(questions.status, 'published'), questionScopeWhere(scope))),

    /** Sets `is_free` on the scope's published rule-sourced questions. */
    async applyRule(scope: Scope, freeIds: Set<string>) {
      const ids = [...freeIds];
      await db
        .update(questions)
        .set({ isFree: ids.length ? inArray(questions.id, ids) : sql`false` })
        .where(
          and(
            live,
            eq(questions.status, 'published'),
            eq(questions.freeSource, 'rule'),
            questionScopeWhere(scope),
          ),
        );
    },

    async nextSortOrder(conn: Conn, scope: Scope) {
      const [row] = await conn
        .select({ max: sql<number | null>`max(${questions.sortOrder})` })
        .from(questions)
        .where(and(live, questionScopeWhere(scope)));
      return (row?.max ?? -1) + 1;
    },

    async insert(conn: Conn, values: typeof questions.$inferInsert) {
      const [row] = await conn.insert(questions).values(values).returning();
      return row!;
    },

    async update(conn: Conn, id: string, values: Partial<typeof questions.$inferInsert>) {
      const [row] = await conn.update(questions).set(values).where(eq(questions.id, id)).returning();
      return row!;
    },

    /**
     * Replaces the options, keeping ids that are sent back so references from attempts stay valid.
     * All flags are cleared first: the one-correct-option index is checked per statement.
     */
    async syncOptions(
      tx: Tx,
      questionId: string,
      options: { id?: string | undefined; text: string; isCorrect: boolean }[],
    ) {
      const existing = await tx
        .select()
        .from(questionOptions)
        .where(eq(questionOptions.questionId, questionId));
      const keep = new Set(options.map((o) => o.id).filter((id) => id && existing.some((e) => e.id === id)));
      const removed = existing.filter((e) => !keep.has(e.id)).map((e) => e.id);
      if (removed.length) await tx.delete(questionOptions).where(inArray(questionOptions.id, removed));
      await tx
        .update(questionOptions)
        .set({ isCorrect: false })
        .where(eq(questionOptions.questionId, questionId));
      for (const [i, o] of options.entries()) {
        if (o.id && keep.has(o.id)) {
          await tx
            .update(questionOptions)
            .set({ text: o.text, isCorrect: o.isCorrect, sortOrder: i })
            .where(eq(questionOptions.id, o.id));
        } else {
          await tx
            .insert(questionOptions)
            .values({ questionId, text: o.text, isCorrect: o.isCorrect, sortOrder: i });
        }
      }
    },

    /**
     * Replaces the accepted answers. Previous rows are deactivated, not deleted (history), and the new
     * ones keep the admin's order: the first is shown to students as the correct answer.
     */
    async syncAnswers(
      tx: Tx,
      questionId: string,
      answers: { original: string; normalized: string }[],
      version: number,
    ) {
      await tx
        .update(questionAnswers)
        .set({ isActive: false })
        .where(and(eq(questionAnswers.questionId, questionId), eq(questionAnswers.isActive, true)));
      const base = Date.now();
      if (answers.length) {
        await tx.insert(questionAnswers).values(
          answers.map((a, i) => ({
            questionId,
            answerOriginal: a.original,
            answerNormalized: a.normalized,
            normalizationVersion: version,
            createdAt: new Date(base + i),
          })),
        );
      }
    },

    /** Siblings for reordering: same subject, track, unit and lesson. */
    siblings: (q: QuestionRow) =>
      db
        .select({ id: questions.id })
        .from(questions)
        .where(
          and(
            live,
            eq(questions.subjectId, q.subjectId),
            q.teacherTrackId
              ? eq(questions.teacherTrackId, q.teacherTrackId)
              : isNull(questions.teacherTrackId),
            q.unitId ? eq(questions.unitId, q.unitId) : isNull(questions.unitId),
            q.lessonId ? eq(questions.lessonId, q.lessonId) : isNull(questions.lessonId),
          ),
        ),

    /** Accepted answers whose stored form was produced by another normalizer version (§14.5). */
    staleAnswers: (version: number) =>
      db
        .select()
        .from(questionAnswers)
        .where(and(eq(questionAnswers.isActive, true), ne(questionAnswers.normalizationVersion, version))),

    /**
     * Random practice draw (§15.3): ids of live published questions in one subject scope, in random
     * order; only free ones unless the scope is open.
     */
    randomPublishedIds: (
      f: {
        subjectId: string;
        teacherTrackId: string | null;
        unitId?: string | null | undefined;
        lessonId?: string | null | undefined;
        types?: QuestionRow['type'][] | undefined;
        freeOnly: boolean;
      },
      limit: number,
    ) =>
      db
        .select({ id: questions.id })
        .from(questions)
        .where(
          and(
            isNull(questions.deletedAt),
            eq(questions.status, 'published'),
            eq(questions.subjectId, f.subjectId),
            f.teacherTrackId
              ? eq(questions.teacherTrackId, f.teacherTrackId)
              : isNull(questions.teacherTrackId),
            f.unitId ? eq(questions.unitId, f.unitId) : undefined,
            f.lessonId ? eq(questions.lessonId, f.lessonId) : undefined,
            f.types?.length ? inArray(questions.type, f.types) : undefined,
            f.freeOnly ? eq(questions.isFree, true) : undefined,
          ),
        )
        .orderBy(sql`random()`)
        .limit(limit),

    /** Live published questions of one subject scope (a null track is general content). */
    publishedRowsInScope: (subjectId: string, teacherTrackId: string | null) =>
      db
        .select()
        .from(questions)
        .where(
          and(
            eq(questions.subjectId, subjectId),
            teacherTrackId ? eq(questions.teacherTrackId, teacherTrackId) : isNull(questions.teacherTrackId),
            isNull(questions.deletedAt),
            eq(questions.status, 'published'),
          ),
        ),

    names: async (subjectIds: string[], trackIds: string[]) => {
      const [s, t] = await Promise.all([
        subjectIds.length
          ? db
              .select({ id: subjects.id, nameAr: subjects.nameAr })
              .from(subjects)
              .where(inArray(subjects.id, subjectIds))
          : [],
        trackIds.length
          ? db
              .select({ id: teacherTracks.id, titleAr: teacherTracks.titleAr })
              .from(teacherTracks)
              .where(inArray(teacherTracks.id, trackIds))
          : [],
      ]);
      return {
        subjects: new Map(s.map((r) => [r.id, r.nameAr])),
        tracks: new Map(t.map((r) => [r.id, r.titleAr])),
      };
    },
  };
}

export type QuestionRepository = ReturnType<typeof createQuestionRepository>;
