'use client';

import { Plus } from 'lucide-react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { useState } from 'react';
import { selectClass } from '@/components/access/scope-picker';
import { FormError } from '@/components/form-error';
import { PlacementPicker, trackIdOf, type Placement } from '@/components/questions/placement-picker';
import { Button } from '@/components/ui/button';
import { Card } from '@/components/ui/card';
import { Input, Label } from '@/components/ui/input';
import { api, unwrap } from '@/lib/api';
import { freeLabel, MODE_LABELS, STATUS_LABELS, type AdminQuestion } from '@/lib/questions';
import { errorMessage, useLoad } from '@/lib/use-load';

type Status = AdminQuestion['status'] | '';

/** Curated quizzes by subject, scope, unit and lesson (spec §15.1, §26.2). */
export default function QuizzesPage() {
  const router = useRouter();
  const [placement, setPlacement] = useState<Placement>({
    subjectId: null,
    track: 'any',
    unitId: null,
    lessonId: null,
  });
  const [status, setStatus] = useState<Status>('');
  const [title, setTitle] = useState('');
  const [error, setError] = useState<string | null>(null);

  const query = {
    ...(placement.subjectId ? { subjectId: placement.subjectId } : {}),
    ...(placement.track === 'general' ? { generalOnly: 'true' as const } : {}),
    ...(trackIdOf(placement) ? { teacherTrackId: trackIdOf(placement)! } : {}),
    ...(placement.unitId ? { unitId: placement.unitId } : {}),
    ...(placement.lessonId ? { lessonId: placement.lessonId } : {}),
    ...(status ? { status } : {}),
  };
  const quizzes = useLoad(
    () => unwrap(api.GET('/api/v1/admin/quizzes', { params: { query } })),
    [JSON.stringify(query)],
  );

  async function create(e: React.FormEvent) {
    e.preventDefault();
    setError(null);
    try {
      const created = await unwrap(
        api.POST('/api/v1/admin/quizzes', {
          body: {
            subjectId: placement.subjectId!,
            teacherTrackId: trackIdOf(placement),
            unitId: placement.unitId,
            lessonId: placement.lessonId,
            titleAr: title,
          },
        }),
      );
      router.push(`/quizzes/${created.quiz.id}`);
    } catch (err) {
      setError(errorMessage(err));
    }
  }

  return (
    <div className="mx-auto max-w-6xl space-y-4">
      <h1 className="text-xl font-semibold">الاختبارات</h1>
      <Card className="space-y-3">
        <PlacementPicker value={placement} onChange={setPlacement} allowAnyTrack />
        <div className="flex flex-wrap items-end gap-3">
          <select
            aria-label="الحالة"
            className={`${selectClass} w-40`}
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
          <form onSubmit={create} className="flex flex-1 flex-wrap items-end gap-2">
            <div className="min-w-60 flex-1 space-y-1">
              <Label htmlFor="quiz-title">اختبار جديد في الموضع المحدد</Label>
              <Input
                id="quiz-title"
                placeholder="عنوان الاختبار"
                value={title}
                onChange={(e) => setTitle(e.target.value)}
              />
            </div>
            <Button
              type="submit"
              disabled={!title.trim() || !placement.subjectId || placement.track === 'any'}
            >
              <Plus className="size-4" aria-hidden />
              إنشاء
            </Button>
          </form>
        </div>
        {placement.subjectId && placement.track === 'any' ? (
          <p className="text-xs text-muted">
            اختر «المحتوى العام للمادة» أو مساراً لإنشاء اختبار. تُضاف إليه أسئلة من النطاق نفسه فقط.
          </p>
        ) : null}
        <FormError message={error} />
      </Card>
      <FormError message={quizzes.error} />
      <Card className="overflow-x-auto p-0">
        <table className="w-full text-sm">
          <thead className="border-b border-border text-muted">
            <tr>
              <th className="p-3 text-start font-medium">الاختبار</th>
              <th className="p-3 text-start font-medium">النطاق</th>
              <th className="p-3 text-start font-medium">الأسئلة</th>
              <th className="p-3 text-start font-medium">الوضع</th>
              <th className="p-3 text-start font-medium">الحالة</th>
              <th className="p-3 text-start font-medium">الوصول</th>
            </tr>
          </thead>
          <tbody>
            {(quizzes.data ?? []).map((d) => (
              <tr key={d.id} className="border-b border-border last:border-0">
                <td className="p-3">
                  <Link href={`/quizzes/${d.id}`} className="text-brand hover:underline">
                    {d.titleAr}
                  </Link>
                </td>
                <td className="p-3">
                  {d.subjectNameAr}
                  <div className="text-xs text-muted">{d.trackTitleAr ?? 'المحتوى العام'}</div>
                </td>
                <td className="p-3">{d.questionCount}</td>
                <td className="p-3">
                  {MODE_LABELS[d.allowedModes]}
                  {d.isMockExam ? <div className="text-xs text-muted">امتحان تجريبي</div> : null}
                </td>
                <td className="p-3">{STATUS_LABELS[d.status]}</td>
                <td className="p-3">{freeLabel(d)}</td>
              </tr>
            ))}
            {quizzes.data?.length === 0 ? (
              <tr>
                <td colSpan={6} className="p-6 text-center text-muted">
                  لا توجد اختبارات مطابقة
                </td>
              </tr>
            ) : null}
          </tbody>
        </table>
      </Card>
    </div>
  );
}
