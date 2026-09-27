'use client';

import { ArrowDown, ArrowUp, Plus } from 'lucide-react';
import Link from 'next/link';
import { useEffect, useState } from 'react';
import { selectClass } from '@/components/access/scope-picker';
import { FormError } from '@/components/form-error';
import { PlacementPicker, trackIdOf, type Placement } from '@/components/questions/placement-picker';
import { Button } from '@/components/ui/button';
import { Card } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { api, unwrap } from '@/lib/api';
import { freeLabel, STATUS_LABELS, TYPE_LABELS, type AdminQuestion } from '@/lib/questions';
import { errorMessage } from '@/lib/use-load';

type Status = AdminQuestion['status'] | '';
type Type = AdminQuestion['type'] | '';

/**
 * Questions by subject, scope, unit and lesson (spec §26.2). With a lesson selected and no other
 * filter, the list is that lesson's full order and can be rearranged.
 */
export default function QuestionsPage() {
  const [placement, setPlacement] = useState<Placement>({
    subjectId: null,
    track: 'any',
    unitId: null,
    lessonId: null,
  });
  const [status, setStatus] = useState<Status>('');
  const [type, setType] = useState<Type>('');
  const [q, setQ] = useState('');
  const [search, setSearch] = useState('');
  const [items, setItems] = useState<AdminQuestion[]>([]);
  const [total, setTotal] = useState(0);
  const [cursor, setCursor] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  const query = {
    ...(placement.subjectId ? { subjectId: placement.subjectId } : {}),
    ...(placement.track === 'general' ? { generalOnly: 'true' as const } : {}),
    ...(trackIdOf(placement) ? { teacherTrackId: trackIdOf(placement)! } : {}),
    ...(placement.unitId ? { unitId: placement.unitId } : {}),
    ...(placement.lessonId ? { lessonId: placement.lessonId } : {}),
    ...(status ? { status } : {}),
    ...(type ? { type } : {}),
    ...(search ? { q: search } : {}),
  };
  const key = JSON.stringify(query);

  async function load(after: string | null) {
    setLoading(true);
    setError(null);
    try {
      const page = await unwrap(
        api.GET('/api/v1/admin/questions', {
          params: { query: { ...query, limit: 50, ...(after ? { cursor: after } : {}) } },
        }),
      );
      setItems((prev) => (after ? [...prev, ...page.items] : page.items));
      setTotal(page.totalCount);
      setCursor(page.nextCursor);
    } catch (err) {
      setError(errorMessage(err));
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    void load(null);
  }, [key]);

  const canReorder =
    !!placement.lessonId && placement.track !== 'any' && !status && !type && !search && !cursor;

  async function move(index: number, delta: number) {
    const next = [...items];
    const [moved] = next.splice(index, 1);
    next.splice(index + delta, 0, moved!);
    setItems(next);
    try {
      await unwrap(api.POST('/api/v1/admin/questions/reorder', { body: { ids: next.map((i) => i.id) } }));
    } catch (err) {
      setError(errorMessage(err));
      void load(null);
    }
  }

  const newHref = `/questions/new?${new URLSearchParams({
    ...(placement.subjectId ? { subjectId: placement.subjectId } : {}),
    ...(placement.track !== 'any' ? { track: placement.track } : {}),
    ...(placement.unitId ? { unitId: placement.unitId } : {}),
    ...(placement.lessonId ? { lessonId: placement.lessonId } : {}),
  }).toString()}`;

  return (
    <div className="mx-auto max-w-6xl space-y-4">
      <div className="flex items-center justify-between">
        <h1 className="text-xl font-semibold">الأسئلة</h1>
        <Button asChild>
          <Link href={newHref}>
            <Plus className="size-4" aria-hidden />
            سؤال جديد
          </Link>
        </Button>
      </div>
      <Card className="space-y-3">
        <PlacementPicker value={placement} onChange={setPlacement} allowAnyTrack />
        <div className="grid gap-3 sm:grid-cols-[10rem_12rem_1fr]">
          <select
            aria-label="الحالة"
            className={selectClass}
            value={status}
            onChange={(e) => setStatus(e.target.value as Status)}
          >
            <option value="">كل الحالات</option>
            {Object.entries(STATUS_LABELS).map(([k, label]) => (
              <option key={k} value={k}>
                {label}
              </option>
            ))}
          </select>
          <select
            aria-label="النوع"
            className={selectClass}
            value={type}
            onChange={(e) => setType(e.target.value as Type)}
          >
            <option value="">كل الأنواع</option>
            {Object.entries(TYPE_LABELS).map(([k, label]) => (
              <option key={k} value={k}>
                {label}
              </option>
            ))}
          </select>
          <form
            onSubmit={(e) => {
              e.preventDefault();
              setSearch(q.trim());
            }}
          >
            <Input
              type="search"
              placeholder="ابحث في نص السؤال"
              aria-label="بحث"
              value={q}
              onChange={(e) => setQ(e.target.value)}
            />
          </form>
        </div>
      </Card>
      <FormError message={error} />
      <p className="text-sm text-muted">
        {total} سؤال{canReorder ? ' · استخدم الأسهم لترتيب أسئلة هذا الدرس' : ''}
      </p>
      <Card className="overflow-x-auto p-0">
        <table className="w-full text-sm">
          <thead className="border-b border-border text-muted">
            <tr>
              {canReorder ? <th className="w-20 p-3" /> : null}
              <th className="p-3 text-start font-medium">السؤال</th>
              <th className="p-3 text-start font-medium">النوع</th>
              <th className="p-3 text-start font-medium">النطاق</th>
              <th className="p-3 text-start font-medium">الحالة</th>
              <th className="p-3 text-start font-medium">الوصول</th>
            </tr>
          </thead>
          <tbody>
            {items.map((item, i) => (
              <tr key={item.id} className="border-b border-border last:border-0">
                {canReorder ? (
                  <td className="p-3">
                    <div className="flex gap-1">
                      <Button
                        size="sm"
                        variant="ghost"
                        aria-label="أعلى"
                        disabled={i === 0}
                        onClick={() => void move(i, -1)}
                      >
                        <ArrowUp className="size-4" aria-hidden />
                      </Button>
                      <Button
                        size="sm"
                        variant="ghost"
                        aria-label="أسفل"
                        disabled={i === items.length - 1}
                        onClick={() => void move(i, 1)}
                      >
                        <ArrowDown className="size-4" aria-hidden />
                      </Button>
                    </div>
                  </td>
                ) : null}
                <td className="max-w-md p-3">
                  <Link href={`/questions/${item.id}`} className="line-clamp-2 text-brand hover:underline">
                    {item.questionText}
                  </Link>
                </td>
                <td className="p-3">{TYPE_LABELS[item.type]}</td>
                <td className="p-3">
                  {item.subjectNameAr}
                  <div className="text-xs text-muted">{item.trackTitleAr ?? 'المحتوى العام'}</div>
                </td>
                <td className="p-3">{STATUS_LABELS[item.status]}</td>
                <td className="p-3">{freeLabel(item)}</td>
              </tr>
            ))}
            {!loading && items.length === 0 ? (
              <tr>
                <td colSpan={6} className="p-6 text-center text-muted">
                  لا توجد أسئلة مطابقة
                </td>
              </tr>
            ) : null}
          </tbody>
        </table>
      </Card>
      {cursor ? (
        <Button variant="outline" disabled={loading} onClick={() => void load(cursor)}>
          عرض المزيد
        </Button>
      ) : null}
    </div>
  );
}
