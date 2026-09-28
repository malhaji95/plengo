import { and, asc, desc, eq, gte, isNotNull, isNull, ne, sql } from 'drizzle-orm';
import {
  cardStates,
  flashcardDecks,
  flashcards,
  questions,
  quizAttemptAnswers,
  quizAttempts,
  reviewLogs,
  subjects,
  teacherTracks,
  units,
  userMistakes,
  userSubjectStats,
  type Db,
} from '@plengo/db';
import { BUSINESS_UTC_OFFSET_MS, DAY, DAY_STARTS_AT_MS } from '@plengo/srs';

/**
 * The business day (04:00 Damascus boundary) of a timestamp column, as SQL. Grouped by position
 * (`group by 1`): the bound parameters make a repeated expression look different to Postgres.
 */
const dayOf = (col: unknown) =>
  sql<number>`floor((extract(epoch from ${col}) * 1000 + ${BUSINESS_UTC_OFFSET_MS - DAY_STARTS_AT_MS}) / ${DAY})::int`;

const graded = (userId: string) =>
  and(eq(quizAttemptAnswers.userId, userId), isNotNull(quizAttemptAnswers.gradedAt));
const answeredCol = sql<number>`count(*)::int`;
const correctCol = sql<number>`count(*) filter (where ${quizAttemptAnswers.isCorrect})::int`;

/**
 * Statistics reads (§16.2): `user_subject_stats` totals, and aggregates over graded attempt answers
 * (indexed by user and grading time) joined to the question's current placement.
 */
export function createStatsRepository(db: Db) {
  return {
    /** Per subject scope totals with names, most answered first. */
    subjectTotals: (userId: string) =>
      db
        .select({
          s: userSubjectStats,
          subjectNameAr: subjects.nameAr,
          trackTitleAr: teacherTracks.titleAr,
        })
        .from(userSubjectStats)
        .innerJoin(subjects, eq(subjects.id, userSubjectStats.subjectId))
        .leftJoin(teacherTracks, eq(teacherTracks.id, userSubjectStats.teacherTrackId))
        .where(eq(userSubjectStats.userId, userId))
        .orderBy(desc(userSubjectStats.answered)),

    /** Track totals of one subject (general content excluded). */
    trackTotals: (userId: string, subjectId: string) =>
      db
        .select({ s: userSubjectStats, trackTitleAr: teacherTracks.titleAr })
        .from(userSubjectStats)
        .innerJoin(teacherTracks, eq(teacherTracks.id, userSubjectStats.teacherTrackId))
        .where(and(eq(userSubjectStats.userId, userId), eq(userSubjectStats.subjectId, subjectId))),

    async submittedAttemptCount(userId: string) {
      const [row] = await db
        .select({ n: sql<number>`count(*)::int` })
        .from(quizAttempts)
        .where(and(eq(quizAttempts.userId, userId), eq(quizAttempts.status, 'submitted')));
      return row?.n ?? 0;
    },

    byType: (userId: string) =>
      db
        .select({ type: questions.type, answered: answeredCol, correct: correctCol })
        .from(quizAttemptAnswers)
        .innerJoin(questions, eq(questions.id, quizAttemptAnswers.questionId))
        .where(graded(userId))
        .groupBy(questions.type),

    /** Live units with at least `minAnswers` graded answers, lowest accuracy first. */
    weakestUnits: (userId: string, minAnswers: number, limit: number) =>
      db
        .select({
          unitId: units.id,
          unitNameAr: units.titleAr,
          subjectId: subjects.id,
          subjectNameAr: subjects.nameAr,
          answered: answeredCol,
          correct: correctCol,
        })
        .from(quizAttemptAnswers)
        .innerJoin(questions, eq(questions.id, quizAttemptAnswers.questionId))
        .innerJoin(units, eq(units.id, questions.unitId))
        .innerJoin(subjects, eq(subjects.id, questions.subjectId))
        .where(and(graded(userId), isNull(units.deletedAt)))
        .groupBy(units.id, units.titleAr, subjects.id, subjects.nameAr)
        .having(sql`count(*) >= ${minAnswers}`)
        .orderBy(
          sql`count(*) filter (where ${quizAttemptAnswers.isCorrect})::float / count(*)`,
          asc(units.id),
        )
        .limit(limit),

    /** Non-removed mistakes on live published questions, most wrong first. */
    mostMissed: (userId: string, limit: number) =>
      db
        .select({ m: userMistakes, q: questions, subjectNameAr: subjects.nameAr })
        .from(userMistakes)
        .innerJoin(questions, eq(questions.id, userMistakes.questionId))
        .innerJoin(subjects, eq(subjects.id, questions.subjectId))
        .where(
          and(
            eq(userMistakes.userId, userId),
            ne(userMistakes.status, 'removed'),
            isNull(questions.deletedAt),
            eq(questions.status, 'published'),
          ),
        )
        .orderBy(desc(userMistakes.wrongCount), desc(userMistakes.lastWrongAt))
        .limit(limit),

    /** Business days with a graded answer. */
    answerDays: (userId: string) =>
      db
        .selectDistinct({ day: dayOf(quizAttemptAnswers.gradedAt) })
        .from(quizAttemptAnswers)
        .where(graded(userId)),

    /** Business days with a (not undone) card review. */
    reviewDays: (userId: string) =>
      db
        .selectDistinct({ day: dayOf(reviewLogs.reviewedAt) })
        .from(reviewLogs)
        .where(and(eq(reviewLogs.userId, userId), eq(reviewLogs.undone, false))),

    /** Graded answers in one subject grouped by the question's unit, lesson and type. */
    subjectGroups: (userId: string, subjectId: string) =>
      db
        .select({
          unitId: questions.unitId,
          lessonId: questions.lessonId,
          type: questions.type,
          answered: answeredCol,
          correct: correctCol,
        })
        .from(quizAttemptAnswers)
        .innerJoin(questions, eq(questions.id, quizAttemptAnswers.questionId))
        .where(and(graded(userId), eq(questions.subjectId, subjectId)))
        .groupBy(questions.unitId, questions.lessonId, questions.type),

    /** Graded answers per business day since `since`. */
    answersPerDay: (userId: string, since: Date) =>
      db
        .select({ day: dayOf(quizAttemptAnswers.gradedAt), answered: answeredCol, correct: correctCol })
        .from(quizAttemptAnswers)
        .where(and(graded(userId), gte(quizAttemptAnswers.gradedAt, since)))
        .groupBy(sql`1`),

    /** The student's states on live published cards of live published decks, with the deck. */
    cardStates: (userId: string) =>
      db
        .select({ state: cardStates.state, dueAt: cardStates.dueAt, deck: flashcardDecks })
        .from(cardStates)
        .innerJoin(flashcards, eq(flashcards.id, cardStates.flashcardId))
        .innerJoin(flashcardDecks, eq(flashcardDecks.id, flashcards.deckId))
        .where(
          and(
            eq(cardStates.userId, userId),
            isNull(flashcards.deletedAt),
            eq(flashcards.status, 'published'),
            isNull(flashcardDecks.deletedAt),
            eq(flashcardDecks.status, 'published'),
          ),
        ),

    /** Per business day since `since`: reviews, reviews of review-state cards, and those not failed. */
    reviewsPerDay: (userId: string, since: Date) =>
      db
        .select({
          day: dayOf(reviewLogs.reviewedAt),
          n: sql<number>`count(*)::int`,
          reviewed: sql<number>`count(*) filter (where ${reviewLogs.stateBefore} ->> 'state' = 'review')::int`,
          kept: sql<number>`count(*) filter (where ${reviewLogs.stateBefore} ->> 'state' = 'review' and ${reviewLogs.rating} <> 'again')::int`,
        })
        .from(reviewLogs)
        .where(
          and(eq(reviewLogs.userId, userId), eq(reviewLogs.undone, false), gte(reviewLogs.reviewedAt, since)),
        )
        .groupBy(sql`1`),
  };
}

export type StatsRepository = ReturnType<typeof createStatsRepository>;
