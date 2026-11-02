import { cleanup, fireEvent, render, screen } from '@testing-library/react';
import { afterEach, describe, expect, it, vi } from 'vitest';
import { CardPreview } from '@/components/flashcards/card-preview';

afterEach(() => cleanup());

const image = (name: string) => ({
  mediaId: name,
  cacheKey: name,
  fullUrl: `https://r2.test/${name}.webp`,
  thumbUrl: `https://r2.test/${name}-thumb.webp`,
  width: 1080,
  height: 1080,
});
const card = (n: number) => ({
  id: `c${n}`,
  deckId: 'deck-1',
  sortOrder: n,
  status: 'published' as const,
  contentVersion: 1,
  front: image(`front-${n}`),
  back: image(`back-${n}`),
});
const cards = [card(1), card(2)];
const shown = () => screen.getByRole('img').getAttribute('src');

describe('card preview', () => {
  it('shows the full-size front, flips to the back, and moves through the deck', () => {
    render(<CardPreview cards={cards} start={0} onClose={() => {}} />);
    expect(screen.getByText('البطاقة 1 من 2 · الوجه الأمامي')).toBeTruthy();
    expect(shown()).toBe('https://r2.test/front-1.webp');

    fireEvent.click(screen.getByRole('button', { name: 'عرض الخلف' }));
    expect(shown()).toBe('https://r2.test/back-1.webp');

    fireEvent.click(screen.getByRole('button', { name: /التالية/ }));
    expect(screen.getByText('البطاقة 2 من 2 · الوجه الأمامي')).toBeTruthy();
    expect(shown()).toBe('https://r2.test/front-2.webp');
    expect(screen.getByRole('button', { name: /التالية/ }).hasAttribute('disabled')).toBe(true);
  });

  it('supports the keyboard: Space flips, arrows move (RTL), Escape closes', () => {
    const onClose = vi.fn();
    render(<CardPreview cards={cards} start={1} onClose={onClose} />);
    fireEvent.keyDown(window, { key: ' ' });
    expect(shown()).toBe('https://r2.test/back-2.webp');
    fireEvent.keyDown(window, { key: 'ArrowRight' });
    expect(shown()).toBe('https://r2.test/front-1.webp');
    fireEvent.keyDown(window, { key: 'Escape' });
    expect(onClose).toHaveBeenCalledOnce();
  });
});
