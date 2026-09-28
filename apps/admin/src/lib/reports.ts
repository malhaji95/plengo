import type { components } from './api-schema';

export type AdminReport = components['schemas']['AdminReport'];

export const REASON_LABELS: Record<AdminReport['reason'], string> = {
  wrong_answer: 'إجابة خاطئة',
  typo: 'خطأ إملائي',
  unclear: 'غير واضح',
  image_problem: 'مشكلة في الصورة',
  other: 'أخرى',
};

export const REPORT_STATUS_LABELS: Record<AdminReport['status'], string> = {
  open: 'مفتوح',
  resolved: 'تمت المعالجة',
  dismissed: 'مرفوض',
};

/** Where to fix the reported item ("jump to edit", §21). */
export const editHref = (r: AdminReport) =>
  r.itemType === 'question' ? `/questions/${r.itemId}` : r.deckId ? `/flashcards/${r.deckId}` : null;
