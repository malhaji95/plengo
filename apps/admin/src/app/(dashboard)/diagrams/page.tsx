'use client';

import { Plus } from 'lucide-react';
import Link from 'next/link';
import { useState } from 'react';
import { selectClass } from '@/components/access/scope-picker';
import { DiagramImport } from '@/components/diagrams/diagram-import';
import { FormError } from '@/components/form-error';
import { PlacementPicker, trackIdOf, type Placement } from '@/components/questions/placement-picker';
import { Button } from '@/components/ui/button';
import { Card } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { api, unwrap } from '@/lib/api';
import type { AdminDiagram } from '@/lib/diagrams';
import { freeLabel, STATUS_LABELS } from '@/lib/questions';
import { useLoad } from '@/lib/use-load';

type Status = AdminDiagram['status'] | '';

/** «رسمات العلوم» (v3 §9): filters by placement, status and text; create and bulk import. */
export default function DiagramsPage() {
  const [placement, setPlacement] = useState<Placement>({
    subjectId: null,
    track: 'any',
    unitId: null,
    lessonId: null,
  });
  const [status, setStatus] = useState<Status>('');
  const [q, setQ] = useState('');
  const [cursor, setCursor] = useState<string | undefined>(undefined);
  const [showImport, setShowImport] = useState(false);

  const query = {
    ...(placement.subjectId ? { subjectId: placement.subjectId } : {}),
    ...(placement.track === 'general' ? { generalOnly: 'true' as const } : {}),
    ...(trackIdOf(placement) ? { teacherTrackId: trackIdOf(placement)! } : {}),
    ...(placement.unitId ? { unitId: placement.unitId } : {}),
    ...(placement.lessonId ? { lessonId: placement.lessonId } : {}),
    ...(status ? { status } : {}),
    ...(q.trim() ? { q: q.trim() } : {}),
    ...(cursor ? { cursor } : {}),
  };
  const list = useLoad(
    () => unwrap(api.GET('/api/v1/admin/diagrams', { params: { query } })),
    [JSON.stringify(query)],
  );

  return (
    <div className="mx-auto max-w-6xl space-y-4">
      <div className="flex flex-wrap items-center justify-between gap-2">
        <h1 className="text-xl font-semibold">رسمات العلوم</h1>
        <div className="flex gap-2">
          <Button variant="outline" onClick={() => setShowImport((v) => !v)}>
            استيراد جماعي
          </Button>
          <Button asChild>
            <Link href="/diagrams/new">
              <Plus className="size-4" aria-hidden />
              رسمة جديدة
            </Link>
          </Button>
        </div>
      </div>
      {showImport ? (
        <Card>
          <DiagramImport onDone={() => void list.reload()} />
        </Card>
      ) : null}
      <Card className="space-y-3">
        <PlacementPicker
          value={placement}
          onChange={(p) => {
            setPlacement(p);
            setCursor(undefined);
          }}
          allowAnyTrack
        />
        <div className="flex flex-wrap gap-3">
          <select
            aria-label="الحالة"
            className={`${selectClass} w-40`}
            value={status}
            onChange={(e) => {
              setStatus(e.target.value as Status);
              setCursor(undefined);
            }}
          >
            <option value="">كل الحالات</option>
            {Object.entries(STATUS_LABELS).map(([k, label]) => (
              <option key={k} value={k}>
                {label}
              </option>
            ))}
          </select>
          <Input
            aria-label="بحث"
            placeholder="بحث في العنوان والإجابات"
            className="max-w-xs"
            value={q}
            onChange={(e) => {
              setQ(e.target.value);
              setCursor(undefined);
            }}
          />
        </div>
      </Card>
      <FormError message={list.error} />
      <Card className="overflow-x-auto p-0">
        <table className="w-full text-sm">
          <thead className="border-b border-border text-muted">
            <tr>
              <th className="p-3 text-start font-medium">الرسمة</th>
              <th className="p-3 text-start font-medium">النطاق</th>
              <th className="p-3 text-start font-medium">الأجزاء</th>
              <th className="p-3 text-start font-medium">الحالة</th>
              <th className="p-3 text-start font-medium">الوصول</th>
            </tr>
          </thead>
          <tbody>
            {(list.data?.items ?? []).map((d) => (
              <tr key={d.id} className="border-b border-border last:border-0">
                <td className="p-3">
                  <div className="flex items-center gap-2">
                    {d.image ? (
                      <img
                        src={d.image.thumbUrl}
                        alt=""
                        className="size-10 rounded-md border border-border object-cover"
                      />
                    ) : null}
                    <Link href={`/diagrams/${d.id}`} className="text-brand hover:underline">
                      {d.titleAr}
                    </Link>
                  </div>
                </td>
                <td className="p-3">
                  {d.subjectNameAr}
                  <div className="text-xs text-muted">{d.trackTitleAr ?? 'المحتوى العام'}</div>
                </td>
                <td className="p-3">{d.labels.length}</td>
                <td className="p-3">{STATUS_LABELS[d.status]}</td>
                <td className="p-3">{freeLabel(d)}</td>
              </tr>
            ))}
            {list.data?.items.length === 0 ? (
              <tr>
                <td colSpan={5} className="p-6 text-center text-muted">
                  لا توجد رسمات مطابقة
                </td>
              </tr>
            ) : null}
          </tbody>
        </table>
      </Card>
      <div className="flex items-center justify-between text-sm text-muted">
        <span>{list.data ? `${list.data.totalCount} رسمة` : ''}</span>
        <div className="flex gap-2">
          {cursor ? (
            <Button variant="outline" size="sm" onClick={() => setCursor(undefined)}>
              البداية
            </Button>
          ) : null}
          {list.data?.nextCursor ? (
            <Button variant="outline" size="sm" onClick={() => setCursor(list.data!.nextCursor!)}>
              التالي
            </Button>
          ) : null}
        </div>
      </div>
    </div>
  );
}
