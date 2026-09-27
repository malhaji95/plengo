import { z } from 'zod';
import { scopeAccessSchema } from './access.js';

/*
 * Education structure (spec §6). Codes are the stable identifiers used by bulk import (§27):
 * lowercase latin letters, digits, '-' and '_'.
 */

export const codeSchema = z
  .string()
  .trim()
  .toLowerCase()
  .pipe(
    z
      .string()
      .min(1)
      .max(64)
      .regex(/^[a-z0-9]+(?:[-_][a-z0-9]+)*$/),
  );
const nameAr = z.string().trim().min(1).max(200);
const sortOrder = z.number().int().min(0).max(1_000_000);

export const universitySchema = z.object({
  id: z.string(),
  code: z.string(),
  nameAr: z.string(),
  sortOrder: z.number(),
  isActive: z.boolean(),
});
export const facultySchema = universitySchema.extend({ universityId: z.string() });
export const academicYearSchema = universitySchema.extend({ facultyId: z.string() });

export const subjectSchema = z.object({
  id: z.string(),
  educationLevelId: z.string(),
  universityId: z.string().nullable(),
  facultyId: z.string().nullable(),
  academicYearId: z.string().nullable(),
  code: z.string(),
  nameAr: z.string(),
  description: z.string().nullable(),
  coverMediaId: z.string().nullable(),
  coverUrl: z.string().nullable(),
  sortOrder: z.number(),
  isActive: z.boolean(),
});

export const unitSchema = z.object({
  id: z.string(),
  subjectId: z.string(),
  code: z.string(),
  titleAr: z.string(),
  sortOrder: z.number(),
});

export const lessonSchema = z.object({
  id: z.string(),
  subjectId: z.string(),
  unitId: z.string().nullable(),
  code: z.string(),
  titleAr: z.string(),
  sortOrder: z.number(),
});

export const unitWithLessonsSchema = unitSchema.extend({ lessons: z.array(lessonSchema) });

/** A track as listed under its subject (spec §23.2 #10: general content + teacher tracks). */
export const subjectTrackSchema = z.object({
  id: z.string(),
  teacherId: z.string(),
  teacherNameAr: z.string(),
  teacherPhotoUrl: z.string().nullable(),
  titleAr: z.string(),
  description: z.string().nullable(),
  coverUrl: z.string().nullable(),
  /** Whether the student can open this track's premium content (entitlement or promotion). */
  hasAccess: z.boolean(),
});

/**
 * A subject with its units (each with its lessons), the lessons that sit directly under it, and the
 * teacher tracks within it.
 */
export const subjectOutlineSchema = z.object({
  subject: subjectSchema,
  units: z.array(unitWithLessonsSchema),
  lessons: z.array(lessonSchema),
  tracks: z.array(subjectTrackSchema),
  /** Access to the subject's general content (not its tracks, §8.1). */
  access: scopeAccessSchema,
});

export const universityListSchema = z.array(universitySchema);
export const facultyListSchema = z.array(facultySchema);
export const academicYearListSchema = z.array(academicYearSchema);
export const subjectListSchema = z.array(subjectSchema);
export const unitListSchema = z.array(unitSchema);
export const lessonListSchema = z.array(lessonSchema);

// ---- queries ----

export const subjectListQuerySchema = z.object({
  levelId: z.uuid().optional(),
  universityId: z.uuid().optional(),
  facultyId: z.uuid().optional(),
  academicYearId: z.uuid().optional(),
});
export const universityIdQuerySchema = z.object({ universityId: z.uuid() });
export const facultyIdQuerySchema = z.object({ facultyId: z.uuid() });
export const subjectIdQuerySchema = z.object({ subjectId: z.uuid() });
export const lessonListQuerySchema = z.object({ subjectId: z.uuid(), unitId: z.uuid().optional() });

// ---- admin requests ----

export const updateLevelBodySchema = z.object({ nameAr: nameAr.optional(), sortOrder: sortOrder.optional() });

export const createUniversityBodySchema = z.object({
  code: codeSchema,
  nameAr,
  isActive: z.boolean().optional(),
});
export const updateUniversityBodySchema = createUniversityBodySchema.partial();

export const createFacultyBodySchema = createUniversityBodySchema.extend({ universityId: z.uuid() });
export const updateFacultyBodySchema = createUniversityBodySchema.partial();

export const createAcademicYearBodySchema = createUniversityBodySchema.extend({ facultyId: z.uuid() });
export const updateAcademicYearBodySchema = createUniversityBodySchema.partial();

export const createSubjectBodySchema = z.object({
  educationLevelId: z.uuid(),
  universityId: z.uuid().nullable().optional(),
  facultyId: z.uuid().nullable().optional(),
  academicYearId: z.uuid().nullable().optional(),
  code: codeSchema,
  nameAr,
  description: z.string().trim().max(2000).nullable().optional(),
  coverMediaId: z.uuid().nullable().optional(),
  isActive: z.boolean().optional(),
});
export const updateSubjectBodySchema = createSubjectBodySchema.partial();

export const createUnitBodySchema = z.object({ subjectId: z.uuid(), code: codeSchema, titleAr: nameAr });
export const updateUnitBodySchema = z.object({ code: codeSchema.optional(), titleAr: nameAr.optional() });

export const createLessonBodySchema = z.object({
  subjectId: z.uuid(),
  unitId: z.uuid().nullable().optional(),
  code: codeSchema,
  titleAr: nameAr,
});
export const updateLessonBodySchema = z.object({
  unitId: z.uuid().nullable().optional(),
  code: codeSchema.optional(),
  titleAr: nameAr.optional(),
});

/** New order of all live siblings, first to last. */
export const reorderBodySchema = z.object({ ids: z.array(z.uuid()).min(1).max(500) });
export const deletedSchema = z.object({ deleted: z.boolean() });
export const reorderedSchema = z.object({ reordered: z.boolean() });

export type University = z.infer<typeof universitySchema>;
export type Faculty = z.infer<typeof facultySchema>;
export type AcademicYear = z.infer<typeof academicYearSchema>;
export type Subject = z.infer<typeof subjectSchema>;
export type Unit = z.infer<typeof unitSchema>;
export type Lesson = z.infer<typeof lessonSchema>;
export type SubjectOutline = z.infer<typeof subjectOutlineSchema>;

const named: [z.ZodType, string][] = [
  [universitySchema, 'University'],
  [facultySchema, 'Faculty'],
  [academicYearSchema, 'AcademicYear'],
  [subjectSchema, 'Subject'],
  [unitSchema, 'Unit'],
  [lessonSchema, 'Lesson'],
  [unitWithLessonsSchema, 'UnitWithLessons'],
  [subjectTrackSchema, 'SubjectTrack'],
  [subjectOutlineSchema, 'SubjectOutline'],
  [universityListSchema, 'UniversityList'],
  [facultyListSchema, 'FacultyList'],
  [academicYearListSchema, 'AcademicYearList'],
  [subjectListSchema, 'SubjectList'],
  [unitListSchema, 'UnitList'],
  [lessonListSchema, 'LessonList'],
  [updateLevelBodySchema, 'UpdateLevelRequest'],
  [createUniversityBodySchema, 'CreateUniversityRequest'],
  [updateUniversityBodySchema, 'UpdateUniversityRequest'],
  [createFacultyBodySchema, 'CreateFacultyRequest'],
  [updateFacultyBodySchema, 'UpdateFacultyRequest'],
  [createAcademicYearBodySchema, 'CreateAcademicYearRequest'],
  [updateAcademicYearBodySchema, 'UpdateAcademicYearRequest'],
  [createSubjectBodySchema, 'CreateSubjectRequest'],
  [updateSubjectBodySchema, 'UpdateSubjectRequest'],
  [createUnitBodySchema, 'CreateUnitRequest'],
  [updateUnitBodySchema, 'UpdateUnitRequest'],
  [createLessonBodySchema, 'CreateLessonRequest'],
  [updateLessonBodySchema, 'UpdateLessonRequest'],
  [reorderBodySchema, 'ReorderRequest'],
  [deletedSchema, 'DeletedResult'],
  [reorderedSchema, 'ReorderedResult'],
];
for (const [schema, id] of named) z.globalRegistry.add(schema, { id });
