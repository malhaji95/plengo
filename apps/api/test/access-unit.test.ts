import { describe, expect, it } from 'vitest';
import { businessDate, endOfBusinessDay, startOfBusinessDay } from '../src/lib/business-time.js';
import {
  COUPON_ALPHABET,
  createCouponCrypto,
  formatCouponCode,
  generateCouponCode,
  normalizeCouponCode,
} from '../src/lib/coupon-code.js';
import { toCsv } from '../src/lib/tabular.js';
import { effectiveRule, previewCounts, ruleFreeIds, type RankedItem } from '../src/services/free-rules.js';

describe('coupon codes (§9.2, §9.3)', () => {
  it('generates 10 characters from the unambiguous alphabet', () => {
    for (let i = 0; i < 200; i++) {
      const code = generateCouponCode();
      expect(code).toMatch(new RegExp(`^[${COUPON_ALPHABET}]{10}$`));
    }
    expect(COUPON_ALPHABET).toHaveLength(31);
    expect(COUPON_ALPHABET).not.toMatch(/[01ILO]/);
    expect(formatCouponCode('ABCD2345XY')).toBe('ABCD-2345-XY');
  });

  it('normalizes spacing, dashes, case and Arabic/Persian digits', () => {
    expect(normalizeCouponCode('  abcd-2345-xy ')).toBe('ABCD2345XY');
    expect(normalizeCouponCode('ABCD ٢٣٤٥ XY')).toBe('ABCD2345XY');
    expect(normalizeCouponCode('abcd۲۳۴۵xy')).toBe('ABCD2345XY');
    expect(normalizeCouponCode('ABCD–2345–XY')).toBe('ABCD2345XY');
  });

  it('rejects wrong lengths and characters outside the alphabet', () => {
    expect(normalizeCouponCode('ABCD2345X')).toBeNull();
    expect(normalizeCouponCode('ABCD2345XYZ')).toBeNull();
    expect(normalizeCouponCode('ABCD2345X0')).toBeNull(); // 0 is ambiguous
    expect(normalizeCouponCode('ABCD2345XI')).toBeNull();
    expect(normalizeCouponCode('')).toBeNull();
  });

  it('hashes deterministically and round-trips encryption', () => {
    const c = createCouponCrypto('s'.repeat(32), Buffer.alloc(32, 3).toString('base64'));
    expect(c.hash('ABCD2345XY')).toBe(c.hash('ABCD2345XY'));
    const enc = c.encrypt('ABCD2345XY');
    expect(enc).not.toContain('ABCD');
    expect(c.encrypt('ABCD2345XY')).not.toBe(enc); // random IV
    expect(c.decrypt(enc)).toBe('ABCD2345XY');
    const tampered = enc.slice(0, -2) + (enc.endsWith('A') ? 'BB' : 'AA');
    expect(() => c.decrypt(tampered)).toThrow();
  });
});

describe('business time (§8.2)', () => {
  it('maps a date-only expiry to 23:59:59 Asia/Damascus', () => {
    // Syria has stayed on UTC+3 since 2022.
    expect(endOfBusinessDay('2027-06-30', 'Asia/Damascus').toISOString()).toBe('2027-06-30T20:59:59.000Z');
    expect(startOfBusinessDay('2027-06-30', 'Asia/Damascus').toISOString()).toBe('2027-06-29T21:00:00.000Z');
    expect(businessDate(new Date('2027-06-30T21:30:00Z'), 'Asia/Damascus')).toBe('2027-07-01');
  });

  it('handles zones with daylight saving', () => {
    expect(endOfBusinessDay('2027-07-01', 'Europe/Berlin').toISOString()).toBe('2027-07-01T21:59:59.000Z');
    expect(endOfBusinessDay('2027-01-01', 'Europe/Berlin').toISOString()).toBe('2027-01-01T22:59:59.000Z');
  });
});

describe('CSV export', () => {
  it('quotes, adds a BOM and neutralises formulas', () => {
    const csv = toCsv({ header: ['a', 'b'], rows: [['=1+1', 'x,"y"']] }).toString('utf8');
    expect(csv.charCodeAt(0)).toBe(0xfeff);
    expect(csv).toContain(`'=1+1,"x,""y"""`);
  });
});

describe('free rules (§8.4)', () => {
  // Unit u1 (lessons l1, l2), unit u2 (lesson l3), lesson l4 directly under the subject.
  const outline = {
    units: [
      { id: 'u2', sortOrder: 2 },
      { id: 'u1', sortOrder: 1 },
    ],
    lessons: [
      { id: 'l2', unitId: 'u1', sortOrder: 2 },
      { id: 'l1', unitId: 'u1', sortOrder: 1 },
      { id: 'l3', unitId: 'u2', sortOrder: 1 },
      { id: 'l4', unitId: null, sortOrder: 1 },
    ],
  };
  const item = (
    id: string,
    unitId: string | null,
    lessonId: string | null,
    sortOrder: number,
    extra = {},
  ): RankedItem => ({
    id,
    unitId,
    lessonId,
    sortOrder,
    isFree: false,
    manual: false,
    ...extra,
  });
  const items = [
    item('q-l3', 'u2', 'l3', 1),
    item('q-l1b', 'u1', 'l1', 2),
    item('q-l1a', 'u1', 'l1', 1),
    item('q-u1', 'u1', null, 1),
    item('q-l2', 'u1', 'l2', 1),
    item('q-l4', null, 'l4', 1),
    item('q-none', null, null, 1),
  ];
  const ids = (s: Set<string>) => [...s].sort();

  it('first_n_items follows unit → lesson → item order', () => {
    expect(ids(ruleFreeIds({ ruleType: 'first_n_items', ruleValue: 3 }, items, outline))).toEqual(
      ['q-l1a', 'q-l1b', 'q-u1'].sort(),
    );
  });

  it('first_n_lessons, first_unit and percentage', () => {
    expect(ids(ruleFreeIds({ ruleType: 'first_n_lessons', ruleValue: 2 }, items, outline))).toEqual(
      ['q-l1a', 'q-l1b', 'q-l2'].sort(),
    );
    expect(ids(ruleFreeIds({ ruleType: 'first_unit', ruleValue: null }, items, outline))).toEqual(
      ['q-l1a', 'q-l1b', 'q-l2', 'q-u1'].sort(),
    );
    // ceil(7 * 30%) = 3
    expect(ruleFreeIds({ ruleType: 'percentage', ruleValue: 30 }, items, outline).size).toBe(3);
    expect(ruleFreeIds({ ruleType: 'manual', ruleValue: null }, items, outline).size).toBe(0);
    expect(ruleFreeIds(null, items, outline).size).toBe(0);
  });

  it('keeps manual overrides in the preview counts', () => {
    const withManual = items.map((i) => (i.id === 'q-none' ? { ...i, manual: true, isFree: true } : i));
    expect(previewCounts({ ruleType: 'first_n_items', ruleValue: 2 }, withManual, outline)).toEqual({
      freeCount: 3,
      paidCount: 4,
    });
  });

  it('prefers a kind-specific rule over the scope-wide one', () => {
    const rules = [
      { contentKind: 'all' as const, id: 'all' },
      { contentKind: 'quizzes' as const, id: 'quiz' },
    ];
    expect(effectiveRule(rules, 'quizzes')?.id).toBe('quiz');
    expect(effectiveRule(rules, 'questions')?.id).toBe('all');
    expect(effectiveRule([], 'questions')).toBeNull();
  });
});
