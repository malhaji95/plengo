import { and, desc, eq, sql } from 'drizzle-orm';
import type { AdminAccount } from '@plengo/contracts';
import { adminTwoFactor, profiles, sessions, users, type Db } from '@plengo/db';
import type { Auth } from '../auth/better-auth.js';
import { AppError } from '../lib/app-error.js';
import type { SessionsRepository } from '../repositories/sessions-repository.js';
import type { UsersRepository } from '../repositories/users-repository.js';
import type { AuditService } from './audit-service.js';
import { mapAuthError } from './auth-service.js';
import type { AdminActor } from './structure-service.js';

/**
 * Admin accounts (spec §11.3, §26.2): created only by other admins, deactivated and reactivated,
 * with a 2FA reset by another admin. The last active admin cannot be deactivated. All audited.
 */
export function createAdminService(deps: {
  db: Db;
  auth: Auth;
  usersRepo: UsersRepository;
  sessionsRepo: SessionsRepository;
  audit: AuditService;
}) {
  const { db, auth, usersRepo, sessionsRepo, audit } = deps;

  const record = (actor: AdminActor, action: string, id: string, metadata: Record<string, unknown> = {}) =>
    audit.record({
      actorAdminId: actor.adminId,
      action,
      resourceType: 'admin',
      resourceId: id,
      metadata,
      ip: actor.ip,
    });

  async function list(): Promise<AdminAccount[]> {
    const lastSeen = sql<Date | null>`(select max(s.last_seen_at) from sessions s where s.user_id = "users"."id")`;
    const rows = await db
      .select({ u: users, fullName: profiles.fullName, lastSeen })
      .from(users)
      .leftJoin(profiles, eq(profiles.userId, users.id))
      .where(eq(users.role, 'admin'))
      .orderBy(desc(users.createdAt));
    return rows.map((r) => ({
      id: r.u.id,
      email: r.u.email,
      fullName: r.fullName ?? r.u.name,
      status: r.u.status,
      twoFactorEnabled: r.u.twoFactorEnabled,
      createdAt: r.u.createdAt.toISOString(),
      lastSeenAt: r.lastSeen ? new Date(r.lastSeen).toISOString() : null,
    }));
  }

  async function get(id: string) {
    const account = (await list()).find((a) => a.id === id);
    if (!account) throw new AppError('NOT_FOUND');
    return account;
  }

  return {
    list,

    async create(actor: AdminActor, input: { email: string; fullName: string; password: string }) {
      if (await usersRepo.findByEmail(input.email)) throw new AppError('AUTH_EMAIL_TAKEN');
      let userId: string;
      try {
        const res = await auth.api.signUpEmail({
          body: { name: input.fullName, email: input.email, password: input.password },
        });
        userId = res.user.id;
      } catch (err) {
        mapAuthError(err, 'VALIDATION_ERROR');
      }
      await usersRepo.setRoleAndVerified(userId, 'admin', true);
      await usersRepo.upsertProfile({ userId, fullName: input.fullName });
      await record(actor, 'admin.created', userId, { email: input.email });
      return get(userId);
    },

    /** Disables the account and ends its sessions. Refused for the last active admin. */
    async deactivate(actor: AdminActor, id: string) {
      await db.transaction(async (tx) => {
        // Lock every active admin so two admins cannot deactivate each other at the same time.
        const active = await tx
          .select({ id: users.id })
          .from(users)
          .where(and(eq(users.role, 'admin'), eq(users.status, 'active')))
          .for('update');
        const [target] = await tx
          .select()
          .from(users)
          .where(and(eq(users.id, id), eq(users.role, 'admin')));
        if (!target) throw new AppError('NOT_FOUND');
        if (target.status !== 'active') return;
        if (active.length <= 1) {
          throw new AppError('VALIDATION_ERROR', { details: { field: 'id', reason: 'last_active_admin' } });
        }
        await tx.update(users).set({ status: 'disabled', updatedAt: new Date() }).where(eq(users.id, id));
      });
      await sessionsRepo.revokeAllForUser(id);
      await record(actor, 'admin.deactivated', id);
      return get(id);
    },

    async reactivate(actor: AdminActor, id: string) {
      const [target] = await db
        .select()
        .from(users)
        .where(and(eq(users.id, id), eq(users.role, 'admin')));
      if (!target) throw new AppError('NOT_FOUND');
      if (target.status !== 'active') {
        await db.update(users).set({ status: 'active', updatedAt: new Date() }).where(eq(users.id, id));
        await record(actor, 'admin.reactivated', id);
      }
      return get(id);
    },

    /**
     * Another admin clears the TOTP secret and recovery codes; the admin enrolls again at next
     * login. Their sessions end. An admin cannot reset their own 2FA.
     */
    async resetTwoFactor(actor: AdminActor, id: string) {
      if (id === actor.adminId) throw new AppError('NOT_AUTHORIZED');
      const [target] = await db
        .select()
        .from(users)
        .where(and(eq(users.id, id), eq(users.role, 'admin')));
      if (!target) throw new AppError('NOT_FOUND');
      await db.transaction(async (tx) => {
        await tx.delete(adminTwoFactor).where(eq(adminTwoFactor.userId, id));
        await tx
          .update(users)
          .set({ twoFactorEnabled: false, updatedAt: new Date() })
          .where(eq(users.id, id));
      });
      await sessionsRepo.revokeAllForUser(id);
      await record(actor, 'admin.2fa_reset', id);
      return get(id);
    },

    /** A student's active sessions, for the admin student page (§26.2). */
    async studentSessions(studentId: string) {
      await assertStudent(studentId);
      return (await sessionsRepo.listActive(studentId)).map((s) => ({
        id: s.id,
        platform: s.platform,
        appVersion: s.appVersion,
        userAgent: s.userAgent,
        createdAt: s.createdAt.toISOString(),
        lastSeenAt: s.lastSeenAt.toISOString(),
        current: false,
      }));
    },

    async revokeStudentSession(actor: AdminActor, studentId: string, sessionId: string) {
      await assertStudent(studentId);
      const [row] = await db
        .select({ id: sessions.id })
        .from(sessions)
        .where(and(eq(sessions.id, sessionId), eq(sessions.userId, studentId)));
      if (!row) throw new AppError('NOT_FOUND');
      await sessionsRepo.revoke(sessionId);
      await audit.record({
        actorAdminId: actor.adminId,
        action: 'session.revoked_by_admin',
        resourceType: 'student',
        resourceId: studentId,
        metadata: { sessionId },
        ip: actor.ip,
      });
      return { revoked: true };
    },
  };

  async function assertStudent(id: string) {
    const [u] = await db.select({ role: users.role }).from(users).where(eq(users.id, id));
    if (!u || u.role !== 'student') throw new AppError('NOT_FOUND');
  }
}

export type AdminService = ReturnType<typeof createAdminService>;
