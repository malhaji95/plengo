import { z } from 'zod';
import { IMPORT_MAX_BYTES, importErrorSchema, importFormatSchema } from './admin-tools.js';
import { cardImageSchema } from './flashcards.js';
import { contentStatusSchema, uuidListParam } from './questions.js';

/*
 * «رسمات العلوم» (v3 §9): a diagram is an image with numbered parts; the student types the name of
 * each part. Placement, access scope, free flags and status work like questions (spec §8, §14).
 * Student payloads never carry the accepted answers before a check.
 */

const int = () => z.number().int();
const coordinate = z.number().min(0).max(1);

/** Diagrams of one practice session at most; «−/+» in the app stays within it. */
export const DIAGRAM_PRACTICE_MAX = 50;
export const DIAGRAM_LABELS_MAX = 50;
export const DIAGRAM_ANSWERS_MAX = 10;

// ---- student ----

export const studentDiagramSchema = z.object({
  id: z.string(),
  subjectId: z.string(),
  teacherTrackId: z.string().nullable(),
  unitId: z.string().nullable(),
  lessonId: z.string().nullable(),
  titleAr: z.string(),
  labelCount: int(),
  isFree: z.boolean(),
  /** The student cannot practise it (no access): show the lock; practice skips it. */
  locked: z.boolean(),
  sortOrder: int(),
});

export const diagramListQuerySchema = z.object({
  subjectId: z.uuid(),
  /** Omitted: the subject's general diagrams. Set: that track's (§8.1). */
  teacherTrackId: z.uuid().optional(),
  /** «وحدة كاملة»: every diagram of the unit, its lessons included. */
  unitId: z.uuid().optional(),
  /** «عدة دروس» / «درس واحد»: comma-separated lesson ids. */
  lessonIds: uuidListParam.optional(),
});

export const studentDiagramListSchema = z.object({
  items: z.array(studentDiagramSchema),
  totalCount: int(),
  /** Diagrams the student can practise now. */
  accessibleCount: int(),
  lockedCount: int(),
});

/** A label without its answers: the number to name and an optional marker position. */
export const practiceDiagramLabelSchema = z.object({
  id: z.string(),
  number: int(),
  /** 0..1 of the image width / height, measured from the top-left; null when the image is numbered. */
  x: z.number().nullable(),
  y: z.number().nullable(),
});

export const practiceDiagramSchema = z.object({
  id: z.string(),
  subjectId: z.string(),
  unitId: z.string().nullable(),
  lessonId: z.string().nullable(),
  titleAr: z.string(),
  image: cardImageSchema,
  /** In number order. */
  labels: z.array(practiceDiagramLabelSchema),
  contentVersion: int(),
});

export const diagramPracticeBodySchema = z.object({
  subjectId: z.uuid(),
  teacherTrackId: z.uuid().nullable().optional(),
  /** «وحدة كاملة». */
  unitId: z.uuid().nullable().optional(),
  /** «عدة دروس» / «درس واحد». Neither unit nor lessons: the whole subject. */
  lessonIds: z.array(z.uuid()).max(100).optional(),
  count: int().min(1).max(DIAGRAM_PRACTICE_MAX),
});

export const diagramPracticeSchema = z.object({
  /** Up to `count` random accessible diagrams of the scope (fewer when the scope has fewer). */
  diagrams: z.array(practiceDiagramSchema),
  /** Accessible diagrams in the scope (the most the student can ask for). */
  availableCount: int(),
  /** Locked diagrams left out. */
  lockedCount: int(),
  /** When the signed image URLs stop working. */
  urlsExpireAt: z.string(),
});

export const checkDiagramBodySchema = z.object({
  /** One entry per label the student answered; missing labels count as wrong. */
  answers: z.array(z.object({ number: int().min(1), answer: z.string().max(300) })).max(DIAGRAM_LABELS_MAX),
});

export const diagramLabelResultSchema = z.object({
  labelId: z.string(),
  number: int(),
  /** What the student sent, or null when the label was left empty. */
  answer: z.string().nullable(),
  isCorrect: z.boolean(),
  /** Every accepted answer as the admin wrote it; the first is the model answer. */
  acceptedAnswers: z.array(z.string()),
});

export const diagramCheckResultSchema = z.object({
  diagramId: z.string(),
  correctCount: int(),
  totalCount: int(),
  labels: z.array(diagramLabelResultSchema),
});

// ---- admin ----

export const adminDiagramLabelSchema = z.object({
  id: z.string(),
  number: int(),
  x: z.number().nullable(),
  y: z.number().nullable(),
  answers: z.array(z.string()),
  sortOrder: int(),
});

export const adminDiagramSchema = z.object({
  id: z.string(),
  subjectId: z.string(),
  subjectNameAr: z.string(),
  teacherTrackId: z.string().nullable(),
  trackTitleAr: z.string().nullable(),
  unitId: z.string().nullable(),
  lessonId: z.string().nullable(),
  titleAr: z.string(),
  description: z.string().nullable(),
  imageMediaId: z.string(),
  /** Signed preview URLs; null while the image is not processed. */
  image: cardImageSchema.nullable(),
  isFree: z.boolean(),
  freeSource: z.enum(['rule', 'manual_override']),
  status: contentStatusSchema,
  sortOrder: int(),
  contentVersion: int(),
  labels: z.array(adminDiagramLabelSchema),
  createdAt: z.string(),
  updatedAt: z.string(),
});

export const adminDiagramPageSchema = z.object({
  items: z.array(adminDiagramSchema),
  nextCursor: z.string().nullable(),
  totalCount: int(),
});

const boolParam = z.enum(['true', 'false']).transform((v) => v === 'true');

export const adminDiagramQuerySchema = z.object({
  subjectId: z.uuid().optional(),
  teacherTrackId: z.uuid().optional(),
  generalOnly: boolParam.optional(),
  unitId: z.uuid().optional(),
  lessonId: z.uuid().optional(),
  status: contentStatusSchema.optional(),
  /** Searches the title and the answers. */
  q: z.string().trim().max(200).optional(),
  cursor: z.string().max(200).optional(),
  limit: z.coerce.number().int().min(1).max(200).default(50),
});

/** Labels in display order; numbers are unique within the diagram. */
export const diagramLabelInputSchema = z.object({
  number: int().min(1).max(999),
  x: coordinate.nullable().optional(),
  y: coordinate.nullable().optional(),
  answers: z.array(z.string().trim().min(1).max(300)).min(1).max(DIAGRAM_ANSWERS_MAX),
});

const diagramContentShape = {
  unitId: z.uuid().nullable().optional(),
  lessonId: z.uuid().nullable().optional(),
  titleAr: z.string().trim().min(1).max(300),
  description: z.string().trim().max(2000).nullable().optional(),
  /** An uploaded, processed image (upload kind `flashcard`). */
  imageMediaId: z.uuid(),
  labels: z.array(diagramLabelInputSchema).min(1).max(DIAGRAM_LABELS_MAX),
};

/** The subject and track are fixed at creation: they decide the access scope. */
export const createDiagramBodySchema = z.object({
  subjectId: z.uuid(),
  teacherTrackId: z.uuid().nullable().optional(),
  ...diagramContentShape,
  publish: z.boolean().optional(),
});

export const updateDiagramBodySchema = z.object(diagramContentShape).partial();

export const diagramImportBodySchema = z.object({
  format: importFormatSchema,
  fileName: z.string().trim().min(1).max(200),
  contentBase64: z
    .string()
    .min(1)
    .max(Math.ceil((IMPORT_MAX_BYTES * 4) / 3) + 4),
  /**
   * Uploaded images by the file name used in the `image_file` column. A dry run may omit it (or
   * name only the files the admin picked, with any id): it reports the files the sheet needs.
   */
  images: z.record(z.string().max(300), z.uuid()).optional(),
  /** Validate and preview only; nothing is created. */
  dryRun: z.boolean(),
  /** Publish the created diagrams (otherwise drafts). */
  publish: z.boolean().optional(),
});

export const diagramImportPreviewSchema = z.object({
  ref: z.string(),
  titleAr: z.string(),
  subjectCode: z.string(),
  unitCode: z.string().nullable(),
  lessonCode: z.string().nullable(),
  teacherTrackCode: z.string().nullable(),
  imageFile: z.string(),
  labels: z.array(z.object({ number: int(), answers: z.array(z.string()) })),
});

export const diagramImportResultSchema = z.object({
  dryRun: z.boolean(),
  totalRows: int(),
  diagrams: z.array(diagramImportPreviewSchema),
  /** Every image file the sheet references. */
  requiredImages: z.array(z.string()),
  /** Referenced files with no uploaded image in `images`. */
  missingImages: z.array(z.string()),
  errors: z.array(importErrorSchema),
  /** Ids of the created diagrams (empty for a dry run or when there were errors). */
  createdIds: z.array(z.string()),
});

export const diagramImportTemplateQuerySchema = z.object({ format: importFormatSchema });

export type StudentDiagram = z.infer<typeof studentDiagramSchema>;
export type PracticeDiagram = z.infer<typeof practiceDiagramSchema>;
export type DiagramCheckResult = z.infer<typeof diagramCheckResultSchema>;
export type AdminDiagram = z.infer<typeof adminDiagramSchema>;
export type DiagramImportResult = z.infer<typeof diagramImportResultSchema>;

const named: [z.ZodType, string][] = [
  [studentDiagramSchema, 'StudentDiagram'],
  [studentDiagramListSchema, 'StudentDiagramList'],
  [practiceDiagramLabelSchema, 'PracticeDiagramLabel'],
  [practiceDiagramSchema, 'PracticeDiagram'],
  [diagramPracticeBodySchema, 'DiagramPracticeRequest'],
  [diagramPracticeSchema, 'DiagramPractice'],
  [checkDiagramBodySchema, 'CheckDiagramRequest'],
  [diagramLabelResultSchema, 'DiagramLabelResult'],
  [diagramCheckResultSchema, 'DiagramCheckResult'],
  [adminDiagramLabelSchema, 'AdminDiagramLabel'],
  [adminDiagramSchema, 'AdminDiagram'],
  [adminDiagramPageSchema, 'AdminDiagramPage'],
  [diagramLabelInputSchema, 'DiagramLabelInput'],
  [createDiagramBodySchema, 'CreateDiagramRequest'],
  [updateDiagramBodySchema, 'UpdateDiagramRequest'],
  [diagramImportBodySchema, 'DiagramImportRequest'],
  [diagramImportPreviewSchema, 'DiagramImportPreview'],
  [diagramImportResultSchema, 'DiagramImportResult'],
];
for (const [schema, id] of named) z.globalRegistry.add(schema, { id });
