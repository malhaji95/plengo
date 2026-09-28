import { index, integer, jsonb, pgTable, text, timestamp, uuid } from 'drizzle-orm/pg-core';
import { importFormatEnum, importKindEnum, importStatusEnum } from './enums.js';
import { users } from './identity.js';

/**
 * A bulk question import (spec §27): parsed and validated by a job, previewed with per-row errors,
 * then committed in one transaction. `rows` holds the validated rows until the import completes.
 */
export const importJobs = pgTable(
  'import_jobs',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    kind: importKindEnum('kind').notNull(),
    format: importFormatEnum('format').notNull(),
    fileName: text('file_name').notNull(),
    status: importStatusEnum('status').notNull().default('parsing'),
    totalRows: integer('total_rows').notNull().default(0),
    validRows: integer('valid_rows').notNull().default(0),
    errorCount: integer('error_count').notNull().default(0),
    /** The uploaded file, base64; dropped once parsed. */
    fileData: text('file_data'),
    rows: jsonb('rows').$type<unknown[]>(),
    summary: jsonb('summary').$type<Record<string, unknown>>(),
    failureReason: text('failure_reason'),
    createdByAdminId: uuid('created_by_admin_id').references(() => users.id, { onDelete: 'set null' }),
    createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
    completedAt: timestamp('completed_at', { withTimezone: true }),
  },
  (t) => [index('import_jobs_created_idx').on(t.createdAt)],
);

export const importErrors = pgTable(
  'import_errors',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    jobId: uuid('job_id')
      .notNull()
      .references(() => importJobs.id, { onDelete: 'cascade' }),
    /** 1-based spreadsheet row (the header is row 1). */
    rowNumber: integer('row_number').notNull(),
    field: text('field'),
    message: text('message').notNull(),
  },
  (t) => [index('import_errors_job_row_idx').on(t.jobId, t.rowNumber)],
);
