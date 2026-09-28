import { and, asc, desc, eq, gte, isNotNull, isNull, ne, sql } from 'drizzle-orm';
import type { Accuracy, FlashcardStats, StatsOverview, SubjectStats } from '@plengo/contracts';
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
import { BUSINESS_UTC_OFFSET_MS, DAY, DAY_STARTS_AT_MS, businessDay, startOfBusinessDay } from '@plengo/srs';
import type { StructureRepository } from '../repositories/structure-repository.js';
import type { TeacherRepository } from '../repositories/teacher-repository.js';
import type { AccessService } from './access-service.js';
import { assertVisibleScope } from './content-placement.js';

/** Units need this many answers before they can be called weak (§16.2). */
export const WEAK_UNIT_MIN_ANSWERS = 10;

export const accuracy = (answered: number, correct: number): Accuracy => ({
  answered,
  correct,
  accuracyPercent: answered ? Math.round((correct * 100) / answered) : null,
});

/**
 * The business day (04:00 Damascus boundary) of a timestamp column, as SQL. Grouped by position
 * (`group by 1`): the bound parameters make a repeated expression look different to Postgres.
 */
const dayOf = (col: unknown) =>
  sql<number>`floor((extract(epoch from ${col}) * 1000 + ${BUSINESS_UTC_OFFSET_MS - DAY_STARTS_AT_MS}) / ${DAY})::int`;

/** A business day number as its calendar date. */
export const dateOf = (day: number) => new Date(day * DAY).toISOString().slice(0, 10);

/** Consecutive business days with activity, ending today (or yesterday when today has none yet). */
export function streak(days: Set<number>, today: number) {
  let d = days.has(today) ? today : today - 1;
  let n = 0;
  while (days.has(d)) {
    n += 1;
    d -= 1;
  }
  return n;
}

/**
 * Statistics (spec §16.2). Totals come from `user_subject_stats`; breakdowns and trends from graded
 * attempt answers (indexed by user and grading time) joined to the question's current placement.
 */
export function createStatsService(deps: {
  db: Db;
  structureRepo: StructureRepository;
  teacherRepo: TeacherRepository;
  access: AccessService;
  now?: () => Date;
}) {
  const { db, structureRepo, teacherRepo, access } = deps;
  const now = deps.now ?? (() => new Date());

  const graded = (userId: string) =>
    and(eq(quizAttemptAnswers.userId, userId), isNotNull(quizAttemptAnswers.gradedAt));
  const answeredCol = sql<number>`count(*)::int`;
  const correctCol = sql<number>`count(*) filter (where ${quizAttemptAnswers.isCorrect})::int`;

  return {
    async overview(userId: string): Promise<StatsOverview> {
      const today = businessDay(now().getTime());
      const [subjectRows, completed, byType, weak, missed, mistakeCounts, answerDays, reviewDays, ctx] =
        await Promise.all([
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
          db
            .select({ n: sql<number>`count(*)::int` })
            .from(quizAttempts)
            .where(and(eq(quizAttempts.userId, userId), eq(quizAttempts.status, 'submitted'))),
          db
            .select({ type: questions.type, answered: answeredCol, correct: correctCol })
            .from(quizAttemptAnswers)
            .innerJoin(questions, eq(questions.id, quizAttemptAnswers.questionId))
            .where(graded(userId))
            .groupBy(questions.type),
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
            .having(sql`count(*) >= ${WEAK_UNIT_MIN_ANSWERS}`)
            .orderBy(
              sql`count(*) filter (where ${quizAttemptAnswers.isCorrect})::float / count(*)`,
              asc(units.id),
            )
            .limit(5),
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
            .limit(20),
          db
            .select({ status: userMistakes.status, n: sql<number>`count(*)::int` })
            .from(userMistakes)
            .where(eq(userMistakes.userId, userId))
            .groupBy(userMistakes.status),
          db
            .selectDistinct({ day: dayOf(quizAttemptAnswers.gradedAt) })
            .from(quizAttemptAnswers)
            .where(graded(userId)),
          db
            .selectDistinct({ day: dayOf(reviewLogs.reviewedAt) })
            .from(reviewLogs)
            .where(and(eq(reviewLogs.userId, userId), eq(reviewLogs.undone, false))),
          access.context(userId),
        ]);

      const totals = subjectRows.reduce(
        (t, r) => ({
          answered: t.answered + r.s.answered,
          correct: t.correct + r.s.correct,
          timeMs: t.timeMs + r.s.timeMs,
        }),
        { answered: 0, correct: 0, timeMs: 0 },
      );
      const days = new Set([...answerDays, ...reviewDays].map((r) => r.day));
      const count = (s: string) => mistakeCounts.find((m) => m.status === s)?.n ?? 0;
      return {
        totals: accuracy(totals.answered, totals.correct),
        quizzesCompleted: completed[0]?.n ?? 0,
        studyDays: days.size,
        currentStreak: streak(days, today),
        averageTimeMs: totals.answered ? Math.round(totals.timeMs / totals.answered) : null,
        mistakes: { active: count('active'), mastered: count('mastered') },
        subjects: subjectRows.map((r) => ({
          subjectId: r.s.subjectId,
          subjectNameAr: r.subjectNameAr,
          teacherTrackId: r.s.teacherTrackId,
          trackTitleAr: r.trackTitleAr,
          ...accuracy(r.s.answered, r.s.correct),
        })),
        byType: byType.map((r) => ({ type: r.type, ...accuracy(r.answered, r.correct) })),
        weakestUnits: weak.map((r) => ({
          unitId: r.unitId,
          unitNameAr: r.unitNameAr,
          subjectId: r.subjectId,
          subjectNameAr: r.subjectNameAr,
          ...accuracy(r.answered, r.correct),
        })),
        // Question text only while the student can still open the question.
        mostMissed: missed
          .filter((r) => ctx.canAccessItem(r.q))
          .slice(0, 5)
          .map((r) => ({
            questionId: r.q.id,
            questionText: r.q.questionText,
            subjectNameAr: r.subjectNameAr,
            wrongCount: r.m.wrongCount,
          })),
      };
    },

    async subject(userId: string, subjectId: string): Promise<SubjectStats> {
      await assertVisibleScope({ structureRepo, teacherRepo }, subjectId, null);
      const [subject, unitRows, lessonRows, groups, tracks] = await Promise.all([
        structureRepo.getSubject(subjectId, { studentVisible: true }),
        structureRepo.listUnits(subjectId),
        structureRepo.listLessons(subjectId),
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
        db
          .select({ s: userSubjectStats, trackTitleAr: teacherTracks.titleAr })
          .from(userSubjectStats)
          .innerJoin(teacherTracks, eq(teacherTracks.id, userSubjectStats.teacherTrackId))
          .where(and(eq(userSubjectStats.userId, userId), eq(userSubjectStats.subjectId, subjectId))),
      ]);
      const sum = (pick: (g: (typeof groups)[number]) => boolean) => {
        const rows = groups.filter(pick);
        return accuracy(
          rows.reduce((n, r) => n + r.answered, 0),
          rows.reduce((n, r) => n + r.correct, 0),
        );
      };
      const lessonAcc = (l: { id: string; titleAr: string }) => ({
        lessonId: l.id,
        lessonNameAr: l.titleAr,
        ...sum((g) => g.lessonId === l.id),
      });
      const types = [...new Set(groups.map((g) => g.type))];
      return {
        subjectId,
        subjectNameAr: subject?.nameAr ?? '',
        totals: sum(() => true),
        units: unitRows.map((u) => ({
          unitId: u.id,
          unitNameAr: u.titleAr,
          ...sum((g) => g.unitId === u.id),
          lessons: lessonRows.filter((l) => l.unitId === u.id).map(lessonAcc),
        })),
        lessons: lessonRows.filter((l) => !l.unitId).map(lessonAcc),
        tracks: tracks.map((t) => ({
          subjectId,
          subjectNameAr: subject?.nameAr ?? '',
          teacherTrackId: t.s.teacherTrackId,
          trackTitleAr: t.trackTitleAr,
          ...accuracy(t.s.answered, t.s.correct),
        })),
        byType: types.map((type) => ({ type, ...sum((g) => g.type === type) })),
      };
    },

    /** Weekly accuracy: 7-business-day windows ending today, oldest first. */
    async trend(userId: string, weeks: number) {
      const today = businessDay(now().getTime());
      const firstDay = today - weeks * 7 + 1;
      const rows = await db
        .select({ day: dayOf(quizAttemptAnswers.gradedAt), answered: answeredCol, correct: correctCol })
        .from(quizAttemptAnswers)
        .where(and(graded(userId), gte(quizAttemptAnswers.gradedAt, new Date(startOfBusinessDay(firstDay)))))
        .groupBy(sql`1`);
      return {
        weeks: Array.from({ length: weeks }, (_, i) => {
          const start = firstDay + i * 7;
          const inWeek = rows.filter((r) => r.day >= start && r.day < start + 7);
          return {
            weekStart: dateOf(start),
            ...accuracy(
              inWeek.reduce((n, r) => n + r.answered, 0),
              inWeek.reduce((n, r) => n + r.correct, 0),
            ),
          };
        }),
      };
    },

    /** Official-card study statistics, only for decks the student can open. */
    async flashcards(userId: string): Promise<FlashcardStats> {
      const at = now().getTime();
      const today = businessDay(at);
      const [states, logs, ctx] = await Promise.all([
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
        db
          .select({
            day: dayOf(reviewLogs.reviewedAt),
            n: sql<number>`count(*)::int`,
            reviewed: sql<number>`count(*) filter (where ${reviewLogs.stateBefore} ->> 'state' = 'review')::int`,
            kept: sql<number>`count(*) filter (where ${reviewLogs.stateBefore} ->> 'state' = 'review' and ${reviewLogs.rating} <> 'again')::int`,
          })
          .from(reviewLogs)
          .where(
            and(
              eq(reviewLogs.userId, userId),
              eq(reviewLogs.undone, false),
              gte(reviewLogs.reviewedAt, new Date(startOfBusinessDay(today - 29))),
            ),
          )
          .groupBy(sql`1`),
        access.context(userId),
      ]);
      const open = states.filter((s) => ctx.canAccessItem(s.deck));
      const dueBy = (day: number) => startOfBusinessDay(day + 1);
      const forecast = Array.from({ length: 7 }, (_, i) => {
        const day = today + i;
        const count = open.filter(
          (s) =>
            s.state !== 'new' &&
            s.dueAt.getTime() < dueBy(day) &&
            (i === 0 || s.dueAt.getTime() >= dueBy(day - 1)),
        ).length;
        return { date: dateOf(day), count };
      });
      const reviewed = logs.reduce((n, r) => n + r.reviewed, 0);
      const kept = logs.reduce((n, r) => n + r.kept, 0);
      const byState = { new: 0, learning: 0, review: 0, relearning: 0 };
      for (const s of open) byState[s.state] += 1;
      return {
        dueToday: forecast[0]!.count,
        forecast,
        reviewsPerDay: Array.from({ length: 30 }, (_, i) => {
          const day = today - 29 + i;
          return { date: dateOf(day), count: logs.find((r) => r.day === day)?.n ?? 0 };
        }),
        retentionPercent: reviewed ? Math.round((kept * 100) / reviewed) : null,
        byState,
      };
    },
  };
}

export type StatsService = ReturnType<typeof createStatsService>;
