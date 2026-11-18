import { and, eq, isNull } from 'drizzle-orm';
import { freeAccessRules, subjects, teacherTracks, type Db } from '@plengo/db';
import type { FreeContentKind, FreeRule, FreeRulePreview, FreeRuleType } from '@plengo/contracts';
import { AppError } from '../lib/app-error.js';
import type { JobQueue } from '../jobs/queue.js';
import {
  scopeKey,
  scopeWhere,
  toScope,
  type AccessRepository,
  type Scope,
} from '../repositories/access-repository.js';
import type { StructureRepository } from '../repositories/structure-repository.js';
import type { AuditService } from './audit-service.js';
import type { ConfigService } from './config-service.js';
import {
  ITEM_KINDS,
  effectiveRule,
  previewCounts,
  ruleFreeIds,
  type ItemKind,
  type RankedItem,
  type RuleSpec,
  type ScopeOutline,
} from './free-rules.js';
import type { AdminActor } from './structure-service.js';

/**
 * A content table that stores `is_free` / `free_source` (spec §8.4). Questions, flashcard decks and
 * quizzes register one each as they arrive (Phases 5–7).
 */
export interface FreeContentSource {
  kind: ItemKind;
  /** Published items of the scope, with their placement and current free state. */
  items(scope: Scope): Promise<RankedItem[]>;
  /** Sets `is_free` on the scope's `free_source='rule'` items: true for `freeIds`, false otherwise. */
  applyRule(scope: Scope, freeIds: Set<string>): Promise<void>;
}

type RuleInput = {
  scope: Scope;
  contentKind: FreeContentKind;
  ruleType: FreeRuleType;
  ruleValue?: number | null | undefined;
};

export function createFreeRuleService(deps: {
  db: Db;
  accessRepo: AccessRepository;
  structureRepo: StructureRepository;
  audit: AuditService;
  jobs: JobQueue;
  config: ConfigService;
  sources: FreeContentSource[];
}) {
  const { db, accessRepo, structureRepo, audit, jobs, config, sources } = deps;

  /**
   * v3 §3: a kind with no rule in its scope (neither its own nor `all`) gets the default rule — the
   * first `defaultFreeLessons` lessons are free. Explicit rules (even `manual`) and manual item
   * overrides still win.
   */
  async function defaultRule(): Promise<RuleSpec | null> {
    const { defaultFreeLessons } = await config.getAccessSettings();
    return defaultFreeLessons > 0 ? { ruleType: 'first_n_lessons', ruleValue: defaultFreeLessons } : null;
  }

  async function ruleFor(
    rules: { contentKind: FreeContentKind; ruleType: FreeRuleType; ruleValue: number | null }[],
    kind: ItemKind,
  ) {
    return effectiveRule(rules, kind) ?? (await defaultRule());
  }

  async function outlineOf(scope: Scope): Promise<ScopeOutline> {
    let subjectId = scope.subjectId;
    if (scope.scopeType === 'teacher_track') {
      const [track] = await db
        .select({ subjectId: teacherTracks.subjectId })
        .from(teacherTracks)
        .where(eq(teacherTracks.id, scope.teacherTrackId));
      if (!track) return { units: [], lessons: [] };
      subjectId = track.subjectId;
    }
    const [units, lessons] = await Promise.all([
      structureRepo.listUnits(subjectId!),
      structureRepo.listLessons(subjectId!),
    ]);
    return { units, lessons };
  }

  const rulesOf = (scope: Scope) =>
    db.select().from(freeAccessRules).where(scopeWhere(freeAccessRules, scope));

  /** Kinds whose effective rule would change if `kind`'s rule changed. */
  const affectedKinds = (kind: FreeContentKind, existing: { contentKind: FreeContentKind }[]): ItemKind[] =>
    kind === 'all' ? ITEM_KINDS.filter((k) => !existing.some((r) => r.contentKind === k)) : [kind];

  async function preview(
    input: RuleInput | { scope: Scope; contentKind: FreeContentKind; ruleType: null },
  ): Promise<FreeRulePreview> {
    const existing = await rulesOf(input.scope);
    const outline = await outlineOf(input.scope);
    const rule: RuleSpec | null = input.ruleType
      ? { ruleType: input.ruleType, ruleValue: 'ruleValue' in input ? (input.ruleValue ?? null) : null }
      : // Removing a specific rule falls back to the scope's `all` rule, then to the default.
        ((input.contentKind !== 'all' ? existing.find((r) => r.contentKind === 'all') : undefined) ??
        (await defaultRule()));
    const byKind = [];
    for (const kind of affectedKinds(input.contentKind, existing)) {
      const source = sources.find((s) => s.kind === kind);
      const items = source ? await source.items(input.scope) : [];
      byKind.push({ contentKind: kind, ...previewCounts(rule, items, outline) });
    }
    return {
      freeCount: byKind.reduce((n, k) => n + k.freeCount, 0),
      paidCount: byKind.reduce((n, k) => n + k.paidCount, 0),
      byKind,
    };
  }

  async function toRules(rows: (typeof freeAccessRules.$inferSelect)[]): Promise<FreeRule[]> {
    const scopes = await accessRepo.describeScopes(rows);
    return rows
      .filter((r) => scopes.has(scopeKey(r)))
      .map((r) => ({
        id: r.id,
        scope: scopes.get(scopeKey(r))!,
        contentKind: r.contentKind,
        ruleType: r.ruleType,
        ruleValue: r.ruleValue,
        updatedAt: r.updatedAt.toISOString(),
      }));
  }

  /**
   * Re-evaluates every kind's effective rule over the scope's rule-sourced items. With
   * `onlyDefaulted`, only kinds that follow the default (no rule of their own) are touched.
   */
  async function recompute(scope: Scope, opts: { onlyDefaulted?: boolean } = {}) {
    const [rules, outline] = await Promise.all([rulesOf(scope), outlineOf(scope)]);
    for (const source of sources) {
      if (opts.onlyDefaulted && effectiveRule(rules, source.kind)) continue;
      const items = await source.items(scope);
      const rule = await ruleFor(rules, source.kind);
      await source.applyRule(scope, ruleFreeIds(rule, items, outline));
    }
  }

  return {
    list: async () => toRules(await db.select().from(freeAccessRules).orderBy(freeAccessRules.updatedAt)),

    preview: (input: RuleInput) => preview(input),

    /** Saves the rule, records the preview counts, and queues the recompute job (§8.4). Audited. */
    async upsert(actor: AdminActor, input: RuleInput): Promise<FreeRule> {
      if (!(await accessRepo.scopeExists(input.scope)))
        throw new AppError('NOT_FOUND', { details: { field: 'scope' } });
      const counts = await preview(input);
      const ruleValue = input.ruleValue ?? null;
      const row = await db.transaction(async (tx) => {
        const [existing] = await tx
          .select()
          .from(freeAccessRules)
          .where(
            and(scopeWhere(freeAccessRules, input.scope), eq(freeAccessRules.contentKind, input.contentKind)),
          )
          .for('update');
        const values = {
          ruleType: input.ruleType,
          ruleValue,
          updatedByAdminId: actor.adminId,
          updatedAt: new Date(),
        };
        const [saved] = existing
          ? await tx
              .update(freeAccessRules)
              .set(values)
              .where(eq(freeAccessRules.id, existing.id))
              .returning()
          : await tx
              .insert(freeAccessRules)
              .values({ ...input.scope, contentKind: input.contentKind, ...values })
              .returning();
        await audit.record(
          {
            actorAdminId: actor.adminId,
            action: 'free_rule.changed',
            resourceType: 'free_access_rule',
            resourceId: saved!.id,
            metadata: {
              ...input.scope,
              contentKind: input.contentKind,
              from: existing ? { ruleType: existing.ruleType, ruleValue: existing.ruleValue } : null,
              to: { ruleType: input.ruleType, ruleValue },
              preview: { freeCount: counts.freeCount, paidCount: counts.paidCount },
            },
            ip: actor.ip,
          },
          tx,
        );
        return saved!;
      });
      await jobs.send('access.recompute-free', { ...input.scope });
      return (await toRules([row]))[0]!;
    },

    async remove(actor: AdminActor, id: string) {
      const [row] = await db.select().from(freeAccessRules).where(eq(freeAccessRules.id, id));
      if (!row) throw new AppError('NOT_FOUND');
      const scope = toScope(row);
      const counts = await preview({ scope, contentKind: row.contentKind, ruleType: null });
      await db.transaction(async (tx) => {
        await tx.delete(freeAccessRules).where(eq(freeAccessRules.id, id));
        await audit.record(
          {
            actorAdminId: actor.adminId,
            action: 'free_rule.deleted',
            resourceType: 'free_access_rule',
            resourceId: id,
            metadata: {
              ...scope,
              contentKind: row.contentKind,
              from: { ruleType: row.ruleType, ruleValue: row.ruleValue },
              preview: { freeCount: counts.freeCount, paidCount: counts.paidCount },
            },
            ip: actor.ip,
          },
          tx,
        );
      });
      await jobs.send('access.recompute-free', { ...scope });
      return { id, deleted: true as const };
    },

    recompute,

    /**
     * Job (v3 §3): when `defaultFreeLessons` differs from the value last applied, re-evaluate every
     * scope's kinds that follow the default, then remember the value. Runs at startup and after the
     * setting changes; a no-op otherwise.
     */
    async applyDefaultIfChanged() {
      const { defaultFreeLessons } = await config.getAccessSettings();
      if ((await config.getAppliedDefaultFreeLessons()) === defaultFreeLessons) return false;
      const [subjectRows, trackRows] = await Promise.all([
        db.select({ id: subjects.id }).from(subjects).where(isNull(subjects.deletedAt)),
        db.select({ id: teacherTracks.id }).from(teacherTracks).where(isNull(teacherTracks.deletedAt)),
      ]);
      const scopes: Scope[] = [
        ...subjectRows.map((s) => ({ scopeType: 'subject' as const, subjectId: s.id, teacherTrackId: null })),
        ...trackRows.map((t) => ({
          scopeType: 'teacher_track' as const,
          subjectId: null,
          teacherTrackId: t.id,
        })),
      ];
      for (const scope of scopes) await recompute(scope, { onlyDefaulted: true });
      await config.setAppliedDefaultFreeLessons(defaultFreeLessons);
      return true;
    },

    /**
     * On publish (Phases 5–7): whether a newly published item is free under the scope's rule. Existing
     * items never change when new content is added (§8.4).
     */
    async isFreeOnPublish(scope: Scope, kind: ItemKind, itemId: string) {
      const source = sources.find((s) => s.kind === kind);
      if (!source) return false;
      const [rules, outline, items] = await Promise.all([
        rulesOf(scope),
        outlineOf(scope),
        source.items(scope),
      ]);
      return ruleFreeIds(await ruleFor(rules, kind), items, outline).has(itemId);
    },
  };
}

export type FreeRuleService = ReturnType<typeof createFreeRuleService>;
