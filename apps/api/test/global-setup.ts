import pg from 'pg';
import { createDb, createPool, runMigrations } from '@plengo/db';

/**
 * Creates a fresh `plengo_test` database next to TEST_DATABASE_URL (default: local Postgres) and
 * applies all migrations. Tests share it and isolate by using unique emails.
 */
export default async function setup() {
  const adminUrl = process.env.TEST_DATABASE_URL ?? 'postgres://postgres@localhost:5432/postgres';
  const dbName = process.env.TEST_DATABASE_NAME ?? 'plengo_test';
  const admin = new pg.Client({ connectionString: adminUrl });
  await admin.connect();
  await admin.query(`DROP DATABASE IF EXISTS ${dbName} WITH (FORCE)`);
  await admin.query(`CREATE DATABASE ${dbName}`);
  await admin.end();

  const url = new URL(adminUrl);
  url.pathname = `/${dbName}`;
  process.env.TEST_DB_URL = url.toString();

  const pool = createPool(url.toString(), 1);
  await runMigrations(createDb(pool));
  // Tests written before v3 expect no default free lessons; the v3 tests turn it on and back off.
  await pool.query(
    `insert into app_settings (key, value) values
       ('access', '{"allowTemporaryToPermanentUpgrade": true, "defaultFreeLessons": 0}'),
       ('free_defaults_applied', '{"defaultFreeLessons": 0}')
     on conflict (key) do nothing`,
  );
  await pool.end();
}
