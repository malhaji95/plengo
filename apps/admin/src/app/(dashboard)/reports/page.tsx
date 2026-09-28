'use client';

import Link from 'next/link';
import { useSearchParams } from 'next/navigation';
import { Suspense, useState } from 'react';
import { selectClass } from '@/components/access/scope-picker';
import { FormError } from '@/components/form-error';
import { Button } from '@/components/ui/button';
import { Card } from '@/components/ui/card';
import { Label } from '@/components/ui/input';
import { formatDateTime } from '@/lib/access';
import { api, unwrap } from '@/lib/api';
import { editHref, REASON_LABELS, REPORT_STATUS_LABELS, type AdminReport } from '@/lib/reports';
import { errorMessage, useLoad } from '@/lib/use-load';

type Report = AdminReport;
type Status = Report['status'];
type Reason = Report['reason'];
type ItemType = Report['itemType'];
const STATUS_LABELS = REPORT_STATUS_LABELS;

function ReportsInbox() {
  const params = useSearchParams();
  const itemId = params.get('itemId') ?? undefined;
  const [status, setStatus] = useState<Status | ''>('open');
  const [itemType, setItemType] = useState<ItemType | ''>('');
  const [reason, setReason] = useState<Reason | ''>('');
  const [older, setOlder] = useState<Report[]>([]);
  const [cursor, setCursor] = useState<string | null | undefined>(undefined);
  const [error, setError] = useState<string | null>(null);
  const query = {
    ...(status ? { status } : {}),
    ...(itemType ? { itemType } : {}),
    ...(reason ? { reason } : {}),
    ...(itemId ? { itemId } : {}),
  };
  const page = useLoad(async () => {
    setOlder([]);
    setCursor(undefined);
    return unwrap(api.GET('/api/v1/admin/reports', { params: { query } }));
  }, [status, itemType, reason, itemId]);
  const next = cursor === undefined ? page.data?.nextCursor : cursor;
  const [handled, setHandled] = useState<Record<string, Report>>({});
  const items = [...(page.data?.items ?? []), ...older].map((r) => handled[r.id] ?? r);

  async function more() {
    if (!next) return;
    try {
      const p = await unwrap(
        api.GET('/api/v1/admin/reports', { params: { query: { ...query, cursor: next } } }),
      );
      setOlder((o) => [...o, ...p.items]);
      setCursor(p.nextCursor);
    } catch (err) {
      setError(errorMessage(err));
    }
  }

  return (
    <div className="mx-auto max-w-6xl space-y-4">
      <h1 className="text-xl font-semibold">البلاغات</h1>
      {itemId ? (
        <p className="text-sm">
          بلاغات عنصر واحد ·{' '}
          <Link className="text-brand underline" href="/reports">
            عرض الكل
          </Link>
        </p>
      ) : null}
      <Card className="grid gap-3 sm:grid-cols-3">
        <div className="space-y-1">
          <Label htmlFor="report-status">الحالة</Label>
          <select
            id="report-status"
            className={selectClass}
            value={status}
            onChange={(e) => setStatus(e.target.value as Status | '')}
          >
            <option value="">الكل</option>
            {(Object.keys(STATUS_LABELS) as Status[]).map((s) => (
              <option key={s} value={s}>
                {STATUS_LABELS[s]}
              </option>
            ))}
          </select>
        </div>
        <div className="space-y-1">
          <Label htmlFor="report-type">النوع</Label>
          <select
            id="report-type"
            className={selectClass}
            value={itemType}
            onChange={(e) => setItemType(e.target.value as ItemType | '')}
          >
            <option value="">الكل</option>
            <option value="question">سؤال</option>
            <option value="flashcard">بطاقة</option>
          </select>
        </div>
        <div className="space-y-1">
          <Label htmlFor="report-reason">السبب</Label>
          <select
            id="report-reason"
            className={selectClass}
            value={reason}
            onChange={(e) => setReason(e.target.value as Reason | '')}
          >
            <option value="">الكل</option>
            {(Object.keys(REASON_LABELS) as Reason[]).map((r) => (
              <option key={r} value={r}>
                {REASON_LABELS[r]}
              </option>
            ))}
          </select>
        </div>
      </Card>
      <FormError message={page.error ?? error} />
      <div className="space-y-3">
        {items.map((r) => (
          <ReportCard
            key={r.id}
            report={r}
            onHandled={(updated) => setHandled((h) => ({ ...h, [r.id]: updated }))}
          />
        ))}
        {page.data && items.length === 0 ? (
          <Card className="text-center text-muted">لا توجد بلاغات</Card>
        ) : null}
      </div>
      {next ? (
        <Button variant="outline" onClick={() => void more()}>
          عرض المزيد
        </Button>
      ) : null}
    </div>
  );
}

function ReportCard({ report: r, onHandled }: { report: Report; onHandled: (r: Report) => void }) {
  const [note, setNote] = useState('');
  const [notify, setNotify] = useState(true);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const edit = editHref(r);

  async function resolve(status: 'resolved' | 'dismissed') {
    setBusy(true);
    setError(null);
    try {
      onHandled(
        await unwrap(
          api.POST('/api/v1/admin/reports/{id}/resolve', {
            params: { path: { id: r.id } },
            body: { status, resolutionNote: note.trim() || null, notifyStudent: notify },
          }),
        ),
      );
    } catch (err) {
      setError(errorMessage(err));
    } finally {
      setBusy(false);
    }
  }

  return (
    <Card className="space-y-2">
      <div className="flex flex-wrap items-start justify-between gap-2">
        <div className="min-w-0">
          <div className="font-medium">{r.itemTitleAr ?? (r.itemType === 'question' ? 'سؤال' : 'بطاقة')}</div>
          <div className="text-sm text-muted">
            {r.itemType === 'question' ? 'سؤال' : 'بطاقة'}
            {r.subjectNameAr ? ` · ${r.subjectNameAr}` : ''} · {REASON_LABELS[r.reason]}
            {r.openReportsOnItem > 1 ? ` · ${r.openReportsOnItem} بلاغات مفتوحة على العنصر` : ''}
          </div>
        </div>
        <span
          className={
            r.status === 'open'
              ? 'text-sm text-brand'
              : r.status === 'resolved'
                ? 'text-sm text-success'
                : 'text-sm text-muted'
          }
        >
          {STATUS_LABELS[r.status]}
        </span>
      </div>
      {r.note ? <p className="rounded-lg bg-surface-muted p-2 text-sm">{r.note}</p> : null}
      <div className="text-xs text-muted">
        {r.studentName} · <span dir="ltr">{r.studentEmail}</span> · {formatDateTime(r.createdAt)}
      </div>
      {r.status !== 'open' && r.resolutionNote ? (
        <p className="text-sm">
          <span className="text-muted">ملاحظة المعالجة: </span>
          {r.resolutionNote}
        </p>
      ) : null}
      <div className="flex flex-wrap items-center gap-2">
        {edit ? (
          <Link href={edit} className="text-sm text-brand underline">
            فتح للتعديل
          </Link>
        ) : null}
        {r.status === 'open' ? (
          <>
            <input
              aria-label="ملاحظة المعالجة"
              placeholder="ملاحظة (اختيارية)"
              className="h-9 min-w-48 flex-1 rounded-lg border border-border bg-surface px-3 text-sm"
              value={note}
              onChange={(e) => setNote(e.target.value)}
            />
            <label className="flex items-center gap-1 text-sm">
              <input type="checkbox" checked={notify} onChange={(e) => setNotify(e.target.checked)} />
              إشعار الطالب
            </label>
            <Button size="sm" disabled={busy} onClick={() => void resolve('resolved')}>
              تمت المعالجة
            </Button>
            <Button size="sm" variant="outline" disabled={busy} onClick={() => void resolve('dismissed')}>
              رفض
            </Button>
          </>
        ) : null}
      </div>
      <FormError message={error} />
    </Card>
  );
}

/** Content problem reports (spec §21): filters, jump to edit, resolve or dismiss. */
export default function ReportsPage() {
  return (
    <Suspense>
      <ReportsInbox />
    </Suspense>
  );
}
