import type {
  AdminLoyaltyRedemption,
  AdminLoyaltyReward,
  AdminStudentLoyalty,
  LoyaltyLedgerEntry,
  LoyaltyRedemption,
  LoyaltySettings,
  LoyaltySummary,
} from '@plengo/contracts';
import type { Db } from '@plengo/db';
import { businessDay, DAY } from '@plengo/srs';
import { AppError } from '../lib/app-error.js';
import type { AccessRepository } from '../repositories/access-repository.js';
import type { FlashcardRepository } from '../repositories/flashcard-repository.js';
import type {
  LedgerRow,
  LoyaltyRepository,
  RedemptionRow,
  RewardRow,
} from '../repositories/loyalty-repository.js';
import type { AccessService } from './access-service.js';
import type { AuditService } from './audit-service.js';
import type { ConfigService } from './config-service.js';
import { invalid } from './content-placement.js';
import type { AdminActor } from './structure-service.js';

/** The business day (04:00 Damascus boundary, as streaks and the daily goal) of an instant. */
export const loyaltyDay = (at: Date) => new Date(businessDay(at.getTime()) * DAY).toISOString().slice(0, 10);

/** Reviews synced long after the fact still earn, on their own day; future timestamps count as now. */
const MAX_FUTURE_MS = 60_000;

const iso = (d: Date | null) => (d ? d.toISOString() : null);

const toEntry = (r: LedgerRow): LoyaltyLedgerEntry => ({
  id: r.id,
  delta: r.delta,
  reason: r.reason,
  refId: r.refId,
  day: r.day,
  note: r.note,
  createdAt: r.createdAt.toISOString(),
});

const toRedemption = (r: RedemptionRow): LoyaltyRedemption => ({
  id: r.id,
  rewardId: r.rewardId,
  titleAr: r.titleAr,
  kind: r.kind,
  costPoints: r.costPoints,
  deckId: r.deckId,
  status: r.status,
  note: r.note,
  createdAt: r.createdAt.toISOString(),
  handledAt: iso(r.handledAt),
});

/**
 * Loyalty programme (v3 §10). Points are earned after the work they reward is committed (review
 * sync, correct checks) in their own short transaction, deduplicated by the ledger's unique key, so a
 * retried sync never pays twice. A per-student advisory lock serialises the cap and balance checks.
 */
export function createLoyaltyService(deps: {
  db: Db;
  repo: LoyaltyRepository;
  accessRepo: AccessRepository;
  flashcardRepo: FlashcardRepository;
  access: AccessService;
  config: ConfigService;
  audit: AuditService;
  now?: () => Date;
}) {
  const { db, repo, accessRepo, flashcardRepo, access, config, audit } = deps;
  const now = deps.now ?? (() => new Date());

  /**
   * Awards `points` for each ref on its day, skipping refs that already earned and stopping at the
   * day's cap (a partial award fills it exactly). Returns the points written.
   */
  async function award(
    userId: string,
    reason: 'review' | 'correct_answer',
    points: number,
    cap: number,
    items: { refId: string; at: Date }[],
  ) {
    if (points <= 0 || !items.length) return 0;
    const at = now();
    const byDay = new Map<string, string[]>();
    for (const i of items) {
      const when = i.at.getTime() > at.getTime() + MAX_FUTURE_MS ? at : i.at;
      const day = loyaltyDay(when);
      byDay.set(day, [...(byDay.get(day) ?? []), i.refId]);
    }
    return db.transaction(async (tx) => {
      await repo.lockUser(tx, userId);
      let written = 0;
      for (const [day, refs] of byDay) {
        const seen = await repo.existingRefs(tx, userId, reason, day, refs);
        let earned = await repo.earnedOn(tx, userId, day);
        for (const refId of new Set(refs)) {
          if (seen.has(refId)) continue;
          const room = cap > 0 ? cap - earned : points;
          const delta = Math.min(points, room);
          if (delta <= 0) break;
          if (await repo.insertEntry(tx, { userId, delta, reason, refId, day, createdAt: at })) {
            earned += delta;
            written += delta;
          }
        }
      }
      return written;
    });
  }

  async function summary(userId: string): Promise<LoyaltySummary> {
    const rules = await config.getLoyaltySettings();
    const day = loyaltyDay(now());
    const [balance, earnedToday] = await Promise.all([
      repo.balance(db, userId),
      repo.earnedOn(db, userId, day),
    ]);
    return {
      enabled: rules.enabled,
      balance,
      earnedToday,
      dailyCap: rules.dailyCap,
      remainingToday: rules.dailyCap > 0 ? Math.max(0, rules.dailyCap - earnedToday) : null,
      day,
      rules,
    };
  }

  async function assertDeck(kind: RewardRow['kind'], deckId: string | null | undefined) {
    if (kind === 'unlock_deck') {
      if (!deckId) invalid('deckId');
      const deck = await flashcardRepo.getDeck(deckId!);
      if (!deck) invalid('deckId');
    } else if (deckId) invalid('deckId', 'custom_has_no_deck');
  }

  async function adminRewards(): Promise<AdminLoyaltyReward[]> {
    return (await repo.rewards({ activeOnly: false })).map((r) => ({
      id: r.reward.id,
      titleAr: r.reward.titleAr,
      description: r.reward.description,
      costPoints: r.reward.costPoints,
      kind: r.reward.kind,
      deckId: r.reward.deckId,
      deckTitleAr: r.deckTitleAr,
      isActive: r.reward.isActive,
      sortOrder: r.reward.sortOrder,
      redemptionCount: r.redemptionCount,
      createdAt: r.reward.createdAt.toISOString(),
      updatedAt: r.reward.updatedAt.toISOString(),
    }));
  }
  const adminReward = async (id: string) => {
    const found = (await adminRewards()).find((r) => r.id === id);
    if (!found) throw new AppError('NOT_FOUND');
    return found;
  };

  async function studentLoyalty(userId: string): Promise<AdminStudentLoyalty> {
    const day = loyaltyDay(now());
    const [balance, earnedToday, ledger, redemptions, unlocked] = await Promise.all([
      repo.balance(db, userId),
      repo.earnedOn(db, userId, day),
      repo.ledger(userId, 100),
      repo.redemptionsOf(userId),
      repo.unlockedDeckIds(userId),
    ]);
    return {
      userId,
      balance,
      earnedToday,
      ledger: ledger.map(toEntry),
      redemptions: redemptions.map(toRedemption),
      unlockedDeckIds: unlocked,
    };
  }

  return {
    getSettings: () => config.getLoyaltySettings(),

    async setSettings(actor: AdminActor, value: LoyaltySettings) {
      const before = await config.getLoyaltySettings();
      const saved = await config.setLoyaltySettings(value, actor.adminId);
      await audit.record({
        actorAdminId: actor.adminId,
        action: 'settings.changed',
        resourceType: 'app_setting',
        resourceId: 'loyalty',
        metadata: { from: before, to: saved },
        ip: actor.ip,
      });
      return saved;
    },

    /** After a review sync: official card reviews that were newly stored (not undone). */
    async awardReviews(userId: string, logs: { id: string; reviewedAt: Date }[]) {
      const rules = await config.getLoyaltySettings();
      if (!rules.enabled) return 0;
      return award(
        userId,
        'review',
        rules.pointsPerReview,
        rules.dailyCap,
        logs.map((l) => ({ refId: l.id, at: l.reviewedAt })),
      );
    },

    /** After a correct question check: once per question per business day. */
    async awardCorrectAnswer(userId: string, questionId: string) {
      const rules = await config.getLoyaltySettings();
      if (!rules.enabled) return 0;
      return award(userId, 'correct_answer', rules.pointsPerCorrectQuestion, rules.dailyCap, [
        { refId: questionId, at: now() },
      ]);
    },

    // ---- student ----

    summary,

    async ledger(userId: string) {
      return { items: (await repo.ledger(userId, 100)).map(toEntry) };
    },

    async rewards(userId: string) {
      const [rows, balance, ctx] = await Promise.all([
        repo.rewards({ activeOnly: true }),
        repo.balance(db, userId),
        access.context(userId),
      ]);
      const decks = new Map<string, Awaited<ReturnType<FlashcardRepository['getDeck']>>>();
      for (const r of rows)
        if (r.reward.deckId && !decks.has(r.reward.deckId))
          decks.set(r.reward.deckId, await flashcardRepo.getDeck(r.reward.deckId));
      const items = rows.flatMap((r) => {
        const deck = r.reward.deckId ? decks.get(r.reward.deckId) : null;
        // A deck reward whose deck is gone or unpublished is not offered.
        if (r.reward.kind === 'unlock_deck' && (!deck || deck.status !== 'published')) return [];
        return [
          {
            id: r.reward.id,
            titleAr: r.reward.titleAr,
            description: r.reward.description,
            costPoints: r.reward.costPoints,
            kind: r.reward.kind,
            deckId: r.reward.deckId,
            deckTitleAr: r.deckTitleAr,
            deckSubjectId: r.deckSubjectId,
            alreadyOwned: deck ? ctx.canAccessDeck(deck) : false,
            affordable: balance >= r.reward.costPoints,
            sortOrder: r.reward.sortOrder,
          },
        ];
      });
      return { balance, items };
    },

    async myRedemptions(userId: string) {
      return (await repo.redemptionsOf(userId)).map(toRedemption);
    },

    /**
     * Spends points on an active reward. `unlock_deck` opens the deck at once (ALREADY_ENTITLED when
     * the student can already open it); `custom` waits for the admin. INSUFFICIENT_POINTS otherwise.
     */
    async redeem(userId: string, rewardId: string) {
      const rules = await config.getLoyaltySettings();
      if (!rules.enabled) throw new AppError('NOT_FOUND');
      const reward = await repo.reward(rewardId);
      if (!reward || !reward.isActive) throw new AppError('NOT_FOUND');
      if (reward.kind === 'unlock_deck') {
        const deck = await flashcardRepo.getDeck(reward.deckId!);
        if (!deck || deck.status !== 'published') throw new AppError('NOT_FOUND');
        if ((await access.context(userId)).canAccessDeck(deck)) throw new AppError('ALREADY_ENTITLED');
      }
      const at = now();
      const redemption = await db.transaction(async (tx) => {
        await repo.lockUser(tx, userId);
        const balance = await repo.balance(tx, userId);
        if (balance < reward.costPoints)
          throw new AppError('INSUFFICIENT_POINTS', { details: { balance, costPoints: reward.costPoints } });
        const row = await repo.insertRedemption(tx, {
          userId,
          rewardId: reward.id,
          titleAr: reward.titleAr,
          kind: reward.kind,
          costPoints: reward.costPoints,
          deckId: reward.deckId,
          status: reward.kind === 'unlock_deck' ? 'fulfilled' : 'pending',
          handledAt: reward.kind === 'unlock_deck' ? at : null,
          createdAt: at,
        });
        await repo.insertEntry(tx, {
          userId,
          delta: -reward.costPoints,
          reason: 'redemption',
          refId: row.id,
          day: loyaltyDay(at),
          createdAt: at,
        });
        if (
          reward.kind === 'unlock_deck' &&
          !(await repo.insertUnlock(tx, {
            userId,
            deckId: reward.deckId!,
            redemptionId: row.id,
            createdAt: at,
          }))
        )
          throw new AppError('ALREADY_ENTITLED');
        return row;
      });
      return { redemption: toRedemption(redemption), balance: await repo.balance(db, userId) };
    },

    // ---- admin ----

    adminRewards,

    async createReward(
      actor: AdminActor,
      input: {
        titleAr: string;
        description?: string | null | undefined;
        costPoints: number;
        kind: RewardRow['kind'];
        deckId?: string | null | undefined;
        isActive?: boolean | undefined;
        sortOrder?: number | undefined;
      },
    ) {
      await assertDeck(input.kind, input.deckId);
      const at = now();
      const row = await repo.insertReward({
        titleAr: input.titleAr,
        description: input.description ?? null,
        costPoints: input.costPoints,
        kind: input.kind,
        deckId: input.kind === 'unlock_deck' ? input.deckId! : null,
        isActive: input.isActive ?? true,
        sortOrder: input.sortOrder ?? 0,
        createdAt: at,
        updatedAt: at,
      });
      await audit.record({
        actorAdminId: actor.adminId,
        action: 'loyalty_reward.created',
        resourceType: 'loyalty_reward',
        resourceId: row.id,
        metadata: { kind: row.kind, costPoints: row.costPoints, deckId: row.deckId },
        ip: actor.ip,
      });
      return adminReward(row.id);
    },

    async updateReward(
      actor: AdminActor,
      id: string,
      patch: Partial<{
        titleAr: string;
        description: string | null | undefined;
        costPoints: number;
        kind: RewardRow['kind'];
        deckId: string | null | undefined;
        isActive: boolean;
        sortOrder: number;
      }>,
    ) {
      const current = await repo.reward(id);
      if (!current) throw new AppError('NOT_FOUND');
      const kind = patch.kind ?? current.kind;
      const deckId = kind === 'custom' ? null : patch.deckId !== undefined ? patch.deckId : current.deckId;
      await assertDeck(kind, deckId);
      await repo.updateReward(id, {
        ...(patch.titleAr !== undefined ? { titleAr: patch.titleAr } : {}),
        ...(patch.description !== undefined ? { description: patch.description } : {}),
        ...(patch.costPoints !== undefined ? { costPoints: patch.costPoints } : {}),
        ...(patch.isActive !== undefined ? { isActive: patch.isActive } : {}),
        ...(patch.sortOrder !== undefined ? { sortOrder: patch.sortOrder } : {}),
        kind,
        deckId,
        updatedAt: now(),
      });
      await audit.record({
        actorAdminId: actor.adminId,
        action: 'loyalty_reward.updated',
        resourceType: 'loyalty_reward',
        resourceId: id,
        metadata: patch,
        ip: actor.ip,
      });
      return adminReward(id);
    },

    /** Soft delete: past redemptions keep pointing at it. */
    async removeReward(actor: AdminActor, id: string) {
      if (!(await repo.reward(id))) throw new AppError('NOT_FOUND');
      await repo.updateReward(id, { deletedAt: now(), isActive: false, updatedAt: now() });
      await audit.record({
        actorAdminId: actor.adminId,
        action: 'loyalty_reward.deleted',
        resourceType: 'loyalty_reward',
        resourceId: id,
        metadata: {},
        ip: actor.ip,
      });
      return { deleted: true as const };
    },

    async redemptions(
      q: { status?: RedemptionRow['status'] | undefined; userId?: string | undefined },
      cursor: string | undefined,
      limit: number,
    ) {
      const page = await repo.redemptionPage(q, cursor, limit);
      return {
        items: page.items.map((r): AdminLoyaltyRedemption => ({
          ...toRedemption(r.redemption),
          userId: r.redemption.userId,
          studentEmail: r.email,
          studentName: r.name,
          handledByAdminId: r.redemption.handledByAdminId,
        })),
        nextCursor: page.nextCursor,
      };
    },

    /** `fulfilled` marks a custom reward handed over; `cancelled` refunds and removes a deck unlock. */
    async setRedemptionStatus(
      actor: AdminActor,
      id: string,
      input: { status: 'fulfilled' | 'cancelled'; note?: string | null | undefined },
    ) {
      const at = now();
      const row = await db.transaction(async (tx) => {
        const current = await repo.redemptionForUpdate(tx, id);
        if (!current) throw new AppError('NOT_FOUND');
        if (current.status === 'cancelled' || current.status === input.status)
          throw new AppError('VALIDATION_ERROR', { details: { field: 'status', reason: current.status } });
        await repo.lockUser(tx, current.userId);
        if (input.status === 'cancelled') {
          await repo.insertEntry(tx, {
            userId: current.userId,
            delta: current.costPoints,
            reason: 'refund',
            refId: current.id,
            day: loyaltyDay(at),
            adminId: actor.adminId,
            note: input.note ?? null,
            createdAt: at,
          });
          await repo.removeUnlockOf(tx, current.id);
        }
        const updated = await repo.updateRedemption(tx, id, {
          status: input.status,
          handledAt: at,
          handledByAdminId: actor.adminId,
          note: input.note ?? current.note,
        });
        await audit.record(
          {
            actorAdminId: actor.adminId,
            action: `loyalty_redemption.${input.status}`,
            resourceType: 'loyalty_redemption',
            resourceId: id,
            metadata: { userId: current.userId, from: current.status, costPoints: current.costPoints },
            ip: actor.ip,
          },
          tx,
        );
        return updated;
      });
      return toRedemption(row);
    },

    async studentLoyalty(userId: string) {
      if (!(await accessRepo.isStudent(userId))) throw new AppError('NOT_FOUND');
      return studentLoyalty(userId);
    },

    /** Manual adjustment with a reason; never takes the balance below zero. Audited. */
    async adjust(actor: AdminActor, userId: string, input: { delta: number; note: string }) {
      if (!(await accessRepo.isStudent(userId))) throw new AppError('NOT_FOUND');
      const at = now();
      await db.transaction(async (tx) => {
        await repo.lockUser(tx, userId);
        const balance = await repo.balance(tx, userId);
        if (balance + input.delta < 0)
          throw new AppError('INSUFFICIENT_POINTS', { details: { balance, delta: input.delta } });
        await repo.insertEntry(tx, {
          userId,
          delta: input.delta,
          reason: 'admin_adjust',
          refId: null,
          day: loyaltyDay(at),
          note: input.note,
          adminId: actor.adminId,
          createdAt: at,
        });
        await audit.record(
          {
            actorAdminId: actor.adminId,
            action: 'loyalty.adjusted',
            resourceType: 'user',
            resourceId: userId,
            metadata: { delta: input.delta, note: input.note, balanceBefore: balance },
            ip: actor.ip,
          },
          tx,
        );
      });
      return studentLoyalty(userId);
    },
  };
}

export type LoyaltyService = ReturnType<typeof createLoyaltyService>;
