import type { AcademicYear, Faculty, Lesson, Subject, Unit, University } from '@plengo/contracts';
import type { Db } from '@plengo/db';
import { AppError } from '../lib/app-error.js';
import type {
  OrderedTableName,
  SiblingScope,
  StructureRepository,
} from '../repositories/structure-repository.js';
import type { ObjectStorage } from '../storage/storage.js';
import type { AuditService } from './audit-service.js';
import { resolveCollegePath, type CollegePathInput } from './college-path.js';
import { toAcademicYear, toFaculty, toLesson, toSubject, toUnit, toUniversity } from './structure-mappers.js';

export interface AdminActor {
  adminId: string;
  ip: string | null;
}

type Patch<T> = { [K in keyof T]?: T[K] | undefined };

/** Postgres unique violation on a `*_code_live_idx` index → CODE_TAKEN. */
function rethrowCodeTaken(err: unknown): never {
  const pg = ((err as { cause?: unknown }).cause ?? err) as { code?: string; constraint?: string };
  if (pg.code === '23505' && pg.constraint?.endsWith('_code_live_idx')) throw new AppError('CODE_TAKEN');
  throw err;
}

async function guardCode<T>(op: () => Promise<T>): Promise<T> {
  try {
    return await op();
  } catch (err) {
    rethrowCodeTaken(err);
  }
}

const RESOURCE: Record<OrderedTableName, string> = {
  universities: 'university',
  faculties: 'faculty',
  academicYears: 'academic_year',
  subjects: 'subject',
  units: 'unit',
  lessons: 'lesson',
};

/**
 * Admin management of the education structure (spec §6, §26.2). Deletes are soft and are refused
 * while live children exist; every change is audited (spec §32).
 */
export function createStructureService(deps: {
  db: Db;
  repo: StructureRepository;
  audit: AuditService;
  storage: ObjectStorage;
}) {
  const { db, repo, audit, storage } = deps;

  const record = (actor: AdminActor, name: OrderedTableName, verb: string, id: string, metadata = {}) =>
    audit.record({
      actorAdminId: actor.adminId,
      action: `structure.${RESOURCE[name]}.${verb}`,
      resourceType: RESOURCE[name],
      resourceId: id,
      metadata,
      ip: actor.ip,
    });

  function notFound(): never {
    throw new AppError('NOT_FOUND');
  }

  async function create<N extends OrderedTableName>(
    actor: AdminActor,
    name: N,
    scope: SiblingScope,
    values: Parameters<StructureRepository['insertRow']>[1],
  ) {
    const row = await guardCode(() =>
      db.transaction(async (tx) => {
        const sortOrder = await repo.nextSortOrder(name, scope, tx);
        return repo.insertRow(name, { ...values, sortOrder } as never, tx);
      }),
    );
    await record(actor, name, 'created', row.id, { code: (row as { code: string }).code });
    return row as ReturnType<StructureRepository['insertRow']> extends Promise<infer R> ? R : never;
  }

  async function update<N extends OrderedTableName>(
    actor: AdminActor,
    name: N,
    id: string,
    values: Record<string, unknown>,
  ) {
    const row = await guardCode(() => repo.updateRow(name, id, values as never));
    if (!row) notFound();
    await record(actor, name, 'updated', id, { fields: Object.keys(values) });
    return row;
  }

  async function remove(actor: AdminActor, name: OrderedTableName, id: string) {
    if (name !== 'lessons' && (await repo.isInUse(name, id))) throw new AppError('RESOURCE_IN_USE');
    if (!(await repo.softDelete(name, id))) notFound();
    await record(actor, name, 'deleted', id);
    return { deleted: true };
  }

  /** `ids` must be exactly the live siblings of one scope, in their new order. */
  async function reorder(actor: AdminActor, name: OrderedTableName, ids: string[]) {
    if (new Set(ids).size !== ids.length)
      throw new AppError('VALIDATION_ERROR', { details: { reason: 'duplicate_ids' } });
    await db.transaction(async (tx) => {
      const scopes = await repo.scopesOf(name, ids, tx);
      if (scopes.length !== ids.length) notFound();
      const scope = scopes[0]!;
      const key = JSON.stringify(scope);
      if (scopes.some((s) => JSON.stringify(s) !== key)) {
        throw new AppError('VALIDATION_ERROR', { details: { reason: 'mixed_parents' } });
      }
      const siblings = await repo.siblingIds(name, scope, tx);
      if (siblings.length !== ids.length) {
        throw new AppError('VALIDATION_ERROR', { details: { reason: 'incomplete_order' } });
      }
      await repo.setSortOrders(name, ids, tx);
    });
    await record(actor, name, 'reordered', ids[0]!, { count: ids.length });
    return { reordered: true };
  }

  async function assertCover(coverMediaId: string | null | undefined) {
    if (!coverMediaId) return;
    const media = await repo.getCoverMedia(coverMediaId);
    if (!media || media.deletedAt || media.kind !== 'cover' || media.status !== 'ready') {
      throw new AppError('VALIDATION_ERROR', { details: { field: 'coverMediaId' } });
    }
  }

  async function subjectOrFail(id: string) {
    return (await repo.getSubject(id, { studentVisible: false })) ?? notFound();
  }

  return {
    // ---- levels (fixed set; rename and reorder only) ----
    async updateLevel(
      actor: AdminActor,
      id: string,
      fields: { nameAr?: string | undefined; sortOrder?: number | undefined },
    ) {
      const row = await repo.updateLevel(id, fields);
      if (!row) notFound();
      await audit.record({
        actorAdminId: actor.adminId,
        action: 'structure.level.updated',
        resourceType: 'education_level',
        resourceId: id,
        metadata: { fields: Object.keys(fields) },
        ip: actor.ip,
      });
      return row;
    },

    // ---- universities ----
    listUniversities: async (): Promise<University[]> =>
      (await repo.listUniversities({ activeOnly: false })).map(toUniversity),

    async createUniversity(
      actor: AdminActor,
      input: { code: string; nameAr: string; isActive?: boolean | undefined },
    ) {
      return toUniversity((await create(actor, 'universities', {}, input)) as never);
    },

    async updateUniversity(
      actor: AdminActor,
      id: string,
      input: Patch<{ code: string; nameAr: string; isActive: boolean }>,
    ) {
      return toUniversity((await update(actor, 'universities', id, input)) as never);
    },

    // ---- faculties ----
    async listFaculties(universityId: string): Promise<Faculty[]> {
      return (await repo.listFaculties(universityId, { activeOnly: false })).map(toFaculty);
    },

    async createFaculty(
      actor: AdminActor,
      input: { universityId: string; code: string; nameAr: string; isActive?: boolean | undefined },
    ) {
      if (!(await repo.getUniversity(input.universityId))) {
        throw new AppError('VALIDATION_ERROR', { details: { field: 'universityId' } });
      }
      return toFaculty(
        (await create(actor, 'faculties', { universityId: input.universityId }, input)) as never,
      );
    },

    async updateFaculty(
      actor: AdminActor,
      id: string,
      input: Patch<{ code: string; nameAr: string; isActive: boolean }>,
    ) {
      return toFaculty((await update(actor, 'faculties', id, input)) as never);
    },

    // ---- academic years ----
    async listAcademicYears(facultyId: string): Promise<AcademicYear[]> {
      return (await repo.listAcademicYears(facultyId, { activeOnly: false })).map(toAcademicYear);
    },

    async createAcademicYear(
      actor: AdminActor,
      input: { facultyId: string; code: string; nameAr: string; isActive?: boolean | undefined },
    ) {
      if (!(await repo.getFaculty(input.facultyId))) {
        throw new AppError('VALIDATION_ERROR', { details: { field: 'facultyId' } });
      }
      return toAcademicYear(
        (await create(actor, 'academicYears', { facultyId: input.facultyId }, input)) as never,
      );
    },

    async updateAcademicYear(
      actor: AdminActor,
      id: string,
      input: Patch<{ code: string; nameAr: string; isActive: boolean }>,
    ) {
      return toAcademicYear((await update(actor, 'academicYears', id, input)) as never);
    },

    // ---- subjects ----
    async listSubjects(filter: {
      levelId?: string | undefined;
      universityId?: string | undefined;
      facultyId?: string | undefined;
      academicYearId?: string | undefined;
    }): Promise<Subject[]> {
      return (await repo.listSubjects(filter, { studentVisible: false })).map((r) => toSubject(r, storage));
    },

    async createSubject(
      actor: AdminActor,
      input: CollegePathInput & {
        educationLevelId: string;
        code: string;
        nameAr: string;
        description?: string | null | undefined;
        coverMediaId?: string | null | undefined;
        isActive?: boolean | undefined;
      },
    ): Promise<Subject> {
      const path = await resolveCollegePath(repo, input.educationLevelId, input, { requireActive: false });
      await assertCover(input.coverMediaId);
      const row = await create(
        actor,
        'subjects',
        { educationLevelId: input.educationLevelId, ...path },
        {
          educationLevelId: input.educationLevelId,
          ...path,
          code: input.code,
          nameAr: input.nameAr,
          description: input.description ?? null,
          coverMediaId: input.coverMediaId ?? null,
          isActive: input.isActive ?? true,
        },
      );
      return toSubject((await repo.getSubject(row.id, { studentVisible: false }))!, storage);
    },

    async updateSubject(
      actor: AdminActor,
      id: string,
      input: CollegePathInput & {
        educationLevelId?: string | undefined;
        code?: string | undefined;
        nameAr?: string | undefined;
        description?: string | null | undefined;
        coverMediaId?: string | null | undefined;
        isActive?: boolean | undefined;
      },
    ): Promise<Subject> {
      const current = await subjectOrFail(id);
      const values: Record<string, unknown> = {};
      // The college path is replaced as a whole: when any layer is given, the new path comes from the
      // given layers alone (the deepest wins); otherwise changing the level clears it.
      const collegeGiven =
        input.universityId !== undefined ||
        input.facultyId !== undefined ||
        input.academicYearId !== undefined;
      const levelId = input.educationLevelId ?? current.educationLevelId;
      if (collegeGiven || levelId !== current.educationLevelId) {
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
          { requireActive: false },
        );
        const moved =
          levelId !== current.educationLevelId ||
          path.universityId !== current.universityId ||
          path.facultyId !== current.facultyId ||
          path.academicYearId !== current.academicYearId;
        if (moved) {
          Object.assign(values, { educationLevelId: levelId, ...path });
          // A subject moved to other siblings goes to the end of their order.
          values.sortOrder = await repo.nextSortOrder('subjects', { educationLevelId: levelId, ...path });
        }
      }
      if (input.coverMediaId !== undefined) {
        await assertCover(input.coverMediaId);
        values.coverMediaId = input.coverMediaId;
      }
      for (const key of ['code', 'nameAr', 'description', 'isActive'] as const) {
        if (input[key] !== undefined) values[key] = input[key];
      }
      await update(actor, 'subjects', id, values);
      return toSubject((await repo.getSubject(id, { studentVisible: false }))!, storage);
    },

    // ---- units ----
    async listUnits(subjectId: string): Promise<Unit[]> {
      return (await repo.listUnits(subjectId)).map(toUnit);
    },

    async createUnit(actor: AdminActor, input: { subjectId: string; code: string; titleAr: string }) {
      if (!(await repo.getSubject(input.subjectId, { studentVisible: false }))) {
        throw new AppError('VALIDATION_ERROR', { details: { field: 'subjectId' } });
      }
      return toUnit((await create(actor, 'units', { subjectId: input.subjectId }, input)) as never);
    },

    async updateUnit(actor: AdminActor, id: string, input: Patch<{ code: string; titleAr: string }>) {
      return toUnit((await update(actor, 'units', id, input)) as never);
    },

    // ---- lessons ----
    async listLessons(subjectId: string, unitId?: string): Promise<Lesson[]> {
      return (await repo.listLessons(subjectId, unitId)).map(toLesson);
    },

    async createLesson(
      actor: AdminActor,
      input: { subjectId: string; unitId?: string | null | undefined; code: string; titleAr: string },
    ) {
      if (!(await repo.getSubject(input.subjectId, { studentVisible: false }))) {
        throw new AppError('VALIDATION_ERROR', { details: { field: 'subjectId' } });
      }
      const unitId = input.unitId ?? null;
      await assertUnitInSubject(unitId, input.subjectId);
      return toLesson(
        (await create(
          actor,
          'lessons',
          { subjectId: input.subjectId, unitId },
          { ...input, unitId },
        )) as never,
      );
    },

    async updateLesson(
      actor: AdminActor,
      id: string,
      input: Patch<{ unitId: string | null; code: string; titleAr: string }>,
    ) {
      const lesson = (await repo.getLesson(id)) ?? notFound();
      const values: Record<string, unknown> = { ...input };
      if (input.unitId !== undefined && input.unitId !== lesson.unitId) {
        await assertUnitInSubject(input.unitId, lesson.subjectId);
        // Moving to another unit appends the lesson at the end of its new siblings.
        values.sortOrder = await repo.nextSortOrder('lessons', {
          subjectId: lesson.subjectId,
          unitId: input.unitId,
        });
      }
      return toLesson((await update(actor, 'lessons', id, values)) as never);
    },

    // ---- shared ----
    remove,
    reorder,
  };

  async function assertUnitInSubject(unitId: string | null, subjectId: string) {
    if (!unitId) return;
    const unit = await repo.getUnit(unitId);
    // spec §6.1: a lesson's unit must belong to the same subject (also enforced by a composite FK).
    if (!unit || unit.subjectId !== subjectId) {
      throw new AppError('VALIDATION_ERROR', { details: { field: 'unitId', reason: 'other_subject' } });
    }
  }
}

export type StructureService = ReturnType<typeof createStructureService>;
