'use client';

import { ImagePlus, Loader2, X } from 'lucide-react';
import { useRef, useState } from 'react';
import { Button } from '@/components/ui/button';
import { api, ApiError, unwrap } from '@/lib/api';

const ACCEPTED = ['image/png', 'image/jpeg', 'image/webp'];
const MAX_BYTES = 10 * 1024 * 1024;

type Kind = 'teacher' | 'cover' | 'banner' | 'flashcard';

/**
 * Upload flow of spec §12.3: ask the API for a presigned PUT, send the file straight to storage,
 * confirm, then wait until the background job has produced the WebP variants.
 */
export async function uploadImage(kind: Kind, file: File): Promise<string> {
  const created = await unwrap(
    api.POST('/api/v1/admin/uploads', { body: { kind, contentType: file.type, size: file.size } }),
  );
  const put = await fetch(created.uploadUrl, { method: 'PUT', headers: created.headers, body: file });
  if (!put.ok) throw new ApiError('UPLOAD_FAILED', 'تعذر رفع الملف', put.status);
  await unwrap(api.POST('/api/v1/admin/uploads/{id}/complete', { params: { path: { id: created.id } } }));

  for (let attempt = 0; attempt < 60; attempt++) {
    const media = await unwrap(
      api.GET('/api/v1/admin/uploads/{id}', { params: { path: { id: created.id } } }),
    );
    if (media.status === 'ready') return created.id;
    if (media.status === 'failed') throw new ApiError('UPLOAD_FAILED', 'الملف ليس صورة صالحة', 400);
    await new Promise((r) => setTimeout(r, 1000));
  }
  throw new ApiError('UPLOAD_TIMEOUT', 'استغرقت معالجة الصورة وقتاً طويلاً، حاول مجدداً', 0);
}

export function ImageUpload(props: {
  kind: Kind;
  label: string;
  imageUrl: string | null;
  /** Called with the new media id once processed, or null when the image is removed. */
  onChange: (mediaId: string | null) => Promise<unknown>;
}) {
  const input = useRef<HTMLInputElement>(null);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [preview, setPreview] = useState<string | null>(null);

  async function pick(file: File | undefined) {
    if (!file) return;
    setError(null);
    if (!ACCEPTED.includes(file.type)) return setError('الصيغ المقبولة: PNG أو JPEG أو WebP');
    if (file.size > MAX_BYTES) return setError('الحد الأقصى لحجم الصورة 10 ميغابايت');
    setBusy(true);
    setPreview(URL.createObjectURL(file));
    try {
      await props.onChange(await uploadImage(props.kind, file));
    } catch (err) {
      setError(err instanceof ApiError ? err.message : 'حدث خطأ، حاول لاحقاً');
    } finally {
      // Show the stored, processed image (or the previous one on failure) rather than the local file.
      setPreview(null);
      setBusy(false);
      if (input.current) input.current.value = '';
    }
  }

  const shown = preview ?? props.imageUrl;
  return (
    <div className="space-y-2">
      <span className="text-sm font-medium">{props.label}</span>
      <div className="flex items-center gap-3">
        <div className="flex size-20 items-center justify-center overflow-hidden rounded-lg border border-border bg-surface-muted">
          {shown ? (
            <img src={shown} alt="" className="size-full object-cover" />
          ) : (
            <ImagePlus className="size-6 text-muted" />
          )}
        </div>
        <div className="flex flex-col gap-1">
          <Button
            type="button"
            size="sm"
            variant="outline"
            disabled={busy}
            onClick={() => input.current?.click()}
          >
            {busy ? (
              <Loader2 className="size-4 animate-spin" aria-hidden />
            ) : (
              <ImagePlus className="size-4" aria-hidden />
            )}
            {busy ? 'جارٍ الرفع…' : shown ? 'تغيير الصورة' : 'رفع صورة'}
          </Button>
          {props.imageUrl && !busy ? (
            <Button
              type="button"
              size="sm"
              variant="ghost"
              onClick={() => {
                setPreview(null);
                void props.onChange(null);
              }}
            >
              <X className="size-4" aria-hidden />
              إزالة
            </Button>
          ) : null}
        </div>
        <input
          ref={input}
          type="file"
          accept={ACCEPTED.join(',')}
          className="hidden"
          aria-label={props.label}
          onChange={(e) => void pick(e.target.files?.[0])}
        />
      </div>
      {error ? <p className="text-sm text-danger">{error}</p> : null}
    </div>
  );
}
