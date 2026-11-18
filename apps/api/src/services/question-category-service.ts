import type {
  AdminQuestionCategory,
  StudentQuestionCategory,
  StudentQuestionCategoryList,
} from '@plengo/contracts';
import { AppError } from '../lib/app-error.js';
import type {
  CategoryRow,
  QuestionCategoryRepository,
} from '../repositories/question-category-repository.js';
import type { StructureRepository } from '../repositories/structure-repository.js';
import type { TeacherRepository } from '../repositories/teacher-repository.js';
import { scopeOf, type AccessService } from './access-service.js';
import type { AuditService } from './audit-service.js';
import { assertVisibleScope, invalid } from './content-placement.js';
import { guardCode, type AdminActor } from './structure-service.js';

/** Parents before their children, each level in sort order (input already sorted). */
function treeOrder<T extends { id: string; parentId: string | null }>(rows: T[]): T[] {
  const ids = new Set(rows.map((r) => r.id));
  const out: T[] = [];
  const seen = new Set<string>();
  const visit = (parentId: string | null) => {
    for (const r of rows) {
      if (seen.has(r.id)) continue;
      const rootLike = parentId === null ? !r.parentId || !ids.has(r.parentId) : r.parentId === parentId;
      if (!rootLike) continue;
      seen.add(r.id);
      out.push(r);
      visit(r.id);
    }
  };
  visit(null);
  // Anything left (a cycle cannot be stored, but stay total).
  for (const r of rows) if (!seen.has(r.id)) out.push(r);
  return out;
}

/**
 * Question categories (v3 §3, §5). Global categories apply to every subject; a subject's own add to
 * them. A child's parent is global or of the same subject; a global category's parent is global.
 */
export function createQuestionCategoryService(deps: {
  repo: QuestionCategoryRepository;
  structureRepo: StructureRepository;
  teacherRepo: TeacherRepository;
  access: AccessService;
  audit: AuditService;
  now?: () => Date;
}) {
  const { repo, structureRepo, teacherRepo, access, audit } = deps;
  const now = deps.now ?? (() => new Date());

  const toAdmin = (r: {
    category: CategoryRow;
    subjectNameAr: string | null;
    questionCount: number;
  }): AdminQuestionCategory => ({
    id: r.category.id,
    subjectId: r.category.subjectId,
    subjectNameAr: r.subjectNameAr,
    parentId: r.category.parentId,
    code: r.category.code,
    nameAr: r.category.nameAr,
    sortOrder: r.category.sortOrder,
    questionCount: r.questionCount,
    createdAt: r.category.createdAt.toISOString(),
    updatedAt: r.category.updatedAt.toISOString(),
  });

  async function adminGet(id: string) {
    const c = (await repo.get(id)) ?? notFound();
    const rows = await repo.list(
      c.subjectId ? { subjectId: c.subjectId, subjectOnly: true } : { globalOnly: true },
    );
    return toAdmin(rows.find((r) => r.category.id === id)!);
  }
  const notFound = (): never => {
    throw new AppError('NOT_FOUND');
  };

  /** The parent exists and fits the category's subject; no cycle through `selfId`. */
  async function checkParent(parentId: string, subjectId: string | null, selfId?: string) {
    const parent = await repo.get(parentId);
    if (!parent) invalid('parentId');
    if (parent!.subjectId !== null && parent!.subjectId !== subjectId)
      invalid('parentId', 'subject_mismatch');
    if (selfId) {
      let at: CategoryRow | null = parent!;
      for (let depth = 0; at && depth < 50; depth++) {
        if (at.id === selfId) invalid('parentId', 'cycle');
        at = at.parentId ? await repo.get(at.parentId) : null;
      }
    }
  }

  const record = (actor: AdminActor, action: string, id: string, metadata: Record<string, unknown> = {}) =>
    audit.record({
      actorAdminId: actor.adminId,
      action,
      resourceType: 'question_category',
      resourceId: id,
      metadata,
      ip: actor.ip,
    });

  /** Ids plus every live descendant (a parent category includes its children). */
  async function expand(ids: string[]): Promise<string[]> {
    if (!ids.length) return [];
    const all = (await repo.list()).map((r) => r.category);
    const out = new Set(ids);
    let frontier = [...ids];
    while (frontier.length) {
      const next = all.filter((c) => c.parentId && frontier.includes(c.parentId) && !out.has(c.id));
      for (const c of next) out.add(c.id);
      frontier = next.map((c) => c.id);
    }
    return [...out];
  }

  return {
    expand,

    /** A live category usable for a question of `subjectId`; throws VALIDATION_ERROR otherwise. */
    async assertUsable(categoryId: string, subjectId: string) {
      const c = await repo.get(categoryId);
      if (!c || (c.subjectId !== null && c.subjectId !== subjectId)) invalid('categoryId');
    },

    /** Code → category usable for each subject, the subject's own code winning over a global one. */
    async codeLookup(subjectIds: string[]) {
      const rows = await repo.usableIn(subjectIds);
      return (subjectId: string, code: string) =>
        rows.find((c) => c.subjectId === subjectId && c.code === code) ??
        rows.find((c) => c.subjectId === null && c.code === code) ??
        null;
    },

    /** Category names by id (deleted ones included through the live list only). */
    async names(ids: string[]) {
      const rows = await repo.byIds([...new Set(ids)]);
      return new Map(rows.map((c) => [c.id, c.nameAr]));
    },

    // ---- admin ----

    async adminList(q: {
      subjectId?: string | undefined;
      globalOnly?: boolean | undefined;
      subjectOnly?: boolean | undefined;
    }): Promise<AdminQuestionCategory[]> {
      const rows = await repo.list({
        subjectId: q.subjectId,
        subjectOnly: q.subjectOnly ?? false,
        globalOnly: q.globalOnly ?? false,
      });
      return treeOrder(rows.map(toAdmin));
    },

    adminGet,

    async create(
      actor: AdminActor,
      input: {
        subjectId?: string | null | undefined;
        parentId?: string | null | undefined;
        code: string;
        nameAr: string;
        sortOrder?: number | undefined;
      },
    ) {
      const subjectId = input.subjectId ?? null;
      if (subjectId && !(await structureRepo.getSubject(subjectId, { studentVisible: false })))
        invalid('subjectId');
      if (input.parentId) await checkParent(input.parentId, subjectId);
      const row = await guardCode(async () =>
        repo.insert({
          subjectId,
          parentId: input.parentId ?? null,
          code: input.code,
          nameAr: input.nameAr,
          sortOrder: input.sortOrder ?? (await repo.nextSortOrder(subjectId)),
        }),
      );
      await record(actor, 'question_category.created', row.id, { subjectId, code: row.code });
      return adminGet(row.id);
    },

    async update(
      actor: AdminActor,
      id: string,
      patch: {
        parentId?: string | null | undefined;
        code?: string | undefined;
        nameAr?: string | undefined;
        sortOrder?: number | undefined;
      },
    ) {
      const current = (await repo.get(id)) ?? notFound();
      if (patch.parentId) await checkParent(patch.parentId, current.subjectId, id);
      await guardCode(() =>
        repo.update(id, {
          ...(patch.parentId !== undefined ? { parentId: patch.parentId } : {}),
          ...(patch.code !== undefined ? { code: patch.code } : {}),
          ...(patch.nameAr !== undefined ? { nameAr: patch.nameAr } : {}),
          ...(patch.sortOrder !== undefined ? { sortOrder: patch.sortOrder } : {}),
          updatedAt: now(),
        }),
      );
      await record(actor, 'question_category.updated', id, { ...patch });
      return adminGet(id);
    },

    /** Soft delete. A category with live children cannot be deleted; its questions lose it. */
    async remove(actor: AdminActor, id: string) {
      if (!(await repo.get(id))) notFound();
      if ((await repo.children(id)).length) throw new AppError('RESOURCE_IN_USE');
      await repo.remove(id, now());
      await record(actor, 'question_category.deleted', id);
      return { deleted: true };
    },

    // ---- student ----

    /**
     * The categories a subject's questions can use, with counts of published questions in the
     * scope (and unit or lesson): all, and those the student can open now.
     */
    async studentList(
      userId: string,
      q: {
        subjectId: string;
        teacherTrackId?: string | undefined;
        unitId?: string | undefined;
        lessonId?: string | undefined;
      },
    ): Promise<StudentQuestionCategoryList> {
      const trackId = q.teacherTrackId ?? null;
      await assertVisibleScope({ structureRepo, teacherRepo }, q.subjectId, trackId);
      const scope = scopeOf({ subjectId: q.subjectId, teacherTrackId: trackId });
      const [rows, counts, ctx] = await Promise.all([
        repo.list({ subjectId: q.subjectId }),
        repo.publishedCounts(scope, { unitId: q.unitId, lessonId: q.lessonId }),
        access.context(userId),
      ]);
      const open = ctx.scopeAccess(scope).hasAccess;
      const byCategory = new Map(counts.map((c) => [c.categoryId, c]));
      const countOf = (id: string | null) => {
        const c = byCategory.get(id);
        return { questionCount: c?.total ?? 0, accessibleCount: c ? (open ? c.total : c.free) : 0 };
      };
      const items: StudentQuestionCategory[] = treeOrder(
        rows.map(({ category: c }) => ({
          id: c.id,
          subjectId: c.subjectId,
          parentId: c.parentId,
          code: c.code,
          nameAr: c.nameAr,
          sortOrder: c.sortOrder,
          ...countOf(c.id),
        })),
      );
      return { items, uncategorized: countOf(null) };
    },
  };
}

export type QuestionCategoryService = ReturnType<typeof createQuestionCategoryService>;
