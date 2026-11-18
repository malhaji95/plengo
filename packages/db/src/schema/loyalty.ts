import { sql } from 'drizzle-orm';
import {
  boolean,
  check,
  date,
  index,
  integer,
  pgTable,
  text,
  timestamp,
  uniqueIndex,
  uuid,
} from 'drizzle-orm/pg-core';
import { flashcardDecks } from './content.js';
import { loyaltyReasonEnum, loyaltyRedemptionStatusEnum, loyaltyRewardKindEnum } from './enums.js';
import { users } from './identity.js';

/*
 * Loyalty programme (v3 §10). Points are a ledger: the balance is the sum of a student's deltas.
 * Earned points carry the business day they count toward (the daily cap, same 04:00 Damascus
 * boundary as streaks and the daily goal); `(user, reason, ref_id, day)` is unique so a review log
 * or a question's correct answer earns at most once (per day for questions).
 */
export const loyaltyLedger = pgTable(
  'loyalty_ledger',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    userId: uuid('user_id')
      .notNull()
      .references(() => users.id, { onDelete: 'cascade' }),
    delta: integer('delta').notNull(),
    reason: loyaltyReasonEnum('reason').notNull(),
    /** Review log id, question id, redemption id; null for admin adjustments. */
    refId: text('ref_id'),
    /** Business day (YYYY-MM-DD) the entry counts toward. */
    day: date('day').notNull(),
    note: text('note'),
    adminId: uuid('admin_id').references(() => users.id, { onDelete: 'set null' }),
    createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  },
  (t) => [
    check('loyalty_ledger_delta_ck', sql`${t.delta} <> 0`),
    uniqueIndex('loyalty_ledger_ref_uq')
      .on(t.userId, t.reason, t.refId, t.day)
      .where(sql`ref_id is not null`),
    index('loyalty_ledger_user_day_idx').on(t.userId, t.day),
    index('loyalty_ledger_user_created_idx').on(t.userId, t.createdAt),
  ],
);

/** Rewards students spend points on, managed in the admin. */
export const loyaltyRewards = pgTable(
  'loyalty_rewards',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    titleAr: text('title_ar').notNull(),
    description: text('description'),
    costPoints: integer('cost_points').notNull(),
    kind: loyaltyRewardKindEnum('kind').notNull(),
    /** `unlock_deck`: the official deck the reward opens for the student. */
    deckId: uuid('deck_id').references(() => flashcardDecks.id),
    isActive: boolean('is_active').notNull().default(true),
    sortOrder: integer('sort_order').notNull().default(0),
    createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
    updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
    deletedAt: timestamp('deleted_at', { withTimezone: true }),
  },
  (t) => [
    check('loyalty_rewards_cost_ck', sql`${t.costPoints} > 0`),
    check('loyalty_rewards_deck_ck', sql`(${t.kind} = 'unlock_deck') = (${t.deckId} is not null)`),
  ],
);

/** A student's spending. `custom` rewards wait for the admin (`pending` → `fulfilled`). */
export const loyaltyRedemptions = pgTable(
  'loyalty_redemptions',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    userId: uuid('user_id')
      .notNull()
      .references(() => users.id, { onDelete: 'cascade' }),
    rewardId: uuid('reward_id')
      .notNull()
      .references(() => loyaltyRewards.id),
    /** Copied from the reward at redemption time. */
    titleAr: text('title_ar').notNull(),
    kind: loyaltyRewardKindEnum('kind').notNull(),
    costPoints: integer('cost_points').notNull(),
    deckId: uuid('deck_id').references(() => flashcardDecks.id),
    status: loyaltyRedemptionStatusEnum('status').notNull(),
    handledByAdminId: uuid('handled_by_admin_id').references(() => users.id, { onDelete: 'set null' }),
    handledAt: timestamp('handled_at', { withTimezone: true }),
    note: text('note'),
    createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  },
  (t) => [
    index('loyalty_redemptions_user_idx').on(t.userId, t.createdAt),
    index('loyalty_redemptions_status_idx').on(t.status, t.createdAt),
  ],
);

/**
 * A per-student deck unlock (a loyalty reward): access to that one official deck, honoured by every
 * access check next to entitlements, promotions and free flags (spec §8.6).
 */
export const studentDeckUnlocks = pgTable(
  'student_deck_unlocks',
  {
    userId: uuid('user_id')
      .notNull()
      .references(() => users.id, { onDelete: 'cascade' }),
    deckId: uuid('deck_id')
      .notNull()
      .references(() => flashcardDecks.id),
    redemptionId: uuid('redemption_id').references(() => loyaltyRedemptions.id, { onDelete: 'set null' }),
    createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  },
  (t) => [uniqueIndex('student_deck_unlocks_uq').on(t.userId, t.deckId)],
);
