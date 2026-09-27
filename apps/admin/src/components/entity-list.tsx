'use client';

import { ArrowDown, ArrowUp, Check, Pencil, Plus, Trash2, X } from 'lucide-react';
import { useState } from 'react';
import { FormError } from '@/components/form-error';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { errorMessage } from '@/lib/use-load';
import { cn } from '@/lib/utils';

export interface EntityItem {
  id: string;
  code?: string;
  name: string;
  isActive?: boolean;
}

export interface EntityListProps {
  title: string;
  items: EntityItem[];
  /** Whether items carry a stable import code (everything except levels). */
  withCode?: boolean;
  /** Whether items can be hidden from students. */
  withActive?: boolean;
  selectedId?: string | null;
  onSelect?: (id: string) => void;
  onCreate?: (input: { code: string; name: string }) => Promise<unknown>;
  onUpdate: (id: string, input: { code?: string; name?: string; isActive?: boolean }) => Promise<unknown>;
  onDelete?: (id: string) => Promise<unknown>;
  onReorder?: (ids: string[]) => Promise<unknown>;
  /** Reload after any change. */
  onChanged: () => Promise<unknown> | void;
  emptyText?: string;
  addLabel?: string;
}

/**
 * A titled list of ordered structure nodes with inline create / rename / activate / reorder /
 * delete. Every action goes to the API; the list reloads afterwards so the server stays the truth.
 */
export function EntityList(props: EntityListProps) {
  const { items, withCode = true, withActive = false } = props;
  const [error, setError] = useState<string | null>(null);
  const [editing, setEditing] = useState<string | null>(null);
  const [adding, setAdding] = useState(false);
  const [busy, setBusy] = useState(false);

  async function run(action: () => Promise<unknown>) {
    setBusy(true);
    setError(null);
    try {
      await action();
      await props.onChanged();
      return true;
    } catch (err) {
      setError(errorMessage(err));
      return false;
    } finally {
      setBusy(false);
    }
  }

  function move(index: number, delta: number) {
    const ids = items.map((i) => i.id);
    const [moved] = ids.splice(index, 1);
    ids.splice(index + delta, 0, moved!);
    void run(() => props.onReorder!(ids));
  }

  return (
    <section className="flex min-w-0 flex-col rounded-xl border border-border bg-surface">
      <header className="flex items-center justify-between border-b border-border px-4 py-3">
        <h2 className="font-semibold">{props.title}</h2>
        {props.onCreate ? (
          <Button size="sm" variant="outline" onClick={() => setAdding((v) => !v)} disabled={busy}>
            <Plus className="size-4" aria-hidden />
            {props.addLabel ?? 'إضافة'}
          </Button>
        ) : null}
      </header>

      <div className="space-y-2 p-3">
        <FormError message={error} />
        {adding && props.onCreate ? (
          <ItemForm
            withCode={withCode}
            submitLabel="إضافة"
            onCancel={() => setAdding(false)}
            onSubmit={async (v) => {
              if (await run(() => props.onCreate!(v))) setAdding(false);
            }}
          />
        ) : null}

        {items.length === 0 && !adding ? (
          <p className="px-1 py-6 text-center text-sm text-muted">{props.emptyText ?? 'لا توجد عناصر بعد'}</p>
        ) : null}

        <ul className="space-y-1">
          {items.map((item, index) =>
            editing === item.id ? (
              <li key={item.id}>
                <ItemForm
                  withCode={withCode}
                  initial={{ code: item.code ?? '', name: item.name }}
                  submitLabel="حفظ"
                  onCancel={() => setEditing(null)}
                  onSubmit={async (v) => {
                    if (await run(() => props.onUpdate(item.id, withCode ? v : { name: v.name })))
                      setEditing(null);
                  }}
                />
              </li>
            ) : (
              <li
                key={item.id}
                className={cn(
                  'group flex flex-wrap items-center gap-x-2 gap-y-1 rounded-lg px-2 py-1.5',
                  props.selectedId === item.id ? 'bg-brand/10' : 'hover:bg-surface-muted',
                )}
              >
                <button
                  type="button"
                  className="min-w-32 flex-1 text-start"
                  onClick={() => props.onSelect?.(item.id)}
                  disabled={!props.onSelect}
                >
                  <span
                    className={cn('block break-words', item.isActive === false && 'text-muted line-through')}
                  >
                    {item.name}
                  </span>
                  {withCode && item.code ? (
                    <span dir="ltr" className="block truncate text-start font-mono text-xs text-muted">
                      {item.code}
                    </span>
                  ) : null}
                </button>
                <div className="ms-auto flex shrink-0 items-center gap-0.5">
                  {withActive ? (
                    <Button
                      size="sm"
                      variant="ghost"
                      title={item.isActive ? 'إخفاء عن الطلاب' : 'إظهار للطلاب'}
                      onClick={() => void run(() => props.onUpdate(item.id, { isActive: !item.isActive }))}
                      disabled={busy}
                    >
                      <span className={cn('text-xs', item.isActive ? 'text-brand' : 'text-muted')}>
                        {item.isActive ? 'ظاهر' : 'مخفي'}
                      </span>
                    </Button>
                  ) : null}
                  {props.onReorder ? (
                    <>
                      <Button
                        size="sm"
                        variant="ghost"
                        aria-label="تحريك للأعلى"
                        disabled={busy || index === 0}
                        onClick={() => move(index, -1)}
                      >
                        <ArrowUp className="size-4" />
                      </Button>
                      <Button
                        size="sm"
                        variant="ghost"
                        aria-label="تحريك للأسفل"
                        disabled={busy || index === items.length - 1}
                        onClick={() => move(index, 1)}
                      >
                        <ArrowDown className="size-4" />
                      </Button>
                    </>
                  ) : null}
                  <Button
                    size="sm"
                    variant="ghost"
                    aria-label="تعديل"
                    disabled={busy}
                    onClick={() => setEditing(item.id)}
                  >
                    <Pencil className="size-4" />
                  </Button>
                  {props.onDelete ? (
                    <Button
                      size="sm"
                      variant="ghost"
                      aria-label="حذف"
                      disabled={busy}
                      onClick={() => {
                        if (window.confirm(`حذف «${item.name}»؟`)) void run(() => props.onDelete!(item.id));
                      }}
                    >
                      <Trash2 className="size-4 text-danger" />
                    </Button>
                  ) : null}
                </div>
              </li>
            ),
          )}
        </ul>
      </div>
    </section>
  );
}

function ItemForm(props: {
  withCode: boolean;
  initial?: { code: string; name: string };
  submitLabel: string;
  onSubmit: (v: { code: string; name: string }) => Promise<void>;
  onCancel: () => void;
}) {
  const [name, setName] = useState(props.initial?.name ?? '');
  const [code, setCode] = useState(props.initial?.code ?? '');
  return (
    <form
      className="flex flex-wrap items-center gap-2 rounded-lg bg-surface-muted p-2"
      onSubmit={(e) => {
        e.preventDefault();
        void props.onSubmit({ code: code.trim(), name: name.trim() });
      }}
    >
      <Input
        aria-label="الاسم"
        placeholder="الاسم"
        value={name}
        onChange={(e) => setName(e.target.value)}
        className="min-w-40 flex-1"
        required
        autoFocus
      />
      {props.withCode ? (
        <Input
          aria-label="الرمز"
          placeholder="code"
          dir="ltr"
          value={code}
          onChange={(e) => setCode(e.target.value)}
          className="w-40 font-mono"
          pattern="[A-Za-z0-9]+([\-_][A-Za-z0-9]+)*"
          title="أحرف لاتينية وأرقام و - أو _"
          required
        />
      ) : null}
      <Button type="submit" size="sm">
        <Check className="size-4" aria-hidden />
        {props.submitLabel}
      </Button>
      <Button type="button" size="sm" variant="ghost" onClick={props.onCancel} aria-label="إلغاء">
        <X className="size-4" />
      </Button>
    </form>
  );
}
