import { createHash } from 'node:crypto';

/*
 * Spaced repetition, SM-2 / Anki style with three buttons (spec §13.4). The Dart port in the student
 * app must produce identical results for `fixtures/scheduler.json`: same arithmetic, rounding, fuzz
 * bytes and business-day boundary. Times are epoch milliseconds (UTC).
 */

export const MINUTE = 60_000;
export const DAY = 86_400_000;

export const SRS = {
  learningStepsMs: [1 * MINUTE, 10 * MINUTE],
  relearningStepsMs: [10 * MINUTE],
  graduatingIntervalDays: 1,
  easyIntervalDays: 4,
  startingEase: 2.5,
  minimumEase: 1.3,
  easyBonus: 1.3,
  lapseIntervalFactor: 0,
  maximumIntervalDays: 365,
  learnAheadLimitMs: 20 * MINUTE,
  newCardsPerDay: 20,
  maxReviewsPerDay: 200,
} as const;

/**
 * The business day runs 04:00 → 04:00 Asia/Damascus (§13.5). Syria has kept UTC+3 all year since
 * 2022; a fixed offset keeps every client and the server identical without a time-zone database.
 */
export const BUSINESS_UTC_OFFSET_MS = 3 * 60 * MINUTE;
export const DAY_STARTS_AT_MS = 4 * 60 * MINUTE;

/** Business-day number of an instant (days since the 1970-01-01 business day). */
export const businessDay = (at: number) => Math.floor((at + BUSINESS_UTC_OFFSET_MS - DAY_STARTS_AT_MS) / DAY);

/** UTC instant at which business day `day` starts (04:00 Damascus). */
export const startOfBusinessDay = (day: number) => day * DAY + DAY_STARTS_AT_MS - BUSINESS_UTC_OFFSET_MS;

export type CardStateName = 'new' | 'learning' | 'review' | 'relearning';
export type Rating = 'again' | 'good' | 'easy';

export interface CardState {
  state: CardStateName;
  step: number;
  dueAt: number;
  /** Whole days in review; during relearning, the interval to return to (§13.4 pendingInterval). */
  intervalDays: number;
  ease: number;
  reps: number;
  lapses: number;
  lastReviewedAt: number | null;
}

export function newCardState(now: number): CardState {
  return {
    state: 'new',
    step: 0,
    dueAt: now,
    intervalDays: 0,
    ease: SRS.startingEase,
    reps: 0,
    lapses: 0,
    lastReviewedAt: null,
  };
}

/** Ease is kept to two decimals so repeated ±0.20/+0.15 steps never drift between languages. */
const round2 = (x: number) => Math.floor(x * 100 + 0.5) / 100;
const roundHalfUp = (x: number) => Math.floor(x + 0.5);

/** First four SHA-256 bytes of `seed`, as an unsigned big-endian integer. */
function seedNumber(seed: string): number {
  return createHash('sha256').update(seed, 'utf8').digest().readUInt32BE(0);
}

/** §13.4 exact fuzz for review intervals of at least 3 days. */
export function fuzzInterval(
  cardId: string,
  reps: number,
  rating: 'good' | 'easy',
  preFuzzDays: number,
): number {
  const base = roundHalfUp(preFuzzDays);
  const span = Math.max(1, roundHalfUp(base * 0.05));
  const bucket = seedNumber(`${cardId}:${reps}:${rating}`) % (2 * span + 1);
  return Math.min(SRS.maximumIntervalDays, Math.max(1, base + bucket - span));
}

function reviewInterval(cardId: string, reps: number, rating: 'good' | 'easy', pre: number): number {
  const capped = Math.min(SRS.maximumIntervalDays, pre);
  return capped >= 3 ? fuzzInterval(cardId, reps, rating, capped) : Math.max(1, roundHalfUp(capped));
}

/** The state after rating a card at `now`. `cardId` is the stable flashcard or user card id. */
export function schedule(card: CardState, rating: Rating, now: number, cardId: string): CardState {
  const reps = card.reps + 1;
  const today = businessDay(now);
  const base = { ...card, reps, lastReviewedAt: now };
  const inDays = (days: number) => startOfBusinessDay(today + days);
  const toReview = (intervalDays: number, extra: Partial<CardState> = {}): CardState => ({
    ...base,
    ...extra,
    state: 'review',
    step: 0,
    intervalDays,
    dueAt: inDays(intervalDays),
  });

  switch (card.state) {
    case 'new':
    case 'learning': {
      if (rating === 'again')
        return { ...base, state: 'learning', step: 0, dueAt: now + SRS.learningStepsMs[0] };
      if (rating === 'easy') return toReview(SRS.easyIntervalDays);
      const next = card.state === 'new' ? 1 : card.step + 1;
      if (next < SRS.learningStepsMs.length) {
        return { ...base, state: 'learning', step: next, dueAt: now + SRS.learningStepsMs[next]! };
      }
      return toReview(SRS.graduatingIntervalDays);
    }
    case 'review': {
      const late = Math.max(0, today - businessDay(card.dueAt));
      if (rating === 'again') {
        return {
          ...base,
          state: 'relearning',
          step: 0,
          lapses: card.lapses + 1,
          ease: Math.max(SRS.minimumEase, round2(card.ease - 0.2)),
          intervalDays: Math.max(1, Math.floor(card.intervalDays * SRS.lapseIntervalFactor)),
          dueAt: now + SRS.relearningStepsMs[0],
        };
      }
      if (rating === 'good') {
        const pre = Math.max(card.intervalDays + 1, (card.intervalDays + late / 2) * card.ease);
        return toReview(reviewInterval(cardId, reps, 'good', pre));
      }
      const pre = Math.max(card.intervalDays + 1, (card.intervalDays + late) * card.ease * SRS.easyBonus);
      return toReview(reviewInterval(cardId, reps, 'easy', pre), { ease: round2(card.ease + 0.15) });
    }
    case 'relearning': {
      if (rating === 'again') return { ...base, step: 0, dueAt: now + SRS.relearningStepsMs[0] };
      const next = card.step + 1;
      if (rating === 'good' && next < SRS.relearningStepsMs.length) {
        return { ...base, step: next, dueAt: now + SRS.relearningStepsMs[next]! };
      }
      return toReview(card.intervalDays);
    }
  }
}

/** Arabic label for a predicted interval (§13.4): د، س، يوم/أيام، شهر. */
export function intervalLabel(after: CardState, now: number): string {
  if (after.state === 'learning' || after.state === 'relearning') {
    const minutes = Math.round((after.dueAt - now) / MINUTE);
    if (minutes <= 1) return '< 1 د';
    if (minutes < 60) return `${minutes} د`;
    return `${Math.round(minutes / 60)} س`;
  }
  const d = after.intervalDays;
  if (d >= 30) return `${Math.floor((d / 30) * 10 + 0.5) / 10} شهر`;
  if (d === 1) return 'يوم';
  if (d === 2) return 'يومان';
  if (d <= 10) return `${d} أيام`;
  return `${d} يوماً`;
}

/** Predicted state and label for each button, shown under the buttons after a flip. */
export function preview(card: CardState, now: number, cardId: string) {
  return Object.fromEntries(
    (['again', 'good', 'easy'] as const).map((rating) => {
      const after = schedule(card, rating, now, cardId);
      return [rating, { state: after, label: intervalLabel(after, now) }];
    }),
  ) as Record<Rating, { state: CardState; label: string }>;
}
