import { businessDay, DAY } from '@plengo/srs';
import type { AdminBanner, HomeBanner } from '@plengo/contracts';
import { AppError } from '../lib/app-error.js';
import type { MediaRow } from '../repositories/flashcard-repository.js';
import type { BannerRow, CountdownRow, HomeRepository } from '../repositories/home-repository.js';
import type { StructureRepository } from '../repositories/structure-repository.js';
import type { ObjectStorage } from '../storage/storage.js';
import type { AccessService } from './access-service.js';
import type { AuditService } from './audit-service.js';
import type { CatalogService } from './catalog-service.js';
import { invalid } from './content-placement.js';
import type { LearningService } from './learning-service.js';
import { damascusToday, daysUntil, type NotificationService } from './notification-service.js';
import type { SrsService } from './srs-service.js';
import { publicImageUrl } from './structure-mappers.js';
import type { AdminActor } from './structure-service.js';
import type { TeacherService } from './teacher-service.js';

type Counts = (scope: { scopeType: 'subject'; subjectId: string; teacherTrackId: null }) => Promise<{
  total: number;
  free: number;
}>;

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/;

/** Consecutive days with the goal met, ending today (or yesterday while today is still open). */
export function goalStreak(metDays: Set<number>, today: number) {
  let day = metDays.has(today) ? today : today - 1;
  let streak = 0;
  while (metDays.has(day)) {
    streak++;
    day--;
  }
  return streak;
}

/**
 * The student home (spec §19.1) and the admin side of banners (§19.2) and exam countdowns (§19.3).
 * Daily goal and streak (§19.4) use business days starting 04:00 Asia/Damascus.
 */
export function createHomeService(deps: {
  repo: HomeRepository;
  structureRepo: StructureRepository;
  storage: ObjectStorage;
  audit: AuditService;
  catalog: CatalogService;
  access: AccessService;
  learning: LearningService;
  srs: SrsService;
  teachers: TeacherService;
  notifications: NotificationService;
  counts: Counts[];
  now?: () => Date;
}) {
  const { repo, structureRepo, storage, audit, catalog, access, learning, srs, teachers, notifications } =
    deps;
  const now = deps.now ?? (() => new Date());
  const record = (actor: AdminActor, action: string, type: string, id: string, metadata = {}) =>
    audit.record({
      actorAdminId: actor.adminId,
      action,
      resourceType: type,
      resourceId: id,
      metadata,
      ip: actor.ip,
    });

  const dayString = (day: number) => new Date(day * DAY).toISOString().slice(0, 10);

  const bannerImage = (m: MediaRow | null) => (m ? publicImageUrl(storage, m.variants, m.status) : null);

  function isLive(b: BannerRow, at: Date) {
    return (
      b.isActive &&
      (!b.startsAt || b.startsAt.getTime() <= at.getTime()) &&
      (!b.endsAt || b.endsAt.getTime() > at.getTime())
    );
  }

  const toAdminBanner = (b: BannerRow, m: MediaRow | null): AdminBanner => ({
    id: b.id,
    titleAr: b.titleAr,
    imageMediaId: b.imageMediaId,
    imageUrl: bannerImage(m),
    action: b.action,
    actionTarget: b.actionTarget,
    educationLevelId: b.educationLevelId,
    startsAt: b.startsAt?.toISOString() ?? null,
    endsAt: b.endsAt?.toISOString() ?? null,
    isActive: b.isActive,
    sortOrder: b.sortOrder,
    live: isLive(b, now()),
    updatedAt: b.updatedAt.toISOString(),
  });

  const toCountdown = (c: CountdownRow) => ({
    id: c.id,
    educationLevelId: c.educationLevelId,
    titleAr: c.titleAr,
    examDate: c.examDate,
    isActive: c.isActive,
    daysLeft: daysUntil(c.examDate, now()),
  });

  /** A click action needs a target of the right shape (§19.2). */
  function assertAction(action: BannerRow['action'], target: string | null | undefined) {
    if (action === 'none') return;
    if (!target) invalid('actionTarget');
    if (action === 'external_url' && !/^https:\/\/[^\s]+$/.test(target!))
      invalid('actionTarget', 'https_url');
    if (action === 'internal_route' && !/^\/[\w\-/?=&.%]*$/.test(target!)) invalid('actionTarget', 'route');
    if (action !== 'external_url' && action !== 'internal_route' && !UUID.test(target!))
      invalid('actionTarget', 'id');
  }

  async function assertImage(mediaId: string) {
    const m = await repo.media(mediaId);
    if (!m || m.deletedAt || m.kind !== 'banner' || m.status !== 'ready') invalid('imageMediaId');
  }

  function assertSchedule(startsAt: Date | null, endsAt: Date | null) {
    if (startsAt && endsAt && endsAt.getTime() <= startsAt.getTime()) invalid('endsAt', 'before_start');
  }

  const dateOrNull = (v: string | null | undefined) => (v ? new Date(v) : null);

  async function saveBanner(actor: AdminActor, id: string, values: Partial<BannerRow>) {
    await repo.updateBanner(id, { ...values, updatedByAdminId: actor.adminId, updatedAt: now() });
    await record(actor, 'banner.updated', 'banner', id);
    const row = (await repo.banner(id))!;
    return toAdminBanner(row.banner, row.media);
  }

  async function today(userId: string, goal: number) {
    const at = now();
    const todayNum = businessDay(at.getTime());
    const rows = await repo.activity(userId, dayString(todayNum - 400));
    const todayRow = rows.find((r) => r.day === dayString(todayNum));
    const met = new Set(
      rows.filter((r) => r.goalMet).map((r) => Math.round(Date.parse(`${r.day}T00:00:00Z`) / DAY)),
    );
    const due = await srs.due(userId, undefined).catch(() => ({ cards: [], userCards: [] }));
    const done = todayRow?.itemsDone ?? 0;
    const dayGoal = todayRow?.goal ?? goal;
    return {
      dueCards: due.cards.length + due.userCards.length,
      goal: dayGoal,
      done,
      goalMet: done >= dayGoal,
      streak: goalStreak(met, todayNum),
    };
  }

  return {
    async home(userId: string) {
      const me = await catalog.me(userId);
      const profile = await repo.profile(userId);
      const at = now();
      const levelId = me.educationLevelId;
      const [countdown, bannerRows, unread, resume, owned, followed, mistakes] = await Promise.all([
        levelId ? repo.nextCountdown(levelId, damascusToday(at)) : Promise.resolve(null),
        repo.liveBanners(levelId, at),
        notifications.unreadCount(userId),
        learning.resume(userId, 5),
        access.myEntitlements(userId),
        teachers.followedTeachers(userId),
        learning.mistakeCounts(userId),
      ]);
      const banners: HomeBanner[] = bannerRows.map(({ banner: b, media: m }) => ({
        id: b.id,
        titleAr: b.titleAr,
        imageUrl: bannerImage(m) ?? '',
        width: m.variants.full?.width ?? m.width,
        height: m.variants.full?.height ?? m.height,
        action: b.action,
        actionTarget: b.actionTarget,
      }));
      const freeSubjects = [];
      if (levelId) {
        for (const s of await catalog.subjects({ levelId })) {
          const scope = { scopeType: 'subject' as const, subjectId: s.id, teacherTrackId: null };
          let free = 0;
          for (const c of deps.counts) free += (await c(scope)).free;
          if (free > 0) freeSubjects.push({ subjectId: s.id, nameAr: s.nameAr, freeCount: free });
        }
      }
      return {
        greetingName: me.fullName,
        unreadNotifications: unread,
        countdown: countdown
          ? {
              titleAr: countdown.titleAr,
              examDate: countdown.examDate,
              daysLeft: daysUntil(countdown.examDate, at),
            }
          : null,
        banners,
        today: await today(userId, profile?.dailyGoal ?? 20),
        resume,
        myAccess: owned.filter((e) => e.state === 'active'),
        freeSubjects,
        followedTeachers: followed,
        activeMistakes: mistakes.active,
      };
    },

    async goal(userId: string) {
      const p = await repo.profile(userId);
      if (!p) throw new AppError('NOT_FOUND');
      return { dailyGoal: p.dailyGoal };
    },

    /** Applies to today and later days; days already past keep their goal. */
    async setGoal(userId: string, dailyGoal: number) {
      await repo.updateProfile(userId, { dailyGoal });
      await repo.setTodayGoal(userId, dayString(businessDay(now().getTime())), dailyGoal);
      return { dailyGoal };
    },

    // ---- admin: banners ----

    async banners(): Promise<AdminBanner[]> {
      return (await repo.listBanners()).map((r) => toAdminBanner(r.banner, r.media));
    },

    async createBanner(
      actor: AdminActor,
      input: {
        titleAr: string;
        imageMediaId: string;
        action: BannerRow['action'];
        actionTarget?: string | null | undefined;
        educationLevelId?: string | null | undefined;
        startsAt?: string | null | undefined;
        endsAt?: string | null | undefined;
        isActive?: boolean | undefined;
      },
    ) {
      await assertImage(input.imageMediaId);
      assertAction(input.action, input.actionTarget);
      if (input.educationLevelId && !(await structureRepo.getLevel(input.educationLevelId)))
        invalid('educationLevelId');
      const startsAt = dateOrNull(input.startsAt);
      const endsAt = dateOrNull(input.endsAt);
      assertSchedule(startsAt, endsAt);
      const b = await repo.insertBanner({
        titleAr: input.titleAr,
        imageMediaId: input.imageMediaId,
        action: input.action,
        actionTarget: input.action === 'none' ? null : (input.actionTarget ?? null),
        educationLevelId: input.educationLevelId ?? null,
        startsAt,
        endsAt,
        isActive: input.isActive ?? true,
        sortOrder: await repo.nextBannerOrder(),
        createdByAdminId: actor.adminId,
        updatedByAdminId: actor.adminId,
      });
      await record(actor, 'banner.created', 'banner', b.id);
      const row = (await repo.banner(b.id))!;
      return toAdminBanner(row.banner, row.media);
    },

    async updateBanner(
      actor: AdminActor,
      id: string,
      patch: {
        titleAr?: string | undefined;
        imageMediaId?: string | undefined;
        action?: BannerRow['action'] | undefined;
        actionTarget?: string | null | undefined;
        educationLevelId?: string | null | undefined;
        startsAt?: string | null | undefined;
        endsAt?: string | null | undefined;
        isActive?: boolean | undefined;
      },
    ) {
      const current =
        (await repo.banner(id))?.banner ??
        (() => {
          throw new AppError('NOT_FOUND');
        })();
      if (patch.imageMediaId) await assertImage(patch.imageMediaId);
      const action = patch.action ?? current.action;
      const target = patch.actionTarget !== undefined ? patch.actionTarget : current.actionTarget;
      assertAction(action, target);
      if (patch.educationLevelId && !(await structureRepo.getLevel(patch.educationLevelId)))
        invalid('educationLevelId');
      const startsAt = patch.startsAt !== undefined ? dateOrNull(patch.startsAt) : current.startsAt;
      const endsAt = patch.endsAt !== undefined ? dateOrNull(patch.endsAt) : current.endsAt;
      assertSchedule(startsAt, endsAt);
      return saveBanner(actor, id, {
        ...(patch.titleAr !== undefined ? { titleAr: patch.titleAr } : {}),
        ...(patch.imageMediaId !== undefined ? { imageMediaId: patch.imageMediaId } : {}),
        action,
        actionTarget: action === 'none' ? null : target,
        ...(patch.educationLevelId !== undefined ? { educationLevelId: patch.educationLevelId } : {}),
        startsAt,
        endsAt,
        ...(patch.isActive !== undefined ? { isActive: patch.isActive } : {}),
      });
    },

    async removeBanner(actor: AdminActor, id: string) {
      if (!(await repo.banner(id))) throw new AppError('NOT_FOUND');
      await repo.updateBanner(id, { deletedAt: now(), updatedByAdminId: actor.adminId });
      await record(actor, 'banner.deleted', 'banner', id);
      return { deleted: true };
    },

    /** `ids` must be every banner in the new order. */
    async reorderBanners(actor: AdminActor, ids: string[]) {
      const all = new Set(await repo.liveBannerIds());
      if (all.size !== ids.length || new Set(ids).size !== ids.length || ids.some((i) => !all.has(i))) {
        invalid('ids', 'not_all_banners');
      }
      for (const [i, id] of ids.entries()) await repo.updateBanner(id, { sortOrder: i });
      await record(actor, 'banner.reordered', 'banner', ids[0]!, { ids });
      return { reordered: true };
    },

    // ---- admin: countdowns ----

    async countdowns() {
      return (await repo.countdowns()).map(toCountdown);
    },

    async createCountdown(
      actor: AdminActor,
      input: { educationLevelId: string; titleAr: string; examDate: string; isActive?: boolean | undefined },
    ) {
      if (!(await structureRepo.getLevel(input.educationLevelId))) invalid('educationLevelId');
      const c = await repo.insertCountdown({ ...input, isActive: input.isActive ?? true });
      await record(actor, 'countdown.created', 'exam_countdown', c.id);
      return toCountdown(c);
    },

    async updateCountdown(
      actor: AdminActor,
      id: string,
      patch: {
        educationLevelId?: string | undefined;
        titleAr?: string | undefined;
        examDate?: string | undefined;
        isActive?: boolean | undefined;
      },
    ) {
      if (!(await repo.countdown(id))) throw new AppError('NOT_FOUND');
      if (patch.educationLevelId && !(await structureRepo.getLevel(patch.educationLevelId)))
        invalid('educationLevelId');
      await repo.updateCountdown(id, { ...patch, updatedAt: now() });
      await record(actor, 'countdown.updated', 'exam_countdown', id);
      return toCountdown((await repo.countdown(id))!);
    },

    async removeCountdown(actor: AdminActor, id: string) {
      if (!(await repo.countdown(id))) throw new AppError('NOT_FOUND');
      await repo.deleteCountdown(id);
      await record(actor, 'countdown.deleted', 'exam_countdown', id);
      return { deleted: true };
    },
  };
}

export type HomeService = ReturnType<typeof createHomeService>;
