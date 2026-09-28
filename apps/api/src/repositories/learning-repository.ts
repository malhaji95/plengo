import { sql } from 'drizzle-orm';
import { questionStats, userMistakes, userProgress, userSubjectStats, type Tx } from '@plengo/db';

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
 * Writes that follow a graded answer (§16.1, §16.2, §18, §28.1). Each runs inside the grading
 * transaction as a single upsert, so concurrent grading of other questions never loses counts.
 */
export function createLearningRepository() {
  return {
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
