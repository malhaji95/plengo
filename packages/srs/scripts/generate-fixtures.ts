/**
 * Regenerates fixtures/scheduler.json from the scenarios below. Expected values are reviewed by hand
 * against spec §13.4 before committing; the TS and Dart test suites then both replay the file.
 *   node --import tsx scripts/generate-fixtures.ts
 */
import { writeFileSync } from 'node:fs';
import {
  businessDay,
  fuzzInterval,
  intervalLabel,
  newCardState,
  schedule,
  startOfBusinessDay,
  type CardState,
  type Rating,
} from '../src/index.js';

const T0 = Date.parse('2026-09-27T09:00:00Z'); // 12:00 in Damascus
const MIN = 60_000;
const DAY = 86_400_000;
const CARD = '0f8b5a1e-3c2d-4e6f-9a7b-1c2d3e4f5a6b';

type Step = { rating: Rating; at: number };
const review = (
  intervalDays: number,
  ease: number,
  dueAt: number,
  extra: Partial<CardState> = {},
): CardState => ({
  state: 'review',
  step: 0,
  dueAt,
  intervalDays,
  ease,
  reps: 5,
  lapses: 0,
  lastReviewedAt: dueAt - intervalDays * DAY,
  ...extra,
});
const dueToday = startOfBusinessDay(businessDay(T0));

const scenarios: { name: string; cardId: string; start: CardState; steps: Step[] }[] = [
  {
    name: 'new: Good, Good → learning 10 min, then review 1 day (§37.5)',
    cardId: CARD,
    start: newCardState(T0),
    steps: [
      { rating: 'good', at: T0 },
      { rating: 'good', at: T0 + 10 * MIN },
    ],
  },
  {
    name: 'new: Easy → review exactly 4 days, no fuzz (§37.5)',
    cardId: CARD,
    start: newCardState(T0),
    steps: [{ rating: 'easy', at: T0 }],
  },
  {
    name: 'new: Again, Good, Again, Good, Good',
    cardId: CARD,
    start: newCardState(T0),
    steps: [
      { rating: 'again', at: T0 },
      { rating: 'good', at: T0 + MIN },
      { rating: 'again', at: T0 + 11 * MIN },
      { rating: 'good', at: T0 + 12 * MIN },
      { rating: 'good', at: T0 + 22 * MIN },
    ],
  },
  {
    name: 'review: Again → relearning 10 min, ease −0.20, then Good → 1 day (§37.5)',
    cardId: CARD,
    start: review(10, 2.5, dueToday),
    steps: [
      { rating: 'again', at: T0 },
      { rating: 'good', at: T0 + 10 * MIN },
    ],
  },
  {
    name: 'review: Again never takes ease below 1.30',
    cardId: CARD,
    start: review(5, 1.4, dueToday),
    steps: [
      { rating: 'again', at: T0 },
      { rating: 'easy', at: T0 + 10 * MIN },
      { rating: 'again', at: T0 + 2 * DAY },
    ],
  },
  {
    name: 'relearning: Again restarts the step, Easy finishes',
    cardId: CARD,
    start: review(20, 2.5, dueToday),
    steps: [
      { rating: 'again', at: T0 },
      { rating: 'again', at: T0 + 10 * MIN },
      { rating: 'easy', at: T0 + 20 * MIN },
    ],
  },
  {
    name: 'review: Good on the due day, fuzzed',
    cardId: CARD,
    start: review(10, 2.5, dueToday),
    steps: [{ rating: 'good', at: T0 }],
  },
  {
    name: 'review: Good 4 days late uses late/2',
    cardId: CARD,
    start: review(10, 2.5, dueToday - 4 * DAY),
    steps: [{ rating: 'good', at: T0 }],
  },
  {
    name: 'review: Easy 4 days late uses late × ease × 1.30 and ease +0.15',
    cardId: CARD,
    start: review(10, 2.5, dueToday - 4 * DAY),
    steps: [{ rating: 'easy', at: T0 }],
  },
  {
    name: 'review: short interval below 3 days is rounded, not fuzzed',
    cardId: CARD,
    start: review(1, 2.5, dueToday),
    steps: [{ rating: 'good', at: T0 }],
  },
  {
    name: 'review: interval capped at 365 days',
    cardId: CARD,
    start: review(300, 2.5, dueToday),
    steps: [
      { rating: 'good', at: T0 },
      { rating: 'easy', at: T0 + 400 * DAY },
    ],
  },
  {
    name: 'business day: 03:59 Damascus still belongs to the previous day',
    cardId: CARD,
    start: newCardState(T0),
    steps: [{ rating: 'easy', at: Date.parse('2026-09-28T00:59:00Z') }],
  },
  {
    name: 'business day: 04:00 Damascus starts a new day',
    cardId: CARD,
    start: newCardState(T0),
    steps: [{ rating: 'easy', at: Date.parse('2026-09-28T01:00:00Z') }],
  },
  {
    name: 'fuzz seeds on the card id',
    cardId: '9d3c7b2a-1111-4222-8333-944455566677',
    start: review(10, 2.5, dueToday),
    steps: [{ rating: 'good', at: T0 }],
  },
];

const iso = (ms: number | null) => (ms === null ? null : new Date(ms).toISOString());
const serial = (s: CardState) => ({ ...s, dueAt: iso(s.dueAt), lastReviewedAt: iso(s.lastReviewedAt) });

const out = {
  version: 1,
  scenarios: scenarios.map((sc) => {
    let state = sc.start;
    return {
      name: sc.name,
      cardId: sc.cardId,
      start: serial(sc.start),
      steps: sc.steps.map((st) => {
        state = schedule(state, st.rating, st.at, sc.cardId);
        return {
          rating: st.rating,
          at: iso(st.at),
          expect: serial(state),
          label: intervalLabel(state, st.at),
        };
      }),
    };
  }),
  fuzz: [
    ['0f8b5a1e-3c2d-4e6f-9a7b-1c2d3e4f5a6b', 6, 'good', 25],
    ['0f8b5a1e-3c2d-4e6f-9a7b-1c2d3e4f5a6b', 6, 'easy', 25],
    ['0f8b5a1e-3c2d-4e6f-9a7b-1c2d3e4f5a6b', 7, 'good', 25],
    ['user-card-7', 3, 'good', 3],
    ['user-card-7', 3, 'good', 2.5],
    ['user-card-7', 12, 'easy', 45.5],
    ['user-card-7', 40, 'good', 365],
    ['بطاقة', 2, 'good', 100.49],
  ].map(([cardId, reps, rating, pre]) => ({
    cardId,
    reps,
    rating,
    preFuzzDays: pre,
    expected: fuzzInterval(cardId as string, reps as number, rating as 'good' | 'easy', pre as number),
  })),
  businessDays: ['2026-09-27T00:59:59Z', '2026-09-27T01:00:00Z', '2026-12-31T21:30:00Z'].map((at) => ({
    at,
    day: businessDay(Date.parse(at)),
    startsAt: iso(startOfBusinessDay(businessDay(Date.parse(at)))),
  })),
};

writeFileSync(new URL('../fixtures/scheduler.json', import.meta.url), `${JSON.stringify(out, null, 2)}\n`);
console.log('fixtures written');
