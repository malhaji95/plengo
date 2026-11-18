'use client';

import { useState } from 'react';
import { FormError } from '@/components/form-error';
import { Button } from '@/components/ui/button';
import { Card } from '@/components/ui/card';
import { Input, Label } from '@/components/ui/input';
import { formatDateTime } from '@/lib/access';
import { api, unwrap } from '@/lib/api';
import { REASON_LABELS, REDEMPTION_STATUS_LABELS } from '@/lib/loyalty';
import { errorMessage, useLoad } from '@/lib/use-load';

/** A student's loyalty balance, recent point changes and redemptions, with a manual adjustment (v3 §10). */
export function StudentLoyalty({ studentId }: { studentId: string }) {
  const loyalty = useLoad(
    () => unwrap(api.GET('/api/v1/admin/students/{id}/loyalty', { params: { path: { id: studentId } } })),
    [studentId],
  );
  const [delta, setDelta] = useState('');
  const [note, setNote] = useState('');
  const [error, setError] = useState<string | null>(null);
  const valid = /^-?\d+$/.test(delta.trim()) && Number(delta) !== 0 && note.trim().length > 0;

  async function adjust(e: React.FormEvent) {
    e.preventDefault();
    setError(null);
    try {
      await unwrap(
        api.POST('/api/v1/admin/students/{id}/loyalty/adjust', {
          params: { path: { id: studentId } },
          body: { delta: Number(delta), note: note.trim() },
        }),
      );
      setDelta('');
      setNote('');
      await loyalty.reload();
    } catch (err) {
      setError(errorMessage(err));
    }
  }

  const data = loyalty.data;
  return (
    <Card className="space-y-3">
      <h2 className="font-semibold">نقاط الولاء</h2>
      <FormError message={loyalty.error ?? error} />
      {data ? (
        <p className="text-sm">
          الرصيد: <strong dir="ltr">{data.balance}</strong> نقطة · اليوم:{' '}
          <span dir="ltr">{data.earnedToday}</span>
          {data.unlockedDeckIds.length ? ` · ${data.unlockedDeckIds.length} مجموعة مفتوحة بالنقاط` : ''}
        </p>
      ) : null}
      <form onSubmit={adjust} className="flex flex-wrap items-end gap-2">
        <div className="space-y-1">
          <Label htmlFor="loyalty-delta">تعديل (+/−)</Label>
          <Input
            id="loyalty-delta"
            dir="ltr"
            className="w-28"
            placeholder="+50"
            value={delta}
            onChange={(e) => setDelta(e.target.value)}
          />
        </div>
        <div className="min-w-60 flex-1 space-y-1">
          <Label htmlFor="loyalty-note">السبب</Label>
          <Input id="loyalty-note" value={note} onChange={(e) => setNote(e.target.value)} />
        </div>
        <Button type="submit" disabled={!valid}>
          تطبيق
        </Button>
      </form>
      {data?.ledger.length ? (
        <table className="w-full text-sm">
          <thead className="border-b border-border text-muted">
            <tr>
              <th className="p-2 text-start font-medium">التاريخ</th>
              <th className="p-2 text-start font-medium">السبب</th>
              <th className="p-2 text-start font-medium">النقاط</th>
            </tr>
          </thead>
          <tbody>
            {data.ledger.slice(0, 20).map((l) => (
              <tr key={l.id} className="border-b border-border last:border-0">
                <td className="p-2">{formatDateTime(l.createdAt)}</td>
                <td className="p-2">
                  {REASON_LABELS[l.reason]}
                  {l.note ? <span className="text-muted"> · {l.note}</span> : null}
                </td>
                <td className="p-2" dir="ltr">
                  {l.delta > 0 ? `+${l.delta}` : l.delta}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      ) : data ? (
        <p className="text-sm text-muted">لا توجد حركات نقاط</p>
      ) : null}
      {data?.redemptions.length ? (
        <ul className="space-y-1 text-sm">
          {data.redemptions.map((r) => (
            <li key={r.id}>
              {r.titleAr} · <span dir="ltr">{r.costPoints}</span> نقطة · {REDEMPTION_STATUS_LABELS[r.status]}{' '}
              · {formatDateTime(r.createdAt)}
            </li>
          ))}
        </ul>
      ) : null}
    </Card>
  );
}
