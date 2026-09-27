import type { AdminCard, AdminDeck, CardImage, StudentCard, StudentDeck } from '@plengo/contracts';
import type { Db } from '@plengo/db';
import { AppError } from '../lib/app-error.js';
import type { Scope } from '../repositories/access-repository.js';
import type {
  CardWithMedia,
  DeckFilter,
  DeckRow,
  FlashcardRepository,
  MediaRow,
} from '../repositories/flashcard-repository.js';
import type { StructureRepository } from '../repositories/structure-repository.js';
import type { TeacherRepository } from '../repositories/teacher-repository.js';
import type { ObjectStorage } from '../storage/storage.js';
import { scopeOf, type AccessService } from './access-service.js';
import type { AuditService } from './audit-service.js';
import { assertVisibleScope, invalid, resolvePlacement, validateContentScope } from './content-placement.js';
import type { FreeContentSource, FreeRuleService } from './free-rule-service.js';
import { publicImageUrl } from './structure-mappers.js';
import type { AdminActor } from './structure-service.js';

/** Signed image URLs live one hour (§12.5). */
export const SIGNED_URL_TTL_SECONDS = 3600;

type DeckWithCount = DeckRow & { cardCount: number };

/** Plugs decks into the free-rule engine (§8.4). */
export function deckFreeSource(repo: FlashcardRepository): FreeContentSource {
  return {
    kind: 'flashcard_decks',
    items: async (scope) =>
      (await repo.publishedInScope(scope)).map((r) => ({
        id: r.id,
        unitId: r.unitId,
        lessonId: r.lessonId,
        sortOrder: r.sortOrder,
        isFree: r.isFree,
        manual: r.freeSource === 'manual_override',
      })),
    applyRule: (scope, freeIds) => repo.applyRule(scope, freeIds),
  };
}

/**
 * Official flashcard decks and cards (spec §13.1). Deck metadata, membership and order changes bump
 * the deck's `content_version`; a card's images, order or status bump the card's (§22.3).
 */
export function createFlashcardService(deps: {
  db: Db;
  repo: FlashcardRepository;
  structureRepo: StructureRepository;
  teacherRepo: TeacherRepository;
  access: AccessService;
  freeRules: FreeRuleService;
  audit: AuditService;
  storage: ObjectStorage;
  now?: () => Date;
}) {
  const { db, repo, structureRepo, teacherRepo, access, freeRules, audit, storage } = deps;
  const now = deps.now ?? (() => new Date());
  const notFound = (): never => {
    throw new AppError('NOT_FOUND');
  };
  const record = (actor: AdminActor, action: string, resourceType: string, id: string, metadata = {}) =>
    audit.record({
      actorAdminId: actor.adminId,
      action,
      resourceType,
      resourceId: id,
      metadata,
      ip: actor.ip,
    });

  // ---- images ----

  async function image(m: MediaRow): Promise<CardImage> {
    const full = m.variants.full;
    const thumb = m.variants.thumb ?? full;
    const sign = (key: string | undefined) =>
      key ? storage.getSignedGetUrl(m.bucket, key, SIGNED_URL_TTL_SECONDS) : Promise.resolve('');
    const [fullUrl, thumbUrl] = await Promise.all([sign(full?.key), sign(thumb?.key)]);
    return {
      mediaId: m.id,
      cacheKey: `${m.id}:${m.version}`,
      fullUrl,
      thumbUrl,
      width: full?.width ?? null,
      height: full?.height ?? null,
    };
  }

  async function toStudentCard(c: CardWithMedia): Promise<StudentCard> {
    const [frontImage, backImage] = await Promise.all([image(c.front), image(c.back)]);
    return {
      id: c.id,
      deckId: c.deckId,
      sortOrder: c.sortOrder,
      contentVersion: c.contentVersion,
      front: frontImage,
      back: backImage,
    };
  }

  const toAdminCard = async (c: CardWithMedia): Promise<AdminCard> => ({
    ...(await toStudentCard(c)),
    status: c.status,
  });

  async function coverUrls(decks: DeckRow[]) {
    const ids = [...new Set(decks.flatMap((d) => (d.coverMediaId ? [d.coverMediaId] : [])))];
    const media = await Promise.all(ids.map((id) => repo.getMedia(id)));
    return new Map(
      media.flatMap((m) => (m ? [[m.id, publicImageUrl(storage, m.variants, m.status)] as const] : [])),
    );
  }

  async function toAdminDecks(decks: DeckWithCount[]): Promise<AdminDeck[]> {
    const [names, covers] = await Promise.all([
      repo.names(
        [...new Set(decks.map((d) => d.subjectId))],
        [...new Set(decks.flatMap((d) => (d.teacherTrackId ? [d.teacherTrackId] : [])))],
      ),
      coverUrls(decks),
    ]);
    return decks.map((d) => ({
      id: d.id,
      subjectId: d.subjectId,
      subjectNameAr: names.subjects.get(d.subjectId) ?? '',
      teacherTrackId: d.teacherTrackId,
      trackTitleAr: d.teacherTrackId ? (names.tracks.get(d.teacherTrackId) ?? null) : null,
      unitId: d.unitId,
      lessonId: d.lessonId,
      titleAr: d.titleAr,
      description: d.description,
      coverMediaId: d.coverMediaId,
      coverUrl: d.coverMediaId ? (covers.get(d.coverMediaId) ?? null) : null,
      isFree: d.isFree,
      freeSource: d.freeSource,
      status: d.status,
      sortOrder: d.sortOrder,
      contentVersion: d.contentVersion,
      cardCount: d.cardCount,
      createdAt: d.createdAt.toISOString(),
      updatedAt: d.updatedAt.toISOString(),
    }));
  }

  const adminDeck = async (id: string) => (await toAdminDecks([(await repo.getDeck(id)) ?? notFound()]))[0]!;

  /** A card image must be an uploaded, processed flashcard image. */
  async function assertCardImage(mediaId: string, field: string) {
    const m = await repo.getMedia(mediaId);
    if (!m || m.deletedAt || m.kind !== 'flashcard' || m.status !== 'ready') invalid(field);
  }
  async function assertCover(mediaId: string | null | undefined) {
    if (!mediaId) return;
    const m = await repo.getMedia(mediaId);
    if (!m || m.deletedAt || m.kind !== 'cover' || m.status !== 'ready') invalid('coverMediaId');
  }

  const deckScope = (d: { subjectId: string; teacherTrackId: string | null }): Scope => scopeOf(d);

  /** Metadata, membership and order changes bump the deck version (§22.3). */
  const bumpDeck = (
    conn: Db | Parameters<Parameters<Db['transaction']>[0]>[0],
    d: DeckRow,
    actor: AdminActor,
  ) =>
    repo.updateDeck(conn, d.id, {
      contentVersion: d.contentVersion + 1,
      updatedByAdminId: actor.adminId,
      updatedAt: now(),
    });

  async function setDeckStatus(actor: AdminActor, id: string, status: DeckRow['status']): Promise<AdminDeck> {
    const deck = (await repo.getDeck(id)) ?? notFound();
    if (deck.status === status) return adminDeck(id);
    if (status === 'published' && deck.cardCount === 0) invalid('cards', 'empty_deck');
    await repo.updateDeck(db, id, { status, updatedByAdminId: actor.adminId, updatedAt: now() });
    if (status === 'published' && deck.freeSource === 'rule') {
      await repo.updateDeck(db, id, {
        isFree: await freeRules.isFreeOnPublish(deckScope(deck), 'flashcard_decks', id),
      });
    }
    await record(
      actor,
      `deck.${status === 'published' ? 'published' : status === 'archived' ? 'archived' : 'unpublished'}`,
      'flashcard_deck',
      id,
    );
    return adminDeck(id);
  }

  // ---- student ----

  async function publishedDeck(id: string) {
    const deck = await repo.getDeck(id);
    if (!deck || deck.status !== 'published') notFound();
    await assertVisibleScope({ structureRepo, teacherRepo }, deck!.subjectId, deck!.teacherTrackId);
    return deck!;
  }

  async function toStudentDecks(
    decks: DeckWithCount[],
    canOpen: (d: DeckRow) => boolean,
  ): Promise<StudentDeck[]> {
    const covers = await coverUrls(decks);
    return decks.map((d) => ({
      id: d.id,
      subjectId: d.subjectId,
      teacherTrackId: d.teacherTrackId,
      unitId: d.unitId,
      lessonId: d.lessonId,
      titleAr: d.titleAr,
      description: d.description,
      coverUrl: d.coverMediaId ? (covers.get(d.coverMediaId) ?? null) : null,
      cardCount: d.cardCount,
      isFree: d.isFree,
      locked: !canOpen(d),
      contentVersion: d.contentVersion,
      sortOrder: d.sortOrder,
    }));
  }

  return {
    image,
    toStudentCard,
    counts: (scope: Scope) => repo.scopeCounts(scope),

    // ---- admin: decks ----

    async adminList(filter: DeckFilter) {
      return toAdminDecks(await repo.listDecks(filter));
    },
    adminGet: adminDeck,

    async createDeck(
      actor: AdminActor,
      input: {
        subjectId: string;
        teacherTrackId?: string | null | undefined;
        unitId?: string | null | undefined;
        lessonId?: string | null | undefined;
        titleAr: string;
        description?: string | null | undefined;
        coverMediaId?: string | null | undefined;
      },
    ): Promise<AdminDeck> {
      const trackId = input.teacherTrackId ?? null;
      await validateContentScope({ structureRepo, teacherRepo }, input.subjectId, trackId);
      const place = await resolvePlacement(
        structureRepo,
        input.subjectId,
        input.unitId ?? null,
        input.lessonId ?? null,
      );
      await assertCover(input.coverMediaId);
      const scope = deckScope({ subjectId: input.subjectId, teacherTrackId: trackId });
      const deck = await db.transaction(async (tx) => {
        const row = await repo.insertDeck(tx, {
          subjectId: input.subjectId,
          teacherTrackId: trackId,
          ...place,
          titleAr: input.titleAr,
          description: input.description ?? null,
          coverMediaId: input.coverMediaId ?? null,
          sortOrder: await repo.nextDeckSortOrder(tx, scope),
          createdByAdminId: actor.adminId,
          updatedByAdminId: actor.adminId,
        });
        await audit.record(
          {
            actorAdminId: actor.adminId,
            action: 'deck.created',
            resourceType: 'flashcard_deck',
            resourceId: row.id,
            metadata: { ...scope },
            ip: actor.ip,
          },
          tx,
        );
        return row;
      });
      return adminDeck(deck.id);
    },

    async updateDeck(
      actor: AdminActor,
      id: string,
      patch: {
        unitId?: string | null | undefined;
        lessonId?: string | null | undefined;
        titleAr?: string | undefined;
        description?: string | null | undefined;
        coverMediaId?: string | null | undefined;
      },
    ): Promise<AdminDeck> {
      const current = (await repo.getDeck(id)) ?? notFound();
      const place = await resolvePlacement(
        structureRepo,
        current.subjectId,
        patch.unitId !== undefined ? patch.unitId : current.unitId,
        patch.lessonId !== undefined ? patch.lessonId : current.lessonId,
      );
      if (patch.coverMediaId !== undefined) await assertCover(patch.coverMediaId);
      const next = {
        ...place,
        titleAr: patch.titleAr ?? current.titleAr,
        description: patch.description !== undefined ? patch.description : current.description,
        coverMediaId: patch.coverMediaId !== undefined ? patch.coverMediaId : current.coverMediaId,
      };
      const changed = (Object.keys(next) as (keyof typeof next)[]).some((k) => next[k] !== current[k]);
      if (!changed) return adminDeck(id);
      await repo.updateDeck(db, id, {
        ...next,
        contentVersion: current.contentVersion + 1,
        updatedByAdminId: actor.adminId,
        updatedAt: now(),
      });
      await record(actor, 'deck.updated', 'flashcard_deck', id, {
        contentVersion: current.contentVersion + 1,
      });
      return adminDeck(id);
    },

    setDeckStatus,

    async setDeckFree(actor: AdminActor, id: string, mode: 'rule' | 'free' | 'paid'): Promise<AdminDeck> {
      const deck = (await repo.getDeck(id)) ?? notFound();
      const values =
        mode === 'rule'
          ? {
              freeSource: 'rule' as const,
              isFree:
                deck.status === 'published'
                  ? await freeRules.isFreeOnPublish(deckScope(deck), 'flashcard_decks', id)
                  : false,
            }
          : { freeSource: 'manual_override' as const, isFree: mode === 'free' };
      await repo.updateDeck(db, id, { ...values, updatedByAdminId: actor.adminId, updatedAt: now() });
      await record(actor, 'deck.free_override', 'flashcard_deck', id, { mode, isFree: values.isFree });
      return adminDeck(id);
    },

    /** `ids` must be every live sibling deck (same subject, track, unit and lesson) in the new order. */
    async reorderDecks(actor: AdminActor, ids: string[]) {
      const first = (await repo.getDeck(ids[0]!)) ?? notFound();
      const siblings = new Set((await repo.deckSiblings(first)).map((s) => s.id));
      if (
        siblings.size !== ids.length ||
        new Set(ids).size !== ids.length ||
        ids.some((i) => !siblings.has(i))
      ) {
        invalid('ids', 'not_all_siblings');
      }
      await db.transaction(async (tx) => {
        for (const [i, id] of ids.entries()) await repo.updateDeck(tx, id, { sortOrder: i });
      });
      await record(actor, 'deck.reordered', 'flashcard_deck', first.id, { ids });
      return { reordered: true };
    },

    async removeDeck(actor: AdminActor, id: string) {
      if (!(await repo.getDeck(id))) notFound();
      await repo.updateDeck(db, id, { deletedAt: now(), updatedByAdminId: actor.adminId });
      await record(actor, 'deck.deleted', 'flashcard_deck', id);
      return { deleted: true };
    },

    // ---- admin: cards ----

    async adminCards(deckId: string): Promise<AdminCard[]> {
      if (!(await repo.getDeck(deckId))) notFound();
      return Promise.all((await repo.listCards(deckId, { publishedOnly: false })).map(toAdminCard));
    },

    async createCard(
      actor: AdminActor,
      deckId: string,
      input: { frontMediaId: string; backMediaId: string },
    ) {
      await assertCardImage(input.frontMediaId, 'frontMediaId');
      await assertCardImage(input.backMediaId, 'backMediaId');
      const id = await db.transaction(async (tx) => {
        const deck = (await repo.getDeckForUpdate(tx, deckId)) ?? notFound();
        const card = await repo.insertCard(tx, {
          deckId,
          frontMediaId: input.frontMediaId,
          backMediaId: input.backMediaId,
          sortOrder: await repo.nextCardSortOrder(tx, deckId),
        });
        await bumpDeck(tx, deck, actor);
        return card.id;
      });
      await record(actor, 'card.created', 'flashcard', id, { deckId });
      return toAdminCard((await repo.getCard(id))!);
    },

    async updateCard(
      actor: AdminActor,
      id: string,
      patch: {
        frontMediaId?: string | undefined;
        backMediaId?: string | undefined;
        status?: DeckRow['status'] | undefined;
      },
    ): Promise<AdminCard> {
      const current = (await repo.getCard(id)) ?? notFound();
      if (patch.frontMediaId && patch.frontMediaId !== current.frontMediaId)
        await assertCardImage(patch.frontMediaId, 'frontMediaId');
      if (patch.backMediaId && patch.backMediaId !== current.backMediaId)
        await assertCardImage(patch.backMediaId, 'backMediaId');
      const next = {
        frontMediaId: patch.frontMediaId ?? current.frontMediaId,
        backMediaId: patch.backMediaId ?? current.backMediaId,
        status: patch.status ?? current.status,
      };
      if (
        next.frontMediaId === current.frontMediaId &&
        next.backMediaId === current.backMediaId &&
        next.status === current.status
      ) {
        return toAdminCard(current);
      }
      await db.transaction(async (tx) => {
        const deck = (await repo.getDeckForUpdate(tx, current.deckId)) ?? notFound();
        await repo.updateCard(tx, id, {
          ...next,
          contentVersion: current.contentVersion + 1,
          updatedAt: now(),
        });
        // A status change alters deck membership (§22.3).
        if (next.status !== current.status) await bumpDeck(tx, deck, actor);
      });
      await record(actor, 'card.updated', 'flashcard', id, { deckId: current.deckId, ...patch });
      return toAdminCard((await repo.getCard(id))!);
    },

    /** Every live card of the deck, in the new order. Moved cards and the deck get new versions. */
    async reorderCards(actor: AdminActor, deckId: string, ids: string[]) {
      const live = await repo.liveCardIds(deckId);
      if (
        live.length !== ids.length ||
        new Set(ids).size !== ids.length ||
        ids.some((i) => !live.includes(i))
      ) {
        invalid('ids', 'not_all_cards');
      }
      await db.transaction(async (tx) => {
        const deck = (await repo.getDeckForUpdate(tx, deckId)) ?? notFound();
        for (const [i, cardId] of ids.entries()) {
          const card = (await repo.getCard(cardId, tx))!;
          if (card.sortOrder !== i) {
            await repo.updateCard(tx, cardId, {
              sortOrder: i,
              contentVersion: card.contentVersion + 1,
              updatedAt: now(),
            });
          }
        }
        await bumpDeck(tx, deck, actor);
      });
      await record(actor, 'card.reordered', 'flashcard_deck', deckId, { ids });
      return { reordered: true };
    },

    async removeCard(actor: AdminActor, id: string) {
      const card = (await repo.getCard(id)) ?? notFound();
      await db.transaction(async (tx) => {
        const deck = (await repo.getDeckForUpdate(tx, card.deckId)) ?? notFound();
        await repo.updateCard(tx, id, { deletedAt: now(), updatedAt: now() });
        await bumpDeck(tx, deck, actor);
      });
      await record(actor, 'card.deleted', 'flashcard', id, { deckId: card.deckId });
      return { deleted: true };
    },

    // ---- student ----

    async studentDecks(
      userId: string,
      q: {
        subjectId: string;
        teacherTrackId?: string | undefined;
        unitId?: string | undefined;
        lessonId?: string | undefined;
      },
    ) {
      await assertVisibleScope({ structureRepo, teacherRepo }, q.subjectId, q.teacherTrackId ?? null);
      const [decks, ctx] = await Promise.all([
        repo.listDecks({
          subjectId: q.subjectId,
          teacherTrackId: q.teacherTrackId,
          generalOnly: !q.teacherTrackId,
          unitId: q.unitId,
          lessonId: q.lessonId,
          status: 'published',
        }),
        access.context(userId),
      ]);
      return toStudentDecks(decks, (d) => ctx.canAccessItem(d));
    },

    async studentDeck(userId: string, id: string): Promise<StudentDeck> {
      const deck = await publishedDeck(id);
      const ctx = await access.context(userId);
      return (await toStudentDecks([deck], (d) => ctx.canAccessItem(d)))[0]!;
    },

    /** Cards with signed image URLs; locked decks answer CONTENT_LOCKED (§8.6, §12.5). */
    async deckCards(userId: string, id: string) {
      const deck = await publishedDeck(id);
      await access.assertCanAccessItem(userId, deck);
      const cards = await repo.listCards(id, { publishedOnly: true });
      return {
        deck: (await toStudentDecks([deck], () => true))[0]!,
        cards: await Promise.all(cards.map(toStudentCard)),
        urlsExpireAt: new Date(now().getTime() + SIGNED_URL_TTL_SECONDS * 1000).toISOString(),
      };
    },
  };
}

export type FlashcardService = ReturnType<typeof createFlashcardService>;
