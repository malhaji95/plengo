'use client';

import Link from 'next/link';
import { useState } from 'react';
import { FormError } from '@/components/form-error';
import { Card } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { formatDate } from '@/lib/access';
import { api, unwrap } from '@/lib/api';
import { Button } from '@/components/ui/button';
import type { components } from '@/lib/api-schema';
import { useLoad } from '@/lib/use-load';

type AdminStudent = components['schemas']['AdminStudent'];

/** Student search by email, name or id (spec §26.2). */
export default function StudentsPage() {
  const [q, setQ] = useState('');
  const [query, setQuery] = useState('');
  const [pages, setPages] = useState<string[]>([]);
  const [more, setMore] = useState<AdminStudent[]>([]);
  const students = useLoad(async () => {
    setMore([]);
    setPages([]);
    return unwrap(api.GET('/api/v1/admin/students', { params: { query: query ? { q: query } : {} } }));
  }, [query]);
  const nextCursor = pages.length ? pages[pages.length - 1] : students.data?.nextCursor;
  const list = [...(students.data?.items ?? []), ...more];

  async function loadMore() {
    if (!nextCursor) return;
    const page = await unwrap(
      api.GET('/api/v1/admin/students', {
        params: { query: { ...(query ? { q: query } : {}), cursor: nextCursor } },
      }),
    );
    setMore((m) => [...m, ...page.items]);
    setPages((p) => [...p, page.nextCursor ?? '']);
  }

  return (
    <div className="mx-auto max-w-5xl space-y-4">
      <h1 className="text-xl font-semibold">الطلاب</h1>
      <form
        onSubmit={(e) => {
          e.preventDefault();
          setQuery(q.trim());
        }}
      >
        <Input
          type="search"
          placeholder="ابحث بالبريد الإلكتروني أو الاسم"
          aria-label="بحث"
          value={q}
          onChange={(e) => setQ(e.target.value)}
        />
      </form>
      <FormError message={students.error} />
      <Card className="overflow-x-auto p-0">
        <table className="w-full text-sm">
          <thead className="border-b border-border text-muted">
            <tr>
              <th className="p-3 text-start font-medium">الطالب</th>
              <th className="p-3 text-start font-medium">صلاحيات فعّالة</th>
              <th className="p-3 text-start font-medium">تاريخ التسجيل</th>
            </tr>
          </thead>
          <tbody>
            {list.map((s) => (
              <tr key={s.id} className="border-b border-border last:border-0">
                <td className="p-3">
                  <Link href={`/students/${s.id}`} className="text-brand hover:underline">
                    {s.fullName ?? '—'}
                  </Link>
                  <div dir="ltr" className="text-start text-xs text-muted">
                    {s.email}
                  </div>
                </td>
                <td className="p-3">{s.activeEntitlementCount}</td>
                <td className="p-3">{formatDate(s.createdAt)}</td>
              </tr>
            ))}
            {students.data?.items.length === 0 ? (
              <tr>
                <td colSpan={3} className="p-6 text-center text-muted">
                  لا يوجد طلاب مطابقون
                </td>
              </tr>
            ) : null}
          </tbody>
        </table>
      </Card>
      {nextCursor ? (
        <Button variant="outline" onClick={() => void loadMore()}>
          تحميل المزيد
        </Button>
      ) : null}
    </div>
  );
}
