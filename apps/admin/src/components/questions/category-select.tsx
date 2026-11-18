'use client';

import { selectClass } from '@/components/access/scope-picker';
import { Label } from '@/components/ui/input';
import { api, unwrap } from '@/lib/api';
import { categoryLabel, depthOf } from '@/lib/categories';
import { useLoad } from '@/lib/use-load';

/**
 * Question category (v3 §3): the global categories and the subject's own, children indented under
 * their parents. `filter` adds «بلا تصنيف» for the questions list.
 */
export function CategorySelect({
  subjectId,
  value,
  onChange,
  filter,
  id = 'q-category',
}: {
  subjectId: string | null;
  value: string | null;
  onChange: (v: string | null) => void;
  filter?: boolean;
  id?: string;
}) {
  const categories = useLoad(
    () =>
      unwrap(
        api.GET('/api/v1/admin/question-categories', {
          params: { query: subjectId ? { subjectId } : { globalOnly: 'true' } },
        }),
      ),
    [subjectId],
  );
  const list = categories.data ?? [];
  const depth = depthOf(list);
  return (
    <div className="space-y-1">
      <Label htmlFor={id}>التصنيف</Label>
      <select
        id={id}
        className={selectClass}
        value={value ?? ''}
        onChange={(e) => onChange(e.target.value || null)}
      >
        <option value="">{filter ? 'كل التصنيفات' : 'بلا تصنيف'}</option>
        {filter ? <option value="none">بلا تصنيف</option> : null}
        {list.map((c) => (
          <option key={c.id} value={c.id} title={categoryLabel(list, c.id)}>
            {`${'— '.repeat(depth.get(c.id) ?? 0)}${c.nameAr}${c.subjectId ? '' : ' (عام)'}`}
          </option>
        ))}
      </select>
    </div>
  );
}
