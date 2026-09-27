'use client';

import { ArrowRight, Download } from 'lucide-react';
import Link from 'next/link';
import { useParams } from 'next/navigation';
import { useEffect, useState } from 'react';
import { FormError } from '@/components/form-error';
import { Button } from '@/components/ui/button';
import { Card } from '@/components/ui/card';
import { formatDate, formatDateTime, scopeLabel } from '@/lib/access';
import { api, unwrap } from '@/lib/api';
import { errorMessage, useLoad } from '@/lib/use-load';

const COUPON_STATUS: Record<string, string> = { active: 'غير مستخدم', redeemed: 'مستخدم', revoked: 'ملغى' };

/** One batch: generation progress, export (audited), revoke, and its codes (spec §9.6). */
export default function CouponBatchPage() {
  const { id } = useParams<{ id: string }>();
  const batch = useLoad(
    () => unwrap(api.GET('/api/v1/admin/coupon-batches/{id}', { params: { path: { id } } })),
    [id],
  );
  const codes = useLoad(
    () => unwrap(api.GET('/api/v1/admin/coupon-batches/{id}/coupons', { params: { path: { id } } })),
    [id],
  );
  const [error, setError] = useState<string | null>(null);
  const b = batch.data;
  const generating = !!b && b.status === 'active' && b.generatedCount < b.quantity;

  // Generation runs as a background job: poll until every code exists, then list them.
  const reloadBatch = batch.reload;
  const reloadCodes = codes.reload;
  useEffect(() => {
    if (!generating) {
      void reloadCodes();
      return;
    }
    const timer = setInterval(() => void reloadBatch(), 1500);
    return () => clearInterval(timer);
  }, [generating, reloadBatch, reloadCodes]);

  async function exportAs(format: 'csv' | 'xlsx') {
    setError(null);
    const { data, response } = await api.GET('/api/v1/admin/coupon-batches/{id}/export', {
      params: { path: { id }, query: { format } },
      parseAs: 'blob',
    });
    if (!response.ok || !data) {
      setError('تعذر تصدير الأكواد');
      return;
    }
    const match = /filename="([^"]+)"/.exec(response.headers.get('content-disposition') ?? '');
    const url = URL.createObjectURL(data as Blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = match?.[1] ?? `coupons.${format}`;
    a.click();
    URL.revokeObjectURL(url);
  }

  async function revoke() {
    if (
      !window.confirm(
        'إلغاء الدفعة يجعل كل الأكواد غير المستخدمة غير صالحة. الصلاحيات الممنوحة سابقاً لا تتأثر. متابعة؟',
      )
    )
      return;
    setError(null);
    try {
      await unwrap(api.POST('/api/v1/admin/coupon-batches/{id}/revoke', { params: { path: { id } } }));
      await Promise.all([batch.reload(), codes.reload()]);
    } catch (err) {
      setError(errorMessage(err));
    }
  }

  return (
    <div className="mx-auto max-w-5xl space-y-4">
      <Link href="/coupons" className="inline-flex items-center gap-1 text-sm text-brand">
        <ArrowRight className="size-4" aria-hidden />
        كل الدفعات
      </Link>
      <FormError message={batch.error ?? codes.error ?? error} />
      {b ? (
        <Card className="space-y-3">
          <div className="flex flex-wrap items-start justify-between gap-2">
            <div>
              <h1 className="text-xl font-semibold">{b.name}</h1>
              <p className="text-sm text-muted">
                {scopeLabel(b.scope)} · {b.distributorName ?? 'بدون موزع'}
              </p>
            </div>
            {b.status === 'revoked' ? (
              <span className="rounded-full bg-danger/10 px-3 py-1 text-sm text-danger">
                ملغاة {formatDate(b.revokedAt)}
              </span>
            ) : null}
          </div>
          <dl className="grid gap-2 text-sm sm:grid-cols-2">
            <div>
              <dt className="text-muted">الوصول بعد التفعيل</dt>
              <dd>
                {b.permanentAccess
                  ? 'دائم'
                  : b.accessDurationDays
                    ? `${b.accessDurationDays} يوماً`
                    : `حتى ${formatDate(b.accessExpiresAt)}`}
              </dd>
            </div>
            <div>
              <dt className="text-muted">صلاحية الكود</dt>
              <dd>
                {b.validFrom ? `من ${formatDate(b.validFrom)} ` : ''}
                {b.expiresAt ? `حتى ${formatDate(b.expiresAt)}` : b.validFrom ? '' : 'بدون تاريخ انتهاء'}
              </dd>
            </div>
            <div>
              <dt className="text-muted">الأكواد</dt>
              <dd>
                {b.generatedCount} من {b.quantity} · استُخدم {b.redeemedCount}
              </dd>
            </div>
            <div>
              <dt className="text-muted">أنشئت</dt>
              <dd>{formatDateTime(b.createdAt)}</dd>
            </div>
          </dl>
          {generating ? (
            <div
              role="progressbar"
              aria-valuemin={0}
              aria-valuemax={b.quantity}
              aria-valuenow={b.generatedCount}
              aria-label="تقدم التوليد"
              className="h-2 overflow-hidden rounded-full bg-surface-muted"
            >
              <div
                className="h-full bg-brand transition-all"
                style={{ width: `${(b.generatedCount / b.quantity) * 100}%` }}
              />
            </div>
          ) : null}
          {b.notes ? <p className="text-sm">{b.notes}</p> : null}
          <div className="flex flex-wrap gap-2">
            <Button variant="outline" disabled={generating} onClick={() => void exportAs('csv')}>
              <Download className="size-4" aria-hidden />
              تصدير CSV
            </Button>
            <Button variant="outline" disabled={generating} onClick={() => void exportAs('xlsx')}>
              <Download className="size-4" aria-hidden />
              تصدير Excel
            </Button>
            {b.status === 'active' ? (
              <Button variant="ghost" className="text-danger" onClick={() => void revoke()}>
                إلغاء الدفعة
              </Button>
            ) : null}
          </div>
        </Card>
      ) : null}

      <Card className="overflow-x-auto p-0">
        <table className="w-full text-sm">
          <thead className="border-b border-border text-muted">
            <tr>
              <th className="p-3 text-start font-medium">الكود</th>
              <th className="p-3 text-start font-medium">الحالة</th>
              <th className="p-3 text-start font-medium">استخدمه</th>
            </tr>
          </thead>
          <tbody>
            {(codes.data ?? []).map((c) => (
              <tr key={c.id} className="border-b border-border last:border-0">
                <td className="p-3">
                  <span dir="ltr" className="font-mono">
                    …{c.codeLast4.slice(0, 2)}-{c.codeLast4.slice(2)}
                  </span>
                </td>
                <td className="p-3">{COUPON_STATUS[c.status]}</td>
                <td className="p-3">
                  {c.redeemedByEmail ? (
                    <Link
                      href={`/students/${c.redeemedByUserId}`}
                      dir="ltr"
                      className="text-brand hover:underline"
                    >
                      {c.redeemedByEmail}
                    </Link>
                  ) : (
                    '—'
                  )}
                  {c.redeemedAt ? (
                    <div className="text-xs text-muted">{formatDateTime(c.redeemedAt)}</div>
                  ) : null}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </Card>
    </div>
  );
}
