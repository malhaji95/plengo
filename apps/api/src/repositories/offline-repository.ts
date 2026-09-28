import { and, asc, eq, inArray, isNull, sql } from 'drizzle-orm';
import { alias, type AnyPgColumn } from 'drizzle-orm/pg-core';
import {
  flashcardDecks,
  flashcards,
  mediaFiles,
  offlineGradeMismatches,
  offlineLeases,
  questions,
  quizQuestions,
  quizzes,
  type Db,
} from '@plengo/db';
import type { Scope } from './access-repository.js';

export type LeaseRow = typeof offlineLeases.$inferSelect;

const front = alias(mediaFiles, 'front_media');
const back = alias(mediaFiles, 'back_media');

const inScope = (
  table: { subjectId: AnyPgColumn; teacherTrackId: AnyPgColumn },
  subjectId: string,
  teacherTrackId: string | null,
) =>
  and(
    eq(table.subjectId, subjectId),
    teacherTrackId ? eq(table.teacherTrackId, teacherTrackId) : isNull(table.teacherTrackId),
  );

/** Reads for offline packs (§22) and the lease and mismatch tables. */
export function createOfflineRepository(db: Db) {
  return {
    /** Live published decks of a subject scope (a null track is general content), in reading order. */
    decksInScope: (subjectId: string, teacherTrackId: string | null) =>
      db
        .select()
        .from(flashcardDecks)
        .where(
          and(
            inScope(flashcardDecks, subjectId, teacherTrackId),
            isNull(flashcardDecks.deletedAt),
            eq(flashcardDecks.status, 'published'),
          ),
        )
        .orderBy(asc(flashcardDecks.sortOrder), asc(flashcardDecks.id)),

    /** Live published cards of these decks with both images. */
    async cardsOfDecks(deckIds: string[]) {
      if (!deckIds.length) return [];
      return db
        .select({ card: flashcards, front, back })
        .from(flashcards)
        .innerJoin(front, eq(front.id, flashcards.frontMediaId))
        .innerJoin(back, eq(back.id, flashcards.backMediaId))
        .where(
          and(
            inArray(flashcards.deckId, deckIds),
            isNull(flashcards.deletedAt),
            eq(flashcards.status, 'published'),
          ),
        )
        .orderBy(asc(flashcards.sortOrder), asc(flashcards.id));
    },

    /** Live published quizzes of a scope that may be downloaded (`allow_offline`, §22.1). */
    quizzesInScope: (subjectId: string, teacherTrackId: string | null) =>
      db
        .select()
        .from(quizzes)
        .where(
          and(
            inScope(quizzes, subjectId, teacherTrackId),
            isNull(quizzes.deletedAt),
            eq(quizzes.status, 'published'),
            eq(quizzes.allowOffline, true),
          ),
        )
        .orderBy(asc(quizzes.sortOrder), asc(quizzes.id)),

    /** Member question ids per quiz (live published ones), in quiz order. */
    async quizMembers(quizIds: string[]) {
      const out = new Map<string, string[]>();
      if (!quizIds.length) return out;
      const rows = await db
        .select({ quizId: quizQuestions.quizId, questionId: quizQuestions.questionId })
        .from(quizQuestions)
        .innerJoin(questions, eq(questions.id, quizQuestions.questionId))
        .where(
          and(
            inArray(quizQuestions.quizId, quizIds),
            isNull(questions.deletedAt),
            eq(questions.status, 'published'),
          ),
        )
        .orderBy(asc(quizQuestions.sortOrder), asc(questions.id));
      for (const r of rows) out.set(r.quizId, [...(out.get(r.quizId) ?? []), r.questionId]);
      return out;
    },

    // ---- leases ----

    leasesFor: (userId: string, sessionId: string) =>
      db
        .select()
        .from(offlineLeases)
        .where(
          and(
            eq(offlineLeases.userId, userId),
            eq(offlineLeases.sessionId, sessionId),
            isNull(offlineLeases.revokedAt),
          ),
        ),

    insertLease: async (values: typeof offlineLeases.$inferInsert) =>
      (await db.insert(offlineLeases).values(values).returning())[0]!,

    revokeLeases: async (ids: string[], at: Date) => {
      if (!ids.length) return;
      await db.update(offlineLeases).set({ revokedAt: at }).where(inArray(offlineLeases.id, ids));
    },

    /** Live leases a student holds for a scope on any device (offline attempts may use them). */
    async hasLease(userId: string, scope: Scope, at: Date) {
      const [row] = await db
        .select({ id: offlineLeases.id })
        .from(offlineLeases)
        .where(
          and(
            eq(offlineLeases.userId, userId),
            scope.scopeType === 'subject'
              ? eq(offlineLeases.subjectId, scope.subjectId)
              : eq(offlineLeases.teacherTrackId, scope.teacherTrackId),
            isNull(offlineLeases.revokedAt),
            sql`${offlineLeases.expiresAt} > ${at}`,
          ),
        )
        .limit(1);
      return Boolean(row);
    },

    async recordMismatches(rows: (typeof offlineGradeMismatches.$inferInsert)[]) {
      if (rows.length) await db.insert(offlineGradeMismatches).values(rows);
    },
  };
}

export type OfflineRepository = ReturnType<typeof createOfflineRepository>;
