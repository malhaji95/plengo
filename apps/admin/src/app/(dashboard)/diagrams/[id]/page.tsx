'use client';

import { ArrowRight } from 'lucide-react';
import Link from 'next/link';
import { useParams, useRouter } from 'next/navigation';
import { useState } from 'react';
import { selectClass } from '@/components/access/scope-picker';
import { DiagramEditor } from '@/components/diagrams/diagram-editor';
import { FormError } from '@/components/form-error';
import { Button } from '@/components/ui/button';
import { Card } from '@/components/ui/card';
import { api, unwrap } from '@/lib/api';
import type { AdminDiagram } from '@/lib/diagrams';
import { freeLabel, STATUS_LABELS } from '@/lib/questions';
import { errorMessage, useLoad } from '@/lib/use-load';

/** One diagram (v3 §9): content, status, free override, delete. `/diagrams/new` creates one. */
export default function DiagramPage() {
  const { id } = useParams<{ id: string }>();
  const router = useRouter();
  const isNew = id === 'new';
  const loaded = useLoad(
    () =>
      isNew
        ? Promise.resolve(null)
        : unwrap(api.GET('/api/v1/admin/diagrams/{id}', { params: { path: { id } } })),
    [id],
  );
  const [error, setError] = useState<string | null>(null);
  const [saved, setSaved] = useState(false);
  const d = loaded.data;

  async function run(call: () => Promise<unknown>) {
    setError(null);
    try {
      await call();
      await loaded.reload();
    } catch (err) {
      setError(errorMessage(err));
    }
  }

  const onSaved = (diagram: AdminDiagram) => {
    if (isNew) router.push(`/diagrams/${diagram.id}`);
    else {
      setSaved(true);
      void loaded.reload();
    }
  };

  return (
    <div className="mx-auto max-w-6xl space-y-4">
      <Link href="/diagrams" className="inline-flex items-center gap-1 text-sm text-brand">
        <ArrowRight className="size-4" aria-hidden />
        كل الرسمات
      </Link>
      <h1 className="text-xl font-semibold">{isNew ? 'رسمة جديدة' : (d?.titleAr ?? '…')}</h1>
      <FormError message={loaded.error ?? error} />
      {d ? (
        <Card className="flex flex-wrap items-center gap-3 text-sm">
          <span>
            الحالة: <strong>{STATUS_LABELS[d.status]}</strong>
          </span>
          {d.status !== 'published' ? (
            <Button
              size="sm"
              onClick={() =>
                void run(() =>
                  unwrap(
                    api.POST('/api/v1/admin/diagrams/{id}/status', {
                      params: { path: { id } },
                      body: { status: 'published' },
                    }),
                  ),
                )
              }
            >
              نشر
            </Button>
          ) : (
            <Button
              size="sm"
              variant="outline"
              onClick={() =>
                void run(() =>
                  unwrap(
                    api.POST('/api/v1/admin/diagrams/{id}/status', {
                      params: { path: { id } },
                      body: { status: 'draft' },
                    }),
                  ),
                )
              }
            >
              إلغاء النشر
            </Button>
          )}
          <span className="ms-4">الوصول: {freeLabel(d)}</span>
          <select
            aria-label="الوصول"
            className={`${selectClass} w-44`}
            value={d.freeSource === 'rule' ? 'rule' : d.isFree ? 'free' : 'paid'}
            onChange={(e) =>
              void run(() =>
                unwrap(
                  api.PUT('/api/v1/admin/diagrams/{id}/free', {
                    params: { path: { id } },
                    body: { mode: e.target.value as 'rule' | 'free' | 'paid' },
                  }),
                ),
              )
            }
          >
            <option value="rule">حسب القاعدة</option>
            <option value="free">مجاني (يدوي)</option>
            <option value="paid">مدفوع (يدوي)</option>
          </select>
          <span className="text-muted">الإصدار {d.contentVersion}</span>
          <Button
            size="sm"
            variant="outline"
            className="ms-auto text-danger"
            onClick={() => {
              if (!window.confirm('حذف هذه الرسمة؟')) return;
              void (async () => {
                try {
                  await unwrap(api.DELETE('/api/v1/admin/diagrams/{id}', { params: { path: { id } } }));
                  router.push('/diagrams');
                } catch (err) {
                  setError(errorMessage(err));
                }
              })();
            }}
          >
            حذف
          </Button>
        </Card>
      ) : null}
      {saved ? <p className="text-sm text-brand">تم الحفظ</p> : null}
      {isNew || d ? (
        <Card>
          <DiagramEditor
            key={d ? `${d.id}:${d.contentVersion}:${d.updatedAt}` : 'new'}
            diagram={d}
            onSaved={onSaved}
          />
        </Card>
      ) : null}
    </div>
  );
}
