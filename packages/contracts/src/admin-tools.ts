import { z } from 'zod';
import { questionTypeSchema } from './questions.js';

/* Admin productivity (spec §26.2, §27, §32): audit log, global search, question analytics, imports. */

const int = () => z.number().int();
const boolParam = z.enum(['true', 'false']).transform((v) => v === 'true');
const cursor = z.string().max(200).optional();

// ---- audit log (§32) ----

export const auditLogQuerySchema = z.object({
  actorAdminId: z.uuid().optional(),
  /** Exact action, or a prefix ending in "." (e.g. "coupon_batch."). */
  action: z.string().trim().max(100).optional(),
  resourceType: z.string().trim().max(100).optional(),
  resourceId: z.string().trim().max(100).optional(),
  /** Damascus calendar days, inclusive. */
  from: z.iso.date().optional(),
  to: z.iso.date().optional(),
  cursor,
  limit: z.coerce.number().int().min(1).max(200).default(50),
});

export const auditLogEntrySchema = z.object({
  id: z.string(),
  actorAdminId: z.string().nullable(),
  actorName: z.string().nullable(),
  actorEmail: z.string().nullable(),
  action: z.string(),
  resourceType: z.string(),
  resourceId: z.string().nullable(),
  metadata: z.record(z.string(), z.unknown()),
  createdAt: z.string(),
});

export const auditLogPageSchema = z.object({
  items: z.array(auditLogEntrySchema),
  nextCursor: z.string().nullable(),
});

// ---- global search (§26.2) ----

export const adminSearchQuerySchema = z.object({ q: z.string().trim().min(2).max(100) });

export const adminSearchHitTypeSchema = z.enum([
  'admin',
  'student',
  'teacher',
  'track',
  'subject',
  'question',
  'coupon',
  'batch',
]);

export const adminSearchHitSchema = z.object({
  type: adminSearchHitTypeSchema,
  id: z.string(),
  title: z.string(),
  subtitle: z.string().nullable(),
  /** Where the hit opens in the admin (e.g. the batch of a coupon, the subject of a unit). */
  parentId: z.string().nullable(),
});

export const adminSearchResultSchema = z.object({ items: z.array(adminSearchHitSchema) });

// ---- question analytics (§26.2) ----

export const questionAnalyticsSortSchema = z.enum(['attempts', 'correct', 'reports', 'mismatches', 'recent']);

export const questionAnalyticsQuerySchema = z.object({
  subjectId: z.uuid().optional(),
  teacherTrackId: z.uuid().optional(),
  flagged: boolParam.optional(),
  sort: questionAnalyticsSortSchema.default('attempts'),
  cursor,
  limit: z.coerce.number().int().min(1).max(200).default(50),
});

export const questionAnalyticsRowSchema = z.object({
  questionId: z.string(),
  type: questionTypeSchema,
  questionText: z.string(),
  status: z.enum(['draft', 'published', 'archived']),
  subjectId: z.string(),
  subjectNameAr: z.string(),
  teacherTrackId: z.string().nullable(),
  trackTitleAr: z.string().nullable(),
  attempts: int(),
  /** Null until the question has been answered. */
  correctPercent: z.number().nullable(),
  averageTimeMs: int().nullable(),
  flagged: z.boolean(),
  openReports: int(),
  /** Offline answers the device graded differently from the server (§22.6). */
  offlineMismatches: int(),
  lastAttemptAt: z.string().nullable(),
});

export const questionAnalyticsPageSchema = z.object({
  items: z.array(questionAnalyticsRowSchema),
  nextCursor: z.string().nullable(),
});

export const optionStatSchema = z.object({
  optionId: z.string(),
  text: z.string(),
  isCorrect: z.boolean(),
  count: int(),
  percent: z.number(),
});

export const questionAnalyticsDetailSchema = questionAnalyticsRowSchema.extend({
  options: z.array(optionStatSchema),
  /** Why the rule flagged it, when it did. */
  flagReasons: z.array(z.enum(['low_correct', 'wrong_option_preferred'])),
});

// ---- bulk import / export (§27) ----

export const importKindSchema = z.enum(['mcq', 'true_false', 'written']);
export const importFormatSchema = z.enum(['csv', 'xlsx']);
export const importStatusSchema = z.enum(['parsing', 'ready', 'failed', 'importing', 'completed']);

/** Files up to 5 MB, sent base64-encoded. */
export const IMPORT_MAX_BYTES = 5 * 1024 * 1024;
export const IMPORT_MAX_ROWS = 2000;

export const createImportBodySchema = z.object({
  kind: importKindSchema,
  format: importFormatSchema,
  fileName: z.string().trim().min(1).max(200),
  contentBase64: z
    .string()
    .min(1)
    .max(Math.ceil((IMPORT_MAX_BYTES * 4) / 3) + 4),
});

export const importErrorSchema = z.object({
  rowNumber: int(),
  field: z.string().nullable(),
  message: z.string(),
});

export const importPreviewRowSchema = z.object({
  rowNumber: int(),
  questionText: z.string(),
  subjectCode: z.string(),
  unitCode: z.string().nullable(),
  lessonCode: z.string().nullable(),
  teacherTrackCode: z.string().nullable(),
  /** Options (MCQ, true/false) or accepted answers (written), correct first for MCQ/TF. */
  answers: z.array(z.string()),
  isFree: z.boolean().nullable(),
});

export const importJobSchema = z.object({
  id: z.string(),
  kind: importKindSchema,
  format: importFormatSchema,
  fileName: z.string(),
  status: importStatusSchema,
  totalRows: int(),
  validRows: int(),
  errorCount: int(),
  failureReason: z.string().nullable(),
  /** First errors by row (up to 500). */
  errors: z.array(importErrorSchema),
  /** First valid rows as they will be imported (up to 50). */
  preview: z.array(importPreviewRowSchema),
  summary: z.object({ created: int(), published: z.boolean(), scopes: int() }).nullable(),
  createdAt: z.string(),
  completedAt: z.string().nullable(),
});

export const importJobListSchema = z.array(importJobSchema.omit({ errors: true, preview: true }));

export const confirmImportBodySchema = z.object({
  /** Publish the imported questions right away (free rules apply); otherwise they stay drafts. */
  publish: z.boolean().default(false),
});

export const importTemplateQuerySchema = z.object({ kind: importKindSchema, format: importFormatSchema });

export const questionExportQuerySchema = z.object({
  kind: importKindSchema,
  format: importFormatSchema,
  subjectId: z.uuid(),
  teacherTrackId: z.uuid().optional(),
});

// ---- flashcard bulk upload (§27) ----

/** Pairs appended to a deck in this order; free status stays a deck setting (§8.4). */
export const bulkCardsBodySchema = z.object({
  cards: z
    .array(
      z.object({
        frontMediaId: z.uuid(),
        backMediaId: z.uuid(),
      }),
    )
    .min(1)
    .max(300),
});

export type AuditLogEntry = z.infer<typeof auditLogEntrySchema>;
export type AdminSearchHit = z.infer<typeof adminSearchHitSchema>;
export type QuestionAnalyticsRow = z.infer<typeof questionAnalyticsRowSchema>;
export type ImportJob = z.infer<typeof importJobSchema>;
export type ImportPreviewRow = z.infer<typeof importPreviewRowSchema>;

// Query schemas stay unnamed: they become parameters, not components.
const named: [z.ZodType, string][] = [
  [auditLogEntrySchema, 'AuditLogEntry'],
  [auditLogPageSchema, 'AuditLogPage'],
  [adminSearchHitTypeSchema, 'AdminSearchHitType'],
  [adminSearchHitSchema, 'AdminSearchHit'],
  [adminSearchResultSchema, 'AdminSearchResult'],
  [questionAnalyticsSortSchema, 'QuestionAnalyticsSort'],
  [questionAnalyticsRowSchema, 'QuestionAnalyticsRow'],
  [questionAnalyticsPageSchema, 'QuestionAnalyticsPage'],
  [optionStatSchema, 'OptionStat'],
  [questionAnalyticsDetailSchema, 'QuestionAnalyticsDetail'],
  [importKindSchema, 'ImportKind'],
  [importFormatSchema, 'ImportFormat'],
  [importStatusSchema, 'ImportStatus'],
  [createImportBodySchema, 'CreateImportRequest'],
  [importErrorSchema, 'ImportError'],
  [importPreviewRowSchema, 'ImportPreviewRow'],
  [importJobSchema, 'ImportJob'],
  [importJobListSchema, 'ImportJobList'],
  [confirmImportBodySchema, 'ConfirmImportRequest'],
  [bulkCardsBodySchema, 'BulkCardsRequest'],
];
for (const [schema, id] of named) z.globalRegistry.add(schema, { id });
