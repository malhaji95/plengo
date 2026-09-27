import type {
  AcademicYear,
  EducationLevel,
  Faculty,
  Lesson,
  Subject,
  SubjectOutline,
  University,
} from '@plengo/contracts';
import { AppError } from '../lib/app-error.js';
import type { StructureRepository, SubjectFilter } from '../repositories/structure-repository.js';
import type { UsersRepository } from '../repositories/users-repository.js';
import type { ObjectStorage } from '../storage/storage.js';
import { resolveCollegePath, type CollegePathInput } from './college-path.js';
import { toAcademicYear, toFaculty, toLesson, toSubject, toUnit, toUniversity } from './structure-mappers.js';

/**
 * What students browse (spec §8.9): every level is browsable regardless of the profile level; only
 * active, non-deleted nodes are shown. Access to content inside subjects arrives with Phase 4.
 */
export function createCatalogService(deps: {
  repo: StructureRepository;
  usersRepo: UsersRepository;
  storage: ObjectStorage;
}) {
  const { repo, usersRepo, storage } = deps;
  const notFound = (): never => {
    throw new AppError('NOT_FOUND');
  };

  async function visibleSubject(id: string) {
    return (await repo.getSubject(id, { studentVisible: true })) ?? notFound();
  }

  return {
    async levels(): Promise<EducationLevel[]> {
      return (await repo.listLevels()).map((l) => ({
        id: l.id,
        code: l.code,
        nameAr: l.nameAr,
        sortOrder: l.sortOrder,
        isCollege: l.code === 'college',
      }));
    },

    universities: async (): Promise<University[]> =>
      (await repo.listUniversities({ activeOnly: true })).map(toUniversity),

    async faculties(universityId: string): Promise<Faculty[]> {
      const university = await repo.getUniversity(universityId);
      if (!university?.isActive) notFound();
      return (await repo.listFaculties(universityId, { activeOnly: true })).map(toFaculty);
    },

    async academicYears(facultyId: string): Promise<AcademicYear[]> {
      const faculty = await repo.getFaculty(facultyId);
      if (!faculty?.isActive) notFound();
      const university = await repo.getUniversity(faculty!.universityId);
      if (!university?.isActive) notFound();
      return (await repo.listAcademicYears(facultyId, { activeOnly: true })).map(toAcademicYear);
    },

    async subjects(filter: SubjectFilter): Promise<Subject[]> {
      return (await repo.listSubjects(filter, { studentVisible: true })).map((r) => toSubject(r, storage));
    },

    async outline(subjectId: string): Promise<SubjectOutline> {
      const subject = await visibleSubject(subjectId);
      const [unitRows, lessonRows] = await Promise.all([
        repo.listUnits(subjectId),
        repo.listLessons(subjectId),
      ]);
      const lessons = lessonRows.map(toLesson);
      return {
        subject: toSubject(subject, storage),
        units: unitRows.map((u) => ({ ...toUnit(u), lessons: lessons.filter((l) => l.unitId === u.id) })),
        lessons: lessons.filter((l) => l.unitId === null),
      };
    },

    async unit(unitId: string) {
      const unit = (await repo.getUnit(unitId)) ?? notFound();
      await visibleSubject(unit.subjectId);
      return { ...toUnit(unit), lessons: (await repo.listLessons(unit.subjectId, unit.id)).map(toLesson) };
    },

    async lesson(lessonId: string): Promise<Lesson> {
      const lesson = (await repo.getLesson(lessonId)) ?? notFound();
      await visibleSubject(lesson.subjectId);
      return toLesson(lesson);
    },

    /** Profile level and college path only set defaults; they never restrict browsing (§8.9). */
    async updateProfile(
      userId: string,
      input: CollegePathInput & { fullName?: string | undefined; educationLevelId?: string | undefined },
    ) {
      const me = (await usersRepo.getMe(userId)) ?? notFound();
      const fields: Parameters<UsersRepository['updateProfile']>[1] = {};
      if (input.fullName) fields.fullName = input.fullName;

      const collegeGiven =
        input.universityId !== undefined ||
        input.facultyId !== undefined ||
        input.academicYearId !== undefined;
      const levelId = input.educationLevelId ?? me.educationLevelId;
      if (collegeGiven || (input.educationLevelId && input.educationLevelId !== me.educationLevelId)) {
        if (!levelId) throw new AppError('VALIDATION_ERROR', { details: { field: 'educationLevelId' } });
        const path = await resolveCollegePath(
          repo,
          levelId,
          collegeGiven
            ? {
                universityId: input.universityId ?? null,
                facultyId: input.facultyId ?? null,
                academicYearId: input.academicYearId ?? null,
              }
            : {},
          { requireActive: true },
        );
        Object.assign(fields, { educationLevelId: levelId, ...path });
      }
      if (Object.keys(fields).length) await usersRepo.updateProfile(userId, fields);
      return (await usersRepo.getMe(userId))!;
    },

    /** Validates a registration's optional level + college path before the account is created. */
    async validateRegistrationPath(levelId: string | undefined, input: CollegePathInput) {
      if (!levelId) {
        if (input.universityId || input.facultyId || input.academicYearId) {
          throw new AppError('VALIDATION_ERROR', { details: { field: 'educationLevelId' } });
        }
        return { universityId: null, facultyId: null, academicYearId: null };
      }
      return resolveCollegePath(repo, levelId, input, { requireActive: true });
    },
  };
}

export type CatalogService = ReturnType<typeof createCatalogService>;
