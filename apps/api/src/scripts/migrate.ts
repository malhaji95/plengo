/** Applies pending Drizzle migrations; run once per deploy before starting new API containers. */
import { createDb, createPool, runMigrations } from '@plengo/db';

const url = process.env.DATABASE_URL;
if (!url) throw new Error('DATABASE_URL is required');
const pool = createPool(url, 1);
try {
  await runMigrations(createDb(pool));
  console.log('migrations applied');
} finally {
  await pool.end();
}
