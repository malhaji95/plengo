import { and, asc, desc, eq, inArray, isNull } from 'drizzle-orm';
import {
  educationLevels,
  importErrors,
  importJobs,
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

export type ImportJobRow = typeof importJobs.$inferSelect;

/** Bulk import jobs and the code lookups rows are resolved with (spec §27). */
export function createImportRepository(db: Db) {
  return {
    insertJob: async (values: typeof importJobs.$inferInsert) =>
      (await db.insert(importJobs).values(values).returning())[0]!,

    job: async (id: string) => (await db.select().from(importJobs).where(eq(importJobs.id, id)))[0] ?? null,

    jobs: (limit: number) => db.select().from(importJobs).orderBy(desc(importJobs.createdAt)).limit(limit),

    /** Updates the job only while it is in `from`; returns whether it was. */
    async transition(
      id: string,
      from: ImportJobRow['status'],
      values: Partial<typeof importJobs.$inferInsert>,
    ) {
      const rows = await db
        .update(importJobs)
        .set(values)
        .where(and(eq(importJobs.id, id), eq(importJobs.status, from)))
        .returning({ id: importJobs.id });
      return rows.length > 0;
    },

    /** Marks the import done inside the import transaction; the validated rows are dropped. */
    async complete(tx: Tx, id: string, summary: Record<string, unknown>, at: Date) {
      await tx
        .update(importJobs)
        .set({ status: 'completed', rows: null, summary, completedAt: at })
        .where(eq(importJobs.id, id));
    },

    async replaceErrors(
      jobId: string,
      errors: { rowNumber: number; field: string | null; message: string }[],
    ) {
      await db.delete(importErrors).where(eq(importErrors.jobId, jobId));
      for (let i = 0; i < errors.length; i += 500) {
        await db.insert(importErrors).values(errors.slice(i, i + 500).map((e) => ({ jobId, ...e })));
      }
    },

    errors: (jobId: string, limit: number) =>
      db
        .select()
        .from(importErrors)
        .where(eq(importErrors.jobId, jobId))
        .orderBy(asc(importErrors.rowNumber), asc(importErrors.id))
        .limit(limit),

    levels: (codes: string[]) =>
      codes.length
        ? db.select().from(educationLevels).where(inArray(educationLevels.code, codes))
        : Promise.resolve([]),

    subjects: (codes: string[]) =>
      codes.length
        ? db
            .select({ id: subjects.id, code: subjects.code, educationLevelId: subjects.educationLevelId })
            .from(subjects)
            .where(and(inArray(subjects.code, codes), isNull(subjects.deletedAt)))
        : Promise.resolve([]),

    units: (subjectIds: string[]) =>
      subjectIds.length
        ? db
            .select({ id: units.id, subjectId: units.subjectId, code: units.code })
            .from(units)
            .where(and(inArray(units.subjectId, subjectIds), isNull(units.deletedAt)))
        : Promise.resolve([]),

    lessons: (subjectIds: string[]) =>
      subjectIds.length
        ? db
            .select({
              id: lessons.id,
              subjectId: lessons.subjectId,
              unitId: lessons.unitId,
              code: lessons.code,
            })
            .from(lessons)
            .where(and(inArray(lessons.subjectId, subjectIds), isNull(lessons.deletedAt)))
        : Promise.resolve([]),

    tracks: (slugs: string[]) =>
      slugs.length
        ? db
            .select({ id: teacherTracks.id, subjectId: teacherTracks.subjectId, slug: teacherTracks.slug })
            .from(teacherTracks)
            .where(and(inArray(teacherTracks.slug, slugs), isNull(teacherTracks.deletedAt)))
        : Promise.resolve([]),

    /** Live questions of one type in a scope, in their order, with the codes an import file uses. */
    async exportRows(
      type: (typeof questions.$inferSelect)['type'],
      subjectId: string,
      trackId: string | null,
    ) {
      const rows = await db
        .select({
          q: questions,
          levelCode: educationLevels.code,
          subjectCode: subjects.code,
          unitCode: units.code,
          lessonCode: lessons.code,
          trackSlug: teacherTracks.slug,
        })
        .from(questions)
        .innerJoin(subjects, eq(subjects.id, questions.subjectId))
        .innerJoin(educationLevels, eq(educationLevels.id, subjects.educationLevelId))
        .leftJoin(units, eq(units.id, questions.unitId))
        .leftJoin(lessons, eq(lessons.id, questions.lessonId))
        .leftJoin(teacherTracks, eq(teacherTracks.id, questions.teacherTrackId))
        .where(
          and(
            eq(questions.type, type),
            eq(questions.subjectId, subjectId),
            trackId ? eq(questions.teacherTrackId, trackId) : isNull(questions.teacherTrackId),
            isNull(questions.deletedAt),
          ),
        )
        .orderBy(asc(questions.sortOrder), asc(questions.createdAt));
      const ids = rows.map((r) => r.q.id);
      const [options, answers] = ids.length
        ? await Promise.all([
            db
              .select()
              .from(questionOptions)
              .where(inArray(questionOptions.questionId, ids))
              .orderBy(asc(questionOptions.sortOrder)),
            db
              .select()
              .from(questionAnswers)
              .where(and(inArray(questionAnswers.questionId, ids), eq(questionAnswers.isActive, true)))
              .orderBy(asc(questionAnswers.createdAt)),
          ])
        : [[], []];
      return rows.map((r) => ({
        ...r,
        options: options.filter((o) => o.questionId === r.q.id),
        answers: answers.filter((a) => a.questionId === r.q.id).map((a) => a.answerOriginal),
      }));
    },
  };
}

export type ImportRepository = ReturnType<typeof createImportRepository>;
