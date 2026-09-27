import { sql } from 'drizzle-orm';
import {
  boolean,
  check,
  index,
  integer,
  pgTable,
  text,
  timestamp,
  unique,
  uniqueIndex,
  uuid,
} from 'drizzle-orm/pg-core';
import {
  couponBatchStatusEnum,
  couponStatusEnum,
  entitlementSourceEnum,
  entitlementStatusEnum,
  freeContentKindEnum,
  freeRuleTypeEnum,
  scopeTypeEnum,
} from './enums.js';
import { sessions, users } from './identity.js';
import { subjects } from './structure.js';
import { teacherTracks } from './teachers.js';

/*
 * Access model (spec §8, §9). Two scopes only: a subject's general content or one teacher track. Every
 * scoped table carries explicit nullable FKs plus the same CHECK; there is no polymorphic scope_id.
 */

const scopeColumns = () => ({
  scopeType: scopeTypeEnum('scope_type').notNull(),
  subjectId: uuid('subject_id').references(() => subjects.id),
  teacherTrackId: uuid('teacher_track_id').references(() => teacherTracks.id),
});

const scopeCheck = (table: string, t: { scopeType: unknown; subjectId: unknown; teacherTrackId: unknown }) =>
  check(
    `${table}_scope_ck`,
    sql`(${t.scopeType} = 'subject' and ${t.subjectId} is not null and ${t.teacherTrackId} is null)
     or (${t.scopeType} = 'teacher_track' and ${t.teacherTrackId} is not null and ${t.subjectId} is null)`,
  );

const createdAt = timestamp('created_at', { withTimezone: true }).notNull().defaultNow();

/** One rule per scope and content kind; a specific kind overrides `all` (spec §8.4). */
export const freeAccessRules = pgTable(
  'free_access_rules',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    ...scopeColumns(),
    contentKind: freeContentKindEnum('content_kind').notNull(),
    ruleType: freeRuleTypeEnum('rule_type').notNull(),
    ruleValue: integer('rule_value'),
    updatedByAdminId: uuid('updated_by_admin_id').references(() => users.id, { onDelete: 'set null' }),
    updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
  },
  (t) => [
    scopeCheck('free_access_rules', t),
    check(
      'free_access_rules_value_ck',
      sql`case ${t.ruleType}
        when 'first_n_items' then ${t.ruleValue} >= 1
        when 'first_n_lessons' then ${t.ruleValue} >= 1
        when 'percentage' then ${t.ruleValue} between 1 and 100
        else ${t.ruleValue} is null end`,
    ),
    uniqueIndex('free_access_rules_subject_kind_uq')
      .on(t.subjectId, t.contentKind)
      .where(sql`scope_type = 'subject'`),
    uniqueIndex('free_access_rules_track_kind_uq')
      .on(t.teacherTrackId, t.contentKind)
      .where(sql`scope_type = 'teacher_track'`),
  ],
);

/** Temporary free access to a whole scope; creates no entitlement rows (spec §8.5). */
export const promotions = pgTable(
  'promotions',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    ...scopeColumns(),
    titleAr: text('title_ar').notNull(),
    startsAt: timestamp('starts_at', { withTimezone: true }).notNull(),
    endsAt: timestamp('ends_at', { withTimezone: true }).notNull(),
    isActive: boolean('is_active').notNull().default(true),
    createdByAdminId: uuid('created_by_admin_id').references(() => users.id, { onDelete: 'set null' }),
    createdAt,
  },
  (t) => [
    scopeCheck('promotions', t),
    check('promotions_window_ck', sql`${t.endsAt} > ${t.startsAt}`),
    index('promotions_subject_idx').on(t.subjectId),
    index('promotions_track_idx').on(t.teacherTrackId),
  ],
);

export const couponBatches = pgTable(
  'coupon_batches',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    name: text('name').notNull(),
    distributorName: text('distributor_name'),
    notes: text('notes'),
    ...scopeColumns(),
    quantity: integer('quantity').notNull(),
    /** Codes created so far by the generation job; progress is generated_count / quantity. */
    generatedCount: integer('generated_count').notNull().default(0),
    validFrom: timestamp('valid_from', { withTimezone: true }),
    expiresAt: timestamp('expires_at', { withTimezone: true }),
    accessDurationDays: integer('access_duration_days'),
    accessExpiresAt: timestamp('access_expires_at', { withTimezone: true }),
    permanentAccess: boolean('permanent_access').notNull().default(false),
    status: couponBatchStatusEnum('status').notNull().default('active'),
    createdByAdminId: uuid('created_by_admin_id').references(() => users.id, { onDelete: 'set null' }),
    createdAt,
    revokedAt: timestamp('revoked_at', { withTimezone: true }),
    revokedByAdminId: uuid('revoked_by_admin_id').references(() => users.id, { onDelete: 'set null' }),
  },
  (t) => [
    scopeCheck('coupon_batches', t),
    check('coupon_batches_quantity_ck', sql`${t.quantity} between 1 and 5000`),
    check(
      'coupon_batches_access_ck',
      sql`(case when ${t.permanentAccess} then 1 else 0 end
        + case when ${t.accessDurationDays} is not null then 1 else 0 end
        + case when ${t.accessExpiresAt} is not null then 1 else 0 end) = 1`,
    ),
  ],
);

/** Access terms are copied from the batch so a code is self-describing (spec §9.1). */
export const coupons = pgTable(
  'coupons',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    batchId: uuid('batch_id')
      .notNull()
      .references(() => couponBatches.id),
    codeHash: text('code_hash').notNull().unique('coupons_code_hash_uq'),
    codeEncrypted: text('code_encrypted').notNull(),
    codeLast4: text('code_last4').notNull(),
    ...scopeColumns(),
    validFrom: timestamp('valid_from', { withTimezone: true }),
    expiresAt: timestamp('expires_at', { withTimezone: true }),
    accessDurationDays: integer('access_duration_days'),
    accessExpiresAt: timestamp('access_expires_at', { withTimezone: true }),
    permanentAccess: boolean('permanent_access').notNull().default(false),
    maxUses: integer('max_uses').notNull().default(1),
    currentUses: integer('current_uses').notNull().default(0),
    status: couponStatusEnum('status').notNull().default('active'),
    createdByAdminId: uuid('created_by_admin_id').references(() => users.id, { onDelete: 'set null' }),
    createdAt,
  },
  (t) => [
    scopeCheck('coupons', t),
    check('coupons_uses_ck', sql`${t.currentUses} between 0 and ${t.maxUses}`),
    index('coupons_batch_idx').on(t.batchId),
    index('coupons_last4_idx').on(t.codeLast4),
  ],
);

export const entitlements = pgTable(
  'entitlements',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    userId: uuid('user_id')
      .notNull()
      .references(() => users.id),
    ...scopeColumns(),
    source: entitlementSourceEnum('source').notNull(),
    couponId: uuid('coupon_id').references(() => coupons.id),
    grantedByAdminId: uuid('granted_by_admin_id').references(() => users.id, { onDelete: 'set null' }),
    startsAt: timestamp('starts_at', { withTimezone: true }).notNull().defaultNow(),
    expiresAt: timestamp('expires_at', { withTimezone: true }),
    isPermanent: boolean('is_permanent').notNull().default(false),
    status: entitlementStatusEnum('status').notNull().default('active'),
    revokedAt: timestamp('revoked_at', { withTimezone: true }),
    revokedByAdminId: uuid('revoked_by_admin_id').references(() => users.id, { onDelete: 'set null' }),
    revokeReason: text('revoke_reason'),
    createdAt,
    updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
  },
  (t) => [
    scopeCheck('entitlements', t),
    check(
      'entitlements_term_ck',
      sql`(${t.isPermanent} and ${t.expiresAt} is null) or (not ${t.isPermanent} and ${t.expiresAt} is not null)`,
    ),
    // spec §8.3: the final concurrency guard. Time cannot appear in the predicate, so every grant path
    // first expires stale rows for the same user + scope inside its transaction.
    uniqueIndex('entitlements_one_active_subject')
      .on(t.userId, t.subjectId)
      .where(sql`status = 'active' and scope_type = 'subject'`),
    uniqueIndex('entitlements_one_active_track')
      .on(t.userId, t.teacherTrackId)
      .where(sql`status = 'active' and scope_type = 'teacher_track'`),
    index('entitlements_user_scope_idx').on(t.userId, t.scopeType, t.subjectId, t.teacherTrackId, t.status),
    index('entitlements_expires_idx').on(t.expiresAt),
  ],
);

export const couponRedemptions = pgTable(
  'coupon_redemptions',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    couponId: uuid('coupon_id')
      .notNull()
      .references(() => coupons.id),
    /** Nulled on account deletion so the code stays consumed (spec §33). */
    userId: uuid('user_id').references(() => users.id, { onDelete: 'set null' }),
    redeemedAt: timestamp('redeemed_at', { withTimezone: true }).notNull().defaultNow(),
    sessionId: uuid('session_id').references(() => sessions.id, { onDelete: 'set null' }),
    entitlementId: uuid('entitlement_id')
      .notNull()
      .references(() => entitlements.id),
    /** Hashed client IP; counts successful attempts toward the per-IP limit (spec §9.5). */
    ipHash: text('ip_hash'),
  },
  (t) => [
    unique('coupon_redemptions_coupon_user_uq').on(t.couponId, t.userId),
    index('coupon_redemptions_user_idx').on(t.userId, t.redeemedAt),
    index('coupon_redemptions_ip_idx').on(t.ipHash, t.redeemedAt),
  ],
);

export const couponRedemptionFailures = pgTable(
  'coupon_redemption_failures',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    userId: uuid('user_id').references(() => users.id, { onDelete: 'set null' }),
    ipHash: text('ip_hash'),
    codeLast4: text('code_last4'),
    reason: text('reason').notNull(),
    createdAt,
  },
  (t) => [
    index('coupon_redemption_failures_user_idx').on(t.userId, t.createdAt),
    index('coupon_redemption_failures_ip_idx').on(t.ipHash, t.createdAt),
  ],
);
