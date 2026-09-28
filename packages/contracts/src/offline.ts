import { z } from 'zod';
import { scopeTypeSchema } from './access.js';
import { difficultySchema, questionTypeSchema } from './questions.js';
import { attemptModeSchema, attemptSourceSchema } from './quizzes.js';

/*
 * Offline packs (spec §22). Pack keys: `{scope_type}:{scope_id}:{unit_id|none}:{kind}` with kind
 * `questions`, `decks` or `quizzes`; a single deck is `{scope_type}:{scope_id}:-:deck.{deck_id}`.
 */

const int = () => z.number().int();

export const LEASE_DAYS = 30;

export const offlineScopeSchema = z.object({
  scopeType: scopeTypeSchema,
  subjectId: z.string().nullable(),
  teacherTrackId: z.string().nullable(),
});

export const offlinePackKindSchema = z.enum(['questions', 'decks', 'quizzes', 'deck']);

export const offlinePackSchema = z.object({
  packKey: z.string(),
  kind: offlinePackKindSchema,
  unitId: z.string().nullable(),
  /** For a single-deck pack. */
  deckId: z.string().nullable(),
  titleAr: z.string(),
  itemCount: int(),
  /** Estimated download size in bytes (images included). */
  sizeBytes: int(),
  /** Changes whenever an item is added, removed or edited ("تحديث متاح"). */
  version: z.string(),
  /** Holds premium items: usable offline only with a valid lease. */
  premium: z.boolean(),
});

/** Everything downloadable in one subject or track for this student (§22.1). */
export const offlineScopeCatalogSchema = z.object({
  scope: offlineScopeSchema,
  titleAr: z.string(),
  /** An active entitlement: premium items are included. Otherwise only free items are. */
  entitled: z.boolean(),
  packs: z.array(offlinePackSchema),
  sizeBytes: int(),
});

export const offlineScopeQuerySchema = z.object({
  subjectId: z.uuid(),
  teacherTrackId: z.uuid().optional(),
});

/** Scopes the student holds an entitlement for, with their total size (after redemption, §22.2). */
export const offlineCatalogSchema = z.object({
  scopes: z.array(
    z.object({ scope: offlineScopeSchema, titleAr: z.string(), sizeBytes: int(), packCount: int() }),
  ),
});

export const offlineItemTypeSchema = z.enum(['question', 'deck', 'card', 'quiz']);

export const offlineManifestSchema = z.object({
  packKey: z.string(),
  version: z.string(),
  premium: z.boolean(),
  /** The normalizer version the accepted answers were computed with (§22.6). */
  normalizationVersion: int(),
  items: z.array(z.object({ type: offlineItemTypeSchema, id: z.string(), version: int() })),
});

export const offlineQuestionSchema = z.object({
  id: z.string(),
  type: questionTypeSchema,
  subjectId: z.string(),
  teacherTrackId: z.string().nullable(),
  unitId: z.string().nullable(),
  lessonId: z.string().nullable(),
  sortOrder: int(),
  difficulty: difficultySchema.nullable(),
  isFree: z.boolean(),
  questionText: z.string(),
  explanation: z.string().nullable(),
  options: z.array(z.object({ id: z.string(), text: z.string(), isCorrect: z.boolean() })),
  acceptedAnswers: z.array(
    z.object({ original: z.string(), normalized: z.string(), normalizationVersion: int() }),
  ),
});

export const offlineImageSchema = z.object({
  mediaId: z.string(),
  version: int(),
  /** Signed (1 hour). */
  url: z.string(),
  width: int().nullable(),
  height: int().nullable(),
  sizeBytes: int(),
});

export const offlineDeckSchema = z.object({
  id: z.string(),
  subjectId: z.string(),
  teacherTrackId: z.string().nullable(),
  unitId: z.string().nullable(),
  lessonId: z.string().nullable(),
  titleAr: z.string(),
  description: z.string().nullable(),
  isFree: z.boolean(),
  sortOrder: int(),
  cardIds: z.array(z.string()),
});

export const offlineCardSchema = z.object({
  id: z.string(),
  deckId: z.string(),
  sortOrder: int(),
  front: offlineImageSchema,
  back: offlineImageSchema,
});

export const offlineQuizSchema = z.object({
  id: z.string(),
  subjectId: z.string(),
  teacherTrackId: z.string().nullable(),
  unitId: z.string().nullable(),
  lessonId: z.string().nullable(),
  titleAr: z.string(),
  description: z.string().nullable(),
  allowedModes: z.enum(['practice', 'exam', 'both']),
  timeLimitSeconds: int().nullable(),
  passingScore: int().nullable(),
  shuffleQuestions: z.boolean(),
  shuffleOptions: z.boolean(),
  isFree: z.boolean(),
  questionIds: z.array(z.string()),
});

export const offlineItemSchema = z.object({
  type: offlineItemTypeSchema,
  id: z.string(),
  version: int(),
  question: offlineQuestionSchema.nullable(),
  deck: offlineDeckSchema.nullable(),
  card: offlineCardSchema.nullable(),
  quiz: offlineQuizSchema.nullable(),
});

export const offlineItemsPageSchema = z.object({
  items: z.array(offlineItemSchema),
  nextCursor: z.string().nullable(),
  urlsExpireAt: z.string(),
});

export const offlineItemsQuerySchema = z.object({
  /** Comma-separated ids to fetch (delta downloads); all items when omitted. */
  ids: z
    .string()
    .max(40 * 100)
    .optional(),
  cursor: z.string().max(200).optional(),
});

export const packKeyParamsSchema = z.object({ packKey: z.string().min(5).max(200) });

// ---- leases ----

export const refreshLeasesBodySchema = z.object({
  scopes: z
    .array(
      z.object({
        scopeType: scopeTypeSchema,
        subjectId: z.uuid().nullable().optional(),
        teacherTrackId: z.uuid().nullable().optional(),
      }),
    )
    .max(200),
});

export const offlineLeaseSchema = offlineScopeSchema.extend({
  /** `none`: no active entitlement any more; delete this scope's premium pack data (§22.4). */
  status: z.enum(['active', 'none']),
  expiresAt: z.string().nullable(),
});

export const offlineLeasesSchema = z.object({
  /** For clock protection: the device refuses leases when its clock is behind this. */
  serverTime: z.string(),
  leases: z.array(offlineLeaseSchema),
});

// ---- offline attempts ----

export const offlineAnswerSchema = z.object({
  questionId: z.uuid(),
  selectedOptionId: z.uuid().nullable().optional(),
  writtenAnswer: z.string().max(500).nullable().optional(),
  flagged: z.boolean().optional(),
  timeSpentMs: int().min(0).max(86_400_000).nullable().optional(),
  /** What the device showed; a different server grade is logged (§22.6). */
  localIsCorrect: z.boolean().nullable().optional(),
});

export const offlineAttemptSchema = z.object({
  clientAttemptId: z.uuid(),
  source: attemptSourceSchema,
  mode: attemptModeSchema,
  quizId: z.uuid().nullable().optional(),
  subjectId: z.uuid().nullable().optional(),
  teacherTrackId: z.uuid().nullable().optional(),
  /** Questions in the order the student saw them. */
  questionIds: z.array(z.uuid()).min(1).max(200),
  startedAt: z.iso.datetime({ offset: true }),
  submittedAt: z.iso.datetime({ offset: true }),
  timeSpentMs: int().min(0).max(86_400_000).nullable().optional(),
  answers: z.array(offlineAnswerSchema).max(200),
});

export const offlineSyncBodySchema = z.object({ attempts: z.array(offlineAttemptSchema).max(20) });

export const offlineSyncResultSchema = z.object({
  results: z.array(
    z.object({
      clientAttemptId: z.string(),
      status: z.enum(['accepted', 'rejected']),
      /** Why an attempt was refused (e.g. `quiz_unavailable`, `no_questions`). */
      reason: z.string().nullable(),
      attemptId: z.string().nullable(),
      correctCount: int().nullable(),
      totalCount: int().nullable(),
      /** Answers the server graded differently from the device. */
      mismatches: int(),
    }),
  ),
});

export type OfflineScope = z.infer<typeof offlineScopeSchema>;
export type OfflinePack = z.infer<typeof offlinePackSchema>;
export type OfflineItem = z.infer<typeof offlineItemSchema>;
export type OfflineAttempt = z.infer<typeof offlineAttemptSchema>;

const named: [z.ZodType, string][] = [
  [offlineScopeSchema, 'OfflineScope'],
  [offlinePackKindSchema, 'OfflinePackKind'],
  [offlinePackSchema, 'OfflinePack'],
  [offlineScopeCatalogSchema, 'OfflineScopeCatalog'],
  [offlineCatalogSchema, 'OfflineCatalog'],
  [offlineItemTypeSchema, 'OfflineItemType'],
  [offlineManifestSchema, 'OfflineManifest'],
  [offlineQuestionSchema, 'OfflineQuestion'],
  [offlineImageSchema, 'OfflineImage'],
  [offlineDeckSchema, 'OfflineDeck'],
  [offlineCardSchema, 'OfflineCard'],
  [offlineQuizSchema, 'OfflineQuiz'],
  [offlineItemSchema, 'OfflineItem'],
  [offlineItemsPageSchema, 'OfflineItemsPage'],
  [refreshLeasesBodySchema, 'RefreshLeasesRequest'],
  [offlineLeaseSchema, 'OfflineLease'],
  [offlineLeasesSchema, 'OfflineLeases'],
  [offlineAnswerSchema, 'OfflineAnswer'],
  [offlineAttemptSchema, 'OfflineAttempt'],
  [offlineSyncBodySchema, 'OfflineSyncRequest'],
  [offlineSyncResultSchema, 'OfflineSyncResult'],
];
for (const [schema, id] of named) z.globalRegistry.add(schema, { id });
