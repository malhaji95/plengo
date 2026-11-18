import type { components } from './api-schema';

export type AdminLoyaltyReward = components['schemas']['AdminLoyaltyReward'];
export type LoyaltySettings = components['schemas']['LoyaltySettings'];
export type RedemptionStatus = components['schemas']['LoyaltyRedemptionStatus'];
export type RewardKind = components['schemas']['LoyaltyRewardKind'];
export type LoyaltyReason = components['schemas']['LoyaltyReason'];

export const REWARD_KIND_LABELS: Record<RewardKind, string> = {
  unlock_deck: 'فتح مجموعة بطاقات',
  custom: 'مكافأة خاصة',
};

export const REDEMPTION_STATUS_LABELS: Record<RedemptionStatus, string> = {
  pending: 'بانتظار التسليم',
  fulfilled: 'تم',
  cancelled: 'ملغى (مُسترد)',
};

export const REASON_LABELS: Record<LoyaltyReason, string> = {
  review: 'مراجعة بطاقة',
  correct_answer: 'إجابة صحيحة',
  redemption: 'استبدال مكافأة',
  refund: 'استرداد',
  admin_adjust: 'تعديل يدوي',
};

/** The reward form as text fields. */
export interface RewardForm {
  titleAr: string;
  description: string;
  costPoints: string;
  kind: RewardKind;
  deckId: string;
  isActive: boolean;
  sortOrder: string;
}

export const EMPTY_REWARD: RewardForm = {
  titleAr: '',
  description: '',
  costPoints: '100',
  kind: 'unlock_deck',
  deckId: '',
  isActive: true,
  sortOrder: '0',
};

export const toRewardForm = (r: AdminLoyaltyReward): RewardForm => ({
  titleAr: r.titleAr,
  description: r.description ?? '',
  costPoints: String(r.costPoints),
  kind: r.kind,
  deckId: r.deckId ?? '',
  isActive: r.isActive,
  sortOrder: String(r.sortOrder),
});

export function rewardProblems(f: RewardForm): string[] {
  const problems: string[] = [];
  if (!f.titleAr.trim()) problems.push('أدخل عنوان المكافأة');
  const cost = Number(f.costPoints);
  if (!Number.isInteger(cost) || cost < 1) problems.push('التكلفة عدد صحيح موجب');
  if (f.kind === 'unlock_deck' && !f.deckId) problems.push('اختر المجموعة التي تفتحها المكافأة');
  const order = Number(f.sortOrder);
  if (!Number.isInteger(order) || order < 0) problems.push('الترتيب عدد صحيح');
  return problems;
}

export const rewardBody = (f: RewardForm) => ({
  titleAr: f.titleAr.trim(),
  description: f.description.trim() || null,
  costPoints: Number(f.costPoints),
  kind: f.kind,
  deckId: f.kind === 'unlock_deck' ? f.deckId : null,
  isActive: f.isActive,
  sortOrder: Number(f.sortOrder),
});

/** Settings form problems (Arabic); empty when valid. */
export function settingsProblems(s: {
  pointsPerReview: string;
  dailyCap: string;
  pointsPerCorrectQuestion: string;
}) {
  const ok = (v: string, max: number) => /^\d+$/.test(v.trim()) && Number(v) <= max;
  const problems: string[] = [];
  if (!ok(s.pointsPerReview, 1000)) problems.push('نقاط المراجعة بين 0 و 1000');
  if (!ok(s.dailyCap, 100_000)) problems.push('الحد اليومي بين 0 و 100000');
  if (!ok(s.pointsPerCorrectQuestion, 1000)) problems.push('نقاط الإجابة الصحيحة بين 0 و 1000');
  return problems;
}
