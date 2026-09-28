import type { Accuracy, FlashcardStats, StatsOverview, SubjectStats } from '@plengo/contracts';
import { DAY, businessDay, startOfBusinessDay } from '@plengo/srs';
import type { StatsRepository } from '../repositories/stats-repository.js';
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
  repo: StatsRepository;
  structureRepo: StructureRepository;
  teacherRepo: TeacherRepository;
  access: AccessService;
  /** Same counts as the mistake bank shows (hidden questions excluded). */
  mistakeCounts: (userId: string) => Promise<{ active: number; mastered: number }>;
  now?: () => Date;
}) {
  const { repo, structureRepo, teacherRepo, access } = deps;
  const now = deps.now ?? (() => new Date());

  return {
    async overview(userId: string): Promise<StatsOverview> {
      const today = businessDay(now().getTime());
      const [subjectRows, completed, byType, weak, missed, mistakeCounts, answerDays, reviewDays, ctx] =
        await Promise.all([
          repo.subjectTotals(userId),
          repo.submittedAttemptCount(userId),
          repo.byType(userId),
          repo.weakestUnits(userId, WEAK_UNIT_MIN_ANSWERS, 5),
          repo.mostMissed(userId, 20),
          deps.mistakeCounts(userId),
          repo.answerDays(userId),
          repo.reviewDays(userId),
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
      return {
        totals: accuracy(totals.answered, totals.correct),
        quizzesCompleted: completed,
        studyDays: days.size,
        currentStreak: streak(days, today),
        averageTimeMs: totals.answered ? Math.round(totals.timeMs / totals.answered) : null,
        mistakes: mistakeCounts,
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
        repo.subjectGroups(userId, subjectId),
        repo.trackTotals(userId, subjectId),
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
      const rows = await repo.answersPerDay(userId, new Date(startOfBusinessDay(firstDay)));
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
        repo.cardStates(userId),
        repo.reviewsPerDay(userId, new Date(startOfBusinessDay(today - 29))),
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
