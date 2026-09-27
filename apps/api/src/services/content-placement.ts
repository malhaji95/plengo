import { AppError } from '../lib/app-error.js';
import type { StructureRepository } from '../repositories/structure-repository.js';
import type { TeacherRepository } from '../repositories/teacher-repository.js';

/*
 * Placement rules shared by questions, flashcard decks and (Phase 7) quizzes: a content item belongs to
 * a subject, optionally one track of that subject, and optionally a unit/lesson of that subject
 * (spec §6.1, §7.3). The database enforces the same through composite keys.
 */

export const invalid = (field: string, reason?: string): never => {
  throw new AppError('VALIDATION_ERROR', { details: reason ? { field, reason } : { field } });
};

/** The subject exists (not deleted) and the track, if any, belongs to it. */
export async function validateContentScope(
  deps: { structureRepo: StructureRepository; teacherRepo: TeacherRepository },
  subjectId: string,
  teacherTrackId: string | null,
) {
  const subject = await deps.structureRepo.getSubject(subjectId, { studentVisible: false });
  if (!subject) invalid('subjectId');
  if (teacherTrackId) {
    const track = await deps.teacherRepo.getTrack(teacherTrackId, { visibleOnly: false });
    if (!track || track.subjectId !== subjectId) invalid('teacherTrackId');
  }
}

/** Unit and lesson belong to the subject; a lesson inside a unit implies that unit. */
export async function resolvePlacement(
  structureRepo: StructureRepository,
  subjectId: string,
  unitId: string | null,
  lessonId: string | null,
) {
  if (unitId) {
    const unit = await structureRepo.getUnit(unitId);
    if (!unit || unit.subjectId !== subjectId) invalid('unitId');
  }
  if (lessonId) {
    const lesson = await structureRepo.getLesson(lessonId);
    if (!lesson || lesson.subjectId !== subjectId) invalid('lessonId');
    if (unitId && lesson!.unitId !== unitId) invalid('lessonId', 'unit_mismatch');
    if (!unitId) unitId = lesson!.unitId;
  }
  return { unitId, lessonId };
}

/** Student-side: the item's subject and track are visible; otherwise the item does not exist. */
export async function assertVisibleScope(
  deps: { structureRepo: StructureRepository; teacherRepo: TeacherRepository },
  subjectId: string,
  teacherTrackId: string | null,
) {
  const subject = await deps.structureRepo.getSubject(subjectId, { studentVisible: true });
  if (!subject) throw new AppError('NOT_FOUND');
  if (teacherTrackId) {
    const track = await deps.teacherRepo.getTrack(teacherTrackId, { visibleOnly: true });
    if (!track || track.subjectId !== subjectId) throw new AppError('NOT_FOUND');
  }
}
