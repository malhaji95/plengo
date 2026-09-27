import { z } from 'zod';

/*
 * Questions (spec §14). Student responses never contain `isCorrect` or accepted answers before the
 * server grades an answer (§14.3); locked questions are metadata only (§8.6).
 */

export const questionTypeSchema = z.enum(['mcq', 'true_false', 'written']);
export const contentStatusSchema = z.enum(['draft', 'published', 'archived']);
export const difficultySchema = z.enum(['easy', 'medium', 'hard']);

const questionText = z.string().trim().min(1).max(4000);
const explanation = z.string().trim().max(4000);

/** Total and free published questions in a scope (subject general content or a track). */
export const contentCountSchema = z.object({ total: z.number(), free: z.number() });

// ---- student ----

export const studentOptionSchema = z.object({ id: z.string(), text: z.string() });

export const studentQuestionSchema = z.object({
  id: z.string(),
  type: questionTypeSchema,
  subjectId: z.string(),
  teacherTrackId: z.string().nullable(),
  unitId: z.string().nullable(),
  lessonId: z.string().nullable(),
  sortOrder: z.number(),
  difficulty: difficultySchema.nullable(),
  isFree: z.boolean(),
  /** Locked questions carry no text or options. */
  locked: z.boolean(),
  questionText: z.string().nullable(),
  options: z.array(studentOptionSchema).nullable(),
});

export const studentQuestionPageSchema = z.object({
  items: z.array(studentQuestionSchema),
  nextCursor: z.string().nullable(),
  /** Counts for the whole filter, not just this page. */
  totalCount: z.number(),
  accessibleCount: z.number(),
});

export const questionListQuerySchema = z.object({
  subjectId: z.uuid(),
  /** Omitted: the subject's general questions. Set: that track's questions (§8.1). */
  teacherTrackId: z.uuid().optional(),
  unitId: z.uuid().optional(),
  lessonId: z.uuid().optional(),
  cursor: z.string().max(200).optional(),
  limit: z.coerce.number().int().min(1).max(100).default(30),
});

export const checkAnswerBodySchema = z.object({
  selectedOptionId: z.uuid().optional(),
  writtenAnswer: z.string().max(500).optional(),
});

/** Revealed only after grading (§14.3, §15.5). */
export const checkResultSchema = z.object({
  isCorrect: z.boolean(),
  correctOptionId: z.string().nullable(),
  /** Written questions: the first accepted answer, as the admin wrote it. */
  correctAnswer: z.string().nullable(),
  explanation: z.string().nullable(),
});

// ---- admin ----

export const adminQuestionOptionSchema = z.object({
  id: z.string(),
  text: z.string(),
  isCorrect: z.boolean(),
  sortOrder: z.number(),
});

export const adminAcceptedAnswerSchema = z.object({
  id: z.string(),
  answerOriginal: z.string(),
  answerNormalized: z.string(),
  normalizationVersion: z.number(),
});

export const adminQuestionSchema = z.object({
  id: z.string(),
  type: questionTypeSchema,
  subjectId: z.string(),
  subjectNameAr: z.string(),
  teacherTrackId: z.string().nullable(),
  trackTitleAr: z.string().nullable(),
  unitId: z.string().nullable(),
  lessonId: z.string().nullable(),
  questionText: z.string(),
  explanation: z.string().nullable(),
  difficulty: difficultySchema.nullable(),
  isFree: z.boolean(),
  freeSource: z.enum(['rule', 'manual_override']),
  status: contentStatusSchema,
  sortOrder: z.number(),
  contentVersion: z.number(),
  options: z.array(adminQuestionOptionSchema),
  acceptedAnswers: z.array(adminAcceptedAnswerSchema),
  createdAt: z.string(),
  updatedAt: z.string(),
});

export const adminQuestionPageSchema = z.object({
  items: z.array(adminQuestionSchema),
  nextCursor: z.string().nullable(),
  totalCount: z.number(),
});

const boolParam = z.enum(['true', 'false']).transform((v) => v === 'true');

export const adminQuestionQuerySchema = z.object({
  subjectId: z.uuid().optional(),
  teacherTrackId: z.uuid().optional(),
  /** Only the subject's general questions (no track). */
  generalOnly: boolParam.optional(),
  unitId: z.uuid().optional(),
  lessonId: z.uuid().optional(),
  status: contentStatusSchema.optional(),
  type: questionTypeSchema.optional(),
  q: z.string().trim().max(200).optional(),
  cursor: z.string().max(200).optional(),
  limit: z.coerce.number().int().min(1).max(200).default(50),
});

export const questionOptionInputSchema = z.object({
  /** Keep the id of an existing option so later attempts keep pointing at it. */
  id: z.uuid().optional(),
  text: z.string().trim().min(1).max(1000),
  isCorrect: z.boolean(),
});

/**
 * Content fields. Per type: `mcq` needs 2–6 options with exactly one correct; `true_false` needs
 * `trueFalseAnswer`; `written` needs 1–10 accepted answers. Checked by the service.
 */
const questionContentShape = {
  unitId: z.uuid().nullable().optional(),
  lessonId: z.uuid().nullable().optional(),
  questionText,
  explanation: explanation.nullable().optional(),
  difficulty: difficultySchema.nullable().optional(),
  options: z.array(questionOptionInputSchema).max(6).optional(),
  trueFalseAnswer: z.boolean().optional(),
  acceptedAnswers: z.array(z.string().trim().min(1).max(300)).max(10).optional(),
};

/** The subject, track and type are fixed at creation: they decide the access scope and grading. */
export const createQuestionBodySchema = z.object({
  type: questionTypeSchema,
  subjectId: z.uuid(),
  teacherTrackId: z.uuid().nullable().optional(),
  ...questionContentShape,
  /** Save and publish in one step. */
  publish: z.boolean().optional(),
});

export const updateQuestionBodySchema = z.object(questionContentShape).partial();

export const questionStatusBodySchema = z.object({ status: contentStatusSchema });

/** `rule` follows the scope's free rule; `free`/`paid` are manual overrides (§8.4). */
export const questionFreeBodySchema = z.object({ mode: z.enum(['rule', 'free', 'paid']) });

export const questionReorderBodySchema = z.object({ ids: z.array(z.uuid()).min(1).max(1000) });

export const normalizePreviewBodySchema = z.object({
  answers: z.array(z.string().max(300)).min(1).max(20),
});
export const normalizePreviewSchema = z.object({
  normalizationVersion: z.number(),
  items: z.array(z.object({ original: z.string(), normalized: z.string() })),
});

export type QuestionType = z.infer<typeof questionTypeSchema>;
export type StudentQuestion = z.infer<typeof studentQuestionSchema>;
export type AdminQuestion = z.infer<typeof adminQuestionSchema>;
export type CheckResult = z.infer<typeof checkResultSchema>;
export type ContentCount = z.infer<typeof contentCountSchema>;

const named: [z.ZodType, string][] = [
  [contentCountSchema, 'ContentCount'],
  [studentOptionSchema, 'StudentOption'],
  [studentQuestionSchema, 'StudentQuestion'],
  [studentQuestionPageSchema, 'StudentQuestionPage'],
  [checkAnswerBodySchema, 'CheckAnswerRequest'],
  [checkResultSchema, 'CheckResult'],
  [adminQuestionOptionSchema, 'AdminQuestionOption'],
  [adminAcceptedAnswerSchema, 'AdminAcceptedAnswer'],
  [adminQuestionSchema, 'AdminQuestion'],
  [adminQuestionPageSchema, 'AdminQuestionPage'],
  [questionOptionInputSchema, 'QuestionOptionInput'],
  [createQuestionBodySchema, 'CreateQuestionRequest'],
  [updateQuestionBodySchema, 'UpdateQuestionRequest'],
  [questionStatusBodySchema, 'QuestionStatusRequest'],
  [questionFreeBodySchema, 'QuestionFreeRequest'],
  [questionReorderBodySchema, 'QuestionReorderRequest'],
  [normalizePreviewBodySchema, 'NormalizePreviewRequest'],
  [normalizePreviewSchema, 'NormalizePreview'],
];
for (const [schema, id] of named) z.globalRegistry.add(schema, { id });
