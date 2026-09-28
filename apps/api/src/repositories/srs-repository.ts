import { and, asc, eq, gt, inArray, isNotNull, lt, ne, or, sql } from 'drizzle-orm';
import {
  cardStates,
  flashcardDecks,
  flashcards,
  reviewLogs,
  subjects,
  userCards,
  userDecks,
  type Db,
  type Tx,
} from '@plengo/db';

export type CardStateRow = typeof cardStates.$inferSelect;
export type ReviewLogInsert = typeof reviewLogs.$inferInsert;

/** The scheduling columns of a card state (everything but identity and `updated_at`). */
export type CardStateColumns = Pick<
  CardStateRow,
  'state' | 'step' | 'dueAt' | 'intervalDays' | 'ease' | 'reps' | 'lapses' | 'lastReviewedAt'
>;

/** Which card a state or log belongs to: an official card or a student card (§13.7). */
export type CardKey =
  { flashcardId: string; userCardId?: undefined } | { userCardId: string; flashcardId?: undefined };

const keyWhere = (userId: string, key: CardKey) =>
  and(
    eq(cardStates.userId, userId),
    key.flashcardId
      ? eq(cardStates.flashcardId, key.flashcardId)
      : eq(cardStates.userCardId, key.userCardId!),
  );

/** Spaced-repetition card states and review logs (§13.6–§13.8). */
export function createSrsRepository(db: Db) {
  return {
    /** Keyset page over (updated_at, id) of the student's card states. */
    statesSince: (userId: string, after: { at: Date; id: string } | null, limit: number) =>
      db
        .select()
        .from(cardStates)
        .where(
          and(
            eq(cardStates.userId, userId),
            after
              ? or(
                  gt(cardStates.updatedAt, after.at),
                  and(eq(cardStates.updatedAt, after.at), gt(cardStates.id, after.id)),
                )
              : undefined,
          ),
        )
        .orderBy(asc(cardStates.updatedAt), asc(cardStates.id))
        .limit(limit),

    async statesFor(userId: string, flashcardIds: string[], userCardIds: string[] = []) {
      if (!flashcardIds.length && !userCardIds.length) return [];
      return db
        .select()
        .from(cardStates)
        .where(
          and(
            eq(cardStates.userId, userId),
            or(
              flashcardIds.length ? inArray(cardStates.flashcardId, flashcardIds) : undefined,
              userCardIds.length ? inArray(cardStates.userCardId, userCardIds) : undefined,
            ),
          ),
        );
    },

    /** Inserts once by the client id; returns whether this call inserted it. */
    async insertLog(tx: Tx, values: ReviewLogInsert) {
      const inserted = await tx
        .insert(reviewLogs)
        .values(values)
        .onConflictDoNothing({ target: reviewLogs.id })
        .returning({ id: reviewLogs.id });
      return inserted.length > 0;
    },

    /** Marks the student's own log undone; false when the log is not theirs. */
    async markLogUndone(tx: Tx, id: string, userId: string) {
      const [mine] = await tx
        .update(reviewLogs)
        .set({ undone: true })
        .where(and(eq(reviewLogs.id, id), eq(reviewLogs.userId, userId)))
        .returning({ id: reviewLogs.id });
      return Boolean(mine);
    },

    async stateForUpdate(tx: Tx, userId: string, key: CardKey) {
      const [row] = await tx.select().from(cardStates).where(keyWhere(userId, key)).for('update');
      return row ?? null;
    },

    async updateState(tx: Tx, id: string, values: CardStateColumns & { updatedAt: Date }) {
      await tx.update(cardStates).set(values).where(eq(cardStates.id, id));
    },

    /** Stores the state only when its last review is newer than the stored one; returns whether it did. */
    async upsertIfNewer(
      tx: Tx,
      userId: string,
      key: CardKey,
      cols: CardStateColumns,
      lastReviewedAt: Date,
      at: Date,
    ) {
      const applied = await tx
        .insert(cardStates)
        .values({ userId, ...key, ...cols, updatedAt: at })
        .onConflictDoUpdate({
          target: key.flashcardId
            ? [cardStates.userId, cardStates.flashcardId]
            : [cardStates.userId, cardStates.userCardId],
          set: { ...cols, updatedAt: at },
          setWhere: sql`${cardStates.lastReviewedAt} is null or ${cardStates.lastReviewedAt} < ${lastReviewedAt}`,
        })
        .returning({ id: cardStates.id });
      return applied.length > 0;
    },

    /** Reviewed (non-new) states due before `before` on live published cards and decks, oldest first. */
    due: (userId: string, before: Date, subjectId: string | undefined, limit: number) =>
      db
        .select({ state: cardStates, deck: flashcardDecks, subjectNameAr: subjects.nameAr })
        .from(cardStates)
        .innerJoin(flashcards, eq(flashcards.id, cardStates.flashcardId))
        .innerJoin(flashcardDecks, eq(flashcardDecks.id, flashcards.deckId))
        .innerJoin(subjects, eq(subjects.id, flashcardDecks.subjectId))
        .where(
          and(
            eq(cardStates.userId, userId),
            ne(cardStates.state, 'new'),
            lt(cardStates.dueAt, before),
            sql`${flashcards.deletedAt} is null`,
            eq(flashcards.status, 'published'),
            sql`${flashcardDecks.deletedAt} is null`,
            eq(flashcardDecks.status, 'published'),
            subjectId ? eq(flashcardDecks.subjectId, subjectId) : undefined,
          ),
        )
        .orderBy(asc(cardStates.dueAt))
        .limit(limit),

    /** Reviewed states of the student's live cards in live decks, due before `before`. */
    dueUserCards: (userId: string, before: Date, subjectId: string | undefined, limit: number) =>
      db
        .select({ state: cardStates, card: userCards, deckName: userDecks.name })
        .from(cardStates)
        .innerJoin(userCards, eq(userCards.id, cardStates.userCardId))
        .innerJoin(userDecks, eq(userDecks.id, userCards.deckId))
        .where(
          and(
            eq(cardStates.userId, userId),
            ne(cardStates.state, 'new'),
            lt(cardStates.dueAt, before),
            sql`${userCards.deletedAt} is null`,
            sql`${userDecks.deletedAt} is null`,
            subjectId ? eq(userDecks.subjectId, subjectId) : undefined,
          ),
        )
        .orderBy(asc(cardStates.dueAt))
        .limit(limit),

    /** Of the given cards, those the student has reviewed at least once. */
    async studiedCardIds(userId: string, flashcardIds: string[]) {
      if (!flashcardIds.length) return [];
      return db
        .select({ id: cardStates.flashcardId })
        .from(cardStates)
        .where(
          and(
            eq(cardStates.userId, userId),
            isNotNull(cardStates.lastReviewedAt),
            inArray(cardStates.flashcardId, flashcardIds),
          ),
        );
    },
  };
}

export type SrsRepository = ReturnType<typeof createSrsRepository>;
