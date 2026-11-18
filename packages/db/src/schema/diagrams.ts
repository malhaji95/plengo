import { sql } from 'drizzle-orm';
import {
  boolean,
  check,
  doublePrecision,
  foreignKey,
  index,
  integer,
  pgTable,
  text,
  timestamp,
  uniqueIndex,
  uuid,
} from 'drizzle-orm/pg-core';
import { contentStatusEnum, freeSourceEnum } from './enums.js';
import { users } from './identity.js';
import { mediaFiles } from './media.js';
import { lessons, subjects, units } from './structure.js';
import { teacherTracks } from './teachers.js';

/*
 * «رسمات العلوم» (v3 §9): an image with numbered parts the student names. Placement, access scope,
 * free flags and status follow questions (spec §8, §14): a subject, optionally one of its tracks, and
 * optionally a unit/lesson of that subject, kept consistent by composite keys.
 */
export const diagrams = pgTable(
  'diagrams',
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
    /** A processed private image (uploaded with the `flashcard` media kind); served by signed URL. */
    imageMediaId: uuid('image_media_id')
      .notNull()
      .references(() => mediaFiles.id),
    isFree: boolean('is_free').notNull().default(false),
    freeSource: freeSourceEnum('free_source').notNull().default('rule'),
    status: contentStatusEnum('status').notNull().default('draft'),
    sortOrder: integer('sort_order').notNull().default(0),
    /** Bumped by edits of the title, image or labels. */
    contentVersion: integer('content_version').notNull().default(1),
    createdByAdminId: uuid('created_by_admin_id').references(() => users.id, { onDelete: 'set null' }),
    updatedByAdminId: uuid('updated_by_admin_id').references(() => users.id, { onDelete: 'set null' }),
    createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
    updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
    deletedAt: timestamp('deleted_at', { withTimezone: true }),
  },
  (t) => [
    foreignKey({
      name: 'diagrams_track_subject_fk',
      columns: [t.teacherTrackId, t.subjectId],
      foreignColumns: [teacherTracks.id, teacherTracks.subjectId],
    }),
    foreignKey({
      name: 'diagrams_unit_subject_fk',
      columns: [t.unitId, t.subjectId],
      foreignColumns: [units.id, units.subjectId],
    }),
    foreignKey({
      name: 'diagrams_lesson_subject_fk',
      columns: [t.lessonId, t.subjectId],
      foreignColumns: [lessons.id, lessons.subjectId],
    }),
    check('diagrams_version_ck', sql`${t.contentVersion} >= 1`),
    index('diagrams_scope_status_sort_idx').on(t.subjectId, t.teacherTrackId, t.status, t.sortOrder),
    index('diagrams_unit_idx').on(t.unitId),
    index('diagrams_lesson_idx').on(t.lessonId),
  ],
);

/**
 * A numbered part of a diagram. `x`/`y` (0..1 of the image's width/height) place a marker when the
 * image itself has no numbers. `answers` are the accepted names as the admin wrote them; checks
 * compare normalised forms (the written-answer normaliser, §14.5).
 */
export const diagramLabels = pgTable(
  'diagram_labels',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    diagramId: uuid('diagram_id')
      .notNull()
      .references(() => diagrams.id, { onDelete: 'cascade' }),
    number: integer('number').notNull(),
    x: doublePrecision('x'),
    y: doublePrecision('y'),
    answers: text('answers').array().notNull(),
    sortOrder: integer('sort_order').notNull().default(0),
  },
  (t) => [
    uniqueIndex('diagram_labels_number_uq').on(t.diagramId, t.number),
    index('diagram_labels_diagram_sort_idx').on(t.diagramId, t.sortOrder),
    check('diagram_labels_number_ck', sql`${t.number} >= 1`),
    check('diagram_labels_x_ck', sql`${t.x} is null or (${t.x} >= 0 and ${t.x} <= 1)`),
    check('diagram_labels_y_ck', sql`${t.y} is null or (${t.y} >= 0 and ${t.y} <= 1)`),
    check('diagram_labels_answers_ck', sql`cardinality(${t.answers}) >= 1`),
  ],
);
