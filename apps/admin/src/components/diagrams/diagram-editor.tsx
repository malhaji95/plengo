'use client';

import { ArrowDown, ArrowUp, Crosshair, Plus, Trash2 } from 'lucide-react';
import { useState } from 'react';
import { FormError } from '@/components/form-error';
import { uploadImage } from '@/components/image-upload';
import {
  EMPTY_PLACEMENT,
  PlacementPicker,
  trackIdOf,
  type Placement,
} from '@/components/questions/placement-picker';
import { Button } from '@/components/ui/button';
import { Input, Label } from '@/components/ui/input';
import { api, unwrap } from '@/lib/api';
import {
  addLabel,
  labelProblems,
  moveLabel,
  relativePoint,
  renumber,
  toDrafts,
  toLabelInputs,
  type AdminDiagram,
  type LabelDraft,
} from '@/lib/diagrams';
import { errorMessage } from '@/lib/use-load';

/**
 * «رسمات العلوم» editor (v3 §9): placement, image, and the numbered parts with their accepted
 * answers («|» between alternatives). Picking a part's ⌖ then clicking the image places its marker,
 * for images that have no numbers drawn on them.
 */
export function DiagramEditor({
  diagram,
  onSaved,
}: {
  diagram?: AdminDiagram | null;
  onSaved: (d: AdminDiagram) => void;
}) {
  const [placement, setPlacement] = useState<Placement>(
    diagram
      ? {
          subjectId: diagram.subjectId,
          track: diagram.teacherTrackId ?? 'general',
          unitId: diagram.unitId,
          lessonId: diagram.lessonId,
        }
      : EMPTY_PLACEMENT,
  );
  const [title, setTitle] = useState(diagram?.titleAr ?? '');
  const [description, setDescription] = useState(diagram?.description ?? '');
  const [imageMediaId, setImageMediaId] = useState<string | null>(diagram?.imageMediaId ?? null);
  const [imageUrl, setImageUrl] = useState<string | null>(diagram?.image?.fullUrl ?? null);
  const [labels, setLabels] = useState<LabelDraft[]>(() =>
    diagram ? toDrafts(diagram.labels) : addLabel([]),
  );
  const [placing, setPlacing] = useState<string | null>(null);
  const [publish, setPublish] = useState(false);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [uploading, setUploading] = useState(false);

  /** Shows the picked file at once (to place markers) while it uploads through the usual flow. */
  async function pickImage(file: File | undefined) {
    if (!file) return;
    setError(null);
    setUploading(true);
    try {
      setImageUrl(URL.createObjectURL(file));
      setImageMediaId(await uploadImage('flashcard', file));
    } catch (err) {
      setImageMediaId(diagram?.imageMediaId ?? null);
      setImageUrl(diagram?.image?.fullUrl ?? null);
      setError(errorMessage(err));
    } finally {
      setUploading(false);
    }
  }

  const update = (key: string, patch: Partial<LabelDraft>) =>
    setLabels((ls) => ls.map((l) => (l.key === key ? { ...l, ...patch } : l)));
  const problems = [
    ...labelProblems(labels),
    ...(!title.trim() ? ['أدخل عنوان الرسمة'] : []),
    ...(!imageMediaId || uploading ? ['ارفع صورة الرسمة'] : []),
    ...(!placement.subjectId ? ['اختر المادة'] : []),
  ];

  async function save() {
    setError(null);
    setBusy(true);
    try {
      const content = {
        unitId: placement.unitId,
        lessonId: placement.lessonId,
        titleAr: title.trim(),
        description: description.trim() || null,
        imageMediaId: imageMediaId!,
        labels: toLabelInputs(labels),
      };
      const saved = diagram
        ? await unwrap(
            api.PATCH('/api/v1/admin/diagrams/{id}', { params: { path: { id: diagram.id } }, body: content }),
          )
        : await unwrap(
            api.POST('/api/v1/admin/diagrams', {
              body: {
                ...content,
                subjectId: placement.subjectId!,
                teacherTrackId: trackIdOf(placement),
                publish,
              },
            }),
          );
      onSaved(saved);
    } catch (err) {
      setError(errorMessage(err));
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="space-y-4">
      <PlacementPicker value={placement} onChange={setPlacement} lockScope={!!diagram} />
      <div className="grid gap-3 md:grid-cols-2">
        <div className="space-y-1">
          <Label htmlFor="d-title">عنوان الرسمة</Label>
          <Input id="d-title" value={title} onChange={(e) => setTitle(e.target.value)} />
        </div>
        <div className="space-y-1">
          <Label htmlFor="d-description">وصف (اختياري)</Label>
          <Input id="d-description" value={description} onChange={(e) => setDescription(e.target.value)} />
        </div>
      </div>
      <div className="space-y-1">
        <Label htmlFor="d-image">صورة الرسمة</Label>
        <input
          id="d-image"
          type="file"
          accept="image/png,image/jpeg,image/webp"
          className="block text-sm"
          disabled={uploading}
          onChange={(e) => void pickImage(e.target.files?.[0])}
        />
        {uploading ? <p className="text-xs text-muted">جارٍ رفع الصورة ومعالجتها…</p> : null}
      </div>
      <div className="grid gap-4 lg:grid-cols-2">
        <div className="space-y-2">
          <div className="flex items-center justify-between">
            <h3 className="font-semibold">الأجزاء المرقّمة</h3>
            <div className="flex gap-2">
              <Button size="sm" variant="outline" onClick={() => setLabels((ls) => renumber(ls))}>
                إعادة الترقيم
              </Button>
              <Button size="sm" variant="outline" onClick={() => setLabels((ls) => addLabel(ls))}>
                <Plus className="size-4" aria-hidden />
                جزء
              </Button>
            </div>
          </div>
          <p className="text-xs text-muted">
            افصل بين الإجابات المقبولة بـ «|»، مثل: الغشاء البلازمي | الغشاء الخلوي. تُقارن الإجابات بعد إزالة
            التشكيل والتطويل وتوحيد الهمزات والتاء المربوطة.
          </p>
          <ul className="space-y-2">
            {labels.map((l, i) => (
              <li key={l.key} className="flex items-start gap-2 rounded-lg border border-border p-2">
                <Input
                  aria-label={`رقم الجزء ${i + 1}`}
                  type="number"
                  dir="ltr"
                  min={1}
                  className="w-16"
                  value={l.number}
                  onChange={(e) => update(l.key, { number: Number(e.target.value) })}
                />
                <div className="flex-1 space-y-1">
                  <Input
                    aria-label={`إجابات الجزء ${l.number}`}
                    placeholder="الإجابة | إجابة أخرى"
                    value={l.answers}
                    onChange={(e) => update(l.key, { answers: e.target.value })}
                  />
                  <p className="text-xs text-muted">
                    {l.x === null ? (
                      'بلا علامة (الرقم مرسوم على الصورة)'
                    ) : (
                      <span dir="ltr">
                        x {l.x} · y {l.y}
                      </span>
                    )}
                  </p>
                </div>
                <div className="flex gap-1">
                  <Button
                    size="sm"
                    variant={placing === l.key ? 'default' : 'ghost'}
                    aria-label={`تحديد موضع الجزء ${l.number}`}
                    onClick={() => setPlacing(placing === l.key ? null : l.key)}
                  >
                    <Crosshair className="size-4" aria-hidden />
                  </Button>
                  {l.x !== null ? (
                    <Button
                      size="sm"
                      variant="ghost"
                      aria-label={`إزالة موضع الجزء ${l.number}`}
                      onClick={() => update(l.key, { x: null, y: null })}
                    >
                      ×
                    </Button>
                  ) : null}
                  <Button
                    size="sm"
                    variant="ghost"
                    aria-label={`تقديم الجزء ${l.number}`}
                    onClick={() => setLabels((ls) => moveLabel(ls, i, -1))}
                  >
                    <ArrowUp className="size-4" aria-hidden />
                  </Button>
                  <Button
                    size="sm"
                    variant="ghost"
                    aria-label={`تأخير الجزء ${l.number}`}
                    onClick={() => setLabels((ls) => moveLabel(ls, i, 1))}
                  >
                    <ArrowDown className="size-4" aria-hidden />
                  </Button>
                  <Button
                    size="sm"
                    variant="ghost"
                    aria-label={`حذف الجزء ${l.number}`}
                    onClick={() => setLabels((ls) => ls.filter((x) => x.key !== l.key))}
                  >
                    <Trash2 className="size-4" aria-hidden />
                  </Button>
                </div>
              </li>
            ))}
          </ul>
        </div>
        <div className="space-y-2">
          <h3 className="font-semibold">المعاينة</h3>
          {placing ? <p className="text-xs text-brand">اضغط على الصورة لوضع علامة الجزء المحدد</p> : null}
          {imageUrl ? (
            <div className="relative inline-block max-w-full">
              <img
                src={imageUrl}
                alt="معاينة الرسمة"
                className={`max-h-[28rem] max-w-full rounded-lg border border-border ${placing ? 'cursor-crosshair' : ''}`}
                onClick={(e) => {
                  if (!placing) return;
                  const p = relativePoint(e, e.currentTarget.getBoundingClientRect());
                  update(placing, p);
                  setPlacing(null);
                }}
              />
              {labels
                .filter((l) => l.x !== null && l.y !== null)
                .map((l) => (
                  <span
                    key={l.key}
                    className="pointer-events-none absolute flex size-6 -translate-x-1/2 -translate-y-1/2 items-center justify-center rounded-full bg-brand text-xs font-bold text-brand-foreground"
                    style={{ left: `${l.x! * 100}%`, top: `${l.y! * 100}%` }}
                  >
                    {l.number}
                  </span>
                ))}
            </div>
          ) : (
            <p className="text-sm text-muted">لم تُرفع صورة بعد</p>
          )}
        </div>
      </div>
      {problems.length ? (
        <ul className="list-inside list-disc text-sm text-danger">
          {problems.map((p) => (
            <li key={p}>{p}</li>
          ))}
        </ul>
      ) : null}
      <FormError message={error} />
      <div className="flex items-center gap-3">
        {!diagram ? (
          <label className="flex items-center gap-2 text-sm">
            <input type="checkbox" checked={publish} onChange={(e) => setPublish(e.target.checked)} />
            نشر مباشرة
          </label>
        ) : null}
        <Button disabled={busy || problems.length > 0} onClick={() => void save()}>
          {diagram ? 'حفظ التعديلات' : 'إنشاء الرسمة'}
        </Button>
      </div>
    </div>
  );
}
