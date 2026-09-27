'use client';

import { ArrowRight } from 'lucide-react';
import Link from 'next/link';
import { useParams } from 'next/navigation';
import { useState } from 'react';
import { EntityList } from '@/components/entity-list';
import { FormError } from '@/components/form-error';
import { Button } from '@/components/ui/button';
import { Card } from '@/components/ui/card';
import { Input, Label } from '@/components/ui/input';
import { api, unwrap } from '@/lib/api';
import { errorMessage, useLoad } from '@/lib/use-load';

const LOOSE = 'loose';

/** One subject: its details, its optional units and their lessons (spec §6). */
export default function SubjectPage() {
  const { id } = useParams<{ id: string }>();
  const subject = useLoad(
    () => unwrap(api.GET('/api/v1/admin/subjects/{id}', { params: { path: { id } } })),
    [id],
  );
  const units = useLoad(
    () => unwrap(api.GET('/api/v1/admin/units', { params: { query: { subjectId: id } } })),
    [id],
  );
  const [unitId, setUnitId] = useState<string>(LOOSE);
  const lessons = useLoad(
    () => unwrap(api.GET('/api/v1/admin/lessons', { params: { query: { subjectId: id } } })),
    [id],
  );
  const shownLessons = (lessons.data ?? []).filter((l) =>
    unitId === LOOSE ? l.unitId === null : l.unitId === unitId,
  );
  const unitName = units.data?.find((u) => u.id === unitId)?.titleAr;

  return (
    <div className="mx-auto max-w-5xl space-y-4">
      <Link href="/subjects" className="inline-flex items-center gap-1 text-sm text-brand">
        <ArrowRight className="size-4" aria-hidden />
        كل المواد
      </Link>
      <FormError message={subject.error ?? units.error ?? lessons.error} />
      {subject.data ? <SubjectDetails subject={subject.data} onSaved={subject.reload} /> : null}

      <div className="grid gap-4 lg:grid-cols-2">
        <EntityList
          title="الوحدات"
          items={(units.data ?? []).map((u) => ({ id: u.id, code: u.code, name: u.titleAr }))}
          selectedId={unitId}
          onSelect={setUnitId}
          onCreate={(v) =>
            unwrap(
              api.POST('/api/v1/admin/units', { body: { subjectId: id, code: v.code, titleAr: v.name } }),
            )
          }
          onUpdate={(uid, v) =>
            unwrap(
              api.PATCH('/api/v1/admin/units/{id}', {
                params: { path: { id: uid } },
                body: { ...(v.code ? { code: v.code } : {}), ...(v.name ? { titleAr: v.name } : {}) },
              }),
            )
          }
          onDelete={async (uid) => {
            await unwrap(api.DELETE('/api/v1/admin/units/{id}', { params: { path: { id: uid } } }));
            if (uid === unitId) setUnitId(LOOSE);
          }}
          onReorder={(ids) => unwrap(api.PUT('/api/v1/admin/units/reorder', { body: { ids } }))}
          onChanged={units.reload}
          emptyText="لا توجد وحدات — الوحدات اختيارية"
        />
        <div className="space-y-2">
          <div className="flex items-center gap-2 text-sm">
            <Button
              size="sm"
              variant={unitId === LOOSE ? 'default' : 'outline'}
              onClick={() => setUnitId(LOOSE)}
            >
              دروس بلا وحدة
            </Button>
            {unitName ? <span className="text-muted">دروس الوحدة: {unitName}</span> : null}
          </div>
          <EntityList
            title={unitId === LOOSE ? 'الدروس المباشرة' : `دروس ${unitName ?? ''}`}
            items={shownLessons.map((l) => ({ id: l.id, code: l.code, name: l.titleAr }))}
            onCreate={(v) =>
              unwrap(
                api.POST('/api/v1/admin/lessons', {
                  body: {
                    subjectId: id,
                    unitId: unitId === LOOSE ? null : unitId,
                    code: v.code,
                    titleAr: v.name,
                  },
                }),
              )
            }
            onUpdate={(lid, v) =>
              unwrap(
                api.PATCH('/api/v1/admin/lessons/{id}', {
                  params: { path: { id: lid } },
                  body: { ...(v.code ? { code: v.code } : {}), ...(v.name ? { titleAr: v.name } : {}) },
                }),
              )
            }
            onDelete={(lid) =>
              unwrap(api.DELETE('/api/v1/admin/lessons/{id}', { params: { path: { id: lid } } }))
            }
            onReorder={(ids) => unwrap(api.PUT('/api/v1/admin/lessons/reorder', { body: { ids } }))}
            onChanged={lessons.reload}
            emptyText="لا توجد دروس — الدروس اختيارية"
          />
        </div>
      </div>
    </div>
  );
}

function SubjectDetails({
  subject,
  onSaved,
}: {
  subject: { id: string; code: string; nameAr: string; description: string | null; isActive: boolean };
  onSaved: () => Promise<unknown>;
}) {
  const [error, setError] = useState<string | null>(null);
  const [saved, setSaved] = useState(false);

  async function save(form: FormData) {
    setError(null);
    setSaved(false);
    try {
      await unwrap(
        api.PATCH('/api/v1/admin/subjects/{id}', {
          params: { path: { id: subject.id } },
          body: {
            nameAr: String(form.get('nameAr')),
            code: String(form.get('code')),
            description: String(form.get('description') ?? '').trim() || null,
            isActive: form.get('isActive') === 'on',
          },
        }),
      );
      await onSaved();
      setSaved(true);
    } catch (err) {
      setError(errorMessage(err));
    }
  }

  return (
    <Card className="space-y-4">
      <form
        key={`${subject.id}:${subject.code}:${subject.nameAr}`}
        className="grid gap-4 sm:grid-cols-2"
        onSubmit={(e) => {
          e.preventDefault();
          void save(new FormData(e.currentTarget));
        }}
      >
        <div className="space-y-2">
          <Label htmlFor="nameAr">اسم المادة</Label>
          <Input id="nameAr" name="nameAr" defaultValue={subject.nameAr} required />
        </div>
        <div className="space-y-2">
          <Label htmlFor="code">الرمز</Label>
          <Input id="code" name="code" dir="ltr" className="font-mono" defaultValue={subject.code} required />
        </div>
        <div className="space-y-2 sm:col-span-2">
          <Label htmlFor="description">الوصف</Label>
          <textarea
            id="description"
            name="description"
            defaultValue={subject.description ?? ''}
            rows={3}
            className="w-full rounded-lg border border-border bg-surface p-3 text-sm"
          />
        </div>
        <label className="flex items-center gap-2 text-sm">
          <input type="checkbox" name="isActive" defaultChecked={subject.isActive} className="size-4" />
          ظاهرة للطلاب
        </label>
        <div className="flex items-center justify-end gap-3">
          {saved ? <span className="text-sm text-brand">تم الحفظ</span> : null}
          <Button type="submit">حفظ</Button>
        </div>
      </form>
      <FormError message={error} />
    </Card>
  );
}
