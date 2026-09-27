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
import { useLoad } from '@/lib/use-load';

/** One student: profile summary, entitlements, and grant/extend/revoke (spec §26.2). */
export default function StudentPage() {
  const { id } = useParams<{ id: string }>();
  const detail = useLoad(
    () => unwrap(api.GET('/api/v1/admin/students/{id}', { params: { path: { id } } })),
    [id],
  );
  const s = detail.data?.student;

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
          </p>
        </Card>
      ) : null}
      <Card className="space-y-3 p-0 pt-4">
        <h2 className="px-4 font-semibold">صلاحيات الوصول</h2>
        <EntitlementTable items={detail.data?.entitlements ?? []} onChanged={detail.reload} />
      </Card>
      <Card className="space-y-3">
        <h2 className="font-semibold">منح وصول جديد</h2>
        <GrantForm studentId={id} onGranted={detail.reload} />
      </Card>
    </div>
  );
}
