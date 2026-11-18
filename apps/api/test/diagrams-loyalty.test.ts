import { randomUUID } from 'node:crypto';
import { eq } from 'drizzle-orm';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { mediaFiles, userDailyActivity, users } from '@plengo/db';
import { newCardState, schedule } from '@plengo/srs';
import { toCsv } from '../src/lib/tabular.js';
import {
  body,
  createTestApp,
  enrolledAdminSession,
  levelId,
  tokensFor,
  type TestContext,
} from './helpers.js';

/*
 * v3 §9 «رسمات العلوم» (diagrams) and v3 §10 loyalty points (docs/redesign/V3_PLAN.md).
 */

let t: TestContext;
let admin: Record<string, string>;

beforeAll(async () => {
  t = await createTestApp();
  admin = (await enrolledAdminSession(t)).headers;
  await setDefaultFreeLessons(3);
});
afterAll(async () => {
  await setDefaultFreeLessons(0);
  await t.close();
});

/** v3 §3 default (the test database starts with 0): the first three lessons are free. */
async function setDefaultFreeLessons(n: number) {
  const res = await t.app.inject({
    method: 'PUT',
    url: '/api/v1/admin/settings/access',
    headers: admin,
    payload: { allowTemporaryToPermanentUpgrade: true, defaultFreeLessons: n },
  });
  expect(res.statusCode).toBe(200);
  await t.queue.drain(t.c.jobHandlers);
}

const slug = (p: string) => `${p}-${randomUUID().slice(0, 8)}`;
type Json = Record<string, unknown>;

async function adminCall<T = Json>(
  method: 'GET' | 'POST' | 'PATCH' | 'PUT' | 'DELETE',
  url: string,
  payload?: object,
) {
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
}
async function student(): Promise<Student> {
  const { email, accessToken } = await tokensFor(t);
  const [u] = await t.c.db.select({ id: users.id }).from(users).where(eq(users.email, email));
  return { id: u!.id, token: accessToken };
}
async function call<T = Json>(
  s: Student,
  method: 'GET' | 'POST' | 'PUT' | 'DELETE',
  url: string,
  payload?: object,
) {
  const res = await t.app.inject({
    method,
    url: `/api/v1${url}`,
    headers: { authorization: `Bearer ${s.token}`, 'x-app-platform': 'android' },
    ...(payload ? { payload } : {}),
  });
  return { status: res.statusCode, ...body<T>(res) };
}

async function image(kind: 'flashcard' | 'cover' = 'flashcard') {
  const id = randomUUID();
  const bucket = kind === 'cover' ? 'public' : 'private';
  const variants = {
    full: { key: `test/${kind}/${id}/full.webp`, width: 1080, height: 720, size: 10 },
    thumb: { key: `test/${kind}/${id}/thumb.webp`, width: 360, height: 240, size: 5 },
  };
  for (const v of Object.values(variants))
    await t.storage.put(bucket, v.key, Buffer.from('img'), 'image/webp');
  await t.c.db.insert(mediaFiles).values({
    id,
    bucket,
    storageKey: `test/${kind}/${id}/original`,
    kind,
    mimeType: 'image/png',
    originalSize: 100,
    variants,
    status: 'ready',
  });
  return id;
}

/** A subject with two units of two lessons each; with the default rule the first three lessons are free. */
async function world() {
  const levelCode = 'grade-12';
  const subject = (
    await adminCall<{ id: string; code: string }>('POST', '/subjects', {
      educationLevelId: await levelId(t, levelCode),
      code: slug('sub'),
      nameAr: 'العلوم',
    })
  ).data;
  const unit = async (titleAr: string) =>
    (
      await adminCall<{ id: string; code: string }>('POST', '/units', {
        subjectId: subject.id,
        code: slug('u'),
        titleAr,
      })
    ).data;
  const lesson = async (unitId: string, titleAr: string) =>
    (
      await adminCall<{ id: string; code: string }>('POST', '/lessons', {
        subjectId: subject.id,
        unitId,
        code: slug('l'),
        titleAr,
      })
    ).data;
  const u1 = await unit('الوحدة الأولى');
  const u2 = await unit('الوحدة الثانية');
  const l1 = await lesson(u1.id, 'الدرس 1');
  const l2 = await lesson(u1.id, 'الدرس 2');
  const l3 = await lesson(u2.id, 'الدرس 3');
  const l4 = await lesson(u2.id, 'الدرس 4');
  return { levelCode, subject, u1, u2, l1, l2, l3, l4 };
}

type AdminDiagram = {
  id: string;
  isFree: boolean;
  status: string;
  contentVersion: number;
  unitId: string | null;
  lessonId: string | null;
  image: { fullUrl: string } | null;
  labels: { id: string; number: number; x: number | null; y: number | null; answers: string[] }[];
};

const LABELS = [
  { number: 1, answers: ['النواة'] },
  { number: 2, answers: ['الغشاء البلازمي', 'الغشاء الخلوي'], x: 0.2, y: 0.75 },
  { number: 3, answers: ['الميتوكوندريا', 'المتقدرة'] },
];

async function diagram(payload: Json, publish = true) {
  const res = await adminCall<AdminDiagram>('POST', '/diagrams', {
    titleAr: `رسمة ${randomUUID().slice(0, 6)}`,
    imageMediaId: await image(),
    labels: LABELS,
    publish,
    ...payload,
  });
  expect(res.status, JSON.stringify(res.error)).toBe(200);
  return res.data;
}

async function setLoyalty(patch: Json) {
  const res = await adminCall('PUT', '/settings/loyalty', {
    enabled: true,
    pointsPerReview: 1,
    dailyCap: 50,
    pointsPerCorrectQuestion: 0,
    ...patch,
  });
  expect(res.status, JSON.stringify(res.error)).toBe(200);
}

describe('diagrams «رسمات العلوم» (v3 §9)', () => {
  it('admin CRUD validates labels, follows the free rules, bumps the version and soft-deletes', async () => {
    const w = await world();
    const bad = async (labels: unknown) => {
      const res = await adminCall('POST', '/diagrams', {
        subjectId: w.subject.id,
        titleAr: 'خطأ',
        imageMediaId: await image(),
        labels,
      });
      expect(res.status).toBe(400);
    };
    await bad([
      { number: 1, answers: ['أ'] },
      { number: 1, answers: ['ب'] },
    ]);
    await bad([{ number: 1, answers: ['أ'], x: 0.5 }]);
    await bad([{ number: 1, answers: ['ـــ'] }]);
    // A cover image (public kind) is not a diagram image.
    const wrongImage = await adminCall('POST', '/diagrams', {
      subjectId: w.subject.id,
      titleAr: 'خطأ',
      imageMediaId: await image('cover'),
      labels: LABELS,
    });
    expect(wrongImage.status).toBe(400);

    const free = await diagram({ subjectId: w.subject.id, lessonId: w.l1.id });
    expect(free).toMatchObject({ status: 'published', isFree: true, unitId: w.u1.id, lessonId: w.l1.id });
    expect(free.image?.fullUrl).toBeTruthy();
    expect(free.labels.map((l) => l.number)).toEqual([1, 2, 3]);
    expect(free.labels[1]).toMatchObject({ x: 0.2, y: 0.75, answers: ['الغشاء البلازمي', 'الغشاء الخلوي'] });
    const paid = await diagram({ subjectId: w.subject.id, lessonId: w.l4.id });
    expect(paid.isFree).toBe(false);

    // Duplicate answers (after normalisation) collapse; label edits bump the version.
    const edited = await adminCall<AdminDiagram>('PATCH', `/diagrams/${free.id}`, {
      labels: [
        { number: 2, answers: ['الغشاء البلازمي'], x: 0.1, y: 0.1 },
        { number: 1, answers: ['النواة', 'النَّواة'] },
      ],
    });
    expect(edited.status).toBe(200);
    expect(edited.data.contentVersion).toBe(free.contentVersion + 1);
    expect(edited.data.labels.map((l) => [l.number, l.answers])).toEqual([
      [2, ['الغشاء البلازمي']],
      [1, ['النواة']],
    ]);
    // Moving to another lesson is placement only.
    const moved = await adminCall<AdminDiagram>('PATCH', `/diagrams/${free.id}`, { lessonId: w.l2.id });
    expect(moved.data.contentVersion).toBe(edited.data.contentVersion);
    expect(moved.data.unitId).toBe(w.u1.id);

    const list = await adminCall<{ items: AdminDiagram[]; totalCount: number }>(
      'GET',
      `/diagrams?subjectId=${w.subject.id}&q=${encodeURIComponent('المتقدرة')}`,
    );
    expect(list.data.items.map((d) => d.id)).toEqual([paid.id]);
    const byLesson = await adminCall<{ items: AdminDiagram[] }>('GET', `/diagrams?lessonId=${w.l4.id}`);
    expect(byLesson.data.items.map((d) => d.id)).toEqual([paid.id]);

    // Manual override, then an explicit `diagrams` rule.
    expect(
      (await adminCall<AdminDiagram>('PUT', `/diagrams/${paid.id}/free`, { mode: 'free' })).data.isFree,
    ).toBe(true);
    expect(
      (await adminCall<AdminDiagram>('PUT', `/diagrams/${paid.id}/free`, { mode: 'rule' })).data.isFree,
    ).toBe(false);
    const rule = await adminCall('PUT', '/free-rules', {
      scopeType: 'subject',
      subjectId: w.subject.id,
      contentKind: 'diagrams',
      ruleType: 'first_n_items',
      ruleValue: 5,
    });
    expect(rule.status, JSON.stringify(rule.error)).toBe(200);
    await t.queue.drain(t.c.jobHandlers);
    expect((await adminCall<AdminDiagram>('GET', `/diagrams/${paid.id}`)).data.isFree).toBe(true);

    expect((await adminCall('DELETE', `/diagrams/${paid.id}`)).status).toBe(200);
    expect((await adminCall('GET', `/diagrams/${paid.id}`)).status).toBe(404);
  });

  it('lists a scope with locked flags, practises accessible ones without answers and checks normalised names', async () => {
    const w = await world();
    const inL1 = await diagram({ subjectId: w.subject.id, lessonId: w.l1.id });
    const inL3 = await diagram({ subjectId: w.subject.id, lessonId: w.l3.id });
    const inL4 = await diagram({ subjectId: w.subject.id, lessonId: w.l4.id });
    await diagram({ subjectId: w.subject.id, lessonId: w.l3.id }, false); // draft: never listed
    const s = await student();

    type List = {
      items: { id: string; locked: boolean; labelCount: number }[];
      accessibleCount: number;
      lockedCount: number;
    };
    const unit2 = await call<List>(s, 'GET', `/diagrams?subjectId=${w.subject.id}&unitId=${w.u2.id}`);
    expect(unit2.status).toBe(200);
    expect(unit2.data.items.map((d) => [d.id, d.locked])).toEqual([
      [inL3.id, false],
      [inL4.id, true],
    ]);
    expect(unit2.data).toMatchObject({ accessibleCount: 1, lockedCount: 1 });
    expect(unit2.data.items[0]!.labelCount).toBe(3);
    const lessons = await call<List>(
      s,
      'GET',
      `/diagrams?subjectId=${w.subject.id}&lessonIds=${w.l1.id},${w.l4.id}`,
    );
    expect(lessons.data.items.map((d) => d.id)).toEqual([inL1.id, inL4.id]);

    type Practice = {
      diagrams: { id: string; image: { fullUrl: string }; labels: { number: number; x: number | null }[] }[];
      availableCount: number;
      lockedCount: number;
    };
    const practice = await call<Practice>(s, 'POST', '/diagrams/practice', {
      subjectId: w.subject.id,
      count: 10,
    });
    expect(practice.status).toBe(200);
    expect(practice.data).toMatchObject({ availableCount: 2, lockedCount: 1 });
    expect(practice.data.diagrams.map((d) => d.id).sort()).toEqual([inL1.id, inL3.id].sort());
    expect(practice.data.diagrams[0]!.labels.map((l) => l.number)).toEqual([1, 2, 3]);
    expect(practice.data.diagrams[0]!.image.fullUrl).toBeTruthy();
    expect(JSON.stringify(practice.data)).not.toContain('النواة');
    const one = await call<Practice>(s, 'POST', '/diagrams/practice', {
      subjectId: w.subject.id,
      lessonIds: [w.l3.id, w.l4.id],
      count: 1,
    });
    expect(one.data.diagrams.map((d) => d.id)).toEqual([inL3.id]);

    const today = async () => {
      const rows = await t.c.db.select().from(userDailyActivity).where(eq(userDailyActivity.userId, s.id));
      return rows.reduce((n, r) => n + r.itemsDone, 0);
    };
    const before = await today();
    type Check = {
      correctCount: number;
      totalCount: number;
      labels: { number: number; isCorrect: boolean; answer: string | null; acceptedAnswers: string[] }[];
    };
    const check = await call<Check>(s, 'POST', `/diagrams/${inL1.id}/check`, {
      answers: [
        { number: 1, answer: '  النَّواه ' },
        { number: 2, answer: 'الغشاء   الخلوى' },
      ],
    });
    expect(check.status, JSON.stringify(check.error)).toBe(200);
    expect(check.data).toMatchObject({ correctCount: 2, totalCount: 3 });
    expect(check.data.labels.map((l) => [l.number, l.isCorrect, l.answer])).toEqual([
      [1, true, 'النَّواه'],
      [2, true, 'الغشاء   الخلوى'],
      [3, false, null],
    ]);
    expect(check.data.labels[2]!.acceptedAnswers).toEqual(['الميتوكوندريا', 'المتقدرة']);
    expect(await today()).toBe(before + 1);

    expect(
      (await call(s, 'POST', `/diagrams/${inL1.id}/check`, { answers: [{ number: 9, answer: 'x' }] })).status,
    ).toBe(400);
    const locked = await call(s, 'POST', `/diagrams/${inL4.id}/check`, { answers: [] });
    expect(locked.error?.code).toBe('CONTENT_LOCKED');

    // An entitlement opens the rest.
    await adminCall('POST', `/students/${s.id}/entitlements`, {
      scopeType: 'subject',
      subjectId: w.subject.id,
      permanentAccess: true,
    });
    const all = await call<List>(s, 'GET', `/diagrams?subjectId=${w.subject.id}`);
    expect(all.data).toMatchObject({ accessibleCount: 3, lockedCount: 0 });
  });

  it('imports diagrams from a sheet plus images: dry run, row errors, then one transaction', async () => {
    const w = await world();
    const header = [
      'diagram_ref',
      'education_level_code',
      'subject_code',
      'unit_code',
      'lesson_code',
      'title',
      'image_file',
      'label_number',
      'answers',
      'x',
      'y',
    ];
    const base = [w.levelCode, w.subject.code, w.u1.code, w.l1.code];
    const rows = [
      ['cell', ...base, 'الخلية', 'cell.png', '1', 'النواة', '', ''],
      ['cell', ...base, '', '', '2', 'الغشاء البلازمي | الغشاء الخلوي', '0.3', '0.4'],
      [
        'virus',
        w.levelCode,
        w.subject.code,
        w.u2.code,
        w.l4.code,
        'الفيروس',
        'virus.png',
        '1',
        'الغلاف',
        '',
        '',
      ],
    ];
    const send = (r: string[][], extra: Json) =>
      adminCall<{
        diagrams: { ref: string; labels: { number: number; answers: string[] }[] }[];
        requiredImages: string[];
        missingImages: string[];
        errors: { rowNumber: number; field: string }[];
        createdIds: string[];
      }>('POST', '/diagrams/import', {
        format: 'csv',
        fileName: 'd.csv',
        contentBase64: toCsv({ header, rows: r }).toString('base64'),
        ...extra,
      });

    const dry = await send(rows, { dryRun: true });
    expect(dry.status, JSON.stringify(dry.error)).toBe(200);
    expect(dry.data.errors).toEqual([]);
    expect(dry.data.requiredImages.sort()).toEqual(['cell.png', 'virus.png']);
    expect(dry.data.missingImages.sort()).toEqual(['cell.png', 'virus.png']);
    expect(dry.data.diagrams.find((d) => d.ref === 'cell')!.labels).toEqual([
      { number: 1, answers: ['النواة'] },
      { number: 2, answers: ['الغشاء البلازمي', 'الغشاء الخلوي'] },
    ]);

    const broken = await send(
      [
        ...rows,
        ['cell', ...base, '', '', '2', 'مكرر', '', ''],
        ['x', w.levelCode, w.subject.code, '', 'nope', 't', 'x.png', '1', 'a', '', ''],
      ],
      { dryRun: true },
    );
    expect(broken.data.errors.map((e) => [e.rowNumber, e.field])).toEqual([
      [5, 'label_number'],
      [6, 'lesson_code'],
    ]);

    const images = { 'cell.png': await image(), 'virus.png': await image() };
    // A real run without every image creates nothing.
    const partial = await send(rows, { dryRun: false, images: { 'cell.png': images['cell.png'] } });
    expect(partial.data.createdIds).toEqual([]);
    expect(partial.data.errors.map((e) => e.field)).toEqual(['image_file']);

    const done = await send(rows, { dryRun: false, images, publish: true });
    expect(done.status, JSON.stringify(done.error)).toBe(200);
    expect(done.data.createdIds).toHaveLength(2);
    const created = await adminCall<{ items: AdminDiagram[] }>('GET', `/diagrams?subjectId=${w.subject.id}`);
    expect(created.data.items.map((d) => [d.lessonId, d.status, d.isFree, d.labels.length])).toEqual([
      [w.l1.id, 'published', true, 2],
      [w.l4.id, 'published', false, 1],
    ]);
    expect(created.data.items[0]!.labels[1]).toMatchObject({ x: 0.3, y: 0.4 });

    const template = await t.app.inject({
      method: 'GET',
      url: '/api/v1/admin/diagrams/import/template?format=csv',
      headers: admin,
    });
    expect(template.statusCode).toBe(200);
    expect(template.body).toContain('diagram_ref');
  });
});

// ---------------------------------------------------------------------------------------------

describe('loyalty points (v3 §10)', () => {
  afterAll(async () => {
    await setLoyalty({});
  });

  async function deckIn(w: Awaited<ReturnType<typeof world>>, lessonId: string, cards = 6) {
    const d = (
      await adminCall<{ id: string }>('POST', '/decks', {
        titleAr: 'بطاقات',
        subjectId: w.subject.id,
        lessonId,
      })
    ).data;
    const ids: string[] = [];
    for (let i = 0; i < cards; i++)
      ids.push(
        (
          await adminCall<{ id: string }>('POST', `/decks/${d.id}/cards`, {
            frontMediaId: await image(),
            backMediaId: await image(),
          })
        ).data.id,
      );
    expect((await adminCall('POST', `/decks/${d.id}/status`, { status: 'published' })).status).toBe(200);
    return { deckId: d.id, cardIds: ids };
  }

  function reviewLog(flashcardId: string, at = Date.now() - 60_000) {
    const before = newCardState(at);
    const after = schedule(before, 'good', at, flashcardId);
    const iso = (x: typeof before) => ({
      ...x,
      dueAt: new Date(x.dueAt).toISOString(),
      lastReviewedAt: x.lastReviewedAt === null ? null : new Date(x.lastReviewedAt).toISOString(),
    });
    return {
      id: randomUUID(),
      flashcardId,
      rating: 'good',
      stateBefore: iso(before),
      stateAfter: iso(after),
      reviewedAt: new Date(at).toISOString(),
    };
  }

  type Summary = { balance: number; earnedToday: number; remainingToday: number | null; dailyCap: number };
  type Sync = { acceptedLogs: number; pointsEarned: number };

  it('has editable defaults; awards reviews once each within the daily cap; correct answers once a day', async () => {
    await setLoyalty({});
    const defaults = await adminCall('GET', '/settings/loyalty');
    expect(defaults.data).toEqual({
      enabled: true,
      pointsPerReview: 1,
      dailyCap: 50,
      pointsPerCorrectQuestion: 0,
    });
    await setLoyalty({ dailyCap: 3, pointsPerCorrectQuestion: 2 });

    const w = await world();
    const { cardIds } = await deckIn(w, w.l1.id);
    const s = await student();
    const logs = cardIds.slice(0, 5).map((id) => reviewLog(id));
    const sync = await call<Sync>(s, 'POST', '/srs/sync', { logs, states: [] });
    expect(sync.status, JSON.stringify(sync.error)).toBe(200);
    expect(sync.data).toMatchObject({ acceptedLogs: 5, pointsEarned: 3 });
    // Replaying the same logs earns nothing.
    const again = await call<Sync>(s, 'POST', '/srs/sync', { logs, states: [] });
    expect(again.data).toMatchObject({ acceptedLogs: 0, pointsEarned: 0 });

    const summary = await call<Summary>(s, 'GET', '/loyalty');
    expect(summary.data).toMatchObject({ balance: 3, earnedToday: 3, remainingToday: 0, dailyCap: 3 });

    // A correct check: nothing while capped, then once per question per day.
    const q = await adminCall<{ id: string; options: { id: string; isCorrect: boolean }[] }>(
      'POST',
      '/questions',
      {
        type: 'mcq',
        subjectId: w.subject.id,
        lessonId: w.l1.id,
        questionText: 'سؤال',
        options: [
          { text: 'أ', isCorrect: true },
          { text: 'ب', isCorrect: false },
        ],
        publish: true,
      },
    );
    const right = q.data.options.find((o) => o.isCorrect)!.id;
    const wrong = q.data.options.find((o) => !o.isCorrect)!.id;
    await call(s, 'POST', `/questions/${q.data.id}/check`, { selectedOptionId: right });
    expect((await call<Summary>(s, 'GET', '/loyalty')).data.balance).toBe(3);
    await setLoyalty({ dailyCap: 10, pointsPerCorrectQuestion: 2 });
    await call(s, 'POST', `/questions/${q.data.id}/check`, { selectedOptionId: right });
    await call(s, 'POST', `/questions/${q.data.id}/check`, { selectedOptionId: right });
    await call(s, 'POST', `/questions/${q.data.id}/check`, { selectedOptionId: wrong });
    expect((await call<Summary>(s, 'GET', '/loyalty')).data).toMatchObject({ balance: 5, earnedToday: 5 });

    const history = await call<{ items: { reason: string; delta: number }[] }>(s, 'GET', '/loyalty/history');
    expect(history.data.items.map((i) => [i.reason, i.delta])).toEqual([
      ['correct_answer', 2],
      ['review', 1],
      ['review', 1],
      ['review', 1],
    ]);

    // Undone reviews never earn; nor does anything while the programme is off.
    const undone = await call<Sync>(s, 'POST', '/srs/sync', {
      logs: [{ ...reviewLog(cardIds[5]!), undone: true }],
      states: [],
    });
    expect(undone.data.pointsEarned).toBe(0);
    await setLoyalty({ enabled: false });
    const off = await call<Sync>(s, 'POST', '/srs/sync', { logs: [reviewLog(cardIds[4]!)], states: [] });
    expect(off.data).toMatchObject({ acceptedLogs: 1, pointsEarned: 0 });
  });

  it('redeems rewards: insufficient points, a deck unlock grants access, custom waits for the admin', async () => {
    await setLoyalty({});
    const w = await world();
    const locked = await deckIn(w, w.l4.id, 7);
    const s = await student();
    const cardsOf = (who = s) =>
      call<{ previewOnly: boolean; cards: unknown[]; deck: { locked: boolean } }>(
        who,
        'GET',
        `/decks/${locked.deckId}/cards`,
      );
    expect((await cardsOf()).data.previewOnly).toBe(true);

    const deckReward = await adminCall<{ id: string; deckTitleAr: string }>('POST', '/loyalty/rewards', {
      titleAr: 'افتح مجموعة الفيروسات',
      costPoints: 100,
      kind: 'unlock_deck',
      deckId: locked.deckId,
    });
    expect(deckReward.status, JSON.stringify(deckReward.error)).toBe(200);
    expect(deckReward.data.deckTitleAr).toBe('بطاقات');
    expect(
      (await adminCall('POST', '/loyalty/rewards', { titleAr: 'x', costPoints: 1, kind: 'unlock_deck' }))
        .status,
    ).toBe(400);
    const custom = await adminCall<{ id: string }>('POST', '/loyalty/rewards', {
      titleAr: 'دفتر بلينغو',
      costPoints: 30,
      kind: 'custom',
    });
    const hidden = await adminCall<{ id: string }>('POST', '/loyalty/rewards', {
      titleAr: 'مخفية',
      costPoints: 1,
      kind: 'custom',
      isActive: false,
    });

    const rewards = await call<{
      balance: number;
      items: { id: string; affordable: boolean; alreadyOwned: boolean }[];
    }>(s, 'GET', '/loyalty/rewards');
    const ours = [deckReward.data.id, custom.data.id, hidden.data.id];
    expect(
      rewards.data.items.filter((r) => ours.includes(r.id)).map((r) => [r.id, r.affordable, r.alreadyOwned]),
    ).toEqual([
      [custom.data.id, false, false],
      [deckReward.data.id, false, false],
    ]);

    const short = await call(s, 'POST', `/loyalty/rewards/${deckReward.data.id}/redeem`);
    expect(short.status).toBe(409);
    expect(short.error?.code).toBe('INSUFFICIENT_POINTS');

    const adjusted = await adminCall<{ balance: number; ledger: { reason: string; note: string }[] }>(
      'POST',
      `/students/${s.id}/loyalty/adjust`,
      { delta: 150, note: 'هدية' },
    );
    expect(adjusted.data.balance).toBe(150);
    expect(adjusted.data.ledger[0]).toMatchObject({ reason: 'admin_adjust', note: 'هدية' });
    expect(
      (await adminCall('POST', `/students/${s.id}/loyalty/adjust`, { delta: -1000, note: 'x' })).error?.code,
    ).toBe('INSUFFICIENT_POINTS');

    const redeemed = await call<{ redemption: { status: string; deckId: string }; balance: number }>(
      s,
      'POST',
      `/loyalty/rewards/${deckReward.data.id}/redeem`,
    );
    expect(redeemed.status, JSON.stringify(redeemed.error)).toBe(200);
    expect(redeemed.data).toMatchObject({
      balance: 50,
      redemption: { status: 'fulfilled', deckId: locked.deckId },
    });
    const opened = await cardsOf();
    expect(opened.data).toMatchObject({ previewOnly: false, deck: { locked: false } });
    expect(opened.data.cards).toHaveLength(7);
    const twice = await call(s, 'POST', `/loyalty/rewards/${deckReward.data.id}/redeem`);
    expect(twice.error?.code).toBe('ALREADY_ENTITLED');
    // Another student is still locked out.
    expect((await cardsOf(await student())).data.previewOnly).toBe(true);

    const pending = await call<{ redemption: { id: string; status: string }; balance: number }>(
      s,
      'POST',
      `/loyalty/rewards/${custom.data.id}/redeem`,
    );
    expect(pending.data).toMatchObject({ balance: 20, redemption: { status: 'pending' } });
    expect((await call(s, 'POST', `/loyalty/rewards/${hidden.data.id}/redeem`)).status).toBe(404);

    const list = await adminCall<{ items: { id: string; studentEmail: string | null }[] }>(
      'GET',
      `/loyalty/redemptions?status=pending&userId=${s.id}`,
    );
    expect(list.data.items.map((r) => r.id)).toEqual([pending.data.redemption.id]);
    expect(list.data.items[0]!.studentEmail).toContain('@');
    const cancelled = await adminCall<{ status: string }>(
      'POST',
      `/loyalty/redemptions/${pending.data.redemption.id}/status`,
      { status: 'cancelled', note: 'نفدت الكمية' },
    );
    expect(cancelled.data.status).toBe('cancelled');
    expect(
      (
        await adminCall('POST', `/loyalty/redemptions/${pending.data.redemption.id}/status`, {
          status: 'fulfilled',
        })
      ).status,
    ).toBe(400);

    const detail = await adminCall<{ balance: number; unlockedDeckIds: string[]; redemptions: unknown[] }>(
      'GET',
      `/students/${s.id}/loyalty`,
    );
    expect(detail.data).toMatchObject({ balance: 50, unlockedDeckIds: [locked.deckId] });
    expect(detail.data.redemptions).toHaveLength(2);
    expect((await call<unknown[]>(s, 'GET', '/loyalty/redemptions')).data).toHaveLength(2);

    // Cancelling the deck redemption refunds it and closes the deck again.
    const deckRedemption = (
      await adminCall<{ items: { id: string; kind: string }[] }>('GET', `/loyalty/redemptions?userId=${s.id}`)
    ).data.items.find((r) => r.kind === 'unlock_deck')!;
    await adminCall('POST', `/loyalty/redemptions/${deckRedemption.id}/status`, { status: 'cancelled' });
    expect((await cardsOf()).data.previewOnly).toBe(true);
    expect((await call<Summary>(s, 'GET', '/loyalty')).data.balance).toBe(150);

    expect((await adminCall('DELETE', `/loyalty/rewards/${custom.data.id}`)).status).toBe(200);
    expect(
      (await adminCall<{ id: string }[]>('GET', '/loyalty/rewards')).data.some(
        (r) => r.id === custom.data.id,
      ),
    ).toBe(false);
  });
});
