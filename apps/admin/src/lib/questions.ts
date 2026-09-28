import type { components } from './api-schema';

export type AdminQuestion = components['schemas']['AdminQuestion'];
export type QuestionType = AdminQuestion['type'];

export const TYPE_LABELS: Record<QuestionType, string> = {
  mcq: 'اختيار من متعدد',
  true_false: 'صح / خطأ',
  written: 'إجابة مكتوبة',
};

export const STATUS_LABELS: Record<AdminQuestion['status'], string> = {
  draft: 'مسودة',
  published: 'منشور',
  archived: 'مؤرشف',
};

export const DIFFICULTY_LABELS: Record<NonNullable<AdminQuestion['difficulty']>, string> = {
  easy: 'سهل',
  medium: 'متوسط',
  hard: 'صعب',
};

export function freeLabel(q: Pick<AdminQuestion, 'isFree' | 'freeSource'>) {
  const state = q.isFree ? 'مجاني' : 'مدفوع';
  return q.freeSource === 'manual_override' ? `${state} (يدوي)` : `${state} (حسب القاعدة)`;
}

export type AdminQuiz = components['schemas']['AdminQuiz'];

export const MODE_LABELS: Record<AdminQuiz['allowedModes'], string> = {
  both: 'تدريب وامتحان',
  practice: 'تدريب فقط',
  exam: 'امتحان فقط',
};
