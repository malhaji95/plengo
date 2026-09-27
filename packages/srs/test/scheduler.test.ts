import { describe, expect, it } from 'vitest';
import fixtures from '../fixtures/scheduler.json' with { type: 'json' };
import {
  businessDay,
  fuzzInterval,
  intervalLabel,
  newCardState,
  preview,
  schedule,
  startOfBusinessDay,
  type CardState,
  type Rating,
} from '../src/index.js';

type Serialized = Omit<CardState, 'dueAt' | 'lastReviewedAt'> & {
  dueAt: string;
  lastReviewedAt: string | null;
};
const parse = (s: Serialized): CardState => ({
  ...s,
  dueAt: Date.parse(s.dueAt),
  lastReviewedAt: s.lastReviewedAt === null ? null : Date.parse(s.lastReviewedAt),
});

describe('scheduler fixtures (shared with Dart)', () => {
  for (const sc of fixtures.scenarios) {
    it(sc.name, () => {
      let state = parse(sc.start as Serialized);
      for (const step of sc.steps) {
        const at = Date.parse(step.at);
        state = schedule(state, step.rating as Rating, at, sc.cardId);
        expect(state).toEqual(parse(step.expect as Serialized));
        expect(intervalLabel(state, at)).toBe(step.label);
      }
    });
  }

  it('fuzz vectors', () => {
    for (const f of fixtures.fuzz) {
      expect(fuzzInterval(f.cardId, f.reps, f.rating as 'good' | 'easy', f.preFuzzDays)).toBe(f.expected);
    }
  });

  it('business days start at 04:00 Asia/Damascus', () => {
    for (const b of fixtures.businessDays) {
      expect(businessDay(Date.parse(b.at))).toBe(b.day);
      expect(new Date(startOfBusinessDay(b.day)).toISOString()).toBe(b.startsAt);
    }
  });
});

describe('scheduler properties', () => {
  const now = Date.parse('2026-09-27T09:00:00Z');

  it('never fuzzes learning steps or graduation', () => {
    for (let i = 0; i < 50; i++) {
      const id = `card-${i}`;
      expect(schedule(newCardState(now), 'easy', now, id).intervalDays).toBe(4);
      const learning = schedule(newCardState(now), 'good', now, id);
      expect(schedule(learning, 'good', now, id).intervalDays).toBe(1);
    }
  });

  it('keeps fuzz within ±5% (at least ±1 day) and inside [1, 365]', () => {
    for (let i = 0; i < 500; i++) {
      const pre = 3 + (i % 400);
      const got = fuzzInterval(`c${i}`, i, i % 2 ? 'good' : 'easy', pre);
      const span = Math.max(1, Math.floor(Math.floor(pre + 0.5) * 0.05 + 0.5));
      expect(Math.abs(got - Math.min(pre, 365))).toBeLessThanOrEqual(span + 0.5);
      expect(got).toBeGreaterThanOrEqual(1);
      expect(got).toBeLessThanOrEqual(365);
    }
  });

  it('previews all three buttons with labels', () => {
    const p = preview(newCardState(now), now, 'x');
    expect([p.again.label, p.good.label, p.easy.label]).toEqual(['< 1 د', '10 د', '4 أيام']);
  });

  it('is deterministic', () => {
    const s = { ...newCardState(now), state: 'review' as const, intervalDays: 40, reps: 9 };
    expect(schedule(s, 'good', now, 'same')).toEqual(schedule(s, 'good', now, 'same'));
  });
});
