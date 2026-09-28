import { and, asc, desc, eq, gte, ilike, isNull, like, lt, or, sql, type SQL } from 'drizzle-orm';
import {
  auditLogs,
  contentReports,
  couponBatches,
  offlineGradeMismatches,
  questionOptions,
  questionStats,
  questions,
  subjects,
  teacherTracks,
  teachers,
  users,
  type Db,
} from '@plengo/db';

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

/** `%text%` for ILIKE with the user's wildcards escaped. */
const contains = (q: string) => `%${q.replace(/[\\%_]/g, (c) => `\\${c}`)}%`;

export type AuditFilter = {
  actorAdminId?: string | undefined;
  action?: string | undefined;
  resourceType?: string | undefined;
  resourceId?: string | undefined;
  from?: Date | undefined;
  /** Exclusive. */
  to?: Date | undefined;
};

export type AnalyticsFilter = {
  subjectId?: string | undefined;
  teacherTrackId?: string | undefined;
  flagged?: boolean | undefined;
  questionId?: string | undefined;
};
export type AnalyticsSort = 'attempts' | 'correct' | 'reports' | 'mismatches' | 'recent';

/** Read models for the admin's audit log, global search and question analytics (§26.2, §32). */
export function createAdminToolsRepository(db: Db) {
  const openReports = sql<number>`(select count(*)::int from ${contentReports} r
    where r.item_type = 'question' and r.item_id = ${questions.id} and r.status = 'open')`;
  const mismatches = sql<number>`(select count(*)::int from ${offlineGradeMismatches} m
    where m.question_id = ${questions.id})`;
  const attempts = sql<number>`coalesce(${questionStats.attemptCount}, 0)`;
  const correctRatio = sql`case when ${questionStats.attemptCount} > 0
    then ${questionStats.correctCount}::float / ${questionStats.attemptCount} end`;

  return {
    auditLog: (f: AuditFilter, limit: number, offset: number) =>
      db
        .select({ log: auditLogs, name: users.name, email: users.email })
        .from(auditLogs)
        .leftJoin(users, eq(users.id, auditLogs.actorAdminId))
        .where(
          and(
            f.actorAdminId ? eq(auditLogs.actorAdminId, f.actorAdminId) : undefined,
            f.action
              ? f.action.endsWith('.')
                ? like(auditLogs.action, `${f.action.replace(/[\\%_]/g, (c) => `\\${c}`)}%`)
                : eq(auditLogs.action, f.action)
              : undefined,
            f.resourceType ? eq(auditLogs.resourceType, f.resourceType) : undefined,
            f.resourceId ? eq(auditLogs.resourceId, f.resourceId) : undefined,
            f.from ? gte(auditLogs.createdAt, f.from) : undefined,
            f.to ? lt(auditLogs.createdAt, f.to) : undefined,
          ),
        )
        .orderBy(desc(auditLogs.createdAt), desc(auditLogs.id))
        .limit(limit)
        .offset(offset),

    /** Up to `limit` matches per entity type; a UUID also matches ids exactly. */
    async search(q: string, limit: number) {
      const pattern = contains(q);
      const byId = (col: SQL | Parameters<typeof eq>[0]) =>
        UUID.test(q) ? eq(col as Parameters<typeof eq>[0], q) : undefined;
      const [people, teacherRows, trackRows, subjectRows, questionRows, batchRows] = await Promise.all([
        db
          .select({ id: users.id, name: users.name, email: users.email, role: users.role })
          .from(users)
          .where(or(ilike(users.name, pattern), ilike(users.email, pattern), byId(users.id)))
          .orderBy(asc(users.name))
          .limit(limit * 2),
        db
          .select({ id: teachers.id, nameAr: teachers.nameAr, slug: teachers.slug })
          .from(teachers)
          .where(
            and(
              isNull(teachers.deletedAt),
              or(ilike(teachers.nameAr, pattern), ilike(teachers.slug, pattern), byId(teachers.id)),
            ),
          )
          .limit(limit),
        db
          .select({
            id: teacherTracks.id,
            titleAr: teacherTracks.titleAr,
            slug: teacherTracks.slug,
            teacherId: teacherTracks.teacherId,
            teacherName: teachers.nameAr,
          })
          .from(teacherTracks)
          .innerJoin(teachers, eq(teachers.id, teacherTracks.teacherId))
          .where(
            and(
              isNull(teacherTracks.deletedAt),
              or(
                ilike(teacherTracks.titleAr, pattern),
                ilike(teacherTracks.slug, pattern),
                byId(teacherTracks.id),
              ),
            ),
          )
          .limit(limit),
        db
          .select({ id: subjects.id, nameAr: subjects.nameAr, code: subjects.code })
          .from(subjects)
          .where(
            and(
              isNull(subjects.deletedAt),
              or(ilike(subjects.nameAr, pattern), ilike(subjects.code, pattern), byId(subjects.id)),
            ),
          )
          .limit(limit),
        db
          .select({
            id: questions.id,
            questionText: questions.questionText,
            type: questions.type,
            subjectNameAr: subjects.nameAr,
          })
          .from(questions)
          .innerJoin(subjects, eq(subjects.id, questions.subjectId))
          .where(
            and(isNull(questions.deletedAt), or(ilike(questions.questionText, pattern), byId(questions.id))),
          )
          .orderBy(desc(questions.updatedAt))
          .limit(limit),
        db
          .select({
            id: couponBatches.id,
            name: couponBatches.name,
            distributorName: couponBatches.distributorName,
            status: couponBatches.status,
          })
          .from(couponBatches)
          .where(
            or(
              ilike(couponBatches.name, pattern),
              ilike(couponBatches.distributorName, pattern),
              byId(couponBatches.id),
            ),
          )
          .orderBy(desc(couponBatches.createdAt))
          .limit(limit),
      ]);
      return { people, teacherRows, trackRows, subjectRows, questionRows, batchRows };
    },

    analytics(f: AnalyticsFilter, sort: AnalyticsSort, limit: number, offset: number) {
      const order = {
        attempts: [desc(attempts), desc(questions.createdAt)],
        // Lowest share of correct answers first; unanswered questions last.
        correct: [sql`${correctRatio} asc nulls last`, desc(attempts)],
        reports: [desc(openReports), desc(attempts)],
        mismatches: [desc(mismatches), desc(attempts)],
        recent: [sql`${questionStats.lastAttemptAt} desc nulls last`],
      }[sort];
      return db
        .select({
          q: {
            id: questions.id,
            type: questions.type,
            questionText: questions.questionText,
            status: questions.status,
            subjectId: questions.subjectId,
            teacherTrackId: questions.teacherTrackId,
          },
          subjectNameAr: subjects.nameAr,
          trackTitleAr: teacherTracks.titleAr,
          stats: questionStats,
          openReports,
          mismatches,
        })
        .from(questions)
        .innerJoin(subjects, eq(subjects.id, questions.subjectId))
        .leftJoin(teacherTracks, eq(teacherTracks.id, questions.teacherTrackId))
        .leftJoin(questionStats, eq(questionStats.questionId, questions.id))
        .where(
          and(
            isNull(questions.deletedAt),
            f.questionId ? eq(questions.id, f.questionId) : undefined,
            f.subjectId ? eq(questions.subjectId, f.subjectId) : undefined,
            f.teacherTrackId ? eq(questions.teacherTrackId, f.teacherTrackId) : undefined,
            f.flagged === undefined
              ? undefined
              : f.flagged
                ? eq(questionStats.flaggedForReview, true)
                : sql`coalesce(${questionStats.flaggedForReview}, false) = false`,
          ),
        )
        .orderBy(...order, asc(questions.id))
        .limit(limit)
        .offset(offset);
    },

    options: (questionId: string) =>
      db
        .select({ id: questionOptions.id, text: questionOptions.text, isCorrect: questionOptions.isCorrect })
        .from(questionOptions)
        .where(eq(questionOptions.questionId, questionId))
        .orderBy(asc(questionOptions.sortOrder)),

    /** Clears the review flag; the rule looks again after 30 more attempts. */
    async clearFlag(questionId: string) {
      const rows = await db
        .update(questionStats)
        .set({ flaggedForReview: false, flagReviewedAttempts: sql`${questionStats.attemptCount}` })
        .where(eq(questionStats.questionId, questionId))
        .returning({ id: questionStats.questionId });
      return rows.length > 0;
    },
  };
}

export type AdminToolsRepository = ReturnType<typeof createAdminToolsRepository>;
