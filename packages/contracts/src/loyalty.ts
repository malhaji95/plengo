import { z } from 'zod';

/*
 * Loyalty programme (v3 §10): points for reviewed cards (and, when the admin sets it, correct
 * answers), capped per business day; rewards students spend them on.
 */

const int = () => z.number().int();

/** Admin-editable rules (app_settings `loyalty`). */
export const loyaltySettingsSchema = z.object({
  enabled: z.boolean(),
  /** Points for each official card review synced from the app. */
  pointsPerReview: int().min(0).max(1000),
  /** Most points earned per business day (04:00 Damascus boundary); 0 = no cap. */
  dailyCap: int().min(0).max(100_000),
  /** Points for a correct answer to a question check (once per question per day); 0 = off. */
  pointsPerCorrectQuestion: int().min(0).max(1000),
});

export const loyaltyReasonSchema = z.enum([
  'review',
  'correct_answer',
  'redemption',
  'refund',
  'admin_adjust',
]);
export const loyaltyRewardKindSchema = z.enum(['unlock_deck', 'custom']);
export const loyaltyRedemptionStatusSchema = z.enum(['pending', 'fulfilled', 'cancelled']);

export const loyaltySummarySchema = z.object({
  enabled: z.boolean(),
  balance: int(),
  /** Points earned today (business day) toward the cap. */
  earnedToday: int(),
  dailyCap: int(),
  /** Null when there is no cap. */
  remainingToday: int().nullable(),
  /** The business day `earnedToday` belongs to (YYYY-MM-DD). */
  day: z.string(),
  rules: loyaltySettingsSchema,
});

export const loyaltyLedgerEntrySchema = z.object({
  id: z.string(),
  delta: int(),
  reason: loyaltyReasonSchema,
  refId: z.string().nullable(),
  day: z.string(),
  note: z.string().nullable(),
  createdAt: z.string(),
});
export const loyaltyLedgerPageSchema = z.object({ items: z.array(loyaltyLedgerEntrySchema) });

export const loyaltyRewardSchema = z.object({
  id: z.string(),
  titleAr: z.string(),
  description: z.string().nullable(),
  costPoints: int(),
  kind: loyaltyRewardKindSchema,
  deckId: z.string().nullable(),
  deckTitleAr: z.string().nullable(),
  deckSubjectId: z.string().nullable(),
  /** `unlock_deck` only: the student can already open that deck (unlocked, free or entitled). */
  alreadyOwned: z.boolean(),
  /** The balance covers the cost. */
  affordable: z.boolean(),
  sortOrder: int(),
});
export const loyaltyRewardListSchema = z.object({
  balance: int(),
  items: z.array(loyaltyRewardSchema),
});

export const loyaltyRedemptionSchema = z.object({
  id: z.string(),
  rewardId: z.string(),
  titleAr: z.string(),
  kind: loyaltyRewardKindSchema,
  costPoints: int(),
  deckId: z.string().nullable(),
  /** `unlock_deck` is fulfilled at once; `custom` stays pending until the admin handles it. */
  status: loyaltyRedemptionStatusSchema,
  note: z.string().nullable(),
  createdAt: z.string(),
  handledAt: z.string().nullable(),
});
export const loyaltyRedemptionListSchema = z.array(loyaltyRedemptionSchema);

export const loyaltyRedeemResultSchema = z.object({
  redemption: loyaltyRedemptionSchema,
  balance: int(),
});

// ---- admin ----

export const adminLoyaltyRewardSchema = z.object({
  id: z.string(),
  titleAr: z.string(),
  description: z.string().nullable(),
  costPoints: int(),
  kind: loyaltyRewardKindSchema,
  deckId: z.string().nullable(),
  deckTitleAr: z.string().nullable(),
  isActive: z.boolean(),
  sortOrder: int(),
  redemptionCount: int(),
  createdAt: z.string(),
  updatedAt: z.string(),
});
export const adminLoyaltyRewardListSchema = z.array(adminLoyaltyRewardSchema);

const rewardShape = {
  titleAr: z.string().trim().min(1).max(200),
  description: z.string().trim().max(2000).nullable().optional(),
  costPoints: int().min(1).max(10_000_000),
  kind: loyaltyRewardKindSchema,
  /** Required for `unlock_deck`; must be empty for `custom`. */
  deckId: z.uuid().nullable().optional(),
  isActive: z.boolean().optional(),
  sortOrder: int().min(0).max(100_000).optional(),
};
export const createLoyaltyRewardBodySchema = z.object(rewardShape);
export const updateLoyaltyRewardBodySchema = z.object(rewardShape).partial();

export const adminLoyaltyRedemptionSchema = loyaltyRedemptionSchema.extend({
  userId: z.string(),
  studentEmail: z.string().nullable(),
  studentName: z.string().nullable(),
  handledByAdminId: z.string().nullable(),
});
export const adminLoyaltyRedemptionPageSchema = z.object({
  items: z.array(adminLoyaltyRedemptionSchema),
  nextCursor: z.string().nullable(),
});
export const adminLoyaltyRedemptionQuerySchema = z.object({
  status: loyaltyRedemptionStatusSchema.optional(),
  userId: z.uuid().optional(),
  cursor: z.string().max(200).optional(),
  limit: z.coerce.number().int().min(1).max(200).default(50),
});
/** `cancelled` refunds the points and removes a deck unlock it granted. */
export const redemptionStatusBodySchema = z.object({
  status: z.enum(['fulfilled', 'cancelled']),
  note: z.string().trim().max(500).nullable().optional(),
});

export const adminStudentLoyaltySchema = z.object({
  userId: z.string(),
  balance: int(),
  earnedToday: int(),
  /** Latest entries first (at most 100). */
  ledger: z.array(loyaltyLedgerEntrySchema),
  redemptions: z.array(loyaltyRedemptionSchema),
  /** Decks the student unlocked with points. */
  unlockedDeckIds: z.array(z.string()),
});
export const loyaltyAdjustBodySchema = z.object({
  delta: int()
    .min(-1_000_000)
    .max(1_000_000)
    .refine((v) => v !== 0, 'delta must not be 0'),
  note: z.string().trim().min(1).max(500),
});

export type LoyaltySettings = z.infer<typeof loyaltySettingsSchema>;
export type LoyaltySummary = z.infer<typeof loyaltySummarySchema>;
export type LoyaltyReward = z.infer<typeof loyaltyRewardSchema>;
export type LoyaltyRedemption = z.infer<typeof loyaltyRedemptionSchema>;
export type LoyaltyLedgerEntry = z.infer<typeof loyaltyLedgerEntrySchema>;
export type AdminLoyaltyReward = z.infer<typeof adminLoyaltyRewardSchema>;
export type AdminLoyaltyRedemption = z.infer<typeof adminLoyaltyRedemptionSchema>;
export type AdminStudentLoyalty = z.infer<typeof adminStudentLoyaltySchema>;

const named: [z.ZodType, string][] = [
  [loyaltySettingsSchema, 'LoyaltySettings'],
  [loyaltyReasonSchema, 'LoyaltyReason'],
  [loyaltyRewardKindSchema, 'LoyaltyRewardKind'],
  [loyaltyRedemptionStatusSchema, 'LoyaltyRedemptionStatus'],
  [loyaltySummarySchema, 'LoyaltySummary'],
  [loyaltyLedgerEntrySchema, 'LoyaltyLedgerEntry'],
  [loyaltyLedgerPageSchema, 'LoyaltyLedgerPage'],
  [loyaltyRewardSchema, 'LoyaltyReward'],
  [loyaltyRewardListSchema, 'LoyaltyRewardList'],
  [loyaltyRedemptionSchema, 'LoyaltyRedemption'],
  [loyaltyRedemptionListSchema, 'LoyaltyRedemptionList'],
  [loyaltyRedeemResultSchema, 'LoyaltyRedeemResult'],
  [adminLoyaltyRewardSchema, 'AdminLoyaltyReward'],
  [adminLoyaltyRewardListSchema, 'AdminLoyaltyRewardList'],
  [createLoyaltyRewardBodySchema, 'CreateLoyaltyRewardRequest'],
  [updateLoyaltyRewardBodySchema, 'UpdateLoyaltyRewardRequest'],
  [adminLoyaltyRedemptionSchema, 'AdminLoyaltyRedemption'],
  [adminLoyaltyRedemptionPageSchema, 'AdminLoyaltyRedemptionPage'],
  [redemptionStatusBodySchema, 'RedemptionStatusRequest'],
  [adminStudentLoyaltySchema, 'AdminStudentLoyalty'],
  [loyaltyAdjustBodySchema, 'LoyaltyAdjustRequest'],
];
for (const [schema, id] of named) z.globalRegistry.add(schema, { id });
