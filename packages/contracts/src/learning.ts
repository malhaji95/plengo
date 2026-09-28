import { z } from 'zod';
import { studentCardSchema, studentDeckSchema } from './flashcards.js';
import { questionTypeSchema, studentQuestionSchema } from './questions.js';

/* Mistake bank, statistics, bookmarks and progress (spec §16–§18). */

const int = () => z.number().int();

// ---- mistake bank ----

export const mistakeStatusSchema = z.enum(['active', 'mastered', 'removed']);

export const mistakeSchema = z.object({
  questionId: z.string(),
  type: questionTypeSchema,
  questionText: z.string(),
  subjectId: z.string(),
  subjectNameAr: z.string(),
  teacherTrackId: z.string().nullable(),
  trackTitleAr: z.string().nullable(),
  unitId: z.string().nullable(),
  unitNameAr: z.string().nullable(),
  lessonId: z.string().nullable(),
  lessonNameAr: z.string().nullable(),
  status: mistakeStatusSchema,
  wrongCount: int(),
  correctStreak: int(),
  firstWrongAt: z.string(),
  lastWrongAt: z.string(),
});

export const mistakeListSchema = z.object({
  items: z.array(mistakeSchema),
  /** Across the whole bank (only questions the student can still open). */
  activeCount: int(),
  masteredCount: int(),
  /** Correct answers in a row that master a mistake (config `mistakeMasteryStreak`). */
  masteryStreak: int(),
  nextCursor: z.string().nullable(),
});

export const mistakeFilterStatusSchema = z.enum(['active', 'mastered']);
/** Same values as the question type; named separately so query enums get their own client type. */
export const mistakeFilterTypeSchema = z.enum(['mcq', 'true_false', 'written']);

export const mistakeQuerySchema = z.object({
  status: mistakeFilterStatusSchema.default('active'),
  subjectId: z.uuid().optional(),
  teacherTrackId: z.uuid().optional(),
  unitId: z.uuid().optional(),
  lessonId: z.uuid().optional(),
  type: mistakeFilterTypeSchema.optional(),
  cursor: z.string().max(200).optional(),
  limit: z.coerce.number().int().min(1).max(500).default(100),
});

export const learningSettingsSchema = z.object({ mistakeMasteryStreak: int().min(1).max(10) });

// ---- statistics ----

export const accuracySchema = z.object({
  answered: int(),
  correct: int(),
  /** Null when nothing was answered. */
  accuracyPercent: int().nullable(),
});

export const subjectAccuracySchema = accuracySchema.extend({
  subjectId: z.string(),
  subjectNameAr: z.string(),
  teacherTrackId: z.string().nullable(),
  trackTitleAr: z.string().nullable(),
});
export const typeAccuracySchema = accuracySchema.extend({ type: questionTypeSchema });
export const unitAccuracySchema = accuracySchema.extend({
  unitId: z.string(),
  unitNameAr: z.string(),
  subjectId: z.string(),
  subjectNameAr: z.string(),
});
export const missedQuestionSchema = z.object({
  questionId: z.string(),
  questionText: z.string(),
  subjectNameAr: z.string(),
  wrongCount: int(),
});

export const statsOverviewSchema = z.object({
  totals: accuracySchema,
  quizzesCompleted: int(),
  /** Business days (04:00 Damascus boundary) with answers or reviews. */
  studyDays: int(),
  currentStreak: int(),
  averageTimeMs: int().nullable(),
  mistakes: z.object({ active: int(), mastered: int() }),
  subjects: z.array(subjectAccuracySchema),
  byType: z.array(typeAccuracySchema),
  /** Lowest accuracy among units with at least 10 answers. */
  weakestUnits: z.array(unitAccuracySchema),
  mostMissed: z.array(missedQuestionSchema),
});

export const lessonAccuracySchema = accuracySchema.extend({ lessonId: z.string(), lessonNameAr: z.string() });
export const unitBreakdownSchema = accuracySchema.extend({
  unitId: z.string(),
  unitNameAr: z.string(),
  lessons: z.array(lessonAccuracySchema),
});
export const subjectStatsSchema = z.object({
  subjectId: z.string(),
  subjectNameAr: z.string(),
  totals: accuracySchema,
  units: z.array(unitBreakdownSchema),
  /** Lessons placed directly under the subject. */
  lessons: z.array(lessonAccuracySchema),
  tracks: z.array(subjectAccuracySchema),
  byType: z.array(typeAccuracySchema),
});

export const trendWeekSchema = accuracySchema.extend({
  /** Business date (YYYY-MM-DD) the week starts on. */
  weekStart: z.string(),
});
export const statsTrendSchema = z.object({ weeks: z.array(trendWeekSchema) });
export const statsTrendQuerySchema = z.object({ weeks: z.coerce.number().int().min(1).max(52).default(12) });

export const dayCountSchema = z.object({ date: z.string(), count: int() });
export const flashcardStatsSchema = z.object({
  dueToday: int(),
  /** Today plus the next six business days. */
  forecast: z.array(dayCountSchema),
  /** Last 30 business days. */
  reviewsPerDay: z.array(dayCountSchema),
  /** Share of review-state ratings that were not Again, last 30 days. */
  retentionPercent: int().nullable(),
  byState: z.object({ new: int(), learning: int(), review: int(), relearning: int() }),
});

// ---- bookmarks ----

export const bookmarkItemTypeSchema = z.enum(['question', 'flashcard', 'user_card', 'deck']);

export const bookmarkSchema = z.object({
  id: z.string(),
  itemType: bookmarkItemTypeSchema,
  itemId: z.string(),
  createdAt: z.string(),
  /** Locked items show as locked, with metadata only (§17). */
  locked: z.boolean(),
  /** False when the item was removed or unpublished. */
  available: z.boolean(),
  titleAr: z.string().nullable(),
  subjectId: z.string().nullable(),
  subjectNameAr: z.string().nullable(),
  question: studentQuestionSchema.nullable(),
  deck: studentDeckSchema.nullable(),
  card: studentCardSchema.nullable(),
});
export const bookmarkListSchema = z.object({
  items: z.array(bookmarkSchema),
  nextCursor: z.string().nullable(),
  urlsExpireAt: z.string(),
});
export const bookmarkQuerySchema = z.object({
  itemType: bookmarkItemTypeSchema.optional(),
  cursor: z.string().max(200).optional(),
  limit: z.coerce.number().int().min(1).max(200).default(50),
});
export const bookmarkBodySchema = z.object({ itemType: bookmarkItemTypeSchema, itemId: z.uuid() });
export const bookmarkKeySchema = z.object({ itemType: bookmarkItemTypeSchema, itemId: z.string() });
export const bookmarkKeyListSchema = z.array(bookmarkKeySchema);

// ---- progress ----

export const activityTypeSchema = z.enum(['question', 'quiz', 'deck']);

export const progressCountsSchema = z.object({
  questionsAttempted: int(),
  questionsCorrect: int(),
  questionsTotal: int(),
  quizzesCompleted: int(),
  quizzesTotal: int(),
  flashcardsStudied: int(),
  flashcardsTotal: int(),
  /** Distinct accessible published items interacted with / all of them (§18). */
  completionPercent: int(),
});

export const unitProgressSchema = progressCountsSchema.extend({ unitId: z.string() });
export const lessonProgressSchema = progressCountsSchema.extend({ lessonId: z.string() });

export const scopeProgressSchema = progressCountsSchema.extend({
  subjectId: z.string(),
  teacherTrackId: z.string().nullable(),
  lastActivityAt: z.string().nullable(),
  units: z.array(unitProgressSchema),
  lessons: z.array(lessonProgressSchema),
});
export const progressQuerySchema = z.object({
  subjectId: z.uuid(),
  teacherTrackId: z.uuid().optional(),
});

export const resumeItemSchema = z.object({
  subjectId: z.string(),
  subjectNameAr: z.string(),
  teacherTrackId: z.string().nullable(),
  trackTitleAr: z.string().nullable(),
  unitId: z.string().nullable(),
  unitNameAr: z.string().nullable(),
  lessonId: z.string().nullable(),
  lessonNameAr: z.string().nullable(),
  activityType: activityTypeSchema,
  itemId: z.string().nullable(),
  itemTitleAr: z.string().nullable(),
  /** An unfinished attempt to continue, when the last activity was one. */
  attemptId: z.string().nullable(),
  lastActivityAt: z.string(),
});
export const resumeListSchema = z.array(resumeItemSchema);

export type Mistake = z.infer<typeof mistakeSchema>;
export type LearningSettings = z.infer<typeof learningSettingsSchema>;
export type Accuracy = z.infer<typeof accuracySchema>;
export type StatsOverview = z.infer<typeof statsOverviewSchema>;
export type SubjectStats = z.infer<typeof subjectStatsSchema>;
export type FlashcardStats = z.infer<typeof flashcardStatsSchema>;
export type Bookmark = z.infer<typeof bookmarkSchema>;
export type ProgressCounts = z.infer<typeof progressCountsSchema>;
export type ScopeProgress = z.infer<typeof scopeProgressSchema>;
export type ResumeItem = z.infer<typeof resumeItemSchema>;

const named: [z.ZodType, string][] = [
  [mistakeFilterStatusSchema, 'MistakeFilterStatus'],
  [mistakeFilterTypeSchema, 'MistakeFilterType'],
  [mistakeSchema, 'Mistake'],
  [mistakeListSchema, 'MistakeList'],
  [learningSettingsSchema, 'LearningSettings'],
  [accuracySchema, 'Accuracy'],
  [subjectAccuracySchema, 'SubjectAccuracy'],
  [typeAccuracySchema, 'TypeAccuracy'],
  [unitAccuracySchema, 'UnitAccuracy'],
  [missedQuestionSchema, 'MissedQuestion'],
  [statsOverviewSchema, 'StatsOverview'],
  [lessonAccuracySchema, 'LessonAccuracy'],
  [unitBreakdownSchema, 'UnitBreakdown'],
  [subjectStatsSchema, 'SubjectStats'],
  [trendWeekSchema, 'TrendWeek'],
  [statsTrendSchema, 'StatsTrend'],
  [dayCountSchema, 'DayCount'],
  [flashcardStatsSchema, 'FlashcardStats'],
  [bookmarkItemTypeSchema, 'BookmarkItemType'],
  [bookmarkSchema, 'Bookmark'],
  [bookmarkListSchema, 'BookmarkList'],
  [bookmarkBodySchema, 'BookmarkRequest'],
  [bookmarkKeySchema, 'BookmarkKey'],
  [bookmarkKeyListSchema, 'BookmarkKeyList'],
  [progressCountsSchema, 'ProgressCounts'],
  [unitProgressSchema, 'UnitProgress'],
  [lessonProgressSchema, 'LessonProgress'],
  [scopeProgressSchema, 'ScopeProgress'],
  [resumeItemSchema, 'ResumeItem'],
  [resumeListSchema, 'ResumeList'],
];
for (const [schema, id] of named) z.globalRegistry.add(schema, { id });
