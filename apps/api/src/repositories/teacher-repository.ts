import { and, asc, count, eq, isNull, sql, type SQL } from 'drizzle-orm';
import { alias } from 'drizzle-orm/pg-core';
import {
  academicYears,
  faculties,
  mediaFiles,
  subjects,
  teacherFollowers,
  teacherTracks,
  teachers,
  universities,
  type Db,
} from '@plengo/db';
import { studentVisibleSubject } from './structure-repository.js';

const photo = alias(mediaFiles, 'teacher_photo');
const cover = alias(mediaFiles, 'track_cover');

const liveActiveTeacher = and(isNull(teachers.deletedAt), eq(teachers.isActive, true))!;

const followerCount = sql<number>`(select count(*)::int from ${teacherFollowers} where ${teacherFollowers.teacherId} = ${teachers.id})`;

const teacherColumns = {
  id: teachers.id,
  nameAr: teachers.nameAr,
  slug: teachers.slug,
  photoMediaId: teachers.photoMediaId,
  shortDescription: teachers.shortDescription,
  bio: teachers.bio,
  isActive: teachers.isActive,
  sortOrder: teachers.sortOrder,
  photoVariants: photo.variants,
  photoStatus: photo.status,
  followerCount,
};

const trackColumns = {
  id: teacherTracks.id,
  teacherId: teacherTracks.teacherId,
  teacherNameAr: teachers.nameAr,
  subjectId: teacherTracks.subjectId,
  subjectNameAr: subjects.nameAr,
  educationLevelId: subjects.educationLevelId,
  titleAr: teacherTracks.titleAr,
  slug: teacherTracks.slug,
  description: teacherTracks.description,
  coverMediaId: teacherTracks.coverMediaId,
  isActive: teacherTracks.isActive,
  sortOrder: teacherTracks.sortOrder,
  coverVariants: cover.variants,
  coverStatus: cover.status,
  teacherPhotoVariants: photo.variants,
  teacherPhotoStatus: photo.status,
};

export type TeacherRow = Awaited<
  ReturnType<ReturnType<typeof createTeacherRepository>['listTeachers']>
>[number];
export type TrackRow = Awaited<ReturnType<ReturnType<typeof createTeacherRepository>['listTracks']>>[number];

/** A track is visible to students when it, its teacher and its subject (with its college layers) are. */
const visibleTrack = and(
  isNull(teacherTracks.deletedAt),
  eq(teacherTracks.isActive, true),
  liveActiveTeacher,
  studentVisibleSubject,
)!;

export function createTeacherRepository(db: Db) {
  function teacherQuery() {
    return db
      .select(teacherColumns)
      .from(teachers)
      .leftJoin(photo, eq(photo.id, teachers.photoMediaId))
      .$dynamic();
  }

  function trackQuery() {
    return db
      .select(trackColumns)
      .from(teacherTracks)
      .innerJoin(teachers, eq(teachers.id, teacherTracks.teacherId))
      .innerJoin(subjects, eq(subjects.id, teacherTracks.subjectId))
      .leftJoin(universities, eq(universities.id, subjects.universityId))
      .leftJoin(faculties, eq(faculties.id, subjects.facultyId))
      .leftJoin(academicYears, eq(academicYears.id, subjects.academicYearId))
      .leftJoin(photo, eq(photo.id, teachers.photoMediaId))
      .leftJoin(cover, eq(cover.id, teacherTracks.coverMediaId))
      .$dynamic();
  }

  return {
    // ---- teachers ----
    listTeachers(opts: { visibleOnly: boolean }) {
      return teacherQuery()
        .where(opts.visibleOnly ? liveActiveTeacher : isNull(teachers.deletedAt))
        .orderBy(asc(teachers.sortOrder), asc(teachers.nameAr));
    },

    async getTeacher(id: string, opts: { visibleOnly: boolean }) {
      const [row] = await teacherQuery()
        .where(and(eq(teachers.id, id), opts.visibleOnly ? liveActiveTeacher : isNull(teachers.deletedAt)))
        .limit(1);
      return row ?? null;
    },

    async trackCounts(): Promise<Map<string, number>> {
      const rows = await db
        .select({ teacherId: teacherTracks.teacherId, n: count() })
        .from(teacherTracks)
        .where(isNull(teacherTracks.deletedAt))
        .groupBy(teacherTracks.teacherId);
      return new Map(rows.map((r) => [r.teacherId, r.n]));
    },

    // ---- following ----
    async followedIds(userId: string): Promise<Set<string>> {
      const rows = await db
        .select({ teacherId: teacherFollowers.teacherId })
        .from(teacherFollowers)
        .where(eq(teacherFollowers.userId, userId));
      return new Set(rows.map((r) => r.teacherId));
    },

    listFollowedTeachers(userId: string) {
      return teacherQuery()
        .innerJoin(teacherFollowers, eq(teacherFollowers.teacherId, teachers.id))
        .where(and(eq(teacherFollowers.userId, userId), liveActiveTeacher))
        .orderBy(asc(teachers.sortOrder), asc(teachers.nameAr));
    },

    async follow(teacherId: string, userId: string) {
      await db.insert(teacherFollowers).values({ teacherId, userId }).onConflictDoNothing();
    },

    async unfollow(teacherId: string, userId: string) {
      await db
        .delete(teacherFollowers)
        .where(and(eq(teacherFollowers.teacherId, teacherId), eq(teacherFollowers.userId, userId)));
    },

    async followerCount(teacherId: string): Promise<number> {
      const [row] = await db
        .select({ n: count() })
        .from(teacherFollowers)
        .where(eq(teacherFollowers.teacherId, teacherId));
      return row?.n ?? 0;
    },

    // ---- tracks ----
    listTracks(
      filter: { teacherId?: string | undefined; subjectId?: string | undefined },
      opts: { visibleOnly: boolean },
    ) {
      const where: SQL[] = [];
      if (filter.teacherId) where.push(eq(teacherTracks.teacherId, filter.teacherId));
      if (filter.subjectId) where.push(eq(teacherTracks.subjectId, filter.subjectId));
      return trackQuery()
        .where(and(...where, opts.visibleOnly ? visibleTrack : isNull(teacherTracks.deletedAt)))
        .orderBy(asc(teachers.sortOrder), asc(teacherTracks.sortOrder), asc(teacherTracks.titleAr));
    },

    async getTrack(id: string, opts: { visibleOnly: boolean }) {
      const [row] = await trackQuery()
        .where(
          and(eq(teacherTracks.id, id), opts.visibleOnly ? visibleTrack : isNull(teacherTracks.deletedAt)),
        )
        .limit(1);
      return row ?? null;
    },
  };
}

export type TeacherRepository = ReturnType<typeof createTeacherRepository>;
