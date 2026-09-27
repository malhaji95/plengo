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
  unique,
  uniqueIndex,
  uuid,
} from 'drizzle-orm/pg-core';
import { mediaFiles } from './media.js';

/*
 * Education structure (spec §6): Level → [College: University → Faculty → Academic Year] → Subject
 * → Unit? → Lesson?. The college layers, units and lessons are all optional. `code` values are the
 * stable references used by bulk import (§27); they are unique among live (not soft-deleted) rows.
 */

const timestamps = {
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
};
const deletedAt = timestamp('deleted_at', { withTimezone: true });
const live = sql`deleted_at is null`;

/** The three fixed levels (spec §1). Seeded by migration; admins may rename and reorder. */
export const educationLevels = pgTable('education_levels', {
  id: uuid('id').primaryKey().defaultRandom(),
  code: text('code').notNull().unique(),
  nameAr: text('name_ar').notNull(),
  sortOrder: integer('sort_order').notNull().default(0),
  ...timestamps,
});

export const universities = pgTable(
  'universities',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    code: text('code').notNull(),
    nameAr: text('name_ar').notNull(),
    sortOrder: integer('sort_order').notNull().default(0),
    isActive: boolean('is_active').notNull().default(true),
    ...timestamps,
    deletedAt,
  },
  (t) => [uniqueIndex('universities_code_live_idx').on(t.code).where(live)],
);

export const faculties = pgTable(
  'faculties',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    universityId: uuid('university_id')
      .notNull()
      .references(() => universities.id),
    code: text('code').notNull(),
    nameAr: text('name_ar').notNull(),
    sortOrder: integer('sort_order').notNull().default(0),
    isActive: boolean('is_active').notNull().default(true),
    ...timestamps,
    deletedAt,
  },
  (t) => [
    unique('faculties_id_university_uq').on(t.id, t.universityId),
    uniqueIndex('faculties_code_live_idx').on(t.universityId, t.code).where(live),
  ],
);

export const academicYears = pgTable(
  'academic_years',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    facultyId: uuid('faculty_id')
      .notNull()
      .references(() => faculties.id),
    code: text('code').notNull(),
    nameAr: text('name_ar').notNull(),
    sortOrder: integer('sort_order').notNull().default(0),
    isActive: boolean('is_active').notNull().default(true),
    ...timestamps,
    deletedAt,
  },
  (t) => [
    unique('academic_years_id_faculty_uq').on(t.id, t.facultyId),
    uniqueIndex('academic_years_code_live_idx').on(t.facultyId, t.code).where(live),
  ],
);

export const subjects = pgTable(
  'subjects',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    educationLevelId: uuid('education_level_id')
      .notNull()
      .references(() => educationLevels.id),
    universityId: uuid('university_id').references(() => universities.id),
    facultyId: uuid('faculty_id'),
    academicYearId: uuid('academic_year_id'),
    code: text('code').notNull(),
    nameAr: text('name_ar').notNull(),
    description: text('description'),
    coverMediaId: uuid('cover_media_id').references(() => mediaFiles.id, { onDelete: 'set null' }),
    sortOrder: integer('sort_order').notNull().default(0),
    isActive: boolean('is_active').notNull().default(true),
    ...timestamps,
    deletedAt,
  },
  (t) => [
    uniqueIndex('subjects_code_live_idx').on(t.code).where(live),
    index('subjects_level_sort_idx').on(t.educationLevelId, t.sortOrder),
    // The college chain must be consistent: a year implies its faculty, a faculty its university.
    foreignKey({
      name: 'subjects_faculty_university_fk',
      columns: [t.facultyId, t.universityId],
      foreignColumns: [faculties.id, faculties.universityId],
    }),
    foreignKey({
      name: 'subjects_year_faculty_fk',
      columns: [t.academicYearId, t.facultyId],
      foreignColumns: [academicYears.id, academicYears.facultyId],
    }),
    check(
      'subjects_college_chain_ck',
      sql`(${t.academicYearId} is null or ${t.facultyId} is not null) and (${t.facultyId} is null or ${t.universityId} is not null)`,
    ),
  ],
);

/** spec §6.1: UNIQUE(id, subject_id) lets lessons and content prove they stay inside one subject. */
export const units = pgTable(
  'units',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    subjectId: uuid('subject_id')
      .notNull()
      .references(() => subjects.id),
    code: text('code').notNull(),
    titleAr: text('title_ar').notNull(),
    sortOrder: integer('sort_order').notNull().default(0),
    ...timestamps,
    deletedAt,
  },
  (t) => [
    unique('units_id_subject_uq').on(t.id, t.subjectId),
    uniqueIndex('units_code_live_idx').on(t.subjectId, t.code).where(live),
    index('units_subject_sort_idx').on(t.subjectId, t.sortOrder),
  ],
);

export const lessons = pgTable(
  'lessons',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    subjectId: uuid('subject_id')
      .notNull()
      .references(() => subjects.id),
    unitId: uuid('unit_id'),
    code: text('code').notNull(),
    titleAr: text('title_ar').notNull(),
    sortOrder: integer('sort_order').notNull().default(0),
    ...timestamps,
    deletedAt,
  },
  (t) => [
    unique('lessons_id_subject_uq').on(t.id, t.subjectId),
    uniqueIndex('lessons_code_live_idx').on(t.subjectId, t.code).where(live),
    index('lessons_subject_sort_idx').on(t.subjectId, t.sortOrder),
    index('lessons_unit_idx').on(t.unitId),
    foreignKey({
      name: 'lessons_unit_subject_fk',
      columns: [t.unitId, t.subjectId],
      foreignColumns: [units.id, units.subjectId],
    }),
  ],
);
