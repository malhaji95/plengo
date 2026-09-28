/**
 * Creates the store-review demo account (docs/release.md):
 *   REVIEW_PASSWORD=… pnpm --filter @plengo/api review:create --email review@<domain> \
 *     --level grade-12 --subjects g12-physics,g12-math --granted-by admin@<domain>
 */
import { parseArgs } from 'node:util';
import { createFastify } from '../app.js';
import { createContainer } from '../container.js';
import { loadEnv } from '../env.js';
import { InlineQueue } from '../jobs/queue.js';
import { randomToken } from '../lib/crypto.js';
import { createReviewAccount } from '../services/review-account.js';

const { values } = parseArgs({
  options: {
    email: { type: 'string' },
    name: { type: 'string', default: 'حساب المراجعة' },
    level: { type: 'string', default: 'grade-12' },
    subjects: { type: 'string', default: '' },
    'granted-by': { type: 'string' },
  },
});
if (!values.email || !values['granted-by']) {
  console.error(
    'usage: review:create --email <email> --granted-by <admin email> [--level code] [--subjects a,b]',
  );
  process.exit(1);
}

const env = loadEnv();
const c = createContainer(env, createFastify({ logger: { level: 'warn' } }).log, { jobs: new InlineQueue() });
const password = process.env.REVIEW_PASSWORD ?? randomToken(12);
try {
  const created = await createReviewAccount(c, {
    email: values.email,
    name: values.name!,
    password,
    levelCode: values.level!,
    subjectCodes: values
      .subjects!.split(',')
      .map((s) => s.trim())
      .filter(Boolean),
    grantedByAdminEmail: values['granted-by'],
  });
  console.log(`review account created (${created.subjects.join(', ') || 'no subjects'})`);
  if (!process.env.REVIEW_PASSWORD) console.log(`password (shown once): ${password}`);
} finally {
  await c.pool.end();
}
