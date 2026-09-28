import { z } from 'zod';
import { checkResultSchema, contentStatusSchema, questionTypeSchema } from './questions.js';

/*
 * Quizzes and attempts (spec §15). Attempt payloads never carry correctness before grading (§14.3):
 * `result` appears on a question once it is checked (practice) or the attempt is submitted (exam).
 */

const int = () => z.number().int();

export const quizModesSchema = z.enum(['practice', 'exam', 'both']);
export const attemptModeSchema = z.enum(['practice', 'exam']);
export const attemptSourceSchema = z.enum(['curated', 'random', 'mistakes']);
export const attemptStatusSchema = z.enum(['in_progress', 'submitted', 'abandoned']);

// ---- student: quizzes ----

export const studentQuizSchema = z.object({
  id: z.string(),
  subjectId: z.string(),
  teacherTrackId: z.string().nullable(),
  unitId: z.string().nullable(),
  lessonId: z.string().nullable(),
  titleAr: z.string(),
  description: z.string().nullable(),
  allowedModes: quizModesSchema,
  timeLimitSeconds: int().nullable(),
  passingScorePercent: int().nullable(),
  maxAttempts: int().nullable(),
  isMockExam: z.boolean(),
  allowOffline: z.boolean(),
  isFree: z.boolean(),
  sortOrder: int(),
  contentVersion: int(),
  /** Mixed quizzes (§8.8): "12 من 30 سؤال متاح". */
  totalCount: int(),
  accessibleCount: int(),
  lockedCount: int(),
  /** Nothing accessible, or a mock exam with any locked question. */
  locked: z.boolean(),
  attemptsUsed: int(),
  bestScorePercent: int().nullable(),
  /** The latest unfinished attempt, for "متابعة الاختبار". */
  inProgressAttemptId: z.string().nullable(),
});
export const studentQuizListSchema = z.array(studentQuizSchema);

export const quizListQuerySchema = z.object({
  subjectId: z.uuid(),
  /** Omitted: the subject's general quizzes. Set: that track's quizzes (§8.1). */
  teacherTrackId: z.uuid().optional(),
  unitId: z.uuid().optional(),
  lessonId: z.uuid().optional(),
});

// ---- student: attempts ----

export const attemptFiltersSchema = z.object({
  subjectId: z.uuid().nullable().optional(),
  /** With `subjectId`: null or omitted selects the subject's general questions. */
  teacherTrackId: z.uuid().nullable().optional(),
  unitId: z.uuid().nullable().optional(),
  lessonId: z.uuid().nullable().optional(),
  types: z.array(questionTypeSchema).max(3).optional(),
  count: int().min(1).max(100).optional(),
  /** Mistake reviews only: limit to these questions ("أعد الأخطاء فقط"). */
  questionIds: z.array(z.uuid()).max(200).optional(),
});

export const startAttemptBodySchema = z.object({
  /** Client UUID: starting twice with the same id returns the first attempt. */
  clientAttemptId: z.uuid(),
  source: attemptSourceSchema,
  mode: attemptModeSchema,
  /** Required for `curated`. */
  quizId: z.uuid().optional(),
  /** Random practice needs `subjectId`; mistake reviews may narrow by any field. */
  filters: attemptFiltersSchema.optional(),
});

export const attemptOptionSchema = z.object({
  id: z.string(),
  text: z.string(),
  /** Present only after grading. */
  isCorrect: z.boolean().nullable(),
});

export const attemptQuestionSchema = z.object({
  questionId: z.string(),
  type: questionTypeSchema,
  unitId: z.string().nullable(),
  lessonId: z.string().nullable(),
  questionText: z.string(),
  /** In this attempt's display order. */
  options: z.array(attemptOptionSchema),
  selectedOptionId: z.string().nullable(),
  writtenAnswer: z.string().nullable(),
  flagged: z.boolean(),
  answeredAt: z.string().nullable(),
  timeSpentMs: int().nullable(),
  /** Set after a practice check or once the attempt is submitted. */
  result: checkResultSchema.nullable(),
});

export const attemptSummarySchema = z.object({
  id: z.string(),
  clientAttemptId: z.string(),
  quizId: z.string().nullable(),
  source: attemptSourceSchema,
  mode: attemptModeSchema,
  titleAr: z.string(),
  subjectId: z.string().nullable(),
  teacherTrackId: z.string().nullable(),
  /** What a random or mistakes attempt was built from, for "أعد الاختبار". */
  filters: attemptFiltersSchema.nullable(),
  status: attemptStatusSchema,
  startedAt: z.string(),
  /** Server-authoritative end of a timed exam. */
  deadlineAt: z.string().nullable(),
  submittedAt: z.string().nullable(),
  submittedLate: z.boolean(),
  totalCount: int(),
  answeredCount: int(),
  correctCount: int().nullable(),
  wrongCount: int().nullable(),
  skippedCount: int().nullable(),
  scorePercent: int().nullable(),
  passingScorePercent: int().nullable(),
  /** Null without a passing score or before submission. */
  passed: z.boolean().nullable(),
  timeSpentMs: int().nullable(),
});
export const attemptSummaryPageSchema = z.object({
  items: z.array(attemptSummarySchema),
  nextCursor: z.string().nullable(),
});

export const attemptSchema = z.object({
  attempt: attemptSummarySchema,
  questions: z.array(attemptQuestionSchema),
  /** Lets the client align its timer with `deadlineAt`. */
  serverTime: z.string(),
});

export const attemptListQuerySchema = z.object({
  status: attemptStatusSchema.optional(),
  quizId: z.uuid().optional(),
  cursor: z.string().max(200).optional(),
  limit: z.coerce.number().int().min(1).max(100).default(20),
});

const answerShape = {
  selectedOptionId: z.uuid().nullable().optional(),
  writtenAnswer: z.string().max(500).nullable().optional(),
  timeSpentMs: int().min(0).max(86_400_000).nullable().optional(),
};

/** Exam autosave: answers can change until submission; `flagged` = علّم للمراجعة. */
export const saveAnswerBodySchema = z.object({ ...answerShape, flagged: z.boolean().optional() });

export const checkAttemptAnswerBodySchema = z.object(answerShape);

export const savedAnswerSchema = z.object({
  questionId: z.string(),
  selectedOptionId: z.string().nullable(),
  writtenAnswer: z.string().nullable(),
  flagged: z.boolean(),
  answeredAt: z.string().nullable(),
});

export const submitAnswerSchema = z.object({
  questionId: z.uuid(),
  ...answerShape,
  flagged: z.boolean().optional(),
});

/** Batch of the latest answers (sent again after a connection drop); idempotent. */
export const submitAttemptBodySchema = z.object({
  answers: z.array(submitAnswerSchema).max(200),
  timeSpentMs: int().min(0).max(86_400_000).optional(),
});

// ---- admin ----

export const adminQuizQuestionSchema = z.object({
  id: z.string(),
  type: questionTypeSchema,
  questionText: z.string(),
  status: contentStatusSchema,
  isFree: z.boolean(),
  unitId: z.string().nullable(),
  lessonId: z.string().nullable(),
  deleted: z.boolean(),
});

export const adminQuizSchema = z.object({
  id: z.string(),
  subjectId: z.string(),
  subjectNameAr: z.string(),
  teacherTrackId: z.string().nullable(),
  trackTitleAr: z.string().nullable(),
  unitId: z.string().nullable(),
  lessonId: z.string().nullable(),
  titleAr: z.string(),
  description: z.string().nullable(),
  allowedModes: quizModesSchema,
  timeLimitSeconds: int().nullable(),
  shuffleQuestions: z.boolean(),
  shuffleOptions: z.boolean(),
  passingScorePercent: int().nullable(),
  maxAttempts: int().nullable(),
  isMockExam: z.boolean(),
  allowOffline: z.boolean(),
  isFree: z.boolean(),
  freeSource: z.enum(['rule', 'manual_override']),
  status: contentStatusSchema,
  sortOrder: int(),
  contentVersion: int(),
  questionCount: int(),
  createdAt: z.string(),
  updatedAt: z.string(),
});
export const adminQuizListSchema = z.array(adminQuizSchema);
export const adminQuizDetailSchema = z.object({
  quiz: adminQuizSchema,
  questions: z.array(adminQuizQuestionSchema),
});

const boolParam = z.enum(['true', 'false']).transform((v) => v === 'true');
export const adminQuizQuerySchema = z.object({
  subjectId: z.uuid().optional(),
  teacherTrackId: z.uuid().optional(),
  generalOnly: boolParam.optional(),
  unitId: z.uuid().optional(),
  lessonId: z.uuid().optional(),
  status: contentStatusSchema.optional(),
});

const quizSettingsShape = {
  unitId: z.uuid().nullable().optional(),
  lessonId: z.uuid().nullable().optional(),
  titleAr: z.string().trim().min(1).max(200),
  description: z.string().trim().max(2000).nullable().optional(),
  allowedModes: quizModesSchema.optional(),
  timeLimitSeconds: int()
    .min(30)
    .max(6 * 3600)
    .nullable()
    .optional(),
  shuffleQuestions: z.boolean().optional(),
  shuffleOptions: z.boolean().optional(),
  passingScorePercent: int().min(0).max(100).nullable().optional(),
  maxAttempts: int().min(1).max(100).nullable().optional(),
  isMockExam: z.boolean().optional(),
  /** Defaults to false for mock exams and true otherwise (§22.2). */
  allowOffline: z.boolean().optional(),
};

/** The subject and track are fixed at creation: every question must share that scope (§15.1.1). */
export const createQuizBodySchema = z.object({
  subjectId: z.uuid(),
  teacherTrackId: z.uuid().nullable().optional(),
  ...quizSettingsShape,
  questionIds: z.array(z.uuid()).max(200).optional(),
});
export const updateQuizBodySchema = z.object(quizSettingsShape).partial();

/** The full membership in order: add, remove and reorder in one call. */
export const quizQuestionsBodySchema = z.object({ questionIds: z.array(z.uuid()).max(200) });

export type StudentQuiz = z.infer<typeof studentQuizSchema>;
export type AttemptSummary = z.infer<typeof attemptSummarySchema>;
export type AttemptQuestion = z.infer<typeof attemptQuestionSchema>;
export type AttemptView = z.infer<typeof attemptSchema>;
export type AdminQuiz = z.infer<typeof adminQuizSchema>;
export type AdminQuizDetail = z.infer<typeof adminQuizDetailSchema>;
export type AttemptFiltersInput = z.infer<typeof attemptFiltersSchema>;

const named: [z.ZodType, string][] = [
  [attemptStatusSchema, 'AttemptStatus'],
  [studentQuizSchema, 'StudentQuiz'],
  [studentQuizListSchema, 'StudentQuizList'],
  [attemptFiltersSchema, 'AttemptFilters'],
  [startAttemptBodySchema, 'StartAttemptRequest'],
  [attemptOptionSchema, 'AttemptOption'],
  [attemptQuestionSchema, 'AttemptQuestion'],
  [attemptSummarySchema, 'AttemptSummary'],
  [attemptSummaryPageSchema, 'AttemptSummaryPage'],
  [attemptSchema, 'Attempt'],
  [saveAnswerBodySchema, 'SaveAnswerRequest'],
  [checkAttemptAnswerBodySchema, 'CheckAttemptAnswerRequest'],
  [savedAnswerSchema, 'SavedAnswer'],
  [submitAnswerSchema, 'SubmitAnswer'],
  [submitAttemptBodySchema, 'SubmitAttemptRequest'],
  [adminQuizQuestionSchema, 'AdminQuizQuestion'],
  [adminQuizSchema, 'AdminQuiz'],
  [adminQuizListSchema, 'AdminQuizList'],
  [adminQuizDetailSchema, 'AdminQuizDetail'],
  [createQuizBodySchema, 'CreateQuizRequest'],
  [updateQuizBodySchema, 'UpdateQuizRequest'],
  [quizQuestionsBodySchema, 'QuizQuestionsRequest'],
];
for (const [schema, id] of named) z.globalRegistry.add(schema, { id });
