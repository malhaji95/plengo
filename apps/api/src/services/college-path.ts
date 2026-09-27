import { AppError } from '../lib/app-error.js';
import type { StructureRepository } from '../repositories/structure-repository.js';

export interface CollegePathInput {
  universityId?: string | null | undefined;
  facultyId?: string | null | undefined;
  academicYearId?: string | null | undefined;
}

export interface CollegePath {
  universityId: string | null;
  facultyId: string | null;
  academicYearId: string | null;
}

const EMPTY: CollegePath = { universityId: null, facultyId: null, academicYearId: null };

function invalid(field: string, reason: string): never {
  throw new AppError('VALIDATION_ERROR', { details: { field, reason } });
}

/**
 * Normalizes an optional University → Faculty → Academic Year selection (spec §6). The deepest
 * given layer wins and the layers above it are derived from it; any layer that was also given must
 * agree. Only the college level may carry these layers. `requireActive` is used for student choices;
 * admins may attach subjects to inactive (not yet published) nodes.
 */
export async function resolveCollegePath(
  repo: StructureRepository,
  levelId: string,
  input: CollegePathInput,
  opts: { requireActive: boolean },
): Promise<CollegePath> {
  const level = await repo.getLevel(levelId);
  if (!level) invalid('educationLevelId', 'not_found');
  const given = input.universityId ?? input.facultyId ?? input.academicYearId ?? null;
  if (level.code !== 'college') {
    if (given) invalid('universityId', 'college_only');
    return EMPTY;
  }

  const usable = (row: { isActive: boolean } | null) => row && (!opts.requireActive || row.isActive);
  let path: CollegePath = { ...EMPTY };

  if (input.academicYearId) {
    const year = await repo.getAcademicYear(input.academicYearId);
    if (!usable(year)) invalid('academicYearId', 'not_found');
    path = { ...path, academicYearId: year!.id, facultyId: year!.facultyId };
  }
  const facultyId = path.facultyId ?? input.facultyId ?? null;
  if (facultyId) {
    if (input.facultyId && input.facultyId !== facultyId) invalid('facultyId', 'mismatch');
    const faculty = await repo.getFaculty(facultyId);
    if (!usable(faculty)) invalid('facultyId', 'not_found');
    path = { ...path, facultyId: faculty!.id, universityId: faculty!.universityId };
  }
  const universityId = path.universityId ?? input.universityId ?? null;
  if (universityId) {
    if (input.universityId && input.universityId !== universityId) invalid('universityId', 'mismatch');
    const university = await repo.getUniversity(universityId);
    if (!usable(university)) invalid('universityId', 'not_found');
    path = { ...path, universityId: university!.id };
  }
  return path;
}
