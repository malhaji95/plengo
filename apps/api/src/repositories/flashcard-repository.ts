import { and, asc, count, eq, getTableColumns, inArray, isNull, sql, type SQL } from 'drizzle-orm';
import { alias } from 'drizzle-orm/pg-core';
import {
  flashcardDecks,
  flashcards,
  lessons,
  mediaFiles,
  subjects,
  teacherTracks,
  units,
  type Db,
  type Tx,
} from '@plengo/db';
import type { Scope } from './access-repository.js';

export type DeckRow = typeof flashcardDecks.$inferSelect;
export type CardRow = typeof flashcards.$inferSelect;
export type MediaRow = typeof mediaFiles.$inferSelect;
export type CardWithMedia = CardRow & { front: MediaRow; back: MediaRow };

type Conn = Db | Tx;

const liveDeck = isNull(flashcardDecks.deletedAt);
const liveCard = isNull(flashcards.deletedAt);
const front = alias(mediaFiles, 'front_media');
const back = alias(mediaFiles, 'back_media');

export function deckScopeWhere(scope: Scope): SQL {
  return scope.scopeType === 'subject'
    ? and(eq(flashcardDecks.subjectId, scope.subjectId), isNull(flashcardDecks.teacherTrackId))!
    : eq(flashcardDecks.teacherTrackId, scope.teacherTrackId);
}

export interface DeckFilter {
  subjectId?: string | undefined;
  teacherTrackId?: string | undefined;
  generalOnly?: boolean | undefined;
  unitId?: string | undefined;
  lessonId?: string | undefined;
  status?: DeckRow['status'] | undefined;
}

/** Published cards per deck. Written with explicit aliases: single-table selects drop qualifiers. */
const cardCount = sql<number>`(select count(*)::int from flashcards fc where fc.deck_id = "flashcard_decks"."id" and fc.deleted_at is null and fc.status = 'published')`;

export function createFlashcardRepository(db: Db) {
  const cardQuery = (conn: Conn) =>
    conn
      .select({ card: flashcards, front, back })
      .from(flashcards)
      .innerJoin(front, eq(front.id, flashcards.frontMediaId))
      .innerJoin(back, eq(back.id, flashcards.backMediaId));

  const toCard = (r: { card: CardRow; front: MediaRow; back: MediaRow }): CardWithMedia => ({
    ...r.card,
    front: r.front,
    back: r.back,
  });

  return {
    async getDeck(id: string, conn: Conn = db) {
      const [row] = await conn
        .select({ ...getTableColumns(flashcardDecks), cardCount })
        .from(flashcardDecks)
        .where(and(eq(flashcardDecks.id, id), liveDeck));
      return row ?? null;
    },

    async getDeckForUpdate(tx: Tx, id: string) {
      const [row] = await tx
        .select()
        .from(flashcardDecks)
        .where(and(eq(flashcardDecks.id, id), liveDeck))
        .for('update');
      return row ?? null;
    },

    /** Decks in reading order (the order free rules use, §8.4), with their published card counts. */
    listDecks: (f: DeckFilter) =>
      db
        .select({ ...getTableColumns(flashcardDecks), cardCount })
        .from(flashcardDecks)
        .leftJoin(units, eq(units.id, flashcardDecks.unitId))
        .leftJoin(lessons, eq(lessons.id, flashcardDecks.lessonId))
        .where(
          and(
            liveDeck,
            f.subjectId ? eq(flashcardDecks.subjectId, f.subjectId) : undefined,
            f.teacherTrackId ? eq(flashcardDecks.teacherTrackId, f.teacherTrackId) : undefined,
            f.generalOnly ? isNull(flashcardDecks.teacherTrackId) : undefined,
            f.unitId ? eq(flashcardDecks.unitId, f.unitId) : undefined,
            f.lessonId ? eq(flashcardDecks.lessonId, f.lessonId) : undefined,
            f.status ? eq(flashcardDecks.status, f.status) : undefined,
          ),
        )
        .orderBy(
          asc(flashcardDecks.subjectId),
          sql`case when ${flashcardDecks.unitId} is not null then 0 when ${flashcardDecks.lessonId} is not null then 1 else 2 end`,
          asc(units.sortOrder),
          asc(units.id),
          sql`case when ${flashcardDecks.lessonId} is null then 0 else 1 end`,
          asc(lessons.sortOrder),
          asc(lessons.id),
          asc(flashcardDecks.sortOrder),
          asc(flashcardDecks.id),
        ),

    async scopeCounts(scope: Scope) {
      const [row] = await db
        .select({ total: count(), free: sql<number>`count(*) filter (where ${flashcardDecks.isFree})::int` })
        .from(flashcardDecks)
        .where(and(liveDeck, eq(flashcardDecks.status, 'published'), deckScopeWhere(scope)));
      return { total: row!.total, free: row!.free };
    },

    publishedInScope: (scope: Scope) =>
      db
        .select({
          id: flashcardDecks.id,
          unitId: flashcardDecks.unitId,
          lessonId: flashcardDecks.lessonId,
          sortOrder: flashcardDecks.sortOrder,
          isFree: flashcardDecks.isFree,
          freeSource: flashcardDecks.freeSource,
        })
        .from(flashcardDecks)
        .where(and(liveDeck, eq(flashcardDecks.status, 'published'), deckScopeWhere(scope))),

    async applyRule(scope: Scope, freeIds: Set<string>) {
      const ids = [...freeIds];
      await db
        .update(flashcardDecks)
        .set({ isFree: ids.length ? inArray(flashcardDecks.id, ids) : sql`false` })
        .where(
          and(
            liveDeck,
            eq(flashcardDecks.status, 'published'),
            eq(flashcardDecks.freeSource, 'rule'),
            deckScopeWhere(scope),
          ),
        );
    },

    async nextDeckSortOrder(conn: Conn, scope: Scope) {
      const [row] = await conn
        .select({ max: sql<number | null>`max(${flashcardDecks.sortOrder})` })
        .from(flashcardDecks)
        .where(and(liveDeck, deckScopeWhere(scope)));
      return (row?.max ?? -1) + 1;
    },

    async insertDeck(conn: Conn, values: typeof flashcardDecks.$inferInsert) {
      const [row] = await conn.insert(flashcardDecks).values(values).returning();
      return row!;
    },

    async updateDeck(conn: Conn, id: string, values: Partial<typeof flashcardDecks.$inferInsert>) {
      const [row] = await conn
        .update(flashcardDecks)
        .set(values)
        .where(eq(flashcardDecks.id, id))
        .returning();
      return row!;
    },

    deckSiblings: (d: DeckRow) =>
      db
        .select({ id: flashcardDecks.id })
        .from(flashcardDecks)
        .where(
          and(
            liveDeck,
            eq(flashcardDecks.subjectId, d.subjectId),
            d.teacherTrackId
              ? eq(flashcardDecks.teacherTrackId, d.teacherTrackId)
              : isNull(flashcardDecks.teacherTrackId),
            d.unitId ? eq(flashcardDecks.unitId, d.unitId) : isNull(flashcardDecks.unitId),
            d.lessonId ? eq(flashcardDecks.lessonId, d.lessonId) : isNull(flashcardDecks.lessonId),
          ),
        ),

    // ---- cards ----

    async listCards(deckId: string, opts: { publishedOnly: boolean }): Promise<CardWithMedia[]> {
      const rows = await cardQuery(db)
        .where(
          and(
            eq(flashcards.deckId, deckId),
            liveCard,
            opts.publishedOnly ? eq(flashcards.status, 'published') : undefined,
          ),
        )
        .orderBy(asc(flashcards.sortOrder), asc(flashcards.id));
      return rows.map(toCard);
    },

    async cardsByIds(ids: string[]): Promise<CardWithMedia[]> {
      if (!ids.length) return [];
      return (await cardQuery(db).where(inArray(flashcards.id, ids))).map(toCard);
    },

    async getCard(id: string, conn: Conn = db): Promise<CardWithMedia | null> {
      const [row] = await cardQuery(conn).where(and(eq(flashcards.id, id), liveCard));
      return row ? toCard(row) : null;
    },

    async nextCardSortOrder(conn: Conn, deckId: string) {
      const [row] = await conn
        .select({ max: sql<number | null>`max(${flashcards.sortOrder})` })
        .from(flashcards)
        .where(and(eq(flashcards.deckId, deckId), liveCard));
      return (row?.max ?? -1) + 1;
    },

    async insertCard(conn: Conn, values: typeof flashcards.$inferInsert) {
      const [row] = await conn.insert(flashcards).values(values).returning();
      return row!;
    },

    async updateCard(conn: Conn, id: string, values: Partial<typeof flashcards.$inferInsert>) {
      const [row] = await conn.update(flashcards).set(values).where(eq(flashcards.id, id)).returning();
      return row!;
    },

    liveCardIds: async (deckId: string) =>
      (
        await db
          .select({ id: flashcards.id })
          .from(flashcards)
          .where(and(eq(flashcards.deckId, deckId), liveCard))
      ).map((r) => r.id),

    /** Of the given ids, those that exist (deleted cards included). */
    async existingCardIds(ids: string[]) {
      if (!ids.length) return [];
      return (await db.select({ id: flashcards.id }).from(flashcards).where(inArray(flashcards.id, ids))).map(
        (r) => r.id,
      );
    },

    /** The deck a card belongs to (deleted ones included). */
    async deckOfCard(conn: Conn, cardId: string) {
      const [row] = await conn
        .select({ d: flashcardDecks })
        .from(flashcards)
        .innerJoin(flashcardDecks, eq(flashcardDecks.id, flashcards.deckId))
        .where(eq(flashcards.id, cardId));
      return row?.d ?? null;
    },

    /** Live published cards of live published decks in one subject scope, with their deck. */
    publishedCardsInScope: (subjectId: string, teacherTrackId: string | null) =>
      db
        .select({ id: flashcards.id, deck: flashcardDecks })
        .from(flashcards)
        .innerJoin(flashcardDecks, eq(flashcardDecks.id, flashcards.deckId))
        .where(
          and(
            eq(flashcardDecks.subjectId, subjectId),
            teacherTrackId
              ? eq(flashcardDecks.teacherTrackId, teacherTrackId)
              : isNull(flashcardDecks.teacherTrackId),
            isNull(flashcardDecks.deletedAt),
            eq(flashcardDecks.status, 'published'),
            isNull(flashcards.deletedAt),
            eq(flashcards.status, 'published'),
          ),
        ),

    /** Titles of live decks. */
    async deckTitles(ids: string[]) {
      if (!ids.length) return [];
      return db
        .select({ id: flashcardDecks.id, t: flashcardDecks.titleAr })
        .from(flashcardDecks)
        .where(and(inArray(flashcardDecks.id, ids), isNull(flashcardDecks.deletedAt)));
    },

    async getMedia(id: string) {
      const [row] = await db.select().from(mediaFiles).where(eq(mediaFiles.id, id)).limit(1);
      return row ?? null;
    },

    names: async (subjectIds: string[], trackIds: string[]) => {
      const [s, t] = await Promise.all([
        subjectIds.length
          ? db
              .select({ id: subjects.id, nameAr: subjects.nameAr })
              .from(subjects)
              .where(inArray(subjects.id, subjectIds))
          : [],
        trackIds.length
          ? db
              .select({ id: teacherTracks.id, titleAr: teacherTracks.titleAr })
              .from(teacherTracks)
              .where(inArray(teacherTracks.id, trackIds))
          : [],
      ]);
      return {
        subjects: new Map(s.map((r) => [r.id, r.nameAr])),
        tracks: new Map(t.map((r) => [r.id, r.titleAr])),
      };
    },
  };
}

export type FlashcardRepository = ReturnType<typeof createFlashcardRepository>;
