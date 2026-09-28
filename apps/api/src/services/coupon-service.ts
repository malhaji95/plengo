import { and, count, desc, eq, gt, isNotNull, max, sql } from 'drizzle-orm';
import {
  couponBatches,
  couponRedemptionFailures,
  couponRedemptions,
  coupons,
  users,
  type Db,
} from '@plengo/db';
import type { AdminCoupon, CouponBatch, ErrorCode, RedeemResult } from '@plengo/contracts';
import { decodeCursor, encodeCursor } from '../repositories/question-repository.js';
import { AppError } from '../lib/app-error.js';
import { businessDate, endOfBusinessDay, startOfBusinessDay } from '../lib/business-time.js';
import {
  formatCouponCode,
  generateCouponCode,
  normalizeCouponCode,
  type CouponCrypto,
} from '../lib/coupon-code.js';
import { toCsv, toXlsx, type Table } from '../lib/tabular.js';
import type { JobQueue } from '../jobs/queue.js';
import { scopeKey, toScope, type AccessRepository, type Scope } from '../repositories/access-repository.js';
import { rethrowActiveScopeConflict, resolveTerm, type AccessService } from './access-service.js';
import type { AuditService } from './audit-service.js';
import type { ConfigService } from './config-service.js';
import type { AdminActor } from './structure-service.js';

/** spec §9.5. */
export const COUPON_LIMITS = {
  perMinute: 5,
  perHour: 20,
  perIpHour: 60,
  consecutiveFailures: 10,
  cooldownMs: 30 * 60_000,
} as const;

const GENERATION_CHUNK = 500;

/** Failures that are logged to coupon_redemption_failures (steps 4–10 of §9.4). */
const LOGGED_FAILURES = new Set<ErrorCode>([
  'COUPON_NOT_FOUND',
  'COUPON_REVOKED',
  'COUPON_EXPIRED',
  'COUPON_ALREADY_USED',
  'ALREADY_ENTITLED',
]);

type RedeemContext = { userId: string; sessionId: string; ip: string | null };

/**
 * Coupons (spec §9). Redemption is one node-postgres transaction; coupon consumption happens after the
 * entitlement insert so a losing concurrent redemption rolls back without using the code (§8.3).
 * Coupon redemption stays separate from entitlement authorization (§41 rule 18).
 */
export function createCouponService(deps: {
  db: Db;
  access: AccessService;
  accessRepo: AccessRepository;
  config: ConfigService;
  audit: AuditService;
  jobs: JobQueue;
  crypto: CouponCrypto;
  hashIp: (ip: string) => string | null;
  timeZone: string;
  now?: () => Date;
}) {
  const { db, access, accessRepo, config, audit, jobs, crypto, hashIp, timeZone } = deps;
  const now = deps.now ?? (() => new Date());

  async function checkRateLimit(userId: string, ipHash: string | null, at: Date) {
    const since = (ms: number) => new Date(at.getTime() - ms);
    const attempts = async (by: 'user' | 'ip', windowMs: number) => {
      const from = since(windowMs);
      const [failed] = await db
        .select({ n: count() })
        .from(couponRedemptionFailures)
        .where(
          and(
            by === 'user'
              ? eq(couponRedemptionFailures.userId, userId)
              : eq(couponRedemptionFailures.ipHash, ipHash!),
            gt(couponRedemptionFailures.createdAt, from),
          ),
        );
      const [succeeded] = await db
        .select({ n: count() })
        .from(couponRedemptions)
        .where(
          and(
            by === 'user' ? eq(couponRedemptions.userId, userId) : eq(couponRedemptions.ipHash, ipHash!),
            gt(couponRedemptions.redeemedAt, from),
          ),
        );
      return failed!.n + succeeded!.n;
    };

    const limited = () => new AppError('RATE_LIMITED');
    if ((await attempts('user', 60_000)) >= COUPON_LIMITS.perMinute) throw limited();
    if ((await attempts('user', 3_600_000)) >= COUPON_LIMITS.perHour) throw limited();
    if (ipHash && (await attempts('ip', 3_600_000)) >= COUPON_LIMITS.perIpHour) throw limited();

    // Consecutive failures: those since the last success. Ten of them start a 30-minute cooldown
    // from the latest one; the next failure after a cooldown starts another.
    const [lastSuccess] = await db
      .select({ at: max(couponRedemptions.redeemedAt) })
      .from(couponRedemptions)
      .where(eq(couponRedemptions.userId, userId));
    const [streak] = await db
      .select({ n: count(), last: max(couponRedemptionFailures.createdAt) })
      .from(couponRedemptionFailures)
      .where(
        and(
          eq(couponRedemptionFailures.userId, userId),
          lastSuccess?.at ? gt(couponRedemptionFailures.createdAt, lastSuccess.at) : undefined,
        ),
      );
    if (
      streak!.n >= COUPON_LIMITS.consecutiveFailures &&
      streak!.last &&
      at.getTime() - streak!.last.getTime() < COUPON_LIMITS.cooldownMs
    ) {
      throw limited();
    }
  }

  async function logFailure(
    ctx: RedeemContext,
    ipHash: string | null,
    last4: string | null,
    reason: ErrorCode,
    at: Date,
  ) {
    await db.insert(couponRedemptionFailures).values({
      userId: ctx.userId,
      ipHash,
      codeLast4: last4,
      reason,
      createdAt: at,
    });
  }

  const batchColumns = {
    batch: couponBatches,
    redeemedCount: sql<number>`(select coalesce(sum(${coupons.currentUses}), 0)::int from ${coupons} where ${coupons.batchId} = ${couponBatches.id})`,
  };

  async function toBatches(rows: { batch: typeof couponBatches.$inferSelect; redeemedCount: number }[]) {
    const scopes = await access.describeScopes(rows.map((r) => r.batch));
    return rows.map(({ batch: b, redeemedCount }): CouponBatch => ({
      id: b.id,
      name: b.name,
      distributorName: b.distributorName,
      notes: b.notes,
      scope: scopes.get(scopeKey(b))!,
      quantity: b.quantity,
      generatedCount: b.generatedCount,
      redeemedCount,
      validFrom: b.validFrom?.toISOString() ?? null,
      expiresAt: b.expiresAt?.toISOString() ?? null,
      accessDurationDays: b.accessDurationDays,
      accessExpiresAt: b.accessExpiresAt?.toISOString() ?? null,
      permanentAccess: b.permanentAccess,
      status: b.status,
      createdAt: b.createdAt.toISOString(),
      revokedAt: b.revokedAt?.toISOString() ?? null,
    }));
  }

  async function getBatch(id: string): Promise<CouponBatch> {
    const [row] = await db.select(batchColumns).from(couponBatches).where(eq(couponBatches.id, id));
    if (!row) throw new AppError('NOT_FOUND');
    return (await toBatches([row]))[0]!;
  }

  async function listCoupons(
    where: ReturnType<typeof eq> | undefined,
    limit?: number,
    offset = 0,
  ): Promise<AdminCoupon[]> {
    const query = db
      .select({
        coupon: coupons,
        batchName: couponBatches.name,
        redeemedAt: couponRedemptions.redeemedAt,
        redeemedByUserId: couponRedemptions.userId,
        redeemedByEmail: users.email,
      })
      .from(coupons)
      .innerJoin(couponBatches, eq(couponBatches.id, coupons.batchId))
      .leftJoin(couponRedemptions, eq(couponRedemptions.couponId, coupons.id))
      .leftJoin(users, eq(users.id, couponRedemptions.userId))
      .where(where)
      .orderBy(coupons.createdAt, coupons.id);
    const rows = limit ? await query.limit(limit).offset(offset) : await query;
    return rows.map((r) => ({
      id: r.coupon.id,
      batchId: r.coupon.batchId,
      batchName: r.batchName,
      codeLast4: r.coupon.codeLast4,
      status: r.coupon.status,
      currentUses: r.coupon.currentUses,
      maxUses: r.coupon.maxUses,
      redeemedAt: r.redeemedAt?.toISOString() ?? null,
      redeemedByUserId: r.redeemedByUserId,
      redeemedByEmail: r.redeemedByEmail,
    }));
  }

  /**
   * One redemption at a time per student (in-process, like the other limits, ADR-006), so a burst
   * of parallel requests cannot all pass the rate-limit count before any attempt is recorded.
   */
  const perStudent = new Map<string, Promise<unknown>>();
  function serialized<T>(userId: string, run: () => Promise<T>): Promise<T> {
    const next = (perStudent.get(userId) ?? Promise.resolve()).catch(() => undefined).then(run);
    perStudent.set(userId, next);
    const clear = () => {
      if (perStudent.get(userId) === next) perStudent.delete(userId);
    };
    next.then(clear, clear);
    return next;
  }

  const service = {
    redeem: (ctx: RedeemContext, rawCode: string): Promise<RedeemResult> =>
      serialized(ctx.userId, () => service.redeemNow(ctx, rawCode)),

    /** spec §9.4, steps 1–15. */
    async redeemNow(ctx: RedeemContext, rawCode: string): Promise<RedeemResult> {
      const at = now();
      const ipHash = ctx.ip ? hashIp(ctx.ip) : null;
      await checkRateLimit(ctx.userId, ipHash, at);

      const code = normalizeCouponCode(rawCode);
      const last4 = code ? code.slice(-4) : null;
      if (!code) {
        await logFailure(ctx, ipHash, null, 'COUPON_NOT_FOUND', at);
        throw new AppError('COUPON_NOT_FOUND');
      }
      const codeHash = crypto.hash(code);
      const settings = await config.getAccessSettings();

      try {
        const result = await db.transaction(async (tx) => {
          const [coupon] = await tx
            .select()
            .from(coupons)
            .where(eq(coupons.codeHash, codeHash))
            .for('update');
          if (!coupon) throw new AppError('COUPON_NOT_FOUND');
          const [batch] = await tx
            .select({ status: couponBatches.status })
            .from(couponBatches)
            .where(eq(couponBatches.id, coupon.batchId));
          if (coupon.status === 'revoked' || batch?.status === 'revoked')
            throw new AppError('COUPON_REVOKED');
          if ((coupon.validFrom && coupon.validFrom > at) || (coupon.expiresAt && coupon.expiresAt <= at)) {
            throw new AppError('COUPON_EXPIRED');
          }
          if (coupon.currentUses >= coupon.maxUses) throw new AppError('COUPON_ALREADY_USED');
          const [mine] = await tx
            .select({ id: couponRedemptions.id })
            .from(couponRedemptions)
            .where(and(eq(couponRedemptions.couponId, coupon.id), eq(couponRedemptions.userId, ctx.userId)));
          if (mine) throw new AppError('COUPON_ALREADY_USED');

          const term = resolveTerm(coupon, at);
          // A fixed access end date that has already passed would grant nothing.
          if (!term.permanent && term.expiresAt <= at) throw new AppError('COUPON_EXPIRED');

          const granted = await access.grantInTx(
            tx,
            { userId: ctx.userId, scope: toScope(coupon), term, source: 'coupon', couponId: coupon.id },
            at,
            settings,
          );
          const uses = coupon.currentUses + 1;
          await tx
            .update(coupons)
            .set({ currentUses: uses, status: uses >= coupon.maxUses ? 'redeemed' : 'active' })
            .where(eq(coupons.id, coupon.id));
          await tx.insert(couponRedemptions).values({
            couponId: coupon.id,
            userId: ctx.userId,
            sessionId: ctx.sessionId,
            entitlementId: granted.entitlement.id,
            ipHash,
            redeemedAt: at,
          });
          return granted;
        });
        const [entitlement] = await access.toMine([result.entitlement], at);
        return { entitlement: entitlement!, upgraded: result.upgraded };
      } catch (err) {
        let failure: unknown = err;
        try {
          rethrowActiveScopeConflict(err);
        } catch (mapped) {
          failure = mapped;
        }
        if (failure instanceof AppError && LOGGED_FAILURES.has(failure.code)) {
          await logFailure(ctx, ipHash, last4, failure.code, at);
        }
        throw failure;
      }
    },

    // ---- admin ----

    listBatches: async () =>
      toBatches(await db.select(batchColumns).from(couponBatches).orderBy(desc(couponBatches.createdAt))),

    getBatch,

    /** One page of a batch's codes (a batch holds up to 5,000). */
    async batchCoupons(batchId: string, cursor?: string, limit = 200) {
      const offset = decodeCursor(cursor);
      const rows = await listCoupons(eq(coupons.batchId, batchId), limit + 1, offset);
      return {
        items: rows.slice(0, limit),
        nextCursor: rows.length > limit ? encodeCursor(offset + limit) : null,
      };
    },

    /** Full code (any spelling a student might type) or the last four characters (§26.2 search). */
    async searchCoupons(q: string): Promise<AdminCoupon[]> {
      const code = normalizeCouponCode(q);
      if (code) return listCoupons(eq(coupons.codeHash, crypto.hash(code)));
      const last4 = q.trim().toUpperCase();
      if (!/^[0-9A-Z]{4}$/.test(last4)) throw new AppError('VALIDATION_ERROR', { details: { field: 'q' } });
      return listCoupons(eq(coupons.codeLast4, last4), 100);
    },

    /** Creates the batch and queues code generation; the admin polls `generatedCount` (§9.6). Audited. */
    async createBatch(
      actor: AdminActor,
      input: {
        name: string;
        distributorName?: string | null | undefined;
        notes?: string | null | undefined;
        scope: Scope;
        quantity: number;
        validFrom?: string | null | undefined;
        expiresOn?: string | null | undefined;
        permanentAccess?: boolean | undefined;
        accessDurationDays?: number | null | undefined;
        accessExpiresOn?: string | null | undefined;
      },
    ): Promise<CouponBatch> {
      if (!(await accessRepo.scopeExists(input.scope))) {
        throw new AppError('NOT_FOUND', { details: { field: 'scope' } });
      }
      const at = now();
      const accessExpiresAt = input.accessExpiresOn
        ? endOfBusinessDay(input.accessExpiresOn, timeZone)
        : null;
      if (accessExpiresAt && accessExpiresAt <= at) {
        throw new AppError('VALIDATION_ERROR', { details: { field: 'accessExpiresOn' } });
      }
      const expiresAt = input.expiresOn ? endOfBusinessDay(input.expiresOn, timeZone) : null;
      if (expiresAt && expiresAt <= at)
        throw new AppError('VALIDATION_ERROR', { details: { field: 'expiresOn' } });

      const batch = await db.transaction(async (tx) => {
        const [row] = await tx
          .insert(couponBatches)
          .values({
            name: input.name,
            distributorName: input.distributorName ?? null,
            notes: input.notes ?? null,
            ...input.scope,
            quantity: input.quantity,
            validFrom: input.validFrom ? startOfBusinessDay(input.validFrom, timeZone) : null,
            expiresAt,
            permanentAccess: input.permanentAccess === true,
            accessDurationDays: input.accessDurationDays ?? null,
            accessExpiresAt,
            createdByAdminId: actor.adminId,
            createdAt: at,
          })
          .returning();
        await audit.record(
          {
            actorAdminId: actor.adminId,
            action: 'coupon_batch.generated',
            resourceType: 'coupon_batch',
            resourceId: row!.id,
            metadata: { name: input.name, quantity: input.quantity, ...input.scope },
            ip: actor.ip,
          },
          tx,
        );
        return row!;
      });
      await jobs.send('coupons.generate', { batchId: batch.id }, { singletonKey: batch.id });
      return getBatch(batch.id);
    },

    /**
     * Job: create the batch's remaining codes in chunks, each chunk committed with its progress so a
     * retried job resumes where it stopped. Hash collisions are skipped and regenerated.
     */
    async generateBatch(batchId: string) {
      for (;;) {
        const [batch] = await db.select().from(couponBatches).where(eq(couponBatches.id, batchId));
        if (!batch || batch.status === 'revoked' || batch.generatedCount >= batch.quantity) return;
        const size = Math.min(GENERATION_CHUNK, batch.quantity - batch.generatedCount);
        const codes = Array.from({ length: size }, generateCouponCode);
        await db.transaction(async (tx) => {
          const inserted = await tx
            .insert(coupons)
            .values(
              codes.map((code) => ({
                batchId,
                codeHash: crypto.hash(code),
                codeEncrypted: crypto.encrypt(code),
                codeLast4: code.slice(-4),
                scopeType: batch.scopeType,
                subjectId: batch.subjectId,
                teacherTrackId: batch.teacherTrackId,
                validFrom: batch.validFrom,
                expiresAt: batch.expiresAt,
                accessDurationDays: batch.accessDurationDays,
                accessExpiresAt: batch.accessExpiresAt,
                permanentAccess: batch.permanentAccess,
                createdByAdminId: batch.createdByAdminId,
              })),
            )
            .onConflictDoNothing({ target: coupons.codeHash })
            .returning({ id: coupons.id });
          await tx
            .update(couponBatches)
            .set({ generatedCount: sql`${couponBatches.generatedCount} + ${inserted.length}` })
            .where(eq(couponBatches.id, batchId));
        });
      }
    },

    /** spec §9.6 export columns. Plaintext codes leave the server only here. Audited. */
    async exportBatch(actor: AdminActor, batchId: string, format: 'csv' | 'xlsx') {
      const batch = await getBatch(batchId);
      const rows = await db
        .select({
          codeEncrypted: coupons.codeEncrypted,
          status: coupons.status,
          createdAt: coupons.createdAt,
        })
        .from(coupons)
        .where(eq(coupons.batchId, batchId))
        .orderBy(coupons.createdAt, coupons.id);
      const accessLabel = batch.permanentAccess
        ? 'permanent'
        : batch.accessDurationDays
          ? `${batch.accessDurationDays} days`
          : `until ${businessDate(new Date(batch.accessExpiresAt!), timeZone)}`;
      const table: Table = {
        header: [
          'code',
          'batch_name',
          'distributor',
          'scope_type',
          'subject',
          'teacher_track',
          'access',
          'code_expires_at',
          'status',
          'created_at',
        ],
        rows: rows.map((r) => [
          formatCouponCode(crypto.decrypt(r.codeEncrypted)),
          batch.name,
          batch.distributorName ?? '',
          batch.scope.scopeType,
          batch.scope.subjectNameAr,
          batch.scope.trackTitleAr ?? '',
          accessLabel,
          batch.expiresAt ? businessDate(new Date(batch.expiresAt), timeZone) : '',
          r.status,
          r.createdAt.toISOString(),
        ]),
      };
      await audit.record({
        actorAdminId: actor.adminId,
        action: 'coupon_batch.exported',
        resourceType: 'coupon_batch',
        resourceId: batchId,
        metadata: { format, count: rows.length },
        ip: actor.ip,
      });
      const base = `coupons-${batch.id.slice(0, 8)}`;
      return format === 'xlsx'
        ? {
            filename: `${base}.xlsx`,
            contentType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            body: toXlsx(table, 'coupons'),
          }
        : { filename: `${base}.csv`, contentType: 'text/csv; charset=utf-8', body: toCsv(table) };
    },

    /**
     * Unredeemed codes become unusable. Existing entitlements are untouched unless an admin revokes
     * them explicitly (§9.6). Audited.
     */
    async revokeBatch(actor: AdminActor, batchId: string): Promise<CouponBatch> {
      const at = now();
      await db.transaction(async (tx) => {
        const [batch] = await tx
          .select()
          .from(couponBatches)
          .where(eq(couponBatches.id, batchId))
          .for('update');
        if (!batch) throw new AppError('NOT_FOUND');
        if (batch.status === 'revoked') return;
        await tx
          .update(couponBatches)
          .set({ status: 'revoked', revokedAt: at, revokedByAdminId: actor.adminId })
          .where(eq(couponBatches.id, batchId));
        const revoked = await tx
          .update(coupons)
          .set({ status: 'revoked' })
          .where(and(eq(coupons.batchId, batchId), eq(coupons.status, 'active')))
          .returning({ id: coupons.id });
        await audit.record(
          {
            actorAdminId: actor.adminId,
            action: 'coupon_batch.revoked',
            resourceType: 'coupon_batch',
            resourceId: batchId,
            metadata: { revokedCodes: revoked.length },
            ip: actor.ip,
          },
          tx,
        );
      });
      return getBatch(batchId);
    },

    /** Users and IPs with the most failures in the last 24 hours (§9.5). */
    async failureReport() {
      const since = new Date(now().getTime() - 24 * 3_600_000);
      const recent = gt(couponRedemptionFailures.createdAt, since);
      const byUser = await db
        .select({
          userId: couponRedemptionFailures.userId,
          email: users.email,
          failures: count(),
          lastAt: max(couponRedemptionFailures.createdAt),
        })
        .from(couponRedemptionFailures)
        .leftJoin(users, eq(users.id, couponRedemptionFailures.userId))
        .where(and(recent, isNotNull(couponRedemptionFailures.userId)))
        .groupBy(couponRedemptionFailures.userId, users.email)
        .orderBy(desc(count()))
        .limit(50);
      const byIp = await db
        .select({
          ipHash: couponRedemptionFailures.ipHash,
          failures: count(),
          lastAt: max(couponRedemptionFailures.createdAt),
        })
        .from(couponRedemptionFailures)
        .where(and(recent, isNotNull(couponRedemptionFailures.ipHash)))
        .groupBy(couponRedemptionFailures.ipHash)
        .orderBy(desc(count()))
        .limit(50);
      return {
        since: since.toISOString(),
        users: byUser.map((r) => ({
          userId: r.userId!,
          email: r.email,
          failures: r.failures,
          lastAt: r.lastAt!.toISOString(),
        })),
        ips: byIp.map((r) => ({ ipHash: r.ipHash!, failures: r.failures, lastAt: r.lastAt!.toISOString() })),
      };
    },
  };
  return service;
}

export type CouponService = ReturnType<typeof createCouponService>;
