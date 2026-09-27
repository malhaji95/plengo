import type { FastifyReply, FastifyRequest } from 'fastify';
import type { Auth } from '../auth/better-auth.js';
import { AppError } from '../lib/app-error.js';
import type { SessionsRepository } from '../repositories/sessions-repository.js';
import type { MobileTokenService } from '../services/mobile-token-service.js';

export const ADMIN_IDLE_TIMEOUT_MS = 12 * 3600 * 1000;
const TOUCH_INTERVAL_MS = 60 * 1000;

export interface AuthContext {
  userId: string;
  sessionId: string;
  role: 'student' | 'admin';
  via: 'bearer' | 'cookie';
  twoFactorEnabled: boolean;
}

declare module 'fastify' {
  interface FastifyRequest {
    auth: AuthContext | null;
  }
}

export function bearerToken(request: FastifyRequest): string | null {
  const header = request.headers.authorization;
  if (!header?.startsWith('Bearer ')) return null;
  return header.slice(7).trim() || null;
}

export function toFetchHeaders(request: FastifyRequest): Headers {
  const headers = new Headers();
  for (const [k, v] of Object.entries(request.headers)) {
    if (Array.isArray(v)) v.forEach((item) => headers.append(k, item));
    else if (v !== undefined) headers.set(k, String(v));
  }
  return headers;
}

/**
 * The only way routes establish identity (spec §8.6). Bearer = mobile access JWT, otherwise the
 * Better Auth cookie session (student web, admin).
 */
export function createGuards(deps: {
  auth: Auth;
  sessionsRepo: SessionsRepository;
  mobileTokens: MobileTokenService;
  now?: () => Date;
}) {
  const { auth, sessionsRepo, mobileTokens } = deps;
  const now = deps.now ?? (() => new Date());

  async function resolve(request: FastifyRequest): Promise<AuthContext | null> {
    if (request.auth) return request.auth;

    const bearer = bearerToken(request);
    let sessionId: string;
    let via: AuthContext['via'];
    if (bearer) {
      const claims = await mobileTokens.verifyAccessToken(bearer);
      if (!claims) throw new AppError('AUTH_SESSION_EXPIRED');
      sessionId = claims.sessionId;
      via = 'bearer';
    } else {
      if (!request.headers.cookie) return null;
      const session = await auth.api.getSession({ headers: toFetchHeaders(request) });
      if (!session) return null;
      sessionId = session.session.id;
      via = 'cookie';
    }

    const at = now();
    const row = await sessionsRepo.findActiveWithUser(sessionId, at);
    if (!row || row.user.status !== 'active') throw new AppError('AUTH_SESSION_EXPIRED');
    const isMobileSession = row.session.platform === 'android' || row.session.platform === 'ios';
    if ((via === 'bearer') !== isMobileSession) throw new AppError('AUTH_SESSION_EXPIRED');

    if (row.user.role === 'admin') {
      if (via !== 'cookie') throw new AppError('NOT_AUTHORIZED');
      if (at.getTime() - row.session.lastSeenAt.getTime() > ADMIN_IDLE_TIMEOUT_MS) {
        await sessionsRepo.revoke(row.session.id, undefined, at);
        throw new AppError('AUTH_SESSION_EXPIRED');
      }
    }
    if (at.getTime() - row.session.lastSeenAt.getTime() > TOUCH_INTERVAL_MS) {
      await sessionsRepo.touch(row.session.id, at);
    }

    request.auth = {
      userId: row.user.id,
      sessionId: row.session.id,
      role: row.user.role,
      via,
      twoFactorEnabled: row.user.twoFactorEnabled,
    };
    return request.auth;
  }

  return {
    resolve,

    /** Any signed-in student. */
    async requireUser(request: FastifyRequest, _reply: FastifyReply) {
      const ctx = await resolve(request);
      if (!ctx) throw new AppError('UNAUTHENTICATED');
      if (ctx.role !== 'student') throw new AppError('NOT_AUTHORIZED');
    },

    /** Admin with a 2FA-verified cookie session (spec §0.3, §11.3). */
    async requireAdmin(request: FastifyRequest, _reply: FastifyReply) {
      const ctx = await resolve(request);
      if (!ctx) throw new AppError('UNAUTHENTICATED');
      if (ctx.role !== 'admin') throw new AppError('NOT_AUTHORIZED');
      if (!ctx.twoFactorEnabled) throw new AppError('AUTH_2FA_REQUIRED');
    },

    /** Admin session that has passed the password step but may still need to enroll in 2FA. */
    async requireAdminEnrolling(request: FastifyRequest, _reply: FastifyReply) {
      const ctx = await resolve(request);
      if (!ctx) throw new AppError('UNAUTHENTICATED');
      if (ctx.role !== 'admin') throw new AppError('NOT_AUTHORIZED');
    },
  };
}

export type Guards = ReturnType<typeof createGuards>;

export function authOf(request: FastifyRequest): AuthContext {
  if (!request.auth) throw new AppError('UNAUTHENTICATED');
  return request.auth;
}
