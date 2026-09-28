import { randomUUID } from 'node:crypto';
import { eq, inArray } from 'drizzle-orm';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { auditLogs, contentReports, mediaFiles, userCards, users } from '@plengo/db';
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

beforeAll(async () => {
  t = await createTestApp();
  admin = (await enrolledAdminSession(t)).headers;
});
afterAll(async () => {
  await t.close();
});

type Json = Record<string, unknown>;
const slug = (p: string) => `${p}-${randomUUID().slice(0, 8)}`;
const at = (offsetMs = 0) => new Date(Date.now() - 60_000 + offsetMs).toISOString();

async function adminCall<T = Json>(method: 'GET' | 'POST' | 'PUT', url: string, payload?: object) {
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
  return { status: res.statusCode, raw: res.body, ...body<T>(res) };
}

/** A processed image as the upload pipeline leaves it. */
async function image(kind: 'flashcard' | 'user-card', ownerUserId: string | null = null, status = 'ready') {
  const id = randomUUID();
  const variants = {
    full: { key: `test/${kind}/${id}/full.webp`, width: 1080, height: 720, size: 10 },
    thumb: { key: `test/${kind}/${id}/thumb.webp`, width: 360, height: 240, size: 5 },
  };
  for (const v of Object.values(variants))
    await t.storage.put('private', v.key, Buffer.from('img'), 'image/webp');
  await t.c.db.insert(mediaFiles).values({
    id,
    bucket: 'private',
    storageKey: `test/${kind}/${id}/original`,
    kind,
    ownerUserId,
    mimeType: 'image/png',
    originalSize: 100,
    variants,
    status: status as 'ready',
  });
  return id;
}

async function officialDeck() {
  const subject = (
    await adminCall<{ id: string }>('POST', '/subjects', {
      educationLevelId: await levelId(t, 'grade-12'),
      code: slug('phys'),
      nameAr: 'الفيزياء',
    })
  ).data;
  const deck = (
    await adminCall<{ id: string }>('POST', '/decks', { subjectId: subject.id, titleAr: 'رسمية' })
  ).data;
  const card = (
    await adminCall<{ id: string }>('POST', `/decks/${deck.id}/cards`, {
      frontMediaId: await image('flashcard'),
      backMediaId: await image('flashcard'),
    })
  ).data;
  await adminCall('POST', `/decks/${deck.id}/status`, { status: 'published' });
  return { subjectId: subject.id, deckId: deck.id, cardId: card.id };
}

const deckInput = (over: Json = {}) => ({
  id: randomUUID(),
  name: 'مفرداتي',
  sortOrder: 0,
  createdAt: at(),
  updatedAt: at(),
  ...over,
});
const cardInput = (deckId: string, over: Json = {}) => ({
  id: randomUUID(),
  deckId,
  kind: 'custom',
  frontText: 'السؤال',
  backText: 'الجواب',
  sortOrder: 0,
  createdAt: at(),
  updatedAt: at(),
  ...over,
});

type SyncResult = {
  appliedDecks: number;
  appliedCards: number;
  rejected: { type: string; id: string; code: string; reason: string }[];
};
type CardView = {
  id: string;
  kind: string;
  locked: boolean;
  deletedAt: string | null;
  front: { text: string | null; mediaId: string | null; image: { fullUrl: string } | null };
  back: { text: string | null; image: { fullUrl: string } | null };
};
type Changes = {
  decks: { id: string; name: string; cardCount: number; deletedAt: string | null }[];
  cards: CardView[];
  cursor: string;
  hasMore: boolean;
};
const sync = (s: Student, decks: Json[], cards: Json[] = []) =>
  call<SyncResult>(s, 'POST', '/my-decks/sync', { decks, cards });

describe('student decks (§13.9)', () => {
  it('syncs offline-created decks and cards and feeds them to other devices', async () => {
    const s = await student();
    const deck = deckInput({ color: '#FF8800' });
    const img = await image('user-card', s.id);
    const cards = [
      cardInput(deck.id),
      cardInput(deck.id, { frontText: null, frontMediaId: img, sortOrder: 1 }),
    ];
    const res = await sync(s, [deck], cards);
    expect(res.data).toEqual({ appliedDecks: 1, appliedCards: 2, rejected: [] });

    const first = await call<Changes>(s, 'GET', '/my-decks/changes');
    expect(first.data.decks).toMatchObject([{ id: deck.id, name: 'مفرداتي', cardCount: 2, deletedAt: null }]);
    expect(first.data.cards.map((c) => c.id)).toEqual(cards.map((c) => c.id));
    expect(first.data.cards[1]!.front).toMatchObject({ text: null, mediaId: img });
    expect(first.data.cards[1]!.front.image!.fullUrl).toMatch(/^memory:\/\/private\/.+sig=/);
    expect(first.data.hasMore).toBe(false);

    // Nothing new: the same cursor comes back with no items.
    const again = await call<Changes>(s, 'GET', `/my-decks/changes?since=${first.data.cursor}`);
    expect(again.data).toMatchObject({ decks: [], cards: [], cursor: first.data.cursor });

    // Last write wins by updated_at: an older edit is ignored, a newer one applies.
    await sync(s, [], [{ ...cards[0]!, frontText: 'قديم', updatedAt: at(-30_000) }]);
    await sync(s, [], [{ ...cards[0]!, frontText: 'جديد', updatedAt: at(10_000) }]);
    const next = await call<Changes>(s, 'GET', `/my-decks/changes?since=${first.data.cursor}`);
    expect(next.data.cards).toHaveLength(1);
    expect(next.data.cards[0]!.front.text).toBe('جديد');

    // Paging through the feed.
    const paged = await call<Changes>(s, 'GET', '/my-decks/changes?limit=1');
    expect(paged.data.hasMore).toBe(true);
    expect(paged.data.cards).toHaveLength(1);

    const list = await call<{ id: string; cardCount: number }[]>(s, 'GET', '/my-decks');
    expect(list.data).toMatchObject([{ id: deck.id, cardCount: 2 }]);
    const detail = await call<{ cards: CardView[] }>(s, 'GET', `/my-decks/${deck.id}/cards`);
    expect(detail.data.cards).toHaveLength(2);

    // Another student sees nothing of it.
    const other = await student();
    expect((await call(other, 'GET', `/my-decks/${deck.id}/cards`)).status).toBe(404);
    expect((await call<Changes>(other, 'GET', '/my-decks/changes')).data.decks).toEqual([]);
  });

  it('clamps future timestamps so a fast device clock cannot win forever', async () => {
    const s = await student();
    const deck = deckInput({ updatedAt: new Date(Date.now() + 86_400_000).toISOString() });
    await sync(s, [deck]);
    const [row] = (await call<Changes>(s, 'GET', '/my-decks/changes')).data.decks;
    expect(Date.parse((row as unknown as { updatedAt: string }).updatedAt)).toBeLessThanOrEqual(Date.now());
    // A real later edit still wins.
    await sync(s, [{ ...deck, name: 'اسم لاحق', updatedAt: new Date(Date.now() + 1000).toISOString() }]);
    expect((await call<{ name: string }[]>(s, 'GET', '/my-decks')).data[0]!.name).toBe('اسم لاحق');
  });

  it('refuses invalid items without failing the batch', async () => {
    const s = await student();
    const other = await student();
    const deck = deckInput();
    const foreignDeck = deckInput();
    await sync(other, [foreignDeck]);
    const othersImage = await image('user-card', other.id);
    const failedImage = await image('user-card', s.id, 'failed');
    const good = cardInput(deck.id);
    const res = await sync(
      s,
      [deck, { ...foreignDeck, name: 'استيلاء', updatedAt: at(5000) }],
      [
        good,
        cardInput(deck.id, { frontText: '  ' }),
        cardInput(deck.id, { frontMediaId: othersImage }),
        cardInput(deck.id, { backMediaId: failedImage }),
        cardInput(foreignDeck.id),
        cardInput(randomUUID()),
        cardInput(deck.id, { officialFlashcardId: randomUUID() }),
      ],
    );
    expect(res.data.appliedDecks).toBe(1);
    expect(res.data.appliedCards).toBe(1);
    expect(res.data.rejected.map((r) => `${r.type}:${r.code}:${r.reason}`)).toEqual([
      'deck:NOT_FOUND:deck',
      'card:VALIDATION_ERROR:empty_face',
      'card:VALIDATION_ERROR:media',
      'card:VALIDATION_ERROR:media',
      'card:NOT_FOUND:deck',
      'card:NOT_FOUND:deck',
      'card:VALIDATION_ERROR:official_flashcard',
    ]);
    // A card cannot change kind.
    const changed = await sync(s, [], [{ ...good, kind: 'official_ref', updatedAt: at(5000) }]);
    expect(changed.data.rejected[0]).toMatchObject({ code: 'VALIDATION_ERROR', reason: 'kind' });
    // Text is limited to 1,000 characters (§13.9).
    expect((await sync(s, [], [cardInput(deck.id, { frontText: 'x'.repeat(1001) })])).status).toBe(400);
    // The other student's deck is untouched.
    expect((await call<{ name: string }[]>(other, 'GET', '/my-decks')).data[0]!.name).toBe('مفرداتي');
  });

  it('enforces 50 decks and 5,000 cards, and deleting frees them (§12.8)', async () => {
    const s = await student();
    const decks = Array.from({ length: 51 }, (_, i) => deckInput({ sortOrder: i }));
    const res = await sync(s, decks);
    expect(res.data.appliedDecks).toBe(50);
    expect(res.data.rejected).toEqual([
      { type: 'deck', id: decks[50]!.id, code: 'QUOTA_EXCEEDED', reason: 'deck_quota' },
    ]);
    // Deleting one makes room.
    await sync(s, [{ ...decks[0]!, deletedAt: at(1000), updatedAt: at(1000) }]);
    expect((await sync(s, [decks[50]!])).data.appliedDecks).toBe(1);

    // Fill the card quota directly, then sync two more.
    const deckId = decks[1]!.id;
    const now = new Date();
    const rows = Array.from({ length: 4999 }, (_, i) => ({
      id: randomUUID(),
      deckId,
      userId: s.id,
      kind: 'custom' as const,
      frontText: `${i}`,
      backText: `${i}`,
      createdAt: now,
      updatedAt: now,
    }));
    for (let i = 0; i < rows.length; i += 1000)
      await t.c.db.insert(userCards).values(rows.slice(i, i + 1000));
    const two = [cardInput(deckId), cardInput(deckId)];
    const cards = await sync(s, [], two);
    expect(cards.data.appliedCards).toBe(1);
    expect(cards.data.rejected).toEqual([
      { type: 'card', id: two[1]!.id, code: 'QUOTA_EXCEEDED', reason: 'card_quota' },
    ]);
    // Deleting the deck deletes its cards, which frees the card quota.
    await sync(s, [{ ...decks[1]!, deletedAt: at(2000), updatedAt: at(2000) }]);
    expect((await sync(s, [], [{ ...two[1]!, deckId: decks[2]!.id }])).data.appliedCards).toBe(1);
    // A card cannot be added to a deleted deck.
    expect((await sync(s, [], [cardInput(deckId)])).data.rejected[0]).toMatchObject({ reason: 'deck' });
  });

  it('releases images that no live card uses', async () => {
    const s = await student();
    const deck = deckInput();
    const a = await image('user-card', s.id);
    const b = await image('user-card', s.id);
    const card = cardInput(deck.id, { frontMediaId: a });
    await sync(s, [deck], [card]);
    await sync(s, [], [{ ...card, frontMediaId: b, updatedAt: at(1000) }]);
    const rows = async () =>
      new Map(
        (
          await t.c.db
            .select()
            .from(mediaFiles)
            .where(inArray(mediaFiles.id, [a, b]))
        ).map((m) => [m.id, m.deletedAt]),
      );
    expect((await rows()).get(a)).not.toBeNull();
    expect((await rows()).get(b)).toBeNull();
    await sync(s, [], [{ ...card, frontMediaId: b, deletedAt: at(2000), updatedAt: at(2000) }]);
    expect((await rows()).get(b)).not.toBeNull();
    const feed = await call<Changes>(s, 'GET', '/my-decks/changes');
    expect(feed.data.cards[0]!.deletedAt).not.toBeNull();
    expect(feed.data.decks[0]!.cardCount).toBe(0);
  });

  it('adds official cards only while the student can open them ("أضف إلى بطاقاتي")', async () => {
    const s = await student();
    const w = await officialDeck();
    const deck = deckInput({ subjectId: w.subjectId });
    const ref = cardInput(deck.id, {
      kind: 'official_ref',
      frontText: null,
      backText: null,
      officialFlashcardId: w.cardId,
    });
    const locked = await sync(s, [deck], [ref]);
    expect(locked.data.rejected).toEqual([
      { type: 'card', id: ref.id, code: 'CONTENT_LOCKED', reason: 'official_flashcard' },
    ]);

    const grant = await adminCall<{ id: string }>('POST', `/students/${s.id}/entitlements`, {
      scopeType: 'subject',
      subjectId: w.subjectId,
      permanentAccess: true,
    });
    expect((await sync(s, [], [ref])).data.appliedCards).toBe(1);
    let view = (await call<{ cards: CardView[] }>(s, 'GET', `/my-decks/${deck.id}/cards`)).data.cards[0]!;
    expect(view).toMatchObject({ kind: 'official_ref', locked: false });
    expect(view.front.image!.fullUrl).toMatch(/sig=/);

    // Studied, then access ends: the card stays but shows locked and leaves the due queue.
    const state = {
      state: 'review',
      step: 0,
      dueAt: at(-1000),
      intervalDays: 1,
      ease: 2.5,
      reps: 1,
      lapses: 0,
      lastReviewedAt: at(-2000),
    };
    await call(s, 'POST', '/srs/sync', { logs: [], states: [{ ...state, userCardId: ref.id }] });
    const due = await call<{ userCards: { card: { id: string } }[] }>(s, 'GET', '/srs/due');
    expect(due.data.userCards.map((c) => c.card.id)).toEqual([ref.id]);

    await adminCall('POST', `/entitlements/${grant.data.id}/revoke`, { reason: 'اختبار' });
    view = (await call<{ cards: CardView[] }>(s, 'GET', `/my-decks/${deck.id}/cards`)).data.cards[0]!;
    expect(view).toMatchObject({ locked: true, front: { image: null }, back: { image: null } });
    expect((await call<{ userCards: unknown[] }>(s, 'GET', '/srs/due')).data.userCards).toEqual([]);
    // Existing references can still be moved or deleted.
    expect((await sync(s, [], [{ ...ref, sortOrder: 3, updatedAt: at(5000) }])).data.appliedCards).toBe(1);
  });
});

describe('spaced repetition on student cards (§13.7)', () => {
  it('stores states and logs for the student own cards only', async () => {
    const s = await student();
    const other = await student();
    const deck = deckInput();
    const card = cardInput(deck.id);
    await sync(s, [deck], [card]);
    const before = {
      state: 'new',
      step: 0,
      dueAt: at(),
      intervalDays: 0,
      ease: 2.5,
      reps: 0,
      lapses: 0,
      lastReviewedAt: null,
    };
    const after = { ...before, state: 'learning', reps: 1, dueAt: at(60_000), lastReviewedAt: at() };
    const log = {
      id: randomUUID(),
      userCardId: card.id,
      rating: 'good',
      stateBefore: before,
      stateAfter: after,
      reviewedAt: at(),
    };
    const res = await call<{ acceptedLogs: number; states: { userCardId: string; flashcardId: null }[] }>(
      s,
      'POST',
      '/srs/sync',
      { logs: [log], states: [{ ...after, userCardId: card.id }] },
    );
    expect(res.data.acceptedLogs).toBe(1);
    expect(res.data.states).toMatchObject([{ userCardId: card.id, flashcardId: null, state: 'learning' }]);
    const pulled = await call<{ items: { userCardId: string | null }[] }>(s, 'GET', '/srs/states');
    expect(pulled.data.items.map((i) => i.userCardId)).toContain(card.id);

    expect(
      (await call(other, 'POST', '/srs/sync', { logs: [{ ...log, id: randomUUID() }], states: [] })).error
        ?.code,
    ).toBe('VALIDATION_ERROR');
    // Exactly one card id per entry.
    const both = { ...log, id: randomUUID(), flashcardId: randomUUID() };
    expect((await call(s, 'POST', '/srs/sync', { logs: [both], states: [] })).status).toBe(400);
    const neither = { ...log, id: randomUUID(), userCardId: undefined };
    expect((await call(s, 'POST', '/srs/sync', { logs: [neither], states: [] })).status).toBe(400);
  });
});

describe('bookmarks on student cards (§17)', () => {
  it('saves own cards and refuses others', async () => {
    const s = await student();
    const other = await student();
    const deck = deckInput();
    const card = cardInput(deck.id, { frontText: 'قانون نيوتن' });
    await sync(s, [deck], [card]);
    const added = await call<{ available: boolean; titleAr: string; userCard: { id: string } }>(
      s,
      'PUT',
      '/bookmarks',
      { itemType: 'user_card', itemId: card.id },
    );
    expect(added.error).toBeNull();
    expect(added.data).toMatchObject({ available: true, titleAr: 'قانون نيوتن', userCard: { id: card.id } });
    expect(
      (await call(other, 'PUT', '/bookmarks', { itemType: 'user_card', itemId: card.id })).error?.code,
    ).toBe('NOT_FOUND');
    // A deleted card stays saved but unavailable.
    await sync(s, [], [{ ...card, deletedAt: at(1000), updatedAt: at(1000) }]);
    const list = await call<{ items: { available: boolean; userCard: unknown }[] }>(
      s,
      'GET',
      '/bookmarks?itemType=user_card',
    );
    expect(list.data.items).toMatchObject([{ available: false, userCard: null }]);
  });
});

describe('content reports (§21)', () => {
  async function publishedQuestion(subjectId: string, publish = true) {
    return (
      await adminCall<{ id: string }>('POST', '/questions', {
        type: 'true_false',
        subjectId,
        questionText: 'الأرض كروية',
        trueFalseAnswer: true,
        publish,
      })
    ).data.id;
  }

  it('lets students report visible items once each, 20 per day', async () => {
    const s = await student();
    const w = await officialDeck();
    const q = await publishedQuestion(w.subjectId);
    const first = await call<{ id: string; status: string }>(s, 'POST', '/reports', {
      itemType: 'question',
      itemId: q,
      reason: 'wrong_answer',
      note: '  الجواب خاطئ  ',
    });
    expect(first.data).toMatchObject({ status: 'open', note: 'الجواب خاطئ' });
    const repeat = await call<{ id: string }>(s, 'POST', '/reports', {
      itemType: 'question',
      itemId: q,
      reason: 'typo',
    });
    expect(repeat.data.id).toBe(first.data.id);
    expect(
      (
        await call(s, 'POST', '/reports', {
          itemType: 'flashcard',
          itemId: w.cardId,
          reason: 'image_problem',
        })
      ).status,
    ).toBe(200);

    const draft = await publishedQuestion(w.subjectId, false);
    expect(
      (await call(s, 'POST', '/reports', { itemType: 'question', itemId: draft, reason: 'typo' })).error
        ?.code,
    ).toBe('NOT_FOUND');
    expect((await call(s, 'POST', '/reports', { itemType: 'question', itemId: q, reason: 'x' })).status).toBe(
      400,
    );
    expect(
      (
        await call(s, 'POST', '/reports', {
          itemType: 'question',
          itemId: q,
          reason: 'typo',
          note: 'x'.repeat(501),
        })
      ).status,
    ).toBe(400);

    // 2 so far; 18 more (older reports on other items) reach the limit.
    await t.c.db.insert(contentReports).values(
      Array.from({ length: 18 }, () => ({
        userId: s.id,
        itemType: 'question' as const,
        itemId: randomUUID(),
        reason: 'other' as const,
      })),
    );
    const q2 = await publishedQuestion(w.subjectId);
    expect(
      (await call(s, 'POST', '/reports', { itemType: 'question', itemId: q2, reason: 'unclear' })).error
        ?.code,
    ).toBe('RATE_LIMITED');
    expect((await call<unknown[]>(s, 'GET', '/reports')).data).toHaveLength(20);
  });

  it('gives admins an inbox to resolve or dismiss, audited', async () => {
    const s = await student();
    const w = await officialDeck();
    const q = await publishedQuestion(w.subjectId);
    const r = (
      await call<{ id: string }>(s, 'POST', '/reports', { itemType: 'question', itemId: q, reason: 'typo' })
    ).data;
    const c = (
      await call<{ id: string }>(s, 'POST', '/reports', {
        itemType: 'flashcard',
        itemId: w.cardId,
        reason: 'other',
      })
    ).data;

    type Page = {
      items: {
        id: string;
        itemTitleAr: string;
        deckId: string | null;
        subjectNameAr: string;
        studentEmail: string;
        openReportsOnItem: number;
      }[];
      nextCursor: string | null;
    };
    const open = await adminCall<Page>('GET', '/reports?status=open&itemType=question&limit=200');
    const mine = open.data.items.find((i) => i.id === r.id)!;
    expect(mine).toMatchObject({
      itemTitleAr: 'الأرض كروية',
      subjectNameAr: 'الفيزياء',
      openReportsOnItem: 1,
    });
    const cardReport = (await adminCall<Page['items'][number]>('GET', `/reports/${c.id}`)).data;
    expect(cardReport.deckId).toBe(w.deckId);

    const resolved = await adminCall<{ status: string; resolutionNote: string }>(
      'POST',
      `/reports/${r.id}/resolve`,
      { status: 'resolved', resolutionNote: 'تم التصحيح' },
    );
    expect(resolved.data).toMatchObject({ status: 'resolved', resolutionNote: 'تم التصحيح' });
    expect((await adminCall('POST', `/reports/${c.id}/resolve`, { status: 'open' })).status).toBe(400);
    const [log] = await t.c.db.select().from(auditLogs).where(eq(auditLogs.resourceId, r.id));
    expect(log!.action).toBe('report.resolved');

    const students = await call<{ id: string; status: string }[]>(s, 'GET', '/reports');
    expect(students.data.find((x) => x.id === r.id)!.status).toBe('resolved');
    // Students cannot reach the inbox.
    expect((await call(s, 'GET', '/admin/reports')).status).toBe(403);
  });
});
