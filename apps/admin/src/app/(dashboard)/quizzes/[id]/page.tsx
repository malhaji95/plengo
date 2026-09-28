'use client';

import { ArrowDown, ArrowRight, ArrowUp, Plus, Search, Trash2 } from 'lucide-react';
import Link from 'next/link';
import { useParams, useRouter } from 'next/navigation';
import { useState } from 'react';
import { selectClass } from '@/components/access/scope-picker';
import { FormError } from '@/components/form-error';
import { PlacementPicker, type Placement } from '@/components/questions/placement-picker';
import { Button } from '@/components/ui/button';
import { Card } from '@/components/ui/card';
import { Input, Label } from '@/components/ui/input';
import { api, unwrap } from '@/lib/api';
import type { components } from '@/lib/api-schema';
import { freeLabel, MODE_LABELS, STATUS_LABELS, TYPE_LABELS, type AdminQuiz } from '@/lib/questions';
import { errorMessage, useLoad } from '@/lib/use-load';

type QuizQuestion = components['schemas']['AdminQuizQuestion'];
type UpdateQuiz = components['schemas']['UpdateQuizRequest'];

/** One quiz: publishing, free status, settings and its questions (spec §15.1). */
export default function QuizPage() {
  const { id } = useParams<{ id: string }>();
  const router = useRouter();
  const detail = useLoad(
    () => unwrap(api.GET('/api/v1/admin/quizzes/{id}', { params: { path: { id } } })),
    [id],
  );
  const [error, setError] = useState<string | null>(null);

  async function run(call: () => Promise<unknown>) {
    setError(null);
    try {
      await call();
      await detail.reload();
    } catch (err) {
      setError(errorMessage(err));
    }
  }
  const setStatus = (status: AdminQuiz['status']) =>
    run(() =>
      unwrap(api.POST('/api/v1/admin/quizzes/{id}/status', { params: { path: { id } }, body: { status } })),
    );

  const q = detail.data?.quiz;
  return (
    <div className="mx-auto max-w-6xl space-y-4">
      <Link href="/quizzes" className="inline-flex items-center gap-1 text-sm text-brand">
        <ArrowRight className="size-4" aria-hidden />
        كل الاختبارات
      </Link>
      <FormError message={detail.error ?? error} />
      {q && detail.data ? (
        <>
          <Card className="flex flex-wrap items-center justify-between gap-3">
            <div className="space-y-1 text-sm">
              <h1 className="text-xl font-semibold">{q.titleAr}</h1>
              <p>
                <span className="font-semibold">{STATUS_LABELS[q.status]}</span> · {freeLabel(q)} ·{' '}
                {q.questionCount} سؤال منشور · {MODE_LABELS[q.allowedModes]} · الإصدار {q.contentVersion}
              </p>
              <p className="text-muted">
                {q.subjectNameAr}
                {q.trackTitleAr ? ` · ${q.trackTitleAr}` : ' · المحتوى العام'}
              </p>
            </div>
            <div className="flex flex-wrap items-center gap-2">
              {q.status !== 'published' ? (
                <Button onClick={() => void setStatus('published')}>نشر</Button>
              ) : (
                <Button variant="outline" onClick={() => void setStatus('archived')}>
                  أرشفة
                </Button>
              )}
              <select
                aria-label="الوصول المجاني"
                className={`${selectClass} w-44`}
                value={q.freeSource === 'rule' ? 'rule' : q.isFree ? 'free' : 'paid'}
                onChange={(e) =>
                  void run(() =>
                    unwrap(
                      api.PUT('/api/v1/admin/quizzes/{id}/free', {
                        params: { path: { id } },
                        body: { mode: e.target.value as 'rule' | 'free' | 'paid' },
                      }),
                    ),
                  )
                }
              >
                <option value="rule">حسب قاعدة النطاق</option>
                <option value="free">مجاني دائماً</option>
                <option value="paid">مدفوع دائماً</option>
              </select>
              <Button
                variant="ghost"
                className="text-danger"
                onClick={() => {
                  if (!window.confirm('حذف هذا الاختبار؟ تبقى محاولات الطلاب السابقة محفوظة.')) return;
                  void run(async () => {
                    await unwrap(api.DELETE('/api/v1/admin/quizzes/{id}', { params: { path: { id } } }));
                    router.push('/quizzes');
                  });
                }}
              >
                حذف
              </Button>
            </div>
          </Card>
          <QuizSettings key={`${q.id}-${q.contentVersion}`} quiz={q} onSaved={() => void detail.reload()} />
          <QuizQuestions
            key={`q-${q.id}-${q.contentVersion}`}
            quiz={q}
            members={detail.data.questions}
            onSaved={() => void detail.reload()}
          />
        </>
      ) : null}
    </div>
  );
}

const numberOrNull = (v: string) => (v.trim() === '' ? null : Number(v));

function QuizSettings({ quiz, onSaved }: { quiz: AdminQuiz; onSaved: () => void }) {
  const [form, setForm] = useState({
    titleAr: quiz.titleAr,
    description: quiz.description ?? '',
    allowedModes: quiz.allowedModes,
    timeLimitMinutes: quiz.timeLimitSeconds ? String(Math.round(quiz.timeLimitSeconds / 60)) : '',
    passingScorePercent: quiz.passingScorePercent?.toString() ?? '',
    maxAttempts: quiz.maxAttempts?.toString() ?? '',
    shuffleQuestions: quiz.shuffleQuestions,
    shuffleOptions: quiz.shuffleOptions,
    isMockExam: quiz.isMockExam,
    allowOffline: quiz.allowOffline,
  });
  const [placement, setPlacement] = useState<Placement>({
    subjectId: quiz.subjectId,
    track: quiz.teacherTrackId ?? 'general',
    unitId: quiz.unitId,
    lessonId: quiz.lessonId,
  });
  const [error, setError] = useState<string | null>(null);
  const set = <K extends keyof typeof form>(key: K, value: (typeof form)[K]) =>
    setForm((f) => ({ ...f, [key]: value }));

  async function save() {
    setError(null);
    const minutes = numberOrNull(form.timeLimitMinutes);
    const body: UpdateQuiz = {
      titleAr: form.titleAr,
      description: form.description.trim() || null,
      allowedModes: form.allowedModes,
      timeLimitSeconds: minutes === null ? null : minutes * 60,
      passingScorePercent: numberOrNull(form.passingScorePercent),
      maxAttempts: numberOrNull(form.maxAttempts),
      shuffleQuestions: form.shuffleQuestions,
      shuffleOptions: form.shuffleOptions,
      isMockExam: form.isMockExam,
      allowOffline: form.allowOffline,
      unitId: placement.unitId,
      lessonId: placement.lessonId,
    };
    try {
      await unwrap(api.PATCH('/api/v1/admin/quizzes/{id}', { params: { path: { id: quiz.id } }, body }));
      onSaved();
    } catch (err) {
      setError(errorMessage(err));
    }
  }

  const check = (
    key: 'shuffleQuestions' | 'shuffleOptions' | 'isMockExam' | 'allowOffline',
    label: string,
  ) => (
    <label className="flex items-center gap-2 text-sm">
      <input
        type="checkbox"
        checked={form[key]}
        onChange={(e) => {
          const on = e.target.checked;
          // A mock exam is exam-only and, unless changed, stays out of offline packs (§22.2).
          if (key === 'isMockExam' && on)
            setForm((f) => ({ ...f, isMockExam: true, allowedModes: 'exam', allowOffline: false }));
          else set(key, on);
        }}
      />
      {label}
    </label>
  );

  return (
    <Card className="space-y-3">
      <h2 className="font-semibold">الإعدادات</h2>
      <div className="grid gap-3 md:grid-cols-2">
        <div className="space-y-1">
          <Label htmlFor="quiz-title">العنوان</Label>
          <Input id="quiz-title" value={form.titleAr} onChange={(e) => set('titleAr', e.target.value)} />
        </div>
        <div className="space-y-1">
          <Label htmlFor="quiz-description">الوصف</Label>
          <Input
            id="quiz-description"
            value={form.description}
            onChange={(e) => set('description', e.target.value)}
          />
        </div>
        <div className="space-y-1">
          <Label htmlFor="quiz-modes">الأوضاع المسموحة</Label>
          <select
            id="quiz-modes"
            className={selectClass}
            value={form.allowedModes}
            onChange={(e) => set('allowedModes', e.target.value as AdminQuiz['allowedModes'])}
          >
            {Object.entries(MODE_LABELS).map(([k, label]) => (
              <option key={k} value={k}>
                {label}
              </option>
            ))}
          </select>
        </div>
        <div className="space-y-1">
          <Label htmlFor="quiz-time">مدة الامتحان بالدقائق (اختياري)</Label>
          <Input
            id="quiz-time"
            type="number"
            min={1}
            dir="ltr"
            disabled={form.allowedModes === 'practice'}
            value={form.timeLimitMinutes}
            onChange={(e) => set('timeLimitMinutes', e.target.value)}
          />
        </div>
        <div className="space-y-1">
          <Label htmlFor="quiz-pass">علامة النجاح % (اختياري)</Label>
          <Input
            id="quiz-pass"
            type="number"
            min={0}
            max={100}
            dir="ltr"
            value={form.passingScorePercent}
            onChange={(e) => set('passingScorePercent', e.target.value)}
          />
        </div>
        <div className="space-y-1">
          <Label htmlFor="quiz-max">الحد الأقصى للمحاولات (اختياري)</Label>
          <Input
            id="quiz-max"
            type="number"
            min={1}
            dir="ltr"
            value={form.maxAttempts}
            onChange={(e) => set('maxAttempts', e.target.value)}
          />
        </div>
      </div>
      <div className="flex flex-wrap gap-4">
        {check('shuffleQuestions', 'ترتيب عشوائي للأسئلة')}
        {check('shuffleOptions', 'ترتيب عشوائي للخيارات')}
        {check('isMockExam', 'امتحان تجريبي (كل شيء أو لا شيء)')}
        {check('allowOffline', 'متاح ضمن حزم العمل دون اتصال')}
      </div>
      <PlacementPicker value={placement} onChange={setPlacement} lockScope />
      <FormError message={error} />
      <Button disabled={!form.titleAr.trim()} onClick={() => void save()}>
        حفظ الإعدادات
      </Button>
    </Card>
  );
}

type Row = Pick<QuizQuestion, 'id' | 'type' | 'questionText' | 'status' | 'isFree'> & { deleted?: boolean };

/** Membership and order. The picker only offers questions of the quiz's own scope (§15.1.1). */
function QuizQuestions({
  quiz,
  members,
  onSaved,
}: {
  quiz: AdminQuiz;
  members: QuizQuestion[];
  onSaved: () => void;
}) {
  const [rows, setRows] = useState<Row[]>(members);
  const [search, setSearch] = useState('');
  const [query, setQuery] = useState('');
  const [error, setError] = useState<string | null>(null);
  const dirty = rows.map((r) => r.id).join() !== members.map((m) => m.id).join();

  const candidates = useLoad(
    () =>
      unwrap(
        api.GET('/api/v1/admin/questions', {
          params: {
            query: {
              subjectId: quiz.subjectId,
              ...(quiz.teacherTrackId
                ? { teacherTrackId: quiz.teacherTrackId }
                : { generalOnly: 'true' as const }),
              ...(quiz.unitId ? { unitId: quiz.unitId } : {}),
              ...(query ? { q: query } : {}),
              limit: 100,
            },
          },
        }),
      ),
    [quiz.subjectId, quiz.teacherTrackId, quiz.unitId, query],
  );
  const inQuiz = new Set(rows.map((r) => r.id));

  const move = (i: number, delta: number) =>
    setRows((list) => {
      const next = [...list];
      const [moved] = next.splice(i, 1);
      next.splice(i + delta, 0, moved!);
      return next;
    });

  async function save() {
    setError(null);
    try {
      await unwrap(
        api.PUT('/api/v1/admin/quizzes/{id}/questions', {
          params: { path: { id: quiz.id } },
          body: { questionIds: rows.map((r) => r.id) },
        }),
      );
      onSaved();
    } catch (err) {
      setError(errorMessage(err));
    }
  }

  return (
    <div className="grid gap-4 lg:grid-cols-2">
      <Card className="space-y-3">
        <div className="flex items-center justify-between">
          <h2 className="font-semibold">أسئلة الاختبار ({rows.length})</h2>
          <Button disabled={!dirty} onClick={() => void save()}>
            حفظ الأسئلة والترتيب
          </Button>
        </div>
        <FormError message={error} />
        <ol className="space-y-2">
          {rows.map((r, i) => (
            <li key={r.id} className="flex items-start gap-2 rounded-md border border-border p-2 text-sm">
              <span className="w-6 shrink-0 text-muted" dir="ltr">
                {i + 1}
              </span>
              <div className="flex-1">
                <p>{r.questionText}</p>
                <p className="text-xs text-muted">
                  {TYPE_LABELS[r.type]} · {r.deleted ? 'محذوف' : STATUS_LABELS[r.status]} ·{' '}
                  {r.isFree ? 'مجاني' : 'مدفوع'}
                </p>
              </div>
              <Button
                variant="ghost"
                aria-label="تحريك للأعلى"
                disabled={i === 0}
                onClick={() => move(i, -1)}
              >
                <ArrowUp className="size-4" aria-hidden />
              </Button>
              <Button
                variant="ghost"
                aria-label="تحريك للأسفل"
                disabled={i === rows.length - 1}
                onClick={() => move(i, 1)}
              >
                <ArrowDown className="size-4" aria-hidden />
              </Button>
              <Button
                variant="ghost"
                className="text-danger"
                aria-label="إزالة"
                onClick={() => setRows((list) => list.filter((x) => x.id !== r.id))}
              >
                <Trash2 className="size-4" aria-hidden />
              </Button>
            </li>
          ))}
          {rows.length === 0 ? <li className="text-sm text-muted">لم تُضف أسئلة بعد.</li> : null}
        </ol>
      </Card>
      <Card className="space-y-3">
        <h2 className="font-semibold">أسئلة من النطاق نفسه</h2>
        <form
          className="flex gap-2"
          onSubmit={(e) => {
            e.preventDefault();
            setQuery(search.trim());
          }}
        >
          <Input placeholder="بحث في نص السؤال" value={search} onChange={(e) => setSearch(e.target.value)} />
          <Button type="submit" variant="outline" aria-label="بحث">
            <Search className="size-4" aria-hidden />
          </Button>
        </form>
        <FormError message={candidates.error} />
        <ul className="max-h-[32rem] space-y-2 overflow-y-auto">
          {(candidates.data?.items ?? [])
            .filter((c) => !inQuiz.has(c.id) && c.status !== 'archived')
            .map((c) => (
              <li key={c.id} className="flex items-start gap-2 rounded-md border border-border p-2 text-sm">
                <div className="flex-1">
                  <p>{c.questionText}</p>
                  <p className="text-xs text-muted">
                    {TYPE_LABELS[c.type]} · {STATUS_LABELS[c.status]} · {c.isFree ? 'مجاني' : 'مدفوع'}
                  </p>
                </div>
                <Button
                  variant="outline"
                  aria-label="إضافة"
                  onClick={() =>
                    setRows((list) => [
                      ...list,
                      {
                        id: c.id,
                        type: c.type,
                        questionText: c.questionText,
                        status: c.status,
                        isFree: c.isFree,
                      },
                    ])
                  }
                >
                  <Plus className="size-4" aria-hidden />
                </Button>
              </li>
            ))}
        </ul>
      </Card>
    </div>
  );
}
