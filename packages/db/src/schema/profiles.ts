import { integer, pgTable, text, timestamp, uuid } from 'drizzle-orm/pg-core';
import { users } from './identity.js';
import { educationLevels } from './structure.js';
import { mediaFiles } from './media.js';

/** spec §28.1. university/faculty/academic_year FKs are added with those tables in Phase 2. */
export const profiles = pgTable('profiles', {
  userId: uuid('user_id')
    .primaryKey()
    .references(() => users.id, { onDelete: 'cascade' }),
  fullName: text('full_name').notNull(),
  educationLevelId: uuid('education_level_id').references(() => educationLevels.id),
  universityId: uuid('university_id'),
  facultyId: uuid('faculty_id'),
  academicYearId: uuid('academic_year_id'),
  avatarMediaId: uuid('avatar_media_id').references(() => mediaFiles.id, { onDelete: 'set null' }),
  dailyGoal: integer('daily_goal').notNull().default(20),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
});
