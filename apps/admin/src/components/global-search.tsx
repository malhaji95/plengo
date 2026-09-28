'use client';

import { Search } from 'lucide-react';
import Link from 'next/link';
import { useEffect, useRef, useState } from 'react';
import { api, unwrap } from '@/lib/api';
import type { components } from '@/lib/api-schema';

type Hit = components['schemas']['AdminSearchHit'];

const TYPE_LABELS: Record<Hit['type'], string> = {
  admin: 'المشرفون',
  student: 'الطلاب',
  teacher: 'المدرسون',
  track: 'المسارات',
  subject: 'المواد',
  question: 'الأسئلة',
  coupon: 'الكوبونات',
  batch: 'دفعات الكوبونات',
};

/** Where each hit opens in the admin. */
export function hitHref(h: Hit): string {
  switch (h.type) {
    case 'admin':
      return '/admins';
    case 'student':
      return `/students/${h.id}`;
    case 'teacher':
      return `/teachers?id=${h.id}`;
    case 'track':
      return `/teachers?id=${h.parentId}`;
    case 'subject':
      return `/subjects/${h.id}`;
    case 'question':
      return `/questions/${h.id}`;
    case 'coupon':
      return `/coupons/${h.parentId}`;
    case 'batch':
      return `/coupons/${h.id}`;
  }
}

/**
 * Global admin search (spec §26.2): admins, students, teachers, tracks, subjects, questions,
 * coupons (full code or last four) and batches. Debounced; results grouped by type.
 */
export function GlobalSearch() {
  const [q, setQ] = useState('');
  const [hits, setHits] = useState<Hit[] | null>(null);
  const [open, setOpen] = useState(false);
  const box = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const query = q.trim();
    if (query.length < 2) {
      setHits(null);
      return;
    }
    let cancelled = false;
    const timer = setTimeout(() => {
      unwrap(api.GET('/api/v1/admin/search', { params: { query: { q: query } } }))
        .then((r) => !cancelled && setHits(r.items))
        .catch(() => !cancelled && setHits([]));
    }, 250);
    return () => {
      cancelled = true;
      clearTimeout(timer);
    };
  }, [q]);

  useEffect(() => {
    const close = (e: MouseEvent) => {
      if (box.current && !box.current.contains(e.target as Node)) setOpen(false);
    };
    document.addEventListener('mousedown', close);
    return () => document.removeEventListener('mousedown', close);
  }, []);

  const groups = (Object.keys(TYPE_LABELS) as Hit['type'][])
    .map((type) => ({ type, items: (hits ?? []).filter((h) => h.type === type) }))
    .filter((g) => g.items.length);

  return (
    <div ref={box} className="relative w-full max-w-md">
      <Search
        className="pointer-events-none absolute start-3 top-1/2 size-4 -translate-y-1/2 text-muted"
        aria-hidden
      />
      <input
        type="search"
        aria-label="بحث شامل"
        placeholder="بحث: طالب، مادة، سؤال، كوبون…"
        className="h-9 w-full rounded-lg border border-border bg-surface ps-9 pe-3 text-sm"
        value={q}
        onChange={(e) => {
          setQ(e.target.value);
          setOpen(true);
        }}
        onFocus={() => setOpen(true)}
        onKeyDown={(e) => e.key === 'Escape' && setOpen(false)}
      />
      {open && hits ? (
        <div
          role="listbox"
          className="absolute inset-x-0 top-full z-30 mt-1 max-h-[70vh] overflow-y-auto rounded-lg border border-border bg-surface p-1 shadow-lg"
        >
          {groups.length === 0 ? <p className="p-3 text-sm text-muted">لا نتائج</p> : null}
          {groups.map((g) => (
            <div key={g.type} className="py-1">
              <div className="px-2 py-1 text-xs font-medium text-muted">{TYPE_LABELS[g.type]}</div>
              {g.items.map((h) => (
                <Link
                  key={`${h.type}:${h.id}`}
                  href={hitHref(h)}
                  role="option"
                  aria-selected={false}
                  className="block rounded-md px-2 py-1.5 text-sm hover:bg-surface-muted"
                  onClick={() => {
                    setOpen(false);
                    setQ('');
                  }}
                >
                  <span className="block truncate">{h.title}</span>
                  {h.subtitle ? (
                    <span className="block truncate text-xs text-muted" dir="auto">
                      {h.subtitle}
                    </span>
                  ) : null}
                </Link>
              ))}
            </div>
          ))}
        </div>
      ) : null}
    </div>
  );
}
