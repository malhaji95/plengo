import type { FastifyBaseLogger } from 'fastify';
import type pg from 'pg';
import { createDb, createPool, type Db } from '@plengo/db';
import { createAuth, type Auth } from './auth/better-auth.js';
import { ConsoleEmailSender, ResendEmailSender, type EmailSender } from './auth/email.js';
import { createGuards, type Guards } from './authorization/guards.js';
import type { Env } from './env.js';
import type { JobHandlers, JobQueue } from './jobs/queue.js';
import { createIpHasher } from './lib/crypto.js';
import { createSessionsRepository, type SessionsRepository } from './repositories/sessions-repository.js';
import { createStructureRepository, type StructureRepository } from './repositories/structure-repository.js';
import { createUsersRepository, type UsersRepository } from './repositories/users-repository.js';
import { createAuditService, type AuditService } from './services/audit-service.js';
import { createAuthService, type AuthService } from './services/auth-service.js';
import { createCatalogService, type CatalogService } from './services/catalog-service.js';
import { createConfigService, type ConfigService } from './services/config-service.js';
import { createMediaProcessor, type MediaProcessor } from './services/media-processing.js';
import { createMobileTokenService, type MobileTokenService } from './services/mobile-token-service.js';
import { createStructureService, type StructureService } from './services/structure-service.js';
import { createUploadService, type UploadService } from './services/upload-service.js';
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
  media: MediaProcessor;
  guards: Guards;
  jobHandlers: JobHandlers;
}

export function createStorage(env: Env): ObjectStorage {
  if (env.STORAGE_DRIVER === 'memory') return new MemoryStorage();
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
  const catalog = createCatalogService({ repo: structureRepo, usersRepo, storage });

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
    configService: createConfigService(db),
    audit,
    uploadService: createUploadService({ db, storage, jobs: overrides.jobs, appEnv: env.APP_ENV }),
    media,
    structureRepo,
    structure: createStructureService({ db, repo: structureRepo, audit, storage }),
    catalog,
    guards: createGuards({ auth, sessionsRepo, mobileTokens, now: overrides.now }),
    jobHandlers: {
      'media.process': (data) => media.process(data),
      'media.cleanup-orphans': async () => {
        await media.cleanupOrphans();
      },
    },
  };
}
