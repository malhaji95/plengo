import type { components } from './api-schema';

export type QuestionCategory = components['schemas']['AdminQuestionCategory'];

/** Depth of each category under its parents (the API lists parents before children). */
export function depthOf(categories: Pick<QuestionCategory, 'id' | 'parentId'>[]): Map<string, number> {
  const byId = new Map(categories.map((c) => [c.id, c]));
  const depth = new Map<string, number>();
  const at = (id: string, guard = 0): number => {
    if (depth.has(id)) return depth.get(id)!;
    const parent = byId.get(id)?.parentId;
    const d = parent && byId.has(parent) && guard < 20 ? at(parent, guard + 1) + 1 : 0;
    depth.set(id, d);
    return d;
  };
  for (const c of categories) at(c.id);
  return depth;
}

/** "علل › علل فيزيائياً": the category's name after its parents. */
export function categoryLabel(categories: QuestionCategory[], id: string): string {
  const byId = new Map(categories.map((c) => [c.id, c]));
  const names: string[] = [];
  let at = byId.get(id);
  for (let i = 0; at && i < 20; i++) {
    names.unshift(at.nameAr);
    at = at.parentId ? byId.get(at.parentId) : undefined;
  }
  return names.join(' › ');
}

/** The ids a category may take as parent: not itself and none of its descendants. */
export function allowedParents(categories: QuestionCategory[], self: QuestionCategory | null) {
  if (!self) return categories;
  const banned = new Set([self.id]);
  let grew = true;
  while (grew) {
    grew = false;
    for (const c of categories) {
      if (c.parentId && banned.has(c.parentId) && !banned.has(c.id)) {
        banned.add(c.id);
        grew = true;
      }
    }
  }
  return categories.filter(
    (c) => !banned.has(c.id) && (c.subjectId === null || c.subjectId === self.subjectId),
  );
}
