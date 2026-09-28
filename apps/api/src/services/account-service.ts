import type { FastifyBaseLogger } from 'fastify';
import type { Db } from '@plengo/db';
import { AppError } from '../lib/app-error.js';
import type { AccountRepository } from '../repositories/account-repository.js';
import type { UsersRepository } from '../repositories/users-repository.js';
import type { ObjectStorage } from '../storage/storage.js';
import type { AuditService } from './audit-service.js';

/**
 * Account deletion (spec §33), from the app or by an admin. Personal data, sessions, push tokens,
 * entitlements, bookmarks, student decks and their images go; learning history stays for aggregate
 * statistics, attached to an anonymous tombstone row with no name, email or avatar.
 */
export function createAccountService(deps: {
  db: Db;
  repo: AccountRepository;
  usersRepo: UsersRepository;
  storage: ObjectStorage;
  audit: AuditService;
  verifyPassword: (email: string, password: string) => Promise<boolean>;
  log?: FastifyBaseLogger | undefined;
  now?: (() => Date) | undefined;
}) {
  const { db, repo, usersRepo, storage, audit, log } = deps;
  const now = deps.now ?? (() => new Date());

  async function erase(userId: string, actorAdminId: string | null, ip: string | null) {
    const user = await usersRepo.findById(userId);
    if (!user || user.role !== 'student' || user.status === 'deleted') throw new AppError('NOT_FOUND');
    const at = now();
    const media = await db.transaction(async (tx) => {
      const owned = await repo.ownedMedia(tx, userId);
      await repo.erase(tx, userId, user.email, at);
      for (const m of owned) await repo.deleteMedia(tx, m.id);
      await audit.record(
        {
          actorAdminId,
          action: actorAdminId ? 'account.deleted_by_admin' : 'account.deleted',
          resourceType: 'user',
          resourceId: userId,
          metadata: { media: owned.length },
          ip,
        },
        tx,
      );
      return owned;
    });
    // Objects go after the commit; a failure only leaves an unreachable object behind.
    for (const m of media) {
      const keys: ['private' | 'public', string][] = [
        ['private', m.storageKey],
        ...Object.values(m.variants ?? {}).map((v) => [m.bucket, v.key] as ['private' | 'public', string]),
      ];
      for (const [bucket, key] of keys) {
        await storage
          .delete(bucket, key)
          .catch((err: unknown) => log?.warn({ err, key }, 'account deletion: object not deleted'));
      }
    }
    return { deleted: true };
  }

  return {
    /** The student deletes their own account; the password confirms it. */
    async deleteOwn(
      userId: string,
      password: string,
      ip: string | null,
      /** Runs after the password check and before erasing (the web signs its cookie out). */
      beforeErase?: () => Promise<unknown>,
    ) {
      const user = await usersRepo.findById(userId);
      if (!user) throw new AppError('NOT_FOUND');
      if (!(await deps.verifyPassword(user.email, password))) throw new AppError('AUTH_INVALID_CREDENTIALS');
      await beforeErase?.();
      return erase(userId, null, ip);
    },

    /** An admin deletes a student's account (e.g. a request by email). Audited. */
    deleteByAdmin: (actor: { adminId: string; ip: string | null }, userId: string) =>
      erase(userId, actor.adminId, actor.ip),
  };
}

export type AccountService = ReturnType<typeof createAccountService>;
