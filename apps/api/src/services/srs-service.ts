import { and, asc, eq, gt, inArray, isNotNull, lt, ne, or, sql } from 'drizzle-orm';
import { cardStates, flashcardDecks, flashcards, reviewLogs, subjects, type Db } from '@plengo/db';
import type { SrsCardState, SrsStateInput } from '@plengo/contracts';
import { businessDay, startOfBusinessDay } from '@plengo/srs';
import { AppError } from '../lib/app-error.js';
import type { FlashcardRepository } from '../repositories/flashcard-repository.js';
import type { LearningRepository } from '../repositories/learning-repository.js';
import type { StructureRepository } from '../repositories/structure-repository.js';
import type { TeacherRepository } from '../repositories/teacher-repository.js';
import type { AccessService } from './access-service.js';
import { assertVisibleScope } from './content-placement.js';
import type { FlashcardService } from './flashcard-service.js';
import { SIGNED_URL_TTL_SECONDS } from './flashcard-service.js';

type StateRow = typeof cardStates.$inferSelect;
type LogInput = {
  id: string;
  flashcardId: string;
  rating: 'again' | 'good' | 'easy';
  stateBefore: SrsStateInput;
  stateAfter: SrsStateInput;
  reviewedAt: string;
  durationMs?: number | null | undefined;
  undone?: boolean | undefined;
};

const MAX_DUE = 1000;

const toColumns = (s: SrsStateInput) => ({
  state: s.state,
  step: s.step,
  dueAt: new Date(s.dueAt),
  intervalDays: s.intervalDays,
  ease: s.ease,
  reps: s.reps,
  lapses: s.lapses,
  lastReviewedAt: s.lastReviewedAt ? new Date(s.lastReviewedAt) : null,
});

const toApi = (r: StateRow): SrsCardState => ({
  flashcardId: r.flashcardId!,
  state: r.state,
  step: r.step,
  dueAt: r.dueAt.toISOString(),
  intervalDays: r.intervalDays,
  ease: r.ease,
  reps: r.reps,
  lapses: r.lapses,
  lastReviewedAt: r.lastReviewedAt?.toISOString() ?? null,
  updatedAt: r.updatedAt.toISOString(),
});

/** Keyset cursor over (updated_at, id); timestamps are written with millisecond precision. */
const encode = (r: StateRow) => Buffer.from(`${r.updatedAt.getTime()}|${r.id}`).toString('base64url');
function decode(cursor: string | undefined) {
  if (!cursor) return null;
  const [ms, id] = Buffer.from(cursor, 'base64url').toString('utf8').split('|');
  if (!id || !/^\d+$/.test(ms ?? '') || !/^[0-9a-f-]{36}$/.test(id))
    throw new AppError('VALIDATION_ERROR', { details: { field: 'since' } });
  return { at: new Date(Number(ms)), id };
}

/**
 * Spaced-repetition storage and sync (spec §13.6–§13.8). Scheduling runs on the device; the server
 * stores client-computed states after schema validation, keeps every review log (idempotent by the
 * client id), and resolves conflicts by the latest review.
 */
export function createSrsService(deps: {
  db: Db;
  flashcardRepo: FlashcardRepository;
  learningRepo: LearningRepository;
  flashcards: FlashcardService;
  structureRepo: StructureRepository;
  teacherRepo: TeacherRepository;
  access: AccessService;
  now?: () => Date;
}) {
  const { db, flashcardRepo, learningRepo, flashcards: cards, structureRepo, teacherRepo, access } = deps;
  const now = deps.now ?? (() => new Date());

  async function assertCardsExist(ids: string[]) {
    if (!ids.length) return;
    const found = await db.select({ id: flashcards.id }).from(flashcards).where(inArray(flashcards.id, ids));
    if (found.length !== ids.length)
      throw new AppError('VALIDATION_ERROR', { details: { field: 'flashcardId' } });
  }

  return {
    /** States changed since `since` (other devices' reviews, §13.8). */
    async states(userId: string, since: string | undefined, limit: number) {
      const after = decode(since);
      const rows = await db
        .select()
        .from(cardStates)
        .where(
          and(
            eq(cardStates.userId, userId),
            isNotNull(cardStates.flashcardId),
            after
              ? or(
                  gt(cardStates.updatedAt, after.at),
                  and(eq(cardStates.updatedAt, after.at), gt(cardStates.id, after.id)),
                )
              : undefined,
          ),
        )
        .orderBy(asc(cardStates.updatedAt), asc(cardStates.id))
        .limit(limit);
      return { items: rows.map(toApi), nextCursor: rows.length ? encode(rows[rows.length - 1]!) : null };
    },

    /**
     * Logs first (insert once; an undone log restores `stateBefore` when it is still the card's latest
     * review), then states (applied only when their last review is newer than the stored one).
     */
    async sync(
      userId: string,
      platform: string | null,
      body: { logs: LogInput[]; states: (SrsStateInput & { flashcardId: string })[] },
    ) {
      const ids = [
        ...new Set([...body.logs.map((l) => l.flashcardId), ...body.states.map((s) => s.flashcardId)]),
      ];
      await assertCardsExist(ids);
      const at = now();

      const result = await db.transaction(async (tx) => {
        let acceptedLogs = 0;
        for (const log of body.logs) {
          const inserted = await tx
            .insert(reviewLogs)
            .values({
              id: log.id,
              userId,
              flashcardId: log.flashcardId,
              rating: log.rating,
              stateBefore: log.stateBefore,
              stateAfter: log.stateAfter,
              reviewedAt: new Date(log.reviewedAt),
              durationMs: log.durationMs ?? null,
              undone: log.undone ?? false,
              devicePlatform: platform,
            })
            .onConflictDoNothing({ target: reviewLogs.id })
            .returning({ id: reviewLogs.id });
          acceptedLogs += inserted.length;

          if (!log.undone) continue;
          const [mine] = await tx
            .update(reviewLogs)
            .set({ undone: true })
            .where(and(eq(reviewLogs.id, log.id), eq(reviewLogs.userId, userId)))
            .returning({ id: reviewLogs.id });
          if (!mine) continue;
          const [current] = await tx
            .select()
            .from(cardStates)
            .where(and(eq(cardStates.userId, userId), eq(cardStates.flashcardId, log.flashcardId)))
            .for('update');
          const undoneAt = log.stateAfter.lastReviewedAt ? Date.parse(log.stateAfter.lastReviewedAt) : null;
          if (current && current.lastReviewedAt?.getTime() === undoneAt) {
            await tx
              .update(cardStates)
              .set({ ...toColumns(log.stateBefore), updatedAt: at })
              .where(eq(cardStates.id, current.id));
          }
        }

        let appliedStates = 0;
        for (const s of body.states) {
          if (!s.lastReviewedAt) continue; // an unreviewed card has nothing to store
          const applied = await tx
            .insert(cardStates)
            .values({ userId, flashcardId: s.flashcardId, ...toColumns(s), updatedAt: at })
            .onConflictDoUpdate({
              target: [cardStates.userId, cardStates.flashcardId],
              set: { ...toColumns(s), updatedAt: at },
              setWhere: sql`${cardStates.lastReviewedAt} is null or ${cardStates.lastReviewedAt} < ${new Date(s.lastReviewedAt)}`,
            })
            .returning({ id: cardStates.id });
          appliedStates += applied.length;
        }
        // The resume pointer follows the latest reviewed deck (§18).
        const latest = body.logs
          .filter((l) => !l.undone)
          .sort((a, b) => Date.parse(b.reviewedAt) - Date.parse(a.reviewedAt))[0];
        if (latest) {
          const [deck] = await tx
            .select({ d: flashcardDecks })
            .from(flashcards)
            .innerJoin(flashcardDecks, eq(flashcardDecks.id, flashcards.deckId))
            .where(eq(flashcards.id, latest.flashcardId));
          const reviewedAt = new Date(latest.reviewedAt);
          if (deck && reviewedAt.getTime() <= at.getTime() + 60_000) {
            await learningRepo.touchProgress(tx, {
              userId,
              subjectId: deck.d.subjectId,
              teacherTrackId: deck.d.teacherTrackId,
              unitId: deck.d.unitId,
              lessonId: deck.d.lessonId,
              type: 'deck',
              itemId: deck.d.id,
              at: reviewedAt,
            });
          }
        }
        return { acceptedLogs, appliedStates };
      });

      const states = ids.length
        ? await db
            .select()
            .from(cardStates)
            .where(and(eq(cardStates.userId, userId), inArray(cardStates.flashcardId, ids)))
        : [];
      return { ...result, states: states.map(toApi) };
    },

    /**
     * Review, learning and relearning cards due before the next 04:00 Damascus boundary, across every
     * deck the student can open (§13.2, §13.5). New cards are introduced from deck study sessions.
     */
    async due(userId: string, subjectId: string | undefined) {
      const at = now();
      const endOfToday = new Date(startOfBusinessDay(businessDay(at.getTime()) + 1));
      const rows = await db
        .select({ state: cardStates, deck: flashcardDecks, subjectNameAr: subjects.nameAr })
        .from(cardStates)
        .innerJoin(flashcards, eq(flashcards.id, cardStates.flashcardId))
        .innerJoin(flashcardDecks, eq(flashcardDecks.id, flashcards.deckId))
        .innerJoin(subjects, eq(subjects.id, flashcardDecks.subjectId))
        .where(
          and(
            eq(cardStates.userId, userId),
            ne(cardStates.state, 'new'),
            lt(cardStates.dueAt, endOfToday),
            sql`${flashcards.deletedAt} is null`,
            eq(flashcards.status, 'published'),
            sql`${flashcardDecks.deletedAt} is null`,
            eq(flashcardDecks.status, 'published'),
            subjectId ? eq(flashcardDecks.subjectId, subjectId) : undefined,
          ),
        )
        .orderBy(asc(cardStates.dueAt))
        .limit(MAX_DUE);

      // Only cards the student can open, in visible subjects and tracks (§13.5).
      const ctx = await access.context(userId);
      const visible = new Map<string, boolean>();
      const isVisible = async (deck: typeof flashcardDecks.$inferSelect) => {
        const key = `${deck.subjectId}:${deck.teacherTrackId}`;
        if (!visible.has(key)) {
          visible.set(
            key,
            await assertVisibleScope({ structureRepo, teacherRepo }, deck.subjectId, deck.teacherTrackId)
              .then(() => true)
              .catch(() => false),
          );
        }
        return visible.get(key)!;
      };
      const open = [];
      for (const r of rows) if (ctx.canAccessItem(r.deck) && (await isVisible(r.deck))) open.push(r);

      const cardRows = new Map(
        (await flashcardRepo.cardsByIds(open.map((r) => r.state.flashcardId!))).map((c) => [c.id, c]),
      );
      const items = await Promise.all(
        open.map(async (r) => ({
          card: await cards.toStudentCard(cardRows.get(r.state.flashcardId!)!),
          deckTitleAr: r.deck.titleAr,
          subjectId: r.deck.subjectId,
          subjectNameAr: r.subjectNameAr,
          state: toApi(r.state),
        })),
      );
      return {
        cards: items,
        urlsExpireAt: new Date(at.getTime() + SIGNED_URL_TTL_SECONDS * 1000).toISOString(),
      };
    },
  };
}

export type SrsService = ReturnType<typeof createSrsService>;
