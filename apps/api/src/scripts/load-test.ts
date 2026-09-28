/*
 * API load test against the §34.1 targets (p95: home ≤ 500 ms, deck page / card batch ≤ 400 ms,
 * grading ≤ 500 ms, stats ≤ 500 ms). Builds the real app on a scratch database, seeds the §40
 * content, registers students through the public endpoints, listens on a local port and drives it
 * over HTTP with concurrent virtual students.
 *
 *   DATABASE_URL=postgres://…/scratch STUDENTS=300 RATE=100 DURATION=60 \
 *     node --conditions=@plengo/source --import tsx src/scripts/load-test.ts
 *
 * Never point it at production: it writes students, attempts and activity.
 */
import { performance } from 'node:perf_hooks';
import { eq } from 'drizzle-orm';
import { educationLevels, runMigrations, subjects } from '@plengo/db';
import { buildApp, createFastify } from '../app.js';
import { ConsoleEmailSender } from '../auth/email.js';
import { createContainer } from '../container.js';
import { loadEnv } from '../env.js';
import { InlineQueue } from '../jobs/queue.js';
import { MemoryStorage } from '../storage/memory-storage.js';
import {
  seedAccess,
  seedFlashcards,
  seedLearning,
  seedQuestions,
  seedStructure,
  seedTeachers,
} from './seed.js';

const STUDENTS = Number(process.env.STUDENTS ?? 300);
const CONCURRENCY = Number(process.env.CONCURRENCY ?? 100);
const DURATION = Number(process.env.DURATION ?? 60) * 1000;
/**
 * Open-loop mode: requests arrive at RATE per second whatever the response times, like independent
 * students (≈ 1,000 active students at one request every 10 s ≈ 100 req/s, the §34.1 "nominal
 * load"). Without RATE, CONCURRENCY closed-loop clients send back to back (a capacity test).
 */
const RATE = process.env.RATE ? Number(process.env.RATE) : null;
const PASSWORD = 'load-test-password-1';

const TARGETS: Record<string, number> = { home: 500, deck: 400, cards: 400, check: 500, stats: 500 };
/** Share of each request type in the mix (a study session: mostly cards and answers). */
const MIX: [string, number][] = [
  ['home', 0.2],
  ['deck', 0.1],
  ['cards', 0.25],
  ['check', 0.3],
  ['stats', 0.15],
];

const env = loadEnv({
  NODE_ENV: 'production',
  APP_ENV: 'test',
  LOG_LEVEL: 'silent',
  DATABASE_POOL_MAX: process.env.DATABASE_POOL_MAX ?? '20',
  BETTER_AUTH_SECRET: 'load-test-better-auth-secret-0123456789',
  BETTER_AUTH_URL: 'http://api.load.local',
  APP_WEB_ORIGIN: 'http://app.load.local',
  ADMIN_ORIGIN: 'http://admin.load.local',
  MOBILE_ACCESS_JWT_SECRET: 'load-test-access-secret-0123456789abcdef',
  MOBILE_REFRESH_TOKEN_PEPPER: 'load-test-refresh-pepper-0123456789abcd',
  COUPON_HMAC_SECRET: 'load-test-coupon-hmac-secret-0123456789ab',
  COUPON_ENCRYPTION_KEY: Buffer.alloc(32, 9).toString('base64'),
  STORAGE_DRIVER: 'memory',
  EMAIL_PROVIDER: 'console',
  JOBS_ENABLED: 'false',
  ...process.env,
});
if (/neon\.tech|prod/i.test(env.DATABASE_URL))
  throw new Error('refusing to load-test a production-looking database');

const app = createFastify({ logger: { level: 'silent' } });
const email = new ConsoleEmailSender();
const queue = new InlineQueue();
const c = createContainer(env, app.log, { email, storage: new MemoryStorage(), jobs: queue });
await runMigrations(c.db);
await buildApp(app, c);
await app.ready();

console.log('seeding §40 content…');
await seedStructure(c.db);
await seedTeachers(c.db);
await seedAccess(c, queue);
await seedQuestions(c);
await seedFlashcards(c);
await seedLearning(c);
await queue.drain(c.jobHandlers);

const [level] = await c.db.select().from(educationLevels).where(eq(educationLevels.code, 'grade-12'));
const [physics] = await c.db.select().from(subjects).where(eq(subjects.code, 'g12-physics'));

console.log(`registering ${STUDENTS} students…`);
const tokens: string[] = [];
for (let i = 0; i < STUDENTS; i++) {
  const addr = `load-${Date.now().toString(36)}-${i}@example.com`;
  const remoteAddress = `10.${(i >> 16) & 255}.${(i >> 8) & 255}.${i & 255}`;
  const reg = await app.inject({
    method: 'POST',
    url: '/api/v1/auth/register',
    remoteAddress,
    payload: { fullName: `طالب ${i}`, email: addr, password: PASSWORD, educationLevelId: level!.id },
  });
  if (reg.statusCode !== 200) throw new Error(`register: ${reg.body}`);
  const otp = /\b(\d{6})\b/.exec([...email.outbox].reverse().find((m) => m.to === addr)!.text)![1];
  await app.inject({
    method: 'POST',
    url: '/api/v1/auth/verify-email',
    remoteAddress,
    payload: { email: addr, otp },
  });
  const login = await app.inject({
    method: 'POST',
    url: '/api/v1/auth/mobile/login',
    remoteAddress,
    payload: { email: addr, password: PASSWORD, platform: 'android', appVersion: '1.0.0' },
  });
  tokens.push(login.json().data.accessToken);
}

await app.listen({ host: '127.0.0.1', port: 0 });
const base = `http://127.0.0.1:${(app.server.address() as { port: number }).port}/api/v1`;
const get = async (path: string, token: string) => {
  const res = await fetch(`${base}${path}`, { headers: { authorization: `Bearer ${token}` } });
  return { status: res.status, body: (await res.json()) as { data: never } };
};

// Content the students can use: the subject's free, published questions and decks.
type Q = { id: string; type: string; locked: boolean; options: { id: string }[] | null };
const qs = (await get(`/questions?subjectId=${physics!.id}&limit=50`, tokens[0]!)).body.data as unknown as {
  items: Q[];
};
const questions = qs.items.filter((q) => !q.locked && q.type !== 'written' && q.options?.length);
const decks = (
  (await get(`/decks?subjectId=${physics!.id}`, tokens[0]!)).body.data as unknown as {
    id: string;
    locked: boolean;
  }[]
).filter((d) => !d.locked);
if (!questions.length || !decks.length) throw new Error('seed content missing (free questions or decks)');

const samples = new Map<string, number[]>(MIX.map(([name]) => [name, []]));
const errors = new Map<string, number>();
const pick = () => {
  let r = Math.random();
  for (const [name, share] of MIX) if ((r -= share) <= 0) return name;
  return MIX[0]![0];
};
const any = <T>(list: T[]) => list[Math.floor(Math.random() * list.length)]!;

async function request(name: string, token: string) {
  const started = performance.now();
  let res: Response;
  switch (name) {
    case 'home':
      res = await fetch(`${base}/home`, { headers: { authorization: `Bearer ${token}` } });
      break;
    case 'deck':
      res = await fetch(`${base}/decks/${any(decks).id}`, { headers: { authorization: `Bearer ${token}` } });
      break;
    case 'cards':
      res = await fetch(`${base}/decks/${any(decks).id}/cards`, {
        headers: { authorization: `Bearer ${token}` },
      });
      break;
    case 'check': {
      const q = any(questions);
      res = await fetch(`${base}/questions/${q.id}/check`, {
        method: 'POST',
        headers: { authorization: `Bearer ${token}`, 'content-type': 'application/json' },
        body: JSON.stringify({ selectedOptionId: any(q.options!).id }),
      });
      break;
    }
    default:
      res = await fetch(`${base}/stats/overview`, { headers: { authorization: `Bearer ${token}` } });
  }
  await res.arrayBuffer();
  const ms = performance.now() - started;
  if (res.status !== 200) errors.set(`${name} ${res.status}`, (errors.get(`${name} ${res.status}`) ?? 0) + 1);
  else samples.get(name)!.push(ms);
}

const end = Date.now() + DURATION;
const started = Date.now();
if (RATE) {
  console.log(`sending ${RATE} requests/s from ${STUDENTS} students for ${DURATION / 1000}s…`);
  const inflight = new Set<Promise<void>>();
  for (let n = 0; Date.now() < end; n++) {
    const due = started + (n * 1000) / RATE;
    if (due > Date.now()) await new Promise((r) => setTimeout(r, due - Date.now()));
    const p: Promise<void> = request(pick(), any(tokens)).finally(() => inflight.delete(p));
    inflight.add(p);
  }
  await Promise.all(inflight);
} else {
  console.log(`running ${CONCURRENCY} concurrent students for ${DURATION / 1000}s…`);
  await Promise.all(
    Array.from({ length: CONCURRENCY }, async (_, w) => {
      while (Date.now() < end) await request(pick(), tokens[w % tokens.length]!);
    }),
  );
}
const seconds = (Date.now() - started) / 1000;

const pct = (sorted: number[], p: number) =>
  sorted[Math.min(sorted.length - 1, Math.floor((p / 100) * sorted.length))] ?? 0;
let total = 0;
let failed = false;
console.log('\nrequest   count    rps   p50 ms  p95 ms  p99 ms  max ms  target p95');
for (const [name] of MIX) {
  const s = samples.get(name)!.sort((a, b) => a - b);
  total += s.length;
  const p95 = pct(s, 95);
  const ok = p95 <= TARGETS[name]!;
  if (!ok) failed = true;
  console.log(
    `${name.padEnd(8)} ${String(s.length).padStart(6)} ${(s.length / seconds).toFixed(1).padStart(6)} ${pct(s, 50).toFixed(0).padStart(8)} ${p95
      .toFixed(0)
      .padStart(
        7,
      )} ${pct(s, 99).toFixed(0).padStart(7)} ${(s.at(-1) ?? 0).toFixed(0).padStart(7)}  ≤ ${TARGETS[name]} ${ok ? '✓' : '✗'}`,
  );
}
console.log(
  `\n${total} requests in ${seconds.toFixed(0)} s (${(total / seconds).toFixed(0)} req/s), ${STUDENTS} students, ${RATE ? `open loop at ${RATE}/s` : `${CONCURRENCY} concurrent`}`,
);
if (errors.size) console.log('errors:', Object.fromEntries(errors));
await app.close();
await c.pool.end();
process.exit(failed || errors.size ? 1 : 0);
