'use client';

import { ChevronLeft, ChevronRight, RotateCcw, X } from 'lucide-react';
import { useEffect, useState } from 'react';
import { Button } from '@/components/ui/button';
import type { components } from '@/lib/api-schema';

type AdminCard = components['schemas']['AdminCard'];

/**
 * Full-size preview of a deck's cards as a student sees them: tap or Space flips the card, the
 * arrows (or the keyboard arrows) move through the deck, Escape closes.
 */
export function CardPreview({
  cards,
  start,
  onClose,
}: {
  cards: AdminCard[];
  start: number;
  onClose: () => void;
}) {
  const [index, setIndex] = useState(start);
  const [flipped, setFlipped] = useState(false);
  const card = cards[index];

  const last = cards.length - 1;
  const go = (delta: number) => {
    setIndex((i) => Math.min(last, Math.max(0, i + delta)));
    setFlipped(false);
  };

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      // In RTL the next card is to the left.
      const delta = e.key === 'ArrowLeft' ? 1 : e.key === 'ArrowRight' ? -1 : 0;
      if (e.key === 'Escape') onClose();
      else if (delta) {
        setIndex((i) => Math.min(last, Math.max(0, i + delta)));
        setFlipped(false);
      } else if (e.key === ' ') {
        e.preventDefault();
        setFlipped((f) => !f);
      }
    };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, [last, onClose]);

  if (!card) return null;
  const face = flipped ? card.back : card.front;
  const faceLabel = flipped ? 'الوجه الخلفي' : 'الوجه الأمامي';

  return (
    <div
      role="dialog"
      aria-modal="true"
      aria-label={`معاينة البطاقة ${index + 1}`}
      className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 p-4"
      onClick={onClose}
    >
      <div
        className="flex max-h-full w-full max-w-xl flex-col gap-3 rounded-xl bg-surface p-4 shadow-xl"
        onClick={(e) => e.stopPropagation()}
      >
        <div className="flex items-center justify-between text-sm">
          <span className="font-semibold">
            البطاقة {index + 1} من {cards.length} · {faceLabel}
          </span>
          <Button autoFocus size="sm" variant="ghost" aria-label="إغلاق المعاينة" onClick={onClose}>
            <X className="size-4" aria-hidden />
          </Button>
        </div>
        <button
          type="button"
          className="flex min-h-0 justify-center rounded-lg bg-surface-muted"
          aria-label={`اقلب البطاقة (${faceLabel})`}
          onClick={() => setFlipped((f) => !f)}
        >
          <img src={face.fullUrl} alt={faceLabel} className="max-h-[70vh] w-auto rounded-lg object-contain" />
        </button>
        <div className="flex items-center justify-between gap-2">
          <Button variant="outline" disabled={index === 0} onClick={() => go(-1)}>
            <ChevronRight className="size-4" aria-hidden />
            السابقة
          </Button>
          <Button variant="outline" onClick={() => setFlipped((f) => !f)}>
            <RotateCcw className="size-4" aria-hidden />
            {flipped ? 'عرض الأمام' : 'عرض الخلف'}
          </Button>
          <Button variant="outline" disabled={index === last} onClick={() => go(1)}>
            التالية
            <ChevronLeft className="size-4" aria-hidden />
          </Button>
        </div>
      </div>
    </div>
  );
}
