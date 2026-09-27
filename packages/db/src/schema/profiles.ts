import { integer, pgTable, text, timestamp, uuid } from 'drizzle-orm/pg-core';
import { users } from './identity.js';
import { academicYears, educationLevels, faculties, universities } from './structure.js';
import { mediaFiles } from './media.js';

/** spec §28.1. The profile level only sets defaults; students browse all levels (§8.9). */
export const profiles = pgTable('profiles', {
  userId: uuid('user_id')
    .primaryKey()
    .references(() => users.id, { onDelete: 'cascade' }),
  fullName: text('full_name').notNull(),
  educationLevelId: uuid('education_level_id').references(() => educationLevels.id),
  universityId: uuid('university_id').references(() => universities.id, { onDelete: 'set null' }),
  facultyId: uuid('faculty_id').references(() => faculties.id, { onDelete: 'set null' }),
  academicYearId: uuid('academic_year_id').references(() => academicYears.id, { onDelete: 'set null' }),
  avatarMediaId: uuid('avatar_media_id').references(() => mediaFiles.id, { onDelete: 'set null' }),
  dailyGoal: integer('daily_goal').notNull().default(20),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
});
