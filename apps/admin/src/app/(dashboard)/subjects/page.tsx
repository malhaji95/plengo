'use client';

import { useRouter } from 'next/navigation';
import { useEffect, useState } from 'react';
import { EntityList } from '@/components/entity-list';
import { FormError } from '@/components/form-error';
import { api, unwrap } from '@/lib/api';
import { useLoad } from '@/lib/use-load';
import { cn } from '@/lib/utils';

type Option = { id: string; nameAr: string };

function Select(props: {
  label: string;
  value: string | null;
  options: Option[];
  onChange: (v: string | null) => void;
  placeholder: string;
}) {
  return (
    <label className="flex flex-col gap-1 text-sm">
      <span className="text-muted">{props.label}</span>
      <select
        className="h-10 rounded-lg border border-border bg-surface px-2"
        value={props.value ?? ''}
        onChange={(e) => props.onChange(e.target.value || null)}
      >
        <option value="">{props.placeholder}</option>
        {props.options.map((o) => (
          <option key={o.id} value={o.id}>
            {o.nameAr}
          </option>
        ))}
      </select>
    </label>
  );
}

/**
 * Subjects per level. For the college level, the optional University → Faculty → Year selection
 * filters the list and is where new subjects are created.
 */
export default function SubjectsPage() {
  const router = useRouter();
  const levels = useLoad(() => unwrap(api.GET('/api/v1/admin/levels')), []);
  const [levelId, setLevelId] = useState<string | null>(null);
  const [universityId, setUniversityId] = useState<string | null>(null);
  const [facultyId, setFacultyId] = useState<string | null>(null);
  const [yearId, setYearId] = useState<string | null>(null);

  useEffect(() => {
    if (!levelId && levels.data?.[0]) setLevelId(levels.data[0].id);
  }, [levels.data, levelId]);

  const level = levels.data?.find((l) => l.id === levelId) ?? null;
  const isCollege = level?.isCollege ?? false;

  const universities = useLoad(
    () => (isCollege ? unwrap(api.GET('/api/v1/admin/universities')) : Promise.resolve([])),
    [isCollege],
  );
  const faculties = useLoad(
    () =>
      universityId
        ? unwrap(api.GET('/api/v1/admin/faculties', { params: { query: { universityId } } }))
        : Promise.resolve([]),
    [universityId],
  );
  const years = useLoad(
    () =>
      facultyId
        ? unwrap(api.GET('/api/v1/admin/academic-years', { params: { query: { facultyId } } }))
        : Promise.resolve([]),
    [facultyId],
  );

  const filter = {
    ...(levelId ? { levelId } : {}),
    ...(isCollege && universityId ? { universityId } : {}),
    ...(isCollege && facultyId ? { facultyId } : {}),
    ...(isCollege && yearId ? { academicYearId: yearId } : {}),
  };
  const subjects = useLoad(
    () =>
      levelId
        ? unwrap(api.GET('/api/v1/admin/subjects', { params: { query: filter } }))
        : Promise.resolve([]),
    [levelId, universityId, facultyId, yearId],
  );

  // Reordering needs one sibling set: a school level, or a fully chosen college year.
  const canReorder = !isCollege || Boolean(yearId);

  return (
    <div className="space-y-4">
      <h1 className="text-xl font-semibold">المواد</h1>
      <FormError message={levels.error ?? subjects.error} />

      <div className="flex flex-wrap gap-2" role="tablist">
        {(levels.data ?? []).map((l) => (
          <button
            key={l.id}
            role="tab"
            aria-selected={l.id === levelId}
            className={cn(
              'rounded-full border px-4 py-1.5 text-sm',
              l.id === levelId ? 'border-brand bg-brand text-brand-foreground' : 'border-border bg-surface',
            )}
            onClick={() => {
              setLevelId(l.id);
              setUniversityId(null);
              setFacultyId(null);
              setYearId(null);
            }}
          >
            {l.nameAr}
          </button>
        ))}
      </div>

      {isCollege ? (
        <div className="grid gap-3 rounded-xl border border-border bg-surface p-3 sm:grid-cols-3">
          <Select
            label="الجامعة"
            placeholder="كل الجامعات / بدون جامعة"
            value={universityId}
            options={universities.data ?? []}
            onChange={(v) => {
              setUniversityId(v);
              setFacultyId(null);
              setYearId(null);
            }}
          />
          <Select
            label="الكلية"
            placeholder="كل الكليات"
            value={facultyId}
            options={faculties.data ?? []}
            onChange={(v) => {
              setFacultyId(v);
              setYearId(null);
            }}
          />
          <Select
            label="السنة الدراسية"
            placeholder="كل السنوات"
            value={yearId}
            options={years.data ?? []}
            onChange={setYearId}
          />
        </div>
      ) : null}

      {levelId ? (
        <EntityList
          title={level ? `مواد ${level.nameAr}` : 'المواد'}
          withActive
          items={(subjects.data ?? []).map((s) => ({
            id: s.id,
            code: s.code,
            name: s.nameAr,
            isActive: s.isActive,
          }))}
          onSelect={(id) => router.push(`/subjects/${id}`)}
          onCreate={(v) =>
            unwrap(
              api.POST('/api/v1/admin/subjects', {
                body: {
                  educationLevelId: levelId,
                  code: v.code,
                  nameAr: v.name,
                  ...(isCollege ? { universityId, facultyId, academicYearId: yearId } : {}),
                },
              }),
            )
          }
          onUpdate={(id, v) =>
            unwrap(
              api.PATCH('/api/v1/admin/subjects/{id}', {
                params: { path: { id } },
                body: {
                  ...(v.code !== undefined ? { code: v.code } : {}),
                  ...(v.name !== undefined ? { nameAr: v.name } : {}),
                  ...(v.isActive !== undefined ? { isActive: v.isActive } : {}),
                },
              }),
            )
          }
          onDelete={(id) => unwrap(api.DELETE('/api/v1/admin/subjects/{id}', { params: { path: { id } } }))}
          {...(canReorder
            ? {
                onReorder: (ids: string[]) =>
                  unwrap(api.PUT('/api/v1/admin/subjects/reorder', { body: { ids } })),
              }
            : {})}
          onChanged={subjects.reload}
          addLabel="مادة جديدة"
          emptyText="لا توجد مواد في هذا القسم"
        />
      ) : null}
    </div>
  );
}
