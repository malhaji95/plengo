import type { AdminTeacher, AdminTrack, Teacher, TeacherTrack } from '@plengo/contracts';
import { AppError } from '../lib/app-error.js';
import type { StructureRepository } from '../repositories/structure-repository.js';
import type { TeacherRepository, TeacherRow, TrackRow } from '../repositories/teacher-repository.js';
import type { ObjectStorage } from '../storage/storage.js';
import { toSubject, publicImageUrl } from './structure-mappers.js';
import { assertReadyImage, type AdminActor, type StructureService } from './structure-service.js';
import { trackScope, type AccessService } from './access-service.js';

type Patch<T> = { [K in keyof T]?: T[K] | undefined };

/**
 * Teachers and teacher tracks (spec §7). Teachers are content entities only. Following never grants
 * access (§7.4); tracks are their own access scope from Phase 4 on.
 */
export function createTeacherService(deps: {
  repo: TeacherRepository;
  structureRepo: StructureRepository;
  structure: StructureService;
  storage: ObjectStorage;
  access: AccessService;
  questionCounts: (scope: ReturnType<typeof trackScope>) => Promise<{ total: number; free: number }>;
  deckCounts: (scope: ReturnType<typeof trackScope>) => Promise<{ total: number; free: number }>;
}) {
  const { repo, structureRepo, structure, storage, access, questionCounts, deckCounts } = deps;
  const notFound = (): never => {
    throw new AppError('NOT_FOUND');
  };

  const toTeacher = (r: TeacherRow, following: boolean): Teacher => ({
    id: r.id,
    nameAr: r.nameAr,
    slug: r.slug,
    photoUrl: publicImageUrl(storage, r.photoVariants, r.photoStatus),
    shortDescription: r.shortDescription,
    followerCount: r.followerCount,
    isFollowing: following,
  });

  const toTrack = (r: TrackRow): TeacherTrack => ({
    id: r.id,
    teacherId: r.teacherId,
    teacherNameAr: r.teacherNameAr,
    subjectId: r.subjectId,
    subjectNameAr: r.subjectNameAr,
    educationLevelId: r.educationLevelId,
    titleAr: r.titleAr,
    slug: r.slug,
    description: r.description,
    coverUrl: publicImageUrl(storage, r.coverVariants, r.coverStatus),
  });

  const toAdminTrack = (r: TrackRow): AdminTrack => ({
    ...toTrack(r),
    coverMediaId: r.coverMediaId,
    isActive: r.isActive,
    sortOrder: r.sortOrder,
  });

  async function adminTeacher(id: string, trackCounts?: Map<string, number>): Promise<AdminTeacher> {
    const r = (await repo.getTeacher(id, { visibleOnly: false })) ?? notFound();
    const counts = trackCounts ?? (await repo.trackCounts());
    return toAdminTeacher(r, counts.get(r.id) ?? 0);
  }

  function toAdminTeacher(r: TeacherRow, trackCount: number): AdminTeacher {
    return {
      id: r.id,
      nameAr: r.nameAr,
      slug: r.slug,
      photoMediaId: r.photoMediaId,
      photoUrl: publicImageUrl(storage, r.photoVariants, r.photoStatus),
      shortDescription: r.shortDescription,
      bio: r.bio,
      isActive: r.isActive,
      sortOrder: r.sortOrder,
      followerCount: r.followerCount,
      trackCount,
    };
  }

  async function visibleTeacher(id: string) {
    return (await repo.getTeacher(id, { visibleOnly: true })) ?? notFound();
  }

  return {
    // ---- admin ----
    async adminListTeachers(): Promise<AdminTeacher[]> {
      const [rows, counts] = await Promise.all([
        repo.listTeachers({ visibleOnly: false }),
        repo.trackCounts(),
      ]);
      return rows.map((r) => toAdminTeacher(r, counts.get(r.id) ?? 0));
    },

    adminGetTeacher: (id: string) => adminTeacher(id),

    async createTeacher(
      actor: AdminActor,
      input: {
        nameAr: string;
        slug: string;
        shortDescription?: string | null | undefined;
        bio?: string | null | undefined;
        photoMediaId?: string | null | undefined;
        isActive?: boolean | undefined;
      },
    ): Promise<AdminTeacher> {
      await assertReadyImage(structureRepo, input.photoMediaId, 'teacher', 'photoMediaId');
      const row = await structure.create(
        actor,
        'teachers',
        {},
        {
          nameAr: input.nameAr,
          slug: input.slug,
          shortDescription: input.shortDescription ?? null,
          bio: input.bio ?? null,
          photoMediaId: input.photoMediaId ?? null,
          isActive: input.isActive ?? true,
        },
      );
      return adminTeacher(row.id);
    },

    async updateTeacher(
      actor: AdminActor,
      id: string,
      input: Patch<{
        nameAr: string;
        slug: string;
        shortDescription: string | null;
        bio: string | null;
        photoMediaId: string | null;
        isActive: boolean;
      }>,
    ): Promise<AdminTeacher> {
      if (input.photoMediaId !== undefined) {
        await assertReadyImage(structureRepo, input.photoMediaId, 'teacher', 'photoMediaId');
      }
      await structure.update(actor, 'teachers', id, input);
      return adminTeacher(id);
    },

    async adminListTracks(filter: { teacherId?: string | undefined; subjectId?: string | undefined }) {
      return (await repo.listTracks(filter, { visibleOnly: false })).map(toAdminTrack);
    },

    async createTrack(
      actor: AdminActor,
      input: {
        teacherId: string;
        subjectId: string;
        titleAr: string;
        slug: string;
        description?: string | null | undefined;
        coverMediaId?: string | null | undefined;
        isActive?: boolean | undefined;
      },
    ): Promise<AdminTrack> {
      if (!(await repo.getTeacher(input.teacherId, { visibleOnly: false }))) {
        throw new AppError('VALIDATION_ERROR', { details: { field: 'teacherId' } });
      }
      if (!(await structureRepo.getSubject(input.subjectId, { studentVisible: false }))) {
        throw new AppError('VALIDATION_ERROR', { details: { field: 'subjectId' } });
      }
      await assertReadyImage(structureRepo, input.coverMediaId, 'cover', 'coverMediaId');
      const row = await structure.create(
        actor,
        'teacherTracks',
        { teacherId: input.teacherId },
        {
          teacherId: input.teacherId,
          subjectId: input.subjectId,
          titleAr: input.titleAr,
          slug: input.slug,
          description: input.description ?? null,
          coverMediaId: input.coverMediaId ?? null,
          isActive: input.isActive ?? true,
        },
      );
      return toAdminTrack((await repo.getTrack(row.id, { visibleOnly: false }))!);
    },

    async updateTrack(
      actor: AdminActor,
      id: string,
      input: Patch<{
        titleAr: string;
        slug: string;
        description: string | null;
        coverMediaId: string | null;
        isActive: boolean;
      }>,
    ): Promise<AdminTrack> {
      if (input.coverMediaId !== undefined) {
        await assertReadyImage(structureRepo, input.coverMediaId, 'cover', 'coverMediaId');
      }
      await structure.update(actor, 'teacherTracks', id, input);
      return toAdminTrack((await repo.getTrack(id, { visibleOnly: false }))!);
    },

    // ---- students ----
    async listTeachers(userId: string): Promise<Teacher[]> {
      const [rows, followed] = await Promise.all([
        repo.listTeachers({ visibleOnly: true }),
        repo.followedIds(userId),
      ]);
      return rows.map((r) => toTeacher(r, followed.has(r.id)));
    },

    async followedTeachers(userId: string): Promise<Teacher[]> {
      return (await repo.listFollowedTeachers(userId)).map((r) => toTeacher(r, true));
    },

    async profile(userId: string, teacherId: string) {
      const teacher = await visibleTeacher(teacherId);
      const [followed, tracks] = await Promise.all([
        repo.followedIds(userId),
        repo.listTracks({ teacherId }, { visibleOnly: true }),
      ]);
      return {
        teacher: { ...toTeacher(teacher, followed.has(teacher.id)), bio: teacher.bio },
        tracks: tracks.map(toTrack),
      };
    },

    async track(userId: string, trackId: string) {
      const track = (await repo.getTrack(trackId, { visibleOnly: true })) ?? notFound();
      const [teacher, subject, followed, scopeAccess, questionCount, deckCount] = await Promise.all([
        repo.getTeacher(track.teacherId, { visibleOnly: true }),
        structureRepo.getSubject(track.subjectId, { studentVisible: true }),
        repo.followedIds(userId),
        access.scopeAccess(userId, trackScope(track.id)),
        questionCounts(trackScope(track.id)),
        deckCounts(trackScope(track.id)),
      ]);
      if (!teacher || !subject) notFound();
      return {
        track: toTrack(track),
        teacher: toTeacher(teacher!, followed.has(teacher!.id)),
        subject: toSubject(subject!, storage),
        access: scopeAccess,
        questionCount,
        deckCount,
      };
    },

    /** Tracks listed on a subject page (spec §23.2 #10). */
    async subjectTracks(subjectId: string) {
      return (await repo.listTracks({ subjectId }, { visibleOnly: true })).map((r) => ({
        id: r.id,
        teacherId: r.teacherId,
        teacherNameAr: r.teacherNameAr,
        teacherPhotoUrl: publicImageUrl(storage, r.teacherPhotoVariants, r.teacherPhotoStatus, 'thumb'),
        titleAr: r.titleAr,
        description: r.description,
        coverUrl: publicImageUrl(storage, r.coverVariants, r.coverStatus),
      }));
    },

    /** Idempotent. Following never grants access (spec §7.4). */
    async setFollowing(userId: string, teacherId: string, following: boolean) {
      await visibleTeacher(teacherId);
      if (following) await repo.follow(teacherId, userId);
      else await repo.unfollow(teacherId, userId);
      return { following, followerCount: await repo.followerCount(teacherId) };
    },
  };
}

export type TeacherService = ReturnType<typeof createTeacherService>;
