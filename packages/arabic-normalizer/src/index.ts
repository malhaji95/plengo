/**
 * Arabic answer normalization, version 1 (spec §14.4). Server-side grading only; the Dart port used
 * for offline grading (Phase 9) must pass the same fixtures in `fixtures/`.
 *
 * Not normalized on purpose (admins add variants explicitly): ة/ه, ؤ/ئ/ء, synonyms.
 */

/** Stored with every accepted answer. Bump it, and regenerate stored values, whenever rules change. */
export const NORMALIZATION_VERSION = 1;

const TATWEEL = /ـ/g;
/** Fathatan … sukun (U+064B–U+0652) and superscript alef (U+0670). */
const DIACRITICS = /[ً-ْٰ]/g;
/** أ إ آ ٱ */
const ALEF_FORMS = /[أإآٱ]/g;
const ALEF_MAKSURA = /ى/g;
const ARABIC_INDIC_DIGITS = /[٠-٩]/g;
const PERSIAN_DIGITS = /[۰-۹]/g;
const ARABIC_DECIMAL_SEPARATOR = /٫/g;
const LATIN_LETTER = /\p{Script=Latin}/gu;
/** . , ، ؛ ; : ! ? ؟ " ' « » ( ) - _ / */
const PUNCTUATION = new Set([
  '.',
  ',',
  '،',
  '؛',
  ';',
  ':',
  '!',
  '?',
  '؟',
  '"',
  "'",
  '«',
  '»',
  '(',
  ')',
  '-',
  '_',
  '/',
]);
const isDigit = (ch: string | undefined) => ch !== undefined && ch >= '0' && ch <= '9';

export function normalizeArabic(input: string): string {
  const s = input
    .normalize('NFKC') // 1 (also folds presentation forms)
    .replace(TATWEEL, '') // 2
    .replace(DIACRITICS, '') // 3
    .replace(ALEF_FORMS, 'ا') // 4
    .replace(ALEF_MAKSURA, 'ي') // 5
    .replace(ARABIC_INDIC_DIGITS, (d) => String(d.charCodeAt(0) - 0x0660)) // 6
    .replace(PERSIAN_DIGITS, (d) => String(d.charCodeAt(0) - 0x06f0))
    .replace(ARABIC_DECIMAL_SEPARATOR, '.')
    .replace(LATIN_LETTER, (c) => c.toLowerCase()); // 7

  // 8: punctuation → space, except `.` or `,` between two digits (a decimal separator, kept as `.`).
  const chars = [...s];
  let out = '';
  for (let i = 0; i < chars.length; i++) {
    const ch = chars[i]!;
    if ((ch === '.' || ch === ',') && isDigit(chars[i - 1]) && isDigit(chars[i + 1])) out += '.';
    else if (PUNCTUATION.has(ch)) out += ' ';
    else out += ch;
  }
  return out.replace(/\s+/g, ' ').trim(); // 9
}

/** Correct when the normalized input equals any accepted answer's normalized form. No partial credit. */
export function matchesAcceptedAnswer(input: string, acceptedNormalized: readonly string[]): boolean {
  const normalized = normalizeArabic(input);
  return normalized.length > 0 && acceptedNormalized.includes(normalized);
}
