import type { FastifyBaseLogger } from 'fastify';
import type pg from 'pg';
import { createDb, createPool, type Db } from '@plengo/db';
import { createAuth, type Auth } from './auth/better-auth.js';
import { ConsoleEmailSender, ResendEmailSender, type EmailSender } from './auth/email.js';
import { createGuards, type Guards } from './authorization/guards.js';
import type { Env } from './env.js';
import type { JobHandlers, JobQueue } from './jobs/queue.js';
import { createCouponCrypto } from './lib/coupon-code.js';
import { createIpHasher } from './lib/crypto.js';
import { createAccessRepository } from './repositories/access-repository.js';
import { createFlashcardRepository } from './repositories/flashcard-repository.js';
import { createAttemptRepository } from './repositories/attempt-repository.js';
import { createBookmarkRepository } from './repositories/bookmark-repository.js';
import { createLearningRepository } from './repositories/learning-repository.js';
import { createQuestionRepository } from './repositories/question-repository.js';
import { createQuizRepository } from './repositories/quiz-repository.js';
import { createSrsRepository } from './repositories/srs-repository.js';
import { createStatsRepository } from './repositories/stats-repository.js';
import { createSessionsRepository, type SessionsRepository } from './repositories/sessions-repository.js';
import { createStructureRepository, type StructureRepository } from './repositories/structure-repository.js';
import { createTeacherRepository } from './repositories/teacher-repository.js';
import { createUsersRepository, type UsersRepository } from './repositories/users-repository.js';
import { createOfflineRepository } from './repositories/offline-repository.js';
import { createHomeRepository } from './repositories/home-repository.js';
import { createAdminToolsRepository } from './repositories/admin-tools-repository.js';
import { createImportRepository } from './repositories/import-repository.js';
import { createReportRepository } from './repositories/report-repository.js';
import { createUserContentRepository } from './repositories/user-content-repository.js';
import { createAccessService, type AccessService } from './services/access-service.js';
import { createAuditService, type AuditService } from './services/audit-service.js';
import { createCouponService, type CouponService } from './services/coupon-service.js';
import {
  createFlashcardService,
  deckFreeSource,
  type FlashcardService,
} from './services/flashcard-service.js';
import { createFreeRuleService, type FreeRuleService } from './services/free-rule-service.js';
import { createSrsService, type SrsService } from './services/srs-service.js';
import { createAttemptService, type AttemptService } from './services/attempt-service.js';
import { createAdminService, type AdminService } from './services/admin-service.js';
import { createLearningService, type LearningService } from './services/learning-service.js';
import { createQuizService, quizFreeSource, type QuizService } from './services/quiz-service.js';
import { createStatsService, type StatsService } from './services/stats-service.js';
import { createPromotionService, type PromotionService } from './services/promotion-service.js';
import {
  createQuestionService,
  questionFreeSource,
  type QuestionService,
} from './services/question-service.js';
import { createAuthService, type AuthService } from './services/auth-service.js';
import { createCatalogService, type CatalogService } from './services/catalog-service.js';
import { createConfigService, type ConfigService } from './services/config-service.js';
import { createMediaProcessor, type MediaProcessor } from './services/media-processing.js';
import { createMobileTokenService, type MobileTokenService } from './services/mobile-token-service.js';
import { createStructureService, type StructureService } from './services/structure-service.js';
import { createTeacherService, type TeacherService } from './services/teacher-service.js';
import { createUploadService, type UploadService } from './services/upload-service.js';
import { createOfflineService, type OfflineService } from './services/offline-service.js';
import { createHomeService, type HomeService } from './services/home-service.js';
import { createAdminToolsService, type AdminToolsService } from './services/admin-tools-service.js';
import { createImportService, type ImportService } from './services/import-service.js';
import { createNotificationService, type NotificationService } from './services/notification-service.js';
import { FcmPushSender, RecordingPushSender, type PushSender } from './services/push.js';
import { createReportService, type ReportService } from './services/report-service.js';
import { createUserContentService, type UserContentService } from './services/user-content-service.js';
import { MemoryStorage } from './storage/memory-storage.js';
import { R2Storage } from './storage/r2-storage.js';
import type { ObjectStorage } from './storage/storage.js';

export interface Container {
  env: Env;
  pool: pg.Pool;
  db: Db;
  auth: Auth;
  email: EmailSender;
  storage: ObjectStorage;
  jobs: JobQueue;
  hashIp: (ip: string) => string | null;
  usersRepo: UsersRepository;
  sessionsRepo: SessionsRepository;
  mobileTokens: MobileTokenService;
  authService: AuthService;
  configService: ConfigService;
  audit: AuditService;
  uploadService: UploadService;
  structureRepo: StructureRepository;
  structure: StructureService;
  catalog: CatalogService;
  teachers: TeacherService;
  access: AccessService;
  coupons: CouponService;
  promotions: PromotionService;
  freeRules: FreeRuleService;
  questions: QuestionService;
  flashcards: FlashcardService;
  srs: SrsService;
  quizzes: QuizService;
  attempts: AttemptService;
  learning: LearningService;
  stats: StatsService;
  admins: AdminService;
  userContent: UserContentService;
  reports: ReportService;
  adminTools: AdminToolsService;
  imports: ImportService;
  offline: OfflineService;
  home: HomeService;
  notifications: NotificationService;
  push: PushSender;
  media: MediaProcessor;
  guards: Guards;
  jobHandlers: JobHandlers;
}

export function createStorage(env: Env): ObjectStorage {
  if (env.STORAGE_DRIVER === 'memory') {
    return new MemoryStorage({
      baseUrl: env.BETTER_AUTH_URL,
      secret: env.BETTER_AUTH_SECRET,
      ...(env.LOCAL_STORAGE_DIR ? { dir: env.LOCAL_STORAGE_DIR } : {}),
    });
  }
  return new R2Storage({
    endpoint: env.R2_ENDPOINT ?? `https://${env.R2_ACCOUNT_ID}.r2.cloudflarestorage.com`,
    accessKeyId: env.R2_ACCESS_KEY_ID!,
    secretAccessKey: env.R2_SECRET_ACCESS_KEY!,
    privateBucket: env.R2_PRIVATE_BUCKET!,
    publicBucket: env.R2_PUBLIC_BUCKET!,
    publicBaseUrl: env.R2_PUBLIC_BASE_URL!,
  });
}

export function createEmailSender(env: Env, log: FastifyBaseLogger): EmailSender {
  return env.EMAIL_PROVIDER === 'resend'
    ? new ResendEmailSender(env.EMAIL_PROVIDER_API_KEY!, env.EMAIL_FROM)
    : new ConsoleEmailSender(log);
}

/** Composition root: every service gets its dependencies here and nowhere else. */
export function createContainer(
  env: Env,
  log: FastifyBaseLogger,
  overrides: {
    pool?: pg.Pool;
    email?: EmailSender;
    storage?: ObjectStorage;
    jobs: JobQueue;
    now?: () => Date;
    push?: PushSender;
  },
): Container {
  const pool = overrides.pool ?? createPool(env.DATABASE_URL, env.DATABASE_POOL_MAX);
  const db = createDb(pool);
  const email = overrides.email ?? createEmailSender(env, log);
  const storage = overrides.storage ?? createStorage(env);
  const hashIp = createIpHasher(env.BETTER_AUTH_SECRET);
  const auth = createAuth({ env, db, email });
  const usersRepo = createUsersRepository(db);
  const sessionsRepo = createSessionsRepository(db);
  const mobileTokens = createMobileTokenService({
    db,
    sessionsRepo,
    accessSecret: env.MOBILE_ACCESS_JWT_SECRET,
    refreshPepper: env.MOBILE_REFRESH_TOKEN_PEPPER,
    now: overrides.now,
  });
  const media = createMediaProcessor({ db, storage, appEnv: env.APP_ENV, log });
  const audit = createAuditService(db, hashIp);
  const structureRepo = createStructureRepository(db);
  const structure = createStructureService({ db, repo: structureRepo, audit, storage });
  const configService = createConfigService(db);
  const accessRepo = createAccessRepository(db);
  const access = createAccessService({
    db,
    repo: accessRepo,
    config: configService,
    audit,
    timeZone: env.TZ_BUSINESS,
    now: overrides.now,
  });
  const coupons = createCouponService({
    db,
    access,
    accessRepo,
    config: configService,
    audit,
    jobs: overrides.jobs,
    crypto: createCouponCrypto(env.COUPON_HMAC_SECRET, env.COUPON_ENCRYPTION_KEY),
    hashIp,
    timeZone: env.TZ_BUSINESS,
    now: overrides.now,
  });
  const promotions = createPromotionService({ db, accessRepo, audit, now: overrides.now });
  const questionRepo = createQuestionRepository(db);
  const imports = createImportService({
    db,
    repo: createImportRepository(db),
    questionRepo,
    audit,
    jobs: overrides.jobs,
    now: overrides.now,
  });
  const flashcardRepo = createFlashcardRepository(db);
  const quizRepo = createQuizRepository(db);
  const attemptRepo = createAttemptRepository(db);
  const learningRepo = createLearningRepository(db);
  const srsRepo = createSrsRepository(db);
  // Each content table registers its free-content source (§8.4).
  const freeRules = createFreeRuleService({
    db,
    accessRepo,
    structureRepo,
    audit,
    jobs: overrides.jobs,
    sources: [questionFreeSource(questionRepo), deckFreeSource(flashcardRepo), quizFreeSource(quizRepo)],
  });
  const teacherRepo = createTeacherRepository(db);
  const questions = createQuestionService({
    db,
    repo: questionRepo,
    structureRepo,
    teacherRepo,
    access,
    freeRules,
    audit,
    inOpenExam: (userId, questionId) => attemptRepo.inOpenExam(userId, questionId),
    onVisibilityChange: (questionId) => quizRepo.bumpContaining(questionId),
    onGraded: (userId) =>
      learningRepo.addDailyActivity(db, userId, (overrides.now ?? (() => new Date()))(), 1),
    now: overrides.now,
  });
  const flashcards = createFlashcardService({
    db,
    repo: flashcardRepo,
    structureRepo,
    teacherRepo,
    access,
    freeRules,
    audit,
    storage,
    now: overrides.now,
  });
  const userContent = createUserContentService({
    db,
    repo: createUserContentRepository(db),
    flashcardRepo,
    flashcards,
    structureRepo,
    teacherRepo,
    access,
    now: overrides.now,
  });
  const srs = createSrsService({
    db,
    repo: srsRepo,
    userContent,
    flashcardRepo,
    learningRepo,
    flashcards,
    structureRepo,
    teacherRepo,
    access,
    now: overrides.now,
  });
  const quizzes = createQuizService({
    db,
    repo: quizRepo,
    questionRepo,
    attemptRepo,
    structureRepo,
    teacherRepo,
    access,
    freeRules,
    audit,
    now: overrides.now,
  });
  const attempts = createAttemptService({
    db,
    repo: attemptRepo,
    questionRepo,
    learningRepo,
    quizRepo,
    quizService: quizzes,
    structureRepo,
    teacherRepo,
    access,
    config: configService,
    now: overrides.now,
  });
  const learning = createLearningService({
    repo: learningRepo,
    bookmarkRepo: createBookmarkRepository(db),
    attemptRepo,
    srsRepo,
    questionRepo,
    quizRepo,
    flashcardRepo,
    flashcards,
    userContent,
    structureRepo,
    teacherRepo,
    access,
    config: configService,
    now: overrides.now,
  });
  const stats = createStatsService({
    repo: createStatsRepository(db),
    structureRepo,
    teacherRepo,
    access,
    mistakeCounts: (userId) => learning.mistakeCounts(userId),
    now: overrides.now,
  });
  const teachers = createTeacherService({
    repo: teacherRepo,
    structureRepo,
    structure,
    storage,
    access,
    questionCounts: (scope) => questions.counts(scope),
    deckCounts: (scope) => flashcards.counts(scope),
    quizCounts: (scope) => quizzes.counts(scope),
  });
  const push =
    overrides.push ??
    (env.FCM_PROJECT_ID && env.FCM_CLIENT_EMAIL && env.FCM_PRIVATE_KEY
      ? new FcmPushSender(
          {
            projectId: env.FCM_PROJECT_ID,
            clientEmail: env.FCM_CLIENT_EMAIL,
            // Env files keep the key on one line with escaped newlines.
            privateKey: env.FCM_PRIVATE_KEY.replace(/\\n/g, '\n'),
          },
          log,
        )
      : new RecordingPushSender(log));
  const homeRepo = createHomeRepository(db);
  const notifications = createNotificationService({
    db,
    repo: homeRepo,
    structureRepo,
    teacherRepo,
    audit,
    jobs: overrides.jobs,
    push,
    now: overrides.now,
  });
  const catalog = createCatalogService({
    repo: structureRepo,
    usersRepo,
    storage,
    access,
    questionCounts: (scope) => questions.counts(scope),
    deckCounts: (scope) => flashcards.counts(scope),
    quizCounts: (scope) => quizzes.counts(scope),
    subjectTracks: (id) => teachers.subjectTracks(id),
  });

  return {
    env,
    pool,
    db,
    auth,
    email,
    storage,
    jobs: overrides.jobs,
    hashIp,
    usersRepo,
    sessionsRepo,
    mobileTokens,
    authService: createAuthService({ auth, usersRepo, sessionsRepo, mobileTokens, catalog }),
    configService,
    audit,
    uploadService: createUploadService({ db, storage, jobs: overrides.jobs, appEnv: env.APP_ENV }),
    media,
    structureRepo,
    structure,
    catalog,
    teachers,
    access,
    coupons,
    promotions,
    freeRules,
    questions,
    flashcards,
    srs,
    quizzes,
    attempts,
    learning,
    stats,
    admins: createAdminService({ db, auth, usersRepo, sessionsRepo, audit }),
    userContent,
    offline: createOfflineService({
      repo: createOfflineRepository(db),
      questionRepo,
      structureRepo,
      teacherRepo,
      access,
      attempts,
      storage,
      now: overrides.now,
    }),
    notifications,
    push,
    home: createHomeService({
      repo: homeRepo,
      structureRepo,
      storage,
      audit,
      catalog,
      access,
      learning,
      srs,
      teachers,
      notifications,
      counts: [
        (scope) => questions.counts(scope),
        (scope) => flashcards.counts(scope),
        (scope) => quizzes.counts(scope),
      ],
      now: overrides.now,
    }),
    reports: createReportService({
      repo: createReportRepository(db),
      questionRepo,
      flashcardRepo,
      structureRepo,
      teacherRepo,
      audit,
      notify: (userId, input) => notifications.notifyUser(userId, input),
      now: overrides.now,
    }),
    adminTools: createAdminToolsService({
      repo: createAdminToolsRepository(db),
      coupons,
      audit,
      timeZone: env.TZ_BUSINESS,
    }),
    imports,
    guards: createGuards({ auth, sessionsRepo, mobileTokens, now: overrides.now }),
    jobHandlers: {
      'media.process': (data) => media.process(data),
      'media.cleanup-orphans': async () => {
        await media.cleanupOrphans();
      },
      'coupons.generate': (data) => coupons.generateBatch(data.batchId),
      'access.recompute-free': (scope) =>
        freeRules.recompute(
          scope.scopeType === 'subject'
            ? { scopeType: 'subject', subjectId: scope.subjectId!, teacherTrackId: null }
            : { scopeType: 'teacher_track', subjectId: null, teacherTrackId: scope.teacherTrackId! },
        ),
      'access.expire-entitlements': async () => {
        await access.expireAllStale();
      },
      'questions.renormalize': async () => {
        await questions.renormalizeAnswers();
      },
      'attempts.abandon-stale': async () => {
        await attempts.abandonStale();
      },
      'notifications.fanout': (data) => notifications.fanout(data.notificationId),
      'notifications.due-reminders': async () => {
        await notifications.dueReminders();
      },
      'imports.parse': (data) => imports.parse(data.jobId),
      'imports.commit': (data) => imports.commit(data),
    },
  };
}
