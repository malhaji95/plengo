'use client';

import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { useState } from 'react';
import { ScopePicker } from '@/components/access/scope-picker';
import { TermPicker } from '@/components/access/term-picker';
import { FormError } from '@/components/form-error';
import { Button } from '@/components/ui/button';
import { Card } from '@/components/ui/card';
import { Input, Label } from '@/components/ui/input';
import {
  EMPTY_SCOPE,
  formatDate,
  formatDateTime,
  scopeBody,
  scopeLabel,
  scopeReady,
  termBody,
  type ScopeValue,
  type TermValue,
} from '@/lib/access';
import { api, unwrap } from '@/lib/api';
import type { components } from '@/lib/api-schema';
import { errorMessage, useLoad } from '@/lib/use-load';

type Coupon = components['schemas']['AdminCoupon'];

const COUPON_STATUS: Record<string, string> = { active: 'غير مستخدم', redeemed: 'مستخدم', revoked: 'ملغى' };

/** Coupon batches (spec §9.6): generate, follow progress, search codes, watch failures. */
export default function CouponsPage() {
  const batches = useLoad(() => unwrap(api.GET('/api/v1/admin/coupon-batches')), []);
  const failures = useLoad(() => unwrap(api.GET('/api/v1/admin/coupon-failures')), []);

  return (
    <div className="mx-auto max-w-5xl space-y-4">
      <h1 className="text-xl font-semibold">الكوبونات · دفعات الكوبونات</h1>
      <CreateBatch />
      <CouponSearch />

      <Card className="overflow-x-auto p-0">
        <h2 className="p-4 pb-0 font-semibold">الدفعات</h2>
        <FormError message={batches.error} />
        <table className="w-full text-sm">
          <thead className="border-b border-border text-muted">
            <tr>
              <th className="p-3 text-start font-medium">الدفعة</th>
              <th className="p-3 text-start font-medium">النطاق</th>
              <th className="p-3 text-start font-medium">الأكواد</th>
              <th className="p-3 text-start font-medium">المستخدم</th>
              <th className="p-3 text-start font-medium">الحالة</th>
            </tr>
          </thead>
          <tbody>
            {(batches.data ?? []).map((b) => (
              <tr key={b.id} className="border-b border-border last:border-0">
                <td className="p-3">
                  <Link href={`/coupons/${b.id}`} className="text-brand hover:underline">
                    {b.name}
                  </Link>
                  <div className="text-xs text-muted">
                    {b.distributorName ?? 'بدون موزع'} · {formatDate(b.createdAt)}
                  </div>
                </td>
                <td className="p-3">{scopeLabel(b.scope)}</td>
                <td className="p-3">
                  {b.generatedCount < b.quantity ? `${b.generatedCount} / ${b.quantity}` : b.quantity}
                </td>
                <td className="p-3">{b.redeemedCount}</td>
                <td className="p-3">
                  {b.status === 'active' ? 'فعّالة' : <span className="text-danger">ملغاة</span>}
                </td>
              </tr>
            ))}
            {batches.data?.length === 0 ? (
              <tr>
                <td colSpan={5} className="p-6 text-center text-muted">
                  لا توجد دفعات بعد
                </td>
              </tr>
            ) : null}
          </tbody>
        </table>
      </Card>

      <Card className="space-y-3">
        <h2 className="font-semibold">محاولات فاشلة خلال آخر 24 ساعة</h2>
        <FormError message={failures.error} />
        <div className="grid gap-4 md:grid-cols-2">
          <div>
            <h3 className="mb-1 text-sm font-medium">حسب الطالب</h3>
            <ul className="divide-y divide-border text-sm">
              {(failures.data?.users ?? []).map((u) => (
                <li key={u.userId} className="flex justify-between gap-2 py-2">
                  <Link
                    href={`/students/${u.userId}`}
                    dir="ltr"
                    className="truncate text-brand hover:underline"
                  >
                    {u.email ?? u.userId}
                  </Link>
                  <span>
                    {u.failures} · {formatDateTime(u.lastAt)}
                  </span>
                </li>
              ))}
              {failures.data?.users.length === 0 ? <li className="py-2 text-muted">لا شيء</li> : null}
            </ul>
          </div>
          <div>
            <h3 className="mb-1 text-sm font-medium">حسب عنوان IP (مُشفّر)</h3>
            <ul className="divide-y divide-border text-sm">
              {(failures.data?.ips ?? []).map((ip) => (
                <li key={ip.ipHash} className="flex justify-between gap-2 py-2">
                  <span dir="ltr" className="font-mono text-xs">
                    {ip.ipHash.slice(0, 12)}…
                  </span>
                  <span>
                    {ip.failures} · {formatDateTime(ip.lastAt)}
                  </span>
                </li>
              ))}
              {failures.data?.ips.length === 0 ? <li className="py-2 text-muted">لا شيء</li> : null}
            </ul>
          </div>
        </div>
      </Card>
    </div>
  );
}

function CreateBatch() {
  const router = useRouter();
  const [name, setName] = useState('');
  const [distributor, setDistributor] = useState('');
  const [notes, setNotes] = useState('');
  const [quantity, setQuantity] = useState(100);
  const [validFrom, setValidFrom] = useState('');
  const [expiresOn, setExpiresOn] = useState('');
  const [scope, setScope] = useState<ScopeValue>(EMPTY_SCOPE);
  const [term, setTerm] = useState<TermValue>({ kind: 'permanent' });
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    setBusy(true);
    setError(null);
    try {
      const batch = await unwrap(
        api.POST('/api/v1/admin/coupon-batches', {
          body: {
            name,
            distributorName: distributor || null,
            notes: notes || null,
            quantity,
            validFrom: validFrom || null,
            expiresOn: expiresOn || null,
            ...scopeBody(scope),
            ...termBody(term),
          },
        }),
      );
      router.push(`/coupons/${batch.id}`);
    } catch (err) {
      setError(errorMessage(err));
      setBusy(false);
    }
  }

  return (
    <Card>
      <details>
        <summary className="cursor-pointer font-semibold">إنشاء دفعة جديدة</summary>
        <form onSubmit={submit} className="mt-4 space-y-3">
          <div className="grid gap-3 sm:grid-cols-2">
            <div className="space-y-1">
              <Label htmlFor="batch-name">اسم الدفعة</Label>
              <Input id="batch-name" required value={name} onChange={(e) => setName(e.target.value)} />
            </div>
            <div className="space-y-1">
              <Label htmlFor="batch-distributor">الموزع (اختياري)</Label>
              <Input
                id="batch-distributor"
                value={distributor}
                onChange={(e) => setDistributor(e.target.value)}
              />
            </div>
          </div>
          <ScopePicker value={scope} onChange={setScope} />
          <TermPicker value={term} onChange={setTerm} label="مدة الوصول بعد التفعيل" />
          <div className="grid gap-3 sm:grid-cols-3">
            <div className="space-y-1">
              <Label htmlFor="batch-quantity">عدد الأكواد (حتى 5000)</Label>
              <Input
                id="batch-quantity"
                type="number"
                dir="ltr"
                min={1}
                max={5000}
                required
                value={quantity}
                onChange={(e) => setQuantity(Number(e.target.value))}
              />
            </div>
            <div className="space-y-1">
              <Label htmlFor="batch-from">صالح للتفعيل من (اختياري)</Label>
              <Input
                id="batch-from"
                type="date"
                dir="ltr"
                value={validFrom}
                onChange={(e) => setValidFrom(e.target.value)}
              />
            </div>
            <div className="space-y-1">
              <Label htmlFor="batch-until">صالح للتفعيل حتى (اختياري)</Label>
              <Input
                id="batch-until"
                type="date"
                dir="ltr"
                value={expiresOn}
                onChange={(e) => setExpiresOn(e.target.value)}
              />
            </div>
          </div>
          <div className="space-y-1">
            <Label htmlFor="batch-notes">ملاحظات (اختياري)</Label>
            <Input id="batch-notes" value={notes} onChange={(e) => setNotes(e.target.value)} />
          </div>
          <FormError message={error} />
          <Button type="submit" disabled={busy || !name || !scopeReady(scope)}>
            توليد الأكواد
          </Button>
        </form>
      </details>
    </Card>
  );
}

function CouponSearch() {
  const [q, setQ] = useState('');
  const [results, setResults] = useState<Coupon[] | null>(null);
  const [error, setError] = useState<string | null>(null);

  async function search(e: React.FormEvent) {
    e.preventDefault();
    setError(null);
    try {
      setResults(await unwrap(api.GET('/api/v1/admin/coupons', { params: { query: { q } } })));
    } catch (err) {
      setError(errorMessage(err));
      setResults(null);
    }
  }

  return (
    <Card className="space-y-3">
      <form onSubmit={search} className="flex gap-2">
        <Input
          dir="ltr"
          className="font-mono uppercase"
          placeholder="XXXX-XXXX-XX / آخر 4 أحرف"
          aria-label="بحث عن كود"
          value={q}
          onChange={(e) => setQ(e.target.value)}
        />
        <Button type="submit" variant="outline" disabled={q.trim().length < 4}>
          بحث
        </Button>
      </form>
      <FormError message={error} />
      {results ? (
        <ul className="divide-y divide-border text-sm">
          {results.map((c) => (
            <li key={c.id} className="flex flex-wrap justify-between gap-2 py-2">
              <span>
                <span dir="ltr" className="font-mono">
                  …{c.codeLast4}
                </span>{' '}
                ·{' '}
                <Link href={`/coupons/${c.batchId}`} className="text-brand hover:underline">
                  {c.batchName}
                </Link>
              </span>
              <span>
                {COUPON_STATUS[c.status]}
                {c.redeemedByEmail ? (
                  <>
                    {' · '}
                    <Link
                      href={`/students/${c.redeemedByUserId}`}
                      dir="ltr"
                      className="text-brand hover:underline"
                    >
                      {c.redeemedByEmail}
                    </Link>
                  </>
                ) : null}
              </span>
            </li>
          ))}
          {results.length === 0 ? <li className="py-2 text-muted">لا توجد نتائج</li> : null}
        </ul>
      ) : null}
    </Card>
  );
}
