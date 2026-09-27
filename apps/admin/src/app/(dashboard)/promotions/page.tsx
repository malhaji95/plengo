'use client';

import { useState } from 'react';
import { ScopePicker } from '@/components/access/scope-picker';
import { FormError } from '@/components/form-error';
import { Button } from '@/components/ui/button';
import { Card } from '@/components/ui/card';
import { Input, Label } from '@/components/ui/input';
import {
  EMPTY_SCOPE,
  formatDateTime,
  scopeBody,
  scopeLabel,
  scopeReady,
  type ScopeValue,
} from '@/lib/access';
import { api, unwrap } from '@/lib/api';
import { errorMessage, useLoad } from '@/lib/use-load';

const STATE: Record<string, string> = {
  scheduled: 'مجدول',
  running: 'جارٍ الآن',
  ended: 'انتهى',
  disabled: 'معطّل',
};

/** A datetime-local value (Damascus wall clock) → ISO instant. Damascus is UTC+3 all year. */
const damascusToIso = (local: string) => new Date(`${local}:00+03:00`).toISOString();

/**
 * Temporary free access to a whole scope for every student (spec §8.5). No entitlements are created;
 * access ends by itself when the promotion ends.
 */
export default function PromotionsPage() {
  const promotions = useLoad(() => unwrap(api.GET('/api/v1/admin/promotions')), []);
  const [scope, setScope] = useState<ScopeValue>(EMPTY_SCOPE);
  const [title, setTitle] = useState('');
  const [startsAt, setStartsAt] = useState('');
  const [endsAt, setEndsAt] = useState('');
  const [error, setError] = useState<string | null>(null);

  async function run(call: () => Promise<unknown>) {
    setError(null);
    try {
      await call();
      await promotions.reload();
      return true;
    } catch (err) {
      setError(errorMessage(err));
      return false;
    }
  }

  async function create(e: React.FormEvent) {
    e.preventDefault();
    const ok = await run(() =>
      unwrap(
        api.POST('/api/v1/admin/promotions', {
          body: {
            ...scopeBody(scope),
            titleAr: title,
            startsAt: damascusToIso(startsAt),
            endsAt: damascusToIso(endsAt),
          },
        }),
      ),
    );
    if (ok) {
      setTitle('');
      setScope(EMPTY_SCOPE);
    }
  }

  return (
    <div className="mx-auto max-w-5xl space-y-4">
      <h1 className="text-xl font-semibold">العروض المؤقتة</h1>
      <Card>
        <form onSubmit={create} className="space-y-3">
          <h2 className="font-semibold">عرض جديد</h2>
          <div className="space-y-1">
            <Label htmlFor="promo-title">العنوان</Label>
            <Input id="promo-title" required value={title} onChange={(e) => setTitle(e.target.value)} />
          </div>
          <ScopePicker value={scope} onChange={setScope} />
          <div className="grid gap-3 sm:grid-cols-2">
            <div className="space-y-1">
              <Label htmlFor="promo-start">يبدأ (بتوقيت دمشق)</Label>
              <Input
                id="promo-start"
                type="datetime-local"
                dir="ltr"
                required
                value={startsAt}
                onChange={(e) => setStartsAt(e.target.value)}
              />
            </div>
            <div className="space-y-1">
              <Label htmlFor="promo-end">ينتهي (بتوقيت دمشق)</Label>
              <Input
                id="promo-end"
                type="datetime-local"
                dir="ltr"
                required
                value={endsAt}
                onChange={(e) => setEndsAt(e.target.value)}
              />
            </div>
          </div>
          <Button type="submit" disabled={!title || !startsAt || !endsAt || !scopeReady(scope)}>
            إنشاء العرض
          </Button>
        </form>
      </Card>
      <FormError message={promotions.error ?? error} />
      <Card className="overflow-x-auto p-0">
        <table className="w-full text-sm">
          <thead className="border-b border-border text-muted">
            <tr>
              <th className="p-3 text-start font-medium">العرض</th>
              <th className="p-3 text-start font-medium">النطاق</th>
              <th className="p-3 text-start font-medium">الفترة</th>
              <th className="p-3 text-start font-medium">الحالة</th>
              <th className="p-3 text-start font-medium">إجراءات</th>
            </tr>
          </thead>
          <tbody>
            {(promotions.data ?? []).map((p) => (
              <tr key={p.id} className="border-b border-border last:border-0">
                <td className="p-3">{p.titleAr}</td>
                <td className="p-3">{scopeLabel(p.scope)}</td>
                <td className="p-3">
                  {formatDateTime(p.startsAt)}
                  <div className="text-muted">← {formatDateTime(p.endsAt)}</div>
                </td>
                <td className="p-3">
                  <span className={p.state === 'running' ? 'text-success' : 'text-muted'}>
                    {STATE[p.state]}
                  </span>
                </td>
                <td className="p-3">
                  <div className="flex gap-2">
                    <Button
                      size="sm"
                      variant="outline"
                      onClick={() =>
                        void run(() =>
                          unwrap(
                            api.PATCH('/api/v1/admin/promotions/{id}', {
                              params: { path: { id: p.id } },
                              body: { isActive: !p.isActive },
                            }),
                          ),
                        )
                      }
                    >
                      {p.isActive ? 'تعطيل' : 'تفعيل'}
                    </Button>
                    <Button
                      size="sm"
                      variant="ghost"
                      className="text-danger"
                      onClick={() => {
                        if (window.confirm('حذف هذا العرض؟'))
                          void run(() =>
                            unwrap(
                              api.DELETE('/api/v1/admin/promotions/{id}', { params: { path: { id: p.id } } }),
                            ),
                          );
                      }}
                    >
                      حذف
                    </Button>
                  </div>
                </td>
              </tr>
            ))}
            {promotions.data?.length === 0 ? (
              <tr>
                <td colSpan={5} className="p-6 text-center text-muted">
                  لا توجد عروض
                </td>
              </tr>
            ) : null}
          </tbody>
        </table>
      </Card>
    </div>
  );
}
