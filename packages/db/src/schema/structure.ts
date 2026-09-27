import { integer, pgTable, text, timestamp, uuid } from 'drizzle-orm/pg-core';

/** Minimal in Phase 1 (registration needs a level); Phase 2 adds the college hierarchy and subjects. */
export const educationLevels = pgTable('education_levels', {
  id: uuid('id').primaryKey().defaultRandom(),
  code: text('code').notNull().unique(),
  nameAr: text('name_ar').notNull(),
  sortOrder: integer('sort_order').notNull().default(0),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
});
