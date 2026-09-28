import {
  USER_CARD_QUOTA,
  USER_DECK_QUOTA,
  type SyncRejection,
  type UserCard,
  type UserCardInput,
  type UserDeck,
  type UserDeckInput,
} from '@plengo/contracts';
import type { Db } from '@plengo/db';
import { AppError } from '../lib/app-error.js';
import type {
  CardWithMedia,
  DeckRow,
  FlashcardRepository,
  MediaRow,
} from '../repositories/flashcard-repository.js';
import type { StructureRepository } from '../repositories/structure-repository.js';
import type { TeacherRepository } from '../repositories/teacher-repository.js';
import type {
  UserCardRow,
  UserContentRepository,
  UserDeckRow,
} from '../repositories/user-content-repository.js';
import type { AccessService } from './access-service.js';
import { assertVisibleScope } from './content-placement.js';
import { SIGNED_URL_TTL_SECONDS, type FlashcardService } from './flashcard-service.js';

type Rejection = SyncRejection;

/** Feed cursor: the last deck and card sequence numbers the device has seen. */
const encodeCursor = (deck: number, card: number) => Buffer.from(`${deck}.${card}`).toString('base64url');
function decodeCursor(cursor: string | undefined) {
  if (!cursor) return { deck: 0, card: 0 };
  const m = /^(\d{1,15})\.(\d{1,15})$/.exec(Buffer.from(cursor, 'base64url').toString('utf8'));
  if (!m) throw new AppError('VALIDATION_ERROR', { details: { field: 'since' } });
  return { deck: Number(m[1]), card: Number(m[2]) };
}

const iso = (d: Date | null) => d?.toISOString() ?? null;
const blank = (s: string | null | undefined) => !s || !s.trim();

/**
 * Private student decks and cards (spec §13.9): created offline with device ids, synced with last
 * write wins on `updated_at`, quotas of §12.8. "أضف إلى بطاقاتي" creates an `official_ref` card that
 * shows the official images only while the student can open the source card.
 */
export function createUserContentService(deps: {
  db: Db;
  repo: UserContentRepository;
  flashcardRepo: FlashcardRepository;
  flashcards: FlashcardService;
  structureRepo: StructureRepository;
  teacherRepo: TeacherRepository;
  access: AccessService;
  now?: () => Date;
}) {
  const { db, repo, flashcardRepo, flashcards, structureRepo, teacherRepo, access } = deps;
  const now = deps.now ?? (() => new Date());
  const expiry = () => new Date(now().getTime() + SIGNED_URL_TTL_SECONDS * 1000).toISOString();

  const toDeck = (d: UserDeckRow, cardCount: number): UserDeck => ({
    id: d.id,
    name: d.name,
    subjectId: d.subjectId,
    color: d.color,
    sortOrder: d.sortOrder,
    cardCount,
    createdAt: d.createdAt.toISOString(),
    updatedAt: d.updatedAt.toISOString(),
    deletedAt: iso(d.deletedAt),
  });

  /** The official cards the student can open now, by id (§13.9: only while accessible). */
  async function openOfficialCards(userId: string, ids: string[]) {
    const out = new Map<string, CardWithMedia>();
    if (!ids.length) return out;
    const ctx = await access.context(userId);
    const cards = await flashcardRepo.cardsByIds([...new Set(ids)]);
    const decks = new Map<string, DeckRow | null>();
    const visible = new Map<string, boolean>();
    for (const c of cards) {
      if (c.deletedAt || c.status !== 'published') continue;
      if (!decks.has(c.deckId)) decks.set(c.deckId, await flashcardRepo.getDeck(c.deckId));
      const d = decks.get(c.deckId);
      if (!d || d.status !== 'published' || !ctx.canAccessItem(d)) continue;
      const key = `${d.subjectId}:${d.teacherTrackId}`;
      if (!visible.has(key)) {
        visible.set(
          key,
          await assertVisibleScope({ structureRepo, teacherRepo }, d.subjectId, d.teacherTrackId)
            .then(() => true)
            .catch(() => false),
        );
      }
      if (visible.get(key)) out.set(c.id, c);
    }
    return out;
  }

  /** Card views with signed image URLs; official references resolved for the student. */
  async function toCards(userId: string, rows: UserCardRow[]): Promise<UserCard[]> {
    const mediaIds = rows.flatMap((r) => [r.frontMediaId, r.backMediaId]).filter((m): m is string => !!m);
    const media = new Map((await repo.media([...new Set(mediaIds)])).map((m) => [m.id, m]));
    const official = await openOfficialCards(
      userId,
      rows.flatMap((r) => (r.officialFlashcardId && !r.deletedAt ? [r.officialFlashcardId] : [])),
    );
    const image = async (m: MediaRow | undefined) =>
      m && m.status === 'ready' && !m.deletedAt ? flashcards.image(m) : null;

    return Promise.all(
      rows.map(async (r) => {
        const base = {
          id: r.id,
          deckId: r.deckId,
          kind: r.kind,
          officialFlashcardId: r.officialFlashcardId,
          sortOrder: r.sortOrder,
          createdAt: r.createdAt.toISOString(),
          updatedAt: r.updatedAt.toISOString(),
          deletedAt: iso(r.deletedAt),
        };
        if (r.kind === 'official_ref') {
          const c = official.get(r.officialFlashcardId!);
          return {
            ...base,
            locked: !c,
            front: { text: null, mediaId: null, image: c ? await flashcards.image(c.front) : null },
            back: { text: null, mediaId: null, image: c ? await flashcards.image(c.back) : null },
          };
        }
        return {
          ...base,
          locked: false,
          front: {
            text: r.frontText,
            mediaId: r.frontMediaId,
            image: await image(r.frontMediaId ? media.get(r.frontMediaId) : undefined),
          },
          back: {
            text: r.backText,
            mediaId: r.backMediaId,
            image: await image(r.backMediaId ? media.get(r.backMediaId) : undefined),
          },
        };
      }),
    );
  }

  /** A custom card's image: the student's own card upload, not deleted and not failed. */
  async function validMedia(userId: string, ids: (string | null | undefined)[]) {
    const wanted = ids.filter((m): m is string => !!m);
    if (!wanted.length) return true;
    const rows = await repo.media(wanted);
    return wanted.every((id) => {
      const m = rows.find((r) => r.id === id);
      return m && m.ownerUserId === userId && m.kind === 'user-card' && !m.deletedAt && m.status !== 'failed';
    });
  }

  return {
    toCards,

    async listDecks(userId: string): Promise<UserDeck[]> {
      return (await repo.decks(userId)).map((r) => toDeck(r.deck, r.cardCount));
    },

    async deckCards(userId: string, deckId: string) {
      const row = await repo.deck(userId, deckId);
      if (!row || row.deck.deletedAt) throw new AppError('NOT_FOUND');
      return {
        deck: toDeck(row.deck, row.cardCount),
        cards: await toCards(userId, await repo.liveCards(userId, deckId)),
        urlsExpireAt: expiry(),
      };
    },

    /** Everything written after `since`, in write order; deletions included (§13.9). */
    async changes(userId: string, since: string | undefined, limit: number) {
      const from = decodeCursor(since);
      const [decks, cards] = await Promise.all([
        repo.deckChanges(userId, from.deck, limit),
        repo.cardChanges(userId, from.card, limit),
      ]);
      const deckSeq = decks.length ? decks[decks.length - 1]!.deck.syncSeq : from.deck;
      const cardSeq = cards.length ? cards[cards.length - 1]!.syncSeq : from.card;
      return {
        decks: decks.map((r) => toDeck(r.deck, r.cardCount)),
        cards: await toCards(userId, cards),
        cursor: encodeCursor(deckSeq, cardSeq),
        hasMore: decks.length === limit || cards.length === limit,
        urlsExpireAt: expiry(),
      };
    },

    /**
     * Applies device writes: decks first (cards may belong to a deck in the same batch), each item
     * only when its `updated_at` is newer than the stored one. Refused items are listed instead of
     * failing the batch, so one bad card never blocks the rest of an offline session.
     */
    async sync(userId: string, body: { decks: UserDeckInput[]; cards: UserCardInput[] }) {
      const at = now();
      // A device clock ahead of the server cannot win every future conflict.
      const clamp = (s: string) => new Date(Math.min(Date.parse(s), at.getTime()));
      const rejected: Rejection[] = [];
      const reject = (type: 'deck' | 'card', id: string, code: Rejection['code'], reason: string) =>
        rejected.push({ type, id, code, reason });

      // Checks that need no lock run first.
      const subjectOk = new Map<string, boolean>();
      for (const d of body.decks) {
        if (d.subjectId && !subjectOk.has(d.subjectId)) {
          subjectOk.set(
            d.subjectId,
            Boolean(await structureRepo.getSubject(d.subjectId, { studentVisible: true })),
          );
        }
      }
      const mediaOk = new Map<string, boolean>();
      for (const c of body.cards) {
        if (c.kind === 'custom') mediaOk.set(c.id, await validMedia(userId, [c.frontMediaId, c.backMediaId]));
      }
      const refIds = body.cards.flatMap((c) =>
        c.kind === 'official_ref' && c.officialFlashcardId ? [c.officialFlashcardId] : [],
      );
      const openRefs = await openOfficialCards(userId, refIds);

      let appliedDecks = 0;
      let appliedCards = 0;
      await db.transaction(async (tx) => {
        await repo.lockStudent(tx, userId);
        const counts = await repo.liveCounts(tx, userId);

        for (const d of body.decks) {
          const existing = await repo.deckById(tx, d.id);
          if (existing && existing.userId !== userId) {
            reject('deck', d.id, 'NOT_FOUND', 'deck');
            continue;
          }
          const updatedAt = clamp(d.updatedAt);
          if (existing && existing.updatedAt.getTime() >= updatedAt.getTime()) continue;
          if (d.subjectId && !subjectOk.get(d.subjectId)) {
            reject('deck', d.id, 'VALIDATION_ERROR', 'subject');
            continue;
          }
          const deleting = Boolean(d.deletedAt);
          const wasLive = Boolean(existing && !existing.deletedAt);
          if (!deleting && !wasLive && counts.decks >= USER_DECK_QUOTA) {
            reject('deck', d.id, 'QUOTA_EXCEEDED', 'deck_quota');
            continue;
          }
          await repo.upsertDeck(tx, {
            id: d.id,
            userId,
            name: d.name,
            subjectId: d.subjectId ?? null,
            color: d.color ?? null,
            sortOrder: d.sortOrder,
            createdAt: existing?.createdAt ?? clamp(d.createdAt),
            updatedAt,
            deletedAt: deleting ? clamp(d.deletedAt!) : null,
          });
          appliedDecks += 1;
          if (deleting && wasLive) {
            counts.decks -= 1;
            const removed = await repo.deleteCardsOfDeck(tx, d.id, updatedAt);
            await repo.releaseMedia(tx, userId, removed.mediaIds);
            counts.cards -= removed.count;
          } else if (!deleting && !wasLive) {
            counts.decks += 1;
          }
        }

        for (const c of body.cards) {
          const existing = await repo.cardById(tx, c.id);
          if (existing && existing.userId !== userId) {
            reject('card', c.id, 'NOT_FOUND', 'card');
            continue;
          }
          const updatedAt = clamp(c.updatedAt);
          if (existing && existing.updatedAt.getTime() >= updatedAt.getTime()) continue;
          const deleting = Boolean(c.deletedAt);
          const wasLive = Boolean(existing && !existing.deletedAt);

          const deck = await repo.deckById(tx, c.deckId);
          if (!deck || deck.userId !== userId || (!deleting && deck.deletedAt)) {
            reject('card', c.id, 'NOT_FOUND', 'deck');
            continue;
          }
          if (existing && existing.kind !== c.kind) {
            reject('card', c.id, 'VALIDATION_ERROR', 'kind');
            continue;
          }
          let values: Pick<
            UserCardRow,
            'frontText' | 'backText' | 'frontMediaId' | 'backMediaId' | 'officialFlashcardId'
          >;
          if (c.kind === 'custom') {
            if (c.officialFlashcardId) {
              reject('card', c.id, 'VALIDATION_ERROR', 'official_flashcard');
              continue;
            }
            if (
              !deleting &&
              ((blank(c.frontText) && !c.frontMediaId) || (blank(c.backText) && !c.backMediaId))
            ) {
              reject('card', c.id, 'VALIDATION_ERROR', 'empty_face');
              continue;
            }
            if (!deleting && !mediaOk.get(c.id)) {
              reject('card', c.id, 'VALIDATION_ERROR', 'media');
              continue;
            }
            values = {
              frontText: blank(c.frontText) ? null : c.frontText!,
              backText: blank(c.backText) ? null : c.backText!,
              frontMediaId: c.frontMediaId ?? null,
              backMediaId: c.backMediaId ?? null,
              officialFlashcardId: null,
            };
          } else {
            const ref = existing?.officialFlashcardId ?? c.officialFlashcardId;
            if (!ref || (existing && c.officialFlashcardId && c.officialFlashcardId !== ref)) {
              reject('card', c.id, 'VALIDATION_ERROR', 'official_flashcard');
              continue;
            }
            // Adding needs access to the source card; later edits (order, deck) do not.
            if (!existing && !deleting && !openRefs.has(ref)) {
              reject('card', c.id, 'CONTENT_LOCKED', 'official_flashcard');
              continue;
            }
            values = {
              frontText: null,
              backText: null,
              frontMediaId: null,
              backMediaId: null,
              officialFlashcardId: ref,
            };
          }
          if (!deleting && !wasLive && counts.cards >= USER_CARD_QUOTA) {
            reject('card', c.id, 'QUOTA_EXCEEDED', 'card_quota');
            continue;
          }
          await repo.upsertCard(tx, {
            id: c.id,
            deckId: c.deckId,
            userId,
            kind: c.kind,
            ...values,
            sortOrder: c.sortOrder,
            createdAt: existing?.createdAt ?? clamp(c.createdAt),
            updatedAt,
            deletedAt: deleting ? clamp(c.deletedAt!) : null,
          });
          appliedCards += 1;
          if (deleting && wasLive) counts.cards -= 1;
          if (!deleting && !wasLive) counts.cards += 1;
          // Images the card no longer uses stop counting against the quota.
          const dropped = [existing?.frontMediaId, existing?.backMediaId].filter(
            (m): m is string => !!m && (deleting || (m !== values.frontMediaId && m !== values.backMediaId)),
          );
          await repo.releaseMedia(tx, userId, dropped);
        }
      });
      return { appliedDecks, appliedCards, rejected };
    },

    /** The student's live cards among `ids`, for SRS and bookmarks. */
    async ownCards(userId: string, ids: string[]) {
      return repo.cardsByIds(userId, ids);
    },
  };
}

export type UserContentService = ReturnType<typeof createUserContentService>;
