'use client';

import { useRouter, useSearchParams } from 'next/navigation';
import { Suspense, useState } from 'react';
import { EntityList } from '@/components/entity-list';
import { FormError } from '@/components/form-error';
import { ImageUpload } from '@/components/image-upload';
import { Button } from '@/components/ui/button';
import { Card } from '@/components/ui/card';
import { Input, Label } from '@/components/ui/input';
import { api, unwrap } from '@/lib/api';
import { errorMessage, useLoad } from '@/lib/use-load';

type AdminTeacher = {
  id: string;
  nameAr: string;
  slug: string;
  photoUrl: string | null;
  shortDescription: string | null;
  bio: string | null;
  isActive: boolean;
  followerCount: number;
  trackCount: number;
};

export default function TeachersPage() {
  return (
    <Suspense>
      <Teachers />
    </Suspense>
  );
}

/** Teachers are content entities managed by admins (spec §0.2, §7). */
function Teachers() {
  const router = useRouter();
  const params = useSearchParams();
  const selectedId = params.get('id');
  const teachers = useLoad(() => unwrap(api.GET('/api/v1/admin/teachers')), []);
  const selected = teachers.data?.find((t) => t.id === selectedId) ?? null;
  const select = (id: string | null) => router.replace(id ? `/teachers?id=${id}` : '/teachers');

  return (
    <div className="space-y-4">
      <h1 className="text-xl font-semibold">المدرسون</h1>
      <FormError message={teachers.error} />
      <div className="grid gap-4 lg:grid-cols-[minmax(0,1fr)_minmax(0,1.6fr)]">
        <EntityList
          title="قائمة المدرسين"
          withActive
          items={(teachers.data ?? []).map((t) => ({
            id: t.id,
            code: t.slug,
            name: t.nameAr,
            isActive: t.isActive,
          }))}
          selectedId={selectedId}
          onSelect={select}
          onCreate={async (v) => {
            const created = await unwrap(
              api.POST('/api/v1/admin/teachers', { body: { nameAr: v.name, slug: v.code } }),
            );
            select(created.id);
          }}
          onUpdate={(id, v) =>
            unwrap(
              api.PATCH('/api/v1/admin/teachers/{id}', {
                params: { path: { id } },
                body: {
                  ...(v.code !== undefined ? { slug: v.code } : {}),
                  ...(v.name !== undefined ? { nameAr: v.name } : {}),
                  ...(v.isActive !== undefined ? { isActive: v.isActive } : {}),
                },
              }),
            )
          }
          onDelete={async (id) => {
            await unwrap(api.DELETE('/api/v1/admin/teachers/{id}', { params: { path: { id } } }));
            if (id === selectedId) select(null);
          }}
          onReorder={(ids) => unwrap(api.PUT('/api/v1/admin/teachers/reorder', { body: { ids } }))}
          onChanged={teachers.reload}
          addLabel="مدرس جديد"
          emptyText="لا يوجد مدرسون بعد"
        />
        {selected ? (
          <div className="space-y-4">
            <TeacherDetails key={selected.id} teacher={selected} onSaved={teachers.reload} />
            <TeacherTracks teacherId={selected.id} onChanged={teachers.reload} />
          </div>
        ) : (
          <div className="flex min-h-40 items-center justify-center rounded-xl border border-dashed border-border text-sm text-muted">
            اختر مدرساً لعرض بياناته ومساراته
          </div>
        )}
      </div>
    </div>
  );
}

function TeacherDetails({ teacher, onSaved }: { teacher: AdminTeacher; onSaved: () => Promise<unknown> }) {
  const [error, setError] = useState<string | null>(null);
  const [saved, setSaved] = useState(false);

  async function patch(body: Record<string, unknown>) {
    setError(null);
    setSaved(false);
    try {
      await unwrap(api.PATCH('/api/v1/admin/teachers/{id}', { params: { path: { id: teacher.id } }, body }));
      await onSaved();
      setSaved(true);
    } catch (err) {
      setError(errorMessage(err));
      throw err;
    }
  }

  return (
    <Card className="space-y-4">
      <div className="flex flex-wrap items-start justify-between gap-4">
        <ImageUpload
          kind="teacher"
          label="صورة المدرس"
          imageUrl={teacher.photoUrl}
          onChange={(photoMediaId) => patch({ photoMediaId })}
        />
        <div className="flex gap-4 text-sm text-muted">
          <span>المتابعون: {teacher.followerCount}</span>
          <span>المسارات: {teacher.trackCount}</span>
        </div>
      </div>
      <form
        className="grid gap-4 sm:grid-cols-2"
        onSubmit={(e) => {
          e.preventDefault();
          const f = new FormData(e.currentTarget);
          void patch({
            nameAr: String(f.get('nameAr')),
            slug: String(f.get('slug')),
            shortDescription: String(f.get('shortDescription') ?? '').trim() || null,
            bio: String(f.get('bio') ?? '').trim() || null,
            isActive: f.get('isActive') === 'on',
          }).catch(() => undefined);
        }}
      >
        <div className="space-y-2">
          <Label htmlFor="nameAr">الاسم</Label>
          <Input id="nameAr" name="nameAr" defaultValue={teacher.nameAr} required />
        </div>
        <div className="space-y-2">
          <Label htmlFor="slug">المعرّف</Label>
          <Input id="slug" name="slug" dir="ltr" className="font-mono" defaultValue={teacher.slug} required />
        </div>
        <div className="space-y-2 sm:col-span-2">
          <Label htmlFor="shortDescription">نبذة قصيرة</Label>
          <Input
            id="shortDescription"
            name="shortDescription"
            defaultValue={teacher.shortDescription ?? ''}
            maxLength={300}
          />
        </div>
        <div className="space-y-2 sm:col-span-2">
          <Label htmlFor="bio">السيرة</Label>
          <textarea
            id="bio"
            name="bio"
            rows={4}
            defaultValue={teacher.bio ?? ''}
            className="w-full rounded-lg border border-border bg-surface p-3 text-sm"
          />
        </div>
        <label className="flex items-center gap-2 text-sm">
          <input type="checkbox" name="isActive" defaultChecked={teacher.isActive} className="size-4" />
          ظاهر للطلاب
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

/** A teacher's tracks: one teacher can have several, even in the same subject (spec §7.2). */
function TeacherTracks({ teacherId, onChanged }: { teacherId: string; onChanged: () => Promise<unknown> }) {
  const tracks = useLoad(
    () => unwrap(api.GET('/api/v1/admin/teacher-tracks', { params: { query: { teacherId } } })),
    [teacherId],
  );
  const [adding, setAdding] = useState(false);
  const reload = async () => {
    await tracks.reload();
    await onChanged();
  };

  return (
    <div className="space-y-2">
      <FormError message={tracks.error} />
      {adding ? (
        <NewTrackForm
          teacherId={teacherId}
          onDone={async (created) => {
            setAdding(false);
            if (created) await reload();
          }}
        />
      ) : (
        <Button size="sm" variant="outline" onClick={() => setAdding(true)}>
          مسار جديد
        </Button>
      )}
      <EntityList
        title="المسارات"
        withActive
        items={(tracks.data ?? []).map((t) => ({
          id: t.id,
          code: t.slug,
          name: `${t.titleAr} · ${t.subjectNameAr}`,
          isActive: t.isActive,
        }))}
        onUpdate={(id, v) =>
          unwrap(
            api.PATCH('/api/v1/admin/teacher-tracks/{id}', {
              params: { path: { id } },
              body: {
                ...(v.code !== undefined ? { slug: v.code } : {}),
                ...(v.name !== undefined ? { titleAr: v.name.split(' · ')[0]! } : {}),
                ...(v.isActive !== undefined ? { isActive: v.isActive } : {}),
              },
            }),
          )
        }
        onDelete={(id) =>
          unwrap(api.DELETE('/api/v1/admin/teacher-tracks/{id}', { params: { path: { id } } }))
        }
        onReorder={(ids) => unwrap(api.PUT('/api/v1/admin/teacher-tracks/reorder', { body: { ids } }))}
        onChanged={reload}
        emptyText="لا توجد مسارات لهذا المدرس"
      />
    </div>
  );
}

function NewTrackForm({
  teacherId,
  onDone,
}: {
  teacherId: string;
  onDone: (created: boolean) => Promise<void>;
}) {
  const levels = useLoad(() => unwrap(api.GET('/api/v1/admin/levels')), []);
  const [levelId, setLevelId] = useState<string>('');
  const subjects = useLoad(
    () =>
      levelId
        ? unwrap(api.GET('/api/v1/admin/subjects', { params: { query: { levelId } } }))
        : Promise.resolve([]),
    [levelId],
  );
  const [error, setError] = useState<string | null>(null);
  const select = 'h-10 w-full rounded-lg border border-border bg-surface px-2';

  return (
    <Card className="p-4">
      <form
        className="grid gap-3 sm:grid-cols-2"
        onSubmit={async (e) => {
          e.preventDefault();
          const f = new FormData(e.currentTarget);
          try {
            await unwrap(
              api.POST('/api/v1/admin/teacher-tracks', {
                body: {
                  teacherId,
                  subjectId: String(f.get('subjectId')),
                  titleAr: String(f.get('titleAr')),
                  slug: String(f.get('slug')),
                },
              }),
            );
            await onDone(true);
          } catch (err) {
            setError(errorMessage(err));
          }
        }}
      >
        <label className="space-y-1 text-sm">
          <span>المرحلة</span>
          <select className={select} value={levelId} onChange={(e) => setLevelId(e.target.value)} required>
            <option value="">اختر المرحلة</option>
            {(levels.data ?? []).map((l) => (
              <option key={l.id} value={l.id}>
                {l.nameAr}
              </option>
            ))}
          </select>
        </label>
        <label className="space-y-1 text-sm">
          <span>المادة</span>
          <select className={select} name="subjectId" required disabled={!levelId}>
            <option value="">اختر المادة</option>
            {(subjects.data ?? []).map((s) => (
              <option key={s.id} value={s.id}>
                {s.nameAr}
              </option>
            ))}
          </select>
        </label>
        <div className="space-y-1">
          <Label htmlFor="titleAr">عنوان المسار</Label>
          <Input id="titleAr" name="titleAr" placeholder="أ. أحمد — فيزياء بكالوريا" required />
        </div>
        <div className="space-y-1">
          <Label htmlFor="trackSlug">المعرّف</Label>
          <Input
            id="trackSlug"
            name="slug"
            dir="ltr"
            className="font-mono"
            placeholder="ahmad-g12-physics"
            required
          />
        </div>
        <div className="flex items-center gap-2 sm:col-span-2">
          <Button type="submit">إضافة المسار</Button>
          <Button type="button" variant="ghost" onClick={() => void onDone(false)}>
            إلغاء
          </Button>
        </div>
        <div className="sm:col-span-2">
          <FormError message={error} />
        </div>
      </form>
    </Card>
  );
}
