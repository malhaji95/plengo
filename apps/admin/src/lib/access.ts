import type { components } from './api-schema';

export type AccessScope = components['schemas']['AccessScope'];
export type ScopeValue = {
  scopeType: 'subject' | 'teacher_track';
  subjectId: string | null;
  teacherTrackId: string | null;
};
export type TermValue =
  { kind: 'permanent' } | { kind: 'duration'; days: number } | { kind: 'until'; date: string };

export const EMPTY_SCOPE: ScopeValue = { scopeType: 'subject', subjectId: null, teacherTrackId: null };

export const scopeReady = (s: ScopeValue) => (s.scopeType === 'subject' ? !!s.subjectId : !!s.teacherTrackId);

/** Request fields for a scope: only the id of its type is sent. */
export function scopeBody(s: ScopeValue) {
  return s.scopeType === 'subject'
    ? { scopeType: 'subject' as const, subjectId: s.subjectId }
    : { scopeType: 'teacher_track' as const, teacherTrackId: s.teacherTrackId };
}

/** Request fields for an access term (exactly one of the three, spec §9.1). */
export function termBody(t: TermValue) {
  if (t.kind === 'permanent') return { permanentAccess: true };
  if (t.kind === 'duration') return { accessDurationDays: t.days };
  return { accessExpiresOn: t.date };
}

export function scopeLabel(s: AccessScope): string {
  return s.scopeType === 'subject'
    ? `${s.subjectNameAr} (المحتوى العام)`
    : `${s.trackTitleAr ?? ''} · ${s.subjectNameAr}`;
}

const dateFmt = new Intl.DateTimeFormat('ar-SY-u-nu-latn', {
  timeZone: 'Asia/Damascus',
  dateStyle: 'medium',
});
const dateTimeFmt = new Intl.DateTimeFormat('ar-SY-u-nu-latn', {
  timeZone: 'Asia/Damascus',
  dateStyle: 'medium',
  timeStyle: 'short',
});

/** Dates are shown in Damascus time, the business time zone (spec §8.2). */
export const formatDate = (iso: string | null | undefined) => (iso ? dateFmt.format(new Date(iso)) : '—');
export const formatDateTime = (iso: string | null | undefined) =>
  iso ? dateTimeFmt.format(new Date(iso)) : '—';

/** Tomorrow's date in Damascus as YYYY-MM-DD, a sensible minimum for date inputs. */
export function damascusDate(offsetDays = 0): string {
  const d = new Date(Date.now() + offsetDays * 86_400_000);
  return new Intl.DateTimeFormat('en-CA', { timeZone: 'Asia/Damascus' }).format(d);
}

export const STATE_LABELS: Record<string, string> = {
  active: 'فعّال',
  expired: 'منتهي',
  revoked: 'ملغى',
  superseded: 'مُستبدل بترقية',
};

export const SOURCE_LABELS: Record<string, string> = {
  coupon: 'كود تفعيل',
  admin_grant: 'منح من المشرف',
  promotion: 'عرض',
  future_purchase: 'شراء',
};

export function termLabel(e: { isPermanent: boolean; expiresAt: string | null }) {
  return e.isPermanent ? 'دائم' : `حتى ${formatDate(e.expiresAt)}`;
}
