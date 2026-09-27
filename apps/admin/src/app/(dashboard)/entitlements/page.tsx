'use client';

import Link from 'next/link';
import { useState } from 'react';
import { GrantForm } from '@/components/access/grant-form';
import { FormError } from '@/components/form-error';
import { Card } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { api, unwrap } from '@/lib/api';
import { errorMessage, useLoad } from '@/lib/use-load';

/**
 * Access grants and the access settings (spec §8.3, §26.2). Existing entitlements are managed from
 * each student's page.
 */
export default function EntitlementsPage() {
  const settings = useLoad(() => unwrap(api.GET('/api/v1/admin/settings/access')), []);
  const [settingsError, setSettingsError] = useState<string | null>(null);
  const [q, setQ] = useState('');
  const [query, setQuery] = useState('');
  const [studentId, setStudentId] = useState<string | null>(null);
  const [granted, setGranted] = useState(false);
  const students = useLoad(
    () =>
      query
        ? unwrap(api.GET('/api/v1/admin/students', { params: { query: { q: query } } }))
        : Promise.resolve([]),
    [query],
  );
  const selected = students.data?.find((s) => s.id === studentId);

  async function toggleUpgrade(value: boolean) {
    setSettingsError(null);
    try {
      await unwrap(
        api.PUT('/api/v1/admin/settings/access', { body: { allowTemporaryToPermanentUpgrade: value } }),
      );
      await settings.reload();
    } catch (err) {
      setSettingsError(errorMessage(err));
    }
  }

  return (
    <div className="mx-auto max-w-4xl space-y-4">
      <h1 className="text-xl font-semibold">صلاحيات الوصول</h1>

      <Card className="space-y-3">
        <h2 className="font-semibold">منح وصول لطالب</h2>
        <form
          onSubmit={(e) => {
            e.preventDefault();
            setGranted(false);
            setStudentId(null);
            setQuery(q.trim());
          }}
        >
          <Input
            type="search"
            placeholder="ابحث عن الطالب بالبريد الإلكتروني أو الاسم ثم اضغط Enter"
            aria-label="بحث عن طالب"
            value={q}
            onChange={(e) => setQ(e.target.value)}
          />
        </form>
        <FormError message={students.error} />
        {query && !selected ? (
          <ul className="divide-y divide-border rounded-lg border border-border">
            {(students.data ?? []).map((s) => (
              <li key={s.id}>
                <button
                  type="button"
                  className="flex w-full items-center justify-between p-3 text-start hover:bg-surface-muted"
                  onClick={() => setStudentId(s.id)}
                >
                  <span>{s.fullName}</span>
                  <span dir="ltr" className="text-xs text-muted">
                    {s.email}
                  </span>
                </button>
              </li>
            ))}
            {students.data?.length === 0 ? (
              <li className="p-3 text-sm text-muted">لا يوجد طلاب مطابقون</li>
            ) : null}
          </ul>
        ) : null}
        {selected ? (
          <div className="space-y-3">
            <p className="text-sm">
              الطالب: <strong>{selected.fullName}</strong>{' '}
              <span dir="ltr" className="text-muted">
                {selected.email}
              </span>{' '}
              ·{' '}
              <Link className="text-brand hover:underline" href={`/students/${selected.id}`}>
                صفحة الطالب
              </Link>
            </p>
            <GrantForm studentId={selected.id} onGranted={() => setGranted(true)} />
            {granted ? <p className="text-sm text-success">تم منح الوصول</p> : null}
          </div>
        ) : null}
      </Card>

      <Card className="space-y-2">
        <h2 className="font-semibold">الإعدادات</h2>
        <FormError message={settings.error ?? settingsError} />
        <label className="flex items-start gap-3 text-sm">
          <input
            type="checkbox"
            className="mt-1 size-4"
            checked={settings.data?.allowTemporaryToPermanentUpgrade ?? true}
            disabled={!settings.data}
            onChange={(e) => void toggleUpgrade(e.target.checked)}
          />
          <span>
            السماح بالترقية من وصول مؤقت إلى دائم
            <span className="block text-muted">
              عند تفعيل كود دائم لنطاق لدى الطالب وصول مؤقت فعّال فيه، يُستبدل الوصول المؤقت بوصول دائم
              ويُستهلك الكود.
            </span>
          </span>
        </label>
      </Card>
    </div>
  );
}
