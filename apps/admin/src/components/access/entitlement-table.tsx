'use client';

import { useState } from 'react';
import { FormError } from '@/components/form-error';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import type { components } from '@/lib/api-schema';
import { damascusDate, formatDate, scopeLabel, SOURCE_LABELS, STATE_LABELS, termLabel } from '@/lib/access';
import { api, unwrap } from '@/lib/api';
import { errorMessage } from '@/lib/use-load';

type Entitlement = components['schemas']['AdminEntitlement'];

/** A student's entitlements with extend (new date or permanent) and revoke; both audited. */
export function EntitlementTable({ items, onChanged }: { items: Entitlement[]; onChanged: () => void }) {
  const [editing, setEditing] = useState<string | null>(null);
  const [date, setDate] = useState(damascusDate(30));
  const [error, setError] = useState<string | null>(null);

  async function run(call: () => Promise<unknown>) {
    setError(null);
    try {
      await call();
      setEditing(null);
      onChanged();
    } catch (err) {
      setError(errorMessage(err));
    }
  }

  const extend = (id: string, body: { expiresOn: string } | { makePermanent: true }) =>
    run(() => unwrap(api.POST('/api/v1/admin/entitlements/{id}/extend', { params: { path: { id } }, body })));

  const revoke = (id: string) => {
    const reason = window.prompt('سبب الإلغاء (اختياري)');
    if (reason === null) return;
    void run(() =>
      unwrap(
        api.POST('/api/v1/admin/entitlements/{id}/revoke', {
          params: { path: { id } },
          body: { reason: reason || null },
        }),
      ),
    );
  };

  return (
    <div className="space-y-2">
      <FormError message={error} />
      <div className="overflow-x-auto">
        <table className="w-full text-sm">
          <thead className="border-b border-border text-muted">
            <tr>
              <th className="p-3 text-start font-medium">النطاق</th>
              <th className="p-3 text-start font-medium">المصدر</th>
              <th className="p-3 text-start font-medium">المدة</th>
              <th className="p-3 text-start font-medium">الحالة</th>
              <th className="p-3 text-start font-medium">إجراءات</th>
            </tr>
          </thead>
          <tbody>
            {items.map((e) => {
              const shownState = e.status === 'superseded' ? 'superseded' : e.state;
              const editable = e.status !== 'revoked' && e.status !== 'superseded';
              return (
                <tr key={e.id} className="border-b border-border align-top last:border-0">
                  <td className="p-3">{scopeLabel(e.scope)}</td>
                  <td className="p-3">
                    {SOURCE_LABELS[e.source]}
                    {e.couponLast4 ? (
                      <span dir="ltr" className="ms-1 font-mono text-xs text-muted">
                        …{e.couponLast4}
                      </span>
                    ) : null}
                  </td>
                  <td className="p-3">
                    {termLabel(e)}
                    <div className="text-xs text-muted">منذ {formatDate(e.startsAt)}</div>
                  </td>
                  <td className="p-3">
                    <span className={shownState === 'active' ? 'text-success' : 'text-muted'}>
                      {STATE_LABELS[shownState]}
                    </span>
                    {e.revokeReason ? <div className="text-xs text-muted">{e.revokeReason}</div> : null}
                  </td>
                  <td className="p-3">
                    {editable ? (
                      editing === e.id ? (
                        <div className="flex flex-wrap items-center gap-2">
                          <Input
                            type="date"
                            dir="ltr"
                            className="w-40"
                            aria-label="تاريخ الانتهاء الجديد"
                            min={damascusDate(1)}
                            value={date}
                            onChange={(ev) => setDate(ev.target.value)}
                          />
                          <Button size="sm" onClick={() => void extend(e.id, { expiresOn: date })}>
                            حفظ
                          </Button>
                          {!e.isPermanent ? (
                            <Button
                              size="sm"
                              variant="outline"
                              onClick={() => void extend(e.id, { makePermanent: true })}
                            >
                              جعله دائماً
                            </Button>
                          ) : null}
                          <Button size="sm" variant="ghost" onClick={() => setEditing(null)}>
                            إلغاء
                          </Button>
                        </div>
                      ) : (
                        <div className="flex gap-2">
                          <Button size="sm" variant="outline" onClick={() => setEditing(e.id)}>
                            تمديد
                          </Button>
                          <Button
                            size="sm"
                            variant="ghost"
                            className="text-danger"
                            onClick={() => revoke(e.id)}
                          >
                            إلغاء الوصول
                          </Button>
                        </div>
                      )
                    ) : null}
                  </td>
                </tr>
              );
            })}
            {items.length === 0 ? (
              <tr>
                <td colSpan={5} className="p-6 text-center text-muted">
                  لا توجد صلاحيات
                </td>
              </tr>
            ) : null}
          </tbody>
        </table>
      </div>
    </div>
  );
}
