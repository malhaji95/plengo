import { and, count, desc, eq, gt, ilike, inArray, isNull, lte, or, sql, type SQL, ne } from 'drizzle-orm';
import {
  coupons,
  entitlements,
  profiles,
  promotions,
  subjects,
  teacherTracks,
  teachers,
  users,
  type Db,
  type Tx,
} from '@plengo/db';
import type { AnyPgColumn } from 'drizzle-orm/pg-core';
import type { AccessScope } from '@plengo/contracts';

/**
 * A scope as stored: exactly one of the two ids is set (spec §8.1). Content items carry both a
 * subject id and an optional track id; `scopeOf` turns them into a Scope.
 */
export type Scope =
  | { scopeType: 'subject'; subjectId: string; teacherTrackId: null }
  | { scopeType: 'teacher_track'; subjectId: null; teacherTrackId: string };

export type ScopeColumns = {
  scopeType: 'subject' | 'teacher_track';
  subjectId: string | null;
  teacherTrackId: string | null;
};

export function toScope(row: ScopeColumns): Scope {
  return row.scopeType === 'subject'
    ? { scopeType: 'subject', subjectId: row.subjectId!, teacherTrackId: null }
    : { scopeType: 'teacher_track', subjectId: null, teacherTrackId: row.teacherTrackId! };
}

export const scopeKey = (s: ScopeColumns) =>
  s.scopeType === 'subject' ? `subject:${s.subjectId}` : `teacher_track:${s.teacherTrackId}`;

type ScopedTable = { scopeType: AnyPgColumn; subjectId: AnyPgColumn; teacherTrackId: AnyPgColumn };

/** WHERE clause matching one scope on any scoped table. */
export function scopeWhere(table: ScopedTable, scope: Scope): SQL {
  return scope.scopeType === 'subject'
    ? and(eq(table.scopeType, 'subject'), eq(table.subjectId, scope.subjectId))!
    : and(eq(table.scopeType, 'teacher_track'), eq(table.teacherTrackId, scope.teacherTrackId))!;
}

/** `status='active' AND starts_at <= now AND (expires_at IS NULL OR expires_at > now)` (§8.2). */
export const entitlementActiveAt = (now: Date) =>
  and(
    eq(entitlements.status, 'active'),
    lte(entitlements.startsAt, now),
    or(isNull(entitlements.expiresAt), gt(entitlements.expiresAt, now)),
  )!;

/** A promotion grants access while enabled and inside its window (§8.5). */
export const promotionRunningAt = (now: Date) =>
  and(eq(promotions.isActive, true), lte(promotions.startsAt, now), gt(promotions.endsAt, now))!;

export type EntitlementRow = typeof entitlements.$inferSelect;

const studentColumns = {
  id: users.id,
  email: users.email,
  name: users.name,
  fullName: profiles.fullName,
  educationLevelId: profiles.educationLevelId,
  emailVerified: users.emailVerified,
  status: users.status,
  createdAt: users.createdAt,
};
export type StudentRow = {
  id: string;
  email: string;
  name: string;
  fullName: string | null;
  educationLevelId: string | null;
  emailVerified: boolean;
  status: 'active' | 'disabled' | 'deleted';
  createdAt: Date;
};

export function createAccessRepository(db: Db) {
  return {
    /** Display names for scopes; unknown or deleted scopes are simply missing from the map. */
    async describeScopes(rows: ScopeColumns[]): Promise<Map<string, AccessScope>> {
      const subjectIds = [...new Set(rows.filter((r) => r.subjectId).map((r) => r.subjectId!))];
      const trackIds = [...new Set(rows.filter((r) => r.teacherTrackId).map((r) => r.teacherTrackId!))];
      const out = new Map<string, AccessScope>();
      if (subjectIds.length) {
        const found = await db
          .select({ id: subjects.id, nameAr: subjects.nameAr, levelId: subjects.educationLevelId })
          .from(subjects)
          .where(inArray(subjects.id, subjectIds));
        for (const s of found) {
          out.set(`subject:${s.id}`, {
            scopeType: 'subject',
            subjectId: s.id,
            teacherTrackId: null,
            subjectNameAr: s.nameAr,
            trackTitleAr: null,
            teacherNameAr: null,
            educationLevelId: s.levelId,
          });
        }
      }
      if (trackIds.length) {
        const found = await db
          .select({
            id: teacherTracks.id,
            titleAr: teacherTracks.titleAr,
            subjectId: subjects.id,
            subjectNameAr: subjects.nameAr,
            levelId: subjects.educationLevelId,
            teacherNameAr: teachers.nameAr,
          })
          .from(teacherTracks)
          .innerJoin(subjects, eq(subjects.id, teacherTracks.subjectId))
          .innerJoin(teachers, eq(teachers.id, teacherTracks.teacherId))
          .where(inArray(teacherTracks.id, trackIds));
        for (const t of found) {
          out.set(`teacher_track:${t.id}`, {
            scopeType: 'teacher_track',
            subjectId: t.subjectId,
            teacherTrackId: t.id,
            subjectNameAr: t.subjectNameAr,
            trackTitleAr: t.titleAr,
            teacherNameAr: t.teacherNameAr,
            educationLevelId: t.levelId,
          });
        }
      }
      return out;
    },

    /** True when the scope's subject or track exists and is not soft-deleted. */
    async scopeExists(scope: Scope): Promise<boolean> {
      const [row] =
        scope.scopeType === 'subject'
          ? await db
              .select({ id: subjects.id })
              .from(subjects)
              .where(and(eq(subjects.id, scope.subjectId), isNull(subjects.deletedAt)))
          : await db
              .select({ id: teacherTracks.id })
              .from(teacherTracks)
              .where(and(eq(teacherTracks.id, scope.teacherTrackId), isNull(teacherTracks.deletedAt)));
      return !!row;
    },

    activeEntitlements: (userId: string, now: Date) =>
      db
        .select()
        .from(entitlements)
        .where(and(eq(entitlements.userId, userId), entitlementActiveAt(now))),

    runningPromotions: (now: Date) => db.select().from(promotions).where(promotionRunningAt(now)),

    /** All of a student's entitlements except superseded ones (they were replaced by an upgrade). */
    listForUser: (userId: string, options: { includeSuperseded?: boolean } = {}) =>
      db
        .select({ entitlement: entitlements, couponLast4: coupons.codeLast4 })
        .from(entitlements)
        .leftJoin(coupons, eq(coupons.id, entitlements.couponId))
        .where(
          and(
            eq(entitlements.userId, userId),
            options.includeSuperseded ? undefined : sql`${entitlements.status} <> 'superseded'`,
          ),
        )
        .orderBy(desc(entitlements.createdAt)),

    get: async (id: string, conn: Db | Tx = db) =>
      (await conn.select().from(entitlements).where(eq(entitlements.id, id)).limit(1))[0] ?? null,

    getForUpdate: async (tx: Tx, id: string) =>
      (await tx.select().from(entitlements).where(eq(entitlements.id, id)).for('update'))[0] ?? null,

    /** Step 8 of §9.4: expire rows whose time has passed so the partial unique index frees up. */
    async expireStale(tx: Tx, userId: string, scope: Scope, now: Date) {
      await tx
        .update(entitlements)
        .set({ status: 'expired', updatedAt: now })
        .where(
          and(
            eq(entitlements.userId, userId),
            scopeWhere(entitlements, scope),
            eq(entitlements.status, 'active'),
            lte(entitlements.expiresAt, now),
          ),
        );
    },

    /** Step 9 of §9.4. */
    async lockActive(tx: Tx, userId: string, scope: Scope) {
      const [row] = await tx
        .select()
        .from(entitlements)
        .where(
          and(
            eq(entitlements.userId, userId),
            scopeWhere(entitlements, scope),
            eq(entitlements.status, 'active'),
          ),
        )
        .for('update');
      return row ?? null;
    },

    async insert(tx: Tx, values: typeof entitlements.$inferInsert) {
      const [row] = await tx.insert(entitlements).values(values).returning();
      return row!;
    },

    async update(conn: Db | Tx, id: string, values: Partial<typeof entitlements.$inferInsert>) {
      const [row] = await conn.update(entitlements).set(values).where(eq(entitlements.id, id)).returning();
      return row!;
    },

    /** Nightly: mark every elapsed active entitlement `expired` (reporting only, §8.2). */
    async expireAllStale(now: Date) {
      const rows = await db
        .update(entitlements)
        .set({ status: 'expired', updatedAt: now })
        .where(and(eq(entitlements.status, 'active'), lte(entitlements.expiresAt, now)))
        .returning({ id: entitlements.id });
      return rows.length;
    },

    // ---- students (admin views, §26.2) ----

    async isStudent(userId: string) {
      const [row] = await db
        .select({ id: users.id })
        .from(users)
        .where(and(eq(users.id, userId), eq(users.role, 'student'), ne(users.status, 'deleted')))
        .limit(1);
      return Boolean(row);
    },

    /** Students by email, name or exact id, newest first. */
    searchStudents: (term: string | undefined, limit: number, offset: number) =>
      db
        .select(studentColumns)
        .from(users)
        .leftJoin(profiles, eq(profiles.userId, users.id))
        .where(
          and(
            eq(users.role, 'student'),
            // Deleted accounts are anonymous tombstones (§33): not listed.
            ne(users.status, 'deleted'),
            term
              ? or(
                  ilike(users.email, `%${term}%`),
                  ilike(profiles.fullName, `%${term}%`),
                  sql`${users.id}::text = ${term}`,
                )
              : undefined,
          ),
        )
        .orderBy(desc(users.createdAt), desc(users.id))
        .limit(limit)
        .offset(offset),

    async student(userId: string) {
      const [row] = await db
        .select(studentColumns)
        .from(users)
        .leftJoin(profiles, eq(profiles.userId, users.id))
        .where(and(eq(users.id, userId), eq(users.role, 'student')))
        .limit(1);
      return row ?? null;
    },

    /** Active entitlements per student at `at`. */
    async activeCounts(userIds: string[], at: Date) {
      if (!userIds.length) return new Map<string, number>();
      const rows = await db
        .select({ userId: entitlements.userId, n: count() })
        .from(entitlements)
        .where(and(inArray(entitlements.userId, userIds), entitlementActiveAt(at)))
        .groupBy(entitlements.userId);
      return new Map(rows.map((r) => [r.userId, r.n]));
    },
  };
}

export type AccessRepository = ReturnType<typeof createAccessRepository>;
