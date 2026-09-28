import {
  bigint,
  boolean,
  index,
  integer,
  jsonb,
  pgTable,
  primaryKey,
  text,
  timestamp,
  unique,
  uuid,
} from 'drizzle-orm/pg-core';
import { questions, quizzes } from './content.js';
import {
  activityTypeEnum,
  attemptModeEnum,
  attemptSourceEnum,
  attemptStatusEnum,
  bookmarkItemTypeEnum,
  mistakeStatusEnum,
} from './enums.js';
import { users } from './identity.js';
import { lessons, subjects, units } from './structure.js';
import { teacherTracks } from './teachers.js';

/*
 * Attempts, mistakes, statistics, bookmarks and progress (spec §15.4, §16–§18). Grading writes the
 * answer, the mistake bank, `user_subject_stats`, `question_stats` and `user_progress` in one
 * transaction.
 */

/** Filters a random or mistakes attempt was built from (§15.3), kept for "أعد الاختبار". */
export type AttemptFilters = {
  subjectId?: string | null;
  teacherTrackId?: string | null;
  unitId?: string | null;
  lessonId?: string | null;
  types?: ('mcq' | 'true_false' | 'written')[];
  count?: number;
  questionIds?: string[];
};

export const quizAttempts = pgTable(
  'quiz_attempts',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    /** Client-generated idempotency key: starting the same attempt twice returns the first. */
    clientAttemptId: uuid('client_attempt_id').notNull(),
    userId: uuid('user_id')
      .notNull()
      .references(() => users.id, { onDelete: 'cascade' }),
    quizId: uuid('quiz_id').references(() => quizzes.id),
    /** The quiz version the attempt was built from. */
    quizContentVersion: integer('quiz_content_version'),
    source: attemptSourceEnum('source').notNull(),
    mode: attemptModeEnum('mode').notNull(),
    titleAr: text('title_ar').notNull(),
    /** The subject a curated or random attempt belongs to; null for cross-subject mistake reviews. */
    subjectId: uuid('subject_id').references(() => subjects.id),
    teacherTrackId: uuid('teacher_track_id').references(() => teacherTracks.id),
    filters: jsonb('filters').$type<AttemptFilters>(),
    questionOrder: jsonb('question_order').$type<string[]>().notNull(),
    /** Option display order per question (shuffled once, at start). */
    optionOrders: jsonb('option_orders').$type<Record<string, string[]>>().notNull(),
    status: attemptStatusEnum('status').notNull().default('in_progress'),
    startedAt: timestamp('started_at', { withTimezone: true }).notNull().defaultNow(),
    /** Server-authoritative end of a timed exam (§15.2). */
    deadlineAt: timestamp('deadline_at', { withTimezone: true }),
    submittedAt: timestamp('submitted_at', { withTimezone: true }),
    submittedLate: boolean('submitted_late').notNull().default(false),
    scorePercent: integer('score_percent'),
    correctCount: integer('correct_count'),
    totalCount: integer('total_count').notNull(),
    timeSpentMs: integer('time_spent_ms'),
    /** Attempts without activity for 7 days become `abandoned` (§15.5). */
    lastActivityAt: timestamp('last_activity_at', { withTimezone: true }).notNull().defaultNow(),
  },
  (t) => [
    unique('quiz_attempts_client_uq').on(t.userId, t.clientAttemptId),
    index('quiz_attempts_user_started_idx').on(t.userId, t.startedAt),
    index('quiz_attempts_user_status_idx').on(t.userId, t.status),
    index('quiz_attempts_quiz_idx').on(t.quizId),
    index('quiz_attempts_activity_idx').on(t.status, t.lastActivityAt),
  ],
);

export const quizAttemptAnswers = pgTable(
  'quiz_attempt_answers',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    attemptId: uuid('attempt_id')
      .notNull()
      .references(() => quizAttempts.id, { onDelete: 'cascade' }),
    questionId: uuid('question_id')
      .notNull()
      .references(() => questions.id),
    /** Copied from the attempt so trends read one index (§16.2). */
    userId: uuid('user_id')
      .notNull()
      .references(() => users.id, { onDelete: 'cascade' }),
    /** No foreign key: options removed later stay readable through the snapshot. */
    selectedOptionId: uuid('selected_option_id'),
    writtenAnswer: text('written_answer'),
    isCorrect: boolean('is_correct'),
    gradedAt: timestamp('graded_at', { withTimezone: true }),
    flagged: boolean('flagged').notNull().default(false),
    answeredAt: timestamp('answered_at', { withTimezone: true }),
    timeSpentMs: integer('time_spent_ms'),
    /** What the student was graded against (§14.6). */
    questionSnapshot: jsonb('question_snapshot').$type<Record<string, unknown>>(),
  },
  (t) => [
    unique('quiz_attempt_answers_uq').on(t.attemptId, t.questionId),
    index('quiz_attempt_answers_question_idx').on(t.questionId),
    index('quiz_attempt_answers_user_graded_idx').on(t.userId, t.gradedAt),
  ],
);

export const userMistakes = pgTable(
  'user_mistakes',
  {
    userId: uuid('user_id')
      .notNull()
      .references(() => users.id, { onDelete: 'cascade' }),
    questionId: uuid('question_id')
      .notNull()
      .references(() => questions.id),
    firstWrongAt: timestamp('first_wrong_at', { withTimezone: true }).notNull(),
    lastWrongAt: timestamp('last_wrong_at', { withTimezone: true }).notNull(),
    wrongCount: integer('wrong_count').notNull().default(1),
    correctStreak: integer('correct_streak').notNull().default(0),
    status: mistakeStatusEnum('status').notNull().default('active'),
    updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
  },
  (t) => [
    primaryKey({ name: 'user_mistakes_pk', columns: [t.userId, t.questionId] }),
    index('user_mistakes_user_status_idx').on(t.userId, t.status),
  ],
);

/** Running totals per subject scope, updated in the grading transaction (§16.2). */
export const userSubjectStats = pgTable(
  'user_subject_stats',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    userId: uuid('user_id')
      .notNull()
      .references(() => users.id, { onDelete: 'cascade' }),
    subjectId: uuid('subject_id')
      .notNull()
      .references(() => subjects.id),
    teacherTrackId: uuid('teacher_track_id').references(() => teacherTracks.id),
    answered: integer('answered').notNull().default(0),
    correct: integer('correct').notNull().default(0),
    /** Sum of answer times; bigint so heavy use never overflows. */
    timeMs: bigint('time_ms', { mode: 'number' }).notNull().default(0),
    updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
  },
  (t) => [unique('user_subject_stats_uq').on(t.userId, t.subjectId, t.teacherTrackId).nullsNotDistinct()],
);

/** Question-level aggregate for admin analytics (§26, §28.1). */
export const questionStats = pgTable('question_stats', {
  questionId: uuid('question_id')
    .primaryKey()
    .references(() => questions.id, { onDelete: 'cascade' }),
  attemptCount: integer('attempt_count').notNull().default(0),
  correctCount: integer('correct_count').notNull().default(0),
  totalTimeMs: bigint('total_time_ms', { mode: 'number' }).notNull().default(0),
  /** Times each option was chosen, by option id. */
  optionDistribution: jsonb('option_distribution').$type<Record<string, number>>().notNull().default({}),
  flaggedForReview: boolean('flagged_for_review').notNull().default(false),
  lastAttemptAt: timestamp('last_attempt_at', { withTimezone: true }),
  updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
});

export const bookmarks = pgTable(
  'bookmarks',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    userId: uuid('user_id')
      .notNull()
      .references(() => users.id, { onDelete: 'cascade' }),
    itemType: bookmarkItemTypeEnum('item_type').notNull(),
    itemId: uuid('item_id').notNull(),
    createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  },
  (t) => [
    unique('bookmarks_uq').on(t.userId, t.itemType, t.itemId),
    index('bookmarks_user_created_idx').on(t.userId, t.createdAt),
  ],
);

/**
 * Resume pointers, one per subject scope (§18, §28.1). Completion percentages are derived from
 * answers and reviews against the current accessible content, not stored.
 */
export const userProgress = pgTable(
  'user_progress',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    userId: uuid('user_id')
      .notNull()
      .references(() => users.id, { onDelete: 'cascade' }),
    subjectId: uuid('subject_id')
      .notNull()
      .references(() => subjects.id),
    teacherTrackId: uuid('teacher_track_id').references(() => teacherTracks.id),
    unitId: uuid('unit_id').references(() => units.id, { onDelete: 'set null' }),
    lessonId: uuid('lesson_id').references(() => lessons.id, { onDelete: 'set null' }),
    lastActivityType: activityTypeEnum('last_activity_type').notNull(),
    lastItemId: uuid('last_item_id'),
    lastActivityAt: timestamp('last_activity_at', { withTimezone: true }).notNull(),
    updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
  },
  (t) => [
    unique('user_progress_scope_uq').on(t.userId, t.subjectId, t.teacherTrackId).nullsNotDistinct(),
    index('user_progress_user_activity_idx').on(t.userId, t.lastActivityAt),
  ],
);
