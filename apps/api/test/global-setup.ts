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
  await pool.end();
}
