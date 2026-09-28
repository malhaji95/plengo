'use client';

import { useState } from 'react';
import { selectClass } from '@/components/access/scope-picker';
import { FormError } from '@/components/form-error';
import { Button } from '@/components/ui/button';
import { Card } from '@/components/ui/card';
import { Input, Label } from '@/components/ui/input';
import { formatDate } from '@/lib/access';
import { api, unwrap } from '@/lib/api';
import { errorMessage, useLoad } from '@/lib/use-load';

/**
 * Exam countdowns (spec §19.3): one date per education level; the Home tab shows the nearest active
 * one for the student's level until the exam day passes.
 */
export default function CountdownsPage() {
  const countdowns = useLoad(() => unwrap(api.GET('/api/v1/admin/countdowns')), []);
  const levels = useLoad(() => unwrap(api.GET('/api/v1/admin/levels')), []);
  const [levelId, setLevelId] = useState('');
  const [title, setTitle] = useState('');
  const [examDate, setExamDate] = useState('');
  const [error, setError] = useState<string | null>(null);
  const levelName = (id: string) => levels.data?.find((l) => l.id === id)?.nameAr ?? '—';

  async function run(call: () => Promise<unknown>) {
    setError(null);
    try {
      await call();
      await countdowns.reload();
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
        api.POST('/api/v1/admin/countdowns', {
          body: { educationLevelId: levelId, titleAr: title, examDate },
        }),
      ),
    );
    if (ok) {
      setTitle('');
      setExamDate('');
    }
  }

  return (
    <div className="mx-auto max-w-4xl space-y-4">
      <h1 className="text-xl font-semibold">العد التنازلي للامتحانات</h1>
      <Card>
        <form onSubmit={create} className="space-y-3">
          <h2 className="font-semibold">موعد امتحان جديد</h2>
          <div className="grid gap-3 sm:grid-cols-3">
            <div className="space-y-1">
              <Label htmlFor="countdown-level">المرحلة</Label>
              <select
                id="countdown-level"
                className={selectClass}
                required
                value={levelId}
                onChange={(e) => setLevelId(e.target.value)}
              >
                <option value="">اختر المرحلة</option>
                {(levels.data ?? []).map((l) => (
                  <option key={l.id} value={l.id}>
                    {l.nameAr}
                  </option>
                ))}
              </select>
            </div>
            <div className="space-y-1">
              <Label htmlFor="countdown-title">العنوان</Label>
              <Input
                id="countdown-title"
                required
                placeholder="امتحانات الشهادة الثانوية"
                value={title}
                onChange={(e) => setTitle(e.target.value)}
              />
            </div>
            <div className="space-y-1">
              <Label htmlFor="countdown-date">تاريخ الامتحان</Label>
              <Input
                id="countdown-date"
                type="date"
                dir="ltr"
                required
                value={examDate}
                onChange={(e) => setExamDate(e.target.value)}
              />
            </div>
          </div>
          <Button type="submit" disabled={!levelId || !title || !examDate}>
            إضافة
          </Button>
        </form>
      </Card>
      <FormError message={countdowns.error ?? error} />
      <Card className="overflow-x-auto p-0">
        <table className="w-full text-sm">
          <thead className="border-b border-border text-muted">
            <tr>
              <th className="p-3 text-start font-medium">المرحلة</th>
              <th className="p-3 text-start font-medium">العنوان</th>
              <th className="p-3 text-start font-medium">التاريخ</th>
              <th className="p-3 text-start font-medium">المتبقي</th>
              <th className="p-3 text-start font-medium">إجراءات</th>
            </tr>
          </thead>
          <tbody>
            {(countdowns.data ?? []).map((c) => (
              <tr key={c.id} className="border-b border-border last:border-0">
                <td className="p-3">{levelName(c.educationLevelId)}</td>
                <td className="p-3">{c.titleAr}</td>
                <td className="p-3">{formatDate(`${c.examDate}T12:00:00Z`)}</td>
                <td className="p-3">
                  {c.daysLeft < 0 ? (
                    <span className="text-muted">انتهى</span>
                  ) : (
                    <span className={c.isActive ? 'text-success' : 'text-muted'}>
                      {c.daysLeft} يوم{c.isActive ? '' : ' (معطّل)'}
                    </span>
                  )}
                </td>
                <td className="p-3">
                  <div className="flex gap-2">
                    <Button
                      size="sm"
                      variant="outline"
                      onClick={() =>
                        void run(() =>
                          unwrap(
                            api.PATCH('/api/v1/admin/countdowns/{id}', {
                              params: { path: { id: c.id } },
                              body: { isActive: !c.isActive },
                            }),
                          ),
                        )
                      }
                    >
                      {c.isActive ? 'تعطيل' : 'تفعيل'}
                    </Button>
                    <Button
                      size="sm"
                      variant="ghost"
                      className="text-danger"
                      onClick={() => {
                        if (window.confirm('حذف موعد الامتحان؟'))
                          void run(() =>
                            unwrap(
                              api.DELETE('/api/v1/admin/countdowns/{id}', { params: { path: { id: c.id } } }),
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
            {countdowns.data?.length === 0 ? (
              <tr>
                <td colSpan={5} className="p-6 text-center text-muted">
                  لا توجد مواعيد
                </td>
              </tr>
            ) : null}
          </tbody>
        </table>
      </Card>
    </div>
  );
}
