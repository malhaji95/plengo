import { sql } from 'drizzle-orm';
import { bigserial, check, index, integer, pgTable, text, timestamp, uuid } from 'drizzle-orm/pg-core';
import { flashcards } from './content.js';
import { reportItemTypeEnum, reportReasonEnum, reportStatusEnum, userCardKindEnum } from './enums.js';
import { users } from './identity.js';
import { mediaFiles } from './media.js';
import { subjects } from './structure.js';

/*
 * Private student decks (spec §13.9). Ids are generated on the device so decks and cards can be
 * created offline; the server keeps the latest write by the client's `updated_at`. `sync_seq` is
 * renumbered from a sequence on every accepted write and drives the changes feed other devices
 * pull, so a device with a wrong clock cannot hide its edits from the feed.
 */
export const userDecks = pgTable(
  'user_decks',
  {
    id: uuid('id').primaryKey(),
    userId: uuid('user_id')
      .notNull()
      .references(() => users.id, { onDelete: 'cascade' }),
    name: text('name').notNull(),
    subjectId: uuid('subject_id').references(() => subjects.id, { onDelete: 'set null' }),
    color: text('color'),
    sortOrder: integer('sort_order').notNull().default(0),
    createdAt: timestamp('created_at', { withTimezone: true }).notNull(),
    updatedAt: timestamp('updated_at', { withTimezone: true }).notNull(),
    deletedAt: timestamp('deleted_at', { withTimezone: true }),
    syncSeq: bigserial('sync_seq', { mode: 'number' }).notNull(),
  },
  (t) => [index('user_decks_user_seq_idx').on(t.userId, t.syncSeq)],
);

export const userCards = pgTable(
  'user_cards',
  {
    id: uuid('id').primaryKey(),
    deckId: uuid('deck_id')
      .notNull()
      .references(() => userDecks.id, { onDelete: 'cascade' }),
    userId: uuid('user_id')
      .notNull()
      .references(() => users.id, { onDelete: 'cascade' }),
    kind: userCardKindEnum('kind').notNull(),
    frontText: text('front_text'),
    backText: text('back_text'),
    frontMediaId: uuid('front_media_id').references(() => mediaFiles.id),
    backMediaId: uuid('back_media_id').references(() => mediaFiles.id),
    officialFlashcardId: uuid('official_flashcard_id').references(() => flashcards.id),
    sortOrder: integer('sort_order').notNull().default(0),
    createdAt: timestamp('created_at', { withTimezone: true }).notNull(),
    updatedAt: timestamp('updated_at', { withTimezone: true }).notNull(),
    deletedAt: timestamp('deleted_at', { withTimezone: true }),
    syncSeq: bigserial('sync_seq', { mode: 'number' }).notNull(),
  },
  (t) => [
    check('user_cards_kind_ck', sql`(${t.kind} = 'official_ref') = (${t.officialFlashcardId} is not null)`),
    index('user_cards_user_seq_idx').on(t.userId, t.syncSeq),
    index('user_cards_deck_idx').on(t.deckId),
  ],
);

/** "إبلاغ عن مشكلة" on a question or official flashcard (spec §21). */
export const contentReports = pgTable(
  'content_reports',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    userId: uuid('user_id')
      .notNull()
      .references(() => users.id, { onDelete: 'cascade' }),
    itemType: reportItemTypeEnum('item_type').notNull(),
    itemId: uuid('item_id').notNull(),
    reason: reportReasonEnum('reason').notNull(),
    note: text('note'),
    status: reportStatusEnum('status').notNull().default('open'),
    resolvedByAdminId: uuid('resolved_by_admin_id').references(() => users.id, { onDelete: 'set null' }),
    resolutionNote: text('resolution_note'),
    createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
    resolvedAt: timestamp('resolved_at', { withTimezone: true }),
  },
  (t) => [
    index('content_reports_status_created_idx').on(t.status, t.createdAt),
    index('content_reports_user_created_idx').on(t.userId, t.createdAt),
    index('content_reports_item_idx').on(t.itemType, t.itemId),
  ],
);
