import type { components } from './api-schema';

export type BannerAction = components['schemas']['BannerAction'];
export type NotificationType = components['schemas']['NotificationType'];
export type NotificationTargetType = components['schemas']['NotificationTargetType'];

/** What a banner or notification opens when tapped (spec §19.2, §20.2). */
export const ACTION_LABELS: Record<BannerAction, string> = {
  none: 'بدون إجراء',
  subject: 'مادة',
  teacher: 'مدرس',
  teacher_track: 'مسار مدرس',
  quiz: 'اختبار',
  deck: 'مجموعة بطاقات',
  internal_route: 'صفحة داخل التطبيق',
  external_url: 'رابط خارجي',
};

export const ACTION_HINTS: Partial<Record<BannerAction, string>> = {
  internal_route: 'مثال: /home/review',
  external_url: 'يبدأ بـ https://',
};

/** Actions whose target is an entity id. */
export const ID_ACTIONS: BannerAction[] = ['subject', 'teacher', 'teacher_track', 'quiz', 'deck'];

export const NOTIFICATION_TYPE_LABELS: Record<NotificationType, string> = {
  announcement: 'إعلان',
  new_content: 'محتوى جديد',
  teacher_update: 'تحديث من مدرس',
  study_reminder: 'تذكير بالدراسة',
  promotion: 'عرض',
  due_reminder: 'تذكير المراجعة',
  report_resolved: 'معالجة بلاغ',
};

export const TARGET_LABELS: Record<NotificationTargetType, string> = {
  all: 'جميع الطلاب',
  level: 'مرحلة تعليمية',
  subject_entitlement: 'من لديهم صلاحية مادة',
  track_entitlement: 'من لديهم صلاحية مسار',
  teacher_followers: 'متابعو مدرس',
  students: 'طلاب محددون',
};

export const STATUS_LABELS: Record<string, string> = {
  queued: 'في الانتظار',
  sending: 'جارٍ الإرسال',
  sent: 'أُرسل',
  failed: 'فشل',
};

/** A datetime-local value (Damascus wall clock) → ISO instant. Damascus is UTC+3 all year. */
export const damascusToIso = (local: string) => new Date(`${local}:00+03:00`).toISOString();

/** ISO instant → datetime-local value on the Damascus wall clock. */
export function isoToDamascus(iso: string | null): string {
  if (!iso) return '';
  return new Date(new Date(iso).getTime() + 3 * 3600_000).toISOString().slice(0, 16);
}
