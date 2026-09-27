import { sql } from 'drizzle-orm';
import {
  boolean,
  check,
  foreignKey,
  index,
  integer,
  pgTable,
  text,
  timestamp,
  uniqueIndex,
  uuid,
} from 'drizzle-orm/pg-core';
import { contentStatusEnum, difficultyEnum, freeSourceEnum, questionTypeEnum } from './enums.js';
import { users } from './identity.js';
import { mediaFiles } from './media.js';
import { lessons, subjects, units } from './structure.js';
import { teacherTracks } from './teachers.js';

/*
 * Questions (spec §14). A question belongs to a subject and optionally to one teacher track, unit and
 * lesson; composite keys keep all of them inside the same subject (§6.1, §7.3). Its access scope is
 * the track when set, otherwise the subject's general content (§8.1).
 */

export const questions = pgTable(
  'questions',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    type: questionTypeEnum('type').notNull(),
    subjectId: uuid('subject_id')
      .notNull()
      .references(() => subjects.id),
    teacherTrackId: uuid('teacher_track_id'),
    unitId: uuid('unit_id'),
    lessonId: uuid('lesson_id'),
    questionText: text('question_text').notNull(),
    explanation: text('explanation'),
    difficulty: difficultyEnum('difficulty'),
    /** Materialized free flag (§8.4): set from the scope's rule on publish unless overridden. */
    isFree: boolean('is_free').notNull().default(false),
    freeSource: freeSourceEnum('free_source').notNull().default('rule'),
    status: contentStatusEnum('status').notNull().default('draft'),
    sortOrder: integer('sort_order').notNull().default(0),
    /** Bumped by every edit of the text, options, accepted answers or explanation (§22.3). */
    contentVersion: integer('content_version').notNull().default(1),
    createdByAdminId: uuid('created_by_admin_id').references(() => users.id, { onDelete: 'set null' }),
    updatedByAdminId: uuid('updated_by_admin_id').references(() => users.id, { onDelete: 'set null' }),
    createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
    updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
    deletedAt: timestamp('deleted_at', { withTimezone: true }),
  },
  (t) => [
    foreignKey({
      name: 'questions_track_subject_fk',
      columns: [t.teacherTrackId, t.subjectId],
      foreignColumns: [teacherTracks.id, teacherTracks.subjectId],
    }),
    foreignKey({
      name: 'questions_unit_subject_fk',
      columns: [t.unitId, t.subjectId],
      foreignColumns: [units.id, units.subjectId],
    }),
    foreignKey({
      name: 'questions_lesson_subject_fk',
      columns: [t.lessonId, t.subjectId],
      foreignColumns: [lessons.id, lessons.subjectId],
    }),
    check('questions_version_ck', sql`${t.contentVersion} >= 1`),
    index('questions_scope_status_sort_idx').on(t.subjectId, t.teacherTrackId, t.status, t.sortOrder),
    index('questions_unit_idx').on(t.unitId),
    index('questions_lesson_idx').on(t.lessonId),
  ],
);

/** MCQ options; true/false questions use two fixed options (صح / خطأ). Exactly one is correct. */
export const questionOptions = pgTable(
  'question_options',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    questionId: uuid('question_id')
      .notNull()
      .references(() => questions.id, { onDelete: 'cascade' }),
    text: text('text').notNull(),
    isCorrect: boolean('is_correct').notNull().default(false),
    sortOrder: integer('sort_order').notNull().default(0),
  },
  (t) => [
    index('question_options_question_sort_idx').on(t.questionId, t.sortOrder),
    uniqueIndex('question_options_one_correct')
      .on(t.questionId)
      .where(sql`is_correct`),
  ],
);

/** Accepted answers of written questions, stored with their normalized form and its version (§14.5). */
export const questionAnswers = pgTable(
  'question_answers',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    questionId: uuid('question_id')
      .notNull()
      .references(() => questions.id, { onDelete: 'cascade' }),
    answerOriginal: text('answer_original').notNull(),
    answerNormalized: text('answer_normalized').notNull(),
    normalizationVersion: integer('normalization_version').notNull(),
    isActive: boolean('is_active').notNull().default(true),
    createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  },
  (t) => [
    index('question_answers_question_idx').on(t.questionId),
    uniqueIndex('question_answers_active_uq')
      .on(t.questionId, t.answerNormalized)
      .where(sql`is_active`),
  ],
);

/** Official flashcard decks (spec §13.1). Placement and scope rules match questions. */
export const flashcardDecks = pgTable(
  'flashcard_decks',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    subjectId: uuid('subject_id')
      .notNull()
      .references(() => subjects.id),
    teacherTrackId: uuid('teacher_track_id'),
    unitId: uuid('unit_id'),
    lessonId: uuid('lesson_id'),
    titleAr: text('title_ar').notNull(),
    description: text('description'),
    coverMediaId: uuid('cover_media_id').references(() => mediaFiles.id, { onDelete: 'set null' }),
    isFree: boolean('is_free').notNull().default(false),
    freeSource: freeSourceEnum('free_source').notNull().default('rule'),
    status: contentStatusEnum('status').notNull().default('draft'),
    sortOrder: integer('sort_order').notNull().default(0),
    /** Bumped by deck metadata, membership and card order changes (§22.3). */
    contentVersion: integer('content_version').notNull().default(1),
    createdByAdminId: uuid('created_by_admin_id').references(() => users.id, { onDelete: 'set null' }),
    updatedByAdminId: uuid('updated_by_admin_id').references(() => users.id, { onDelete: 'set null' }),
    createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
    updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
    deletedAt: timestamp('deleted_at', { withTimezone: true }),
  },
  (t) => [
    foreignKey({
      name: 'flashcard_decks_track_subject_fk',
      columns: [t.teacherTrackId, t.subjectId],
      foreignColumns: [teacherTracks.id, teacherTracks.subjectId],
    }),
    foreignKey({
      name: 'flashcard_decks_unit_subject_fk',
      columns: [t.unitId, t.subjectId],
      foreignColumns: [units.id, units.subjectId],
    }),
    foreignKey({
      name: 'flashcard_decks_lesson_subject_fk',
      columns: [t.lessonId, t.subjectId],
      foreignColumns: [lessons.id, lessons.subjectId],
    }),
    index('flashcard_decks_scope_idx').on(t.subjectId, t.teacherTrackId, t.status, t.sortOrder),
    index('flashcard_decks_unit_idx').on(t.unitId),
    index('flashcard_decks_lesson_idx').on(t.lessonId),
  ],
);

/** Official cards: a front image and a back image (§13.1). */
export const flashcards = pgTable(
  'flashcards',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    deckId: uuid('deck_id')
      .notNull()
      .references(() => flashcardDecks.id),
    frontMediaId: uuid('front_media_id')
      .notNull()
      .references(() => mediaFiles.id),
    backMediaId: uuid('back_media_id')
      .notNull()
      .references(() => mediaFiles.id),
    sortOrder: integer('sort_order').notNull().default(0),
    status: contentStatusEnum('status').notNull().default('published'),
    /** Bumped when the card's images, order or status change (§22.3). */
    contentVersion: integer('content_version').notNull().default(1),
    createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
    updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
    deletedAt: timestamp('deleted_at', { withTimezone: true }),
  },
  (t) => [index('flashcards_deck_sort_idx').on(t.deckId, t.sortOrder)],
);
