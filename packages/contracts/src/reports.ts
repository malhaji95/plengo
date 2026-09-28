import { z } from 'zod';

/* Content problem reports, "إبلاغ عن مشكلة" (spec §21). */

export const REPORTS_PER_DAY = 20;

export const reportItemTypeSchema = z.enum(['question', 'flashcard']);
export const reportReasonSchema = z.enum(['wrong_answer', 'typo', 'unclear', 'image_problem', 'other']);
export const reportStatusSchema = z.enum(['open', 'resolved', 'dismissed']);

export const createReportBodySchema = z.object({
  itemType: reportItemTypeSchema,
  itemId: z.uuid(),
  reason: reportReasonSchema,
  note: z.string().trim().max(500).nullable().optional(),
});

export const reportSchema = z.object({
  id: z.string(),
  itemType: reportItemTypeSchema,
  itemId: z.string(),
  reason: reportReasonSchema,
  note: z.string().nullable(),
  status: reportStatusSchema,
  createdAt: z.string(),
  resolvedAt: z.string().nullable(),
});

export const reportListSchema = z.array(reportSchema);

export const adminReportSchema = reportSchema.extend({
  studentId: z.string(),
  studentName: z.string(),
  studentEmail: z.string(),
  resolutionNote: z.string().nullable(),
  resolvedByAdminId: z.string().nullable(),
  /** Short description of the reported item for the inbox list. */
  itemTitleAr: z.string().nullable(),
  subjectId: z.string().nullable(),
  subjectNameAr: z.string().nullable(),
  /** For flashcards: the deck to open for editing ("jump to edit"). */
  deckId: z.string().nullable(),
  /** Open reports on the same item, this one included. */
  openReportsOnItem: z.number().int(),
});

export const adminReportPageSchema = z.object({
  items: z.array(adminReportSchema),
  nextCursor: z.string().nullable(),
});

export const adminReportQuerySchema = z.object({
  status: reportStatusSchema.optional(),
  itemType: reportItemTypeSchema.optional(),
  reason: reportReasonSchema.optional(),
  cursor: z.string().max(200).optional(),
  limit: z.coerce.number().int().min(1).max(200).default(50),
});

export const resolveReportBodySchema = z.object({
  status: z.enum(['resolved', 'dismissed']),
  resolutionNote: z.string().trim().max(1000).nullable().optional(),
  /** Tell the student in their inbox that the report was handled (§21). */
  notifyStudent: z.boolean().optional(),
});

export type Report = z.infer<typeof reportSchema>;
export type AdminReport = z.infer<typeof adminReportSchema>;

const named: [z.ZodType, string][] = [
  [reportItemTypeSchema, 'ReportItemType'],
  [reportReasonSchema, 'ReportReason'],
  [reportStatusSchema, 'ReportStatus'],
  [createReportBodySchema, 'CreateReportRequest'],
  [reportSchema, 'Report'],
  [reportListSchema, 'ReportList'],
  [adminReportSchema, 'AdminReport'],
  [adminReportPageSchema, 'AdminReportPage'],
  [resolveReportBodySchema, 'ResolveReportRequest'],
];
for (const [schema, id] of named) z.globalRegistry.add(schema, { id });
