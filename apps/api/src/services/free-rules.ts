import type { FreeContentKind, FreeRuleType } from '@plengo/contracts';

/*
 * Materialized free content (spec §8.4): a scope's rule is evaluated against the current ordering and
 * the result is stored on each item (`is_free`, `free_source`). Pure functions here; the service
 * loads items through registered content sources (questions, decks and quizzes from Phase 5 on).
 */

export type ItemKind = Exclude<FreeContentKind, 'all'>;
export const ITEM_KINDS: ItemKind[] = ['questions', 'flashcard_decks', 'quizzes'];

export interface RuleSpec {
  ruleType: FreeRuleType;
  ruleValue: number | null;
}

/** A published content item in one scope. */
export interface RankedItem {
  id: string;
  unitId: string | null;
  lessonId: string | null;
  sortOrder: number;
  isFree: boolean;
  /** `free_source='manual_override'`: rules never change it. */
  manual: boolean;
}

export interface ScopeOutline {
  units: { id: string; sortOrder: number }[];
  lessons: { id: string; unitId: string | null; sortOrder: number }[];
}

const bySort = <T extends { sortOrder: number; id: string }>(a: T, b: T) =>
  a.sortOrder - b.sortOrder || a.id.localeCompare(b.id);

/**
 * The scope's reading order: each unit in order (its unit-level items, then each of its lessons),
 * then lessons directly under the subject, then items attached to neither.
 */
export function orderItems(items: RankedItem[], outline: ScopeOutline) {
  const units = [...outline.units].sort(bySort);
  const lessonsIn = (unitId: string | null) =>
    outline.lessons.filter((l) => l.unitId === unitId).sort(bySort);
  const lessonOrder = [...units.flatMap((u) => lessonsIn(u.id)), ...lessonsIn(null)];

  const slots: { unitId: string | null; lessonId: string | null }[] = [
    ...units.flatMap((u) => [
      { unitId: u.id, lessonId: null },
      ...lessonsIn(u.id).map((l) => ({ unitId: u.id, lessonId: l.id })),
    ]),
    ...lessonsIn(null).map((l) => ({ unitId: null, lessonId: l.id })),
    { unitId: null, lessonId: null },
  ];
  const lessonUnit = new Map(outline.lessons.map((l) => [l.id, l.unitId]));
  const slotIndex = (item: RankedItem) => {
    const unitId = item.lessonId ? (lessonUnit.get(item.lessonId) ?? item.unitId) : item.unitId;
    const i = slots.findIndex((s) => s.lessonId === item.lessonId && s.unitId === unitId);
    return i === -1 ? slots.length : i;
  };
  const ordered = [...items].sort((a, b) => slotIndex(a) - slotIndex(b) || bySort(a, b));
  return { ordered, lessonOrder, firstUnitId: units[0]?.id ?? null };
}

/** Ids the rule makes free, over every item (manual overrides still take a place in the order). */
export function ruleFreeIds(rule: RuleSpec | null, items: RankedItem[], outline: ScopeOutline): Set<string> {
  if (!rule || rule.ruleType === 'manual') return new Set();
  const { ordered, lessonOrder, firstUnitId } = orderItems(items, outline);
  const lessonUnit = new Map(outline.lessons.map((l) => [l.id, l.unitId]));
  const n = rule.ruleValue ?? 0;
  switch (rule.ruleType) {
    case 'first_n_items':
      return new Set(ordered.slice(0, n).map((i) => i.id));
    case 'percentage':
      return new Set(ordered.slice(0, Math.ceil((ordered.length * n) / 100)).map((i) => i.id));
    case 'first_n_lessons': {
      const lessons = new Set(lessonOrder.slice(0, n).map((l) => l.id));
      return new Set(ordered.filter((i) => i.lessonId && lessons.has(i.lessonId)).map((i) => i.id));
    }
    case 'first_unit':
      return new Set(
        ordered
          .filter((i) => firstUnitId && (i.lessonId ? lessonUnit.get(i.lessonId) : i.unitId) === firstUnitId)
          .map((i) => i.id),
      );
  }
}

/** Resulting free/paid split after applying a rule: rule items follow the rule, manual items keep theirs. */
export function previewCounts(rule: RuleSpec | null, items: RankedItem[], outline: ScopeOutline) {
  const free = ruleFreeIds(rule, items, outline);
  const freeCount = items.filter((i) => (i.manual ? i.isFree : free.has(i.id))).length;
  return { freeCount, paidCount: items.length - freeCount };
}

/** A specific kind's rule wins over the scope's `all` rule; no rule behaves like `manual`. */
export function effectiveRule<T extends { contentKind: FreeContentKind }>(
  rules: T[],
  kind: ItemKind,
): T | null {
  return rules.find((r) => r.contentKind === kind) ?? rules.find((r) => r.contentKind === 'all') ?? null;
}
