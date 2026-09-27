import { z } from 'zod';
import { contentStatusSchema } from './questions.js';

/*
 * Flashcards (spec §13) and spaced-repetition sync (§13.6–§13.8). Card images are private: responses
 * carry signed URLs (1 hour) only for cards the student can open (§12.5).
 */

const int = () => z.number().int();

/** A card face. Clients cache images by `cacheKey`, so changing signed URLs do not re-download. */
export const cardImageSchema = z.object({
  mediaId: z.string(),
  cacheKey: z.string(),
  fullUrl: z.string(),
  thumbUrl: z.string(),
  width: int().nullable(),
  height: int().nullable(),
});

// ---- student ----

export const studentDeckSchema = z.object({
  id: z.string(),
  subjectId: z.string(),
  teacherTrackId: z.string().nullable(),
  unitId: z.string().nullable(),
  lessonId: z.string().nullable(),
  titleAr: z.string(),
  description: z.string().nullable(),
  coverUrl: z.string().nullable(),
  cardCount: int(),
  isFree: z.boolean(),
  /** Locked decks are metadata only; their cards are not listed (§8.6). */
  locked: z.boolean(),
  contentVersion: int(),
  sortOrder: int(),
});
export const studentDeckListSchema = z.array(studentDeckSchema);

export const deckListQuerySchema = z.object({
  subjectId: z.uuid(),
  /** Omitted: the subject's general decks. Set: that track's decks (§8.1). */
  teacherTrackId: z.uuid().optional(),
  unitId: z.uuid().optional(),
  lessonId: z.uuid().optional(),
});

export const studentCardSchema = z.object({
  id: z.string(),
  deckId: z.string(),
  sortOrder: int(),
  contentVersion: int(),
  front: cardImageSchema,
  back: cardImageSchema,
});

export const deckCardsSchema = z.object({
  deck: studentDeckSchema,
  cards: z.array(studentCardSchema),
  /** When the signed image URLs stop working; fetch again after this. */
  urlsExpireAt: z.string(),
});

// ---- spaced repetition ----

export const srsStateNameSchema = z.enum(['new', 'learning', 'review', 'relearning']);
export const srsRatingSchema = z.enum(['again', 'good', 'easy']);

/** A card's scheduling state as the device computed it (§13.4). Times are ISO-8601 UTC. */
export const srsStateInputSchema = z.object({
  state: srsStateNameSchema,
  step: int().min(0).max(10),
  dueAt: z.iso.datetime({ offset: true }),
  intervalDays: int().min(0).max(365),
  ease: z.number().min(1.3).max(10),
  reps: int().min(0),
  lapses: int().min(0),
  lastReviewedAt: z.iso.datetime({ offset: true }).nullable(),
});

export const srsCardStateSchema = srsStateInputSchema.extend({
  flashcardId: z.string(),
  updatedAt: z.string(),
});

export const srsStatesPageSchema = z.object({
  items: z.array(srsCardStateSchema),
  /** Pass back as `since` to get only later changes. Null when there is nothing newer. */
  nextCursor: z.string().nullable(),
});
export const srsStatesQuerySchema = z.object({
  since: z.string().max(200).optional(),
  limit: z.coerce.number().int().min(1).max(1000).default(500),
});

export const reviewLogInputSchema = z.object({
  /** Client UUID: the idempotency key. */
  id: z.uuid(),
  flashcardId: z.uuid(),
  rating: srsRatingSchema,
  stateBefore: srsStateInputSchema,
  stateAfter: srsStateInputSchema,
  reviewedAt: z.iso.datetime({ offset: true }),
  durationMs: int().min(0).max(3_600_000).nullable().optional(),
  /** Undo (§13.3): the server restores `stateBefore` if this review is still the card's latest. */
  undone: z.boolean().optional(),
});

export const srsCardStateInputSchema = srsStateInputSchema.extend({ flashcardId: z.uuid() });

export const srsSyncBodySchema = z.object({
  logs: z.array(reviewLogInputSchema).max(500),
  states: z.array(srsCardStateInputSchema).max(500),
});

export const srsSyncResultSchema = z.object({
  acceptedLogs: int(),
  appliedStates: int(),
  /** What the server now holds for every card in the request (last review wins, §13.8). */
  states: z.array(srsCardStateSchema),
});

/** A card due for review today, for the "all due cards" session (§13.2). */
export const dueCardSchema = z.object({
  card: studentCardSchema,
  deckTitleAr: z.string(),
  subjectId: z.string(),
  subjectNameAr: z.string(),
  state: srsCardStateSchema,
});
export const dueCardsSchema = z.object({
  cards: z.array(dueCardSchema),
  urlsExpireAt: z.string(),
});
export const dueQuerySchema = z.object({ subjectId: z.uuid().optional() });

// ---- admin ----

export const adminDeckSchema = z.object({
  id: z.string(),
  subjectId: z.string(),
  subjectNameAr: z.string(),
  teacherTrackId: z.string().nullable(),
  trackTitleAr: z.string().nullable(),
  unitId: z.string().nullable(),
  lessonId: z.string().nullable(),
  titleAr: z.string(),
  description: z.string().nullable(),
  coverMediaId: z.string().nullable(),
  coverUrl: z.string().nullable(),
  isFree: z.boolean(),
  freeSource: z.enum(['rule', 'manual_override']),
  status: contentStatusSchema,
  sortOrder: int(),
  contentVersion: int(),
  cardCount: int(),
  createdAt: z.string(),
  updatedAt: z.string(),
});
export const adminDeckListSchema = z.array(adminDeckSchema);

export const adminCardSchema = z.object({
  id: z.string(),
  deckId: z.string(),
  sortOrder: int(),
  status: contentStatusSchema,
  contentVersion: int(),
  front: cardImageSchema,
  back: cardImageSchema,
});
export const adminCardListSchema = z.array(adminCardSchema);

const boolParam = z.enum(['true', 'false']).transform((v) => v === 'true');
export const adminDeckQuerySchema = z.object({
  subjectId: z.uuid().optional(),
  teacherTrackId: z.uuid().optional(),
  generalOnly: boolParam.optional(),
  unitId: z.uuid().optional(),
  lessonId: z.uuid().optional(),
  status: contentStatusSchema.optional(),
});

const deckContentShape = {
  unitId: z.uuid().nullable().optional(),
  lessonId: z.uuid().nullable().optional(),
  titleAr: z.string().trim().min(1).max(200),
  description: z.string().trim().max(2000).nullable().optional(),
  coverMediaId: z.uuid().nullable().optional(),
};

/** The subject and track are fixed at creation: they decide the deck's access scope. */
export const createDeckBodySchema = z.object({
  subjectId: z.uuid(),
  teacherTrackId: z.uuid().nullable().optional(),
  ...deckContentShape,
});
export const updateDeckBodySchema = z.object(deckContentShape).partial();

export const createCardBodySchema = z.object({ frontMediaId: z.uuid(), backMediaId: z.uuid() });
export const updateCardBodySchema = z.object({
  frontMediaId: z.uuid().optional(),
  backMediaId: z.uuid().optional(),
  status: contentStatusSchema.optional(),
});

export type CardImage = z.infer<typeof cardImageSchema>;
export type StudentDeck = z.infer<typeof studentDeckSchema>;
export type StudentCard = z.infer<typeof studentCardSchema>;
export type AdminDeck = z.infer<typeof adminDeckSchema>;
export type AdminCard = z.infer<typeof adminCardSchema>;
export type SrsStateInput = z.infer<typeof srsStateInputSchema>;
export type SrsCardState = z.infer<typeof srsCardStateSchema>;

const named: [z.ZodType, string][] = [
  [cardImageSchema, 'CardImage'],
  [studentDeckSchema, 'StudentDeck'],
  [studentDeckListSchema, 'StudentDeckList'],
  [studentCardSchema, 'StudentCard'],
  [deckCardsSchema, 'DeckCards'],
  [srsStateInputSchema, 'SrsStateInput'],
  [srsCardStateSchema, 'SrsCardState'],
  [srsCardStateInputSchema, 'SrsSyncState'],
  [srsStatesPageSchema, 'SrsStatesPage'],
  [reviewLogInputSchema, 'ReviewLogInput'],
  [srsSyncBodySchema, 'SrsSyncRequest'],
  [srsSyncResultSchema, 'SrsSyncResult'],
  [dueCardSchema, 'DueCard'],
  [dueCardsSchema, 'DueCards'],
  [adminDeckSchema, 'AdminDeck'],
  [adminDeckListSchema, 'AdminDeckList'],
  [adminCardSchema, 'AdminCard'],
  [adminCardListSchema, 'AdminCardList'],
  [createDeckBodySchema, 'CreateDeckRequest'],
  [updateDeckBodySchema, 'UpdateDeckRequest'],
  [createCardBodySchema, 'CreateCardRequest'],
  [updateCardBodySchema, 'UpdateCardRequest'],
];
for (const [schema, id] of named) z.globalRegistry.add(schema, { id });
