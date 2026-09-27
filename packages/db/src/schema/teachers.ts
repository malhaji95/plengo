import { sql } from 'drizzle-orm';
import {
  boolean,
  index,
  integer,
  pgTable,
  text,
  timestamp,
  unique,
  uniqueIndex,
  uuid,
} from 'drizzle-orm/pg-core';
import { users } from './identity.js';
import { mediaFiles } from './media.js';
import { subjects } from './structure.js';

/*
 * Teachers are content entities only: no accounts, logins or dashboards (spec §0.2, §7).
 * Slugs are the stable references used by imports (`teacher_track_code`, §27); unique among live rows.
 */

const live = sql`deleted_at is null`;

export const teachers = pgTable(
  'teachers',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    nameAr: text('name_ar').notNull(),
    slug: text('slug').notNull(),
    photoMediaId: uuid('photo_media_id').references(() => mediaFiles.id, { onDelete: 'set null' }),
    shortDescription: text('short_description'),
    bio: text('bio'),
    isActive: boolean('is_active').notNull().default(true),
    sortOrder: integer('sort_order').notNull().default(0),
    createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
    updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
    deletedAt: timestamp('deleted_at', { withTimezone: true }),
  },
  (t) => [uniqueIndex('teachers_slug_live_idx').on(t.slug).where(live)],
);

/**
 * A teacher's own collection of content within one subject (spec §7.2). UNIQUE(id, subject_id) is the
 * target of the composite foreign keys that content tables add from Phase 5 on (§7.3).
 */
export const teacherTracks = pgTable(
  'teacher_tracks',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    teacherId: uuid('teacher_id')
      .notNull()
      .references(() => teachers.id),
    subjectId: uuid('subject_id')
      .notNull()
      .references(() => subjects.id),
    titleAr: text('title_ar').notNull(),
    slug: text('slug').notNull(),
    description: text('description'),
    coverMediaId: uuid('cover_media_id').references(() => mediaFiles.id, { onDelete: 'set null' }),
    isActive: boolean('is_active').notNull().default(true),
    sortOrder: integer('sort_order').notNull().default(0),
    createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
    updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
    deletedAt: timestamp('deleted_at', { withTimezone: true }),
  },
  (t) => [
    unique('teacher_tracks_id_subject_uq').on(t.id, t.subjectId),
    uniqueIndex('teacher_tracks_slug_live_idx').on(t.slug).where(live),
    index('teacher_tracks_teacher_sort_idx').on(t.teacherId, t.sortOrder),
    index('teacher_tracks_subject_idx').on(t.subjectId),
  ],
);

/** Following enables lists, feed and notifications; it never grants access (spec §7.4). */
export const teacherFollowers = pgTable(
  'teacher_followers',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    teacherId: uuid('teacher_id')
      .notNull()
      .references(() => teachers.id),
    userId: uuid('user_id')
      .notNull()
      .references(() => users.id, { onDelete: 'cascade' }),
    createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  },
  (t) => [
    unique('teacher_followers_teacher_user_uq').on(t.teacherId, t.userId),
    index('teacher_followers_user_idx').on(t.userId),
    index('teacher_followers_teacher_idx').on(t.teacherId),
  ],
);
