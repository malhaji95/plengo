/**
 * Creates the first (or any) admin account from the command line (spec §11.3):
 *   pnpm --filter @plengo/api admin:create --email a@b.c --name "اسم المشرف"
 * The password comes from ADMIN_PASSWORD or is generated and printed once.
 * The admin enrolls in TOTP on first login.
 */
import { parseArgs } from 'node:util';
import { randomToken } from '../lib/crypto.js';
import { createFastify } from '../app.js';
import { createContainer } from '../container.js';
import { loadEnv } from '../env.js';
import { InlineQueue } from '../jobs/queue.js';

const { values } = parseArgs({ options: { email: { type: 'string' }, name: { type: 'string' } } });
if (!values.email || !values.name) {
  console.error('usage: admin:create --email <email> --name <name>');
  process.exit(1);
}

const env = loadEnv();
const log = createFastify({ logger: { level: 'warn' } }).log;
const c = createContainer(env, log, { jobs: new InlineQueue() });
const email = values.email.trim().toLowerCase();
const password = process.env.ADMIN_PASSWORD ?? randomToken(18);

try {
  if (await c.usersRepo.findByEmail(email)) throw new Error(`a user with ${email} already exists`);
  const res = await c.auth.api.signUpEmail({ body: { name: values.name, email, password } });
  await c.usersRepo.setRoleAndVerified(res.user.id, 'admin', true);
  await c.usersRepo.upsertProfile({ userId: res.user.id, fullName: values.name });
  await c.audit.record({
    actorAdminId: null,
    action: 'admin.created_via_cli',
    resourceType: 'admin',
    resourceId: res.user.id,
  });
  console.log(`admin created: ${email}`);
  if (!process.env.ADMIN_PASSWORD) console.log(`temporary password (shown once): ${password}`);
} finally {
  await c.pool.end();
}
