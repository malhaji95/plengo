'use client';

import { Flag } from 'lucide-react';
import Link from 'next/link';
import { useState } from 'react';
import { selectClass } from '@/components/access/scope-picker';
import { FormError } from '@/components/form-error';
import { Button } from '@/components/ui/button';
import { Card } from '@/components/ui/card';
import { Label } from '@/components/ui/input';
import { formatDateTime } from '@/lib/access';
import { api, unwrap } from '@/lib/api';
import type { components } from '@/lib/api-schema';
import { errorMessage, useLoad } from '@/lib/use-load';

type Row = components['schemas']['QuestionAnalyticsRow'];
type Detail = components['schemas']['QuestionAnalyticsDetail'];
type Sort = components['schemas']['QuestionAnalyticsSort'];

const SORTS: Record<Sort, string> = {
  attempts: 'الأكثر محاولات',
  correct: 'الأقل صحة',
  reports: 'الأكثر بلاغات',
  mismatches: 'فروق التصحيح دون اتصال',
  recent: 'الأحدث نشاطاً',
};
const TYPE_LABELS: Record<Row['type'], string> = {
  mcq: 'اختيار من متعدد',
  true_false: 'صح/خطأ',
  written: 'كتابي',
};
const REASONS: Record<Detail['flagReasons'][number], string> = {
  low_correct: 'نسبة الإجابات الصحيحة أقل من 20%',
  wrong_option_preferred: 'خيار خاطئ اختير أكثر من الصحيح',
};

const percent = (v: number | null) => (v === null ? '—' : `${v}%`);
const seconds = (ms: number | null) => (ms === null ? '—' : `${Math.round(ms / 100) / 10} ث`);

/**
 * Question analytics (spec §26.2): attempts, accuracy, option spread, average time, open reports and
 * offline grading mismatches. Questions with ≥ 30 attempts and < 20% correct, or a wrong option chosen
 * more than the right one, are flagged until an admin reviews them.
 */
export default function QuestionAnalyticsPage() {
  const subjects = useLoad(() => unwrap(api.GET('/api/v1/admin/subjects', { params: { query: {} } })), []);
  const [subjectId, setSubjectId] = useState('');
  const [flaggedOnly, setFlaggedOnly] = useState(false);
  const [sort, setSort] = useState<Sort>('attempts');
  const [more, setMore] = useState<{ items: Row[]; cursor: string | null } | null>(null);
  const [selected, setSelected] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  const query = {
    sort,
    ...(subjectId ? { subjectId } : {}),
    ...(flaggedOnly ? { flagged: 'true' as const } : {}),
  };
  const page = useLoad(async () => {
    setMore(null);
    return unwrap(api.GET('/api/v1/admin/question-analytics', { params: { query } }));
  }, [subjectId, flaggedOnly, sort]);
  const rows = [...(page.data?.items ?? []), ...(more?.items ?? [])];
  const next = more ? more.cursor : (page.data?.nextCursor ?? null);

  async function loadMore() {
    if (!next) return;
    try {
      const p = await unwrap(
        api.GET('/api/v1/admin/question-analytics', { params: { query: { ...query, cursor: next } } }),
      );
      setMore((m) => ({ items: [...(m?.items ?? []), ...p.items], cursor: p.nextCursor }));
    } catch (err) {
      setError(errorMessage(err));
    }
  }

  return (
    <div className="mx-auto max-w-7xl space-y-4">
      <h1 className="text-xl font-semibold">تحليلات الأسئلة</h1>
      <Card className="grid items-end gap-3 sm:grid-cols-[1fr_14rem_auto]">
        <div className="space-y-1">
          <Label htmlFor="qa-subject">المادة</Label>
          <select
            id="qa-subject"
            className={selectClass}
            value={subjectId}
            onChange={(e) => setSubjectId(e.target.value)}
          >
            <option value="">كل المواد</option>
            {(subjects.data ?? []).map((s) => (
              <option key={s.id} value={s.id}>
                {s.nameAr} ({s.code})
              </option>
            ))}
          </select>
        </div>
        <div className="space-y-1">
          <Label htmlFor="qa-sort">الترتيب</Label>
          <select
            id="qa-sort"
            className={selectClass}
            value={sort}
            onChange={(e) => setSort(e.target.value as Sort)}
          >
            {(Object.keys(SORTS) as Sort[]).map((s) => (
              <option key={s} value={s}>
                {SORTS[s]}
              </option>
            ))}
          </select>
        </div>
        <label className="flex h-10 items-center gap-2 text-sm">
          <input type="checkbox" checked={flaggedOnly} onChange={(e) => setFlaggedOnly(e.target.checked)} />
          المعلَّمة للمراجعة فقط
        </label>
      </Card>
      <FormError message={page.error ?? error} />
      <div className="grid gap-4 lg:grid-cols-[1fr_24rem]">
        <Card className="overflow-x-auto p-0">
          <table className="w-full text-sm">
            <thead className="border-b border-border text-muted">
              <tr>
                <th className="p-3 text-start font-medium">السؤال</th>
                <th className="p-3 text-start font-medium">المحاولات</th>
                <th className="p-3 text-start font-medium">الصحة</th>
                <th className="p-3 text-start font-medium">متوسط الوقت</th>
                <th className="p-3 text-start font-medium">بلاغات</th>
                <th className="p-3 text-start font-medium">فروق</th>
              </tr>
            </thead>
            <tbody>
              {rows.map((r) => (
                <tr
                  key={r.questionId}
                  className={`cursor-pointer border-b border-border last:border-0 hover:bg-surface-muted ${selected === r.questionId ? 'bg-brand/5' : ''}`}
                  onClick={() => setSelected(r.questionId)}
                >
                  <td className="max-w-md p-3">
                    <div className="flex items-start gap-2">
                      {r.flagged ? (
                        <Flag className="mt-0.5 size-4 shrink-0 text-danger" aria-label="معلَّم للمراجعة" />
                      ) : null}
                      <span className="line-clamp-2">{r.questionText}</span>
                    </div>
                    <div className="text-xs text-muted">
                      {TYPE_LABELS[r.type]} · {r.trackTitleAr ?? r.subjectNameAr}
                      {r.status !== 'published' ? ` · ${r.status === 'draft' ? 'مسودة' : 'مؤرشف'}` : ''}
                    </div>
                  </td>
                  <td className="p-3">{r.attempts}</td>
                  <td
                    className={`p-3 ${r.correctPercent !== null && r.correctPercent < 20 ? 'text-danger' : ''}`}
                  >
                    {percent(r.correctPercent)}
                  </td>
                  <td className="p-3">{seconds(r.averageTimeMs)}</td>
                  <td className="p-3">{r.openReports || '—'}</td>
                  <td className="p-3">{r.offlineMismatches || '—'}</td>
                </tr>
              ))}
              {page.data && rows.length === 0 ? (
                <tr>
                  <td colSpan={6} className="p-6 text-center text-muted">
                    لا توجد أسئلة
                  </td>
                </tr>
              ) : null}
            </tbody>
          </table>
          {next ? (
            <div className="p-3">
              <Button variant="outline" size="sm" onClick={() => void loadMore()}>
                عرض المزيد
              </Button>
            </div>
          ) : null}
        </Card>
        {selected ? <QuestionDetail id={selected} onChanged={page.reload} /> : null}
      </div>
    </div>
  );
}

function QuestionDetail({ id, onChanged }: { id: string; onChanged: () => Promise<unknown> }) {
  const detail = useLoad(
    () => unwrap(api.GET('/api/v1/admin/question-analytics/{id}', { params: { path: { id } } })),
    [id],
  );
  const [error, setError] = useState<string | null>(null);
  const d = detail.data;

  async function clearFlag() {
    setError(null);
    try {
      await unwrap(
        api.POST('/api/v1/admin/question-analytics/{id}/clear-flag', { params: { path: { id } } }),
      );
      await Promise.all([detail.reload(), onChanged()]);
    } catch (err) {
      setError(errorMessage(err));
    }
  }

  return (
    <Card className="space-y-3 self-start">
      <FormError message={detail.error ?? error} />
      {d ? (
        <>
          <p className="font-medium">{d.questionText}</p>
          <dl className="grid grid-cols-2 gap-2 text-sm">
            <dt className="text-muted">المحاولات</dt>
            <dd>{d.attempts}</dd>
            <dt className="text-muted">الإجابات الصحيحة</dt>
            <dd>{percent(d.correctPercent)}</dd>
            <dt className="text-muted">متوسط الوقت</dt>
            <dd>{seconds(d.averageTimeMs)}</dd>
            <dt className="text-muted">آخر محاولة</dt>
            <dd>{formatDateTime(d.lastAttemptAt)}</dd>
            <dt className="text-muted">فروق التصحيح دون اتصال</dt>
            <dd>{d.offlineMismatches}</dd>
          </dl>
          {d.options.length ? (
            <div className="space-y-2">
              <h3 className="text-sm font-semibold">توزيع الخيارات</h3>
              {d.options.map((o) => (
                <div key={o.optionId} className="space-y-1">
                  <div className="flex justify-between text-sm">
                    <span className={o.isCorrect ? 'font-medium text-success' : ''}>
                      {o.text}
                      {o.isCorrect ? ' ✓' : ''}
                    </span>
                    <span className="text-muted">
                      {o.count} · {o.percent}%
                    </span>
                  </div>
                  <div className="h-2 rounded bg-surface-muted">
                    <div
                      className={`h-2 rounded ${o.isCorrect ? 'bg-success' : 'bg-danger/70'}`}
                      style={{ width: `${o.percent}%` }}
                    />
                  </div>
                </div>
              ))}
            </div>
          ) : null}
          {d.flagged ? (
            <div className="space-y-2 rounded-lg bg-danger/10 p-3 text-sm">
              <div className="font-medium text-danger">معلَّم للمراجعة</div>
              <ul className="list-inside list-disc">
                {d.flagReasons.map((r) => (
                  <li key={r}>{REASONS[r]}</li>
                ))}
              </ul>
              <Button size="sm" variant="outline" onClick={() => void clearFlag()}>
                تمت المراجعة
              </Button>
            </div>
          ) : null}
          <div className="flex flex-wrap gap-3 text-sm">
            <Link href={`/questions/${d.questionId}`} className="text-brand underline">
              تعديل السؤال
            </Link>
            {d.openReports ? (
              <Link href={`/reports?itemId=${d.questionId}`} className="text-brand underline">
                البلاغات ({d.openReports})
              </Link>
            ) : null}
          </div>
        </>
      ) : null}
    </Card>
  );
}
