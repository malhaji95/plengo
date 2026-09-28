import { createHash } from 'node:crypto';
import { NORMALIZATION_VERSION, normalizeArabic } from '@plengo/arabic-normalizer';
import {
  LEASE_DAYS,
  type OfflineAttempt,
  type OfflineItem,
  type OfflinePack,
  type OfflineScope,
} from '@plengo/contracts';
import { AppError } from '../lib/app-error.js';
import type { Scope } from '../repositories/access-repository.js';
import type { MediaRow } from '../repositories/flashcard-repository.js';
import type { OfflineRepository } from '../repositories/offline-repository.js';
import type { QuestionRepository, QuestionWithContent } from '../repositories/question-repository.js';
import type { StructureRepository } from '../repositories/structure-repository.js';
import type { TeacherRepository } from '../repositories/teacher-repository.js';
import type { ObjectStorage } from '../storage/storage.js';
import { scopeOf, type AccessService } from './access-service.js';
import type { AttemptService } from './attempt-service.js';
import { assertVisibleScope } from './content-placement.js';
import { SIGNED_URL_TTL_SECONDS } from './flashcard-service.js';

const DAY_MS = 86_400_000;
const PAGE = 50;
/** Rough JSON sizes for the download estimate; images use their real sizes. */
const QUESTION_BYTES = 1500;
const QUIZ_BYTES = 400;
const DECK_BYTES = 400;

type Kind = 'questions' | 'decks' | 'quizzes' | 'deck';
type ManifestItem = {
  type: 'question' | 'deck' | 'card' | 'quiz';
  id: string;
  version: number;
  free: boolean;
};
type Parsed = { scope: Scope; unit: string | null; kind: Kind; deckId: string | null };

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/;

function scopeId(scope: Scope) {
  return scope.scopeType === 'subject' ? scope.subjectId : scope.teacherTrackId;
}

export function packKey(scope: Scope, unit: string | null, kind: Kind, deckId?: string) {
  return kind === 'deck'
    ? `${scope.scopeType}:${scopeId(scope)}:-:deck.${deckId}`
    : `${scope.scopeType}:${scopeId(scope)}:${unit ?? 'none'}:${kind}`;
}

function parsePackKey(key: string): Parsed {
  const bad = (): never => {
    throw new AppError('NOT_FOUND');
  };
  const [type, id, unit, kind, ...rest] = key.split(':');
  if (rest.length || !id || !UUID.test(id) || !unit || !kind) bad();
  if (type !== 'subject' && type !== 'teacher_track') bad();
  const scope: Scope =
    type === 'subject'
      ? { scopeType: 'subject', subjectId: id!, teacherTrackId: null }
      : { scopeType: 'teacher_track', subjectId: null, teacherTrackId: id! };
  if (kind!.startsWith('deck.')) {
    const deckId = kind!.slice(5);
    if (unit !== '-' || !UUID.test(deckId)) bad();
    return { scope, unit: null, kind: 'deck', deckId };
  }
  if (kind !== 'questions' && kind !== 'decks' && kind !== 'quizzes') bad();
  if (unit !== 'none' && !UUID.test(unit!)) bad();
  return { scope, unit: unit === 'none' ? null : unit!, kind: kind as Kind, deckId: null };
}

const versionOf = (items: { type: string; id: string; version: number }[]) =>
  createHash('sha1')
    .update(
      items
        .map((i) => `${i.type}:${i.id}:${i.version}`)
        .sort()
        .join('|'),
    )
    .digest('hex')
    .slice(0, 16);

const imageSize = (m: MediaRow) => m.variants.full?.size ?? m.optimizedSize ?? m.originalSize;

/**
 * Offline packs (spec §22): what a student may download per subject or track, pack manifests with
 * item versions for delta updates, item chunks with signed image URLs, device leases for premium
 * content, and the upload of attempts taken offline (re-graded by the server).
 *
 * Downloadable: free items, and premium items of scopes the student holds an active entitlement for
 * (a promotion opens content online but gives no offline copy). Quizzes need `allow_offline`.
 */
export function createOfflineService(deps: {
  repo: OfflineRepository;
  questionRepo: QuestionRepository;
  structureRepo: StructureRepository;
  teacherRepo: TeacherRepository;
  access: AccessService;
  attempts: AttemptService;
  storage: ObjectStorage;
  now?: () => Date;
}) {
  const { repo, questionRepo, structureRepo, teacherRepo, access, attempts, storage } = deps;
  const now = deps.now ?? (() => new Date());
  const notFound = (): never => {
    throw new AppError('NOT_FOUND');
  };

  /** The subject and track behind a scope; both must be visible to students. */
  async function resolve(scope: Scope) {
    let subjectId: string;
    let trackId: string | null = null;
    if (scope.scopeType === 'teacher_track') {
      const track = (await teacherRepo.getTrack(scope.teacherTrackId, { visibleOnly: true })) ?? notFound();
      subjectId = track.subjectId;
      trackId = track.id;
    } else {
      subjectId = scope.subjectId;
    }
    await assertVisibleScope({ structureRepo, teacherRepo }, subjectId, trackId);
    return { subjectId, trackId };
  }

  /** Everything the student may download in one scope. */
  async function scopeContent(userId: string, scope: Scope) {
    const { subjectId, trackId } = await resolve(scope);
    const ctx = await access.context(userId);
    const entitled = ctx.hasActiveEntitlement(scope);
    const ok = (item: { isFree: boolean }) => item.isFree || entitled;
    const [questionRows, decks, quizRows] = await Promise.all([
      questionRepo.publishedRowsInScope(subjectId, trackId),
      repo.decksInScope(subjectId, trackId),
      repo.quizzesInScope(subjectId, trackId),
    ]);
    const questions = questionRows.filter(ok);
    const openDecks = decks.filter(ok);
    const cards = await repo.cardsOfDecks(openDecks.map((d) => d.id));
    const questionIds = new Set(questions.map((q) => q.id));
    const members = await repo.quizMembers(quizRows.map((q) => q.id));
    const quizzes = quizRows
      .filter(ok)
      .map((q) => ({ quiz: q, questionIds: (members.get(q.id) ?? []).filter((id) => questionIds.has(id)) }))
      .filter((q) => q.questionIds.length > 0);
    return { subjectId, trackId, entitled, questions, decks: openDecks, cards, quizzes };
  }
  type Content = Awaited<ReturnType<typeof scopeContent>>;

  /** The manifest items of one pack. */
  function packItems(content: Content, p: Parsed): ManifestItem[] {
    const inUnit = (x: { unitId: string | null }) => x.unitId === p.unit;
    switch (p.kind) {
      case 'questions':
        return content.questions
          .filter(inUnit)
          .map((q) => ({ type: 'question' as const, id: q.id, version: q.contentVersion, free: q.isFree }));
      case 'quizzes':
        return content.quizzes
          .filter((q) => inUnit(q.quiz))
          .map((q) => ({
            type: 'quiz' as const,
            id: q.quiz.id,
            version: q.quiz.contentVersion,
            free: q.quiz.isFree,
          }));
      case 'decks':
      case 'deck': {
        const decks = content.decks.filter((d) => (p.kind === 'deck' ? d.id === p.deckId : inUnit(d)));
        const ids = new Set(decks.map((d) => d.id));
        return [
          ...decks.map((d) => ({
            type: 'deck' as const,
            id: d.id,
            version: d.contentVersion,
            free: d.isFree,
          })),
          ...content.cards
            .filter((c) => ids.has(c.card.deckId))
            .map((c) => ({
              type: 'card' as const,
              id: c.card.id,
              version: c.card.contentVersion,
              free: decks.find((d) => d.id === c.card.deckId)!.isFree,
            })),
        ];
      }
    }
  }

  function sizeOf(content: Content, items: ManifestItem[]) {
    const cards = new Map(content.cards.map((c) => [c.card.id, c]));
    return items.reduce((sum, i) => {
      if (i.type === 'question') return sum + QUESTION_BYTES;
      if (i.type === 'quiz') return sum + QUIZ_BYTES;
      if (i.type === 'deck') return sum + DECK_BYTES;
      const c = cards.get(i.id)!;
      return sum + imageSize(c.front) + imageSize(c.back);
    }, 0);
  }

  async function catalogOf(userId: string, scope: Scope) {
    const content = await scopeContent(userId, scope);
    const units = new Map((await structureRepo.listUnits(content.subjectId)).map((u) => [u.id, u.titleAr]));
    const unitIds = [
      ...new Set(
        [...content.questions, ...content.decks, ...content.quizzes.map((q) => q.quiz)].map((x) => x.unitId),
      ),
    ];
    const kindTitle = { questions: 'الأسئلة', decks: 'البطاقات', quizzes: 'الاختبارات' } as const;
    const packs: OfflinePack[] = [];
    for (const unit of unitIds) {
      for (const kind of ['questions', 'decks', 'quizzes'] as const) {
        const p: Parsed = { scope, unit, kind, deckId: null };
        const items = packItems(content, p);
        if (!items.length) continue;
        packs.push({
          packKey: packKey(scope, unit, kind),
          kind,
          unitId: unit,
          deckId: null,
          titleAr: `${unit ? (units.get(unit) ?? '') : 'عام'} · ${kindTitle[kind]}`,
          itemCount: items.length,
          sizeBytes: sizeOf(content, items),
          version: versionOf(items),
          premium: items.some((i) => !i.free),
        });
      }
    }
    for (const d of content.decks) {
      const items = packItems(content, { scope, unit: null, kind: 'deck', deckId: d.id });
      packs.push({
        packKey: packKey(scope, null, 'deck', d.id),
        kind: 'deck',
        unitId: d.unitId,
        deckId: d.id,
        titleAr: d.titleAr,
        itemCount: items.length,
        sizeBytes: sizeOf(content, items),
        version: versionOf(items),
        premium: !d.isFree,
      });
    }
    const subject = await structureRepo.getSubject(content.subjectId, { studentVisible: true });
    const track = content.trackId ? await teacherRepo.getTrack(content.trackId, { visibleOnly: true }) : null;
    return {
      scope: toOfflineScope(scope),
      titleAr: track?.titleAr ?? subject?.nameAr ?? '',
      entitled: content.entitled,
      packs,
      // Unit packs cover everything once; single-deck packs repeat the decks packs.
      sizeBytes: packs.filter((p) => p.kind !== 'deck').reduce((s, p) => s + p.sizeBytes, 0),
    };
  }

  const toOfflineScope = (s: Scope): OfflineScope => ({
    scopeType: s.scopeType,
    subjectId: s.subjectId,
    teacherTrackId: s.teacherTrackId,
  });

  function toQuestion(q: QuestionWithContent) {
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
      questionText: q.questionText,
      explanation: q.explanation,
      options: q.options.map((o) => ({ id: o.id, text: o.text, isCorrect: o.isCorrect })),
      acceptedAnswers: q.answers
        .filter((a) => a.isActive)
        .map((a) => ({
          original: a.answerOriginal,
          // Always the current normalizer's output, so devices on this version can grade locally.
          normalized:
            a.normalizationVersion === NORMALIZATION_VERSION
              ? a.answerNormalized
              : normalizeArabic(a.answerOriginal),
          normalizationVersion: NORMALIZATION_VERSION,
        })),
    };
  }

  async function image(m: MediaRow) {
    const full = m.variants.full;
    return {
      mediaId: m.id,
      version: m.version,
      url: full ? await storage.getSignedGetUrl(m.bucket, full.key, SIGNED_URL_TTL_SECONDS) : '',
      width: full?.width ?? null,
      height: full?.height ?? null,
      sizeBytes: imageSize(m),
    };
  }

  return {
    toOfflineScope,

    /** Scopes with an active entitlement, with their download size (§22.2 after redemption). */
    async catalog(userId: string) {
      const ctx = await access.context(userId);
      const owned = (await access.myEntitlements(userId)).filter((e) => e.state === 'active');
      const scopes = [] as { scope: OfflineScope; titleAr: string; sizeBytes: number; packCount: number }[];
      for (const e of owned) {
        const scope = scopeOf({ subjectId: e.scope.subjectId ?? '', teacherTrackId: e.scope.teacherTrackId });
        if (!ctx.hasActiveEntitlement(scope)) continue;
        const c = await catalogOf(userId, scope).catch(() => null);
        if (c)
          scopes.push({
            scope: c.scope,
            titleAr: c.titleAr,
            sizeBytes: c.sizeBytes,
            packCount: c.packs.length,
          });
      }
      return { scopes };
    },

    scopeCatalog: (userId: string, q: { subjectId: string; teacherTrackId?: string | undefined }) =>
      catalogOf(
        userId,
        q.teacherTrackId
          ? { scopeType: 'teacher_track', subjectId: null, teacherTrackId: q.teacherTrackId }
          : { scopeType: 'subject', subjectId: q.subjectId, teacherTrackId: null },
      ),

    async manifest(userId: string, key: string) {
      const p = parsePackKey(key);
      const content = await scopeContent(userId, p.scope);
      const items = packItems(content, p);
      if (p.kind === 'deck' && !items.length) notFound();
      return {
        packKey: key,
        version: versionOf(items),
        premium: items.some((i) => !i.free),
        normalizationVersion: NORMALIZATION_VERSION,
        items: items.map(({ type, id, version }) => ({ type, id, version })),
      };
    },

    /** Item chunks; `ids` limits the download to new or changed items (delta sync, §22.3). */
    async items(userId: string, key: string, q: { ids?: string | undefined; cursor?: string | undefined }) {
      const p = parsePackKey(key);
      const content = await scopeContent(userId, p.scope);
      let list = packItems(content, p);
      if (q.ids) {
        const wanted = new Set(q.ids.split(',').filter((id) => UUID.test(id)));
        list = list.filter((i) => wanted.has(i.id));
      }
      const offset = Math.max(0, Number(q.cursor ?? 0) || 0);
      const page = list.slice(offset, offset + PAGE);

      const questionIds = page.filter((i) => i.type === 'question').map((i) => i.id);
      const questions = new Map(
        (await questionRepo.attachContent(content.questions.filter((x) => questionIds.includes(x.id)))).map(
          (x) => [x.id, x],
        ),
      );
      const decks = new Map(content.decks.map((d) => [d.id, d]));
      const cards = new Map(content.cards.map((c) => [c.card.id, c]));
      const quizzes = new Map(content.quizzes.map((z) => [z.quiz.id, z]));
      const cardIdsOf = (deckId: string) =>
        content.cards.filter((c) => c.card.deckId === deckId).map((c) => c.card.id);

      const items: OfflineItem[] = [];
      for (const i of page) {
        const base = {
          type: i.type,
          id: i.id,
          version: i.version,
          question: null,
          deck: null,
          card: null,
          quiz: null,
        };
        if (i.type === 'question') items.push({ ...base, question: toQuestion(questions.get(i.id)!) });
        if (i.type === 'deck') {
          const d = decks.get(i.id)!;
          items.push({
            ...base,
            deck: {
              id: d.id,
              subjectId: d.subjectId,
              teacherTrackId: d.teacherTrackId,
              unitId: d.unitId,
              lessonId: d.lessonId,
              titleAr: d.titleAr,
              description: d.description,
              isFree: d.isFree,
              sortOrder: d.sortOrder,
              cardIds: cardIdsOf(d.id),
            },
          });
        }
        if (i.type === 'card') {
          const c = cards.get(i.id)!;
          items.push({
            ...base,
            card: {
              id: c.card.id,
              deckId: c.card.deckId,
              sortOrder: c.card.sortOrder,
              front: await image(c.front),
              back: await image(c.back),
            },
          });
        }
        if (i.type === 'quiz') {
          const { quiz: z, questionIds: ids } = quizzes.get(i.id)!;
          items.push({
            ...base,
            quiz: {
              id: z.id,
              subjectId: z.subjectId,
              teacherTrackId: z.teacherTrackId,
              unitId: z.unitId,
              lessonId: z.lessonId,
              titleAr: z.titleAr,
              description: z.description,
              allowedModes: z.allowedModes,
              timeLimitSeconds: z.timeLimitSeconds,
              passingScore: z.passingScorePercent,
              shuffleQuestions: z.shuffleQuestions,
              shuffleOptions: z.shuffleOptions,
              isFree: z.isFree,
              questionIds: ids,
            },
          });
        }
      }
      return {
        items,
        nextCursor: offset + PAGE < list.length ? String(offset + PAGE) : null,
        urlsExpireAt: new Date(now().getTime() + SIGNED_URL_TTL_SECONDS * 1000).toISOString(),
      };
    },

    /**
     * Leases for the scopes this device holds packs of (§22.4): renewed at most once a day,
     * `expires_at = min(now + 30 days, entitlement end)`; `none` when the entitlement is gone.
     */
    async refreshLeases(
      userId: string,
      sessionId: string,
      scopes: {
        scopeType: 'subject' | 'teacher_track';
        subjectId?: string | null;
        teacherTrackId?: string | null;
      }[],
    ) {
      const at = now();
      const ctx = await access.context(userId, at);
      const held = await repo.leasesFor(userId, sessionId);
      const leases = [];
      for (const s of scopes) {
        const scope: Scope | null =
          s.scopeType === 'subject' && s.subjectId
            ? { scopeType: 'subject', subjectId: s.subjectId, teacherTrackId: null }
            : s.scopeType === 'teacher_track' && s.teacherTrackId
              ? { scopeType: 'teacher_track', subjectId: null, teacherTrackId: s.teacherTrackId }
              : null;
        if (!scope) throw new AppError('VALIDATION_ERROR', { details: { field: 'scopes' } });
        const mine = held.filter((l) =>
          scope.scopeType === 'subject'
            ? l.subjectId === scope.subjectId
            : l.teacherTrackId === scope.teacherTrackId,
        );
        if (!ctx.hasActiveEntitlement(scope)) {
          await repo.revokeLeases(
            mine.map((l) => l.id),
            at,
          );
          leases.push({ ...toOfflineScope(scope), status: 'none' as const, expiresAt: null });
          continue;
        }
        const ends = ctx.scopeAccess(scope).entitlementExpiresAt;
        const expiresAt = new Date(
          Math.min(at.getTime() + LEASE_DAYS * DAY_MS, ends ? Date.parse(ends) : Infinity),
        );
        const fresh = mine.find(
          (l) => l.issuedAt.getTime() > at.getTime() - DAY_MS && l.expiresAt.getTime() > at.getTime(),
        );
        let lease = fresh && fresh.expiresAt.getTime() <= expiresAt.getTime() ? fresh : null;
        if (!lease) {
          await repo.revokeLeases(
            mine.map((l) => l.id),
            at,
          );
          lease = await repo.insertLease({
            userId,
            sessionId,
            scopeType: scope.scopeType,
            subjectId: scope.subjectId,
            teacherTrackId: scope.teacherTrackId,
            issuedAt: at,
            expiresAt,
          });
        }
        leases.push({
          ...toOfflineScope(scope),
          status: 'active' as const,
          expiresAt: lease.expiresAt.toISOString(),
        });
      }
      return { serverTime: at.toISOString(), leases };
    },

    /**
     * Attempts taken offline (§22.6), each idempotent by its client id. A question counts when it is
     * free, open to the student now, or covered by a live lease (downloaded while entitled).
     */
    async sync(userId: string, body: { attempts: OfflineAttempt[] }) {
      const at = now();
      const ctx = await access.context(userId, at);
      const leased = new Map<string, boolean>();
      const canUse = async (q: QuestionWithContent) => {
        if (ctx.canAccessItem(q)) return true;
        const scope = scopeOf(q);
        const key = `${scope.scopeType}:${scopeId(scope)}`;
        if (!leased.has(key)) leased.set(key, await repo.hasLease(userId, scope, at));
        return leased.get(key)!;
      };
      const results = [];
      for (const a of body.attempts) {
        try {
          const { view, mismatches } = await attempts.importOffline(
            userId,
            {
              ...a,
              answers: a.answers.map((x) => ({
                questionId: x.questionId,
                selectedOptionId: x.selectedOptionId ?? null,
                writtenAnswer: x.writtenAnswer ?? null,
                flagged: x.flagged,
                timeSpentMs: x.timeSpentMs ?? null,
                localIsCorrect: x.localIsCorrect,
              })),
            },
            canUse,
          );
          await repo.recordMismatches(mismatches.map((m) => ({ userId, attemptId: view.attempt.id, ...m })));
          results.push({
            clientAttemptId: a.clientAttemptId,
            status: 'accepted' as const,
            reason: null,
            attemptId: view.attempt.id,
            correctCount: view.attempt.correctCount,
            totalCount: view.attempt.totalCount,
            mismatches: mismatches.length,
          });
        } catch (e) {
          if (!(e instanceof AppError)) throw e;
          const details = e.details as { reason?: string } | undefined;
          results.push({
            clientAttemptId: a.clientAttemptId,
            status: 'rejected' as const,
            reason: details?.reason ?? e.code,
            attemptId: null,
            correctCount: null,
            totalCount: null,
            mismatches: 0,
          });
        }
      }
      return { results };
    },
  };
}

export type OfflineService = ReturnType<typeof createOfflineService>;
