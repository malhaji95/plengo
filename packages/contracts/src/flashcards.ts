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

/** Exactly one of `flashcardId` (official card) and `userCardId` (student card, §13.9) is set. */
export const srsCardStateSchema = srsStateInputSchema.extend({
  flashcardId: z.string().nullable(),
  userCardId: z.string().nullable(),
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

const oneCard = (v: { flashcardId?: string | undefined; userCardId?: string | undefined }) =>
  (v.flashcardId === undefined) !== (v.userCardId === undefined);
const oneCardError = { message: 'Exactly one of flashcardId and userCardId', path: ['flashcardId'] };

export const reviewLogInputSchema = z
  .object({
    /** Client UUID: the idempotency key. */
    id: z.uuid(),
    flashcardId: z.uuid().optional(),
    userCardId: z.uuid().optional(),
    rating: srsRatingSchema,
    stateBefore: srsStateInputSchema,
    stateAfter: srsStateInputSchema,
    reviewedAt: z.iso.datetime({ offset: true }),
    durationMs: int().min(0).max(3_600_000).nullable().optional(),
    /** Undo (§13.3): the server restores `stateBefore` if this review is still the card's latest. */
    undone: z.boolean().optional(),
  })
  .refine(oneCard, oneCardError);

export const srsCardStateInputSchema = srsStateInputSchema
  .extend({ flashcardId: z.uuid().optional(), userCardId: z.uuid().optional() })
  .refine(oneCard, oneCardError);

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
// ---- student decks (§13.9) ----

export const USER_DECK_QUOTA = 50;
export const USER_CARD_QUOTA = 5000;
export const USER_CARD_TEXT_MAX = 1000;

const isoTime = z.iso.datetime({ offset: true });

export const userDeckSchema = z.object({
  id: z.string(),
  name: z.string(),
  subjectId: z.string().nullable(),
  color: z.string().nullable(),
  sortOrder: int(),
  /** Live cards in the deck. */
  cardCount: int(),
  createdAt: z.string(),
  updatedAt: z.string(),
  /** Set when deleted; kept in the changes feed so other devices remove it too. */
  deletedAt: z.string().nullable(),
});
export const userDeckListSchema = z.array(userDeckSchema);

export const userCardKindSchema = z.enum(['custom', 'official_ref']);

/** A face of a student card: text, an image, or both. */
export const userCardFaceSchema = z.object({
  text: z.string().nullable(),
  mediaId: z.string().nullable(),
  /** Null while the image is still processing, or when an official card is locked. */
  image: cardImageSchema.nullable(),
});

export const userCardSchema = z.object({
  id: z.string(),
  deckId: z.string(),
  kind: userCardKindSchema,
  officialFlashcardId: z.string().nullable(),
  /** An official_ref card whose source the student can no longer open (or that was removed). */
  locked: z.boolean(),
  front: userCardFaceSchema,
  back: userCardFaceSchema,
  sortOrder: int(),
  createdAt: z.string(),
  updatedAt: z.string(),
  deletedAt: z.string().nullable(),
});

export const userDeckCardsSchema = z.object({
  deck: userDeckSchema,
  cards: z.array(userCardSchema),
  urlsExpireAt: z.string(),
});

export const userDeckInputSchema = z.object({
  /** Generated on the device. */
  id: z.uuid(),
  name: z.string().trim().min(1).max(100),
  subjectId: z.uuid().nullable().optional(),
  color: z
    .string()
    .regex(/^#[0-9a-fA-F]{6}$/)
    .nullable()
    .optional(),
  sortOrder: int().min(0).max(100_000),
  createdAt: isoTime,
  /** Last write wins by this time (§13.9). */
  updatedAt: isoTime,
  deletedAt: isoTime.nullable().optional(),
});

const faceText = z.string().max(USER_CARD_TEXT_MAX).nullable().optional();
export const userCardInputSchema = z.object({
  id: z.uuid(),
  deckId: z.uuid(),
  kind: userCardKindSchema,
  frontText: faceText,
  backText: faceText,
  frontMediaId: z.uuid().nullable().optional(),
  backMediaId: z.uuid().nullable().optional(),
  /** Required for `official_ref` ("أضف إلى بطاقاتي"), absent for `custom`. */
  officialFlashcardId: z.uuid().nullable().optional(),
  sortOrder: int().min(0).max(100_000),
  createdAt: isoTime,
  updatedAt: isoTime,
  deletedAt: isoTime.nullable().optional(),
});

export const userContentSyncBodySchema = z.object({
  decks: z.array(userDeckInputSchema).max(100),
  cards: z.array(userCardInputSchema).max(500),
});

export const syncRejectionSchema = z.object({
  type: z.enum(['deck', 'card']),
  id: z.string(),
  code: z.enum(['QUOTA_EXCEEDED', 'VALIDATION_ERROR', 'CONTENT_LOCKED', 'NOT_FOUND']),
  /** Machine-readable detail, e.g. `deck_quota`, `card_quota`, `empty_face`, `media`, `deck`. */
  reason: z.string(),
});

export const userContentSyncResultSchema = z.object({
  appliedDecks: int(),
  appliedCards: int(),
  /** Items the server refused; the device should undo them locally and tell the student. */
  rejected: z.array(syncRejectionSchema),
});

export const userContentChangesQuerySchema = z.object({
  since: z.string().max(200).optional(),
  limit: z.coerce.number().int().min(1).max(1000).default(500),
});

export const userContentChangesSchema = z.object({
  decks: z.array(userDeckSchema),
  cards: z.array(userCardSchema),
  /** Pass back as `since`. Always set; unchanged when there was nothing new. */
  cursor: z.string(),
  /** More cards changed than `limit`; call again with `cursor`. */
  hasMore: z.boolean(),
  urlsExpireAt: z.string(),
});

/** A student card due today (§13.2). */
export const dueUserCardSchema = z.object({
  card: userCardSchema,
  deckName: z.string(),
  state: srsCardStateSchema,
});

export const dueCardsSchema = z.object({
  cards: z.array(dueCardSchema),
  userCards: z.array(dueUserCardSchema),
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
export type UserDeck = z.infer<typeof userDeckSchema>;
export type UserCard = z.infer<typeof userCardSchema>;
export type UserDeckInput = z.infer<typeof userDeckInputSchema>;
export type UserCardInput = z.infer<typeof userCardInputSchema>;
export type SyncRejection = z.infer<typeof syncRejectionSchema>;

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
  [userDeckSchema, 'UserDeck'],
  [userDeckListSchema, 'UserDeckList'],
  [userCardKindSchema, 'UserCardKind'],
  [userCardFaceSchema, 'UserCardFace'],
  [userCardSchema, 'UserCard'],
  [userDeckCardsSchema, 'UserDeckCards'],
  [userDeckInputSchema, 'UserDeckWrite'],
  [userCardInputSchema, 'UserCardWrite'],
  [userContentSyncBodySchema, 'UserContentSyncRequest'],
  [syncRejectionSchema, 'SyncRejection'],
  [userContentSyncResultSchema, 'UserContentSyncResult'],
  [userContentChangesSchema, 'UserContentChanges'],
  [dueUserCardSchema, 'DueUserCard'],
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
