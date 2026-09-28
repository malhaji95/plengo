import { and, eq, ilike, isNull, or } from 'drizzle-orm';
import {
  accounts,
  bookmarks,
  entitlements,
  mediaFiles,
  mobileRefreshTokens,
  offlineLeases,
  profiles,
  pushTokens,
  sessions,
  teacherFollowers,
  userDecks,
  userNotifications,
  users,
  verificationCodes,
  type Tx,
} from '@plengo/db';

/** The writes of an account deletion (spec §33), all inside the caller's transaction. */
export function createAccountRepository() {
  return {
    /** The account's own media (avatar, student card images), to delete with their objects. */
    ownedMedia: (tx: Tx, userId: string) =>
      tx.select().from(mediaFiles).where(eq(mediaFiles.ownerUserId, userId)),

    async erase(tx: Tx, userId: string, email: string, at: Date) {
      // Personal data and access.
      await tx.delete(sessions).where(eq(sessions.userId, userId));
      await tx.delete(mobileRefreshTokens).where(eq(mobileRefreshTokens.userId, userId));
      await tx.delete(accounts).where(eq(accounts.userId, userId));
      await tx.delete(pushTokens).where(eq(pushTokens.userId, userId));
      await tx
        .delete(verificationCodes)
        .where(
          or(eq(verificationCodes.identifier, email), ilike(verificationCodes.identifier, `%${email}%`)),
        );
      await tx.delete(userNotifications).where(eq(userNotifications.userId, userId));
      await tx.delete(bookmarks).where(eq(bookmarks.userId, userId));
      await tx.delete(teacherFollowers).where(eq(teacherFollowers.userId, userId));
      // Student decks and their cards (cascade); their images are deleted by the caller.
      await tx.delete(userDecks).where(eq(userDecks.userId, userId));
      await tx
        .update(entitlements)
        .set({ status: 'revoked', revokedAt: at, revokeReason: 'account_deleted' })
        .where(and(eq(entitlements.userId, userId), eq(entitlements.status, 'active')));
      await tx
        .update(offlineLeases)
        .set({ revokedAt: at })
        .where(and(eq(offlineLeases.userId, userId), isNull(offlineLeases.revokedAt)));
      await tx
        .update(profiles)
        .set({
          fullName: 'حساب محذوف',
          avatarMediaId: null,
          universityId: null,
          facultyId: null,
          academicYearId: null,
          notifyLearning: false,
          notifyPromotions: false,
          updatedAt: at,
        })
        .where(eq(profiles.userId, userId));
      // The row stays as an anonymous tombstone: attempts, reviews and redemptions keep pointing at
      // it for aggregate statistics, and redeemed codes stay consumed.
      await tx
        .update(users)
        .set({
          name: 'حساب محذوف',
          email: `deleted-${userId}@deleted.invalid`,
          emailVerified: false,
          image: null,
          twoFactorEnabled: false,
          status: 'deleted',
          deletedAt: at,
          updatedAt: at,
        })
        .where(eq(users.id, userId));
    },

    deleteMedia: (tx: Tx, id: string) => tx.delete(mediaFiles).where(eq(mediaFiles.id, id)),
  };
}

export type AccountRepository = ReturnType<typeof createAccountRepository>;
