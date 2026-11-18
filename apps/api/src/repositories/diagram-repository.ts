import { and, asc, count, eq, ilike, inArray, isNull, or, sql, type SQL } from 'drizzle-orm';
import {
  diagramLabels,
  diagrams,
  lessons,
  mediaFiles,
  subjects,
  teacherTracks,
  units,
  type Db,
  type Tx,
} from '@plengo/db';
import type { Scope } from './access-repository.js';
import { decodeCursor, encodeCursor } from './question-repository.js';

export type DiagramRow = typeof diagrams.$inferSelect;
export type DiagramLabelRow = typeof diagramLabels.$inferSelect;
export type DiagramWithLabels = DiagramRow & { labels: DiagramLabelRow[] };

type Conn = Db | Tx;

const live = isNull(diagrams.deletedAt);

export function diagramScopeWhere(scope: Scope): SQL {
  return scope.scopeType === 'subject'
    ? and(eq(diagrams.subjectId, scope.subjectId), isNull(diagrams.teacherTrackId))!
    : eq(diagrams.teacherTrackId, scope.teacherTrackId);
}

export interface DiagramFilter {
  subjectId?: string | undefined;
  teacherTrackId?: string | undefined;
  generalOnly?: boolean | undefined;
  unitId?: string | undefined;
  lessonId?: string | undefined;
  /** Any of these lessons. */
  lessonIds?: string[] | undefined;
  status?: DiagramRow['status'] | undefined;
  q?: string | undefined;
}

function filterWhere(f: DiagramFilter) {
  const like = f.q ? `%${f.q.replace(/[\\%_]/g, (c) => `\\${c}`)}%` : null;
  return and(
    live,
    f.subjectId ? eq(diagrams.subjectId, f.subjectId) : undefined,
    f.teacherTrackId ? eq(diagrams.teacherTrackId, f.teacherTrackId) : undefined,
    f.generalOnly ? isNull(diagrams.teacherTrackId) : undefined,
    f.unitId ? eq(diagrams.unitId, f.unitId) : undefined,
    f.lessonId ? eq(diagrams.lessonId, f.lessonId) : undefined,
    f.lessonIds ? (f.lessonIds.length ? inArray(diagrams.lessonId, f.lessonIds) : sql`false`) : undefined,
    f.status ? eq(diagrams.status, f.status) : undefined,
    like
      ? or(
          ilike(diagrams.titleAr, like),
          sql`exists (select 1 from diagram_labels dl where dl.diagram_id = ${diagrams.id} and array_to_string(dl.answers, ' ') ilike ${like})`,
        )
      : undefined,
  );
}

/** Reading order (the order free rules use, §8.4): unit, lesson, then the diagram's own order. */
const readingOrder = [
  asc(diagrams.subjectId),
  sql`case when ${diagrams.unitId} is not null then 0 when ${diagrams.lessonId} is not null then 1 else 2 end`,
  asc(units.sortOrder),
  asc(units.id),
  sql`case when ${diagrams.lessonId} is null then 0 else 1 end`,
  asc(lessons.sortOrder),
  asc(lessons.id),
  asc(diagrams.sortOrder),
  asc(diagrams.id),
];

export function createDiagramRepository(db: Db) {
  async function labelsOf(ids: string[], conn: Conn = db) {
    const out = new Map<string, DiagramLabelRow[]>(ids.map((id) => [id, []]));
    if (!ids.length) return out;
    const rows = await conn
      .select()
      .from(diagramLabels)
      .where(inArray(diagramLabels.diagramId, ids))
      .orderBy(asc(diagramLabels.sortOrder), asc(diagramLabels.number));
    for (const r of rows) out.get(r.diagramId)!.push(r);
    return out;
  }

  async function withLabels(rows: DiagramRow[], conn: Conn = db): Promise<DiagramWithLabels[]> {
    const labels = await labelsOf(
      rows.map((r) => r.id),
      conn,
    );
    return rows.map((r) => ({ ...r, labels: labels.get(r.id) ?? [] }));
  }

  return {
    withLabels,

    async get(id: string, conn: Conn = db): Promise<DiagramWithLabels | null> {
      const [row] = await conn
        .select()
        .from(diagrams)
        .where(and(eq(diagrams.id, id), live));
      return row ? (await withLabels([row], conn))[0]! : null;
    },

    async getForUpdate(tx: Tx, id: string) {
      const [row] = await tx
        .select()
        .from(diagrams)
        .where(and(eq(diagrams.id, id), live))
        .for('update');
      return row ?? null;
    },

    async page(filter: DiagramFilter, cursor: string | undefined, limit: number) {
      const offset = decodeCursor(cursor);
      const where = filterWhere(filter);
      const rows = await db
        .select()
        .from(diagrams)
        .leftJoin(units, eq(units.id, diagrams.unitId))
        .leftJoin(lessons, eq(lessons.id, diagrams.lessonId))
        .where(where)
        .orderBy(...readingOrder)
        .limit(limit + 1)
        .offset(offset);
      const [total] = await db.select({ n: count() }).from(diagrams).where(where);
      return {
        items: await withLabels(rows.slice(0, limit).map((r) => r.diagrams)),
        nextCursor: rows.length > limit ? encodeCursor(offset + limit) : null,
        total: total!.n,
      };
    },

    /** Every diagram of a filter in reading order, with label counts (student lists, practice). */
    async list(filter: DiagramFilter) {
      const rows = await db
        .select({
          diagram: diagrams,
          labelCount: sql<number>`(select count(*)::int from diagram_labels dl where dl.diagram_id = ${diagrams.id})`,
        })
        .from(diagrams)
        .leftJoin(units, eq(units.id, diagrams.unitId))
        .leftJoin(lessons, eq(lessons.id, diagrams.lessonId))
        .where(filterWhere(filter))
        .orderBy(...readingOrder);
      return rows.map((r) => ({ ...r.diagram, labelCount: r.labelCount }));
    },

    async scopeCounts(scope: Scope) {
      const [row] = await db
        .select({ total: count(), free: sql<number>`count(*) filter (where ${diagrams.isFree})::int` })
        .from(diagrams)
        .where(and(live, eq(diagrams.status, 'published'), diagramScopeWhere(scope)));
      return { total: row!.total, free: row!.free };
    },

    publishedInScope: (scope: Scope) =>
      db
        .select({
          id: diagrams.id,
          unitId: diagrams.unitId,
          lessonId: diagrams.lessonId,
          sortOrder: diagrams.sortOrder,
          isFree: diagrams.isFree,
          freeSource: diagrams.freeSource,
        })
        .from(diagrams)
        .where(and(live, eq(diagrams.status, 'published'), diagramScopeWhere(scope))),

    async applyRule(scope: Scope, freeIds: Set<string>) {
      const ids = [...freeIds];
      await db
        .update(diagrams)
        .set({ isFree: ids.length ? inArray(diagrams.id, ids) : sql`false` })
        .where(
          and(
            live,
            eq(diagrams.status, 'published'),
            eq(diagrams.freeSource, 'rule'),
            diagramScopeWhere(scope),
          ),
        );
    },

    async nextSortOrder(conn: Conn, scope: Scope) {
      const [row] = await conn
        .select({ max: sql<number | null>`max(${diagrams.sortOrder})` })
        .from(diagrams)
        .where(and(live, diagramScopeWhere(scope)));
      return (row?.max ?? -1) + 1;
    },

    async insert(conn: Conn, values: typeof diagrams.$inferInsert) {
      const [row] = await conn.insert(diagrams).values(values).returning();
      return row!;
    },

    async update(conn: Conn, id: string, values: Partial<typeof diagrams.$inferInsert>) {
      await conn.update(diagrams).set(values).where(eq(diagrams.id, id));
    },

    /** Replaces every label of the diagram, in the given order. */
    async replaceLabels(
      conn: Conn,
      diagramId: string,
      labels: { number: number; x: number | null; y: number | null; answers: string[] }[],
    ) {
      await conn.delete(diagramLabels).where(eq(diagramLabels.diagramId, diagramId));
      if (labels.length)
        await conn.insert(diagramLabels).values(labels.map((l, i) => ({ diagramId, ...l, sortOrder: i })));
    },

    async getMedia(id: string) {
      const [row] = await db.select().from(mediaFiles).where(eq(mediaFiles.id, id)).limit(1);
      return row ?? null;
    },

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

    async mediaByIds(ids: string[]) {
      if (!ids.length) return new Map<string, typeof mediaFiles.$inferSelect>();
      const rows = await db.select().from(mediaFiles).where(inArray(mediaFiles.id, ids));
      return new Map(rows.map((r) => [r.id, r]));
    },
  };
}

export type DiagramRepository = ReturnType<typeof createDiagramRepository>;
