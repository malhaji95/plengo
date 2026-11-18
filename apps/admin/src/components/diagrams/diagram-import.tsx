'use client';

import { Loader2 } from 'lucide-react';
import { useState } from 'react';
import { FormError } from '@/components/form-error';
import { uploadImage } from '@/components/image-upload';
import { Button } from '@/components/ui/button';
import { Label } from '@/components/ui/input';
import { api, unwrap } from '@/lib/api';
import { isImageName } from '@/lib/bulk-pairs';
import { matchImages, type DiagramImportResult } from '@/lib/diagrams';
import { fileToBase64, saveFile } from '@/lib/download';
import { errorMessage } from '@/lib/use-load';
import { unzipImages } from '@/lib/zip';

const MAX_IMAGE_BYTES = 10 * 1024 * 1024;

/**
 * Diagram bulk import (v3 §9): an Excel/CSV sheet with one row per numbered part (diagram_ref groups
 * rows; answers separated by «|») plus the images, picked as files or a ZIP. «تحقق» validates the
 * sheet on the server; «استيراد» uploads the referenced images through the usual flow and creates
 * every diagram in one transaction.
 */
export function DiagramImport({ onDone }: { onDone: () => void }) {
  const [sheet, setSheet] = useState<File | null>(null);
  const [images, setImages] = useState<File[]>([]);
  const [result, setResult] = useState<DiagramImportResult | null>(null);
  const [publish, setPublish] = useState(false);
  const [progress, setProgress] = useState<string | null>(null);
  const [message, setMessage] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  const format = (f: File) => (/\.csv$/i.test(f.name) ? ('csv' as const) : ('xlsx' as const));
  const matched = result ? matchImages(result.requiredImages, images) : null;
  const ready = !!result && result.errors.length === 0 && matched?.missing.length === 0;

  async function pickImages(list: FileList | null) {
    if (!list?.length) return;
    setError(null);
    try {
      const picked: File[] = [];
      for (const f of Array.from(list)) {
        if (/\.zip$/i.test(f.name)) picked.push(...(await unzipImages(f, isImageName)));
        else if (isImageName(f.name)) picked.push(f);
      }
      const tooBig = picked.find((f) => f.size > MAX_IMAGE_BYTES);
      if (tooBig) return setError(`الملف ${tooBig.name} أكبر من 10 ميغابايت`);
      setImages((prev) => [...prev.filter((p) => !picked.some((n) => n.name === p.name)), ...picked]);
    } catch {
      setError('تعذرت قراءة الملفات');
    }
  }

  async function send(dryRun: boolean, mediaIds?: Record<string, string>) {
    return unwrap(
      api.POST('/api/v1/admin/diagrams/import', {
        body: {
          format: format(sheet!),
          fileName: sheet!.name,
          contentBase64: await fileToBase64(sheet!),
          dryRun,
          publish,
          ...(mediaIds ? { images: mediaIds } : {}),
        },
      }),
    );
  }

  async function validate() {
    setError(null);
    setMessage(null);
    try {
      setResult(await send(true));
    } catch (err) {
      setError(errorMessage(err));
    }
  }

  async function run() {
    if (!result || !matched) return;
    setError(null);
    try {
      const mediaIds: Record<string, string> = {};
      const names = result.requiredImages;
      for (const [i, name] of names.entries()) {
        setProgress(`${i + 1} / ${names.length}`);
        mediaIds[name] = await uploadImage('flashcard', matched.found.get(name) as File);
      }
      setProgress('…');
      const done = await send(false, mediaIds);
      setResult(done);
      if (done.createdIds.length) {
        setMessage(`تم إنشاء ${done.createdIds.length} رسمة`);
        setSheet(null);
        setImages([]);
        onDone();
      }
    } catch (err) {
      setError(errorMessage(err));
    } finally {
      setProgress(null);
    }
  }

  async function template(fmt: 'csv' | 'xlsx') {
    const { data, response } = await api.GET('/api/v1/admin/diagrams/import/template', {
      params: { query: { format: fmt } },
      parseAs: 'blob',
    });
    if (response.ok && data) saveFile(data as Blob, response, `diagrams-template.${fmt}`);
    else setError('تعذر تنزيل القالب');
  }

  return (
    <div className="space-y-3">
      <div className="flex flex-wrap items-center justify-between gap-2">
        <h2 className="font-semibold">استيراد رسمات من ملف</h2>
        <div className="flex gap-2">
          <Button size="sm" variant="outline" onClick={() => void template('xlsx')}>
            قالب Excel
          </Button>
          <Button size="sm" variant="outline" onClick={() => void template('csv')}>
            قالب CSV
          </Button>
        </div>
      </div>
      <p className="text-xs text-muted">
        صف لكل جزء مرقّم. الأعمدة:{' '}
        <span dir="ltr">
          diagram_ref, education_level_code, subject_code, unit_code, lesson_code, teacher_track_code, title,
          image_file, label_number, answers, x, y
        </span>
        . الإجابات المقبولة مفصولة بـ «|»، و x و y (اختياريان) بين 0 و 1.
      </p>
      <div className="grid gap-3 md:grid-cols-2">
        <div className="space-y-1">
          <Label htmlFor="diagram-sheet">ملف الجدول (xlsx أو csv)</Label>
          <input
            id="diagram-sheet"
            type="file"
            accept=".xlsx,.csv"
            className="block text-sm"
            onChange={(e) => {
              setSheet(e.target.files?.[0] ?? null);
              setResult(null);
              setMessage(null);
            }}
          />
        </div>
        <div className="space-y-1">
          <Label htmlFor="diagram-images">الصور (عدة ملفات أو ZIP)</Label>
          <input
            id="diagram-images"
            type="file"
            multiple
            accept="image/png,image/jpeg,image/webp,.zip,application/zip"
            className="block text-sm"
            onChange={(e) => void pickImages(e.target.files)}
          />
          {images.length ? <p className="text-xs text-muted">{images.length} صورة محددة</p> : null}
        </div>
      </div>
      <div className="flex flex-wrap items-center gap-3">
        <Button variant="outline" disabled={!sheet || !!progress} onClick={() => void validate()}>
          تحقق
        </Button>
        <label className="flex items-center gap-2 text-sm">
          <input type="checkbox" checked={publish} onChange={(e) => setPublish(e.target.checked)} />
          نشر بعد الاستيراد
        </label>
        <Button disabled={!ready || !!progress} onClick={() => void run()}>
          {progress ? <Loader2 className="size-4 animate-spin" aria-hidden /> : null}
          {progress ? `جارٍ الرفع ${progress}` : 'استيراد'}
        </Button>
      </div>
      {result ? (
        <div className="space-y-2 text-sm">
          <p>
            {result.totalRows} صف · {result.diagrams.length} رسمة
            {result.errors.length ? <span className="text-danger"> · {result.errors.length} خطأ</span> : null}
          </p>
          {matched?.missing.length ? (
            <p className="text-danger">
              صور غير محددة: <span dir="ltr">{matched.missing.join('، ')}</span>
            </p>
          ) : null}
          {result.errors.length ? (
            <ul className="max-h-48 overflow-auto rounded-lg border border-border p-2">
              {result.errors.map((e, i) => (
                <li key={i}>
                  الصف {e.rowNumber}
                  {e.field ? (
                    <>
                      {' '}
                      · <span dir="ltr">{e.field}</span>
                    </>
                  ) : null}
                  : {e.message}
                </li>
              ))}
            </ul>
          ) : null}
          <div className="max-h-64 overflow-auto rounded-lg border border-border">
            <table className="w-full">
              <thead className="sticky top-0 bg-surface text-muted">
                <tr>
                  <th className="p-2 text-start font-medium">المرجع</th>
                  <th className="p-2 text-start font-medium">العنوان</th>
                  <th className="p-2 text-start font-medium">الصورة</th>
                  <th className="p-2 text-start font-medium">الأجزاء</th>
                </tr>
              </thead>
              <tbody>
                {result.diagrams.map((d) => (
                  <tr key={d.ref} className="border-t border-border">
                    <td className="p-2" dir="ltr">
                      {d.ref}
                    </td>
                    <td className="p-2">{d.titleAr}</td>
                    <td className="p-2" dir="ltr">
                      {d.imageFile}
                    </td>
                    <td className="p-2">
                      {d.labels.map((l) => `${l.number}. ${l.answers.join(' | ')}`).join('، ')}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      ) : null}
      {message ? <p className="text-sm text-brand">{message}</p> : null}
      <FormError message={error} />
    </div>
  );
}
