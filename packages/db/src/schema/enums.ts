import { pgEnum } from 'drizzle-orm/pg-core';

export const userRoleEnum = pgEnum('user_role', ['student', 'admin']);
export const userStatusEnum = pgEnum('user_status', ['active', 'disabled']);
export const sessionPlatformEnum = pgEnum('session_platform', ['android', 'ios', 'web', 'admin']);
export const mediaKindEnum = pgEnum('media_kind', [
  'flashcard',
  'banner',
  'teacher',
  'cover',
  'user-card',
  'import',
  'original',
]);
export const mediaBucketEnum = pgEnum('media_bucket', ['public', 'private']);
export const mediaStatusEnum = pgEnum('media_status', ['pending', 'ready', 'failed']);

/* Access (spec §8, §9). */
export const scopeTypeEnum = pgEnum('scope_type', ['subject', 'teacher_track']);
export const entitlementSourceEnum = pgEnum('entitlement_source', [
  'coupon',
  'admin_grant',
  'promotion',
  'future_purchase',
]);
export const entitlementStatusEnum = pgEnum('entitlement_status', [
  'active',
  'revoked',
  'expired',
  'superseded',
]);
export const freeContentKindEnum = pgEnum('free_content_kind', [
  'questions',
  'flashcard_decks',
  'quizzes',
  'all',
]);
export const freeRuleTypeEnum = pgEnum('free_rule_type', [
  'manual',
  'first_n_items',
  'first_n_lessons',
  'first_unit',
  'percentage',
]);
/** Stored on each content item from Phase 5 on (spec §8.4). */
export const freeSourceEnum = pgEnum('free_source', ['rule', 'manual_override']);
export const couponBatchStatusEnum = pgEnum('coupon_batch_status', ['active', 'revoked']);
export const couponStatusEnum = pgEnum('coupon_status', ['active', 'redeemed', 'revoked']);
