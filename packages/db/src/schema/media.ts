import { index, integer, jsonb, pgTable, text, timestamp, uuid } from 'drizzle-orm/pg-core';
import { mediaBucketEnum, mediaKindEnum, mediaStatusEnum } from './enums.js';
import { users } from './identity.js';

export type MediaVariants = Partial<
  Record<'full' | 'thumb', { key: string; width: number; height: number; size: number }>
>;

/** spec §12.4. `storage_key` is the original upload's key; processed variants live in `variants`. */
export const mediaFiles = pgTable(
  'media_files',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    bucket: mediaBucketEnum('bucket').notNull(),
    storageKey: text('storage_key').notNull().unique(),
    kind: mediaKindEnum('kind').notNull(),
    ownerUserId: uuid('owner_user_id').references(() => users.id, { onDelete: 'set null' }),
    uploadedByAdminId: uuid('uploaded_by_admin_id').references(() => users.id, { onDelete: 'set null' }),
    mimeType: text('mime_type').notNull(),
    width: integer('width'),
    height: integer('height'),
    originalSize: integer('original_size').notNull(),
    optimizedSize: integer('optimized_size'),
    variants: jsonb('variants').$type<MediaVariants>().notNull().default({}),
    status: mediaStatusEnum('status').notNull().default('pending'),
    failureReason: text('failure_reason'),
    version: integer('version').notNull().default(1),
    createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
    deletedAt: timestamp('deleted_at', { withTimezone: true }),
  },
  (t) => [
    index('media_files_owner_idx').on(t.ownerUserId),
    index('media_files_status_created_idx').on(t.status, t.createdAt),
  ],
);
