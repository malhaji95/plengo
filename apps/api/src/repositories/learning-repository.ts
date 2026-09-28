import { and, desc, eq, inArray, isNull, ne, sql } from 'drizzle-orm';
import {
  lessons,
  questionStats,
  questions,
  subjects,
  teacherTracks,
  units,
  userMistakes,
  userProgress,
  userSubjectStats,
  type AttemptFilters,
  type Db,
  type Tx,
} from '@plengo/db';

/** Auto-flag thresholds for admin review (§26.2). */
export const QUESTION_FLAG_MIN_ATTEMPTS = 30;
export const QUESTION_FLAG_MAX_CORRECT_PERCENT = 20;

export interface GradedAnswer {
  userId: string;
  question: {
    id: string;
    subjectId: string;
    teacherTrackId: string | null;
    unitId: string | null;
    lessonId: string | null;
  };
  correctOptionId: string | null;
  selectedOptionId: string | null;
  isCorrect: boolean;
  timeMs: number;
  at: Date;
}

export interface ProgressTouch {
  userId: string;
  subjectId: string;
  teacherTrackId: string | null;
  unitId: string | null;
  lessonId: string | null;
  type: 'question' | 'quiz' | 'deck';
  itemId: string | null;
  at: Date;
}

/**
 * Mistake bank and progress pointers (§16.1, §18). The writes that follow a graded answer (§16.1,
 * §16.2, §18, §28.1) each run inside the grading transaction as a single upsert, so concurrent
 * grading of other questions never loses counts.
 */
export function createLearningRepository(db: Db) {
  return {
    /** The student's non-removed mistakes on live published questions, latest wrong first. */
    mistakes: (userId: string) =>
      db
        .select({ m: userMistakes, q: questions })
        .from(userMistakes)
        .innerJoin(questions, eq(questions.id, userMistakes.questionId))
        .where(
          and(
            eq(userMistakes.userId, userId),
            ne(userMistakes.status, 'removed'),
            isNull(questions.deletedAt),
            eq(questions.status, 'published'),
          ),
        )
        .orderBy(desc(userMistakes.lastWrongAt)),

    /**
     * Questions of the student's active mistakes, live and published, matching the filters. The
     * track filter applies only with a subject (null means general content).
     */
    activeMistakeQuestions: (userId: string, f: AttemptFilters) =>
      db
        .select({ q: questions })
        .from(userMistakes)
        .innerJoin(questions, eq(questions.id, userMistakes.questionId))
        .where(
          and(
            eq(userMistakes.userId, userId),
            eq(userMistakes.status, 'active'),
            isNull(questions.deletedAt),
            eq(questions.status, 'published'),
            f.subjectId ? eq(questions.subjectId, f.subjectId) : undefined,
            f.subjectId && f.teacherTrackId !== undefined
              ? f.teacherTrackId
                ? eq(questions.teacherTrackId, f.teacherTrackId)
                : isNull(questions.teacherTrackId)
              : undefined,
            f.unitId ? eq(questions.unitId, f.unitId) : undefined,
            f.lessonId ? eq(questions.lessonId, f.lessonId) : undefined,
            f.types?.length ? inArray(questions.type, f.types) : undefined,
            f.questionIds?.length ? inArray(questions.id, f.questionIds) : undefined,
          ),
        ),

    /** Marks a mistake removed; false when the student has none for the question. */
    async removeMistake(userId: string, questionId: string, at: Date) {
      const rows = await db
        .update(userMistakes)
        .set({ status: 'removed', updatedAt: at })
        .where(and(eq(userMistakes.userId, userId), eq(userMistakes.questionId, questionId)))
        .returning({ id: userMistakes.questionId });
      return rows.length > 0;
    },

    /** The resume pointer of one subject scope (a null track is general content). */
    progressPointer: (userId: string, subjectId: string, teacherTrackId: string | null) =>
      db
        .select()
        .from(userProgress)
        .where(
          and(
            eq(userProgress.userId, userId),
            eq(userProgress.subjectId, subjectId),
            teacherTrackId
              ? eq(userProgress.teacherTrackId, teacherTrackId)
              : isNull(userProgress.teacherTrackId),
          ),
        ),

    /** The student's resume pointers, newest first. */
    recentProgress: (userId: string, limit: number) =>
      db
        .select()
        .from(userProgress)
        .where(eq(userProgress.userId, userId))
        .orderBy(desc(userProgress.lastActivityAt))
        .limit(limit),

    /** Arabic names of subjects, tracks, units and lessons by id. */
    async names(subjectIds: string[], trackIds: string[], unitIds: string[], lessonIds: string[]) {
      const [s, t, u, l] = await Promise.all([
        subjectIds.length
          ? db
              .select({ id: subjects.id, n: subjects.nameAr })
              .from(subjects)
              .where(inArray(subjects.id, subjectIds))
          : [],
        trackIds.length
          ? db
              .select({ id: teacherTracks.id, n: teacherTracks.titleAr })
              .from(teacherTracks)
              .where(inArray(teacherTracks.id, trackIds))
          : [],
        unitIds.length
          ? db.select({ id: units.id, n: units.titleAr }).from(units).where(inArray(units.id, unitIds))
          : [],
        lessonIds.length
          ? db
              .select({ id: lessons.id, n: lessons.titleAr })
              .from(lessons)
              .where(inArray(lessons.id, lessonIds))
          : [],
      ]);
      const map = (rows: { id: string; n: string }[]) => new Map(rows.map((r) => [r.id, r.n]));
      return { subjects: map(s), tracks: map(t), units: map(u), lessons: map(l) };
    },

    /**
     * Wrong → active with the streak reset (re-activates removed and mastered mistakes). Correct on
     * an active mistake → streak + 1, mastered at `masteryStreak`. Correct otherwise → no change.
     */
    async recordMistake(tx: Tx, g: GradedAnswer, masteryStreak: number) {
      if (!g.isCorrect) {
        await tx
          .insert(userMistakes)
          .values({
            userId: g.userId,
            questionId: g.question.id,
            firstWrongAt: g.at,
            lastWrongAt: g.at,
            wrongCount: 1,
            correctStreak: 0,
            status: 'active',
            updatedAt: g.at,
          })
          .onConflictDoUpdate({
            target: [userMistakes.userId, userMistakes.questionId],
            set: {
              lastWrongAt: g.at,
              wrongCount: sql`${userMistakes.wrongCount} + 1`,
              correctStreak: 0,
              status: 'active',
              updatedAt: g.at,
            },
          });
        return;
      }
      await tx
        .update(userMistakes)
        .set({
          correctStreak: sql`${userMistakes.correctStreak} + 1`,
          status: sql`case when ${userMistakes.correctStreak} + 1 >= ${masteryStreak} then 'mastered'::mistake_status else 'active'::mistake_status end`,
          updatedAt: g.at,
        })
        .where(
          sql`${userMistakes.userId} = ${g.userId} and ${userMistakes.questionId} = ${g.question.id} and ${userMistakes.status} = 'active'`,
        );
    },

    async addSubjectStats(tx: Tx, g: GradedAnswer) {
      await tx
        .insert(userSubjectStats)
        .values({
          userId: g.userId,
          subjectId: g.question.subjectId,
          teacherTrackId: g.question.teacherTrackId,
          answered: 1,
          correct: g.isCorrect ? 1 : 0,
          timeMs: g.timeMs,
          updatedAt: g.at,
        })
        .onConflictDoUpdate({
          target: [userSubjectStats.userId, userSubjectStats.subjectId, userSubjectStats.teacherTrackId],
          set: {
            answered: sql`${userSubjectStats.answered} + 1`,
            correct: sql`${userSubjectStats.correct} + ${g.isCorrect ? 1 : 0}`,
            timeMs: sql`${userSubjectStats.timeMs} + ${g.timeMs}`,
            updatedAt: g.at,
          },
        });
    },

    /**
     * Question aggregate for admin analytics. Flagged (and kept flagged until an admin looks) once it
     * has ≥ 30 attempts and either < 20% correct or a wrong option chosen more than the correct one.
     */
    async addQuestionStats(tx: Tx, g: GradedAnswer) {
      const option = g.selectedOptionId;
      await tx
        .insert(questionStats)
        .values({
          questionId: g.question.id,
          attemptCount: 1,
          correctCount: g.isCorrect ? 1 : 0,
          totalTimeMs: g.timeMs,
          optionDistribution: option ? { [option]: 1 } : {},
          lastAttemptAt: g.at,
          updatedAt: g.at,
        })
        .onConflictDoUpdate({
          target: questionStats.questionId,
          set: {
            attemptCount: sql`${questionStats.attemptCount} + 1`,
            correctCount: sql`${questionStats.correctCount} + ${g.isCorrect ? 1 : 0}`,
            totalTimeMs: sql`${questionStats.totalTimeMs} + ${g.timeMs}`,
            optionDistribution: option
              ? sql`${questionStats.optionDistribution} || jsonb_build_object(${option}::text, coalesce((${questionStats.optionDistribution} ->> ${option}::text)::int, 0) + 1)`
              : sql`${questionStats.optionDistribution}`,
            lastAttemptAt: g.at,
            updatedAt: g.at,
          },
        });
      const correct = g.correctOptionId;
      await tx.execute(sql`
        update question_stats set flagged_for_review = true
        where question_id = ${g.question.id}
          and not flagged_for_review
          and attempt_count >= ${QUESTION_FLAG_MIN_ATTEMPTS}
          and (
            correct_count * 100 < attempt_count * ${QUESTION_FLAG_MAX_CORRECT_PERCENT}
            or exists (
              select 1 from jsonb_each_text(option_distribution) d
              where ${correct}::text is not null and d.key <> ${correct}::text
                and d.value::int > coalesce((option_distribution ->> ${correct}::text)::int, 0)
            )
          )`);
    },

    /** The resume pointer for the item's subject scope (§18). */
    async touchProgress(tx: Tx, p: ProgressTouch) {
      const values = {
        unitId: p.unitId,
        lessonId: p.lessonId,
        lastActivityType: p.type,
        lastItemId: p.itemId,
        lastActivityAt: p.at,
        updatedAt: p.at,
      };
      await tx
        .insert(userProgress)
        .values({ userId: p.userId, subjectId: p.subjectId, teacherTrackId: p.teacherTrackId, ...values })
        .onConflictDoUpdate({
          target: [userProgress.userId, userProgress.subjectId, userProgress.teacherTrackId],
          set: values,
          setWhere: sql`${userProgress.lastActivityAt} <= ${p.at}`,
        });
    },
  };
}

export type LearningRepository = ReturnType<typeof createLearningRepository>;
