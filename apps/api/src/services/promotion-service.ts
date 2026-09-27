import { desc, eq } from 'drizzle-orm';
import { promotions, type Db } from '@plengo/db';
import type { Promotion } from '@plengo/contracts';
import { AppError } from '../lib/app-error.js';
import { scopeKey, type AccessRepository, type Scope } from '../repositories/access-repository.js';
import type { AuditService } from './audit-service.js';
import type { AdminActor } from './structure-service.js';

type Row = typeof promotions.$inferSelect;

/** Temporary free access to a whole scope; no entitlement rows are created (spec §8.5). */
export function createPromotionService(deps: {
  db: Db;
  accessRepo: AccessRepository;
  audit: AuditService;
  now?: () => Date;
}) {
  const { db, accessRepo, audit } = deps;
  const now = deps.now ?? (() => new Date());

  async function toPromotions(rows: Row[]): Promise<Promotion[]> {
    const scopes = await accessRepo.describeScopes(rows);
    const at = now();
    return rows
      .filter((r) => scopes.has(scopeKey(r)))
      .map((r) => ({
        id: r.id,
        scope: scopes.get(scopeKey(r))!,
        titleAr: r.titleAr,
        startsAt: r.startsAt.toISOString(),
        endsAt: r.endsAt.toISOString(),
        isActive: r.isActive,
        state: !r.isActive
          ? 'disabled'
          : r.startsAt > at
            ? 'scheduled'
            : r.endsAt <= at
              ? 'ended'
              : 'running',
        createdAt: r.createdAt.toISOString(),
      }));
  }

  async function one(id: string) {
    const [row] = await db.select().from(promotions).where(eq(promotions.id, id));
    if (!row) throw new AppError('NOT_FOUND');
    return row;
  }

  const record = (actor: AdminActor, action: string, id: string, metadata: Record<string, unknown>) =>
    audit.record({
      actorAdminId: actor.adminId,
      action,
      resourceType: 'promotion',
      resourceId: id,
      metadata,
      ip: actor.ip,
    });

  return {
    list: async () => toPromotions(await db.select().from(promotions).orderBy(desc(promotions.startsAt))),

    async create(
      actor: AdminActor,
      input: {
        scope: Scope;
        titleAr: string;
        startsAt: string;
        endsAt: string;
        isActive?: boolean | undefined;
      },
    ): Promise<Promotion> {
      if (!(await accessRepo.scopeExists(input.scope)))
        throw new AppError('NOT_FOUND', { details: { field: 'scope' } });
      const [row] = await db
        .insert(promotions)
        .values({
          ...input.scope,
          titleAr: input.titleAr,
          startsAt: new Date(input.startsAt),
          endsAt: new Date(input.endsAt),
          isActive: input.isActive ?? true,
          createdByAdminId: actor.adminId,
        })
        .returning();
      await record(actor, 'promotion.created', row!.id, {
        ...input.scope,
        titleAr: input.titleAr,
        startsAt: input.startsAt,
        endsAt: input.endsAt,
      });
      return (await toPromotions([row!]))[0]!;
    },

    async update(
      actor: AdminActor,
      id: string,
      patch: {
        titleAr?: string | undefined;
        startsAt?: string | undefined;
        endsAt?: string | undefined;
        isActive?: boolean | undefined;
      },
    ): Promise<Promotion> {
      const current = await one(id);
      const startsAt = patch.startsAt ? new Date(patch.startsAt) : current.startsAt;
      const endsAt = patch.endsAt ? new Date(patch.endsAt) : current.endsAt;
      if (endsAt <= startsAt) throw new AppError('VALIDATION_ERROR', { details: { field: 'endsAt' } });
      const [row] = await db
        .update(promotions)
        .set({
          titleAr: patch.titleAr ?? current.titleAr,
          startsAt,
          endsAt,
          isActive: patch.isActive ?? current.isActive,
        })
        .where(eq(promotions.id, id))
        .returning();
      await record(actor, 'promotion.updated', id, { patch });
      return (await toPromotions([row!]))[0]!;
    },

    async remove(actor: AdminActor, id: string) {
      const current = await one(id);
      await db.delete(promotions).where(eq(promotions.id, id));
      await record(actor, 'promotion.deleted', id, { titleAr: current.titleAr });
      return { id, deleted: true as const };
    },
  };
}

export type PromotionService = ReturnType<typeof createPromotionService>;
