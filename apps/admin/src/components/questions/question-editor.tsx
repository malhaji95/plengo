'use client';

import { Plus, Trash2 } from 'lucide-react';
import { useRouter } from 'next/navigation';
import { useEffect, useState } from 'react';
import { selectClass } from '@/components/access/scope-picker';
import { FormError } from '@/components/form-error';
import { Button } from '@/components/ui/button';
import { Card } from '@/components/ui/card';
import { Input, Label } from '@/components/ui/input';
import { api, unwrap } from '@/lib/api';
import { DIFFICULTY_LABELS, TYPE_LABELS, type AdminQuestion, type QuestionType } from '@/lib/questions';
import { errorMessage } from '@/lib/use-load';
import { EMPTY_PLACEMENT, PlacementPicker, trackIdOf, type Placement } from './placement-picker';

type Option = { id?: string; text: string; isCorrect: boolean };

const textareaClass =
  'min-h-24 w-full rounded-lg border border-border bg-surface p-3 text-sm focus-visible:outline-2 focus-visible:outline-brand';

/**
 * Create or edit one question (spec §14). The type, subject and track are fixed once created. Written
 * answers show how the server will normalize them before matching (§14.4).
 */
export function QuestionEditor({
  question,
  initialPlacement,
  onSaved,
}: {
  question?: AdminQuestion;
  initialPlacement?: Placement;
  onSaved?: (q: AdminQuestion) => void;
}) {
  const router = useRouter();
  const [type, setType] = useState<QuestionType>(question?.type ?? 'mcq');
  const [placement, setPlacement] = useState<Placement>(
    question
      ? {
          subjectId: question.subjectId,
          track: question.teacherTrackId ?? 'general',
          unitId: question.unitId,
          lessonId: question.lessonId,
        }
      : (initialPlacement ?? EMPTY_PLACEMENT),
  );
  const [text, setText] = useState(question?.questionText ?? '');
  const [explanation, setExplanation] = useState(question?.explanation ?? '');
  const [difficulty, setDifficulty] = useState<AdminQuestion['difficulty']>(question?.difficulty ?? null);
  const [options, setOptions] = useState<Option[]>(
    question?.type === 'mcq'
      ? question.options.map((o) => ({ id: o.id, text: o.text, isCorrect: o.isCorrect }))
      : [
          { text: '', isCorrect: true },
          { text: '', isCorrect: false },
          { text: '', isCorrect: false },
          { text: '', isCorrect: false },
        ],
  );
  const [tfAnswer, setTfAnswer] = useState<boolean>(
    question?.type === 'true_false' ? (question.options[0]?.isCorrect ?? true) : true,
  );
  const [answers, setAnswers] = useState<string[]>(
    question?.type === 'written' ? question.acceptedAnswers.map((a) => a.answerOriginal) : [''],
  );
  const [normalized, setNormalized] = useState<string[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  // Live preview of the server's normalization (§26.2 "accepted answers with normalized preview").
  useEffect(() => {
    if (type !== 'written') return;
    const filled = answers.filter((a) => a.trim());
    if (!filled.length) {
      setNormalized([]);
      return;
    }
    const timer = setTimeout(async () => {
      try {
        const res = await unwrap(
          api.POST('/api/v1/admin/questions/normalize', { body: { answers: filled } }),
        );
        setNormalized(res.items.map((i) => i.normalized));
      } catch {
        setNormalized([]);
      }
    }, 300);
    return () => clearTimeout(timer);
  }, [answers, type]);

  const contentBody = () => ({
    unitId: placement.unitId,
    lessonId: placement.lessonId,
    questionText: text,
    explanation: explanation.trim() || null,
    difficulty,
    ...(type === 'mcq' ? { options: options.filter((o) => o.text.trim()) } : {}),
    ...(type === 'true_false' ? { trueFalseAnswer: tfAnswer } : {}),
    ...(type === 'written' ? { acceptedAnswers: answers.filter((a) => a.trim()) } : {}),
  });

  /** Arabic hints for the most common mistakes; the server still validates everything. */
  function problem(): string | null {
    if (type === 'mcq') {
      const filled = options.filter((o) => o.text.trim());
      if (filled.length < 2) return 'أضف خيارين على الأقل';
      if (filled.filter((o) => o.isCorrect).length !== 1)
        return 'حدد إجابة صحيحة واحدة من بين الخيارات المكتوبة';
      if (new Set(filled.map((o) => o.text.trim())).size !== filled.length) return 'الخيارات مكررة';
    }
    if (type === 'written') {
      if (!answers.some((a) => a.trim())) return 'أضف إجابة مقبولة واحدة على الأقل';
      const forms = normalized.filter(Boolean);
      if (new Set(forms).size !== forms.length) return 'بعض الإجابات متطابقة بعد التطبيع';
    }
    return null;
  }

  async function save(publish: boolean) {
    const hint = problem();
    if (hint) {
      setError(hint);
      return;
    }
    setBusy(true);
    setError(null);
    try {
      const saved = question
        ? await unwrap(
            api.PATCH('/api/v1/admin/questions/{id}', {
              params: { path: { id: question.id } },
              body: contentBody(),
            }),
          )
        : await unwrap(
            api.POST('/api/v1/admin/questions', {
              body: {
                type,
                subjectId: placement.subjectId!,
                teacherTrackId: trackIdOf(placement),
                ...contentBody(),
                publish,
              },
            }),
          );
      const final =
        question && publish && saved.status !== 'published'
          ? await unwrap(
              api.POST('/api/v1/admin/questions/{id}/status', {
                params: { path: { id: saved.id } },
                body: { status: 'published' },
              }),
            )
          : saved;
      if (question) onSaved?.(final);
      else router.push(`/questions/${final.id}`);
    } catch (err) {
      setError(errorMessage(err));
    } finally {
      setBusy(false);
    }
  }

  const setOption = (i: number, patch: Partial<Option>) =>
    setOptions((all) =>
      all.map((o, j) => (j === i ? { ...o, ...patch } : patch.isCorrect ? { ...o, isCorrect: false } : o)),
    );

  return (
    <Card className="space-y-4">
      {!question ? (
        <div className="space-y-1">
          <Label htmlFor="q-type">نوع السؤال</Label>
          <select
            id="q-type"
            className={`${selectClass} sm:w-64`}
            value={type}
            onChange={(e) => setType(e.target.value as QuestionType)}
          >
            {Object.entries(TYPE_LABELS).map(([k, label]) => (
              <option key={k} value={k}>
                {label}
              </option>
            ))}
          </select>
        </div>
      ) : (
        <p className="text-sm text-muted">{TYPE_LABELS[type]}</p>
      )}

      <PlacementPicker value={placement} onChange={setPlacement} lockScope={!!question} />

      <div className="space-y-1">
        <Label htmlFor="q-text">نص السؤال</Label>
        <textarea
          id="q-text"
          className={textareaClass}
          value={text}
          onChange={(e) => setText(e.target.value)}
        />
      </div>

      {type === 'mcq' ? (
        <fieldset className="space-y-2">
          <legend className="text-sm font-medium">الخيارات (اختر الإجابة الصحيحة)</legend>
          {options.map((o, i) => (
            <div key={o.id ?? `new-${i}`} className="flex items-center gap-2">
              <input
                type="radio"
                name="correct"
                aria-label={`الخيار ${i + 1} صحيح`}
                className="size-4"
                checked={o.isCorrect}
                onChange={() => setOption(i, { isCorrect: true })}
              />
              <Input
                aria-label={`الخيار ${i + 1}`}
                value={o.text}
                onChange={(e) => setOption(i, { text: e.target.value })}
              />
              <Button
                type="button"
                variant="ghost"
                size="sm"
                aria-label="حذف الخيار"
                disabled={options.length <= 2}
                onClick={() => setOptions((all) => all.filter((_, j) => j !== i))}
              >
                <Trash2 className="size-4" aria-hidden />
              </Button>
            </div>
          ))}
          {options.length < 6 ? (
            <Button
              type="button"
              variant="outline"
              size="sm"
              onClick={() => setOptions((all) => [...all, { text: '', isCorrect: false }])}
            >
              <Plus className="size-4" aria-hidden />
              خيار
            </Button>
          ) : null}
        </fieldset>
      ) : null}

      {type === 'true_false' ? (
        <fieldset className="flex gap-6 text-sm">
          <legend className="mb-2 text-sm font-medium">الإجابة الصحيحة</legend>
          <label className="flex items-center gap-2">
            <input
              type="radio"
              name="tf"
              className="size-4"
              checked={tfAnswer}
              onChange={() => setTfAnswer(true)}
            />
            صح
          </label>
          <label className="flex items-center gap-2">
            <input
              type="radio"
              name="tf"
              className="size-4"
              checked={!tfAnswer}
              onChange={() => setTfAnswer(false)}
            />
            خطأ
          </label>
        </fieldset>
      ) : null}

      {type === 'written' ? (
        <fieldset className="space-y-2">
          <legend className="text-sm font-medium">الإجابات المقبولة</legend>
          <p className="text-xs text-muted">
            تُطابَق الإجابة بعد التطبيع (إزالة التشكيل والتطويل وتوحيد الألف والأرقام). لا يُوحَّد «ة/ه» ولا
            «ؤ/ئ/ء» ولا المرادفات؛ أضفها كإجابات منفصلة.
          </p>
          {answers.map((a, i) => {
            const filledIndex = answers.slice(0, i).filter((x) => x.trim()).length;
            return (
              <div key={i} className="flex items-center gap-2">
                <Input
                  aria-label={`الإجابة ${i + 1}`}
                  value={a}
                  onChange={(e) => setAnswers((all) => all.map((x, j) => (j === i ? e.target.value : x)))}
                />
                <span className="w-48 shrink-0 truncate text-xs text-muted" title="الصيغة بعد التطبيع">
                  {a.trim() ? `← ${normalized[filledIndex] ?? '…'}` : ''}
                </span>
                <Button
                  type="button"
                  variant="ghost"
                  size="sm"
                  aria-label="حذف الإجابة"
                  disabled={answers.length <= 1}
                  onClick={() => setAnswers((all) => all.filter((_, j) => j !== i))}
                >
                  <Trash2 className="size-4" aria-hidden />
                </Button>
              </div>
            );
          })}
          {answers.length < 10 ? (
            <Button
              type="button"
              variant="outline"
              size="sm"
              onClick={() => setAnswers((all) => [...all, ''])}
            >
              <Plus className="size-4" aria-hidden />
              إجابة
            </Button>
          ) : null}
        </fieldset>
      ) : null}

      <div className="grid gap-3 sm:grid-cols-[1fr_12rem]">
        <div className="space-y-1">
          <Label htmlFor="q-explanation">الشرح (يظهر بعد الإجابة)</Label>
          <textarea
            id="q-explanation"
            className={textareaClass}
            value={explanation}
            onChange={(e) => setExplanation(e.target.value)}
          />
        </div>
        <div className="space-y-1">
          <Label htmlFor="q-difficulty">الصعوبة</Label>
          <select
            id="q-difficulty"
            className={selectClass}
            value={difficulty ?? ''}
            onChange={(e) => setDifficulty((e.target.value || null) as AdminQuestion['difficulty'])}
          >
            <option value="">غير محددة</option>
            {Object.entries(DIFFICULTY_LABELS).map(([k, label]) => (
              <option key={k} value={k}>
                {label}
              </option>
            ))}
          </select>
        </div>
      </div>

      <FormError message={error} />
      <div className="flex flex-wrap gap-2">
        <Button disabled={busy || !text.trim() || !placement.subjectId} onClick={() => void save(false)}>
          حفظ
        </Button>
        {question?.status !== 'published' ? (
          <Button
            variant="outline"
            disabled={busy || !text.trim() || !placement.subjectId}
            onClick={() => void save(true)}
          >
            حفظ ونشر
          </Button>
        ) : null}
      </div>
    </Card>
  );
}
