'use client';

import Link from 'next/link';
import { Card } from '@/components/ui/card';
import { FormError } from '@/components/form-error';
import { api, unwrap } from '@/lib/api';
import { useLoad } from '@/lib/use-load';

/** All teacher tracks at a glance; they are edited from their teacher's page. */
export default function TracksPage() {
  const tracks = useLoad(
    () => unwrap(api.GET('/api/v1/admin/teacher-tracks', { params: { query: {} } })),
    [],
  );
  const teachers = useLoad(() => unwrap(api.GET('/api/v1/admin/teachers')), []);
  const teacherName = new Map((teachers.data ?? []).map((t) => [t.id, t.nameAr]));

  return (
    <div className="mx-auto max-w-5xl space-y-4">
      <h1 className="text-xl font-semibold">مسارات المدرسين</h1>
      <FormError message={tracks.error ?? teachers.error} />
      <Card className="overflow-x-auto p-0">
        <table className="w-full text-sm">
          <thead className="border-b border-border text-muted">
            <tr>
              <th className="p-3 text-start font-medium">المسار</th>
              <th className="p-3 text-start font-medium">المدرس</th>
              <th className="p-3 text-start font-medium">المادة</th>
              <th className="p-3 text-start font-medium">الحالة</th>
            </tr>
          </thead>
          <tbody>
            {(tracks.data ?? []).map((t) => (
              <tr key={t.id} className="border-b border-border last:border-0">
                <td className="p-3">
                  <Link href={`/teachers?id=${t.teacherId}`} className="text-brand hover:underline">
                    {t.titleAr}
                  </Link>
                  <div dir="ltr" className="text-start font-mono text-xs text-muted">
                    {t.slug}
                  </div>
                </td>
                <td className="p-3">{teacherName.get(t.teacherId) ?? '—'}</td>
                <td className="p-3">{t.subjectNameAr}</td>
                <td className="p-3">{t.isActive ? 'ظاهر' : <span className="text-muted">مخفي</span>}</td>
              </tr>
            ))}
            {tracks.data?.length === 0 ? (
              <tr>
                <td colSpan={4} className="p-6 text-center text-muted">
                  لا توجد مسارات بعد
                </td>
              </tr>
            ) : null}
          </tbody>
        </table>
      </Card>
    </div>
  );
}
