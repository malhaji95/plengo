'use client';

import { ArrowDown, ArrowUp } from 'lucide-react';
import { useState } from 'react';
import { selectClass } from '@/components/access/scope-picker';
import { FormError } from '@/components/form-error';
import { ActionFields, actionBody } from '@/components/home/action-fields';
import { ImageUpload } from '@/components/image-upload';
import { Button } from '@/components/ui/button';
import { Card } from '@/components/ui/card';
import { Input, Label } from '@/components/ui/input';
import { formatDateTime } from '@/lib/access';
import { api, unwrap } from '@/lib/api';
import type { components } from '@/lib/api-schema';
import { ACTION_LABELS, damascusToIso, isoToDamascus, type BannerAction } from '@/lib/home';
import { errorMessage, useLoad } from '@/lib/use-load';

type Banner = components['schemas']['AdminBanner'];

type Draft = {
  id: string | null;
  titleAr: string;
  imageMediaId: string | null;
  imageUrl: string | null;
  action: BannerAction;
  target: string;
  levelId: string;
  startsAt: string;
  endsAt: string;
};

const EMPTY: Draft = {
  id: null,
  titleAr: '',
  imageMediaId: null,
  imageUrl: null,
  action: 'none',
  target: '',
  levelId: '',
  startsAt: '',
  endsAt: '',
};

const fromBanner = (b: Banner): Draft => ({
  id: b.id,
  titleAr: b.titleAr,
  imageMediaId: b.imageMediaId,
  imageUrl: b.imageUrl,
  action: b.action,
  target: b.actionTarget ?? '',
  levelId: b.educationLevelId ?? '',
  startsAt: isoToDamascus(b.startsAt),
  endsAt: isoToDamascus(b.endsAt),
});

/**
 * Home banners (spec §19.2): an image, an optional schedule and education level, and a tap
 * action. Students see active banners inside their schedule, in this order.
 */
export default function BannersPage() {
  const banners = useLoad(() => unwrap(api.GET('/api/v1/admin/banners')), []);
  const levels = useLoad(() => unwrap(api.GET('/api/v1/admin/levels')), []);
  const [draft, setDraft] = useState<Draft>(EMPTY);
  const [error, setError] = useState<string | null>(null);
  const levelName = (id: string | null) =>
    id ? (levels.data?.find((l) => l.id === id)?.nameAr ?? '—') : 'جميع المراحل';

  async function run(call: () => Promise<unknown>) {
    setError(null);
    try {
      await call();
      await banners.reload();
      return true;
    } catch (err) {
      setError(errorMessage(err));
      return false;
    }
  }

  async function save(e: React.FormEvent) {
    e.preventDefault();
    if (!draft.imageMediaId) return;
    const body = {
      titleAr: draft.titleAr,
      imageMediaId: draft.imageMediaId,
      ...actionBody(draft.action, draft.target),
      educationLevelId: draft.levelId || null,
      startsAt: draft.startsAt ? damascusToIso(draft.startsAt) : null,
      endsAt: draft.endsAt ? damascusToIso(draft.endsAt) : null,
    };
    const ok = await run(() =>
      draft.id
        ? unwrap(api.PATCH('/api/v1/admin/banners/{id}', { params: { path: { id: draft.id } }, body }))
        : unwrap(api.POST('/api/v1/admin/banners', { body })),
    );
    if (ok) setDraft(EMPTY);
  }

  function move(index: number, by: number) {
    const ids = (banners.data ?? []).map((b) => b.id);
    const [id] = ids.splice(index, 1);
    ids.splice(index + by, 0, id!);
    void run(() => unwrap(api.POST('/api/v1/admin/banners/reorder', { body: { ids } })));
  }

  const list = banners.data ?? [];
  return (
    <div className="mx-auto max-w-5xl space-y-4">
      <h1 className="text-xl font-semibold">الإعلانات (البانرات)</h1>
      <Card>
        <form onSubmit={save} className="space-y-3">
          <h2 className="font-semibold">{draft.id ? 'تعديل البانر' : 'بانر جديد'}</h2>
          <ImageUpload
            kind="banner"
            label="الصورة (يفضّل 16:9)"
            imageUrl={draft.imageUrl}
            onChange={async (imageMediaId) =>
              setDraft((d) => ({ ...d, imageMediaId, imageUrl: imageMediaId ? d.imageUrl : null }))
            }
          />
          {draft.imageMediaId && !draft.imageUrl ? (
            <p className="text-sm text-success">تم رفع الصورة</p>
          ) : null}
          <div className="space-y-1">
            <Label htmlFor="banner-title">العنوان</Label>
            <Input
              id="banner-title"
              required
              value={draft.titleAr}
              onChange={(e) => setDraft({ ...draft, titleAr: e.target.value })}
            />
          </div>
          <ActionFields
            idPrefix="banner"
            action={draft.action}
            target={draft.target}
            onChange={(action, target) => setDraft({ ...draft, action, target })}
          />
          <div className="grid gap-3 sm:grid-cols-3">
            <div className="space-y-1">
              <Label htmlFor="banner-level">المرحلة</Label>
              <select
                id="banner-level"
                className={selectClass}
                value={draft.levelId}
                onChange={(e) => setDraft({ ...draft, levelId: e.target.value })}
              >
                <option value="">جميع المراحل</option>
                {(levels.data ?? []).map((l) => (
                  <option key={l.id} value={l.id}>
                    {l.nameAr}
                  </option>
                ))}
              </select>
            </div>
            <div className="space-y-1">
              <Label htmlFor="banner-start">يبدأ (بتوقيت دمشق، اختياري)</Label>
              <Input
                id="banner-start"
                type="datetime-local"
                dir="ltr"
                value={draft.startsAt}
                onChange={(e) => setDraft({ ...draft, startsAt: e.target.value })}
              />
            </div>
            <div className="space-y-1">
              <Label htmlFor="banner-end">ينتهي (بتوقيت دمشق، اختياري)</Label>
              <Input
                id="banner-end"
                type="datetime-local"
                dir="ltr"
                value={draft.endsAt}
                onChange={(e) => setDraft({ ...draft, endsAt: e.target.value })}
              />
            </div>
          </div>
          <div className="flex gap-2">
            <Button type="submit" disabled={!draft.titleAr || !draft.imageMediaId}>
              {draft.id ? 'حفظ التعديلات' : 'إنشاء البانر'}
            </Button>
            {draft.id ? (
              <Button type="button" variant="ghost" onClick={() => setDraft(EMPTY)}>
                إلغاء
              </Button>
            ) : null}
          </div>
        </form>
      </Card>
      <FormError message={banners.error ?? error} />
      <Card className="overflow-x-auto p-0">
        <table className="w-full text-sm">
          <thead className="border-b border-border text-muted">
            <tr>
              <th className="p-3 text-start font-medium">الترتيب</th>
              <th className="p-3 text-start font-medium">البانر</th>
              <th className="p-3 text-start font-medium">الإجراء</th>
              <th className="p-3 text-start font-medium">المرحلة والفترة</th>
              <th className="p-3 text-start font-medium">الحالة</th>
              <th className="p-3 text-start font-medium">إجراءات</th>
            </tr>
          </thead>
          <tbody>
            {list.map((b, i) => (
              <tr key={b.id} className="border-b border-border last:border-0">
                <td className="p-3">
                  <div className="flex gap-1">
                    <Button
                      size="sm"
                      variant="ghost"
                      aria-label="تحريك للأعلى"
                      disabled={i === 0}
                      onClick={() => move(i, -1)}
                    >
                      <ArrowUp className="size-4" aria-hidden />
                    </Button>
                    <Button
                      size="sm"
                      variant="ghost"
                      aria-label="تحريك للأسفل"
                      disabled={i === list.length - 1}
                      onClick={() => move(i, 1)}
                    >
                      <ArrowDown className="size-4" aria-hidden />
                    </Button>
                  </div>
                </td>
                <td className="p-3">
                  <div className="flex items-center gap-2">
                    {b.imageUrl ? (
                      <img src={b.imageUrl} alt="" className="h-10 w-16 rounded object-cover" />
                    ) : null}
                    {b.titleAr}
                  </div>
                </td>
                <td className="p-3">
                  {ACTION_LABELS[b.action]}
                  {b.actionTarget ? (
                    <div className="text-muted" dir="ltr">
                      {b.actionTarget}
                    </div>
                  ) : null}
                </td>
                <td className="p-3">
                  {levelName(b.educationLevelId)}
                  <div className="text-muted">
                    {b.startsAt || b.endsAt
                      ? `${formatDateTime(b.startsAt)} ← ${formatDateTime(b.endsAt)}`
                      : 'بلا جدول'}
                  </div>
                </td>
                <td className="p-3">
                  <span className={b.live ? 'text-success' : 'text-muted'}>
                    {b.live ? 'ظاهر الآن' : b.isActive ? 'خارج الفترة' : 'معطّل'}
                  </span>
                </td>
                <td className="p-3">
                  <div className="flex gap-2">
                    <Button size="sm" variant="outline" onClick={() => setDraft(fromBanner(b))}>
                      تعديل
                    </Button>
                    <Button
                      size="sm"
                      variant="outline"
                      onClick={() =>
                        void run(() =>
                          unwrap(
                            api.PATCH('/api/v1/admin/banners/{id}', {
                              params: { path: { id: b.id } },
                              body: { isActive: !b.isActive },
                            }),
                          ),
                        )
                      }
                    >
                      {b.isActive ? 'تعطيل' : 'تفعيل'}
                    </Button>
                    <Button
                      size="sm"
                      variant="ghost"
                      className="text-danger"
                      onClick={() => {
                        if (window.confirm('حذف هذا البانر؟'))
                          void run(() =>
                            unwrap(
                              api.DELETE('/api/v1/admin/banners/{id}', { params: { path: { id: b.id } } }),
                            ),
                          );
                      }}
                    >
                      حذف
                    </Button>
                  </div>
                </td>
              </tr>
            ))}
            {banners.data?.length === 0 ? (
              <tr>
                <td colSpan={6} className="p-6 text-center text-muted">
                  لا توجد بانرات
                </td>
              </tr>
            ) : null}
          </tbody>
        </table>
      </Card>
    </div>
  );
}
