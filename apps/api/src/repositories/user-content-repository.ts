import { and, asc, count, eq, gt, inArray, isNull, sql } from 'drizzle-orm';
import { mediaFiles, userCards, userDecks, type Db, type Tx } from '@plengo/db';

type Conn = Db | Tx;
export type UserDeckRow = typeof userDecks.$inferSelect;
export type UserCardRow = typeof userCards.$inferSelect;
export type UserDeckWrite = Omit<typeof userDecks.$inferInsert, 'syncSeq'>;
export type UserCardWrite = Omit<typeof userCards.$inferInsert, 'syncSeq'>;

/*
 * Every accepted write takes the next `sync_seq`. Writes of one student are serialized by
 * `lockStudent`, so their numbers grow in commit order and a reader never skips a row committed
 * after its cursor.
 */
const nextDeckSeq = sql`nextval('user_decks_sync_seq_seq')`;
const nextCardSeq = sql`nextval('user_cards_sync_seq_seq')`;

const liveCardCount = sql<number>`(select count(*)::int from user_cards uc where uc.deck_id = "user_decks"."id" and uc.deleted_at is null)`;

/** Private student decks and cards (§13.9). */
export function createUserContentRepository(db: Db) {
  return {
    /** Serializes one student's writes (the changes feed relies on it). */
    lockStudent: (tx: Tx, userId: string) =>
      tx.execute(sql`select pg_advisory_xact_lock(hashtext(${`user-content:${userId}`}))`),

    decks: (userId: string) =>
      db
        .select({ deck: userDecks, cardCount: liveCardCount })
        .from(userDecks)
        .where(and(eq(userDecks.userId, userId), isNull(userDecks.deletedAt)))
        .orderBy(asc(userDecks.sortOrder), asc(userDecks.createdAt)),

    async deck(userId: string, id: string, conn: Conn = db) {
      const [row] = await conn
        .select({ deck: userDecks, cardCount: liveCardCount })
        .from(userDecks)
        .where(and(eq(userDecks.id, id), eq(userDecks.userId, userId)));
      return row ?? null;
    },

    /** Any deck with this id, whoever owns it (ids come from devices). */
    async deckById(conn: Conn, id: string) {
      const [row] = await conn.select().from(userDecks).where(eq(userDecks.id, id));
      return row ?? null;
    },

    async cardById(conn: Conn, id: string) {
      const [row] = await conn.select().from(userCards).where(eq(userCards.id, id));
      return row ?? null;
    },

    liveCards: (userId: string, deckId: string) =>
      db
        .select()
        .from(userCards)
        .where(and(eq(userCards.userId, userId), eq(userCards.deckId, deckId), isNull(userCards.deletedAt)))
        .orderBy(asc(userCards.sortOrder), asc(userCards.createdAt)),

    /** The student's cards among `ids` (deleted ones included). */
    async cardsByIds(userId: string, ids: string[]) {
      if (!ids.length) return [];
      return db
        .select()
        .from(userCards)
        .where(and(eq(userCards.userId, userId), inArray(userCards.id, ids)));
    },

    /** Live decks and cards, for the quotas (§12.8). */
    async liveCounts(conn: Conn, userId: string) {
      const [decks] = await conn
        .select({ n: count() })
        .from(userDecks)
        .where(and(eq(userDecks.userId, userId), isNull(userDecks.deletedAt)));
      const [cards] = await conn
        .select({ n: count() })
        .from(userCards)
        .where(and(eq(userCards.userId, userId), isNull(userCards.deletedAt)));
      return { decks: decks!.n, cards: cards!.n };
    },

    async upsertDeck(tx: Tx, values: UserDeckWrite) {
      const { id: _id, userId: _u, createdAt: _c, ...changes } = values;
      await tx
        .insert(userDecks)
        .values(values)
        .onConflictDoUpdate({ target: userDecks.id, set: { ...changes, syncSeq: nextDeckSeq } });
    },

    async upsertCard(tx: Tx, values: UserCardWrite) {
      const { id: _id, userId: _u, createdAt: _c, ...changes } = values;
      await tx
        .insert(userCards)
        .values(values)
        .onConflictDoUpdate({ target: userCards.id, set: { ...changes, syncSeq: nextCardSeq } });
    },

    /** Deleting a deck deletes its live cards; returns how many and their image ids. */
    async deleteCardsOfDeck(tx: Tx, deckId: string, at: Date) {
      const rows = await tx
        .update(userCards)
        .set({ deletedAt: at, updatedAt: at, syncSeq: nextCardSeq })
        .where(and(eq(userCards.deckId, deckId), isNull(userCards.deletedAt)))
        .returning({ front: userCards.frontMediaId, back: userCards.backMediaId });
      return {
        count: rows.length,
        mediaIds: rows.flatMap((r) => [r.front, r.back]).filter((m): m is string => Boolean(m)),
      };
    },

    /**
     * Soft-deletes the student's card images that no live card uses any more, which frees their
     * image quota (§12.8).
     */
    async releaseMedia(tx: Tx, userId: string, mediaIds: string[]) {
      const ids = [...new Set(mediaIds)];
      if (!ids.length) return;
      await tx
        .update(mediaFiles)
        .set({ deletedAt: new Date() })
        .where(
          and(
            inArray(mediaFiles.id, ids),
            eq(mediaFiles.ownerUserId, userId),
            eq(mediaFiles.kind, 'user-card'),
            isNull(mediaFiles.deletedAt),
            sql`not exists (select 1 from user_cards uc where uc.deleted_at is null and (uc.front_media_id = ${mediaFiles.id} or uc.back_media_id = ${mediaFiles.id}))`,
          ),
        );
    },

    async media(ids: string[]) {
      if (!ids.length) return [];
      return db.select().from(mediaFiles).where(inArray(mediaFiles.id, ids));
    },

    /** Decks written after sequence number `after`, in write order (deleted ones included). */
    deckChanges: (userId: string, after: number, limit: number) =>
      db
        .select({ deck: userDecks, cardCount: liveCardCount })
        .from(userDecks)
        .where(and(eq(userDecks.userId, userId), gt(userDecks.syncSeq, after)))
        .orderBy(asc(userDecks.syncSeq))
        .limit(limit),

    cardChanges: (userId: string, after: number, limit: number) =>
      db
        .select()
        .from(userCards)
        .where(and(eq(userCards.userId, userId), gt(userCards.syncSeq, after)))
        .orderBy(asc(userCards.syncSeq))
        .limit(limit),
  };
}

export type UserContentRepository = ReturnType<typeof createUserContentRepository>;
