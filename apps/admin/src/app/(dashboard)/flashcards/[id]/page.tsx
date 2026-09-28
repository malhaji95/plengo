'use client';

import { ArrowDown, ArrowRight, ArrowUp, Loader2, Plus, Trash2 } from 'lucide-react';
import Link from 'next/link';
import { useParams, useRouter } from 'next/navigation';
import { useState } from 'react';
import { selectClass } from '@/components/access/scope-picker';
import { FormError } from '@/components/form-error';
import { BulkUpload } from '@/components/flashcards/bulk-upload';
import { ImageUpload, uploadImage } from '@/components/image-upload';
import { PlacementPicker, type Placement } from '@/components/questions/placement-picker';
import { Button } from '@/components/ui/button';
import { Card } from '@/components/ui/card';
import { Input, Label } from '@/components/ui/input';
import { api, unwrap } from '@/lib/api';
import type { components } from '@/lib/api-schema';
import { freeLabel, STATUS_LABELS } from '@/lib/questions';
import { errorMessage, useLoad } from '@/lib/use-load';

type Deck = components['schemas']['AdminDeck'];
type AdminCard = components['schemas']['AdminCard'];

/** One deck: details, publishing, free status, and its front/back image cards (spec §13.1). */
export default function DeckPage() {
  const { id } = useParams<{ id: string }>();
  const router = useRouter();
  const deck = useLoad(() => unwrap(api.GET('/api/v1/admin/decks/{id}', { params: { path: { id } } })), [id]);
  const cards = useLoad(
    () => unwrap(api.GET('/api/v1/admin/decks/{id}/cards', { params: { path: { id } } })),
    [id],
  );
  const [error, setError] = useState<string | null>(null);

  async function run(call: () => Promise<unknown>) {
    setError(null);
    try {
      await call();
      await Promise.all([deck.reload(), cards.reload()]);
    } catch (err) {
      setError(errorMessage(err));
    }
  }

  const d = deck.data;
  const list = cards.data ?? [];

  const move = (index: number, delta: number) => {
    const ids = list.map((c) => c.id);
    const [moved] = ids.splice(index, 1);
    ids.splice(index + delta, 0, moved!);
    return run(() =>
      unwrap(api.POST('/api/v1/admin/decks/{id}/cards/reorder', { params: { path: { id } }, body: { ids } })),
    );
  };

  return (
    <div className="mx-auto max-w-6xl space-y-4">
      <Link href="/flashcards" className="inline-flex items-center gap-1 text-sm text-brand">
        <ArrowRight className="size-4" aria-hidden />
        كل المجموعات
      </Link>
      <FormError message={deck.error ?? cards.error ?? error} />
      {d ? (
        <>
          <Card className="flex flex-wrap items-center justify-between gap-3">
            <div className="space-y-1 text-sm">
              <h1 className="text-xl font-semibold">{d.titleAr}</h1>
              <p>
                <span className="font-semibold">{STATUS_LABELS[d.status]}</span> · {freeLabel(d)} ·{' '}
                {d.cardCount} بطاقة منشورة · الإصدار {d.contentVersion}
              </p>
              <p className="text-muted">
                {d.subjectNameAr}
                {d.trackTitleAr ? ` · ${d.trackTitleAr}` : ' · المحتوى العام'}
              </p>
            </div>
            <div className="flex flex-wrap items-center gap-2">
              {d.status !== 'published' ? (
                <Button
                  onClick={() =>
                    void run(() =>
                      unwrap(
                        api.POST('/api/v1/admin/decks/{id}/status', {
                          params: { path: { id } },
                          body: { status: 'published' },
                        }),
                      ),
                    )
                  }
                >
                  نشر
                </Button>
              ) : (
                <Button
                  variant="outline"
                  onClick={() =>
                    void run(() =>
                      unwrap(
                        api.POST('/api/v1/admin/decks/{id}/status', {
                          params: { path: { id } },
                          body: { status: 'archived' },
                        }),
                      ),
                    )
                  }
                >
                  أرشفة
                </Button>
              )}
              <select
                aria-label="الوصول المجاني"
                className={`${selectClass} w-44`}
                value={d.freeSource === 'rule' ? 'rule' : d.isFree ? 'free' : 'paid'}
                onChange={(e) =>
                  void run(() =>
                    unwrap(
                      api.PUT('/api/v1/admin/decks/{id}/free', {
                        params: { path: { id } },
                        body: { mode: e.target.value as 'rule' | 'free' | 'paid' },
                      }),
                    ),
                  )
                }
              >
                <option value="rule">حسب قاعدة النطاق</option>
                <option value="free">مجانية دائماً</option>
                <option value="paid">مدفوعة دائماً</option>
              </select>
              <Button
                variant="ghost"
                className="text-danger"
                onClick={() => {
                  if (!window.confirm('حذف هذه المجموعة؟ تبقى مراجعات الطلاب السابقة محفوظة.')) return;
                  void run(async () => {
                    await unwrap(api.DELETE('/api/v1/admin/decks/{id}', { params: { path: { id } } }));
                    router.push('/flashcards');
                  });
                }}
              >
                حذف
              </Button>
            </div>
          </Card>
          <DeckDetails key={`${d.id}-${d.contentVersion}`} deck={d} onSaved={() => void deck.reload()} />
        </>
      ) : null}

      <Card className="space-y-3">
        <h2 className="font-semibold">البطاقات ({list.length})</h2>
        <NewCard deckId={id} onCreated={() => void run(async () => {})} />
        <BulkUpload deckId={id} onDone={() => void run(async () => {})} />
        <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
          {list.map((c, i) => (
            <CardTile
              key={c.id}
              card={c}
              index={i}
              count={list.length}
              onMove={(delta) => void move(i, delta)}
              run={run}
            />
          ))}
        </div>
      </Card>
    </div>
  );
}

function DeckDetails({ deck, onSaved }: { deck: Deck; onSaved: () => void }) {
  const [title, setTitle] = useState(deck.titleAr);
  const [description, setDescription] = useState(deck.description ?? '');
  const [placement, setPlacement] = useState<Placement>({
    subjectId: deck.subjectId,
    track: deck.teacherTrackId ?? 'general',
    unitId: deck.unitId,
    lessonId: deck.lessonId,
  });
  const [error, setError] = useState<string | null>(null);

  const save = (body: components['schemas']['UpdateDeckRequest']) =>
    unwrap(api.PATCH('/api/v1/admin/decks/{id}', { params: { path: { id: deck.id } }, body }));

  return (
    <Card className="space-y-3">
      <div className="grid gap-4 md:grid-cols-[1fr_12rem]">
        <div className="space-y-3">
          <div className="space-y-1">
            <Label htmlFor="deck-title">العنوان</Label>
            <Input id="deck-title" value={title} onChange={(e) => setTitle(e.target.value)} />
          </div>
          <div className="space-y-1">
            <Label htmlFor="deck-description">الوصف</Label>
            <Input
              id="deck-description"
              value={description}
              onChange={(e) => setDescription(e.target.value)}
            />
          </div>
        </div>
        <ImageUpload
          kind="cover"
          label="صورة الغلاف"
          imageUrl={deck.coverUrl}
          onChange={async (coverMediaId) => {
            await save({ coverMediaId });
            onSaved();
          }}
        />
      </div>
      <PlacementPicker value={placement} onChange={setPlacement} lockScope />
      <FormError message={error} />
      <Button
        disabled={!title.trim()}
        onClick={async () => {
          setError(null);
          try {
            await save({
              titleAr: title,
              description: description.trim() || null,
              unitId: placement.unitId,
              lessonId: placement.lessonId,
            });
            onSaved();
          } catch (err) {
            setError(errorMessage(err));
          }
        }}
      >
        حفظ التفاصيل
      </Button>
    </Card>
  );
}

/** Pick the front and back images, upload both, then add the card. */
function NewCard({ deckId, onCreated }: { deckId: string; onCreated: () => void }) {
  const [front, setFront] = useState<File | null>(null);
  const [back, setBack] = useState<File | null>(null);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function add() {
    if (!front || !back) return;
    setBusy(true);
    setError(null);
    try {
      const [frontMediaId, backMediaId] = await Promise.all([
        uploadImage('flashcard', front),
        uploadImage('flashcard', back),
      ]);
      await unwrap(
        api.POST('/api/v1/admin/decks/{id}/cards', {
          params: { path: { id: deckId } },
          body: { frontMediaId, backMediaId },
        }),
      );
      setFront(null);
      setBack(null);
      onCreated();
    } catch (err) {
      setError(errorMessage(err));
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="flex flex-wrap items-end gap-3 rounded-lg border border-dashed border-border p-3">
      <div className="space-y-1">
        <Label htmlFor="card-front">الوجه الأمامي</Label>
        <input
          id="card-front"
          type="file"
          accept="image/png,image/jpeg,image/webp"
          className="block text-sm"
          onChange={(e) => setFront(e.target.files?.[0] ?? null)}
        />
      </div>
      <div className="space-y-1">
        <Label htmlFor="card-back">الوجه الخلفي</Label>
        <input
          id="card-back"
          type="file"
          accept="image/png,image/jpeg,image/webp"
          className="block text-sm"
          onChange={(e) => setBack(e.target.files?.[0] ?? null)}
        />
      </div>
      <Button disabled={!front || !back || busy} onClick={() => void add()}>
        {busy ? (
          <Loader2 className="size-4 animate-spin" aria-hidden />
        ) : (
          <Plus className="size-4" aria-hidden />
        )}
        إضافة بطاقة
      </Button>
      <FormError message={error} />
    </div>
  );
}

function CardTile({
  card,
  index,
  count,
  onMove,
  run,
}: {
  card: AdminCard;
  index: number;
  count: number;
  onMove: (delta: number) => void;
  run: (call: () => Promise<unknown>) => Promise<void>;
}) {
  const update = (body: components['schemas']['UpdateCardRequest']) =>
    run(() => unwrap(api.PATCH('/api/v1/admin/cards/{id}', { params: { path: { id: card.id } }, body })));
  return (
    <div
      className={`space-y-2 rounded-lg border border-border p-3 ${card.status !== 'published' ? 'opacity-60' : ''}`}
    >
      <div className="flex items-center justify-between text-sm">
        <span className="font-medium">
          {index + 1} · {STATUS_LABELS[card.status]}
        </span>
        <div className="flex gap-1">
          <Button
            size="sm"
            variant="ghost"
            aria-label="أعلى"
            disabled={index === 0}
            onClick={() => onMove(-1)}
          >
            <ArrowUp className="size-4" aria-hidden />
          </Button>
          <Button
            size="sm"
            variant="ghost"
            aria-label="أسفل"
            disabled={index === count - 1}
            onClick={() => onMove(1)}
          >
            <ArrowDown className="size-4" aria-hidden />
          </Button>
          <Button
            size="sm"
            variant="ghost"
            aria-label="حذف البطاقة"
            className="text-danger"
            onClick={() => {
              if (window.confirm('حذف هذه البطاقة؟'))
                void run(() =>
                  unwrap(api.DELETE('/api/v1/admin/cards/{id}', { params: { path: { id: card.id } } })),
                );
            }}
          >
            <Trash2 className="size-4" aria-hidden />
          </Button>
        </div>
      </div>
      <div className="grid grid-cols-2 gap-2">
        <ImageUpload
          kind="flashcard"
          label="الأمام"
          imageUrl={card.front.thumbUrl}
          onChange={async (frontMediaId) => {
            if (frontMediaId) await update({ frontMediaId });
          }}
        />
        <ImageUpload
          kind="flashcard"
          label="الخلف"
          imageUrl={card.back.thumbUrl}
          onChange={async (backMediaId) => {
            if (backMediaId) await update({ backMediaId });
          }}
        />
      </div>
      <Button
        size="sm"
        variant="outline"
        onClick={() => void update({ status: card.status === 'published' ? 'archived' : 'published' })}
      >
        {card.status === 'published' ? 'إخفاء البطاقة' : 'إظهار البطاقة'}
      </Button>
    </div>
  );
}
