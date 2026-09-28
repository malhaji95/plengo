import { sql } from 'drizzle-orm';
import { boolean, index, integer, pgTable, text, timestamp, uuid } from 'drizzle-orm/pg-core';
import { sessionPlatformEnum, userRoleEnum, userStatusEnum } from './enums.js';

/*
 * Better Auth owns the physical shape of users / sessions / accounts / verification_codes /
 * admin_two_factor (spec §28.1). Property names must match Better Auth's field names; columns are
 * snake_case. Application fields are appended and registered as Better Auth `additionalFields`.
 */

const timestamps = {
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
};

export const users = pgTable('users', {
  id: uuid('id').primaryKey().defaultRandom(),
  name: text('name').notNull(),
  email: text('email').notNull().unique(),
  emailVerified: boolean('email_verified').notNull().default(false),
  image: text('image'),
  twoFactorEnabled: boolean('two_factor_enabled').notNull().default(false),
  role: userRoleEnum('role').notNull().default('student'),
  status: userStatusEnum('status').notNull().default('active'),
  ...timestamps,
  /** Set when the account was deleted; personal data is gone from this row (§33). */
  deletedAt: timestamp('deleted_at', { withTimezone: true }),
});

export const sessions = pgTable(
  'sessions',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    userId: uuid('user_id')
      .notNull()
      .references(() => users.id, { onDelete: 'cascade' }),
    token: text('token').notNull().unique(),
    expiresAt: timestamp('expires_at', { withTimezone: true }).notNull(),
    ipAddress: text('ip_address'),
    userAgent: text('user_agent'),
    platform: sessionPlatformEnum('platform').notNull().default('web'),
    appVersion: text('app_version'),
    ipHash: text('ip_hash'),
    lastSeenAt: timestamp('last_seen_at', { withTimezone: true }).notNull().defaultNow(),
    ...timestamps,
  },
  (t) => [index('sessions_user_id_idx').on(t.userId)],
);

export const accounts = pgTable(
  'accounts',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    userId: uuid('user_id')
      .notNull()
      .references(() => users.id, { onDelete: 'cascade' }),
    accountId: text('account_id').notNull(),
    providerId: text('provider_id').notNull(),
    accessToken: text('access_token'),
    refreshToken: text('refresh_token'),
    idToken: text('id_token'),
    accessTokenExpiresAt: timestamp('access_token_expires_at', { withTimezone: true }),
    refreshTokenExpiresAt: timestamp('refresh_token_expires_at', { withTimezone: true }),
    scope: text('scope'),
    password: text('password'),
    ...timestamps,
  },
  (t) => [index('accounts_user_id_idx').on(t.userId)],
);

export const verificationCodes = pgTable(
  'verification_codes',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    identifier: text('identifier').notNull(),
    value: text('value').notNull(),
    expiresAt: timestamp('expires_at', { withTimezone: true }).notNull(),
    ...timestamps,
  },
  (t) => [index('verification_codes_identifier_idx').on(t.identifier)],
);

export const adminTwoFactor = pgTable('admin_two_factor', {
  id: uuid('id').primaryKey().defaultRandom(),
  userId: uuid('user_id')
    .notNull()
    .unique()
    .references(() => users.id, { onDelete: 'cascade' }),
  secret: text('secret').notNull(),
  backupCodes: text('backup_codes').notNull(),
  verified: boolean('verified').default(false),
  failedVerificationCount: integer('failed_verification_count').default(0),
  lockedUntil: timestamp('locked_until', { withTimezone: true }),
});

/**
 * First-party mobile refresh tokens (spec §2.3, §28.1). One row per issued token; raw tokens are
 * never stored. `session_id` ties the token family to a `sessions` row so students see and revoke
 * mobile sessions alongside web sessions (see docs/architecture.md ADR-004).
 */
export const mobileRefreshTokens = pgTable(
  'mobile_refresh_tokens',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    userId: uuid('user_id')
      .notNull()
      .references(() => users.id, { onDelete: 'cascade' }),
    sessionId: uuid('session_id')
      .notNull()
      .references(() => sessions.id, { onDelete: 'cascade' }),
    sessionFamilyId: uuid('session_family_id').notNull(),
    tokenHash: text('token_hash').notNull().unique(),
    previousTokenHash: text('previous_token_hash'),
    retryGraceExpiresAt: timestamp('retry_grace_expires_at', { withTimezone: true }),
    graceReissueCount: integer('grace_reissue_count').notNull().default(0),
    expiresAt: timestamp('expires_at', { withTimezone: true }).notNull(),
    revokedAt: timestamp('revoked_at', { withTimezone: true }),
    replacedById: uuid('replaced_by_id'),
    createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
    lastUsedAt: timestamp('last_used_at', { withTimezone: true }),
  },
  (t) => [
    index('mobile_refresh_tokens_family_idx').on(t.sessionFamilyId),
    index('mobile_refresh_tokens_user_idx').on(t.userId),
    index('mobile_refresh_tokens_active_idx')
      .on(t.sessionId)
      .where(sql`${t.revokedAt} is null`),
  ],
);
