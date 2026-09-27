import { describe, expect, it } from 'vitest';
import fixtures from '../fixtures/v1.json' with { type: 'json' };
import { matchesAcceptedAnswer, normalizeArabic, NORMALIZATION_VERSION } from '../src/index.js';

describe(`normalizer v${fixtures.version} (spec §14.4)`, () => {
  it('fixtures match the current version', () => {
    expect(NORMALIZATION_VERSION).toBe(fixtures.version);
  });

  for (const f of fixtures.normalize) {
    it(`normalizes: ${f.name}`, () => {
      expect(normalizeArabic(f.input)).toBe(f.expected);
    });
  }

  for (const f of fixtures.match) {
    it(`matches: ${f.name}`, () => {
      expect(matchesAcceptedAnswer(f.input, f.accepted.map(normalizeArabic))).toBe(f.correct);
    });
  }

  it('is idempotent', () => {
    for (const f of fixtures.normalize) expect(normalizeArabic(normalizeArabic(f.input))).toBe(f.expected);
  });
});
