import { REPORTS_PER_DAY, type AdminReport, type Report } from '@plengo/contracts';
import { decodeCursor, encodeCursor } from '../repositories/question-repository.js';
import type { FlashcardRepository } from '../repositories/flashcard-repository.js';
import type { QuestionRepository } from '../repositories/question-repository.js';
import type { ReportFilter, ReportRepository, ReportRow } from '../repositories/report-repository.js';
import type { StructureRepository } from '../repositories/structure-repository.js';
import type { TeacherRepository } from '../repositories/teacher-repository.js';
import { AppError } from '../lib/app-error.js';
import type { AuditService } from './audit-service.js';
import { assertVisibleScope } from './content-placement.js';
import type { AdminActor } from './structure-service.js';

const DAY_MS = 24 * 60 * 60 * 1000;

const toReport = (r: ReportRow): Report => ({
  id: r.id,
  itemType: r.itemType,
  itemId: r.itemId,
  reason: r.reason,
  note: r.note,
  status: r.status,
  createdAt: r.createdAt.toISOString(),
  resolvedAt: r.resolvedAt?.toISOString() ?? null,
});

/** "إبلاغ عن مشكلة" (spec §21): students report questions and official cards; admins resolve. */
export function createReportService(deps: {
  repo: ReportRepository;
  questionRepo: QuestionRepository;
  flashcardRepo: FlashcardRepository;
  structureRepo: StructureRepository;
  teacherRepo: TeacherRepository;
  audit: AuditService;
  /** Tells the student their report was handled (optional, §21). */
  notify?: (
    userId: string,
    input: { type: 'report_resolved'; titleAr: string; bodyAr: string },
  ) => Promise<unknown>;
  now?: () => Date;
}) {
  const { repo, questionRepo, flashcardRepo, structureRepo, teacherRepo, audit } = deps;
  const now = deps.now ?? (() => new Date());
  const visible = (subjectId: string, trackId: string | null) =>
    assertVisibleScope({ structureRepo, teacherRepo }, subjectId, trackId);

  /** The student can see the item: published, in a visible subject and track. */
  async function assertReportable(type: ReportRow['itemType'], id: string) {
    if (type === 'question') {
      const q = await questionRepo.get(id);
      if (!q || q.status !== 'published') throw new AppError('NOT_FOUND');
      await visible(q.subjectId, q.teacherTrackId);
      return;
    }
    const c = await flashcardRepo.getCard(id);
    const d = c ? await flashcardRepo.getDeck(c.deckId) : null;
    if (!c || c.status !== 'published' || !d || d.status !== 'published') throw new AppError('NOT_FOUND');
    await visible(d.subjectId, d.teacherTrackId);
  }

  async function toAdmin(rows: { report: ReportRow; name: string; email: string }[]): Promise<AdminReport[]> {
    const ids = (t: ReportRow['itemType']) =>
      rows.filter((r) => r.report.itemType === t).map((r) => r.report.itemId);
    const questions = new Map((await questionRepo.byIds(ids('question'))).map((q) => [q.id, q]));
    const cards = new Map((await flashcardRepo.cardsByIds(ids('flashcard'))).map((c) => [c.id, c]));
    const deckIds = [...new Set([...cards.values()].map((c) => c.deckId))];
    const decks = new Map<string, { titleAr: string; subjectId: string }>();
    for (const id of deckIds) {
      const d = await flashcardRepo.getDeck(id);
      if (d) decks.set(id, d);
    }
    const subjectIds = [
      ...new Set([
        ...[...questions.values()].map((q) => q.subjectId),
        ...[...decks.values()].map((d) => d.subjectId),
      ]),
    ];
    const names = await flashcardRepo.names(subjectIds, []);
    const open = await repo.openCounts([...new Set(rows.map((r) => r.report.itemId))]);

    return rows.map(({ report: r, name, email }) => {
      let title: string | null;
      let subjectId: string | null;
      let deckId: string | null = null;
      if (r.itemType === 'question') {
        const q = questions.get(r.itemId);
        title = q ? q.questionText.slice(0, 160) : null;
        subjectId = q?.subjectId ?? null;
      } else {
        const c = cards.get(r.itemId);
        const d = c ? decks.get(c.deckId) : undefined;
        deckId = c?.deckId ?? null;
        title = d ? `${d.titleAr} · بطاقة ${c!.sortOrder + 1}` : null;
        subjectId = d?.subjectId ?? null;
      }
      return {
        ...toReport(r),
        studentId: r.userId,
        studentName: name,
        studentEmail: email,
        resolutionNote: r.resolutionNote,
        resolvedByAdminId: r.resolvedByAdminId,
        itemTitleAr: title,
        subjectId,
        subjectNameAr: subjectId ? (names.subjects.get(subjectId) ?? null) : null,
        deckId,
        openReportsOnItem: open.get(r.itemId) ?? 0,
      };
    });
  }

  return {
    /**
     * One open report per student and item (a repeat returns it unchanged); at most
     * `REPORTS_PER_DAY` new reports in any 24 hours.
     */
    async create(
      userId: string,
      input: {
        itemType: ReportRow['itemType'];
        itemId: string;
        reason: ReportRow['reason'];
        note?: string | null | undefined;
      },
    ): Promise<Report> {
      await assertReportable(input.itemType, input.itemId);
      const existing = await repo.openByStudentItem(userId, input.itemType, input.itemId);
      if (existing) return toReport(existing);
      if ((await repo.countSince(userId, new Date(now().getTime() - DAY_MS))) >= REPORTS_PER_DAY) {
        throw new AppError('RATE_LIMITED');
      }
      return toReport(
        await repo.insert({
          userId,
          itemType: input.itemType,
          itemId: input.itemId,
          reason: input.reason,
          note: input.note?.trim() || null,
          createdAt: now(),
        }),
      );
    },

    mine: async (userId: string) => (await repo.mine(userId, 100)).map(toReport),

    async adminList(
      { itemId, ...filter }: Omit<ReportFilter, 'itemIds'> & { itemId?: string | undefined },
      cursor: string | undefined,
      limit: number,
    ) {
      const offset = decodeCursor(cursor);
      const rows = await repo.list({ ...filter, itemIds: itemId ? [itemId] : undefined }, limit + 1, offset);
      return {
        items: await toAdmin(rows.slice(0, limit)),
        nextCursor: rows.length > limit ? encodeCursor(offset + limit) : null,
      };
    },

    async adminGet(id: string) {
      const row = await repo.get(id);
      if (!row) throw new AppError('NOT_FOUND');
      return (await toAdmin([row]))[0]!;
    },

    async resolve(
      actor: AdminActor,
      id: string,
      input: {
        status: 'resolved' | 'dismissed';
        resolutionNote?: string | null | undefined;
        notifyStudent?: boolean | undefined;
      },
    ) {
      const row = await repo.get(id);
      if (!row) throw new AppError('NOT_FOUND');
      await repo.resolve(id, {
        status: input.status,
        resolvedByAdminId: actor.adminId,
        resolutionNote: input.resolutionNote?.trim() || null,
        resolvedAt: now(),
      });
      if (input.notifyStudent && row.report.status === 'open') {
        await deps.notify?.(row.report.userId, {
          type: 'report_resolved',
          titleAr: 'شكراً لبلاغك',
          bodyAr:
            input.status === 'resolved'
              ? 'راجعنا المشكلة التي أبلغت عنها وتم تصحيحها.'
              : 'راجعنا بلاغك ولم نجد ما يحتاج إلى تعديل.',
        });
      }
      await audit.record({
        actorAdminId: actor.adminId,
        action: `report.${input.status}`,
        resourceType: 'content_report',
        resourceId: id,
        metadata: { itemType: row.report.itemType, itemId: row.report.itemId },
        ip: actor.ip,
      });
      return (await toAdmin([(await repo.get(id))!]))[0]!;
    },
  };
}

export type ReportService = ReturnType<typeof createReportService>;
