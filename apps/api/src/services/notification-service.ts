import { businessDay, DAY, startOfBusinessDay } from '@plengo/srs';
import type { AdminNotification, NotificationTarget, StudentNotification } from '@plengo/contracts';
import type { Db } from '@plengo/db';
import { AppError } from '../lib/app-error.js';
import type { JobQueue } from '../jobs/queue.js';
import type { HomeRepository, NotificationRow, Recipient } from '../repositories/home-repository.js';
import { decodeCursor, encodeCursor } from '../repositories/question-repository.js';
import type { StructureRepository } from '../repositories/structure-repository.js';
import type { TeacherRepository } from '../repositories/teacher-repository.js';
import type { AuditService } from './audit-service.js';
import { invalid } from './content-placement.js';
import type { PushSender } from './push.js';
import type { AdminActor } from './structure-service.js';

const BATCH = 500;
const DAMASCUS_OFFSET_MS = 3 * 3600_000;

type Type = NotificationRow['type'];
type Action = NotificationRow['action'];

/** Learning notifications follow the التعلّم switch; promotions need the العروض opt-in (§20.2). */
const category = (type: Type) =>
  type === 'promotion'
    ? 'promotions'
    : type === 'announcement' || type === 'report_resolved'
      ? 'always'
      : 'learning';

/** Inbox: promotions reach only students who opted in; everything else is always kept. */
const inInbox = (type: Type, r: Recipient) => category(type) !== 'promotions' || r.notifyPromotions;
/** Push: learning types follow the learning switch as well. */
const pushed = (type: Type, r: Recipient) =>
  category(type) === 'always' || (category(type) === 'learning' ? r.notifyLearning : r.notifyPromotions);

/** "لديك 35 بطاقة للمراجعة اليوم" with Arabic count agreement. */
export function dueReminderText(n: number) {
  const cards = n === 1 ? 'بطاقة واحدة' : n === 2 ? 'بطاقتان' : n <= 10 ? `${n} بطاقات` : `${n} بطاقة`;
  return `لديك ${cards} للمراجعة اليوم`;
}

/**
 * Notifications (spec §20): every notification lands in the in-app inbox, and push goes out in
 * addition where the student has a device token and consent. Fan-out runs as a job in batches.
 */
export function createNotificationService(deps: {
  db: Db;
  repo: HomeRepository;
  structureRepo: StructureRepository;
  teacherRepo: TeacherRepository;
  audit: AuditService;
  jobs: JobQueue;
  push: PushSender;
  now?: () => Date;
}) {
  const { db, repo, structureRepo, teacherRepo, audit, jobs, push } = deps;
  const now = deps.now ?? (() => new Date());

  async function pushTo(n: NotificationRow, recipients: Recipient[]) {
    const tokens = await repo.tokensOf(recipients.filter((r) => pushed(n.type, r)).map((r) => r.userId));
    if (!tokens.length) return { sent: 0, failed: 0 };
    const result = await push.send(
      tokens.map((t) => t.token),
      {
        title: n.titleAr,
        body: n.bodyAr,
        data: { notificationId: n.id, action: n.action, actionTarget: n.actionTarget ?? '' },
      },
    );
    await repo.revokeTokens(result.invalidTokens, now());
    return result;
  }

  async function validateTarget(type: AdminNotification['targetType'], t: NotificationTarget) {
    const need = (v: unknown, field: string) => {
      if (!v) invalid(`target.${field}`);
    };
    switch (type) {
      case 'level':
        need(t.educationLevelId, 'educationLevelId');
        if (!(await structureRepo.getLevel(t.educationLevelId!))) invalid('target.educationLevelId');
        break;
      case 'subject_entitlement':
        need(t.subjectId, 'subjectId');
        if (!(await structureRepo.getSubject(t.subjectId!, { studentVisible: false })))
          invalid('target.subjectId');
        break;
      case 'track_entitlement':
        need(t.teacherTrackId, 'teacherTrackId');
        if (!(await teacherRepo.getTrack(t.teacherTrackId!, { visibleOnly: false })))
          invalid('target.teacherTrackId');
        break;
      case 'teacher_followers':
        need(t.teacherId, 'teacherId');
        if (!(await teacherRepo.getTeacher(t.teacherId!, { visibleOnly: false })))
          invalid('target.teacherId');
        break;
      case 'students':
        if (!t.userIds?.length) invalid('target.userIds');
        break;
      case 'all':
        break;
    }
  }

  const toAdmin = (n: NotificationRow, readCount: number): AdminNotification => ({
    id: n.id,
    type: n.type,
    titleAr: n.titleAr,
    bodyAr: n.bodyAr,
    action: n.action,
    actionTarget: n.actionTarget,
    targetType: n.targetType,
    target: n.target as NotificationTarget,
    status: n.status,
    recipientCount: n.recipientCount,
    pushCount: n.pushCount,
    pushFailures: n.pushFailures,
    readCount,
    createdAt: n.createdAt.toISOString(),
    sentAt: n.sentAt?.toISOString() ?? null,
  });

  const service = {
    // ---- admin ----

    async create(
      actor: AdminActor,
      input: {
        type: Exclude<Type, 'due_reminder' | 'report_resolved'>;
        titleAr: string;
        bodyAr: string;
        action: Action;
        actionTarget?: string | null | undefined;
        targetType: AdminNotification['targetType'];
        target: NotificationTarget;
      },
    ): Promise<AdminNotification> {
      await validateTarget(input.targetType, input.target);
      const n = await repo.insertNotification(db, {
        type: input.type,
        titleAr: input.titleAr,
        bodyAr: input.bodyAr,
        action: input.action,
        actionTarget: input.actionTarget ?? null,
        targetType: input.targetType,
        target: input.target,
        createdByAdminId: actor.adminId,
        createdAt: now(),
      });
      await audit.record({
        actorAdminId: actor.adminId,
        action: 'notification.created',
        resourceType: 'notification',
        resourceId: n.id,
        metadata: { type: n.type, targetType: n.targetType },
        ip: actor.ip,
      });
      await jobs.send('notifications.fanout', { notificationId: n.id }, { singletonKey: n.id });
      return toAdmin(n, 0);
    },

    async list(cursor: string | undefined, limit: number) {
      const offset = decodeCursor(cursor);
      const rows = await repo.listNotifications(limit + 1, offset);
      return {
        items: rows.slice(0, limit).map((r) => toAdmin(r.n, r.readCount)),
        nextCursor: rows.length > limit ? encodeCursor(offset + limit) : null,
      };
    },

    /** The fan-out job: inbox rows in batches, then push to consenting devices. Safe to repeat. */
    async fanout(notificationId: string) {
      const n = await repo.notification(notificationId);
      if (!n || n.status === 'sent') return;
      await repo.updateNotification(n.id, { status: 'sending' });
      let after: string | null = null;
      let delivered = 0;
      let pushSent = 0;
      let pushFailed = 0;
      for (;;) {
        const page: Recipient[] = await repo.recipients(
          { type: n.targetType, value: n.target },
          after,
          BATCH,
          now(),
        );
        if (!page.length) break;
        after = page[page.length - 1]!.userId;
        const inbox = page.filter((r) => inInbox(n.type, r));
        delivered += await repo.deliver(
          db,
          n.id,
          inbox.map((r) => r.userId),
        );
        const r = await pushTo(n, inbox);
        pushSent += r.sent;
        pushFailed += r.failed;
        if (page.length < BATCH) break;
      }
      await repo.updateNotification(n.id, {
        status: 'sent',
        recipientCount: n.recipientCount + delivered,
        pushCount: n.pushCount + pushSent,
        pushFailures: n.pushFailures + pushFailed,
        sentAt: now(),
      });
    },

    /** A notification for one student (reminders, a handled report), delivered right away. */
    async notifyUser(
      userId: string,
      input: { type: Type; titleAr: string; bodyAr: string; action?: Action; actionTarget?: string | null },
    ) {
      const n = await repo.insertNotification(db, {
        type: input.type,
        titleAr: input.titleAr,
        bodyAr: input.bodyAr,
        action: input.action ?? 'none',
        actionTarget: input.actionTarget ?? null,
        targetType: 'students',
        target: { userIds: [userId] },
        createdAt: now(),
      });
      await jobs.send('notifications.fanout', { notificationId: n.id }, { singletonKey: n.id });
      return n.id;
    },

    /**
     * The hourly reminder job (§20.3): students whose reminder time falls in this Damascus hour, with
     * learning notifications on and cards due today, get one reminder a day.
     */
    async dueReminders() {
      const at = now();
      const hour = String(new Date(at.getTime() + DAMASCUS_OFFSET_MS).getUTCHours()).padStart(2, '0');
      const today = businessDay(at.getTime());
      const endOfDay = new Date(startOfBusinessDay(today + 1));
      const dayStart = new Date(startOfBusinessDay(today));
      let sent = 0;
      for (const { userId } of await repo.reminderCandidates(hour)) {
        const due = await repo.dueCount(userId, endOfDay);
        if (!due || (await repo.receivedSince(userId, 'due_reminder', dayStart))) continue;
        await service.notifyUser(userId, {
          type: 'due_reminder',
          titleAr: 'حان وقت المراجعة',
          bodyAr: dueReminderText(due),
          action: 'internal_route',
          actionTarget: '/review',
        });
        sent++;
      }
      return sent;
    },

    // ---- student ----

    async inbox(userId: string, cursor: string | undefined, limit: number) {
      const offset = decodeCursor(cursor);
      const rows = await repo.inbox(userId, limit + 1, offset);
      const items: StudentNotification[] = rows.slice(0, limit).map(({ un, n }) => ({
        id: un.id,
        type: n.type,
        titleAr: n.titleAr,
        bodyAr: n.bodyAr,
        action: n.action,
        actionTarget: n.actionTarget,
        createdAt: un.createdAt.toISOString(),
        readAt: un.readAt?.toISOString() ?? null,
      }));
      return {
        items,
        nextCursor: rows.length > limit ? encodeCursor(offset + limit) : null,
        unreadCount: await repo.unreadCount(userId),
      };
    },

    async markRead(userId: string, id: string) {
      if (!(await repo.markRead(userId, id, now()))) throw new AppError('NOT_FOUND');
      return { unreadCount: await repo.unreadCount(userId) };
    },

    async markAllRead(userId: string) {
      await repo.markAllRead(userId, now());
      return { unreadCount: 0 };
    },

    unreadCount: (userId: string) => repo.unreadCount(userId),

    async preferences(userId: string) {
      const p =
        (await repo.profile(userId)) ??
        (() => {
          throw new AppError('NOT_FOUND');
        })();
      return { learning: p.notifyLearning, promotions: p.notifyPromotions, reminderTime: p.reminderTime };
    },

    async setPreferences(
      userId: string,
      input: {
        learning?: boolean | undefined;
        promotions?: boolean | undefined;
        reminderTime?: string | undefined;
      },
    ) {
      await repo.updateProfile(userId, {
        ...(input.learning !== undefined ? { notifyLearning: input.learning } : {}),
        ...(input.promotions !== undefined ? { notifyPromotions: input.promotions } : {}),
        ...(input.reminderTime !== undefined ? { reminderTime: input.reminderTime } : {}),
      });
      return service.preferences(userId);
    },

    registerToken: (
      userId: string,
      input: { token: string; platform: string; appVersion?: string | undefined },
    ) =>
      repo.upsertToken(userId, input.token, input.platform, input.appVersion ?? null, now()).then(() => ({
        registered: true,
      })),

    revokeToken: (userId: string, token: string) =>
      repo.revokeToken(userId, token, now()).then(() => ({ revoked: true })),
  };
  return service;
}

export type NotificationService = ReturnType<typeof createNotificationService>;

/** Calendar days from Damascus today to `date` (YYYY-MM-DD). */
export function daysUntil(date: string, at: Date) {
  const today = new Date(at.getTime() + DAMASCUS_OFFSET_MS).toISOString().slice(0, 10);
  return Math.round((Date.parse(`${date}T00:00:00Z`) - Date.parse(`${today}T00:00:00Z`)) / DAY);
}

export function damascusToday(at: Date) {
  return new Date(at.getTime() + DAMASCUS_OFFSET_MS).toISOString().slice(0, 10);
}
