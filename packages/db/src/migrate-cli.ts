import { createDb, createPool } from './client.js';
import { runMigrations } from './migrate.js';

const url = process.env.DATABASE_URL;
if (!url) throw new Error('DATABASE_URL is required');
const pool = createPool(url, 1);
await runMigrations(createDb(pool));
await pool.end();
console.log('migrations applied');
