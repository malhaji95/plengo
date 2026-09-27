import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { PgBossQueue, QUEUES } from '../src/jobs/queue.js';
import { createTestApp, type TestContext } from './helpers.js';

let t: TestContext;
beforeAll(async () => {
  t = await createTestApp();
});
afterAll(async () => {
  await t.close();
});

describe('pg-boss queue', () => {
  it('delivers a job to its worker through Postgres', async () => {
    const queue = new PgBossQueue(process.env.TEST_DB_URL!, t.app.log);
    const seen: string[] = [];
    let resolve!: () => void;
    const delivered = new Promise<void>((r) => (resolve = r));
    await queue.start(
      {
        [QUEUES.mediaProcess]: async ({ mediaId }) => {
          seen.push(mediaId);
          resolve();
        },
        [QUEUES.mediaCleanup]: async () => {},
      },
      { workers: true },
    );
    try {
      await queue.send(QUEUES.mediaProcess, { mediaId: 'job-smoke-test' });
      await Promise.race([
        delivered,
        new Promise((_, rej) => setTimeout(() => rej(new Error('timeout')), 15_000)),
      ]);
      expect(seen).toEqual(['job-smoke-test']);
    } finally {
      await queue.stop();
    }
  });
});
