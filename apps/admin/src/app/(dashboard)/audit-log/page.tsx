'use client';

import { useState } from 'react';
import { selectClass } from '@/components/access/scope-picker';
import { FormError } from '@/components/form-error';
import { Button } from '@/components/ui/button';
import { Card } from '@/components/ui/card';
import { Input, Label } from '@/components/ui/input';
import { formatDateTime } from '@/lib/access';
import { api, unwrap } from '@/lib/api';
import type { components } from '@/lib/api-schema';
import { errorMessage, useLoad } from '@/lib/use-load';

type Entry = components['schemas']['AuditLogEntry'];

/** Common action families; the field also accepts any exact action or a prefix ending in ".". */
const ACTION_PRESETS: [string, string][] = [
  ['admin.', 'المشرفون'],
  ['entitlement.', 'صلاحيات الوصول'],
  ['coupon_batch.', 'دفعات الكوبونات'],
  ['free_rule.', 'قواعد المحتوى المجاني'],
  ['promotion.', 'العروض'],
  ['question.', 'الأسئلة'],
  ['deck.', 'مجموعات البطاقات'],
  ['card.', 'البطاقات'],
  ['quiz.', 'الاختبارات'],
  ['structure.', 'البنية التعليمية والمدرسون'],
  ['banner.', 'البانرات'],
  ['notification.', 'الإشعارات'],
  ['report.', 'البلاغات'],
  ['import.', 'الاستيراد'],
  ['settings.', 'الإعدادات'],
];

/** The audit log (spec §32): who did what, when, to which record. */
export default function AuditLogPage() {
  const admins = useLoad(() => unwrap(api.GET('/api/v1/admin/admins')), []);
  const [actorAdminId, setActor] = useState('');
  const [action, setAction] = useState('');
  const [resourceId, setResourceId] = useState('');
  const [from, setFrom] = useState('');
  const [to, setTo] = useState('');
  const [more, setMore] = useState<{ items: Entry[]; cursor: string | null } | null>(null);
  const [open, setOpen] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  const query = {
    ...(actorAdminId ? { actorAdminId } : {}),
    ...(action.trim() ? { action: action.trim() } : {}),
    ...(resourceId.trim() ? { resourceId: resourceId.trim() } : {}),
    ...(from ? { from } : {}),
    ...(to ? { to } : {}),
  };
  const page = useLoad(async () => {
    setMore(null);
    return unwrap(api.GET('/api/v1/admin/audit-logs', { params: { query } }));
  }, [actorAdminId, action, resourceId, from, to]);
  const items = [...(page.data?.items ?? []), ...(more?.items ?? [])];
  const next = more ? more.cursor : (page.data?.nextCursor ?? null);

  async function loadMore() {
    if (!next) return;
    try {
      const p = await unwrap(
        api.GET('/api/v1/admin/audit-logs', { params: { query: { ...query, cursor: next } } }),
      );
      setMore((m) => ({ items: [...(m?.items ?? []), ...p.items], cursor: p.nextCursor }));
    } catch (err) {
      setError(errorMessage(err));
    }
  }

  return (
    <div className="mx-auto max-w-6xl space-y-4">
      <h1 className="text-xl font-semibold">سجل العمليات</h1>
      <Card className="grid gap-3 sm:grid-cols-2 lg:grid-cols-5">
        <div className="space-y-1">
          <Label htmlFor="audit-actor">المشرف</Label>
          <select
            id="audit-actor"
            className={selectClass}
            value={actorAdminId}
            onChange={(e) => setActor(e.target.value)}
          >
            <option value="">الكل</option>
            {(admins.data ?? []).map((a) => (
              <option key={a.id} value={a.id}>
                {a.fullName}
              </option>
            ))}
          </select>
        </div>
        <div className="space-y-1">
          <Label htmlFor="audit-action">العملية</Label>
          <Input
            id="audit-action"
            dir="ltr"
            list="audit-actions"
            placeholder="coupon_batch."
            value={action}
            onChange={(e) => setAction(e.target.value)}
          />
          <datalist id="audit-actions">
            {ACTION_PRESETS.map(([v, label]) => (
              <option key={v} value={v}>
                {label}
              </option>
            ))}
          </datalist>
        </div>
        <div className="space-y-1">
          <Label htmlFor="audit-resource">معرّف السجل</Label>
          <Input
            id="audit-resource"
            dir="ltr"
            value={resourceId}
            onChange={(e) => setResourceId(e.target.value)}
          />
        </div>
        <div className="space-y-1">
          <Label htmlFor="audit-from">من (دمشق)</Label>
          <Input
            id="audit-from"
            type="date"
            dir="ltr"
            value={from}
            onChange={(e) => setFrom(e.target.value)}
          />
        </div>
        <div className="space-y-1">
          <Label htmlFor="audit-to">إلى (دمشق)</Label>
          <Input id="audit-to" type="date" dir="ltr" value={to} onChange={(e) => setTo(e.target.value)} />
        </div>
      </Card>
      <FormError message={page.error ?? error} />
      <Card className="overflow-x-auto p-0">
        <table className="w-full text-sm">
          <thead className="border-b border-border text-muted">
            <tr>
              <th className="p-3 text-start font-medium">الوقت</th>
              <th className="p-3 text-start font-medium">المشرف</th>
              <th className="p-3 text-start font-medium">العملية</th>
              <th className="p-3 text-start font-medium">السجل</th>
              <th className="p-3 text-start font-medium">تفاصيل</th>
            </tr>
          </thead>
          <tbody>
            {items.map((e) => {
              const hasMeta = Object.keys(e.metadata).length > 0;
              return (
                <tr key={e.id} className="border-b border-border align-top last:border-0">
                  <td className="whitespace-nowrap p-3">{formatDateTime(e.createdAt)}</td>
                  <td className="p-3">
                    {e.actorName ?? 'النظام'}
                    {e.actorEmail ? (
                      <div className="text-xs text-muted" dir="ltr">
                        {e.actorEmail}
                      </div>
                    ) : null}
                  </td>
                  <td className="p-3 font-mono text-xs" dir="ltr">
                    {e.action}
                  </td>
                  <td className="p-3">
                    <div>{e.resourceType}</div>
                    {e.resourceId ? (
                      <button
                        type="button"
                        className="font-mono text-xs text-brand"
                        dir="ltr"
                        onClick={() => setResourceId(e.resourceId!)}
                        title="تصفية حسب هذا السجل"
                      >
                        {e.resourceId}
                      </button>
                    ) : null}
                  </td>
                  <td className="p-3">
                    {hasMeta ? (
                      open === e.id ? (
                        <pre
                          className="max-w-sm overflow-x-auto rounded bg-surface-muted p-2 text-xs"
                          dir="ltr"
                        >
                          {JSON.stringify(e.metadata, null, 2)}
                        </pre>
                      ) : (
                        <Button size="sm" variant="ghost" onClick={() => setOpen(e.id)}>
                          عرض
                        </Button>
                      )
                    ) : (
                      '—'
                    )}
                  </td>
                </tr>
              );
            })}
            {page.data && items.length === 0 ? (
              <tr>
                <td colSpan={5} className="p-6 text-center text-muted">
                  لا توجد عمليات
                </td>
              </tr>
            ) : null}
          </tbody>
        </table>
      </Card>
      {next ? (
        <Button variant="outline" onClick={() => void loadMore()}>
          عرض المزيد
        </Button>
      ) : null}
    </div>
  );
}
