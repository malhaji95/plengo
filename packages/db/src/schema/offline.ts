import { boolean, index, pgTable, timestamp, uuid } from 'drizzle-orm/pg-core';
import { questions } from './content.js';
import { scopeTypeEnum } from './enums.js';
import { sessions, users } from './identity.js';
import { quizAttempts } from './learning.js';
import { subjects } from './structure.js';
import { teacherTracks } from './teachers.js';

/*
 * Offline packs (spec §22). A lease lets one device (session) use a scope's premium pack content
 * until `expires_at` = min(now + 30 days, the entitlement's end). Free content needs no lease.
 */
export const offlineLeases = pgTable(
  'offline_leases',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    userId: uuid('user_id')
      .notNull()
      .references(() => users.id, { onDelete: 'cascade' }),
    sessionId: uuid('session_id').references(() => sessions.id, { onDelete: 'set null' }),
    scopeType: scopeTypeEnum('scope_type').notNull(),
    subjectId: uuid('subject_id').references(() => subjects.id),
    teacherTrackId: uuid('teacher_track_id').references(() => teacherTracks.id),
    issuedAt: timestamp('issued_at', { withTimezone: true }).notNull(),
    expiresAt: timestamp('expires_at', { withTimezone: true }).notNull(),
    revokedAt: timestamp('revoked_at', { withTimezone: true }),
  },
  (t) => [index('offline_leases_user_session_idx').on(t.userId, t.sessionId)],
);

/**
 * An offline answer the device graded differently from the server's re-grade (§22.6): a sign of
 * an outdated pack or tampering, kept for admin review. The server grade is what counts.
 */
export const offlineGradeMismatches = pgTable(
  'offline_grade_mismatches',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    userId: uuid('user_id')
      .notNull()
      .references(() => users.id, { onDelete: 'cascade' }),
    attemptId: uuid('attempt_id')
      .notNull()
      .references(() => quizAttempts.id, { onDelete: 'cascade' }),
    questionId: uuid('question_id')
      .notNull()
      .references(() => questions.id),
    localCorrect: boolean('local_correct').notNull(),
    serverCorrect: boolean('server_correct').notNull(),
    createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  },
  (t) => [index('offline_grade_mismatches_created_idx').on(t.createdAt)],
);
