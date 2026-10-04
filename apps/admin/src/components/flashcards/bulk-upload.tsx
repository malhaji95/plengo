'use client';

import { ArrowLeftRight, CloudUpload, Loader2, Trash2 } from 'lucide-react';
import { useEffect, useMemo, useRef, useState } from 'react';
import { selectClass } from '@/components/access/scope-picker';
import { FormError } from '@/components/form-error';
import { uploadImage } from '@/components/image-upload';
import { Button } from '@/components/ui/button';
import { api, unwrap } from '@/lib/api';
import { isImageName, naturalCompare, pairFiles } from '@/lib/bulk-pairs';
import { errorMessage } from '@/lib/use-load';
import { unzipImages } from '@/lib/zip';

const MAX_BYTES = 10 * 1024 * 1024;
const MAX_PAIRS = 300;

type Row = { key: string; front: string; back: string };

/**
 * Flashcard bulk upload (spec §27): pick images or a ZIP; files are paired by prefix
 * (`001-front.png` + `001-back.png`) into a grid the admin can correct, then uploaded through the
 * usual presigned flow and appended to the deck in order.
 */
export function BulkUpload({ deckId, onDone }: { deckId: string; onDone: () => void }) {
  const input = useRef<HTMLInputElement>(null);
  const [files, setFiles] = useState<Map<string, File>>(new Map());
  const [rows, setRows] = useState<Row[]>([]);
  const [progress, setProgress] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  async function pick(list: FileList | null) {
    if (!list?.length) return;
    setError(null);
    try {
      const picked: File[] = [];
      for (const f of Array.from(list)) {
        if (/\.zip$/i.test(f.name)) picked.push(...(await unzipImages(f, isImageName)));
        else if (isImageName(f.name)) picked.push(f);
      }
      const tooBig = picked.find((f) => f.size > MAX_BYTES);
      if (tooBig) return setError(`الملف ${tooBig.name} أكبر من 10 ميغابايت`);
      const map = new Map(picked.map((f) => [f.name, f]));
      const { pairs } = pairFiles(picked);
      setFiles(map);
      setRows(pairs.map((p) => ({ key: p.key, front: p.front?.name ?? '', back: p.back?.name ?? '' })));
    } catch {
      setError('تعذرت قراءة الملفات');
    } finally {
      if (input.current) input.current.value = '';
    }
  }

  // Thumbnails for the pair grid, revoked when the selection changes. A file the browser cannot
  // preview simply has none.
  const thumbs = useMemo(() => {
    const urls = new Map<string, string>();
    for (const [name, f] of files) {
      try {
        urls.set(name, URL.createObjectURL(f));
      } catch {
        // no preview
      }
    }
    return urls;
  }, [files]);
  useEffect(() => () => thumbs.forEach((u) => URL.revokeObjectURL(u)), [thumbs]);
  const [dragging, setDragging] = useState(false);

  const used = new Set(rows.flatMap((r) => [r.front, r.back]).filter(Boolean));
  const unmatched = [...files.keys()].filter((n) => !used.has(n)).sort(naturalCompare);
  const names = [...files.keys()].sort(naturalCompare);
  const complete = rows.filter((r) => r.front && r.back && r.front !== r.back);
  const ready = rows.length > 0 && complete.length === rows.length && rows.length <= MAX_PAIRS;
  const update = (i: number, patch: Partial<Row>) =>
    setRows((rs) => rs.map((r, j) => (j === i ? { ...r, ...patch } : r)));

  async function upload() {
    setError(null);
    try {
      const cards: { frontMediaId: string; backMediaId: string }[] = [];
      for (const [i, r] of rows.entries()) {
        setProgress(`${i + 1} / ${rows.length}`);
        const [frontMediaId, backMediaId] = await Promise.all([
          uploadImage('flashcard', files.get(r.front)!),
          uploadImage('flashcard', files.get(r.back)!),
        ]);
        cards.push({ frontMediaId, backMediaId });
      }
      await unwrap(
        api.POST('/api/v1/admin/decks/{id}/cards/bulk', {
          params: { path: { id: deckId } },
          body: { cards },
        }),
      );
      setRows([]);
      setFiles(new Map());
      onDone();
    } catch (err) {
      setError(errorMessage(err));
    } finally {
      setProgress(null);
    }
  }

  return (
    <div className="space-y-3">
      <button
        type="button"
        disabled={!!progress}
        onClick={() => input.current?.click()}
        onDragOver={(e) => {
          e.preventDefault();
          setDragging(true);
        }}
        onDragLeave={() => setDragging(false)}
        onDrop={(e) => {
          e.preventDefault();
          setDragging(false);
          void pick(e.dataTransfer.files);
        }}
        className={`flex w-full flex-col items-center gap-2 rounded-xl border-2 border-dashed p-6 text-center transition-colors ${
          dragging ? 'border-brand bg-brand/5' : 'border-border hover:bg-surface-muted'
        }`}
      >
        <CloudUpload className="size-8 text-brand" aria-hidden />
        <span className="font-semibold">رفع جماعي: اسحب الصور أو ملف ZIP هنا، أو اضغط للاختيار</span>
        <span className="text-xs text-muted">
          PNG · JPG · WEBP حتى 10 ميغابايت للصورة، وحتى {MAX_PAIRS} بطاقة في المرة. تُقرن الملفات بالاسم:{' '}
          <span dir="ltr">001-front.png · 001-back.png</span>
        </span>
      </button>
      <input
        ref={input}
        type="file"
        multiple
        accept="image/png,image/jpeg,image/webp,.zip,application/zip"
        className="hidden"
        aria-label="ملفات الرفع الجماعي"
        onChange={(e) => void pick(e.target.files)}
      />
      {rows.length ? (
        <>
          <p className="text-sm">
            <span className="font-semibold">{complete.length}</span> بطاقة مقترنة
            {rows.length > complete.length ? (
              <span className="text-danger"> · {rows.length - complete.length} بحاجة إلى تصحيح</span>
            ) : null}
          </p>
          <div className="max-h-[28rem] overflow-auto rounded-lg border border-border">
            <table className="w-full text-sm">
              <thead className="sticky top-0 bg-surface text-muted">
                <tr>
                  <th className="p-2 text-start font-medium">#</th>
                  <th className="p-2 text-start font-medium">الوجه الأمامي</th>
                  <th className="p-2 text-start font-medium">الوجه الخلفي</th>
                  <th className="p-2" />
                </tr>
              </thead>
              <tbody>
                {rows.map((r, i) => (
                  <tr key={`${r.key}-${i}`} className="border-t border-border">
                    <td className="p-2" dir="ltr">
                      {r.key}
                    </td>
                    {(['front', 'back'] as const).map((sideName) => (
                      <td key={sideName} className="p-2">
                        <div className="flex items-center gap-2">
                          {thumbs.get(r[sideName]) ? (
                            <img
                              src={thumbs.get(r[sideName])}
                              alt=""
                              className="size-12 shrink-0 rounded-md border border-border object-cover"
                            />
                          ) : (
                            <span className="size-12 shrink-0 rounded-md border border-dashed border-border" />
                          )}
                          <select
                            aria-label={`${sideName === 'front' ? 'أمامي' : 'خلفي'} ${r.key}`}
                            className={`${selectClass} ${r[sideName] ? '' : 'border-danger'}`}
                            dir="ltr"
                            value={r[sideName]}
                            onChange={(e) => update(i, { [sideName]: e.target.value })}
                          >
                            <option value="">—</option>
                            {names.map((n) => (
                              <option key={n} value={n}>
                                {n}
                              </option>
                            ))}
                          </select>
                        </div>
                      </td>
                    ))}
                    <td className="p-2">
                      <div className="flex gap-1">
                        <Button
                          size="sm"
                          variant="ghost"
                          aria-label={`تبديل الوجهين ${r.key}`}
                          onClick={() => update(i, { front: r.back, back: r.front })}
                        >
                          <ArrowLeftRight className="size-4" aria-hidden />
                        </Button>
                        <Button
                          size="sm"
                          variant="ghost"
                          aria-label={`حذف ${r.key}`}
                          onClick={() => setRows((rs) => rs.filter((_, j) => j !== i))}
                        >
                          <Trash2 className="size-4" aria-hidden />
                        </Button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
          {unmatched.length ? (
            <p className="text-sm text-muted">
              ملفات غير مقترنة ({unmatched.length}): <span dir="ltr">{unmatched.join('، ')}</span>
              <Button
                size="sm"
                variant="ghost"
                onClick={() => setRows((rs) => [...rs, { key: String(rs.length + 1), front: '', back: '' }])}
              >
                إضافة صف
              </Button>
            </p>
          ) : null}
          {rows.length > MAX_PAIRS ? (
            <p className="text-sm text-danger">الحد الأقصى {MAX_PAIRS} بطاقة في المرة الواحدة</p>
          ) : null}
          <Button disabled={!ready || !!progress} onClick={() => void upload()}>
            {progress ? <Loader2 className="size-4 animate-spin" aria-hidden /> : null}
            {progress ? `جارٍ الرفع ${progress}` : `رفع ${rows.length} بطاقة`}
          </Button>
        </>
      ) : null}
      <FormError message={error} />
    </div>
  );
}
