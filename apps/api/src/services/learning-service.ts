import type {
  Bookmark,
  Mistake,
  ProgressCounts,
  ResumeItem,
  ScopeProgress,
  StudentQuestion,
} from '@plengo/contracts';
import { AppError } from '../lib/app-error.js';
import type { AttemptRepository } from '../repositories/attempt-repository.js';
import type { BookmarkRepository, BookmarkRow } from '../repositories/bookmark-repository.js';
import type { FlashcardRepository } from '../repositories/flashcard-repository.js';
import type { LearningRepository } from '../repositories/learning-repository.js';
import {
  decodeCursor,
  encodeCursor,
  type QuestionRepository,
  type QuestionRow,
} from '../repositories/question-repository.js';
import type { QuizRepository } from '../repositories/quiz-repository.js';
import type { SrsRepository } from '../repositories/srs-repository.js';
import type { StructureRepository } from '../repositories/structure-repository.js';
import type { TeacherRepository } from '../repositories/teacher-repository.js';
import type { AccessService } from './access-service.js';
import type { ConfigService } from './config-service.js';
import { assertVisibleScope, invalid } from './content-placement.js';
import { SIGNED_URL_TTL_SECONDS, type FlashcardService } from './flashcard-service.js';
import { quizAccess } from './quiz-service.js';

type BookmarkType = Bookmark['itemType'];

const percent = (done: number, total: number) => (total ? Math.round((done * 100) / total) : 0);

/**
 * Mistake bank (§16.1), bookmarks (§17) and progress (§18). Everything here is read against the
 * student's current access: questions they can no longer open are hidden (mistakes), shown locked
 * (bookmarks) or left out of totals (progress), never deleted.
 */
export function createLearningService(deps: {
  repo: LearningRepository;
  bookmarkRepo: BookmarkRepository;
  attemptRepo: AttemptRepository;
  srsRepo: SrsRepository;
  questionRepo: QuestionRepository;
  quizRepo: QuizRepository;
  flashcardRepo: FlashcardRepository;
  flashcards: FlashcardService;
  structureRepo: StructureRepository;
  teacherRepo: TeacherRepository;
  access: AccessService;
  config: ConfigService;
  now?: () => Date;
}) {
  const {
    repo,
    bookmarkRepo,
    attemptRepo,
    srsRepo,
    questionRepo,
    quizRepo,
    flashcardRepo,
    flashcards: cards,
    structureRepo,
    teacherRepo,
    access,
    config,
  } = deps;
  const now = deps.now ?? (() => new Date());

  /** Memoized visibility of subject/track pairs for one request. */
  function visibility() {
    const seen = new Map<string, Promise<boolean>>();
    return (subjectId: string, trackId: string | null) => {
      const key = `${subjectId}:${trackId}`;
      if (!seen.has(key)) {
        seen.set(
          key,
          assertVisibleScope({ structureRepo, teacherRepo }, subjectId, trackId)
            .then(() => true)
            .catch(() => false),
        );
      }
      return seen.get(key)!;
    };
  }

  async function names(subjectIds: string[], trackIds: string[], unitIds: string[], lessonIds: string[]) {
    const uniq = (xs: string[]) => [...new Set(xs)];
    return repo.names(uniq(subjectIds), uniq(trackIds), uniq(unitIds), uniq(lessonIds));
  }

  const ids = <T>(rows: T[], pick: (r: T) => string | null) =>
    rows.flatMap((r) => (pick(r) ? [pick(r)!] : []));

  // ---- mistakes ----

  async function mistakeRows(userId: string) {
    const rows = await repo.mistakes(userId);
    const ctx = await access.context(userId);
    const isVisible = visibility();
    const open = [];
    for (const r of rows)
      if (ctx.canAccessItem(r.q) && (await isVisible(r.q.subjectId, r.q.teacherTrackId))) open.push(r);
    return open;
  }

  // ---- bookmarks ----

  function studentQuestion(
    q: QuestionRow,
    locked: boolean,
    options: { id: string; text: string }[] | null,
  ): StudentQuestion {
    return {
      id: q.id,
      type: q.type,
      subjectId: q.subjectId,
      teacherTrackId: q.teacherTrackId,
      unitId: q.unitId,
      lessonId: q.lessonId,
      sortOrder: q.sortOrder,
      difficulty: q.difficulty,
      isFree: q.isFree,
      locked,
      questionText: locked ? null : q.questionText,
      options: locked ? null : options,
    };
  }

  async function assertBookmarkable(type: BookmarkType, id: string) {
    const isVisible = visibility();
    if (type === 'user_card') invalid('itemType', 'not_available');
    if (type === 'question') {
      const q = await questionRepo.get(id);
      if (!q || q.status !== 'published' || !(await isVisible(q.subjectId, q.teacherTrackId)))
        throw new AppError('NOT_FOUND');
    }
    if (type === 'deck') {
      const d = await flashcardRepo.getDeck(id);
      if (!d || d.status !== 'published' || !(await isVisible(d.subjectId, d.teacherTrackId)))
        throw new AppError('NOT_FOUND');
    }
    if (type === 'flashcard') {
      const c = await flashcardRepo.getCard(id);
      const d = c ? await flashcardRepo.getDeck(c.deckId) : null;
      if (
        !c ||
        c.status !== 'published' ||
        !d ||
        d.status !== 'published' ||
        !(await isVisible(d.subjectId, d.teacherTrackId))
      )
        throw new AppError('NOT_FOUND');
    }
  }

  async function bookmarkViews(userId: string, rows: BookmarkRow[]): Promise<Bookmark[]> {
    const ctx = await access.context(userId);
    const isVisible = visibility();
    const byType = (t: BookmarkType) => rows.filter((r) => r.itemType === t).map((r) => r.itemId);

    const qRows = await questionRepo.byIds(byType('question'));
    const qOpen = qRows.filter((q) => ctx.canAccessItem(q));
    const qOptions = new Map((await questionRepo.attachContent(qOpen)).map((q) => [q.id, q.options]));
    const qMap = new Map(qRows.map((q) => [q.id, q]));

    const cardRows = new Map((await flashcardRepo.cardsByIds(byType('flashcard'))).map((c) => [c.id, c]));
    const deckIds = [...new Set([...byType('deck'), ...[...cardRows.values()].map((c) => c.deckId)])];
    const decks = new Map(
      (await Promise.all(deckIds.map((id) => flashcardRepo.getDeck(id)))).flatMap((d) =>
        d ? [[d.id, d] as const] : [],
      ),
    );
    const n = await names(
      [...ids(qRows, (q) => q.subjectId), ...ids([...decks.values()], (d) => d.subjectId)],
      [],
      [],
      [],
    );

    const out: Bookmark[] = [];
    for (const b of rows) {
      const base = {
        id: b.id,
        itemType: b.itemType,
        itemId: b.itemId,
        createdAt: b.createdAt.toISOString(),
        locked: false,
        available: false,
        titleAr: null as string | null,
        subjectId: null as string | null,
        subjectNameAr: null as string | null,
        question: null as Bookmark['question'],
        deck: null as Bookmark['deck'],
        card: null as Bookmark['card'],
      };
      if (b.itemType === 'question') {
        const q = qMap.get(b.itemId);
        if (
          q &&
          !q.deletedAt &&
          q.status === 'published' &&
          (await isVisible(q.subjectId, q.teacherTrackId))
        ) {
          const locked = !ctx.canAccessItem(q);
          const options = qOptions.get(q.id)?.map((o) => ({ id: o.id, text: o.text })) ?? null;
          Object.assign(base, {
            available: true,
            locked,
            titleAr: locked ? null : q.questionText,
            subjectId: q.subjectId,
            subjectNameAr: n.subjects.get(q.subjectId) ?? null,
            question: studentQuestion(q, locked, options),
          });
        }
      } else if (b.itemType === 'deck' || b.itemType === 'flashcard') {
        const card = b.itemType === 'flashcard' ? cardRows.get(b.itemId) : undefined;
        const d = decks.get(b.itemType === 'deck' ? b.itemId : (card?.deckId ?? ''));
        const cardLive = b.itemType === 'deck' || (card && !card.deletedAt && card.status === 'published');
        if (d && d.status === 'published' && cardLive && (await isVisible(d.subjectId, d.teacherTrackId))) {
          const locked = !ctx.canAccessItem(d);
          Object.assign(base, {
            available: true,
            locked,
            titleAr: d.titleAr,
            subjectId: d.subjectId,
            subjectNameAr: n.subjects.get(d.subjectId) ?? null,
            deck: await cards.studentDeck(userId, d.id),
            // Signed URLs only for cards the student can open (§12.5).
            card: card && !locked ? await cards.toStudentCard(card) : null,
          });
        }
      }
      out.push(base);
    }
    return out;
  }

  // ---- progress ----

  type Item = { id: string; unitId: string | null; lessonId: string | null };
  function counts(
    qs: Item[],
    attempted: Map<string, boolean>,
    qz: Item[],
    completed: Set<string>,
    cs: Item[],
    studied: Set<string>,
    pick: (i: Item) => boolean,
  ): ProgressCounts {
    const q = qs.filter(pick);
    const z = qz.filter(pick);
    const c = cs.filter(pick);
    const qa = q.filter((i) => attempted.has(i.id));
    const zc = z.filter((i) => completed.has(i.id)).length;
    const cst = c.filter((i) => studied.has(i.id)).length;
    return {
      questionsAttempted: qa.length,
      questionsCorrect: qa.filter((i) => attempted.get(i.id)).length,
      questionsTotal: q.length,
      quizzesCompleted: zc,
      quizzesTotal: z.length,
      flashcardsStudied: cst,
      flashcardsTotal: c.length,
      completionPercent: percent(qa.length + zc + cst, q.length + z.length + c.length),
    };
  }

  return {
    async mistakes(
      userId: string,
      f: {
        status: 'active' | 'mastered';
        subjectId?: string | undefined;
        teacherTrackId?: string | undefined;
        unitId?: string | undefined;
        lessonId?: string | undefined;
        type?: QuestionRow['type'] | undefined;
        cursor?: string | undefined;
        limit?: number | undefined;
      },
    ) {
      const open = await mistakeRows(userId);
      const picked = open.filter(
        ({ m, q }) =>
          m.status === f.status &&
          (!f.subjectId || q.subjectId === f.subjectId) &&
          (!f.teacherTrackId || q.teacherTrackId === f.teacherTrackId) &&
          (!f.unitId || q.unitId === f.unitId) &&
          (!f.lessonId || q.lessonId === f.lessonId) &&
          (!f.type || q.type === f.type),
      );
      const offset = decodeCursor(f.cursor);
      const limit = f.limit ?? 100;
      const shown = picked.slice(offset, offset + limit);
      const n = await names(
        ids(shown, (r) => r.q.subjectId),
        ids(shown, (r) => r.q.teacherTrackId),
        ids(shown, (r) => r.q.unitId),
        ids(shown, (r) => r.q.lessonId),
      );
      const items: Mistake[] = shown.map(({ m, q }) => ({
        questionId: q.id,
        type: q.type,
        questionText: q.questionText,
        subjectId: q.subjectId,
        subjectNameAr: n.subjects.get(q.subjectId) ?? '',
        teacherTrackId: q.teacherTrackId,
        trackTitleAr: q.teacherTrackId ? (n.tracks.get(q.teacherTrackId) ?? null) : null,
        unitId: q.unitId,
        unitNameAr: q.unitId ? (n.units.get(q.unitId) ?? null) : null,
        lessonId: q.lessonId,
        lessonNameAr: q.lessonId ? (n.lessons.get(q.lessonId) ?? null) : null,
        status: m.status,
        wrongCount: m.wrongCount,
        correctStreak: m.correctStreak,
        firstWrongAt: m.firstWrongAt.toISOString(),
        lastWrongAt: m.lastWrongAt.toISOString(),
      }));
      return {
        items,
        activeCount: open.filter((r) => r.m.status === 'active').length,
        masteredCount: open.filter((r) => r.m.status === 'mastered').length,
        masteryStreak: (await config.getLearningSettings()).mistakeMasteryStreak,
        nextCursor: picked.length > offset + limit ? encodeCursor(offset + limit) : null,
      };
    },

    /** Active and mastered counts over the questions the student can still open (§16.1). */
    async mistakeCounts(userId: string) {
      const open = await mistakeRows(userId);
      return {
        active: open.filter((r) => r.m.status === 'active').length,
        mastered: open.filter((r) => r.m.status === 'mastered').length,
      };
    },

    /** Manual removal (§16.1); a later wrong answer re-activates it. */
    async removeMistake(userId: string, questionId: string) {
      if (!(await repo.removeMistake(userId, questionId, now()))) throw new AppError('NOT_FOUND');
      return { deleted: true };
    },

    async bookmarks(
      userId: string,
      q: { itemType?: BookmarkType | undefined; cursor?: string | undefined; limit?: number | undefined },
    ) {
      const offset = decodeCursor(q.cursor);
      const limit = q.limit ?? 50;
      const rows = await bookmarkRepo.list(userId, q.itemType, limit + 1, offset);
      return {
        items: await bookmarkViews(userId, rows.slice(0, limit)),
        nextCursor: rows.length > limit ? encodeCursor(offset + limit) : null,
        urlsExpireAt: new Date(now().getTime() + SIGNED_URL_TTL_SECONDS * 1000).toISOString(),
      };
    },

    async bookmarkKeys(userId: string) {
      return bookmarkRepo.keys(userId);
    },

    /** Idempotent. Locked items can be saved; they show as locked (§17). */
    async addBookmark(userId: string, itemType: BookmarkType, itemId: string) {
      await assertBookmarkable(itemType, itemId);
      const row = await bookmarkRepo.add(userId, itemType, itemId);
      return (await bookmarkViews(userId, [row]))[0]!;
    },

    async removeBookmark(userId: string, itemType: BookmarkType, itemId: string) {
      await bookmarkRepo.remove(userId, itemType, itemId);
      return { deleted: true };
    },

    /**
     * Completion for one subject scope and its units and lessons: distinct accessible published items
     * the student interacted with over all accessible published items (§18).
     */
    async progress(userId: string, subjectId: string, teacherTrackId: string | null): Promise<ScopeProgress> {
      await assertVisibleScope({ structureRepo, teacherRepo }, subjectId, teacherTrackId);
      const ctx = await access.context(userId);

      const [qRows, zRows, cRows, pointer] = await Promise.all([
        questionRepo.publishedRowsInScope(subjectId, teacherTrackId),
        quizRepo.list({
          subjectId,
          teacherTrackId: teacherTrackId ?? undefined,
          generalOnly: !teacherTrackId,
          status: 'published',
        }),
        flashcardRepo.publishedCardsInScope(subjectId, teacherTrackId),
        repo.progressPointer(userId, subjectId, teacherTrackId),
      ]);

      const qs = qRows.filter((q) => ctx.canAccessItem(q));
      const members = await quizRepo.publishedMembers(zRows.map((z) => z.id));
      const zs = zRows.filter(
        (z) =>
          !quizAccess(
            ctx,
            z,
            members.filter((m) => m.quizId === z.id).map((m) => m.question),
          ).locked,
      );
      const cs = cRows
        .filter((c) => ctx.canAccessItem(c.deck))
        .map((c) => ({ id: c.id, unitId: c.deck.unitId, lessonId: c.deck.lessonId }));

      const [answered, submitted, studied] = await Promise.all([
        attemptRepo.correctnessByQuestion(
          userId,
          qs.map((q) => q.id),
        ),
        attemptRepo.submittedQuizIds(
          userId,
          zs.map((z) => z.id),
        ),
        srsRepo.studiedCardIds(
          userId,
          cs.map((c) => c.id),
        ),
      ]);
      const attempted = new Map(answered.map((r) => [r.id, r.ok]));
      const completed = new Set(submitted.map((r) => r.id!));
      const studiedIds = new Set(studied.map((r) => r.id!));
      const calc = (pick: (i: Item) => boolean) => counts(qs, attempted, zs, completed, cs, studiedIds, pick);

      const unitIds = [...new Set([...qs, ...zs, ...cs].flatMap((i) => (i.unitId ? [i.unitId] : [])))];
      const lessonIds = [...new Set([...qs, ...zs, ...cs].flatMap((i) => (i.lessonId ? [i.lessonId] : [])))];
      return {
        subjectId,
        teacherTrackId,
        ...calc(() => true),
        lastActivityAt: pointer[0]?.lastActivityAt.toISOString() ?? null,
        units: unitIds.map((unitId) => ({ unitId, ...calc((i) => i.unitId === unitId) })),
        lessons: lessonIds.map((lessonId) => ({ lessonId, ...calc((i) => i.lessonId === lessonId) })),
      };
    },

    /** "متابعة التعلم" (§18): the latest activity per subject scope, newest first. */
    async resume(userId: string, limit = 5): Promise<ResumeItem[]> {
      const rows = await repo.recentProgress(userId, 20);
      const isVisible = visibility();
      const visibleRows = [];
      for (const r of rows) if (await isVisible(r.subjectId, r.teacherTrackId)) visibleRows.push(r);
      const shown = visibleRows.slice(0, limit);
      const n = await names(
        ids(shown, (r) => r.subjectId),
        ids(shown, (r) => r.teacherTrackId),
        ids(shown, (r) => r.unitId),
        ids(shown, (r) => r.lessonId),
      );
      const quizIds = shown
        .filter((r) => r.lastActivityType === 'quiz' && r.lastItemId)
        .map((r) => r.lastItemId!);
      const deckIds = shown
        .filter((r) => r.lastActivityType === 'deck' && r.lastItemId)
        .map((r) => r.lastItemId!);
      const [quizTitles, deckTitles, open] = await Promise.all([
        quizRepo.titles(quizIds),
        flashcardRepo.deckTitles(deckIds),
        attemptRepo.inProgressFor(userId, quizIds),
      ]);
      const titles = new Map([...quizTitles, ...deckTitles].map((r) => [r.id, r.t]));
      return shown.map((r) => ({
        subjectId: r.subjectId,
        subjectNameAr: n.subjects.get(r.subjectId) ?? '',
        teacherTrackId: r.teacherTrackId,
        trackTitleAr: r.teacherTrackId ? (n.tracks.get(r.teacherTrackId) ?? null) : null,
        unitId: r.unitId,
        unitNameAr: r.unitId ? (n.units.get(r.unitId) ?? null) : null,
        lessonId: r.lessonId,
        lessonNameAr: r.lessonId ? (n.lessons.get(r.lessonId) ?? null) : null,
        activityType: r.lastActivityType,
        itemId: r.lastItemId,
        itemTitleAr: r.lastItemId ? (titles.get(r.lastItemId) ?? null) : null,
        attemptId:
          r.lastActivityType === 'quiz' ? (open.find((a) => a.quizId === r.lastItemId)?.id ?? null) : null,
        lastActivityAt: r.lastActivityAt.toISOString(),
      }));
    },
  };
}

export type LearningService = ReturnType<typeof createLearningService>;
