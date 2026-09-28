import { z } from 'zod';
import { myEntitlementSchema } from './access.js';
import { resumeItemSchema } from './learning.js';
import { teacherSchema } from './teachers.js';

/* Home, banners, exam countdown, daily goal and notifications (spec §19, §20). */

const int = () => z.number().int();
const hhmm = z.string().regex(/^([01]\d|2[0-3]):[0-5]\d$/);

export const bannerActionSchema = z.enum([
  'subject',
  'teacher',
  'teacher_track',
  'quiz',
  'deck',
  'internal_route',
  'external_url',
  'none',
]);

export const homeBannerSchema = z.object({
  id: z.string(),
  titleAr: z.string(),
  imageUrl: z.string(),
  width: int().nullable(),
  height: int().nullable(),
  action: bannerActionSchema,
  actionTarget: z.string().nullable(),
});

export const examCountdownSchema = z.object({
  titleAr: z.string(),
  examDate: z.string(),
  daysLeft: int(),
});

/** Today's work (§19.4): days start at 04:00 Asia/Damascus. */
export const todaySchema = z.object({
  dueCards: int(),
  goal: int(),
  done: int(),
  goalMet: z.boolean(),
  /** Consecutive days with the goal met, ending today (or yesterday while today is open). */
  streak: int(),
});

export const freeSubjectSchema = z.object({ subjectId: z.string(), nameAr: z.string(), freeCount: int() });

export const homeSchema = z.object({
  greetingName: z.string(),
  unreadNotifications: int(),
  countdown: examCountdownSchema.nullable(),
  banners: z.array(homeBannerSchema),
  today: todaySchema,
  resume: z.array(resumeItemSchema),
  /** Active entitlements: "موادّي" and "مساراتي". */
  myAccess: z.array(myEntitlementSchema),
  freeSubjects: z.array(freeSubjectSchema),
  followedTeachers: z.array(teacherSchema),
  activeMistakes: int(),
});

export const goalSettingsSchema = z.object({ dailyGoal: int().min(1).max(500) });

export const notificationPreferencesSchema = z.object({
  /** التعلّم: new content, teacher updates and reminders (on by default). */
  learning: z.boolean(),
  /** العروض: off until the student opts in; promotions never reach anyone else. */
  promotions: z.boolean(),
  /** Due-card reminder time, HH:MM Asia/Damascus. */
  reminderTime: hhmm,
});
export const updateNotificationPreferencesSchema = notificationPreferencesSchema.partial();

export const notificationTypeSchema = z.enum([
  'new_content',
  'teacher_update',
  'due_reminder',
  'study_reminder',
  'announcement',
  'promotion',
  'report_resolved',
]);

export const studentNotificationSchema = z.object({
  /** The inbox entry id. */
  id: z.string(),
  type: notificationTypeSchema,
  titleAr: z.string(),
  bodyAr: z.string(),
  action: bannerActionSchema,
  actionTarget: z.string().nullable(),
  createdAt: z.string(),
  readAt: z.string().nullable(),
});

export const notificationPageSchema = z.object({
  items: z.array(studentNotificationSchema),
  nextCursor: z.string().nullable(),
  unreadCount: int(),
});

export const notificationQuerySchema = z.object({
  cursor: z.string().max(200).optional(),
  limit: z.coerce.number().int().min(1).max(100).default(30),
});

export const pushTokenBodySchema = z.object({
  token: z.string().min(10).max(4096),
  platform: z.enum(['android', 'ios', 'web']),
  appVersion: z.string().max(40).optional(),
});

export const readResultSchema = z.object({ unreadCount: int() });
export const revokePushTokenBodySchema = z.object({ token: z.string().min(10).max(4096) });

// ---- admin ----

export const adminBannerSchema = z.object({
  id: z.string(),
  titleAr: z.string(),
  imageMediaId: z.string(),
  imageUrl: z.string().nullable(),
  action: bannerActionSchema,
  actionTarget: z.string().nullable(),
  educationLevelId: z.string().nullable(),
  startsAt: z.string().nullable(),
  endsAt: z.string().nullable(),
  isActive: z.boolean(),
  sortOrder: int(),
  /** Active, inside its schedule: what students see now. */
  live: z.boolean(),
  updatedAt: z.string(),
});
export const adminBannerListSchema = z.array(adminBannerSchema);

const bannerShape = {
  titleAr: z.string().trim().min(1).max(200),
  imageMediaId: z.uuid(),
  action: bannerActionSchema,
  actionTarget: z.string().trim().max(500).nullable().optional(),
  educationLevelId: z.uuid().nullable().optional(),
  startsAt: z.iso.datetime({ offset: true }).nullable().optional(),
  endsAt: z.iso.datetime({ offset: true }).nullable().optional(),
  isActive: z.boolean().optional(),
};
export const createBannerBodySchema = z.object({
  ...bannerShape,
  action: bannerActionSchema.default('none'),
});
/** No defaults here: a partial update must leave omitted fields alone. */
export const updateBannerBodySchema = z.object(bannerShape).partial();
export const bannerReorderBodySchema = z.object({ ids: z.array(z.uuid()).min(1).max(200) });

export const adminCountdownSchema = z.object({
  id: z.string(),
  educationLevelId: z.string(),
  titleAr: z.string(),
  examDate: z.string(),
  isActive: z.boolean(),
  daysLeft: int(),
});
export const adminCountdownListSchema = z.array(adminCountdownSchema);
const countdownShape = {
  educationLevelId: z.uuid(),
  titleAr: z.string().trim().min(1).max(200),
  examDate: z.iso.date(),
  isActive: z.boolean().optional(),
};
export const createCountdownBodySchema = z.object(countdownShape);
export const updateCountdownBodySchema = z.object(countdownShape).partial();

export const notificationTargetTypeSchema = z.enum([
  'all',
  'level',
  'subject_entitlement',
  'track_entitlement',
  'teacher_followers',
  'students',
]);

export const notificationTargetSchema = z.object({
  educationLevelId: z.uuid().optional(),
  subjectId: z.uuid().optional(),
  teacherTrackId: z.uuid().optional(),
  teacherId: z.uuid().optional(),
  userIds: z.array(z.uuid()).max(1000).optional(),
});

export const createNotificationBodySchema = z.object({
  type: notificationTypeSchema.exclude(['due_reminder', 'report_resolved']),
  titleAr: z.string().trim().min(1).max(120),
  bodyAr: z.string().trim().min(1).max(500),
  action: bannerActionSchema.default('none'),
  actionTarget: z.string().trim().max(500).nullable().optional(),
  targetType: notificationTargetTypeSchema,
  target: notificationTargetSchema.default({}),
});

export const notificationPreviewBodySchema = createNotificationBodySchema.pick({
  type: true,
  targetType: true,
  target: true,
});
/** Who a notification would reach now (§26.2 "targeting preview"). */
export const notificationPreviewSchema = z.object({
  /** Students who get the inbox entry (promotions: only those who opted in). */
  recipients: int(),
  /** Of those, how many allow a push for this type. */
  pushConsented: int(),
});

export const adminNotificationSchema = z.object({
  id: z.string(),
  type: notificationTypeSchema,
  titleAr: z.string(),
  bodyAr: z.string(),
  action: bannerActionSchema,
  actionTarget: z.string().nullable(),
  targetType: notificationTargetTypeSchema,
  target: notificationTargetSchema,
  status: z.enum(['queued', 'sending', 'sent', 'failed']),
  recipientCount: int(),
  pushCount: int(),
  pushFailures: int(),
  readCount: int(),
  createdAt: z.string(),
  sentAt: z.string().nullable(),
});
export const adminNotificationPageSchema = z.object({
  items: z.array(adminNotificationSchema),
  nextCursor: z.string().nullable(),
});

export type HomeBanner = z.infer<typeof homeBannerSchema>;
export type StudentNotification = z.infer<typeof studentNotificationSchema>;
export type AdminBanner = z.infer<typeof adminBannerSchema>;
export type AdminNotification = z.infer<typeof adminNotificationSchema>;
export type NotificationTarget = z.infer<typeof notificationTargetSchema>;

const named: [z.ZodType, string][] = [
  [bannerActionSchema, 'BannerAction'],
  [homeBannerSchema, 'HomeBanner'],
  [examCountdownSchema, 'ExamCountdown'],
  [todaySchema, 'Today'],
  [freeSubjectSchema, 'FreeSubject'],
  [homeSchema, 'Home'],
  [goalSettingsSchema, 'GoalSettings'],
  [notificationPreferencesSchema, 'NotificationPreferences'],
  [updateNotificationPreferencesSchema, 'UpdateNotificationPreferences'],
  [notificationTypeSchema, 'NotificationType'],
  [studentNotificationSchema, 'StudentNotification'],
  [notificationPageSchema, 'NotificationPage'],
  [pushTokenBodySchema, 'PushTokenRequest'],
  [readResultSchema, 'ReadResult'],
  [revokePushTokenBodySchema, 'RevokePushTokenRequest'],
  [adminBannerSchema, 'AdminBanner'],
  [adminBannerListSchema, 'AdminBannerList'],
  [createBannerBodySchema, 'CreateBannerRequest'],
  [updateBannerBodySchema, 'UpdateBannerRequest'],
  [bannerReorderBodySchema, 'BannerReorderRequest'],
  [adminCountdownSchema, 'AdminCountdown'],
  [adminCountdownListSchema, 'AdminCountdownList'],
  [createCountdownBodySchema, 'CreateCountdownRequest'],
  [updateCountdownBodySchema, 'UpdateCountdownRequest'],
  [notificationTargetTypeSchema, 'NotificationTargetType'],
  [notificationTargetSchema, 'NotificationTarget'],
  [createNotificationBodySchema, 'CreateNotificationRequest'],
  [notificationPreviewBodySchema, 'NotificationPreviewRequest'],
  [notificationPreviewSchema, 'NotificationPreview'],
  [adminNotificationSchema, 'AdminNotification'],
  [adminNotificationPageSchema, 'AdminNotificationPage'],
];
for (const [schema, id] of named) z.globalRegistry.add(schema, { id });
