'use client';

import { Download, Upload } from 'lucide-react';
import { useEffect, useRef, useState } from 'react';
import { selectClass } from '@/components/access/scope-picker';
import { FormError } from '@/components/form-error';
import { Button } from '@/components/ui/button';
import { Card } from '@/components/ui/card';
import { Label } from '@/components/ui/input';
import { formatDateTime } from '@/lib/access';
import { api, unwrap } from '@/lib/api';
import type { components } from '@/lib/api-schema';
import { fileToBase64, saveFile } from '@/lib/download';
import { errorMessage, useLoad } from '@/lib/use-load';

type Kind = components['schemas']['ImportKind'];
type Format = components['schemas']['ImportFormat'];
type Job = components['schemas']['ImportJob'];

const KINDS: Record<Kind, string> = { mcq: 'اختيار من متعدد', true_false: 'صح / خطأ', written: 'كتابي' };
const STATUS: Record<Job['status'], string> = {
  parsing: 'جارٍ التحقق من الملف…',
  ready: 'جاهز للمعاينة',
  failed: 'فشل',
  importing: 'جارٍ الاستيراد…',
  completed: 'اكتمل',
};
const MAX_BYTES = 5 * 1024 * 1024;

/**
 * Bulk import and export (spec §27): CSV or XLSX rows that reference structure by code. Every row is
 * validated before anything is saved; the import itself is one transaction.
 */
export default function ImportExportPage() {
  const [kind, setKind] = useState<Kind>('mcq');
  const [job, setJob] = useState<Job | null>(null);
  const [publish, setPublish] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);
  const input = useRef<HTMLInputElement>(null);
  const jobs = useLoad(() => unwrap(api.GET('/api/v1/admin/imports')), []);

  // Poll while a job is being parsed or imported.
  const jobId = job?.id;
  const pending = job?.status === 'parsing' || job?.status === 'importing';
  useEffect(() => {
    if (!jobId || !pending) return;
    const timer = setTimeout(async () => {
      try {
        const next = await unwrap(api.GET('/api/v1/admin/imports/{id}', { params: { path: { id: jobId } } }));
        setJob(next);
        if (next.status === 'completed' || next.status === 'failed') void jobs.reload();
      } catch (err) {
        setError(errorMessage(err));
      }
    }, 1000);
    return () => clearTimeout(timer);
  }, [jobId, pending, job, jobs]);

  async function template(format: Format) {
    const { data, response } = await api.GET('/api/v1/admin/imports/template', {
      params: { query: { kind, format } },
      parseAs: 'blob',
    });
    if (response.ok && data) saveFile(data as Blob, response, `template-${kind}.${format}`);
    else setError('تعذر تنزيل القالب');
  }

  async function upload(file: File | undefined) {
    if (!file) return;
    setError(null);
    const format: Format | null = /\.csv$/i.test(file.name)
      ? 'csv'
      : /\.xlsx$/i.test(file.name)
        ? 'xlsx'
        : null;
    if (!format) return setError('الصيغ المقبولة: CSV أو XLSX');
    if (file.size > MAX_BYTES) return setError('الحد الأقصى لحجم الملف 5 ميغابايت');
    setBusy(true);
    try {
      setJob(
        await unwrap(
          api.POST('/api/v1/admin/imports', {
            body: { kind, format, fileName: file.name, contentBase64: await fileToBase64(file) },
          }),
        ),
      );
    } catch (err) {
      setError(errorMessage(err));
    } finally {
      setBusy(false);
      if (input.current) input.current.value = '';
    }
  }

  async function confirm() {
    if (!job) return;
    setError(null);
    try {
      setJob(
        await unwrap(
          api.POST('/api/v1/admin/imports/{id}/confirm', {
            params: { path: { id: job.id } },
            body: { publish },
          }),
        ),
      );
    } catch (err) {
      setError(errorMessage(err));
    }
  }

  async function open(id: string) {
    setError(null);
    try {
      setJob(await unwrap(api.GET('/api/v1/admin/imports/{id}', { params: { path: { id } } })));
    } catch (err) {
      setError(errorMessage(err));
    }
  }

  return (
    <div className="mx-auto max-w-6xl space-y-4">
      <h1 className="text-xl font-semibold">الاستيراد والتصدير</h1>
      <Card className="space-y-3">
        <h2 className="font-semibold">استيراد أسئلة</h2>
        <div className="flex flex-wrap items-end gap-3">
          <div className="space-y-1">
            <Label htmlFor="import-kind">نوع الأسئلة</Label>
            <select
              id="import-kind"
              className={selectClass}
              value={kind}
              onChange={(e) => setKind(e.target.value as Kind)}
            >
              {(Object.keys(KINDS) as Kind[]).map((k) => (
                <option key={k} value={k}>
                  {KINDS[k]}
                </option>
              ))}
            </select>
          </div>
          <Button variant="outline" onClick={() => void template('xlsx')}>
            <Download className="size-4" aria-hidden />
            قالب Excel
          </Button>
          <Button variant="outline" onClick={() => void template('csv')}>
            <Download className="size-4" aria-hidden />
            قالب CSV
          </Button>
          <Button disabled={busy} onClick={() => input.current?.click()}>
            <Upload className="size-4" aria-hidden />
            {busy ? 'جارٍ الرفع…' : 'رفع ملف'}
          </Button>
          <input
            ref={input}
            type="file"
            accept=".csv,.xlsx"
            className="hidden"
            aria-label="ملف الاستيراد"
            onChange={(e) => void upload(e.target.files?.[0])}
          />
        </div>
        <p className="text-sm text-muted">
          تُحدَّد المرحلة والمادة والوحدة والدرس بالرموز (code) والمسار بالمعرّف النصي (slug)، لا بالأسماء.
          عمود is_free_override فارغ يعني اتباع قاعدة المحتوى المجاني.
        </p>
      </Card>

      <FormError message={error} />
      {job ? (
        <JobView job={job} publish={publish} setPublish={setPublish} onConfirm={() => void confirm()} />
      ) : null}

      <ExportCard onError={setError} />

      <Card className="overflow-x-auto p-0">
        <h2 className="p-3 font-semibold">آخر عمليات الاستيراد</h2>
        <table className="w-full text-sm">
          <thead className="border-y border-border text-muted">
            <tr>
              <th className="p-3 text-start font-medium">الملف</th>
              <th className="p-3 text-start font-medium">النوع</th>
              <th className="p-3 text-start font-medium">الحالة</th>
              <th className="p-3 text-start font-medium">الصفوف</th>
              <th className="p-3 text-start font-medium">التاريخ</th>
            </tr>
          </thead>
          <tbody>
            {(jobs.data ?? []).map((j) => (
              <tr
                key={j.id}
                className="cursor-pointer border-b border-border last:border-0 hover:bg-surface-muted"
                onClick={() => void open(j.id)}
              >
                <td className="p-3" dir="ltr">
                  {j.fileName}
                </td>
                <td className="p-3">{KINDS[j.kind]}</td>
                <td className="p-3">{STATUS[j.status]}</td>
                <td className="p-3">
                  {j.validRows}/{j.totalRows}
                  {j.errorCount ? <span className="text-danger"> · {j.errorCount} خطأ</span> : null}
                </td>
                <td className="p-3">{formatDateTime(j.createdAt)}</td>
              </tr>
            ))}
            {jobs.data?.length === 0 ? (
              <tr>
                <td colSpan={5} className="p-6 text-center text-muted">
                  لا توجد عمليات بعد
                </td>
              </tr>
            ) : null}
          </tbody>
        </table>
      </Card>
    </div>
  );
}

function JobView(props: {
  job: Job;
  publish: boolean;
  setPublish: (v: boolean) => void;
  onConfirm: () => void;
}) {
  const { job } = props;
  const canImport = job.status === 'ready' && job.errorCount === 0 && job.validRows > 0;
  return (
    <Card className="space-y-3">
      <div className="flex flex-wrap items-center justify-between gap-2">
        <div>
          <div className="font-semibold" dir="auto">
            {job.fileName}
          </div>
          <div className="text-sm text-muted">
            {KINDS[job.kind]} · {STATUS[job.status]}
          </div>
        </div>
        {job.status !== 'parsing' ? (
          <div className="text-sm">
            {job.totalRows} صف · <span className="text-success">{job.validRows} صالح</span>
            {job.errorCount ? <span className="text-danger"> · {job.errorCount} خطأ</span> : null}
          </div>
        ) : null}
      </div>
      {job.failureReason ? <FormError message={job.failureReason} /> : null}
      {job.summary ? (
        <p className="rounded-lg bg-success/10 p-3 text-sm text-success">
          تم استيراد {job.summary.created} سؤالاً {job.summary.published ? 'ونشرها' : 'كمسودات'}.
        </p>
      ) : null}
      {job.errors.length ? (
        <div className="space-y-2">
          <p className="text-sm">صحّح الصفوف التالية ثم ارفع الملف من جديد؛ لا يُستورد ملف فيه أخطاء.</p>
          <div className="max-h-72 overflow-y-auto rounded-lg border border-border">
            <table className="w-full text-sm">
              <thead className="sticky top-0 bg-surface text-muted">
                <tr>
                  <th className="p-2 text-start font-medium">الصف</th>
                  <th className="p-2 text-start font-medium">العمود</th>
                  <th className="p-2 text-start font-medium">الخطأ</th>
                </tr>
              </thead>
              <tbody>
                {job.errors.map((e, i) => (
                  <tr key={i} className="border-t border-border">
                    <td className="p-2">{e.rowNumber}</td>
                    <td className="p-2 font-mono text-xs" dir="ltr">
                      {e.field ?? '—'}
                    </td>
                    <td className="p-2 text-danger">{e.message}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      ) : null}
      {job.preview.length && job.status !== 'completed' ? (
        <div className="space-y-2">
          <h3 className="text-sm font-semibold">
            معاينة{job.validRows > job.preview.length ? ` (أول ${job.preview.length})` : ''}
          </h3>
          <div className="max-h-96 overflow-auto rounded-lg border border-border">
            <table className="w-full text-sm">
              <thead className="sticky top-0 bg-surface text-muted">
                <tr>
                  <th className="p-2 text-start font-medium">الصف</th>
                  <th className="p-2 text-start font-medium">السؤال</th>
                  <th className="p-2 text-start font-medium">الإجابة / الخيارات</th>
                  <th className="p-2 text-start font-medium">المكان</th>
                  <th className="p-2 text-start font-medium">مجاني</th>
                </tr>
              </thead>
              <tbody>
                {job.preview.map((r) => (
                  <tr key={r.rowNumber} className="border-t border-border align-top">
                    <td className="p-2">{r.rowNumber}</td>
                    <td className="p-2">{r.questionText}</td>
                    <td className="p-2">
                      <span className="text-success">{r.answers[0]}</span>
                      {r.answers.length > 1 ? (
                        <span className="text-muted"> · {r.answers.slice(1).join(' · ')}</span>
                      ) : null}
                    </td>
                    <td className="p-2 font-mono text-xs" dir="ltr">
                      {[r.subjectCode, r.unitCode, r.lessonCode, r.teacherTrackCode]
                        .filter(Boolean)
                        .join(' / ')}
                    </td>
                    <td className="p-2">{r.isFree === null ? 'القاعدة' : r.isFree ? 'نعم' : 'لا'}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      ) : null}
      {job.status === 'ready' ? (
        <div className="flex flex-wrap items-center gap-3">
          <label className="flex items-center gap-2 text-sm">
            <input
              type="checkbox"
              checked={props.publish}
              onChange={(e) => props.setPublish(e.target.checked)}
            />
            نشر الأسئلة مباشرة
          </label>
          <Button disabled={!canImport} onClick={props.onConfirm}>
            استيراد {job.validRows} سؤالاً
          </Button>
        </div>
      ) : null}
    </Card>
  );
}

function ExportCard({ onError }: { onError: (message: string | null) => void }) {
  const subjects = useLoad(() => unwrap(api.GET('/api/v1/admin/subjects', { params: { query: {} } })), []);
  const [subjectId, setSubjectId] = useState('');
  const tracks = useLoad(
    () =>
      subjectId
        ? unwrap(api.GET('/api/v1/admin/teacher-tracks', { params: { query: { subjectId } } }))
        : Promise.resolve([]),
    [subjectId],
  );
  const [trackId, setTrackId] = useState('');
  const [kind, setKind] = useState<Kind>('mcq');

  async function exportAs(format: Format) {
    onError(null);
    const { data, response } = await api.GET('/api/v1/admin/questions/export', {
      params: { query: { kind, format, subjectId, ...(trackId ? { teacherTrackId: trackId } : {}) } },
      parseAs: 'blob',
    });
    if (response.ok && data) saveFile(data as Blob, response, `questions-${kind}.${format}`);
    else onError('تعذر التصدير');
  }

  return (
    <Card className="space-y-3">
      <h2 className="font-semibold">تصدير أسئلة</h2>
      <div className="grid gap-3 sm:grid-cols-3">
        <div className="space-y-1">
          <Label htmlFor="export-subject">المادة</Label>
          <select
            id="export-subject"
            className={selectClass}
            value={subjectId}
            onChange={(e) => {
              setSubjectId(e.target.value);
              setTrackId('');
            }}
          >
            <option value="">اختر المادة</option>
            {(subjects.data ?? []).map((s) => (
              <option key={s.id} value={s.id}>
                {s.nameAr} ({s.code})
              </option>
            ))}
          </select>
        </div>
        <div className="space-y-1">
          <Label htmlFor="export-track">النطاق</Label>
          <select
            id="export-track"
            className={selectClass}
            value={trackId}
            onChange={(e) => setTrackId(e.target.value)}
          >
            <option value="">المحتوى العام للمادة</option>
            {(tracks.data ?? []).map((t) => (
              <option key={t.id} value={t.id}>
                {t.titleAr}
              </option>
            ))}
          </select>
        </div>
        <div className="space-y-1">
          <Label htmlFor="export-kind">النوع</Label>
          <select
            id="export-kind"
            className={selectClass}
            value={kind}
            onChange={(e) => setKind(e.target.value as Kind)}
          >
            {(Object.keys(KINDS) as Kind[]).map((k) => (
              <option key={k} value={k}>
                {KINDS[k]}
              </option>
            ))}
          </select>
        </div>
      </div>
      <div className="flex gap-2">
        <Button variant="outline" disabled={!subjectId} onClick={() => void exportAs('xlsx')}>
          <Download className="size-4" aria-hidden />
          Excel
        </Button>
        <Button variant="outline" disabled={!subjectId} onClick={() => void exportAs('csv')}>
          <Download className="size-4" aria-hidden />
          CSV
        </Button>
      </div>
    </Card>
  );
}
