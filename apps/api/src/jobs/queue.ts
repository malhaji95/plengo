import { PgBoss } from 'pg-boss';
import type { FastifyBaseLogger } from 'fastify';

export const QUEUES = {
  mediaProcess: 'media.process',
  mediaCleanup: 'media.cleanup-orphans',
  couponsGenerate: 'coupons.generate',
  recomputeFree: 'access.recompute-free',
  expireEntitlements: 'access.expire-entitlements',
  renormalizeAnswers: 'questions.renormalize',
  abandonAttempts: 'attempts.abandon-stale',
  notificationsFanout: 'notifications.fanout',
  dueReminders: 'notifications.due-reminders',
  importsParse: 'imports.parse',
  importsCommit: 'imports.commit',
} as const;

export type QueueName = (typeof QUEUES)[keyof typeof QUEUES];

export interface JobPayloads {
  'media.process': { mediaId: string };
  'media.cleanup-orphans': Record<string, never>;
  'coupons.generate': { batchId: string };
  'access.recompute-free': {
    scopeType: 'subject' | 'teacher_track';
    subjectId: string | null;
    teacherTrackId: string | null;
  };
  'access.expire-entitlements': Record<string, never>;
  'questions.renormalize': Record<string, never>;
  'attempts.abandon-stale': Record<string, never>;
  'notifications.fanout': { notificationId: string };
  'notifications.due-reminders': Record<string, never>;
  'imports.parse': { jobId: string };
  'imports.commit': { jobId: string; publish: boolean; adminId: string; ip: string | null };
}

/** What services depend on: enqueueing only. Workers are registered at process start. */
export interface JobQueue {
  send<N extends QueueName>(
    name: N,
    data: JobPayloads[N],
    options?: { singletonKey?: string },
  ): Promise<void>;
}

export type JobHandlers = { [N in QueueName]: (data: JobPayloads[N]) => Promise<void> };

/** pg-boss backed queue (spec §2.3): jobs live in Postgres, no extra infrastructure. */
export class PgBossQueue implements JobQueue {
  readonly boss: PgBoss;

  constructor(
    connectionString: string,
    private readonly log: FastifyBaseLogger,
  ) {
    this.boss = new PgBoss({ connectionString, schema: 'pgboss' });
    this.boss.on('error', (err) => log.error({ err }, 'pg-boss error'));
  }

  async start(handlers: JobHandlers, options: { workers: boolean }) {
    await this.boss.start();
    for (const name of Object.values(QUEUES)) {
      await this.boss.createQueue(name, { retryLimit: 3, retryDelay: 30, retryBackoff: true });
    }
    if (!options.workers) return;
    await this.boss.schedule(QUEUES.mediaCleanup, '17 * * * *');
    // Reporting only: access already follows the clock on every request (spec §8.2).
    await this.boss.schedule(QUEUES.expireEntitlements, '5 0 * * *', {}, { tz: 'Asia/Damascus' });
    // Attempts idle for 7 days become abandoned (§15.5).
    await this.boss.schedule(QUEUES.abandonAttempts, '20 3 * * *', {}, { tz: 'Asia/Damascus' });
    // Due-card reminders at each student's chosen time (§20.3); the job picks this hour's students.
    await this.boss.schedule(QUEUES.dueReminders, '0 * * * *', {}, { tz: 'Asia/Damascus' });
    // After a deploy that bumps the normalizer version, stored accepted answers catch up (§14.5).
    await this.boss.send(QUEUES.renormalizeAnswers, {}, { singletonKey: 'startup' });
    for (const name of Object.values(QUEUES)) {
      await this.boss.work<JobPayloads[typeof name]>(name, { batchSize: 1 }, async (jobs) => {
        for (const job of jobs) {
          await (handlers[name] as (d: unknown) => Promise<void>)(job.data);
        }
      });
    }
    this.log.info('job workers started');
  }

  async send<N extends QueueName>(name: N, data: JobPayloads[N], options?: { singletonKey?: string }) {
    await this.boss.send(
      name,
      data,
      options?.singletonKey ? { singletonKey: options.singletonKey } : undefined,
    );
  }

  async stop() {
    await this.boss.stop({ graceful: true, timeout: 10_000 });
  }
}

/** Test/dev queue that records jobs; `drain` runs them with the given handlers. */
export class InlineQueue implements JobQueue {
  readonly pending: { name: QueueName; data: unknown }[] = [];

  async send<N extends QueueName>(name: N, data: JobPayloads[N]) {
    this.pending.push({ name, data });
  }

  async drain(handlers: JobHandlers) {
    while (this.pending.length) {
      const job = this.pending.shift()!;
      await (handlers[job.name] as (d: unknown) => Promise<void>)(job.data);
    }
  }
}
