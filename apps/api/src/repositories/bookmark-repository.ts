import { and, desc, eq } from 'drizzle-orm';
import { bookmarks, type Db } from '@plengo/db';

export type BookmarkRow = typeof bookmarks.$inferSelect;
type BookmarkType = BookmarkRow['itemType'];

const key = (userId: string, itemType: BookmarkType, itemId: string) =>
  and(eq(bookmarks.userId, userId), eq(bookmarks.itemType, itemType), eq(bookmarks.itemId, itemId));

/** Saved items (§17), unique per (user, item type, item id). */
export function createBookmarkRepository(db: Db) {
  return {
    /** Newest first, optionally of one item type. */
    list: (userId: string, itemType: BookmarkType | undefined, limit: number, offset = 0) =>
      db
        .select()
        .from(bookmarks)
        .where(and(eq(bookmarks.userId, userId), itemType ? eq(bookmarks.itemType, itemType) : undefined))
        .orderBy(desc(bookmarks.createdAt), desc(bookmarks.id))
        .limit(limit)
        .offset(offset),

    keys: (userId: string) =>
      db
        .select({ itemType: bookmarks.itemType, itemId: bookmarks.itemId })
        .from(bookmarks)
        .where(eq(bookmarks.userId, userId)),

    /** Idempotent: returns the stored row whether or not this call inserted it. */
    async add(userId: string, itemType: BookmarkType, itemId: string) {
      await db.insert(bookmarks).values({ userId, itemType, itemId }).onConflictDoNothing();
      const [row] = await db
        .select()
        .from(bookmarks)
        .where(key(userId, itemType, itemId));
      return row!;
    },

    async remove(userId: string, itemType: BookmarkType, itemId: string) {
      await db.delete(bookmarks).where(key(userId, itemType, itemId));
    },
  };
}

export type BookmarkRepository = ReturnType<typeof createBookmarkRepository>;
