import { randomUUID } from 'node:crypto';
import { eq } from 'drizzle-orm';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { mediaFiles, offlineGradeMismatches, offlineLeases, quizAttempts, users } from '@plengo/db';
import {
  body,
  createTestApp,
  enrolledAdminSession,
  levelId,
  tokensFor,
  type TestContext,
} from './helpers.js';

let t: TestContext;
let admin: Record<string, string>;
const clock = { now: () => t.clock.now() };

beforeAll(async () => {
  t = await createTestApp();
  admin = (await enrolledAdminSession(t)).headers;
});
afterAll(async () => {
  await t.close();
});

type Json = Record<string, unknown>;
const slug = (p: string) => `${p}-${randomUUID().slice(0, 8)}`;
const DAY = 86_400_000;

async function adminCall<T = Json>(method: 'GET' | 'POST' | 'PUT' | 'PATCH', url: string, payload?: object) {
  const res = await t.app.inject({
    method,
    url: `/api/v1/admin${url}`,
    headers: admin,
    ...(payload ? { payload } : {}),
  });
  return { status: res.statusCode, ...body<T>(res) };
}

interface Student {
  id: string;
  token: string;
  refresh: string;
}
async function student(): Promise<Student> {
  const { email, accessToken, refreshToken } = await tokensFor(t);
  const [u] = await t.c.db.select({ id: users.id }).from(users).where(eq(users.email, email));
  return { id: u!.id, token: accessToken, refresh: refreshToken };
}
async function call<T = Json>(s: Student, method: 'GET' | 'POST', url: string, payload?: object) {
  const res = await t.app.inject({
    method,
    url: `/api/v1${url}`,
    headers: { authorization: `Bearer ${s.token}` },
    ...(payload ? { payload } : {}),
  });
  return { status: res.statusCode, raw: res.body, ...body<T>(res) };
}

async function image() {
  const id = randomUUID();
  const variants = {
    full: { key: `test/flashcard/${id}/full.webp`, width: 1080, height: 720, size: 50_000 },
    thumb: { key: `test/flashcard/${id}/thumb.webp`, width: 360, height: 240, size: 5_000 },
  };
  for (const v of Object.values(variants))
    await t.storage.put('private', v.key, Buffer.from('img'), 'image/webp');
  await t.c.db.insert(mediaFiles).values({
    id,
    bucket: 'private',
    storageKey: `test/flashcard/${id}/original`,
    kind: 'flashcard',
    mimeType: 'image/png',
    originalSize: 100,
    variants,
    status: 'ready',
  });
  return id;
}

type World = Awaited<ReturnType<typeof world>>;

/** A Grade 12 subject with a unit: free and premium questions, a written one, a deck, a quiz and a mock exam. */
async function world() {
  const subject = (
    await adminCall<{ id: string }>('POST', '/subjects', {
      educationLevelId: await levelId(t, 'grade-12'),
      code: slug('chem'),
      nameAr: 'الكيمياء',
    })
  ).data;
  const unit = (
    await adminCall<{ id: string }>('POST', '/units', {
      subjectId: subject.id,
      code: slug('u'),
      titleAr: 'الذرة',
    })
  ).data;
  const create = async (payload: Json) => {
    const res = await adminCall<{ id: string; options: { id: string; isCorrect: boolean }[] }>(
      'POST',
      '/questions',
      {
        subjectId: subject.id,
        unitId: unit.id,
        publish: true,
        ...payload,
      },
    );
    if (res.status !== 200) throw new Error(JSON.stringify(res.error));
    return res.data;
  };
  const free = await create({
    type: 'mcq',
    questionText: 'سؤال مجاني',
    options: [
      { text: 'صحيح', isCorrect: true },
      { text: 'خطأ', isCorrect: false },
    ],
  });
  await adminCall('PUT', `/questions/${free.id}/free`, { mode: 'free' });
  const premium = await create({
    type: 'mcq',
    questionText: 'سؤال مدفوع',
    options: [
      { text: 'صحيح', isCorrect: true },
      { text: 'خطأ', isCorrect: false },
    ],
  });
  const written = await create({
    type: 'written',
    questionText: 'عاصمة سوريا؟',
    acceptedAnswers: ['دِمَشْق'],
  });
  const general = await create({
    type: 'true_false',
    unitId: null,
    questionText: 'الماء مركب',
    trueFalseAnswer: true,
  });

  const deck = (
    await adminCall<{ id: string }>('POST', '/decks', {
      subjectId: subject.id,
      unitId: unit.id,
      titleAr: 'رموز',
    })
  ).data;
  const card = (
    await adminCall<{ id: string }>('POST', `/decks/${deck.id}/cards`, {
      frontMediaId: await image(),
      backMediaId: await image(),
    })
  ).data;
  await adminCall('POST', `/decks/${deck.id}/status`, { status: 'published' });

  const quiz = (
    await adminCall<{ quiz: { id: string } }>('POST', '/quizzes', {
      subjectId: subject.id,
      unitId: unit.id,
      titleAr: 'اختبار الوحدة',
      questionIds: [free.id, premium.id, written.id],
    })
  ).data.quiz;
  await adminCall('POST', `/quizzes/${quiz.id}/status`, { status: 'published' });
  const mock = (
    await adminCall<{ quiz: { id: string; allowOffline: boolean } }>('POST', '/quizzes', {
      subjectId: subject.id,
      titleAr: 'امتحان تجريبي',
      isMockExam: true,
      allowedModes: 'exam',
      timeLimitSeconds: 600,
      questionIds: [free.id, premium.id],
    })
  ).data.quiz;
  expect(mock.allowOffline).toBe(false);
  await adminCall('POST', `/quizzes/${mock.id}/status`, { status: 'published' });
  return {
    subjectId: subject.id,
    unitId: unit.id,
    free,
    premium,
    written,
    general,
    deck: deck.id,
    card: card.id,
    quiz: quiz.id,
    mock: mock.id,
  };
}

type Pack = {
  packKey: string;
  kind: string;
  unitId: string | null;
  itemCount: number;
  sizeBytes: number;
  version: string;
  premium: boolean;
};
type Catalog = { entitled: boolean; packs: Pack[]; sizeBytes: number; titleAr: string };
type Manifest = {
  version: string;
  premium: boolean;
  normalizationVersion: number;
  items: { type: string; id: string; version: number }[];
};
type Item = {
  type: string;
  id: string;
  question: {
    options: { id: string; isCorrect: boolean }[];
    acceptedAnswers: { original: string; normalized: string }[];
  } | null;
  card: { front: { url: string; sizeBytes: number } } | null;
  quiz: { questionIds: string[] } | null;
  deck: { cardIds: string[] } | null;
};

const catalog = (s: Student, w: World) =>
  call<Catalog>(s, 'GET', `/offline/catalog/scope?subjectId=${w.subjectId}`);
const pack = (c: Catalog, kind: string, unitId: string | null) =>
  c.packs.find((p) => p.kind === kind && p.unitId === unitId)!;
const grant = async (s: Student, w: World, extra: Json = { permanentAccess: true }) =>
  (
    await adminCall<{ id: string }>('POST', `/students/${s.id}/entitlements`, {
      scopeType: 'subject',
      subjectId: w.subjectId,
      ...extra,
    })
  ).data.id;

describe('offline catalog and packs (§22.1, §22.3)', () => {
  it('offers free items to everyone and premium items only with an entitlement', async () => {
    const w = await world();
    const s = await student();
    const open = await catalog(s, w);
    expect(open.data.entitled).toBe(false);
    expect(pack(open.data, 'questions', w.unitId)).toMatchObject({ itemCount: 1, premium: false });
    // The deck and the quiz are premium: not offered without an entitlement.
    expect(open.data.packs.filter((p) => p.kind !== 'questions')).toEqual([]);

    await grant(s, w);
    const full = (await catalog(s, w)).data;
    expect(full.entitled).toBe(true);
    expect(pack(full, 'questions', w.unitId)).toMatchObject({ itemCount: 3, premium: true });
    expect(pack(full, 'questions', null)).toMatchObject({ itemCount: 1 });
    expect(pack(full, 'decks', w.unitId)).toMatchObject({ itemCount: 2 }); // the deck and its card
    expect(pack(full, 'decks', w.unitId).sizeBytes).toBeGreaterThanOrEqual(100_000);
    expect(pack(full, 'quizzes', w.unitId)).toMatchObject({ itemCount: 1 });
    expect(full.packs.find((p) => p.kind === 'deck')!.packKey).toBe(
      `subject:${w.subjectId}:-:deck.${w.deck}`,
    );
    // The mock exam (allow_offline = false) is never in a pack.
    const quizzes = full.packs.filter((p) => p.kind === 'quizzes');
    for (const p of quizzes) {
      const m = (await call<Manifest>(s, 'GET', `/offline/packs/${p.packKey}/manifest`)).data;
      expect(m.items.map((i) => i.id)).not.toContain(w.mock);
    }

    const list = await call<{ scopes: { titleAr: string; sizeBytes: number }[] }>(
      s,
      'GET',
      '/offline/catalog',
    );
    expect(list.data.scopes).toMatchObject([{ titleAr: 'الكيمياء', sizeBytes: full.sizeBytes }]);
  });

  it('serves item chunks with answers and signed images, and delta updates by version', async () => {
    const w = await world();
    const s = await student();
    await grant(s, w);
    const c = (await catalog(s, w)).data;
    const questions = pack(c, 'questions', w.unitId);
    const manifest = (await call<Manifest>(s, 'GET', `/offline/packs/${questions.packKey}/manifest`)).data;
    expect(manifest).toMatchObject({ version: questions.version, premium: true, normalizationVersion: 1 });
    const items = (await call<{ items: Item[] }>(s, 'GET', `/offline/packs/${questions.packKey}/items`)).data
      .items;
    const written = items.find((i) => i.id === w.written.id)!;
    expect(written.question!.acceptedAnswers).toEqual([
      { original: 'دِمَشْق', normalized: 'دمشق', normalizationVersion: 1 },
    ]);
    const mcq = items.find((i) => i.id === w.free.id)!;
    expect(mcq.question!.options.filter((o) => o.isCorrect)).toHaveLength(1);

    const decks = (
      await call<{ items: Item[] }>(s, 'GET', `/offline/packs/${pack(c, 'decks', w.unitId).packKey}/items`)
    ).data.items;
    expect(decks.find((i) => i.type === 'deck')!.deck!.cardIds).toEqual([w.card]);
    expect(decks.find((i) => i.type === 'card')!.card!.front).toMatchObject({ sizeBytes: 50_000 });
    expect(decks.find((i) => i.type === 'card')!.card!.front.url).toMatch(/sig=/);
    const quiz = (
      await call<{ items: Item[] }>(s, 'GET', `/offline/packs/${pack(c, 'quizzes', w.unitId).packKey}/items`)
    ).data.items[0]!;
    expect(quiz.quiz!.questionIds).toEqual([w.free.id, w.premium.id, w.written.id]);

    // An admin edit changes the pack version and only that item's version (§22.3).
    await adminCall('PATCH', `/questions/${w.written.id}`, { explanation: 'العاصمة' });
    const after = (await call<Manifest>(s, 'GET', `/offline/packs/${questions.packKey}/manifest`)).data;
    expect(after.version).not.toBe(manifest.version);
    const changed = after.items.filter(
      (i) => manifest.items.find((m) => m.id === i.id)!.version !== i.version,
    );
    expect(changed.map((i) => i.id)).toEqual([w.written.id]);
    const delta = await call<{ items: Item[] }>(
      s,
      'GET',
      `/offline/packs/${questions.packKey}/items?ids=${changed.map((i) => i.id).join(',')}`,
    );
    expect(delta.data.items.map((i) => i.id)).toEqual([w.written.id]);
  });

  it('refuses unknown or malformed pack keys and premium decks without access', async () => {
    const w = await world();
    const s = await student();
    for (const key of [
      'not-a-pack-key',
      `subject:${w.subjectId}:none:everything`,
      `teacher_track:${randomUUID()}:none:questions`,
    ]) {
      expect((await call(s, 'GET', `/offline/packs/${encodeURIComponent(key)}/manifest`)).status).toBe(404);
    }
    expect(
      (await call(s, 'GET', `/offline/packs/subject:${w.subjectId}:-:deck.${w.deck}/manifest`)).status,
    ).toBe(404);
    // Items of a premium pack are simply not there without access.
    const items = await call<{ items: Item[] }>(
      s,
      'GET',
      `/offline/packs/subject:${w.subjectId}:${w.unitId}:questions/items`,
    );
    expect(items.data.items.map((i) => i.id)).toEqual([w.free.id]);
    expect(items.raw).not.toContain('سؤال مدفوع');
  });
});

describe('offline leases (§22.4)', () => {
  type Leases = {
    serverTime: string;
    leases: { status: string; expiresAt: string | null; subjectId: string }[];
  };
  const refresh = (s: Student, w: World) =>
    call<Leases>(s, 'POST', '/offline/licenses/refresh', {
      scopes: [{ scopeType: 'subject', subjectId: w.subjectId }],
    });

  it('lasts 30 days, ends with the entitlement, and is withdrawn when access ends', async () => {
    const w = await world();
    const s = await student();
    expect((await refresh(s, w)).data.leases).toMatchObject([{ status: 'none', expiresAt: null }]);

    const id = await grant(s, w);
    const first = (await refresh(s, w)).data;
    expect(Math.abs(Date.parse(first.serverTime) - clock.now().getTime())).toBeLessThan(5000);
    const in30 = (at: string) => Date.parse(at) - Date.parse(first.serverTime);
    expect(in30(first.leases[0]!.expiresAt!)).toBe(30 * DAY);
    // Refreshed at most once a day: the same lease comes back.
    expect((await refresh(s, w)).data.leases[0]!.expiresAt).toBe(first.leases[0]!.expiresAt);
    // A day later it is renewed.
    await t.c.db
      .update(offlineLeases)
      .set({ issuedAt: new Date(clock.now().getTime() - DAY - 1000) })
      .where(eq(offlineLeases.userId, s.id));
    const renewed = (await refresh(s, w)).data;
    expect(Date.parse(renewed.leases[0]!.expiresAt!) - Date.parse(renewed.serverTime)).toBe(30 * DAY);
    expect(
      (await t.c.db.select().from(offlineLeases).where(eq(offlineLeases.userId, s.id))).filter(
        (l) => !l.revokedAt,
      ),
    ).toHaveLength(1);

    await adminCall('POST', `/entitlements/${id}/revoke`, { reason: 'اختبار' });
    expect((await refresh(s, w)).data.leases).toMatchObject([{ status: 'none' }]);
    expect(
      (await t.c.db.select().from(offlineLeases).where(eq(offlineLeases.userId, s.id))).every(
        (l) => l.revokedAt,
      ),
    ).toBe(true);
  });

  it('never outlives a temporary entitlement', async () => {
    const w = await world();
    const s = await student();
    await grant(s, w, { accessDurationDays: 7 });
    const lease = (await refresh(s, w)).data.leases[0]!;
    expect(Date.parse(lease.expiresAt!)).toBeLessThanOrEqual(clock.now().getTime() + 8 * DAY);
    expect(Date.parse(lease.expiresAt!)).toBeGreaterThan(clock.now().getTime() + 6 * DAY);
  });
});

describe('offline attempts (§22.6)', () => {
  type SyncResult = {
    results: {
      clientAttemptId: string;
      status: string;
      reason: string | null;
      attemptId: string | null;
      correctCount: number | null;
      totalCount: number | null;
      mismatches: number;
    }[];
  };
  const correctOf = (q: { options: { id: string; isCorrect: boolean }[] }) =>
    q.options.find((o) => o.isCorrect)!.id;
  const wrongOf = (q: { options: { id: string; isCorrect: boolean }[] }) =>
    q.options.find((o) => !o.isCorrect)!.id;

  it('re-grades offline answers, logs mismatches and stores each attempt once', async () => {
    const w = await world();
    const s = await student();
    await grant(s, w);
    const attempt = {
      clientAttemptId: randomUUID(),
      source: 'curated',
      mode: 'practice',
      quizId: w.quiz,
      questionIds: [w.written.id, w.free.id, w.premium.id],
      startedAt: new Date(clock.now().getTime() - 600_000).toISOString(),
      submittedAt: clock.now().toISOString(),
      answers: [
        // Alef, diacritics and spacing variants grade like the server (§22.11).
        { questionId: w.written.id, writtenAnswer: '  دمشق ', localIsCorrect: true },
        { questionId: w.free.id, selectedOptionId: correctOf(w.free), localIsCorrect: true },
        // The device claims a wrong answer is right: logged, the server grade wins.
        { questionId: w.premium.id, selectedOptionId: wrongOf(w.premium), localIsCorrect: true },
      ],
    };
    const first = (await call<SyncResult>(s, 'POST', '/offline/sync', { attempts: [attempt] })).data
      .results[0]!;
    expect(first).toMatchObject({ status: 'accepted', correctCount: 2, totalCount: 3, mismatches: 1 });
    const again = (await call<SyncResult>(s, 'POST', '/offline/sync', { attempts: [attempt] })).data
      .results[0]!;
    expect(again).toMatchObject({ status: 'accepted', attemptId: first.attemptId, mismatches: 0 });
    expect(
      await t.c.db
        .select()
        .from(quizAttempts)
        .where(eq(quizAttempts.clientAttemptId, attempt.clientAttemptId)),
    ).toHaveLength(1);
    const logged = await t.c.db
      .select()
      .from(offlineGradeMismatches)
      .where(eq(offlineGradeMismatches.userId, s.id));
    expect(logged).toMatchObject([{ questionId: w.premium.id, localCorrect: true, serverCorrect: false }]);
    // The wrong answer is in the mistake bank, as from an online attempt.
    const mistakes = await t.c.learning.mistakes(s.id, { status: 'active' });
    expect(mistakes.items.map((m) => m.questionId)).toEqual([w.premium.id]);
  });

  it('counts premium questions covered by a lease even after access ended, and nothing without one', async () => {
    const w = await world();
    const s = await student();
    const random = (ids: string[]) => ({
      clientAttemptId: randomUUID(),
      source: 'random',
      mode: 'practice',
      subjectId: w.subjectId,
      questionIds: ids,
      startedAt: clock.now().toISOString(),
      submittedAt: clock.now().toISOString(),
      answers: ids.map((id) => ({
        questionId: id,
        selectedOptionId: correctOf(id === w.free.id ? w.free : w.premium),
      })),
    });
    // No entitlement, no lease: the premium question is dropped; the free one counts.
    const none = (
      await call<SyncResult>(s, 'POST', '/offline/sync', { attempts: [random([w.premium.id, w.free.id])] })
    ).data.results[0]!;
    expect(none).toMatchObject({ status: 'accepted', totalCount: 1, correctCount: 1 });
    expect(
      (await call<SyncResult>(s, 'POST', '/offline/sync', { attempts: [random([w.premium.id])] })).data
        .results[0],
    ).toMatchObject({ status: 'rejected', reason: 'no_questions' });

    const id = await grant(s, w);
    await call(s, 'POST', '/offline/licenses/refresh', {
      scopes: [{ scopeType: 'subject', subjectId: w.subjectId }],
    });
    await adminCall('POST', `/entitlements/${id}/revoke`, { reason: 'انتهى' });
    // Answered offline while the lease was valid: still counts.
    expect(
      (await call<SyncResult>(s, 'POST', '/offline/sync', { attempts: [random([w.premium.id])] })).data
        .results[0],
    ).toMatchObject({ status: 'accepted', totalCount: 1 });
  });

  it('refuses a mock exam that was never allowed offline', async () => {
    const w = await world();
    const s = await student();
    await grant(s, w);
    const res = await call<SyncResult>(s, 'POST', '/offline/sync', {
      attempts: [
        {
          clientAttemptId: randomUUID(),
          source: 'curated',
          mode: 'exam',
          quizId: w.mock,
          questionIds: [w.free.id],
          startedAt: clock.now().toISOString(),
          submittedAt: clock.now().toISOString(),
          answers: [],
        },
      ],
    });
    expect(res.data.results[0]).toMatchObject({ status: 'rejected', reason: 'quiz_unavailable' });
  });
});
