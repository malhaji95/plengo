import { sql } from 'drizzle-orm';
import {
  boolean,
  date,
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
import {
  bannerActionEnum,
  notificationStatusEnum,
  notificationTargetEnum,
  notificationTypeEnum,
} from './enums.js';
import { users } from './identity.js';
import { mediaFiles } from './media.js';
import { educationLevels } from './structure.js';

/** Home banners (spec §19.2): scheduled, level-targeted, with a click action. */
export const banners = pgTable(
  'banners',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    titleAr: text('title_ar').notNull(),
    imageMediaId: uuid('image_media_id')
      .notNull()
      .references(() => mediaFiles.id),
    action: bannerActionEnum('action').notNull().default('none'),
    /** An id for content actions, a route for `internal_route`, a URL for `external_url`. */
    actionTarget: text('action_target'),
    /** Null: every level. */
    educationLevelId: uuid('education_level_id').references(() => educationLevels.id),
    startsAt: timestamp('starts_at', { withTimezone: true }),
    endsAt: timestamp('ends_at', { withTimezone: true }),
    isActive: boolean('is_active').notNull().default(true),
    sortOrder: integer('sort_order').notNull().default(0),
    createdByAdminId: uuid('created_by_admin_id').references(() => users.id, { onDelete: 'set null' }),
    updatedByAdminId: uuid('updated_by_admin_id').references(() => users.id, { onDelete: 'set null' }),
    createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
    updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
    deletedAt: timestamp('deleted_at', { withTimezone: true }),
  },
  (t) => [index('banners_active_sort_idx').on(t.isActive, t.sortOrder)],
);

/** "باقي 87 يوماً على امتحان الشهادة الثانوية" (§19.3). */
export const examCountdowns = pgTable(
  'exam_countdowns',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    educationLevelId: uuid('education_level_id')
      .notNull()
      .references(() => educationLevels.id),
    titleAr: text('title_ar').notNull(),
    examDate: date('exam_date', { mode: 'string' }).notNull(),
    isActive: boolean('is_active').notNull().default(true),
    createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
    updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
  },
  (t) => [index('exam_countdowns_level_idx').on(t.educationLevelId)],
);

/**
 * Items done per business day (flashcard ratings + graded answers, §19.4). Days start at 04:00
 * Asia/Damascus, the same boundary as SRS due days and daily statistics. `goal` is the student's
 * goal on that day, so changing it never rewrites past days.
 */
export const userDailyActivity = pgTable(
  'user_daily_activity',
  {
    userId: uuid('user_id')
      .notNull()
      .references(() => users.id, { onDelete: 'cascade' }),
    day: date('day', { mode: 'string' }).notNull(),
    itemsDone: integer('items_done').notNull().default(0),
    goal: integer('goal').notNull(),
    goalMet: boolean('goal_met').notNull().default(false),
  },
  (t) => [primaryKey({ columns: [t.userId, t.day] })],
);

/** A notification as composed (§20.1); `user_notifications` is each student's inbox copy. */
export const notifications = pgTable(
  'notifications',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    type: notificationTypeEnum('type').notNull(),
    titleAr: text('title_ar').notNull(),
    bodyAr: text('body_ar').notNull(),
    action: bannerActionEnum('action').notNull().default('none'),
    actionTarget: text('action_target'),
    targetType: notificationTargetEnum('target_type').notNull(),
    target: jsonb('target').$type<Record<string, unknown>>().notNull().default({}),
    status: notificationStatusEnum('status').notNull().default('queued'),
    recipientCount: integer('recipient_count').notNull().default(0),
    pushCount: integer('push_count').notNull().default(0),
    pushFailures: integer('push_failures').notNull().default(0),
    createdByAdminId: uuid('created_by_admin_id').references(() => users.id, { onDelete: 'set null' }),
    createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
    sentAt: timestamp('sent_at', { withTimezone: true }),
  },
  (t) => [index('notifications_created_idx').on(t.createdAt)],
);

export const userNotifications = pgTable(
  'user_notifications',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    notificationId: uuid('notification_id')
      .notNull()
      .references(() => notifications.id, { onDelete: 'cascade' }),
    userId: uuid('user_id')
      .notNull()
      .references(() => users.id, { onDelete: 'cascade' }),
    readAt: timestamp('read_at', { withTimezone: true }),
    createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  },
  (t) => [
    unique('user_notifications_uq').on(t.notificationId, t.userId),
    index('user_notifications_user_created_idx').on(t.userId, t.createdAt),
    index('user_notifications_unread_idx')
      .on(t.userId)
      .where(sql`${t.readAt} is null`),
  ],
);

/** FCM tokens per device (§20.3). */
export const pushTokens = pgTable(
  'push_tokens',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    userId: uuid('user_id')
      .notNull()
      .references(() => users.id, { onDelete: 'cascade' }),
    platform: text('platform').notNull(),
    token: text('token').notNull().unique(),
    appVersion: text('app_version'),
    createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
    lastSeenAt: timestamp('last_seen_at', { withTimezone: true }).notNull().defaultNow(),
    revokedAt: timestamp('revoked_at', { withTimezone: true }),
  },
  (t) => [index('push_tokens_user_idx').on(t.userId)],
);
