/*
 * Flashcard bulk upload pairing (spec §27): files named `001-front.png` / `001-back.png` (also
 * `_`, a space, `f`/`b`, `a`/`b`, or أمامي/خلفي) are paired by their prefix and ordered by it.
 */

export type Named = { name: string };
export type Pair<T extends Named> = { key: string; front: T | null; back: T | null };

const IMAGE = /\.(png|jpe?g|webp)$/i;
/** A side word, or a single letter only after a separator (so "extra" is not "extr" + "a"). */
const SIDE = /^(.*?)(?:[\s._-]+(f|b|a)|[\s._-]*(front|back|أمامي|امامي|خلفي))$/i;

function side(label: string): 'front' | 'back' {
  return /^(front|f|a|أمامي|امامي)$/i.test(label) ? 'front' : 'back';
}

/** Natural order: "2" before "10". */
export const naturalCompare = (a: string, b: string) =>
  a.localeCompare(b, undefined, { numeric: true, sensitivity: 'base' });

export function isImageName(name: string) {
  return IMAGE.test(name) && !name.split('/').pop()!.startsWith('.');
}

/** Pairs by prefix; files that do not follow the pattern come back as `unmatched`. */
export function pairFiles<T extends Named>(files: T[]): { pairs: Pair<T>[]; unmatched: T[] } {
  const byKey = new Map<string, Pair<T>>();
  const unmatched: T[] = [];
  for (const file of files) {
    const base = file.name.split('/').pop()!.replace(IMAGE, '');
    const m = SIDE.exec(base);
    if (!m || !m[1]) {
      unmatched.push(file);
      continue;
    }
    const key = m[1];
    const pair = byKey.get(key) ?? { key, front: null, back: null };
    const which = side((m[2] ?? m[3])!);
    if (pair[which]) unmatched.push(file);
    else pair[which] = file;
    byKey.set(key, pair);
  }
  const pairs = [...byKey.values()].sort((a, b) => naturalCompare(a.key, b.key));
  return { pairs, unmatched: unmatched.sort((a, b) => naturalCompare(a.name, b.name)) };
}
