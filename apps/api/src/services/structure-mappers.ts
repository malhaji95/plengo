import type { AcademicYear, Faculty, Lesson, Subject, Unit, University } from '@plengo/contracts';
import type { academicYears, faculties, lessons, MediaVariants, units, universities } from '@plengo/db';
import type { SubjectRow } from '../repositories/structure-repository.js';
import type { ObjectStorage } from '../storage/storage.js';

type Row<T extends { $inferSelect: unknown }> = T['$inferSelect'];

export const toUniversity = (r: Row<typeof universities>): University => ({
  id: r.id,
  code: r.code,
  nameAr: r.nameAr,
  sortOrder: r.sortOrder,
  isActive: r.isActive,
});

export const toFaculty = (r: Row<typeof faculties>): Faculty => ({
  ...toUniversity(r),
  universityId: r.universityId,
});

export const toAcademicYear = (r: Row<typeof academicYears>): AcademicYear => ({
  ...toUniversity(r),
  facultyId: r.facultyId,
});

export const toUnit = (r: Row<typeof units>): Unit => ({
  id: r.id,
  subjectId: r.subjectId,
  code: r.code,
  titleAr: r.titleAr,
  sortOrder: r.sortOrder,
});

export const toLesson = (r: Row<typeof lessons>): Lesson => ({
  id: r.id,
  subjectId: r.subjectId,
  unitId: r.unitId,
  code: r.code,
  titleAr: r.titleAr,
  sortOrder: r.sortOrder,
});

/** Public images (covers, teacher photos) are served from the CDN (spec §12.1, §12.5). */
export function publicImageUrl(
  storage: ObjectStorage,
  variants: MediaVariants | null | undefined,
  status: string | null | undefined,
  variant: 'full' | 'thumb' = 'full',
): string | null {
  const v = status === 'ready' ? variants?.[variant] : undefined;
  return v ? storage.getPublicUrl(v.key) : null;
}

export function toSubject(r: SubjectRow, storage: ObjectStorage): Subject {
  return {
    id: r.id,
    educationLevelId: r.educationLevelId,
    universityId: r.universityId,
    facultyId: r.facultyId,
    academicYearId: r.academicYearId,
    code: r.code,
    nameAr: r.nameAr,
    description: r.description,
    coverMediaId: r.coverMediaId,
    coverUrl: publicImageUrl(storage, r.coverVariants, r.coverStatus),
    sortOrder: r.sortOrder,
    isActive: r.isActive,
  };
}
