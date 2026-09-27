import { and, count, desc, eq, ilike, inArray, or, sql } from 'drizzle-orm';
import { entitlements, profiles, users, type Db, type Tx } from '@plengo/db';
import type {
  AccessScope,
  AccessSettings,
  AdminEntitlement,
  AdminStudent,
  MyEntitlement,
  ScopeAccess,
} from '@plengo/contracts';
import { AppError } from '../lib/app-error.js';
import { endOfBusinessDay } from '../lib/business-time.js';
import {
  entitlementActiveAt,
  scopeKey,
  toScope,
  type AccessRepository,
  type EntitlementRow,
  type Scope,
  type ScopeColumns,
} from '../repositories/access-repository.js';
import type { AuditService } from './audit-service.js';
import type { ConfigService } from './config-service.js';
import type { AdminActor } from './structure-service.js';

export type { Scope } from '../repositories/access-repository.js';

/** Any content item: general subject content has no track (spec §8.1). */
export interface ScopedItem {
  subjectId: string;
  teacherTrackId: string | null;
  isFree?: boolean;
}

/** spec §8.6 scopeOf(item): a track item belongs to the track scope only, never the subject scope. */
export function scopeOf(item: ScopedItem): Scope {
  return item.teacherTrackId
    ? { scopeType: 'teacher_track', subjectId: null, teacherTrackId: item.teacherTrackId }
    : { scopeType: 'subject', subjectId: item.subjectId, teacherTrackId: null };
}

export const subjectScope = (subjectId: string): Scope => ({
  scopeType: 'subject',
  subjectId,
  teacherTrackId: null,
});
export const trackScope = (teacherTrackId: string): Scope => ({
  scopeType: 'teacher_track',
  subjectId: null,
  teacherTrackId,
});

const ACTIVE_SCOPE_INDEXES = new Set(['entitlements_one_active_subject', 'entitlements_one_active_track']);

/**
 * spec §8.3: a unique violation on the active-scope indexes means a concurrent grant won the race.
 * The losing transaction has already rolled back; answer ALREADY_ENTITLED. Anything else is rethrown.
 */
export function rethrowActiveScopeConflict(err: unknown): never {
  const pg = ((err as { cause?: unknown }).cause ?? err) as { code?: string; constraint?: string };
  if (pg.code === '23505' && ACTIVE_SCOPE_INDEXES.has(pg.constraint ?? ''))
    throw new AppError('ALREADY_ENTITLED');
  throw err;
}

/** What a grant gives: permanent, or until a fixed instant. */
export type AccessTerm = { permanent: true } | { permanent: false; expiresAt: Date };

export interface GrantInput {
  userId: string;
  scope: Scope;
  term: AccessTerm;
  source: 'coupon' | 'admin_grant';
  couponId?: string;
  grantedByAdminId?: string;
}

/** Interprets the admin-facing access term fields (spec §9.1) at `now`. */
export function resolveTerm(
  input: {
    permanentAccess?: boolean | null | undefined;
    accessDurationDays?: number | null | undefined;
    accessExpiresAt?: Date | null | undefined;
  },
  now: Date,
): AccessTerm {
  if (input.permanentAccess) return { permanent: true };
  if (input.accessDurationDays) {
    return { permanent: false, expiresAt: new Date(now.getTime() + input.accessDurationDays * 86_400_000) };
  }
  if (input.accessExpiresAt) return { permanent: false, expiresAt: input.accessExpiresAt };
  throw new AppError('VALIDATION_ERROR', { details: { field: 'permanentAccess' } });
}

const iso = (d: Date | null) => (d ? d.toISOString() : null);

/**
 * Entitlements and the §8.6 authorization helpers. Access is always evaluated against the clock:
 * an entitlement whose `expires_at` has passed is locked immediately, whatever its stored status.
 */
export function createAccessService(deps: {
  db: Db;
  repo: AccessRepository;
  config: ConfigService;
  audit: AuditService;
  timeZone: string;
  now?: () => Date;
}) {
  const { db, repo, config, audit, timeZone } = deps;
  const now = deps.now ?? (() => new Date());

  function stateOf(e: EntitlementRow, at: Date): MyEntitlement['state'] {
    if (e.status === 'revoked') return 'revoked';
    if (e.status === 'active' && e.startsAt <= at && (!e.expiresAt || e.expiresAt > at)) return 'active';
    return 'expired';
  }

  function fallbackScope(row: ScopeColumns): AccessScope {
    return {
      scopeType: row.scopeType,
      subjectId: row.subjectId ?? '',
      teacherTrackId: row.teacherTrackId,
      subjectNameAr: '',
      trackTitleAr: null,
      teacherNameAr: null,
      educationLevelId: '',
    };
  }

  async function toMine(rows: EntitlementRow[], at = now()): Promise<MyEntitlement[]> {
    const scopes = await repo.describeScopes(rows);
    return rows.map((e) => ({
      id: e.id,
      scope: scopes.get(scopeKey(e)) ?? fallbackScope(e),
      source: e.source,
      startsAt: e.startsAt.toISOString(),
      expiresAt: iso(e.expiresAt),
      isPermanent: e.isPermanent,
      state: stateOf(e, at),
    }));
  }

  async function toAdmin(rows: { entitlement: EntitlementRow; couponLast4: string | null }[]) {
    const mine = await toMine(rows.map((r) => r.entitlement));
    return rows.map(({ entitlement: e, couponLast4 }, i): AdminEntitlement => ({
      ...mine[i]!,
      userId: e.userId,
      status: e.status,
      couponId: e.couponId,
      couponLast4,
      grantedByAdminId: e.grantedByAdminId,
      revokedAt: iso(e.revokedAt),
      revokeReason: e.revokeReason,
      createdAt: e.createdAt.toISOString(),
    }));
  }

  /**
   * Preloads a student's active entitlements and the running promotions so many items can be checked
   * without a query each (lists, quizzes). Build one per request: it is a snapshot of `at`.
   */
  async function context(userId: string, at = now()) {
    const [owned, promos] = await Promise.all([
      repo.activeEntitlements(userId, at),
      repo.runningPromotions(at),
    ]);
    const byScope = new Map(owned.map((e) => [scopeKey(e), e]));
    const promoByScope = new Map<string, (typeof promos)[number]>();
    for (const p of promos) {
      const current = promoByScope.get(scopeKey(p));
      if (!current || p.endsAt > current.endsAt) promoByScope.set(scopeKey(p), p);
    }

    const scopeAccess = (scope: Scope): ScopeAccess => {
      const e = byScope.get(scopeKey(scope));
      const p = promoByScope.get(scopeKey(scope));
      return {
        hasAccess: !!e || !!p,
        reason: e ? 'entitlement' : p ? 'promotion' : null,
        isPermanent: e?.isPermanent ?? false,
        entitlementExpiresAt: iso(e?.expiresAt ?? null),
        promotionTitleAr: p?.titleAr ?? null,
        promotionEndsAt: iso(p?.endsAt ?? null),
      };
    };

    return {
      at,
      hasActiveEntitlement: (scope: Scope) => byScope.has(scopeKey(scope)),
      isPromoted: (scope: Scope) => promoByScope.has(scopeKey(scope)),
      scopeAccess,
      /** spec §8.6: item.is_free OR isPromoted(scopeOf(item)) OR hasActiveEntitlement(user, scopeOf(item)). */
      canAccessItem: (item: ScopedItem) => item.isFree === true || scopeAccess(scopeOf(item)).hasAccess,
    };
  }

  /**
   * Steps 8–11 of §9.4, shared by coupon redemption and admin grants. Must run inside the caller's
   * transaction; a 23505 on the active-scope indexes surfaces from the insert and the caller maps it.
   * Settings are read by the caller before the transaction: a transaction must never wait for a
   * second pool connection while it holds row locks.
   */
  async function grantInTx(tx: Tx, input: GrantInput, at: Date, settings: AccessSettings) {
    await repo.expireStale(tx, input.userId, input.scope, at);
    const existing = await repo.lockActive(tx, input.userId, input.scope);
    let upgraded = false;
    if (existing) {
      const upgrade =
        input.term.permanent && !existing.isPermanent && settings.allowTemporaryToPermanentUpgrade;
      if (!upgrade) throw new AppError('ALREADY_ENTITLED');
      await repo.update(tx, existing.id, { status: 'superseded', updatedAt: at });
      upgraded = true;
    }
    const entitlement = await repo.insert(tx, {
      userId: input.userId,
      ...input.scope,
      source: input.source,
      couponId: input.couponId ?? null,
      grantedByAdminId: input.grantedByAdminId ?? null,
      startsAt: at,
      isPermanent: input.term.permanent,
      expiresAt: input.term.permanent ? null : input.term.expiresAt,
      status: 'active',
      createdAt: at,
      updatedAt: at,
    });
    return { entitlement, upgraded, superseded: existing };
  }

  async function studentOrNotFound(userId: string) {
    const [row] = await db
      .select({ id: users.id })
      .from(users)
      .where(and(eq(users.id, userId), eq(users.role, 'student')))
      .limit(1);
    if (!row) throw new AppError('NOT_FOUND');
  }

  async function assertScope(scope: Scope) {
    if (!(await repo.scopeExists(scope))) throw new AppError('NOT_FOUND', { details: { field: 'scope' } });
  }

  const studentColumns = {
    id: users.id,
    email: users.email,
    name: users.name,
    fullName: profiles.fullName,
    educationLevelId: profiles.educationLevelId,
    emailVerified: users.emailVerified,
    status: users.status,
    createdAt: users.createdAt,
  };

  async function toStudents(
    rows: {
      id: string;
      email: string;
      name: string;
      fullName: string | null;
      educationLevelId: string | null;
      emailVerified: boolean;
      status: 'active' | 'disabled';
      createdAt: Date;
    }[],
  ): Promise<AdminStudent[]> {
    if (!rows.length) return [];
    const at = now();
    const counts = await db
      .select({ userId: entitlements.userId, n: count() })
      .from(entitlements)
      .where(
        and(
          inArray(
            entitlements.userId,
            rows.map((r) => r.id),
          ),
          entitlementActiveAt(at),
        ),
      )
      .groupBy(entitlements.userId);
    const byUser = new Map(counts.map((c) => [c.userId, c.n]));
    return rows.map((r) => ({
      id: r.id,
      email: r.email,
      fullName: r.fullName ?? r.name,
      educationLevelId: r.educationLevelId,
      emailVerified: r.emailVerified,
      status: r.status,
      createdAt: r.createdAt.toISOString(),
      activeEntitlementCount: byUser.get(r.id) ?? 0,
    }));
  }

  return {
    context,
    scopeOf,
    grantInTx,

    async scopeAccess(userId: string, scope: Scope) {
      return (await context(userId)).scopeAccess(scope);
    },
    async hasActiveEntitlement(userId: string, scope: Scope) {
      return (await context(userId)).hasActiveEntitlement(scope);
    },
    async isPromoted(scope: Scope) {
      const at = now();
      return (await repo.runningPromotions(at)).some((p) => scopeKey(p) === scopeKey(scope));
    },
    async canAccessItem(userId: string, item: ScopedItem) {
      return item.isFree === true || (await context(userId)).canAccessItem(item);
    },
    /** For content endpoints: locked items never return payloads (§8.6). */
    async assertCanAccessItem(userId: string, item: ScopedItem) {
      if (!(await this.canAccessItem(userId, item))) throw new AppError('CONTENT_LOCKED');
    },

    describeScopes: (rows: ScopeColumns[]) => repo.describeScopes(rows),
    toMine,

    /** "My access": active entitlements first, then the rest, newest first (§23.2 #28). */
    async myEntitlements(userId: string): Promise<MyEntitlement[]> {
      const rows = await repo.listForUser(userId);
      const mine = await toMine(rows.map((r) => r.entitlement));
      const rank = { active: 0, expired: 1, revoked: 2 } as const;
      return mine.sort((a, b) => rank[a.state] - rank[b.state]);
    },

    // ---- admin ----

    async searchStudents(q: string | undefined): Promise<AdminStudent[]> {
      const term = q?.trim();
      const filter = term
        ? or(
            ilike(users.email, `%${term}%`),
            ilike(profiles.fullName, `%${term}%`),
            sql`${users.id}::text = ${term}`,
          )
        : undefined;
      const rows = await db
        .select(studentColumns)
        .from(users)
        .leftJoin(profiles, eq(profiles.userId, users.id))
        .where(and(eq(users.role, 'student'), filter))
        .orderBy(desc(users.createdAt))
        .limit(50);
      return toStudents(rows);
    },

    async studentDetail(userId: string) {
      const [row] = await db
        .select(studentColumns)
        .from(users)
        .leftJoin(profiles, eq(profiles.userId, users.id))
        .where(and(eq(users.id, userId), eq(users.role, 'student')))
        .limit(1);
      if (!row) throw new AppError('NOT_FOUND');
      const [student] = await toStudents([row]);
      return {
        student: student!,
        entitlements: await toAdmin(await repo.listForUser(userId, { includeSuperseded: true })),
      };
    },

    /** Admin grant (spec §8.3): same overlap rules and 23505 mapping as coupon redemption. Audited. */
    async grant(
      actor: AdminActor,
      userId: string,
      input: {
        scope: Scope;
        permanentAccess?: boolean | undefined;
        accessDurationDays?: number | null | undefined;
        accessExpiresOn?: string | null | undefined;
      },
    ): Promise<AdminEntitlement> {
      await studentOrNotFound(userId);
      await assertScope(input.scope);
      const at = now();
      const term = resolveTerm(
        {
          ...input,
          accessExpiresAt: input.accessExpiresOn ? endOfBusinessDay(input.accessExpiresOn, timeZone) : null,
        },
        at,
      );
      if (!term.permanent && term.expiresAt <= at) {
        throw new AppError('VALIDATION_ERROR', { details: { field: 'accessExpiresOn' } });
      }
      const settings = await config.getAccessSettings();
      let result;
      try {
        result = await db.transaction(async (tx) => {
          const granted = await grantInTx(
            tx,
            { userId, scope: input.scope, term, source: 'admin_grant', grantedByAdminId: actor.adminId },
            at,
            settings,
          );
          await audit.record(
            {
              actorAdminId: actor.adminId,
              action: 'entitlement.granted',
              resourceType: 'entitlement',
              resourceId: granted.entitlement.id,
              metadata: {
                userId,
                ...input.scope,
                isPermanent: term.permanent,
                expiresAt: term.permanent ? null : term.expiresAt.toISOString(),
                supersededId: granted.superseded?.id ?? null,
              },
              ip: actor.ip,
            },
            tx,
          );
          return granted;
        });
      } catch (err) {
        rethrowActiveScopeConflict(err);
      }
      return (await toAdmin([{ entitlement: result.entitlement, couponLast4: null }]))[0]!;
    },

    /**
     * Extend instead of granting a duplicate (§8.3): a later date, or permanent. An expired entitlement
     * becomes active again, which the active-scope indexes allow only if no other one is active.
     */
    async extend(
      actor: AdminActor,
      id: string,
      input: { makePermanent?: boolean | undefined; expiresOn?: string | null | undefined },
    ): Promise<AdminEntitlement> {
      const at = now();
      const expiresAt = input.expiresOn ? endOfBusinessDay(input.expiresOn, timeZone) : null;
      if (!input.makePermanent && (!expiresAt || expiresAt <= at)) {
        throw new AppError('VALIDATION_ERROR', { details: { field: 'expiresOn' } });
      }
      let updated: EntitlementRow;
      try {
        updated = await db.transaction(async (tx) => {
          const current = await repo.getForUpdate(tx, id);
          if (!current) throw new AppError('NOT_FOUND');
          if (current.status === 'revoked' || current.status === 'superseded') {
            throw new AppError('VALIDATION_ERROR', { details: { field: 'status' } });
          }
          const scope = toScope(current);
          await repo.expireStale(tx, current.userId, scope, at);
          const active = await repo.lockActive(tx, current.userId, scope);
          if (active && active.id !== current.id) throw new AppError('ALREADY_ENTITLED');
          const row = await repo.update(tx, id, {
            status: 'active',
            isPermanent: !!input.makePermanent,
            expiresAt: input.makePermanent ? null : expiresAt,
            updatedAt: at,
          });
          await audit.record(
            {
              actorAdminId: actor.adminId,
              action: 'entitlement.extended',
              resourceType: 'entitlement',
              resourceId: id,
              metadata: {
                userId: current.userId,
                from: {
                  isPermanent: current.isPermanent,
                  expiresAt: iso(current.expiresAt),
                  status: current.status,
                },
                to: { isPermanent: row.isPermanent, expiresAt: iso(row.expiresAt) },
              },
              ip: actor.ip,
            },
            tx,
          );
          return row;
        });
      } catch (err) {
        rethrowActiveScopeConflict(err);
      }
      const [withCoupon] = (await repo.listForUser(updated.userId, { includeSuperseded: true })).filter(
        (r) => r.entitlement.id === id,
      );
      return (await toAdmin([withCoupon!]))[0]!;
    },

    async revoke(
      actor: AdminActor,
      id: string,
      reason: string | null | undefined,
    ): Promise<AdminEntitlement> {
      const at = now();
      await db.transaction(async (tx) => {
        const current = await repo.getForUpdate(tx, id);
        if (!current) throw new AppError('NOT_FOUND');
        if (current.status === 'revoked' || current.status === 'superseded') {
          throw new AppError('VALIDATION_ERROR', { details: { field: 'status' } });
        }
        await repo.update(tx, id, {
          status: 'revoked',
          revokedAt: at,
          revokedByAdminId: actor.adminId,
          revokeReason: reason ?? null,
          updatedAt: at,
        });
        await audit.record(
          {
            actorAdminId: actor.adminId,
            action: 'entitlement.revoked',
            resourceType: 'entitlement',
            resourceId: id,
            metadata: { userId: current.userId, reason: reason ?? null },
            ip: actor.ip,
          },
          tx,
        );
      });
      const row = (await repo.listForUser((await repo.get(id))!.userId, { includeSuperseded: true })).find(
        (r) => r.entitlement.id === id,
      )!;
      return (await toAdmin([row]))[0]!;
    },

    /** Nightly job: stored status catches up with the clock for reporting (§8.2). */
    expireAllStale: () => repo.expireAllStale(now()),
  };
}

export type AccessService = ReturnType<typeof createAccessService>;
