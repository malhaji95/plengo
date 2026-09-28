'use client';

import { ArrowRight } from 'lucide-react';
import Link from 'next/link';
import { useParams } from 'next/navigation';
import { EntitlementTable } from '@/components/access/entitlement-table';
import { GrantForm } from '@/components/access/grant-form';
import { FormError } from '@/components/form-error';
import { Card } from '@/components/ui/card';
import { formatDate } from '@/lib/access';
import { api, unwrap } from '@/lib/api';
import { Button } from '@/components/ui/button';
import { errorMessage, useLoad } from '@/lib/use-load';
import { useState } from 'react';

/**
 * One student (spec §26.2): profile summary, entitlements with grant/extend/revoke, active sessions
 * (revocable) and a summary of recent attempts.
 */
export default function StudentPage() {
  const { id } = useParams<{ id: string }>();
  const detail = useLoad(
    () => unwrap(api.GET('/api/v1/admin/students/{id}', { params: { path: { id } } })),
    [id],
  );
  const s = detail.data?.student;
  const sessions = useLoad(
    () => unwrap(api.GET('/api/v1/admin/students/{id}/sessions', { params: { path: { id } } })),
    [id],
  );
  const attempts = useLoad(
    () =>
      unwrap(
        api.GET('/api/v1/admin/students/{id}/attempts', { params: { path: { id }, query: { limit: 20 } } }),
      ),
    [id],
  );
  const [error, setError] = useState<string | null>(null);

  /** Account deletion on the student's request (spec §33): irreversible, audited. */
  async function deleteAccount() {
    if (
      !window.confirm(
        'سيُحذف الاسم والبريد والصورة والجلسات والصلاحيات ومجموعات البطاقات الخاصة لهذا الطالب نهائياً، وتبقى الإحصاءات دون هوية. متابعة؟',
      )
    )
      return;
    setError(null);
    try {
      await unwrap(api.POST('/api/v1/admin/students/{id}/delete', { params: { path: { id } } }));
      await detail.reload();
    } catch (err) {
      setError(errorMessage(err));
    }
  }

  return (
    <div className="mx-auto max-w-5xl space-y-4">
      <Link href="/students" className="inline-flex items-center gap-1 text-sm text-brand">
        <ArrowRight className="size-4" aria-hidden />
        كل الطلاب
      </Link>
      <FormError message={detail.error} />
      {s ? (
        <Card className="space-y-1">
          <h1 className="text-xl font-semibold">{s.fullName ?? '—'}</h1>
          <p dir="ltr" className="text-start text-sm text-muted">
            {s.email}
          </p>
          <p className="text-sm text-muted">
            تاريخ التسجيل {formatDate(s.createdAt)} ·{' '}
            {s.emailVerified ? 'البريد مُفعّل' : 'البريد غير مُفعّل'}
            {s.status === 'disabled' ? ' · الحساب معطّل' : ''}
            {s.status === 'deleted' ? ' · الحساب محذوف' : ''}
          </p>
          {s.status !== 'deleted' ? (
            <div className="pt-2">
              <Button
                variant="outline"
                size="sm"
                className="text-danger"
                onClick={() => void deleteAccount()}
              >
                حذف الحساب نهائياً
              </Button>
            </div>
          ) : null}
        </Card>
      ) : null}
      <FormError message={error} />
      <Card className="space-y-3 p-0 pt-4">
        <h2 className="px-4 font-semibold">صلاحيات الوصول</h2>
        <EntitlementTable items={detail.data?.entitlements ?? []} onChanged={detail.reload} />
      </Card>
      <Card className="space-y-3">
        <h2 className="font-semibold">منح وصول جديد</h2>
        <GrantForm studentId={id} onGranted={detail.reload} />
      </Card>
      <Card className="space-y-3">
        <h2 className="font-semibold">الجلسات النشطة</h2>
        <FormError message={sessions.error ?? error} />
        {(sessions.data ?? []).length === 0 ? <p className="text-sm text-muted">لا توجد جلسات نشطة</p> : null}
        <ul className="space-y-2">
          {(sessions.data ?? []).map((x) => (
            <li key={x.id} className="flex items-center justify-between gap-2 text-sm">
              <span>
                {x.platform}
                {x.appVersion ? ` · ${x.appVersion}` : ''} · آخر نشاط {formatDate(x.lastSeenAt)}
                <span dir="ltr" className="block text-start text-xs text-muted">
                  {x.userAgent ?? ''}
                </span>
              </span>
              <Button
                variant="outline"
                onClick={async () => {
                  setError(null);
                  try {
                    await unwrap(
                      api.DELETE('/api/v1/admin/students/{id}/sessions/{sessionId}', {
                        params: { path: { id, sessionId: x.id } },
                      }),
                    );
                    await sessions.reload();
                  } catch (err) {
                    setError(errorMessage(err));
                  }
                }}
              >
                إنهاء الجلسة
              </Button>
            </li>
          ))}
        </ul>
      </Card>
      <Card className="space-y-3 p-0 pt-4">
        <h2 className="px-4 font-semibold">آخر المحاولات</h2>
        <FormError message={attempts.error} />
        <table className="w-full text-sm">
          <thead className="border-b border-border text-muted">
            <tr>
              <th className="p-3 text-start font-medium">الاختبار</th>
              <th className="p-3 text-start font-medium">الوضع</th>
              <th className="p-3 text-start font-medium">الحالة</th>
              <th className="p-3 text-start font-medium">النتيجة</th>
              <th className="p-3 text-start font-medium">التاريخ</th>
            </tr>
          </thead>
          <tbody>
            {(attempts.data?.items ?? []).map((a) => (
              <tr key={a.id} className="border-b border-border last:border-0">
                <td className="p-3">{a.titleAr}</td>
                <td className="p-3">{a.mode === 'exam' ? 'امتحان' : 'تدريب'}</td>
                <td className="p-3">
                  {a.status === 'submitted' ? 'مُسلّم' : a.status === 'in_progress' ? 'قيد الحل' : 'متروك'}
                  {a.submittedLate ? ' · متأخر' : ''}
                </td>
                <td className="p-3" dir="ltr">
                  {a.scorePercent == null ? '—' : `${a.scorePercent}% (${a.correctCount}/${a.totalCount})`}
                </td>
                <td className="p-3">{formatDate(a.startedAt)}</td>
              </tr>
            ))}
            {attempts.data?.items.length === 0 ? (
              <tr>
                <td colSpan={5} className="p-4 text-center text-muted">
                  لا توجد محاولات
                </td>
              </tr>
            ) : null}
          </tbody>
        </table>
      </Card>
    </div>
  );
}
