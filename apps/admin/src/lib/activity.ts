/** Arabic names for audit-log resource families (the part of an action before the first dot). */
const SUBJECTS: Record<string, string> = {
  admin: 'مشرف',
  entitlement: 'صلاحية وصول',
  coupon_batch: 'دفعة كوبونات',
  free_rule: 'قاعدة محتوى مجاني',
  promotion: 'عرض مؤقت',
  question: 'سؤال',
  deck: 'مجموعة بطاقات',
  card: 'بطاقة',
  quiz: 'اختبار',
  structure: 'البنية التعليمية',
  banner: 'إعلان',
  countdown: 'عد تنازلي',
  notification: 'إشعار',
  report: 'بلاغ',
  import: 'استيراد',
  settings: 'الإعدادات',
  session: 'جلسة',
  review_account: 'حساب المراجعة',
  student: 'طالب',
  teacher: 'مدرس',
  track: 'مسار',
  account: 'حساب طالب',
};

/** `structure.<kind>.<verb>` names the kind of structure record. */
const STRUCTURE: Record<string, string> = {
  level: 'مرحلة تعليمية',
  university: 'جامعة',
  faculty: 'كلية',
  academic_year: 'سنة دراسية',
  subject: 'مادة',
  unit: 'وحدة',
  lesson: 'درس',
  teacher: 'مدرس',
  teacher_track: 'مسار',
};

/** Arabic verbs for the past-tense action suffixes the API writes; `%` places the noun inside. */
const VERBS: Record<string, string> = {
  created: 'إنشاء',
  created_via_cli: 'إنشاء % من سطر الأوامر',
  updated: 'تعديل',
  deleted: 'حذف',
  changed: 'تغيير',
  revoked: 'إلغاء',
  revoked_by_admin: 'إنهاء',
  granted: 'منح',
  extended: 'تمديد',
  generated: 'توليد',
  exported: 'تصدير',
  completed: 'اكتمال',
  reordered: 'إعادة ترتيب',
  flag_cleared: 'إزالة علامة المراجعة عن',
  status_changed: 'تغيير حالة',
  published: 'نشر',
  archived: 'أرشفة',
  resolved: 'معالجة',
  dismissed: 'رفض',
  deactivated: 'تعطيل',
  reactivated: 'إعادة تفعيل',
  sent: 'إرسال',
  deleted_by_admin: 'حذف % من الإدارة',
  '2fa_enrolled': 'تفعيل التحقق الثنائي لحساب %',
  '2fa_reset': 'إعادة ضبط التحقق الثنائي لحساب %',
  free_override: 'تغيير الوصول المجاني (%)',
  questions_set: 'تحديد أسئلة %',
};

/**
 * A readable Arabic line for an audit action such as `question.created` ("إنشاء سؤال"). Unknown
 * actions return null so the caller can show the raw identifier instead.
 */
export function activityLabel(action: string): string | null {
  const [family, ...rest] = action.split('.');
  const verb = VERBS[rest.at(-1) ?? ''];
  const subject = family === 'structure' && rest.length > 1 ? STRUCTURE[rest[0]!] : SUBJECTS[family ?? ''];
  if (!verb || !subject) return null;
  return verb.includes('%') ? verb.replace('%', subject) : `${verb} ${subject}`;
}

const relative = new Intl.RelativeTimeFormat('ar', { numeric: 'auto' });

/** "قبل 5 دقائق", "أمس"… for recent activity. */
export function timeAgo(iso: string, now = Date.now()): string {
  const seconds = Math.round((new Date(iso).getTime() - now) / 1000);
  const units: [Intl.RelativeTimeFormatUnit, number][] = [
    ['day', 86400],
    ['hour', 3600],
    ['minute', 60],
  ];
  for (const [unit, size] of units) {
    if (Math.abs(seconds) >= size) return relative.format(Math.round(seconds / size), unit);
  }
  return 'الآن';
}
