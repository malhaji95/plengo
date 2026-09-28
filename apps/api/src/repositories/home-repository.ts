import {
  and,
  asc,
  count,
  desc,
  eq,
  gt,
  gte,
  inArray,
  isNotNull,
  isNull,
  lte,
  ne,
  or,
  sql,
} from 'drizzle-orm';
import {
  banners,
  cardStates,
  entitlements,
  examCountdowns,
  mediaFiles,
  notifications,
  profiles,
  pushTokens,
  teacherFollowers,
  userDailyActivity,
  userNotifications,
  users,
  type Db,
  type Tx,
} from '@plengo/db';
import { entitlementActiveAt } from './access-repository.js';

type Conn = Db | Tx;
export type BannerRow = typeof banners.$inferSelect;
export type CountdownRow = typeof examCountdowns.$inferSelect;
export type NotificationRow = typeof notifications.$inferSelect;
export type Recipient = { userId: string; notifyLearning: boolean; notifyPromotions: boolean };

const liveBanner = isNull(banners.deletedAt);

/** Banners, countdowns, daily activity, notifications and push tokens (spec §19, §20). */
export function createHomeRepository(db: Db) {
  const recipientColumns = {
    userId: users.id,
    notifyLearning: sql<boolean>`coalesce(${profiles.notifyLearning}, true)`,
    notifyPromotions: sql<boolean>`coalesce(${profiles.notifyPromotions}, false)`,
  };
  const activeStudents = and(eq(users.role, 'student'), eq(users.status, 'active'));

  return {
    // ---- banners ----

    listBanners: () =>
      db
        .select({ banner: banners, media: mediaFiles })
        .from(banners)
        .leftJoin(mediaFiles, eq(mediaFiles.id, banners.imageMediaId))
        .where(liveBanner)
        .orderBy(asc(banners.sortOrder), asc(banners.createdAt)),

    /** Banners students see now: active, inside their schedule, for this level or every level. */
    liveBanners: (levelId: string | null, at: Date) =>
      db
        .select({ banner: banners, media: mediaFiles })
        .from(banners)
        .innerJoin(mediaFiles, eq(mediaFiles.id, banners.imageMediaId))
        .where(
          and(
            liveBanner,
            eq(banners.isActive, true),
            or(isNull(banners.startsAt), lte(banners.startsAt, at)),
            or(isNull(banners.endsAt), gt(banners.endsAt, at)),
            levelId
              ? or(isNull(banners.educationLevelId), eq(banners.educationLevelId, levelId))
              : isNull(banners.educationLevelId),
            eq(mediaFiles.status, 'ready'),
          ),
        )
        .orderBy(asc(banners.sortOrder), asc(banners.createdAt)),

    async banner(id: string) {
      const [row] = await db
        .select({ banner: banners, media: mediaFiles })
        .from(banners)
        .leftJoin(mediaFiles, eq(mediaFiles.id, banners.imageMediaId))
        .where(and(eq(banners.id, id), liveBanner));
      return row ?? null;
    },

    insertBanner: async (values: typeof banners.$inferInsert) =>
      (await db.insert(banners).values(values).returning())[0]!,

    updateBanner: async (id: string, values: Partial<typeof banners.$inferInsert>) => {
      await db.update(banners).set(values).where(eq(banners.id, id));
    },

    async nextBannerOrder() {
      const [row] = await db
        .select({ max: sql<number | null>`max(${banners.sortOrder})` })
        .from(banners)
        .where(liveBanner);
      return (row?.max ?? -1) + 1;
    },

    async media(id: string) {
      const [row] = await db.select().from(mediaFiles).where(eq(mediaFiles.id, id));
      return row ?? null;
    },

    liveBannerIds: async () =>
      (await db.select({ id: banners.id }).from(banners).where(liveBanner)).map((r) => r.id),

    // ---- countdowns ----

    countdowns: () =>
      db.select().from(examCountdowns).orderBy(asc(examCountdowns.examDate), asc(examCountdowns.titleAr)),

    /** The level's next active exam on or after `today` (YYYY-MM-DD). */
    async nextCountdown(levelId: string, today: string) {
      const [row] = await db
        .select()
        .from(examCountdowns)
        .where(
          and(
            eq(examCountdowns.educationLevelId, levelId),
            eq(examCountdowns.isActive, true),
            gte(examCountdowns.examDate, today),
          ),
        )
        .orderBy(asc(examCountdowns.examDate))
        .limit(1);
      return row ?? null;
    },

    async countdown(id: string) {
      const [row] = await db.select().from(examCountdowns).where(eq(examCountdowns.id, id));
      return row ?? null;
    },
    insertCountdown: async (values: typeof examCountdowns.$inferInsert) =>
      (await db.insert(examCountdowns).values(values).returning())[0]!,
    updateCountdown: async (id: string, values: Partial<typeof examCountdowns.$inferInsert>) => {
      await db.update(examCountdowns).set(values).where(eq(examCountdowns.id, id));
    },
    deleteCountdown: async (id: string) => {
      await db.delete(examCountdowns).where(eq(examCountdowns.id, id));
    },

    // ---- daily goal (§19.4) ----

    /** Days with activity from `fromDay` on (YYYY-MM-DD), newest first. */
    activity: (userId: string, fromDay: string) =>
      db
        .select()
        .from(userDailyActivity)
        .where(and(eq(userDailyActivity.userId, userId), gte(userDailyActivity.day, fromDay)))
        .orderBy(desc(userDailyActivity.day)),

    async profile(userId: string) {
      const [row] = await db.select().from(profiles).where(eq(profiles.userId, userId));
      return row ?? null;
    },

    updateProfile: async (userId: string, values: Partial<typeof profiles.$inferInsert>) => {
      await db
        .update(profiles)
        .set({ ...values, updatedAt: new Date() })
        .where(eq(profiles.userId, userId));
    },

    /** The goal of today's row follows a change made today; past days keep theirs. */
    setTodayGoal: async (userId: string, day: string, goal: number) => {
      await db
        .update(userDailyActivity)
        .set({ goal, goalMet: sql`${userDailyActivity.itemsDone} >= ${goal}` })
        .where(and(eq(userDailyActivity.userId, userId), eq(userDailyActivity.day, day)));
    },

    // ---- notifications ----

    insertNotification: async (conn: Conn, values: typeof notifications.$inferInsert) =>
      (await conn.insert(notifications).values(values).returning())[0]!,

    async notification(id: string) {
      const [row] = await db.select().from(notifications).where(eq(notifications.id, id));
      return row ?? null;
    },

    updateNotification: async (id: string, values: Partial<typeof notifications.$inferInsert>) => {
      await db.update(notifications).set(values).where(eq(notifications.id, id));
    },

    listNotifications: (limit: number, offset: number) =>
      db
        .select({
          n: notifications,
          readCount: sql<number>`(select count(*)::int from user_notifications un where un.notification_id = ${notifications.id} and un.read_at is not null)`,
        })
        .from(notifications)
        .where(ne(notifications.type, 'due_reminder'))
        .orderBy(desc(notifications.createdAt), desc(notifications.id))
        .limit(limit)
        .offset(offset),

    /** Recipients of a target, in pages keyed by user id (§20.1). */
    recipients(
      target: { type: NotificationRow['targetType']; value: Record<string, unknown> },
      after: string | null,
      limit: number,
      at: Date,
    ) {
      const page = after ? gt(users.id, after) : undefined;
      const base = db.select(recipientColumns).from(users).leftJoin(profiles, eq(profiles.userId, users.id));
      const ent = (where: ReturnType<typeof eq>) =>
        sql`exists (select 1 from ${entitlements} where ${entitlements.userId} = ${users.id} and ${where} and ${entitlementActiveAt(at)})`;
      const v = target.value;
      const where = (() => {
        switch (target.type) {
          case 'all':
            return undefined;
          case 'level':
            return eq(profiles.educationLevelId, String(v.educationLevelId));
          case 'subject_entitlement':
            return ent(eq(entitlements.subjectId, String(v.subjectId)));
          case 'track_entitlement':
            return ent(eq(entitlements.teacherTrackId, String(v.teacherTrackId)));
          case 'teacher_followers':
            return sql`exists (select 1 from ${teacherFollowers} where ${teacherFollowers.userId} = ${users.id} and ${teacherFollowers.teacherId} = ${String(v.teacherId)})`;
          case 'students': {
            const ids = (v.userIds as string[] | undefined) ?? [];
            return ids.length ? inArray(users.id, ids) : sql`false`;
          }
        }
      })();
      return base
        .where(and(activeStudents, where, page))
        .orderBy(asc(users.id))
        .limit(limit);
    },

    async deliver(conn: Conn, notificationId: string, userIds: string[]) {
      if (!userIds.length) return 0;
      const rows = await conn
        .insert(userNotifications)
        .values(userIds.map((userId) => ({ notificationId, userId })))
        .onConflictDoNothing()
        .returning({ id: userNotifications.id });
      return rows.length;
    },

    inbox: (userId: string, limit: number, offset: number) =>
      db
        .select({ un: userNotifications, n: notifications })
        .from(userNotifications)
        .innerJoin(notifications, eq(notifications.id, userNotifications.notificationId))
        .where(eq(userNotifications.userId, userId))
        .orderBy(desc(userNotifications.createdAt), desc(userNotifications.id))
        .limit(limit)
        .offset(offset),

    async unreadCount(userId: string) {
      const [row] = await db
        .select({ n: count() })
        .from(userNotifications)
        .where(and(eq(userNotifications.userId, userId), isNull(userNotifications.readAt)));
      return row!.n;
    },

    async markRead(userId: string, id: string, at: Date) {
      const rows = await db
        .update(userNotifications)
        .set({ readAt: at })
        .where(and(eq(userNotifications.id, id), eq(userNotifications.userId, userId)))
        .returning({ id: userNotifications.id });
      return rows.length > 0;
    },

    markAllRead: async (userId: string, at: Date) => {
      await db
        .update(userNotifications)
        .set({ readAt: at })
        .where(and(eq(userNotifications.userId, userId), isNull(userNotifications.readAt)));
    },

    /** Whether the student already got a notification of this type since `since`. */
    async receivedSince(userId: string, type: NotificationRow['type'], since: Date) {
      const [row] = await db
        .select({ id: userNotifications.id })
        .from(userNotifications)
        .innerJoin(notifications, eq(notifications.id, userNotifications.notificationId))
        .where(
          and(
            eq(userNotifications.userId, userId),
            eq(notifications.type, type),
            gte(userNotifications.createdAt, since),
          ),
        )
        .limit(1);
      return Boolean(row);
    },

    // ---- reminders ----

    /** Students whose reminder time is in this hour ("HH"), with learning notifications on. */
    reminderCandidates: (hour: string) =>
      db
        .select({ userId: profiles.userId })
        .from(profiles)
        .innerJoin(users, eq(users.id, profiles.userId))
        .where(
          and(
            activeStudents,
            eq(profiles.notifyLearning, true),
            sql`substr(${profiles.reminderTime}, 1, 2) = ${hour}`,
          ),
        ),

    /** Reviewed cards due before `before` (the reminder counts, §20.3). */
    async dueCount(userId: string, before: Date) {
      const [row] = await db
        .select({ n: count() })
        .from(cardStates)
        .where(
          and(eq(cardStates.userId, userId), ne(cardStates.state, 'new'), lte(cardStates.dueAt, before)),
        );
      return row!.n;
    },

    // ---- push tokens ----

    async upsertToken(userId: string, token: string, platform: string, appVersion: string | null, at: Date) {
      await db
        .insert(pushTokens)
        .values({ userId, token, platform, appVersion, createdAt: at, lastSeenAt: at })
        .onConflictDoUpdate({
          target: pushTokens.token,
          set: { userId, platform, appVersion, lastSeenAt: at, revokedAt: null },
        });
    },

    revokeToken: async (userId: string, token: string, at: Date) => {
      await db
        .update(pushTokens)
        .set({ revokedAt: at })
        .where(and(eq(pushTokens.token, token), eq(pushTokens.userId, userId)));
    },

    revokeTokens: async (tokens: string[], at: Date) => {
      if (tokens.length)
        await db.update(pushTokens).set({ revokedAt: at }).where(inArray(pushTokens.token, tokens));
    },

    async tokensOf(userIds: string[]) {
      if (!userIds.length) return [];
      return db
        .select({ userId: pushTokens.userId, token: pushTokens.token })
        .from(pushTokens)
        .where(and(inArray(pushTokens.userId, userIds), isNull(pushTokens.revokedAt)));
    },

    liveTokenCount: async (userId: string) =>
      (
        await db
          .select({ n: count() })
          .from(pushTokens)
          .where(
            and(eq(pushTokens.userId, userId), isNull(pushTokens.revokedAt), isNotNull(pushTokens.token)),
          )
      )[0]!.n,
  };
}

export type HomeRepository = ReturnType<typeof createHomeRepository>;
