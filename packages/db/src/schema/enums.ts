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
  'avatar',
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

/* Content (spec §14, §15). */
export const questionTypeEnum = pgEnum('question_type', ['mcq', 'true_false', 'written']);
export const contentStatusEnum = pgEnum('content_status', ['draft', 'published', 'archived']);
export const difficultyEnum = pgEnum('difficulty', ['easy', 'medium', 'hard']);

/* Spaced repetition (spec §13.4, §13.7). */
export const srsStateEnum = pgEnum('srs_state', ['new', 'learning', 'review', 'relearning']);
export const srsRatingEnum = pgEnum('srs_rating', ['again', 'good', 'easy']);

/* Quizzes and attempts (spec §15). */
export const quizModesEnum = pgEnum('quiz_modes', ['practice', 'exam', 'both']);
export const attemptModeEnum = pgEnum('attempt_mode', ['practice', 'exam']);
export const attemptSourceEnum = pgEnum('attempt_source', ['curated', 'random', 'mistakes']);
export const attemptStatusEnum = pgEnum('attempt_status', ['in_progress', 'submitted', 'abandoned']);

/* Mistake bank, bookmarks, progress (spec §16–§18). */
export const mistakeStatusEnum = pgEnum('mistake_status', ['active', 'mastered', 'removed']);
export const bookmarkItemTypeEnum = pgEnum('bookmark_item_type', [
  'question',
  'flashcard',
  'user_card',
  'deck',
]);
export const activityTypeEnum = pgEnum('activity_type', ['question', 'quiz', 'deck']);

/* Student decks and content reports (spec §13.9, §21). */
export const userCardKindEnum = pgEnum('user_card_kind', ['custom', 'official_ref']);
export const reportItemTypeEnum = pgEnum('report_item_type', ['question', 'flashcard']);
export const reportReasonEnum = pgEnum('report_reason', [
  'wrong_answer',
  'typo',
  'unclear',
  'image_problem',
  'other',
]);
export const reportStatusEnum = pgEnum('report_status', ['open', 'resolved', 'dismissed']);
