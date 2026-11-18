import { and, asc, count, desc, eq, inArray, isNull, sql } from 'drizzle-orm';
import {
  flashcardDecks,
  loyaltyLedger,
  loyaltyRedemptions,
  loyaltyRewards,
  profiles,
  studentDeckUnlocks,
  users,
  type Db,
  type Tx,
} from '@plengo/db';
import { decodeCursor, encodeCursor } from './question-repository.js';

type Conn = Db | Tx;
export type LedgerRow = typeof loyaltyLedger.$inferSelect;
export type RewardRow = typeof loyaltyRewards.$inferSelect;
export type RedemptionRow = typeof loyaltyRedemptions.$inferSelect;

/** Reasons that count toward the daily cap. */
const EARNING = sql`${loyaltyLedger.reason} in ('review', 'correct_answer')`;
const liveReward = isNull(loyaltyRewards.deletedAt);

export function createLoyaltyRepository(db: Db) {
  return {
    /** Serialises a student's point changes (cap and balance checks) inside the caller's transaction. */
    async lockUser(tx: Tx, userId: string) {
      await tx.execute(sql`select pg_advisory_xact_lock(hashtext(${`loyalty:${userId}`}))`);
    },

    async balance(conn: Conn, userId: string) {
      const [row] = await conn
        .select({ n: sql<number>`coalesce(sum(${loyaltyLedger.delta}), 0)::int` })
        .from(loyaltyLedger)
        .where(eq(loyaltyLedger.userId, userId));
      return row?.n ?? 0;
    },

    async earnedOn(conn: Conn, userId: string, day: string) {
      const [row] = await conn
        .select({ n: sql<number>`coalesce(sum(${loyaltyLedger.delta}), 0)::int` })
        .from(loyaltyLedger)
        .where(and(eq(loyaltyLedger.userId, userId), eq(loyaltyLedger.day, day), EARNING));
      return row?.n ?? 0;
    },

    /** Inserts once per (user, reason, ref, day); returns whether a row was written. */
    async insertEntry(conn: Conn, values: typeof loyaltyLedger.$inferInsert) {
      const rows = await conn
        .insert(loyaltyLedger)
        .values(values)
        .onConflictDoNothing()
        .returning({ id: loyaltyLedger.id });
      return rows.length > 0;
    },

    /** Which of these refs already earned on that day (dedupe before applying the cap). */
    async existingRefs(conn: Conn, userId: string, reason: LedgerRow['reason'], day: string, refs: string[]) {
      if (!refs.length) return new Set<string>();
      const rows = await conn
        .select({ refId: loyaltyLedger.refId })
        .from(loyaltyLedger)
        .where(
          and(
            eq(loyaltyLedger.userId, userId),
            eq(loyaltyLedger.reason, reason),
            eq(loyaltyLedger.day, day),
            inArray(loyaltyLedger.refId, refs),
          ),
        );
      return new Set(rows.map((r) => r.refId!));
    },

    ledger: (userId: string, limit: number) =>
      db
        .select()
        .from(loyaltyLedger)
        .where(eq(loyaltyLedger.userId, userId))
        .orderBy(desc(loyaltyLedger.createdAt), desc(loyaltyLedger.id))
        .limit(limit),

    // ---- rewards ----

    async rewards(opts: { activeOnly: boolean }) {
      return db
        .select({
          reward: loyaltyRewards,
          deckTitleAr: flashcardDecks.titleAr,
          deckSubjectId: flashcardDecks.subjectId,
          redemptionCount: sql<number>`(select count(*)::int from loyalty_redemptions r where r.reward_id = ${loyaltyRewards.id} and r.status <> 'cancelled')`,
        })
        .from(loyaltyRewards)
        .leftJoin(flashcardDecks, eq(flashcardDecks.id, loyaltyRewards.deckId))
        .where(and(liveReward, opts.activeOnly ? eq(loyaltyRewards.isActive, true) : undefined))
        .orderBy(
          asc(loyaltyRewards.sortOrder),
          asc(loyaltyRewards.costPoints),
          asc(loyaltyRewards.createdAt),
        );
    },

    async reward(id: string, conn: Conn = db) {
      const [row] = await conn
        .select()
        .from(loyaltyRewards)
        .where(and(eq(loyaltyRewards.id, id), liveReward));
      return row ?? null;
    },

    async insertReward(values: typeof loyaltyRewards.$inferInsert) {
      const [row] = await db.insert(loyaltyRewards).values(values).returning();
      return row!;
    },

    async updateReward(id: string, values: Partial<typeof loyaltyRewards.$inferInsert>) {
      await db.update(loyaltyRewards).set(values).where(eq(loyaltyRewards.id, id));
    },

    // ---- redemptions ----

    async insertRedemption(tx: Tx, values: typeof loyaltyRedemptions.$inferInsert) {
      const [row] = await tx.insert(loyaltyRedemptions).values(values).returning();
      return row!;
    },

    async redemptionForUpdate(tx: Tx, id: string) {
      const [row] = await tx
        .select()
        .from(loyaltyRedemptions)
        .where(eq(loyaltyRedemptions.id, id))
        .for('update');
      return row ?? null;
    },

    async updateRedemption(tx: Tx, id: string, values: Partial<typeof loyaltyRedemptions.$inferInsert>) {
      const [row] = await tx
        .update(loyaltyRedemptions)
        .set(values)
        .where(eq(loyaltyRedemptions.id, id))
        .returning();
      return row!;
    },

    redemptionsOf: (userId: string, limit = 100) =>
      db
        .select()
        .from(loyaltyRedemptions)
        .where(eq(loyaltyRedemptions.userId, userId))
        .orderBy(desc(loyaltyRedemptions.createdAt))
        .limit(limit),

    async redemptionPage(
      f: { status?: RedemptionRow['status'] | undefined; userId?: string | undefined },
      cursor: string | undefined,
      limit: number,
    ) {
      const offset = decodeCursor(cursor);
      const rows = await db
        .select({
          redemption: loyaltyRedemptions,
          email: users.email,
          name: sql<string | null>`coalesce(${profiles.fullName}, ${users.name})`,
        })
        .from(loyaltyRedemptions)
        .innerJoin(users, eq(users.id, loyaltyRedemptions.userId))
        .leftJoin(profiles, eq(profiles.userId, users.id))
        .where(
          and(
            f.status ? eq(loyaltyRedemptions.status, f.status) : undefined,
            f.userId ? eq(loyaltyRedemptions.userId, f.userId) : undefined,
          ),
        )
        .orderBy(desc(loyaltyRedemptions.createdAt), desc(loyaltyRedemptions.id))
        .limit(limit + 1)
        .offset(offset);
      return {
        items: rows.slice(0, limit),
        nextCursor: rows.length > limit ? encodeCursor(offset + limit) : null,
      };
    },

    async rewardRedemptionCount(rewardId: string) {
      const [row] = await db
        .select({ n: count() })
        .from(loyaltyRedemptions)
        .where(eq(loyaltyRedemptions.rewardId, rewardId));
      return row?.n ?? 0;
    },

    // ---- deck unlocks ----

    async insertUnlock(tx: Tx, values: typeof studentDeckUnlocks.$inferInsert) {
      const rows = await tx.insert(studentDeckUnlocks).values(values).onConflictDoNothing().returning();
      return rows.length > 0;
    },

    async removeUnlockOf(tx: Tx, redemptionId: string) {
      await tx.delete(studentDeckUnlocks).where(eq(studentDeckUnlocks.redemptionId, redemptionId));
    },

    async unlockedDeckIds(userId: string) {
      const rows = await db
        .select({ deckId: studentDeckUnlocks.deckId })
        .from(studentDeckUnlocks)
        .where(eq(studentDeckUnlocks.userId, userId));
      return rows.map((r) => r.deckId);
    },
  };
}

export type LoyaltyRepository = ReturnType<typeof createLoyaltyRepository>;
