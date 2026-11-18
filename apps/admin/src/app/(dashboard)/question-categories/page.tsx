'use client';

import { Plus, Save, Trash2 } from 'lucide-react';
import { useEffect, useState } from 'react';
import { selectClass } from '@/components/access/scope-picker';
import { FormError } from '@/components/form-error';
import { Button } from '@/components/ui/button';
import { Card } from '@/components/ui/card';
import { Input, Label } from '@/components/ui/input';
import { api, unwrap } from '@/lib/api';
import { allowedParents, depthOf, type QuestionCategory } from '@/lib/categories';
import { errorMessage, useLoad } from '@/lib/use-load';

/** `''` = the global categories (usable in every subject). */
type Owner = string;

/**
 * Question categories (v3 §3): global ones apply to every subject, and each subject may add its own;
 * a category may have children. Codes are the references used by bulk import (`category_code`).
 */
export default function QuestionCategoriesPage() {
  const subjects = useLoad(() => unwrap(api.GET('/api/v1/admin/subjects', { params: { query: {} } })), []);
  const [owner, setOwner] = useState<Owner>('');
  const list = useLoad(
    () =>
      unwrap(
        api.GET('/api/v1/admin/question-categories', {
          params: { query: owner ? { subjectId: owner } : { globalOnly: 'true' } },
        }),
      ),
    [owner],
  );
  const [error, setError] = useState<string | null>(null);
  const [message, setMessage] = useState<string | null>(null);

  async function run(call: () => Promise<unknown>, done = 'تم الحفظ') {
    setError(null);
    setMessage(null);
    try {
      await call();
      setMessage(done);
      await list.reload();
    } catch (err) {
      setError(errorMessage(err));
    }
  }

  const categories = list.data ?? [];
  const depth = depthOf(categories);

  return (
    <div className="mx-auto max-w-5xl space-y-4">
      <h1 className="text-xl font-semibold">تصنيفات الأسئلة</h1>
      <Card className="space-y-3">
        <div className="space-y-1 sm:w-80">
          <Label htmlFor="cat-owner">التصنيفات</Label>
          <select
            id="cat-owner"
            className={selectClass}
            value={owner}
            onChange={(e) => setOwner(e.target.value)}
          >
            <option value="">العامة (لكل المواد)</option>
            {(subjects.data ?? []).map((s) => (
              <option key={s.id} value={s.id}>
                {s.nameAr}
              </option>
            ))}
          </select>
        </div>
        <p className="text-xs text-muted">
          {owner
            ? 'تظهر التصنيفات العامة أيضاً؛ يمكن إضافة تصنيفات خاصة بهذه المادة، ومنها تصنيفات فرعية تحت تصنيف عام.'
            : 'التصنيفات العامة متاحة في كل المواد.'}
        </p>
      </Card>
      <FormError message={subjects.error ?? list.error ?? error} />
      {message ? <p className="text-sm text-brand">{message}</p> : null}
      <NewCategory
        key={owner}
        subjectId={owner || null}
        parents={categories}
        onCreate={(body) =>
          run(() => unwrap(api.POST('/api/v1/admin/question-categories', { body })), 'تمت الإضافة')
        }
      />
      <Card className="overflow-x-auto p-0">
        <table className="w-full text-sm">
          <thead className="border-b border-border text-muted">
            <tr>
              <th className="p-3 text-start font-medium">الاسم</th>
              <th className="p-3 text-start font-medium">الرمز</th>
              <th className="p-3 text-start font-medium">التصنيف الأب</th>
              <th className="p-3 text-start font-medium">الترتيب</th>
              <th className="p-3 text-start font-medium">الأسئلة</th>
              <th className="p-3" />
            </tr>
          </thead>
          <tbody>
            {categories.map((c) => (
              <CategoryRow
                key={`${c.id}-${c.updatedAt}`}
                category={c}
                depth={depth.get(c.id) ?? 0}
                // Global categories are edited from the global list only.
                editable={!owner || c.subjectId === owner}
                parents={allowedParents(categories, c)}
                onSave={(body) =>
                  run(() =>
                    unwrap(
                      api.PATCH('/api/v1/admin/question-categories/{id}', {
                        params: { path: { id: c.id } },
                        body,
                      }),
                    ),
                  )
                }
                onDelete={() => {
                  if (window.confirm(`حذف التصنيف «${c.nameAr}»؟ تبقى أسئلته بلا تصنيف.`))
                    void run(
                      () =>
                        unwrap(
                          api.DELETE('/api/v1/admin/question-categories/{id}', {
                            params: { path: { id: c.id } },
                          }),
                        ),
                      'تم الحذف',
                    );
                }}
              />
            ))}
            {!list.loading && categories.length === 0 ? (
              <tr>
                <td colSpan={6} className="p-6 text-center text-muted">
                  لا توجد تصنيفات
                </td>
              </tr>
            ) : null}
          </tbody>
        </table>
      </Card>
    </div>
  );
}

type CreateBody = {
  subjectId: string | null;
  parentId: string | null;
  code: string;
  nameAr: string;
};

function NewCategory({
  subjectId,
  parents,
  onCreate,
}: {
  subjectId: string | null;
  parents: QuestionCategory[];
  onCreate: (body: CreateBody) => Promise<void>;
}) {
  const [nameAr, setNameAr] = useState('');
  const [code, setCode] = useState('');
  const [parentId, setParentId] = useState('');
  const usable = parents.filter((p) => p.subjectId === null || p.subjectId === subjectId);
  return (
    <Card className="space-y-3">
      <h2 className="font-semibold">تصنيف جديد</h2>
      <div className="grid gap-3 sm:grid-cols-[1fr_12rem_14rem_auto] sm:items-end">
        <div className="space-y-1">
          <Label htmlFor="new-cat-name">الاسم</Label>
          <Input id="new-cat-name" value={nameAr} onChange={(e) => setNameAr(e.target.value)} />
        </div>
        <div className="space-y-1">
          <Label htmlFor="new-cat-code">الرمز (لاتيني)</Label>
          <Input
            id="new-cat-code"
            dir="ltr"
            placeholder="explain"
            value={code}
            onChange={(e) => setCode(e.target.value.toLowerCase())}
          />
        </div>
        <div className="space-y-1">
          <Label htmlFor="new-cat-parent">التصنيف الأب</Label>
          <select
            id="new-cat-parent"
            className={selectClass}
            value={parentId}
            onChange={(e) => setParentId(e.target.value)}
          >
            <option value="">بلا (تصنيف رئيسي)</option>
            {usable.map((p) => (
              <option key={p.id} value={p.id}>
                {p.nameAr}
              </option>
            ))}
          </select>
        </div>
        <Button
          disabled={!nameAr.trim() || !code.trim()}
          onClick={() =>
            void onCreate({
              subjectId,
              parentId: parentId || null,
              code: code.trim(),
              nameAr: nameAr.trim(),
            }).then(() => {
              setNameAr('');
              setCode('');
              setParentId('');
            })
          }
        >
          <Plus className="size-4" aria-hidden />
          إضافة
        </Button>
      </div>
    </Card>
  );
}

function CategoryRow({
  category: c,
  depth,
  editable,
  parents,
  onSave,
  onDelete,
}: {
  category: QuestionCategory;
  depth: number;
  editable: boolean;
  parents: QuestionCategory[];
  onSave: (body: {
    nameAr: string;
    code: string;
    parentId: string | null;
    sortOrder: number;
  }) => Promise<void>;
  onDelete: () => void;
}) {
  const [nameAr, setNameAr] = useState(c.nameAr);
  const [code, setCode] = useState(c.code);
  const [parentId, setParentId] = useState(c.parentId ?? '');
  const [sortOrder, setSortOrder] = useState(String(c.sortOrder));
  useEffect(() => {
    setNameAr(c.nameAr);
    setCode(c.code);
    setParentId(c.parentId ?? '');
    setSortOrder(String(c.sortOrder));
  }, [c]);
  const changed =
    nameAr !== c.nameAr ||
    code !== c.code ||
    parentId !== (c.parentId ?? '') ||
    sortOrder !== String(c.sortOrder);

  if (!editable) {
    return (
      <tr className="border-b border-border text-muted last:border-0">
        <td className="p-3" style={{ paddingInlineStart: `${0.75 + depth * 1.25}rem` }}>
          {c.nameAr} <span className="text-xs">(عام)</span>
        </td>
        <td className="p-3" dir="ltr">
          {c.code}
        </td>
        <td className="p-3">—</td>
        <td className="p-3">{c.sortOrder}</td>
        <td className="p-3">{c.questionCount}</td>
        <td className="p-3" />
      </tr>
    );
  }
  return (
    <tr className="border-b border-border last:border-0">
      <td className="p-3" style={{ paddingInlineStart: `${0.75 + depth * 1.25}rem` }}>
        <Input aria-label={`اسم ${c.nameAr}`} value={nameAr} onChange={(e) => setNameAr(e.target.value)} />
      </td>
      <td className="p-3">
        <Input
          aria-label={`رمز ${c.nameAr}`}
          dir="ltr"
          value={code}
          onChange={(e) => setCode(e.target.value.toLowerCase())}
        />
      </td>
      <td className="p-3">
        <select
          aria-label={`التصنيف الأب لـ ${c.nameAr}`}
          className={selectClass}
          value={parentId}
          onChange={(e) => setParentId(e.target.value)}
        >
          <option value="">بلا</option>
          {parents.map((p) => (
            <option key={p.id} value={p.id}>
              {p.nameAr}
            </option>
          ))}
        </select>
      </td>
      <td className="w-24 p-3">
        <Input
          aria-label={`ترتيب ${c.nameAr}`}
          type="number"
          dir="ltr"
          value={sortOrder}
          onChange={(e) => setSortOrder(e.target.value)}
        />
      </td>
      <td className="p-3">{c.questionCount}</td>
      <td className="p-3">
        <div className="flex gap-1">
          <Button
            size="sm"
            variant="ghost"
            aria-label={`حفظ ${c.nameAr}`}
            disabled={!changed || !nameAr.trim() || !code.trim()}
            onClick={() =>
              void onSave({
                nameAr: nameAr.trim(),
                code: code.trim(),
                parentId: parentId || null,
                sortOrder: Number(sortOrder) || 0,
              })
            }
          >
            <Save className="size-4" aria-hidden />
          </Button>
          <Button
            size="sm"
            variant="ghost"
            className="text-danger"
            aria-label={`حذف ${c.nameAr}`}
            onClick={onDelete}
          >
            <Trash2 className="size-4" aria-hidden />
          </Button>
        </div>
      </td>
    </tr>
  );
}
