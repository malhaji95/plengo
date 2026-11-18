import type { components } from './api-schema';

export type AdminDiagram = components['schemas']['AdminDiagram'];
export type DiagramImportResult = components['schemas']['DiagramImportResult'];

/** A label row as the editor holds it: answers as one «|»-separated text field. */
export interface LabelDraft {
  key: string;
  number: number;
  x: number | null;
  y: number | null;
  answers: string;
}

let seq = 0;
const nextKey = () => `l${++seq}`;

export const splitAnswers = (text: string) =>
  text
    .split('|')
    .map((a) => a.trim().replace(/\s+/g, ' '))
    .filter(Boolean);

export function toDrafts(labels: AdminDiagram['labels']): LabelDraft[] {
  return labels.map((l) => ({
    key: nextKey(),
    number: l.number,
    x: l.x,
    y: l.y,
    answers: l.answers.join(' | '),
  }));
}

/** A new row numbered after the highest existing number. */
export function addLabel(labels: LabelDraft[]): LabelDraft[] {
  const number = labels.reduce((n, l) => Math.max(n, l.number), 0) + 1;
  return [...labels, { key: nextKey(), number, x: null, y: null, answers: '' }];
}

export function moveLabel(labels: LabelDraft[], index: number, by: -1 | 1): LabelDraft[] {
  const to = index + by;
  if (to < 0 || to >= labels.length) return labels;
  const next = [...labels];
  [next[index], next[to]] = [next[to]!, next[index]!];
  return next;
}

/** Numbers 1…n in the current order (after reordering or removing rows). */
export const renumber = (labels: LabelDraft[]) => labels.map((l, i) => ({ ...l, number: i + 1 }));

/** Arabic problems to show before saving; empty when the labels can be sent. */
export function labelProblems(labels: LabelDraft[]): string[] {
  const problems: string[] = [];
  if (!labels.length) problems.push('أضف جزءاً واحداً على الأقل');
  const numbers = labels.map((l) => l.number);
  if (new Set(numbers).size !== numbers.length) problems.push('أرقام الأجزاء مكررة');
  if (numbers.some((n) => !Number.isInteger(n) || n < 1)) problems.push('رقم الجزء عدد صحيح موجب');
  for (const l of labels) {
    if (!splitAnswers(l.answers).length) problems.push(`الجزء ${l.number} بلا إجابة`);
    if ((l.x === null) !== (l.y === null)) problems.push(`موضع الجزء ${l.number} غير مكتمل`);
  }
  return problems;
}

export const toLabelInputs = (labels: LabelDraft[]) =>
  labels.map((l) => ({ number: l.number, x: l.x, y: l.y, answers: splitAnswers(l.answers) }));

/** A click on the preview image as 0..1 coordinates (rounded to 3 decimals), clamped to the image. */
export function relativePoint(
  click: { clientX: number; clientY: number },
  box: { left: number; top: number; width: number; height: number },
) {
  const clamp = (v: number) => Math.min(1, Math.max(0, Math.round(v * 1000) / 1000));
  return {
    x: clamp((click.clientX - box.left) / (box.width || 1)),
    y: clamp((click.clientY - box.top) / (box.height || 1)),
  };
}

/** Image file names the sheet needs, matched against picked files (case-insensitive, base name). */
export function matchImages(required: string[], files: { name: string }[]) {
  const byName = new Map(files.map((f) => [f.name.split('/').pop()!.toLowerCase(), f]));
  const found = new Map<string, { name: string }>();
  const missing: string[] = [];
  for (const name of required) {
    const f = byName.get(name.split('/').pop()!.toLowerCase());
    if (f) found.set(name, f);
    else missing.push(name);
  }
  return { found, missing };
}
