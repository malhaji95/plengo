import { and, asc, eq, inArray, isNull, or, sql, type SQL } from 'drizzle-orm';
import type { AnyPgColumn } from 'drizzle-orm/pg-core';
import {
  academicYears,
  educationLevels,
  faculties,
  lessons,
  mediaFiles,
  subjects,
  teachers,
  teacherTracks,
  units,
  universities,
  type Db,
  type Tx,
} from '@plengo/db';

type Conn = Db | Tx;

/**
 * Tables whose rows are ordered by `sort_order` among siblings and soft-deleted with `deleted_at`.
 * `scope` lists the columns that define "siblings": subjects are ordered within one level + college
 * path, lessons within their unit (or directly under the subject when `unit_id` is null).
 */
export const ORDERED_TABLES = {
  universities: { table: universities, scope: {} },
  faculties: { table: faculties, scope: { universityId: faculties.universityId } },
  academicYears: { table: academicYears, scope: { facultyId: academicYears.facultyId } },
  subjects: {
    table: subjects,
    scope: {
      educationLevelId: subjects.educationLevelId,
      universityId: subjects.universityId,
      facultyId: subjects.facultyId,
      academicYearId: subjects.academicYearId,
    },
  },
  units: { table: units, scope: { subjectId: units.subjectId } },
  lessons: { table: lessons, scope: { subjectId: lessons.subjectId, unitId: lessons.unitId } },
  teachers: { table: teachers, scope: {} },
  teacherTracks: { table: teacherTracks, scope: { teacherId: teacherTracks.teacherId } },
} as const;
export type OrderedTableName = keyof typeof ORDERED_TABLES;
export type SiblingScope = Record<string, string | null>;

function scopeWhere(name: OrderedTableName, scope: SiblingScope): SQL | undefined {
  const columns = ORDERED_TABLES[name].scope as Record<string, AnyPgColumn>;
  const parts = Object.entries(columns).map(([key, column]) => {
    const value = scope[key] ?? null;
    return value === null ? isNull(column) : eq(column, value);
  });
  return parts.length ? and(...parts) : undefined;
}

const subjectColumns = {
  id: subjects.id,
  educationLevelId: subjects.educationLevelId,
  universityId: subjects.universityId,
  facultyId: subjects.facultyId,
  academicYearId: subjects.academicYearId,
  code: subjects.code,
  nameAr: subjects.nameAr,
  description: subjects.description,
  coverMediaId: subjects.coverMediaId,
  sortOrder: subjects.sortOrder,
  isActive: subjects.isActive,
  coverVariants: mediaFiles.variants,
  coverStatus: mediaFiles.status,
};
export type SubjectRow = {
  id: string;
  educationLevelId: string;
  universityId: string | null;
  facultyId: string | null;
  academicYearId: string | null;
  code: string;
  nameAr: string;
  description: string | null;
  coverMediaId: string | null;
  sortOrder: number;
  isActive: boolean;
  coverVariants: typeof mediaFiles.$inferSelect.variants | null;
  coverStatus: typeof mediaFiles.$inferSelect.status | null;
};

export interface SubjectFilter {
  levelId?: string | undefined;
  universityId?: string | undefined;
  facultyId?: string | undefined;
  academicYearId?: string | undefined;
}

/** A subject is visible to students only when it and every college layer above it are live and active. */
export const studentVisibleSubject = and(
  isNull(subjects.deletedAt),
  eq(subjects.isActive, true),
  or(isNull(subjects.universityId), and(isNull(universities.deletedAt), eq(universities.isActive, true))),
  or(isNull(subjects.facultyId), and(isNull(faculties.deletedAt), eq(faculties.isActive, true))),
  or(isNull(subjects.academicYearId), and(isNull(academicYears.deletedAt), eq(academicYears.isActive, true))),
)!;

export function createStructureRepository(db: Db) {
  function subjectQuery(conn: Conn = db) {
    return conn
      .select(subjectColumns)
      .from(subjects)
      .leftJoin(universities, eq(universities.id, subjects.universityId))
      .leftJoin(faculties, eq(faculties.id, subjects.facultyId))
      .leftJoin(academicYears, eq(academicYears.id, subjects.academicYearId))
      .leftJoin(mediaFiles, eq(mediaFiles.id, subjects.coverMediaId))
      .$dynamic();
  }

  function subjectFilter(filter: SubjectFilter): SQL[] {
    const where: SQL[] = [];
    if (filter.levelId) where.push(eq(subjects.educationLevelId, filter.levelId));
    if (filter.universityId) where.push(eq(subjects.universityId, filter.universityId));
    if (filter.facultyId) where.push(eq(subjects.facultyId, filter.facultyId));
    if (filter.academicYearId) where.push(eq(subjects.academicYearId, filter.academicYearId));
    return where;
  }

  return {
    // ---- levels ----
    listLevels: () => db.select().from(educationLevels).orderBy(asc(educationLevels.sortOrder)),

    async getLevel(id: string) {
      const [row] = await db.select().from(educationLevels).where(eq(educationLevels.id, id)).limit(1);
      return row ?? null;
    },

    async updateLevel(id: string, fields: { nameAr?: string | undefined; sortOrder?: number | undefined }) {
      const [row] = await db
        .update(educationLevels)
        .set({ ...fields, updatedAt: new Date() })
        .where(eq(educationLevels.id, id))
        .returning();
      return row ?? null;
    },

    // ---- college hierarchy ----
    listUniversities: (opts: { activeOnly: boolean }) =>
      db
        .select()
        .from(universities)
        .where(
          and(isNull(universities.deletedAt), opts.activeOnly ? eq(universities.isActive, true) : undefined),
        )
        .orderBy(asc(universities.sortOrder), asc(universities.nameAr)),

    async getUniversity(id: string, conn: Conn = db) {
      const [row] = await conn
        .select()
        .from(universities)
        .where(and(eq(universities.id, id), isNull(universities.deletedAt)))
        .limit(1);
      return row ?? null;
    },

    listFaculties: (universityId: string, opts: { activeOnly: boolean }) =>
      db
        .select()
        .from(faculties)
        .where(
          and(
            eq(faculties.universityId, universityId),
            isNull(faculties.deletedAt),
            opts.activeOnly ? eq(faculties.isActive, true) : undefined,
          ),
        )
        .orderBy(asc(faculties.sortOrder), asc(faculties.nameAr)),

    async getFaculty(id: string, conn: Conn = db) {
      const [row] = await conn
        .select()
        .from(faculties)
        .where(and(eq(faculties.id, id), isNull(faculties.deletedAt)))
        .limit(1);
      return row ?? null;
    },

    listAcademicYears: (facultyId: string, opts: { activeOnly: boolean }) =>
      db
        .select()
        .from(academicYears)
        .where(
          and(
            eq(academicYears.facultyId, facultyId),
            isNull(academicYears.deletedAt),
            opts.activeOnly ? eq(academicYears.isActive, true) : undefined,
          ),
        )
        .orderBy(asc(academicYears.sortOrder), asc(academicYears.nameAr)),

    async getAcademicYear(id: string, conn: Conn = db) {
      const [row] = await conn
        .select()
        .from(academicYears)
        .where(and(eq(academicYears.id, id), isNull(academicYears.deletedAt)))
        .limit(1);
      return row ?? null;
    },

    // ---- subjects ----
    listSubjects(filter: SubjectFilter, opts: { studentVisible: boolean }): Promise<SubjectRow[]> {
      return subjectQuery()
        .where(
          and(
            ...subjectFilter(filter),
            opts.studentVisible ? studentVisibleSubject : isNull(subjects.deletedAt),
          ),
        )
        .orderBy(asc(subjects.sortOrder), asc(subjects.nameAr));
    },

    async getSubject(
      id: string,
      opts: { studentVisible: boolean },
      conn: Conn = db,
    ): Promise<SubjectRow | null> {
      const [row] = await subjectQuery(conn)
        .where(
          and(eq(subjects.id, id), opts.studentVisible ? studentVisibleSubject : isNull(subjects.deletedAt)),
        )
        .limit(1);
      return row ?? null;
    },

    // ---- units and lessons ----
    listUnits: (subjectId: string) =>
      db
        .select()
        .from(units)
        .where(and(eq(units.subjectId, subjectId), isNull(units.deletedAt)))
        .orderBy(asc(units.sortOrder), asc(units.titleAr)),

    async getUnit(id: string, conn: Conn = db) {
      const [row] = await conn
        .select()
        .from(units)
        .where(and(eq(units.id, id), isNull(units.deletedAt)))
        .limit(1);
      return row ?? null;
    },

    listLessons: (subjectId: string, unitId?: string | null) =>
      db
        .select()
        .from(lessons)
        .where(
          and(
            eq(lessons.subjectId, subjectId),
            isNull(lessons.deletedAt),
            unitId === undefined
              ? undefined
              : unitId === null
                ? isNull(lessons.unitId)
                : eq(lessons.unitId, unitId),
          ),
        )
        .orderBy(asc(lessons.sortOrder), asc(lessons.titleAr)),

    async getLesson(id: string, conn: Conn = db) {
      const [row] = await conn
        .select()
        .from(lessons)
        .where(and(eq(lessons.id, id), isNull(lessons.deletedAt)))
        .limit(1);
      return row ?? null;
    },

    async getCoverMedia(id: string) {
      const [row] = await db.select().from(mediaFiles).where(eq(mediaFiles.id, id)).limit(1);
      return row ?? null;
    },

    // ---- shared ordering helpers ----

    /** `sort_order` for a new last child: one past the current maximum among live siblings. */
    async nextSortOrder(name: OrderedTableName, scope: SiblingScope, conn: Conn = db): Promise<number> {
      const { table } = ORDERED_TABLES[name];
      const [row] = await conn
        .select({ max: sql<number | null>`max(${table.sortOrder})` })
        .from(table)
        .where(and(isNull(table.deletedAt), scopeWhere(name, scope)));
      return (row?.max ?? -1) + 1;
    },

    /** Ids of the live siblings that share `scope`. */
    async siblingIds(name: OrderedTableName, scope: SiblingScope, conn: Conn = db): Promise<string[]> {
      const { table } = ORDERED_TABLES[name];
      const rows = await conn
        .select({ id: table.id })
        .from(table)
        .where(and(isNull(table.deletedAt), scopeWhere(name, scope)));
      return rows.map((r) => r.id);
    },

    /** The sibling scope of each live row among `ids` (missing/deleted rows are omitted). */
    async scopesOf(name: OrderedTableName, ids: string[], conn: Conn = db): Promise<SiblingScope[]> {
      const { table, scope } = ORDERED_TABLES[name];
      const columns = { id: table.id, ...(scope as Record<string, AnyPgColumn>) };
      const rows = await conn
        .select(columns)
        .from(table)
        .where(and(inArray(table.id, ids), isNull(table.deletedAt)));
      return rows.map(({ id: _id, ...rest }) => rest as SiblingScope);
    },

    async setSortOrders(name: OrderedTableName, ids: string[], conn: Conn) {
      const { table } = ORDERED_TABLES[name];
      for (const [index, id] of ids.entries()) {
        await conn.update(table).set({ sortOrder: index, updatedAt: new Date() }).where(eq(table.id, id));
      }
    },

    /** Insert or update a row of an ordered table, returning the stored row. */
    async insertRow<N extends OrderedTableName>(
      name: N,
      values: (typeof ORDERED_TABLES)[N]['table']['$inferInsert'],
      conn: Conn = db,
    ): Promise<(typeof ORDERED_TABLES)[N]['table']['$inferSelect']> {
      const { table } = ORDERED_TABLES[name];
      const [row] = await conn
        .insert(table)
        .values(values as never)
        .returning();
      return row as (typeof ORDERED_TABLES)[N]['table']['$inferSelect'];
    },

    async updateRow<N extends OrderedTableName>(
      name: N,
      id: string,
      values: Partial<(typeof ORDERED_TABLES)[N]['table']['$inferInsert']>,
      conn: Conn = db,
    ): Promise<(typeof ORDERED_TABLES)[N]['table']['$inferSelect'] | null> {
      const { table } = ORDERED_TABLES[name];
      const [row] = await conn
        .update(table)
        .set({ ...(values as object), updatedAt: new Date() } as never)
        .where(and(eq(table.id, id), isNull(table.deletedAt)))
        .returning();
      return (row as (typeof ORDERED_TABLES)[N]['table']['$inferSelect'] | undefined) ?? null;
    },

    async softDelete(name: OrderedTableName, id: string, conn: Conn = db) {
      const { table } = ORDERED_TABLES[name];
      const now = new Date();
      const [row] = await conn
        .update(table)
        .set({ deletedAt: now, updatedAt: now })
        .where(and(eq(table.id, id), isNull(table.deletedAt)))
        .returning({ id: table.id });
      return Boolean(row);
    },

    /** Whether live rows still hang under a node, which blocks deleting it (ADR-011). */
    async isInUse(
      name: 'universities' | 'faculties' | 'academicYears' | 'subjects' | 'units' | 'teachers',
      id: string,
    ) {
      const exists = async (query: Promise<unknown[]>) => (await query).length > 0;
      const liveWhere = (t: { deletedAt: AnyPgColumn }, col: AnyPgColumn) =>
        and(eq(col, id), isNull(t.deletedAt));
      switch (name) {
        case 'universities':
          return (
            (await exists(
              db
                .select({ id: faculties.id })
                .from(faculties)
                .where(liveWhere(faculties, faculties.universityId))
                .limit(1),
            )) ||
            (await exists(
              db
                .select({ id: subjects.id })
                .from(subjects)
                .where(liveWhere(subjects, subjects.universityId))
                .limit(1),
            ))
          );
        case 'faculties':
          return (
            (await exists(
              db
                .select({ id: academicYears.id })
                .from(academicYears)
                .where(liveWhere(academicYears, academicYears.facultyId))
                .limit(1),
            )) ||
            (await exists(
              db
                .select({ id: subjects.id })
                .from(subjects)
                .where(liveWhere(subjects, subjects.facultyId))
                .limit(1),
            ))
          );
        case 'academicYears':
          return exists(
            db
              .select({ id: subjects.id })
              .from(subjects)
              .where(liveWhere(subjects, subjects.academicYearId))
              .limit(1),
          );
        case 'subjects':
          return (
            (await exists(
              db
                .select({ id: teacherTracks.id })
                .from(teacherTracks)
                .where(liveWhere(teacherTracks, teacherTracks.subjectId))
                .limit(1),
            )) ||
            (await exists(
              db.select({ id: units.id }).from(units).where(liveWhere(units, units.subjectId)).limit(1),
            )) ||
            (await exists(
              db
                .select({ id: lessons.id })
                .from(lessons)
                .where(liveWhere(lessons, lessons.subjectId))
                .limit(1),
            ))
          );
        case 'teachers':
          return exists(
            db
              .select({ id: teacherTracks.id })
              .from(teacherTracks)
              .where(liveWhere(teacherTracks, teacherTracks.teacherId))
              .limit(1),
          );
        case 'units':
          return exists(
            db.select({ id: lessons.id }).from(lessons).where(liveWhere(lessons, lessons.unitId)).limit(1),
          );
      }
    },
  };
}

export type StructureRepository = ReturnType<typeof createStructureRepository>;
