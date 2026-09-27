import { randomUUID } from 'node:crypto';
import { and, eq, gt } from 'drizzle-orm';
import { jwtVerify, SignJWT } from 'jose';
import { mobileRefreshTokens, sessions, type Db } from '@plengo/db';
import type { TokenPair } from '@plengo/contracts';
import { AppError } from '../lib/app-error.js';
import { hmacHex, randomToken } from '../lib/crypto.js';
import type { SessionsRepository } from '../repositories/sessions-repository.js';

export const ACCESS_TOKEN_TTL_SECONDS = 15 * 60;
export const REFRESH_TOKEN_TTL_SECONDS = 30 * 24 * 3600;
export const REFRESH_RETRY_GRACE_SECONDS = 30;
/** Bounds how many extra successors one rotated token can mint inside its grace window. */
export const MAX_GRACE_REISSUES = 5;

const ISSUER = 'plengo-api';
const AUDIENCE = 'plengo-mobile';

export interface AccessClaims {
  userId: string;
  sessionId: string;
}

/**
 * First-party mobile token pair (spec §2.3, §11.2): 15-minute HS256 access JWT + opaque 256-bit
 * refresh token stored only as an HMAC. Rotation on every refresh; a rotated token presented again
 * within the 30 s grace window mints a sibling successor (concurrent/retried refresh), outside it
 * the whole family is revoked (ADR-004).
 */
export function createMobileTokenService(deps: {
  db: Db;
  sessionsRepo: SessionsRepository;
  accessSecret: string;
  refreshPepper: string;
  now?: () => Date;
}) {
  const { db, sessionsRepo } = deps;
  const now = deps.now ?? (() => new Date());
  const key = new TextEncoder().encode(deps.accessSecret);
  const hashToken = (raw: string) => hmacHex(deps.refreshPepper, raw);

  async function signAccess(userId: string, sessionId: string, issuedAt: Date) {
    const exp = new Date(issuedAt.getTime() + ACCESS_TOKEN_TTL_SECONDS * 1000);
    const token = await new SignJWT({ sid: sessionId, typ: 'access' })
      .setProtectedHeader({ alg: 'HS256' })
      .setSubject(userId)
      .setIssuer(ISSUER)
      .setAudience(AUDIENCE)
      .setIssuedAt(Math.floor(issuedAt.getTime() / 1000))
      .setExpirationTime(Math.floor(exp.getTime() / 1000))
      .setJti(randomUUID())
      .sign(key);
    return { token, exp };
  }

  function newRefresh(issuedAt: Date) {
    const raw = randomToken(32);
    return {
      raw,
      hash: hashToken(raw),
      expiresAt: new Date(issuedAt.getTime() + REFRESH_TOKEN_TTL_SECONDS * 1000),
    };
  }

  async function pair(userId: string, sessionId: string, refreshRaw: string, refreshExp: Date, at: Date) {
    const access = await signAccess(userId, sessionId, at);
    return {
      accessToken: access.token,
      accessTokenExpiresAt: access.exp.toISOString(),
      refreshToken: refreshRaw,
      refreshTokenExpiresAt: refreshExp.toISOString(),
    } satisfies TokenPair;
  }

  return {
    async issueForLogin(input: {
      userId: string;
      platform: 'android' | 'ios';
      appVersion?: string | null;
      ipHash?: string | null;
      userAgent?: string | null;
    }): Promise<TokenPair> {
      const at = now();
      const refresh = newRefresh(at);
      const session = await db.transaction(async (tx) => {
        const s = await sessionsRepo.create(
          {
            userId: input.userId,
            // Opaque placeholder; mobile sessions are never looked up by this token.
            token: `mobile_${randomToken(24)}`,
            platform: input.platform,
            appVersion: input.appVersion,
            ipHash: input.ipHash,
            userAgent: input.userAgent,
            expiresAt: refresh.expiresAt,
          },
          tx,
        );
        await tx.insert(mobileRefreshTokens).values({
          userId: input.userId,
          sessionId: s.id,
          sessionFamilyId: randomUUID(),
          tokenHash: refresh.hash,
          expiresAt: refresh.expiresAt,
        });
        return s;
      });
      return pair(input.userId, session.id, refresh.raw, refresh.expiresAt, at);
    },

    async refresh(rawToken: string): Promise<TokenPair> {
      const at = now();
      const hash = hashToken(rawToken);

      const outcome = await db.transaction(async (tx) => {
        const [row] = await tx
          .select()
          .from(mobileRefreshTokens)
          .where(eq(mobileRefreshTokens.tokenHash, hash))
          .for('update')
          .limit(1);
        if (!row || row.revokedAt || row.expiresAt <= at) return { kind: 'invalid' as const };

        const [session] = await tx
          .select({ id: sessions.id })
          .from(sessions)
          .where(and(eq(sessions.id, row.sessionId), gt(sessions.expiresAt, at)))
          .limit(1);
        if (!session) return { kind: 'invalid' as const };

        const alreadyRotated = row.replacedById !== null;
        const inGrace =
          alreadyRotated &&
          row.retryGraceExpiresAt !== null &&
          at <= row.retryGraceExpiresAt &&
          row.graceReissueCount < MAX_GRACE_REISSUES;

        if (alreadyRotated && !inGrace) {
          // Replay of a rotated token: revoke the whole family (spec §2.3).
          await sessionsRepo.revoke(row.sessionId, tx, at);
          return { kind: 'replay' as const };
        }

        const next = newRefresh(at);
        const [inserted] = await tx
          .insert(mobileRefreshTokens)
          .values({
            userId: row.userId,
            sessionId: row.sessionId,
            sessionFamilyId: row.sessionFamilyId,
            tokenHash: next.hash,
            previousTokenHash: row.tokenHash,
            expiresAt: next.expiresAt,
          })
          .returning({ id: mobileRefreshTokens.id });

        await tx
          .update(mobileRefreshTokens)
          .set(
            alreadyRotated
              ? { graceReissueCount: row.graceReissueCount + 1, lastUsedAt: at }
              : {
                  replacedById: inserted!.id,
                  retryGraceExpiresAt: new Date(at.getTime() + REFRESH_RETRY_GRACE_SECONDS * 1000),
                  lastUsedAt: at,
                },
          )
          .where(eq(mobileRefreshTokens.id, row.id));
        await sessionsRepo.extend(row.sessionId, next.expiresAt, tx);

        return { kind: 'ok' as const, userId: row.userId, sessionId: row.sessionId, next };
      });

      if (outcome.kind !== 'ok') throw new AppError('AUTH_SESSION_EXPIRED');
      return pair(outcome.userId, outcome.sessionId, outcome.next.raw, outcome.next.expiresAt, at);
    },

    /** Revokes the session the token belongs to. Unknown tokens are ignored (idempotent logout). */
    async logout(rawToken: string): Promise<void> {
      const [row] = await db
        .select({ sessionId: mobileRefreshTokens.sessionId })
        .from(mobileRefreshTokens)
        .where(eq(mobileRefreshTokens.tokenHash, hashToken(rawToken)))
        .limit(1);
      if (row) await db.transaction((tx) => sessionsRepo.revoke(row.sessionId, tx, now()));
    },

    /** Signature/expiry check only; callers must still confirm the session is active. */
    async verifyAccessToken(token: string): Promise<AccessClaims | null> {
      try {
        const { payload } = await jwtVerify(token, key, {
          issuer: ISSUER,
          audience: AUDIENCE,
          algorithms: ['HS256'],
          currentDate: now(),
        });
        if (payload.typ !== 'access' || typeof payload.sub !== 'string' || typeof payload.sid !== 'string') {
          return null;
        }
        return { userId: payload.sub, sessionId: payload.sid };
      } catch {
        return null;
      }
    },
  };
}

export type MobileTokenService = ReturnType<typeof createMobileTokenService>;
