'use client';

import { EntityList } from '@/components/entity-list';
import { FormError } from '@/components/form-error';
import { api, unwrap } from '@/lib/api';
import { useLoad } from '@/lib/use-load';

/** The three fixed levels (spec §1): admins rename and reorder them; codes never change. */
export default function LevelsPage() {
  const levels = useLoad(() => unwrap(api.GET('/api/v1/admin/levels')), []);
  const items = (levels.data ?? []).map((l) => ({ id: l.id, code: l.code, name: l.nameAr }));

  async function reorder(ids: string[]) {
    for (const [index, id] of ids.entries()) {
      await unwrap(
        api.PATCH('/api/v1/admin/levels/{id}', { params: { path: { id } }, body: { sortOrder: index } }),
      );
    }
  }

  return (
    <div className="mx-auto max-w-3xl space-y-4">
      <h1 className="text-xl font-semibold">المراحل التعليمية</h1>
      <FormError message={levels.error} />
      <EntityList
        title="المراحل"
        items={items}
        withCode={false}
        onUpdate={(id, v) =>
          unwrap(
            api.PATCH('/api/v1/admin/levels/{id}', { params: { path: { id } }, body: { nameAr: v.name } }),
          )
        }
        onReorder={reorder}
        onChanged={levels.reload}
      />
    </div>
  );
}
