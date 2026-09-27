import { z } from 'zod';

/*
 * Access (spec §8, §9). Two scopes only: a subject's general content, or one teacher track. Requests
 * name a scope with explicit ids; responses describe it with names so clients never look them up.
 */

const text = (max: number) => z.string().trim().max(max);

/** Calendar date `YYYY-MM-DD`. Date-only expiries mean 23:59:59 Asia/Damascus on that date (§8.2). */
export const dateOnlySchema = z.iso.date();

export const scopeTypeSchema = z.enum(['subject', 'teacher_track']);

/** A scope as displayed: the subject, or the track with its teacher and subject. */
export const accessScopeSchema = z.object({
  scopeType: scopeTypeSchema,
  subjectId: z.string(),
  teacherTrackId: z.string().nullable(),
  subjectNameAr: z.string(),
  trackTitleAr: z.string().nullable(),
  teacherNameAr: z.string().nullable(),
  educationLevelId: z.string(),
});

/**
 * Whether the current student can open a scope's premium content, and why (spec §8.6). Free items
 * inside a locked scope stay accessible; they are flagged per item from Phase 5 on.
 */
export const scopeAccessSchema = z.object({
  hasAccess: z.boolean(),
  reason: z.enum(['entitlement', 'promotion']).nullable(),
  isPermanent: z.boolean(),
  entitlementExpiresAt: z.string().nullable(),
  promotionTitleAr: z.string().nullable(),
  promotionEndsAt: z.string().nullable(),
});

export const entitlementSourceSchema = z.enum(['coupon', 'admin_grant', 'promotion', 'future_purchase']);
export const entitlementStatusSchema = z.enum(['active', 'revoked', 'expired', 'superseded']);

/** An entitlement as the student sees it on "My access" (§23.2 #28). */
export const myEntitlementSchema = z.object({
  id: z.string(),
  scope: accessScopeSchema,
  source: entitlementSourceSchema,
  startsAt: z.string(),
  expiresAt: z.string().nullable(),
  isPermanent: z.boolean(),
  /** `active` is evaluated against the clock, not only the stored status. */
  state: z.enum(['active', 'expired', 'revoked']),
});
export const myEntitlementListSchema = z.array(myEntitlementSchema);

export const redeemCouponBodySchema = z.object({ code: z.string().max(64) });
export const redeemResultSchema = z.object({
  entitlement: myEntitlementSchema,
  /** A permanent code replaced an active temporary entitlement (§8.3). */
  upgraded: z.boolean(),
});

// ---- admin ----

/** How long a grant lasts. Exactly one of the three. */
const accessTermShape = {
  permanentAccess: z.boolean().optional(),
  accessDurationDays: z.number().int().min(1).max(3650).nullable().optional(),
  accessExpiresOn: dateOnlySchema.nullable().optional(),
};
const oneTerm = (t: {
  permanentAccess?: boolean | undefined;
  accessDurationDays?: number | null | undefined;
  accessExpiresOn?: string | null | undefined;
}) =>
  [t.permanentAccess === true, t.accessDurationDays != null, t.accessExpiresOn != null].filter(Boolean)
    .length === 1;
const termMessage = { message: 'choose exactly one access term', path: ['permanentAccess'] };

export const adminEntitlementSchema = myEntitlementSchema.extend({
  userId: z.string(),
  status: entitlementStatusSchema,
  couponId: z.string().nullable(),
  couponLast4: z.string().nullable(),
  grantedByAdminId: z.string().nullable(),
  revokedAt: z.string().nullable(),
  revokeReason: z.string().nullable(),
  createdAt: z.string(),
});
export const adminEntitlementListSchema = z.array(adminEntitlementSchema);

export const grantEntitlementBodySchema = z
  .object({
    scopeType: scopeTypeSchema,
    subjectId: z.uuid().nullable().optional(),
    teacherTrackId: z.uuid().nullable().optional(),
    ...accessTermShape,
  })
  .refine(
    (b) =>
      b.scopeType === 'subject' ? !!b.subjectId && !b.teacherTrackId : !!b.teacherTrackId && !b.subjectId,
    {
      message: 'scope requires exactly the id of its type',
      path: ['scopeType'],
    },
  )
  .refine(oneTerm, termMessage);

/** Extend instead of granting a duplicate (§8.3): a later date, or permanent. */
export const extendEntitlementBodySchema = z
  .object({ makePermanent: z.boolean().optional(), expiresOn: dateOnlySchema.nullable().optional() })
  .refine((b) => (b.makePermanent === true) !== (b.expiresOn != null), {
    message: 'choose permanent or a new date',
    path: ['expiresOn'],
  });

export const revokeEntitlementBodySchema = z.object({ reason: text(500).nullable().optional() });

export const adminStudentSchema = z.object({
  id: z.string(),
  email: z.string(),
  fullName: z.string().nullable(),
  educationLevelId: z.string().nullable(),
  emailVerified: z.boolean(),
  status: z.enum(['active', 'disabled']),
  createdAt: z.string(),
  activeEntitlementCount: z.number(),
});
export const adminStudentListSchema = z.array(adminStudentSchema);
export const adminStudentDetailSchema = z.object({
  student: adminStudentSchema,
  entitlements: adminEntitlementListSchema,
});
export const studentSearchQuerySchema = z.object({ q: text(200).optional() });

export const couponBatchSchema = z.object({
  id: z.string(),
  name: z.string(),
  distributorName: z.string().nullable(),
  notes: z.string().nullable(),
  scope: accessScopeSchema,
  quantity: z.number(),
  generatedCount: z.number(),
  redeemedCount: z.number(),
  validFrom: z.string().nullable(),
  expiresAt: z.string().nullable(),
  accessDurationDays: z.number().nullable(),
  accessExpiresAt: z.string().nullable(),
  permanentAccess: z.boolean(),
  status: z.enum(['active', 'revoked']),
  createdAt: z.string(),
  revokedAt: z.string().nullable(),
});
export const couponBatchListSchema = z.array(couponBatchSchema);

export const createCouponBatchBodySchema = z
  .object({
    name: text(200).min(1),
    distributorName: text(200).nullable().optional(),
    notes: text(2000).nullable().optional(),
    scopeType: scopeTypeSchema,
    subjectId: z.uuid().nullable().optional(),
    teacherTrackId: z.uuid().nullable().optional(),
    quantity: z.number().int().min(1).max(5000),
    /** When the codes can be redeemed: from 00:00 of `validFrom` to 23:59:59 of `expiresOn` (Damascus). */
    validFrom: dateOnlySchema.nullable().optional(),
    expiresOn: dateOnlySchema.nullable().optional(),
    ...accessTermShape,
  })
  .refine(
    (b) =>
      b.scopeType === 'subject' ? !!b.subjectId && !b.teacherTrackId : !!b.teacherTrackId && !b.subjectId,
    {
      message: 'scope requires exactly the id of its type',
      path: ['scopeType'],
    },
  )
  .refine(oneTerm, termMessage)
  .refine((b) => !b.validFrom || !b.expiresOn || b.validFrom <= b.expiresOn, {
    message: 'validFrom must not be after expiresOn',
    path: ['expiresOn'],
  });

export const adminCouponSchema = z.object({
  id: z.string(),
  batchId: z.string(),
  batchName: z.string(),
  codeLast4: z.string(),
  status: z.enum(['active', 'redeemed', 'revoked']),
  currentUses: z.number(),
  maxUses: z.number(),
  redeemedAt: z.string().nullable(),
  redeemedByUserId: z.string().nullable(),
  redeemedByEmail: z.string().nullable(),
});
export const adminCouponListSchema = z.array(adminCouponSchema);
/** `q` is a full code (any format students might type) or its last four characters. */
export const couponSearchQuerySchema = z.object({ q: text(64).min(4) });
export const couponExportQuerySchema = z.object({ format: z.enum(['csv', 'xlsx']).default('csv') });

export const couponFailureReportSchema = z.object({
  since: z.string(),
  users: z.array(
    z.object({ userId: z.string(), email: z.string().nullable(), failures: z.number(), lastAt: z.string() }),
  ),
  ips: z.array(z.object({ ipHash: z.string(), failures: z.number(), lastAt: z.string() })),
});

export const promotionSchema = z.object({
  id: z.string(),
  scope: accessScopeSchema,
  titleAr: z.string(),
  startsAt: z.string(),
  endsAt: z.string(),
  isActive: z.boolean(),
  /** `running` means students have access right now. */
  state: z.enum(['scheduled', 'running', 'ended', 'disabled']),
  createdAt: z.string(),
});
export const promotionListSchema = z.array(promotionSchema);
export const createPromotionBodySchema = z
  .object({
    scopeType: scopeTypeSchema,
    subjectId: z.uuid().nullable().optional(),
    teacherTrackId: z.uuid().nullable().optional(),
    titleAr: text(200).min(1),
    startsAt: z.iso.datetime({ offset: true }),
    endsAt: z.iso.datetime({ offset: true }),
    isActive: z.boolean().optional(),
  })
  .refine(
    (b) =>
      b.scopeType === 'subject' ? !!b.subjectId && !b.teacherTrackId : !!b.teacherTrackId && !b.subjectId,
    {
      message: 'scope requires exactly the id of its type',
      path: ['scopeType'],
    },
  )
  .refine((b) => Date.parse(b.endsAt) > Date.parse(b.startsAt), {
    message: 'endsAt must follow startsAt',
    path: ['endsAt'],
  });
/** The scope of a promotion is fixed; create a new one for another scope. */
export const updatePromotionBodySchema = z.object({
  titleAr: text(200).min(1).optional(),
  startsAt: z.iso.datetime({ offset: true }).optional(),
  endsAt: z.iso.datetime({ offset: true }).optional(),
  isActive: z.boolean().optional(),
});

export const freeContentKindSchema = z.enum(['questions', 'flashcard_decks', 'quizzes', 'all']);
export const freeRuleTypeSchema = z.enum([
  'manual',
  'first_n_items',
  'first_n_lessons',
  'first_unit',
  'percentage',
]);

export const freeRuleSchema = z.object({
  id: z.string(),
  scope: accessScopeSchema,
  contentKind: freeContentKindSchema,
  ruleType: freeRuleTypeSchema,
  ruleValue: z.number().nullable(),
  updatedAt: z.string(),
});
export const freeRuleListSchema = z.array(freeRuleSchema);

export const freeRuleBodySchema = z
  .object({
    scopeType: scopeTypeSchema,
    subjectId: z.uuid().nullable().optional(),
    teacherTrackId: z.uuid().nullable().optional(),
    contentKind: freeContentKindSchema,
    ruleType: freeRuleTypeSchema,
    ruleValue: z.number().int().min(1).max(100_000).nullable().optional(),
  })
  .refine(
    (b) =>
      b.scopeType === 'subject' ? !!b.subjectId && !b.teacherTrackId : !!b.teacherTrackId && !b.subjectId,
    {
      message: 'scope requires exactly the id of its type',
      path: ['scopeType'],
    },
  )
  .refine(
    (b) =>
      b.ruleType === 'manual' || b.ruleType === 'first_unit'
        ? b.ruleValue == null
        : b.ruleValue != null && (b.ruleType !== 'percentage' || b.ruleValue <= 100),
    { message: 'ruleValue does not match ruleType', path: ['ruleValue'] },
  );

/** "سيصبح 12 عنصراً مجانياً و3 مدفوعة" — counts after applying the rule (§8.4). */
export const freeRulePreviewSchema = z.object({
  freeCount: z.number(),
  paidCount: z.number(),
  byKind: z.array(
    z.object({ contentKind: freeContentKindSchema, freeCount: z.number(), paidCount: z.number() }),
  ),
});

/** Access settings stored in app_settings (spec §26.2). */
export const accessSettingsSchema = z.object({ allowTemporaryToPermanentUpgrade: z.boolean() });

export type ScopeType = z.infer<typeof scopeTypeSchema>;
export type AccessScope = z.infer<typeof accessScopeSchema>;
export type ScopeAccess = z.infer<typeof scopeAccessSchema>;
export type MyEntitlement = z.infer<typeof myEntitlementSchema>;
export type RedeemResult = z.infer<typeof redeemResultSchema>;
export type AdminEntitlement = z.infer<typeof adminEntitlementSchema>;
export type AdminStudent = z.infer<typeof adminStudentSchema>;
export type CouponBatch = z.infer<typeof couponBatchSchema>;
export type AdminCoupon = z.infer<typeof adminCouponSchema>;
export type Promotion = z.infer<typeof promotionSchema>;
export type FreeRule = z.infer<typeof freeRuleSchema>;
export type FreeRulePreview = z.infer<typeof freeRulePreviewSchema>;
export type FreeContentKind = z.infer<typeof freeContentKindSchema>;
export type FreeRuleType = z.infer<typeof freeRuleTypeSchema>;
export type AccessSettings = z.infer<typeof accessSettingsSchema>;

const named: [z.ZodType, string][] = [
  [accessScopeSchema, 'AccessScope'],
  [scopeAccessSchema, 'ScopeAccess'],
  [myEntitlementSchema, 'MyEntitlement'],
  [myEntitlementListSchema, 'MyEntitlementList'],
  [redeemCouponBodySchema, 'RedeemCouponRequest'],
  [redeemResultSchema, 'RedeemResult'],
  [adminEntitlementSchema, 'AdminEntitlement'],
  [adminEntitlementListSchema, 'AdminEntitlementList'],
  [grantEntitlementBodySchema, 'GrantEntitlementRequest'],
  [extendEntitlementBodySchema, 'ExtendEntitlementRequest'],
  [revokeEntitlementBodySchema, 'RevokeEntitlementRequest'],
  [adminStudentSchema, 'AdminStudent'],
  [adminStudentListSchema, 'AdminStudentList'],
  [adminStudentDetailSchema, 'AdminStudentDetail'],
  [couponBatchSchema, 'CouponBatch'],
  [couponBatchListSchema, 'CouponBatchList'],
  [createCouponBatchBodySchema, 'CreateCouponBatchRequest'],
  [adminCouponSchema, 'AdminCoupon'],
  [adminCouponListSchema, 'AdminCouponList'],
  [couponFailureReportSchema, 'CouponFailureReport'],
  [promotionSchema, 'Promotion'],
  [promotionListSchema, 'PromotionList'],
  [createPromotionBodySchema, 'CreatePromotionRequest'],
  [updatePromotionBodySchema, 'UpdatePromotionRequest'],
  [freeRuleSchema, 'FreeRule'],
  [freeRuleListSchema, 'FreeRuleList'],
  [freeRuleBodySchema, 'FreeRuleRequest'],
  [freeRulePreviewSchema, 'FreeRulePreview'],
  [accessSettingsSchema, 'AccessSettings'],
];
for (const [schema, id] of named) z.globalRegistry.add(schema, { id });
