import { randomUUID } from 'node:crypto';
import { and, eq, sql } from 'drizzle-orm';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { auditLogs, cardStates, mediaFiles, reviewLogs, users } from '@plengo/db';
import { newCardState, schedule, type CardState } from '@plengo/srs';
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

const slug = (p: string) => `${p}-${randomUUID().slice(0, 8)}`;
type Json = Record<string, unknown>;
type Deck = { id: string; status: string; isFree: boolean; contentVersion: number; cardCount: number };
type Card = {
  id: string;
  contentVersion: number;
  status: string;
  front: { fullUrl: string; cacheKey: string };
};

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
async function studentCall<T = Json>(s: Student, method: 'GET' | 'POST', url: string, payload?: object) {
  const res = await t.app.inject({
    method,
    url: `/api/v1${url}`,
    headers: { authorization: `Bearer ${s.token}`, 'x-app-platform': 'android' },
    ...(payload ? { payload } : {}),
  });
  return { status: res.statusCode, raw: res.body, ...body<T>(res) };
}

/** A processed private flashcard image, as the upload pipeline leaves it. */
async function flashcardImage(kind: 'flashcard' | 'cover' = 'flashcard') {
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

async function world() {
  const subject = (
    await adminCall<{ id: string }>('POST', '/subjects', {
      educationLevelId: await levelId(t, 'grade-12'),
      code: slug('phys'),
      nameAr: 'الفيزياء',
    })
  ).data;
  const unit = (
    await adminCall<{ id: string }>('POST', '/units', {
      subjectId: subject.id,
      code: slug('u'),
      titleAr: 'الوحدة',
    })
  ).data;
  const teacher = (
    await adminCall<{ id: string }>('POST', '/teachers', { nameAr: 'أ. أحمد', slug: slug('t') })
  ).data;
  const track = (
    await adminCall<{ id: string }>('POST', '/teacher-tracks', {
      teacherId: teacher.id,
      subjectId: subject.id,
      titleAr: 'مسار',
      slug: slug('tr'),
    })
  ).data;
  return { subjectId: subject.id, unitId: unit.id, trackId: track.id };
}

async function deckWithCards(payload: Json, cards = 2, publish = true) {
  const deck = (await adminCall<Deck>('POST', '/decks', { titleAr: 'بطاقات الحركة', ...payload })).data;
  const created: Card[] = [];
  for (let i = 0; i < cards; i++) {
    const res = await adminCall<Card>('POST', `/decks/${deck.id}/cards`, {
      frontMediaId: await flashcardImage(),
      backMediaId: await flashcardImage(),
    });
    created.push(res.data);
  }
  if (publish) {
    const pub = await adminCall('POST', `/decks/${deck.id}/status`, { status: 'published' });
    expect(pub.status).toBe(200);
  }
  return { deck: (await adminCall<Deck>('GET', `/decks/${deck.id}`)).data, cards: created };
}

describe('admin decks and cards (§13.1)', () => {
  it('creates decks with cards, versions them, and audits', async () => {
    const w = await world();
    const empty = (await adminCall<Deck>('POST', '/decks', { subjectId: w.subjectId, titleAr: 'فارغة' }))
      .data;
    expect((await adminCall('POST', `/decks/${empty.id}/status`, { status: 'published' })).error?.code).toBe(
      'VALIDATION_ERROR',
    );

    const { deck, cards } = await deckWithCards({ subjectId: w.subjectId, unitId: w.unitId });
    expect(deck).toMatchObject({ status: 'published', cardCount: 2 });
    // Two cards added: membership changed twice.
    expect(deck.contentVersion).toBe(3);

    const renamed = await adminCall<Deck>('PATCH', `/decks/${deck.id}`, { titleAr: 'اسم جديد' });
    expect(renamed.data.contentVersion).toBe(4);
    expect(
      (await adminCall<Deck>('PATCH', `/decks/${deck.id}`, { titleAr: 'اسم جديد' })).data.contentVersion,
    ).toBe(4);

    // Reorder: moved cards and the deck get new versions.
    expect(
      (await adminCall('POST', `/decks/${deck.id}/cards/reorder`, { ids: [cards[1]!.id, cards[0]!.id] }))
        .status,
    ).toBe(200);
    const listed = await adminCall<Card[]>('GET', `/decks/${deck.id}/cards`);
    expect(listed.data.map((c) => c.id)).toEqual([cards[1]!.id, cards[0]!.id]);
    expect(listed.data.every((c) => c.contentVersion === 2)).toBe(true);
    expect((await adminCall<Deck>('GET', `/decks/${deck.id}`)).data.contentVersion).toBe(5);

    // New images bump the card only.
    const swapped = await adminCall<Card>('PATCH', `/cards/${cards[0]!.id}`, {
      frontMediaId: await flashcardImage(),
    });
    expect(swapped.data.contentVersion).toBe(3);
    expect((await adminCall<Deck>('GET', `/decks/${deck.id}`)).data.contentVersion).toBe(5);

    // Card images must be processed flashcard images.
    const cover = await flashcardImage('cover');
    expect(
      (await adminCall('POST', `/decks/${deck.id}/cards`, { frontMediaId: cover, backMediaId: cover })).error
        ?.code,
    ).toBe('VALIDATION_ERROR');
    expect((await adminCall<Deck>('PATCH', `/decks/${deck.id}`, { coverMediaId: cover })).status).toBe(200);

    const logs = await t.c.db.select().from(auditLogs).where(eq(auditLogs.resourceId, deck.id));
    expect(logs.map((l) => l.action)).toEqual(
      expect.arrayContaining(['deck.created', 'deck.published', 'deck.updated']),
    );

    expect((await adminCall('DELETE', `/units/${w.unitId}`)).error?.code).toBe('RESOURCE_IN_USE');
  });

  it('applies the free rule on publish and supports overrides (§8.4)', async () => {
    const w = await world();
    await adminCall('PUT', '/free-rules', {
      scopeType: 'subject',
      subjectId: w.subjectId,
      contentKind: 'flashcard_decks',
      ruleType: 'first_n_items',
      ruleValue: 1,
    });
    await t.queue.drain(t.c.jobHandlers);
    const first = await deckWithCards({ subjectId: w.subjectId }, 1);
    const second = await deckWithCards({ subjectId: w.subjectId, titleAr: 'ثانية' }, 1);
    expect(first.deck.isFree).toBe(true);
    expect(second.deck.isFree).toBe(false);
    const forced = await adminCall<Deck>('PUT', `/decks/${second.deck.id}/free`, { mode: 'free' });
    expect(forced.data.isFree).toBe(true);
  });
});

describe('student decks (§8.6, §12.5)', () => {
  it('lists locked decks as metadata and serves signed card URLs only when open', async () => {
    const w = await world();
    const { deck } = await deckWithCards({ subjectId: w.subjectId });
    const trackDeck = await deckWithCards({
      subjectId: w.subjectId,
      teacherTrackId: w.trackId,
      titleAr: 'مسار',
    });
    const s = await student();

    const list = await studentCall<{ id: string; locked: boolean; cardCount: number }[]>(
      s,
      'GET',
      `/decks?subjectId=${w.subjectId}`,
    );
    expect(list.data).toMatchObject([{ id: deck.id, locked: true, cardCount: 2 }]);
    const locked = await studentCall(s, 'GET', `/decks/${deck.id}/cards`);
    expect(locked.error?.code).toBe('CONTENT_LOCKED');
    expect(locked.raw).not.toContain('dev-storage');
    expect(locked.raw).not.toContain('memory://');

    const outline = await studentCall<{ deckCount: { total: number; free: number } }>(
      s,
      'GET',
      `/subjects/${w.subjectId}`,
    );
    expect(outline.data.deckCount).toEqual({ total: 1, free: 0 });

    await adminCall('POST', `/students/${s.id}/entitlements`, {
      scopeType: 'subject',
      subjectId: w.subjectId,
      permanentAccess: true,
    });
    const open = await studentCall<{
      cards: { front: { fullUrl: string; cacheKey: string } }[];
      urlsExpireAt: string;
    }>(s, 'GET', `/decks/${deck.id}/cards`);
    expect(open.status).toBe(200);
    expect(open.data.cards).toHaveLength(2);
    expect(open.data.cards[0]!.front.fullUrl).toMatch(/^memory:\/\/private\/.+sig=/);
    expect(open.data.cards[0]!.front.cacheKey).toMatch(/^[0-9a-f-]{36}:1$/);
    // A subject entitlement does not open the track's deck.
    expect((await studentCall(s, 'GET', `/decks/${trackDeck.deck.id}/cards`)).error?.code).toBe(
      'CONTENT_LOCKED',
    );

    await adminCall('POST', `/decks/${deck.id}/status`, { status: 'archived' });
    expect((await studentCall(s, 'GET', `/decks/${deck.id}`)).status).toBe(404);
  });
});

describe('SRS sync (§13.6–§13.8)', () => {
  const iso = (s: CardState) => ({
    ...s,
    dueAt: new Date(s.dueAt).toISOString(),
    lastReviewedAt: s.lastReviewedAt === null ? null : new Date(s.lastReviewedAt).toISOString(),
  });

  async function setup() {
    const w = await world();
    const { deck, cards } = await deckWithCards({ subjectId: w.subjectId }, 3);
    await adminCall('PUT', `/decks/${deck.id}/free`, { mode: 'free' });
    return { w, deck, cards, s: await student() };
  }

  it('stores logs idempotently and keeps the latest review per card', async () => {
    const { cards, s } = await setup();
    const card = cards[0]!.id;
    const t0 = Date.now() - 60 * 60_000;
    const before = newCardState(t0);
    const after = schedule(before, 'good', t0, card);
    const log = {
      id: randomUUID(),
      flashcardId: card,
      rating: 'good',
      stateBefore: iso(before),
      stateAfter: iso(after),
      reviewedAt: new Date(t0).toISOString(),
      durationMs: 3200,
    };
    const payload = { logs: [log], states: [{ flashcardId: card, ...iso(after) }] };

    const first = await studentCall<{
      acceptedLogs: number;
      appliedStates: number;
      states: { state: string; reps: number }[];
    }>(s, 'POST', '/srs/sync', payload);
    expect(first.data).toMatchObject({
      acceptedLogs: 1,
      appliedStates: 1,
      states: [{ state: 'learning', reps: 1 }],
    });
    const again = await studentCall<{ acceptedLogs: number; appliedStates: number }>(
      s,
      'POST',
      '/srs/sync',
      payload,
    );
    expect(again.data).toMatchObject({ acceptedLogs: 0, appliedStates: 0 });
    expect(await t.c.db.select().from(reviewLogs).where(eq(reviewLogs.id, log.id))).toMatchObject([
      { devicePlatform: 'android', durationMs: 3200 },
    ]);

    // An older state from another device never overwrites a newer one.
    const later = schedule(after, 'good', t0 + 10 * 60_000, card);
    await studentCall(s, 'POST', '/srs/sync', { logs: [], states: [{ flashcardId: card, ...iso(later) }] });
    const stale = await studentCall<{ appliedStates: number; states: { state: string }[] }>(
      s,
      'POST',
      '/srs/sync',
      {
        logs: [],
        states: [{ flashcardId: card, ...iso(after) }],
      },
    );
    expect(stale.data.appliedStates).toBe(0);
    expect(stale.data.states[0]!.state).toBe('review');

    // Unknown cards are rejected; states with no review are ignored.
    expect(
      (
        await studentCall(s, 'POST', '/srs/sync', {
          logs: [],
          states: [{ flashcardId: randomUUID(), ...iso(after) }],
        })
      ).status,
    ).toBe(400);
    const unreviewed = await studentCall<{ appliedStates: number }>(s, 'POST', '/srs/sync', {
      logs: [],
      states: [{ flashcardId: cards[1]!.id, ...iso(newCardState(t0)) }],
    });
    expect(unreviewed.data.appliedStates).toBe(0);
  });

  it('undo restores the state before the review when it is still the latest', async () => {
    const { cards, s } = await setup();
    const card = cards[0]!.id;
    const t0 = Date.now() - 60 * 60_000;
    const s1 = schedule(newCardState(t0), 'easy', t0, card);
    const log1 = {
      id: randomUUID(),
      flashcardId: card,
      rating: 'easy',
      stateBefore: iso(newCardState(t0)),
      stateAfter: iso(s1),
      reviewedAt: new Date(t0).toISOString(),
    };
    await studentCall(s, 'POST', '/srs/sync', { logs: [log1], states: [{ flashcardId: card, ...iso(s1) }] });
    const s2 = schedule(s1, 'again', t0 + 60_000, card);
    const log2 = {
      id: randomUUID(),
      flashcardId: card,
      rating: 'again',
      stateBefore: iso(s1),
      stateAfter: iso(s2),
      reviewedAt: new Date(t0 + 60_000).toISOString(),
    };
    await studentCall(s, 'POST', '/srs/sync', { logs: [log2], states: [{ flashcardId: card, ...iso(s2) }] });

    const undone = await studentCall<{ states: { state: string; lapses: number }[] }>(
      s,
      'POST',
      '/srs/sync',
      {
        logs: [{ ...log2, undone: true }],
        states: [],
      },
    );
    expect(undone.data.states[0]).toMatchObject({ state: 'review', lapses: 0 });
    const [stored] = await t.c.db.select().from(reviewLogs).where(eq(reviewLogs.id, log2.id));
    expect(stored!.undone).toBe(true);

    // Undoing the earlier review too (undo is a stack) brings the card back to new.
    await studentCall(s, 'POST', '/srs/sync', { logs: [{ ...log1, undone: true }], states: [] });
    const [row] = await t.c.db
      .select()
      .from(cardStates)
      .where(and(eq(cardStates.userId, s.id), eq(cardStates.flashcardId, card)));
    expect(row!.state).toBe('new');
  });

  it('pages changed states with a cursor and lists due cards the student can open', async () => {
    const { w, cards, s } = await setup();
    const t0 = Date.now() - 5 * 86_400_000;
    const due = cards.map((c) => ({
      flashcardId: c.id,
      ...iso(schedule(newCardState(t0), 'easy', t0, c.id)),
    }));
    // Two cards due today (their due date is in the past), one far in the future.
    due[2] = { ...due[2]!, dueAt: new Date(Date.now() + 30 * 86_400_000).toISOString() };
    await studentCall(s, 'POST', '/srs/sync', { logs: [], states: due });

    const page1 = await studentCall<{ items: unknown[]; nextCursor: string }>(
      s,
      'GET',
      '/srs/states?limit=2',
    );
    expect(page1.data.items).toHaveLength(2);
    const page2 = await studentCall<{ items: unknown[]; nextCursor: string | null }>(
      s,
      'GET',
      `/srs/states?since=${page1.data.nextCursor}`,
    );
    expect(page2.data.items).toHaveLength(1);
    const page3 = await studentCall<{ items: unknown[]; nextCursor: string | null }>(
      s,
      'GET',
      `/srs/states?since=${page2.data.nextCursor}`,
    );
    expect(page3.data).toEqual({ items: [], nextCursor: null });

    const dueList = await studentCall<{ cards: { card: { id: string; front: { fullUrl: string } } }[] }>(
      s,
      'GET',
      `/srs/due?subjectId=${w.subjectId}`,
    );
    expect(dueList.data.cards.map((c) => c.card.id).sort()).toEqual([cards[0]!.id, cards[1]!.id].sort());
    expect(dueList.data.cards[0]!.card.front.fullUrl).toContain('sig=');

    // Locked again: cards leave the due list, states stay (§13.8).
    await t.c.db.execute(
      sql`update flashcard_decks set is_free = false where id = (select deck_id from flashcards where id = ${cards[0]!.id})`,
    );
    expect((await studentCall<{ cards: unknown[] }>(s, 'GET', '/srs/due')).data.cards).toHaveLength(0);
    expect((await studentCall<{ items: unknown[] }>(s, 'GET', '/srs/states')).data.items).toHaveLength(3);
  });
});
