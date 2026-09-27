import { and, desc, eq, gt, isNull } from 'drizzle-orm';
import { mobileRefreshTokens, sessions, users, type Db, type Tx } from '@plengo/db';

type Conn = Db | Tx;
export type SessionPlatform = 'android' | 'ios' | 'web' | 'admin';

export function createSessionsRepository(db: Db) {
  return {
    async create(
      input: {
        userId: string;
        token: string;
        platform: SessionPlatform;
        appVersion?: string | null;
        ipHash?: string | null;
        userAgent?: string | null;
        expiresAt: Date;
      },
      conn: Conn = db,
    ) {
      const [row] = await conn
        .insert(sessions)
        .values({
          userId: input.userId,
          token: input.token,
          platform: input.platform,
          appVersion: input.appVersion ?? null,
          ipHash: input.ipHash ?? null,
          userAgent: input.userAgent?.slice(0, 200) ?? null,
          expiresAt: input.expiresAt,
        })
        .returning();
      return row!;
    },

    /** Active (unexpired) session joined with its user; null if expired, revoked or missing. */
    async findActiveWithUser(sessionId: string, now = new Date()) {
      const [row] = await db
        .select({ session: sessions, user: users })
        .from(sessions)
        .innerJoin(users, eq(users.id, sessions.userId))
        .where(and(eq(sessions.id, sessionId), gt(sessions.expiresAt, now)))
        .limit(1);
      return row ?? null;
    },

    async findIdByToken(token: string): Promise<string | null> {
      const [row] = await db
        .select({ id: sessions.id })
        .from(sessions)
        .where(eq(sessions.token, token))
        .limit(1);
      return row?.id ?? null;
    },

    async touch(sessionId: string, now = new Date()) {
      await db.update(sessions).set({ lastSeenAt: now }).where(eq(sessions.id, sessionId));
    },

    async annotate(
      sessionId: string,
      fields: { platform?: SessionPlatform; ipHash?: string | null; appVersion?: string | null },
    ) {
      await db.update(sessions).set(fields).where(eq(sessions.id, sessionId));
    },

    async extend(sessionId: string, expiresAt: Date, conn: Conn = db) {
      await conn
        .update(sessions)
        .set({ expiresAt, lastSeenAt: new Date(), updatedAt: new Date() })
        .where(eq(sessions.id, sessionId));
    },

    async listActive(userId: string, now = new Date()) {
      return db
        .select()
        .from(sessions)
        .where(and(eq(sessions.userId, userId), gt(sessions.expiresAt, now)))
        .orderBy(desc(sessions.lastSeenAt));
    },

    /**
     * Revoke a session of any platform: expire the row (cookie sessions stop validating) and revoke
     * any mobile refresh tokens bound to it. Rows are kept for diagnostics.
     */
    async revoke(sessionId: string, conn: Conn = db, now = new Date()) {
      await conn.update(sessions).set({ expiresAt: now, updatedAt: now }).where(eq(sessions.id, sessionId));
      await conn
        .update(mobileRefreshTokens)
        .set({ revokedAt: now })
        .where(and(eq(mobileRefreshTokens.sessionId, sessionId), isNull(mobileRefreshTokens.revokedAt)));
    },

    async revokeAllForUser(userId: string, now = new Date()) {
      await db.transaction(async (tx) => {
        await tx
          .update(sessions)
          .set({ expiresAt: now, updatedAt: now })
          .where(and(eq(sessions.userId, userId), gt(sessions.expiresAt, now)));
        await tx
          .update(mobileRefreshTokens)
          .set({ revokedAt: now })
          .where(and(eq(mobileRefreshTokens.userId, userId), isNull(mobileRefreshTokens.revokedAt)));
      });
    },
  };
}

export type SessionsRepository = ReturnType<typeof createSessionsRepository>;
