import type { AdminSearchHit, AuditLogEntry, QuestionAnalyticsRow } from '@plengo/contracts';
import { AppError } from '../lib/app-error.js';
import { startOfBusinessDay } from '../lib/business-time.js';
import type {
  AdminToolsRepository,
  AnalyticsFilter,
  AnalyticsSort,
} from '../repositories/admin-tools-repository.js';
import { decodeCursor, encodeCursor } from '../repositories/question-repository.js';
import {
  QUESTION_FLAG_MAX_CORRECT_PERCENT,
  QUESTION_FLAG_MIN_ATTEMPTS,
} from '../repositories/learning-repository.js';
import type { AuditService } from './audit-service.js';
import type { CouponService } from './coupon-service.js';
import type { AdminActor } from './structure-service.js';

const PER_TYPE = 8;
const DAY = 86_400_000;

type AnalyticsRow = Awaited<ReturnType<AdminToolsRepository['analytics']>>[number];

/** Audit log, global search and question analytics for the admin (spec §26.2, §32). */
export function createAdminToolsService(deps: {
  repo: AdminToolsRepository;
  coupons: CouponService;
  audit: AuditService;
  timeZone: string;
}) {
  const { repo, coupons, audit, timeZone } = deps;

  const toRow = (r: AnalyticsRow): QuestionAnalyticsRow => {
    const attempts = r.stats?.attemptCount ?? 0;
    return {
      questionId: r.q.id,
      type: r.q.type,
      questionText: r.q.questionText,
      status: r.q.status,
      subjectId: r.q.subjectId,
      subjectNameAr: r.subjectNameAr,
      teacherTrackId: r.q.teacherTrackId,
      trackTitleAr: r.trackTitleAr,
      attempts,
      correctPercent: attempts ? Math.round((r.stats!.correctCount / attempts) * 1000) / 10 : null,
      averageTimeMs: attempts ? Math.round(r.stats!.totalTimeMs / attempts) : null,
      flagged: r.stats?.flaggedForReview ?? false,
      openReports: r.openReports,
      offlineMismatches: r.mismatches,
      lastAttemptAt: r.stats?.lastAttemptAt?.toISOString() ?? null,
    };
  };

  return {
    async auditLog(
      filter: {
        actorAdminId?: string | undefined;
        action?: string | undefined;
        resourceType?: string | undefined;
        resourceId?: string | undefined;
        from?: string | undefined;
        to?: string | undefined;
      },
      cursor: string | undefined,
      limit: number,
    ) {
      const offset = decodeCursor(cursor);
      const rows = await repo.auditLog(
        {
          ...filter,
          from: filter.from ? startOfBusinessDay(filter.from, timeZone) : undefined,
          to: filter.to ? new Date(startOfBusinessDay(filter.to, timeZone).getTime() + DAY) : undefined,
        },
        limit + 1,
        offset,
      );
      const items: AuditLogEntry[] = rows.slice(0, limit).map(({ log, name, email }) => ({
        id: log.id,
        actorAdminId: log.actorAdminId,
        actorName: name,
        actorEmail: email,
        action: log.action,
        resourceType: log.resourceType,
        resourceId: log.resourceId,
        metadata: log.metadata,
        createdAt: log.createdAt.toISOString(),
      }));
      return { items, nextCursor: rows.length > limit ? encodeCursor(offset + limit) : null };
    },

    /** Admins, students, teachers, tracks, subjects, questions, coupons (full code or last 4) and batches. */
    async search(q: string): Promise<{ items: AdminSearchHit[] }> {
      const r = await repo.search(q, PER_TYPE);
      const hit = (h: Omit<AdminSearchHit, 'parentId'> & { parentId?: string | null }): AdminSearchHit => ({
        parentId: null,
        ...h,
      });
      const items: AdminSearchHit[] = [
        ...r.people
          .filter((p) => p.role === 'admin')
          .slice(0, PER_TYPE)
          .map((p) => hit({ type: 'admin', id: p.id, title: p.name, subtitle: p.email })),
        ...r.people
          .filter((p) => p.role === 'student')
          .slice(0, PER_TYPE)
          .map((p) => hit({ type: 'student', id: p.id, title: p.name, subtitle: p.email })),
        ...r.teacherRows.map((t) => hit({ type: 'teacher', id: t.id, title: t.nameAr, subtitle: t.slug })),
        ...r.trackRows.map((t) =>
          hit({ type: 'track', id: t.id, title: t.titleAr, subtitle: t.teacherName, parentId: t.teacherId }),
        ),
        ...r.subjectRows.map((s) => hit({ type: 'subject', id: s.id, title: s.nameAr, subtitle: s.code })),
        ...r.questionRows.map((x) =>
          hit({
            type: 'question',
            id: x.id,
            title: x.questionText.length > 120 ? `${x.questionText.slice(0, 120)}…` : x.questionText,
            subtitle: x.subjectNameAr,
          }),
        ),
        ...r.batchRows.map((b) =>
          hit({ type: 'batch', id: b.id, title: b.name, subtitle: b.distributorName }),
        ),
      ];
      // A coupon code or its last four characters (§26.2); anything else simply matches no coupon.
      try {
        const found = await coupons.searchCoupons(q);
        items.push(
          ...found.slice(0, PER_TYPE).map((c) =>
            hit({
              type: 'coupon',
              id: c.id,
              title: `…${c.codeLast4}`,
              subtitle: c.batchName,
              parentId: c.batchId,
            }),
          ),
        );
      } catch (err) {
        if (!(err instanceof AppError)) throw err;
      }
      return { items };
    },

    async analytics(filter: AnalyticsFilter, sort: AnalyticsSort, cursor: string | undefined, limit: number) {
      const offset = decodeCursor(cursor);
      const rows = await repo.analytics(filter, sort, limit + 1, offset);
      return {
        items: rows.slice(0, limit).map(toRow),
        nextCursor: rows.length > limit ? encodeCursor(offset + limit) : null,
      };
    },

    async analyticsDetail(questionId: string) {
      const [row] = await repo.analytics({ questionId }, 'attempts', 1, 0);
      if (!row) throw new AppError('NOT_FOUND');
      const base = toRow(row);
      const distribution = row.stats?.optionDistribution ?? {};
      const options = await repo.options(questionId);
      const answered = Object.values(distribution).reduce((a, b) => a + b, 0);
      const stats = options.map((o) => {
        const count = distribution[o.id] ?? 0;
        return {
          optionId: o.id,
          text: o.text,
          isCorrect: o.isCorrect,
          count,
          percent: answered ? Math.round((count / answered) * 1000) / 10 : 0,
        };
      });
      const flagReasons: ('low_correct' | 'wrong_option_preferred')[] = [];
      if (base.attempts >= QUESTION_FLAG_MIN_ATTEMPTS) {
        if ((base.correctPercent ?? 100) < QUESTION_FLAG_MAX_CORRECT_PERCENT) flagReasons.push('low_correct');
        const correct = stats.find((s) => s.isCorrect)?.count ?? 0;
        if (stats.some((s) => !s.isCorrect && s.count > correct)) flagReasons.push('wrong_option_preferred');
      }
      return { ...base, options: stats, flagReasons };
    },

    /** The admin reviewed a flagged question; the rule looks again after 30 more attempts. Audited. */
    async clearFlag(actor: AdminActor, questionId: string) {
      if (!(await repo.clearFlag(questionId))) throw new AppError('NOT_FOUND');
      await audit.record({
        actorAdminId: actor.adminId,
        action: 'question.flag_cleared',
        resourceType: 'question',
        resourceId: questionId,
        ip: actor.ip,
      });
      return this.analyticsDetail(questionId);
    },
  };
}

export type AdminToolsService = ReturnType<typeof createAdminToolsService>;
