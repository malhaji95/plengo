import { z } from 'zod';

/*
 * Question categories (v3 §3, §5): «علل», «قارن», «عرّف»… A category without a subject is global and
 * applies to every subject; a subject may add its own. Categories may have children (`parentId`).
 */

const int = () => z.number().int();
const code = z
  .string()
  .trim()
  .min(1)
  .max(60)
  .regex(/^[a-z0-9][a-z0-9_-]*$/);

export const adminQuestionCategorySchema = z.object({
  id: z.string(),
  /** Null: a global category, usable in every subject. */
  subjectId: z.string().nullable(),
  subjectNameAr: z.string().nullable(),
  parentId: z.string().nullable(),
  code: z.string(),
  nameAr: z.string(),
  sortOrder: int(),
  /** Live questions (any status) filed under this category itself (children not included). */
  questionCount: int(),
  createdAt: z.string(),
  updatedAt: z.string(),
});
export const adminQuestionCategoryListSchema = z.array(adminQuestionCategorySchema);

const boolParam = z.enum(['true', 'false']).transform((v) => v === 'true');

export const adminQuestionCategoryQuerySchema = z.object({
  /** With a subject: its own categories plus the global ones (unless `subjectOnly`). */
  subjectId: z.uuid().optional(),
  /** Only the global categories. */
  globalOnly: boolParam.optional(),
  /** With `subjectId`: leave out the global categories. */
  subjectOnly: boolParam.optional(),
});

export const createQuestionCategoryBodySchema = z.object({
  /** Null or omitted: a global category. Fixed at creation. */
  subjectId: z.uuid().nullable().optional(),
  parentId: z.uuid().nullable().optional(),
  code,
  nameAr: z.string().trim().min(1).max(100),
  sortOrder: int().min(0).max(100_000).optional(),
});

export const updateQuestionCategoryBodySchema = z
  .object({
    parentId: z.uuid().nullable(),
    code,
    nameAr: z.string().trim().min(1).max(100),
    sortOrder: int().min(0).max(100_000),
  })
  .partial();

// ---- student ----

export const studentQuestionCategorySchema = z.object({
  id: z.string(),
  subjectId: z.string().nullable(),
  parentId: z.string().nullable(),
  code: z.string(),
  nameAr: z.string(),
  sortOrder: int(),
  /** Published questions of this category itself in the requested scope and placement. */
  questionCount: int(),
  /** Of those, the ones the student can open now. */
  accessibleCount: int(),
});

export const studentQuestionCategoryListSchema = z.object({
  /** Global categories and the subject's own, parents before their children, in sort order. */
  items: z.array(studentQuestionCategorySchema),
  /** Published questions with no category in the same scope and placement. */
  uncategorized: z.object({ questionCount: int(), accessibleCount: int() }),
});

export const studentQuestionCategoryQuerySchema = z.object({
  subjectId: z.uuid(),
  /** Omitted: the subject's general questions. Set: that track's questions (§8.1). */
  teacherTrackId: z.uuid().optional(),
  /** Counts only for this unit or lesson (the lesson page groups its questions by category). */
  unitId: z.uuid().optional(),
  lessonId: z.uuid().optional(),
});

export type AdminQuestionCategory = z.infer<typeof adminQuestionCategorySchema>;
export type StudentQuestionCategory = z.infer<typeof studentQuestionCategorySchema>;
export type StudentQuestionCategoryList = z.infer<typeof studentQuestionCategoryListSchema>;

const named: [z.ZodType, string][] = [
  [adminQuestionCategorySchema, 'AdminQuestionCategory'],
  [adminQuestionCategoryListSchema, 'AdminQuestionCategoryList'],
  [createQuestionCategoryBodySchema, 'CreateQuestionCategoryRequest'],
  [updateQuestionCategoryBodySchema, 'UpdateQuestionCategoryRequest'],
  [studentQuestionCategorySchema, 'StudentQuestionCategory'],
  [studentQuestionCategoryListSchema, 'StudentQuestionCategoryList'],
];
for (const [schema, id] of named) z.globalRegistry.add(schema, { id });
