'use client';

import { ArrowRight } from 'lucide-react';
import Link from 'next/link';
import { useParams, useRouter } from 'next/navigation';
import { useState } from 'react';
import { selectClass } from '@/components/access/scope-picker';
import { FormError } from '@/components/form-error';
import { QuestionEditor } from '@/components/questions/question-editor';
import { Button } from '@/components/ui/button';
import { Card } from '@/components/ui/card';
import { formatDateTime } from '@/lib/access';
import { api, unwrap } from '@/lib/api';
import { freeLabel, STATUS_LABELS, type AdminQuestion } from '@/lib/questions';
import { errorMessage, useLoad } from '@/lib/use-load';

/** One question: content, status, free override (spec §8.4, §14). */
export default function QuestionPage() {
  const { id } = useParams<{ id: string }>();
  const router = useRouter();
  const question = useLoad(
    () => unwrap(api.GET('/api/v1/admin/questions/{id}', { params: { path: { id } } })),
    [id],
  );
  const [error, setError] = useState<string | null>(null);
  const [saved, setSaved] = useState(false);
  const q = question.data;

  async function run(call: () => Promise<unknown>) {
    setError(null);
    setSaved(false);
    try {
      await call();
      await question.reload();
    } catch (err) {
      setError(errorMessage(err));
    }
  }

  const setStatus = (status: AdminQuestion['status']) =>
    run(() =>
      unwrap(api.POST('/api/v1/admin/questions/{id}/status', { params: { path: { id } }, body: { status } })),
    );

  return (
    <div className="mx-auto max-w-5xl space-y-4">
      <Link href="/questions" className="inline-flex items-center gap-1 text-sm text-brand">
        <ArrowRight className="size-4" aria-hidden />
        كل الأسئلة
      </Link>
      <FormError message={question.error ?? error} />
      {q ? (
        <>
          <Card className="flex flex-wrap items-center justify-between gap-3">
            <div className="space-y-1 text-sm">
              <p>
                <span className="font-semibold">{STATUS_LABELS[q.status]}</span> · {freeLabel(q)} · الإصدار{' '}
                {q.contentVersion}
              </p>
              <p className="text-muted">
                {q.subjectNameAr}
                {q.trackTitleAr ? ` · ${q.trackTitleAr}` : ' · المحتوى العام'} · آخر تعديل{' '}
                {formatDateTime(q.updatedAt)}
              </p>
            </div>
            <div className="flex flex-wrap items-center gap-2">
              {q.status !== 'published' ? (
                <Button onClick={() => void setStatus('published')}>نشر</Button>
              ) : null}
              {q.status === 'published' ? (
                <Button variant="outline" onClick={() => void setStatus('archived')}>
                  أرشفة
                </Button>
              ) : null}
              {q.status === 'archived' ? (
                <Button variant="outline" onClick={() => void setStatus('draft')}>
                  إعادة إلى المسودة
                </Button>
              ) : null}
              <select
                aria-label="الوصول المجاني"
                className={`${selectClass} w-44`}
                value={q.freeSource === 'rule' ? 'rule' : q.isFree ? 'free' : 'paid'}
                onChange={(e) =>
                  void run(() =>
                    unwrap(
                      api.PUT('/api/v1/admin/questions/{id}/free', {
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
                  if (!window.confirm('حذف هذا السؤال؟ تبقى محاولات الطلاب السابقة محفوظة.')) return;
                  void run(async () => {
                    await unwrap(api.DELETE('/api/v1/admin/questions/{id}', { params: { path: { id } } }));
                    router.push('/questions');
                  });
                }}
              >
                حذف
              </Button>
            </div>
          </Card>
          {saved ? <p className="text-sm text-success">تم الحفظ</p> : null}
          <QuestionEditor
            key={`${q.id}-${q.contentVersion}-${q.updatedAt}`}
            question={q}
            onSaved={() => {
              void question.reload();
              setSaved(true);
            }}
          />
        </>
      ) : null}
    </div>
  );
}
