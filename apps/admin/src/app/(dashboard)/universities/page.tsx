'use client';

import { useState } from 'react';
import { EntityList } from '@/components/entity-list';
import { FormError } from '@/components/form-error';
import { api, unwrap } from '@/lib/api';
import { useLoad } from '@/lib/use-load';

type Node = { id: string; code: string; nameAr: string; isActive: boolean };
const toItems = (rows: Node[] | null) =>
  (rows ?? []).map((r) => ({ id: r.id, code: r.code, name: r.nameAr, isActive: r.isActive }));
const patchBody = (v: { code?: string; name?: string; isActive?: boolean }) => ({
  ...(v.code !== undefined ? { code: v.code } : {}),
  ...(v.name !== undefined ? { nameAr: v.name } : {}),
  ...(v.isActive !== undefined ? { isActive: v.isActive } : {}),
});

/** College hierarchy (spec §6): University → Faculty → Academic Year, as three linked columns. */
export default function UniversitiesPage() {
  const [universityId, setUniversityId] = useState<string | null>(null);
  const [facultyId, setFacultyId] = useState<string | null>(null);

  const universities = useLoad(() => unwrap(api.GET('/api/v1/admin/universities')), []);
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

  return (
    <div className="space-y-4">
      <div>
        <h1 className="text-xl font-semibold">الجامعات · الكليات · السنوات الدراسية</h1>
        <p className="text-sm text-muted">هذه الطبقات اختيارية وتخص المرحلة الجامعية فقط.</p>
      </div>
      <FormError message={universities.error ?? faculties.error ?? years.error} />
      <div className="grid gap-4 lg:grid-cols-3">
        <EntityList
          title="الجامعات"
          withActive
          items={toItems(universities.data)}
          selectedId={universityId}
          onSelect={(id) => {
            setUniversityId(id);
            setFacultyId(null);
          }}
          onCreate={(v) =>
            unwrap(api.POST('/api/v1/admin/universities', { body: { code: v.code, nameAr: v.name } }))
          }
          onUpdate={(id, v) =>
            unwrap(
              api.PATCH('/api/v1/admin/universities/{id}', { params: { path: { id } }, body: patchBody(v) }),
            )
          }
          onDelete={async (id) => {
            await unwrap(api.DELETE('/api/v1/admin/universities/{id}', { params: { path: { id } } }));
            if (id === universityId) setUniversityId(null);
          }}
          onReorder={(ids) => unwrap(api.PUT('/api/v1/admin/universities/reorder', { body: { ids } }))}
          onChanged={universities.reload}
        />
        {universityId ? (
          <EntityList
            title="الكليات"
            withActive
            items={toItems(faculties.data)}
            selectedId={facultyId}
            onSelect={setFacultyId}
            onCreate={(v) =>
              unwrap(
                api.POST('/api/v1/admin/faculties', { body: { universityId, code: v.code, nameAr: v.name } }),
              )
            }
            onUpdate={(id, v) =>
              unwrap(
                api.PATCH('/api/v1/admin/faculties/{id}', { params: { path: { id } }, body: patchBody(v) }),
              )
            }
            onDelete={async (id) => {
              await unwrap(api.DELETE('/api/v1/admin/faculties/{id}', { params: { path: { id } } }));
              if (id === facultyId) setFacultyId(null);
            }}
            onReorder={(ids) => unwrap(api.PUT('/api/v1/admin/faculties/reorder', { body: { ids } }))}
            onChanged={faculties.reload}
          />
        ) : (
          <Hint text="اختر جامعة لعرض كلياتها" />
        )}
        {facultyId ? (
          <EntityList
            title="السنوات الدراسية"
            withActive
            items={toItems(years.data)}
            onCreate={(v) =>
              unwrap(
                api.POST('/api/v1/admin/academic-years', {
                  body: { facultyId, code: v.code, nameAr: v.name },
                }),
              )
            }
            onUpdate={(id, v) =>
              unwrap(
                api.PATCH('/api/v1/admin/academic-years/{id}', {
                  params: { path: { id } },
                  body: patchBody(v),
                }),
              )
            }
            onDelete={(id) =>
              unwrap(api.DELETE('/api/v1/admin/academic-years/{id}', { params: { path: { id } } }))
            }
            onReorder={(ids) => unwrap(api.PUT('/api/v1/admin/academic-years/reorder', { body: { ids } }))}
            onChanged={years.reload}
          />
        ) : (
          <Hint text="اختر كلية لعرض سنواتها الدراسية" />
        )}
      </div>
    </div>
  );
}

function Hint({ text }: { text: string }) {
  return (
    <div className="flex min-h-40 items-center justify-center rounded-xl border border-dashed border-border text-sm text-muted">
      {text}
    </div>
  );
}
