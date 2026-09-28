import { generateKeyPairSync, randomUUID } from 'node:crypto';
import { and, eq } from 'drizzle-orm';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { auditLogs, cardStates, mediaFiles, pushTokens, userDailyActivity, users } from '@plengo/db';
import type { RecordingPushSender } from '../src/services/push.js';
import { FcmPushSender } from '../src/services/push.js';
import { dueReminderText } from '../src/services/notification-service.js';
import { goalStreak } from '../src/services/home-service.js';
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
const DAY = 86_400_000;
const slug = (p: string) => `${p}-${randomUUID().slice(0, 8)}`;

async function adminCall<T = Json>(
  method: 'GET' | 'POST' | 'PATCH' | 'DELETE' | 'PUT',
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
async function student(level = 'grade-12'): Promise<Student> {
  const { email, accessToken } = await tokensFor(t);
  const [u] = await t.c.db.select({ id: users.id }).from(users).where(eq(users.email, email));
  const s = { id: u!.id, token: accessToken };
  if (level !== 'grade-12') await call(s, 'PATCH', '/me', { educationLevelId: await levelId(t, level) });
  return s;
}
async function call<T = Json>(
  s: Student,
  method: 'GET' | 'POST' | 'PUT' | 'PATCH',
  url: string,
  payload?: object,
) {
  const res = await t.app.inject({
    method,
    url: `/api/v1${url}`,
    headers: { authorization: `Bearer ${s.token}` },
    ...(payload ? { payload } : {}),
  });
  return { status: res.statusCode, ...body<T>(res) };
}

type Home = {
  greetingName: string;
  unreadNotifications: number;
  countdown: { titleAr: string; daysLeft: number } | null;
  banners: { id: string; titleAr: string; imageUrl: string; action: string; actionTarget: string | null }[];
  today: { dueCards: number; goal: number; done: number; goalMet: boolean; streak: number };
  myAccess: unknown[];
};
const home = async (s: Student) => (await call<Home>(s, 'GET', '/home')).data;

async function bannerImage() {
  const id = randomUUID();
  await t.storage.put('public', `test/banner/${id}/full.webp`, Buffer.from('img'), 'image/webp');
  await t.c.db.insert(mediaFiles).values({
    id,
    bucket: 'public',
    storageKey: `test/banner/${id}/original`,
    kind: 'banner',
    mimeType: 'image/png',
    originalSize: 100,
    variants: { full: { key: `test/banner/${id}/full.webp`, width: 1600, height: 600, size: 1000 } },
    status: 'ready',
  });
  return id;
}

const srsState = (reviewedAt: string) => ({
  state: 'learning',
  step: 0,
  dueAt: reviewedAt,
  intervalDays: 0,
  ease: 2.5,
  reps: 1,
  lapses: 0,
  lastReviewedAt: reviewedAt,
});

describe('daily goal and streak (§19.4)', () => {
  it('counts graded answers and ratings per business day starting 04:00 Damascus', async () => {
    const s = await student();
    const w = await deckWorld();
    const today = await home(s);
    expect(today.today).toMatchObject({ goal: 20, done: 0, goalMet: false, streak: 0 });

    // Two ratings: 03:59 Damascus (00:59 UTC) belongs to the previous day, 04:01 to this one.
    const at = new Date(t.clock.now());
    const base = Date.UTC(at.getUTCFullYear(), at.getUTCMonth(), at.getUTCDate());
    const before = new Date(base + 59 * 60_000).toISOString();
    const after = new Date(base + 61 * 60_000).toISOString();
    const log = (id: string, reviewedAt: string) => ({
      id,
      flashcardId: w.cardId,
      rating: 'good',
      stateBefore: srsState(reviewedAt),
      stateAfter: srsState(reviewedAt),
      reviewedAt,
    });
    await call(s, 'POST', '/srs/sync', {
      logs: [log(randomUUID(), before), log(randomUUID(), after)],
      states: [],
    });
    const rows = await t.c.db.select().from(userDailyActivity).where(eq(userDailyActivity.userId, s.id));
    const days = new Map(rows.map((r) => [r.day, r.itemsDone]));
    expect(days.get(new Date(base - DAY).toISOString().slice(0, 10))).toBe(1);
    expect(days.get(new Date(base).toISOString().slice(0, 10))).toBe(1);
  });

  it("meets the goal, keeps each day's goal, and counts a streak of met days", async () => {
    const s = await student();
    expect((await call(s, 'PUT', '/me/settings', { dailyGoal: 2 })).status).toBe(200);
    expect((await call<{ dailyGoal: number }>(s, 'GET', '/me/settings')).data.dailyGoal).toBe(2);
    expect((await call(s, 'PUT', '/me/settings', { dailyGoal: 0 })).status).toBe(400);

    // Two previous days met, the day before them not.
    const now = t.clock.now().getTime();
    const day = (offset: number) =>
      new Date(Math.floor((now + 3 * 3600_000 - 4 * 3600_000) / DAY) * DAY + offset * DAY)
        .toISOString()
        .slice(0, 10);
    await t.c.db.insert(userDailyActivity).values([
      { userId: s.id, day: day(-1), itemsDone: 5, goal: 5, goalMet: true },
      { userId: s.id, day: day(-2), itemsDone: 9, goal: 5, goalMet: true },
      { userId: s.id, day: day(-3), itemsDone: 1, goal: 5, goalMet: false },
    ]);
    expect((await home(s)).today).toMatchObject({ goal: 2, done: 0, goalMet: false, streak: 2 });

    const w = await deckWorld();
    await t.c.learning.addBookmark(s.id, 'deck', w.deckId).catch(() => undefined);
    // Two graded question checks meet today's goal.
    for (let i = 0; i < 2; i++) {
      const res = await call(s, 'POST', `/questions/${w.questionId}/check`, { selectedOptionId: w.optionId });
      expect(res.status).toBe(200);
    }
    expect((await home(s)).today).toMatchObject({ done: 2, goalMet: true, streak: 3 });
    // Raising the goal today applies to today; past days keep theirs.
    await call(s, 'PUT', '/me/settings', { dailyGoal: 10 });
    expect((await home(s)).today).toMatchObject({ goal: 10, goalMet: false, streak: 2 });
  });

  it('computes streaks from met days', () => {
    expect(goalStreak(new Set([10, 9, 8]), 10)).toBe(3);
    expect(goalStreak(new Set([9, 8]), 10)).toBe(2); // today still open
    expect(goalStreak(new Set([8]), 10)).toBe(0);
  });
});

async function deckWorld() {
  const subject = (
    await adminCall<{ id: string }>('POST', '/subjects', {
      educationLevelId: await levelId(t, 'grade-12'),
      code: slug('bio'),
      nameAr: 'الأحياء',
    })
  ).data;
  const q = (
    await adminCall<{ id: string; options: { id: string; isCorrect: boolean }[] }>('POST', '/questions', {
      type: 'mcq',
      subjectId: subject.id,
      questionText: 'ما الخلية؟',
      options: [
        { text: 'وحدة الحياة', isCorrect: true },
        { text: 'عضو', isCorrect: false },
      ],
      publish: true,
    })
  ).data;
  await adminCall('PUT', `/questions/${q.id}/free`, { mode: 'free' });
  const media = async () => {
    const id = randomUUID();
    await t.c.db.insert(mediaFiles).values({
      id,
      bucket: 'private',
      storageKey: `test/fc/${id}`,
      kind: 'flashcard',
      mimeType: 'image/png',
      originalSize: 1,
      variants: { full: { key: `test/fc/${id}/f`, width: 1, height: 1, size: 1 } },
      status: 'ready',
    });
    return id;
  };
  const deck = (
    await adminCall<{ id: string }>('POST', '/decks', { subjectId: subject.id, titleAr: 'خلايا' })
  ).data;
  const card = (
    await adminCall<{ id: string }>('POST', `/decks/${deck.id}/cards`, {
      frontMediaId: await media(),
      backMediaId: await media(),
    })
  ).data;
  await adminCall('POST', `/decks/${deck.id}/status`, { status: 'published' });
  return {
    subjectId: subject.id,
    deckId: deck.id,
    cardId: card.id,
    questionId: q.id,
    optionId: q.options.find((o) => o.isCorrect)!.id,
  };
}

describe('banners and exam countdown (§19.2, §19.3)', () => {
  it('shows live, level-targeted banners in order and validates click actions', async () => {
    const g12 = await levelId(t, 'grade-12');
    const g9 = await levelId(t, 'grade-9');
    const make = (payload: Json) => adminCall<{ id: string; live: boolean }>('POST', '/banners', payload);
    const img = await bannerImage();
    expect(
      (await make({ titleAr: 'x', imageMediaId: img, action: 'external_url', actionTarget: 'http://a.b' }))
        .status,
    ).toBe(400);
    expect(
      (await make({ titleAr: 'x', imageMediaId: img, action: 'subject', actionTarget: 'not-an-id' })).status,
    ).toBe(400);
    expect((await make({ titleAr: 'x', imageMediaId: img, action: 'subject' })).status).toBe(400);
    expect((await make({ titleAr: 'x', imageMediaId: randomUUID() })).status).toBe(400);

    const now = t.clock.now().getTime();
    const all = (
      await make({ titleAr: 'للجميع', imageMediaId: img, action: 'internal_route', actionTarget: '/review' })
    ).data;
    const mine = (
      await make({
        titleAr: 'للبكالوريا',
        imageMediaId: await bannerImage(),
        educationLevelId: g12,
        action: 'external_url',
        actionTarget: 'https://example.com',
      })
    ).data;
    await make({ titleAr: 'للتاسع', imageMediaId: await bannerImage(), educationLevelId: g9 });
    await make({
      titleAr: 'لاحقاً',
      imageMediaId: await bannerImage(),
      startsAt: new Date(now + DAY).toISOString(),
    });
    await make({
      titleAr: 'انتهى',
      imageMediaId: await bannerImage(),
      endsAt: new Date(now - DAY).toISOString(),
    });
    const off = (await make({ titleAr: 'متوقف', imageMediaId: await bannerImage(), isActive: false })).data;
    expect(off.live).toBe(false);
    expect(
      (
        await make({
          titleAr: 'خطأ',
          imageMediaId: await bannerImage(),
          startsAt: new Date(now).toISOString(),
          endsAt: new Date(now - 1).toISOString(),
        })
      ).status,
    ).toBe(400);

    const s = await student();
    const titles = (await home(s)).banners.map((b) => b.titleAr);
    expect(titles).toEqual(expect.arrayContaining(['للجميع', 'للبكالوريا']));
    expect(titles).not.toEqual(expect.arrayContaining(['للتاسع']));
    for (const hidden of ['لاحقاً', 'انتهى', 'متوقف']) expect(titles).not.toContain(hidden);
    expect((await home(s)).banners.find((b) => b.titleAr === 'للبكالوريا')).toMatchObject({
      action: 'external_url',
      actionTarget: 'https://example.com',
    });

    // Reorder: every banner in the new order.
    const list = (await adminCall<{ id: string }[]>('GET', '/banners')).data.map((b) => b.id);
    expect((await adminCall('POST', '/banners/reorder', { ids: [mine.id] })).status).toBe(400);
    const order = [mine.id, ...list.filter((id) => id !== mine.id)];
    expect((await adminCall('POST', '/banners/reorder', { ids: order })).status).toBe(200);
    const after = (await home(s)).banners.map((b) => b.id);
    expect(after.indexOf(mine.id)).toBeLessThan(after.indexOf(all.id));

    await adminCall('PATCH', `/banners/${all.id}`, { isActive: false });
    expect((await home(s)).banners.map((b) => b.id)).not.toContain(all.id);
    // A partial update leaves the tap action alone.
    await adminCall('PATCH', `/banners/${mine.id}`, { isActive: false });
    await adminCall('PATCH', `/banners/${mine.id}`, { isActive: true });
    expect((await home(s)).banners.find((b) => b.id === mine.id)).toMatchObject({ action: 'external_url' });
    await adminCall('DELETE', `/banners/${mine.id}`);
    expect((await home(s)).banners.map((b) => b.id)).not.toContain(mine.id);
    const logs = await t.c.db.select().from(auditLogs).where(eq(auditLogs.resourceId, all.id));
    expect(logs.map((l) => l.action)).toEqual(expect.arrayContaining(['banner.created', 'banner.updated']));
  });

  it('counts down to the next exam of the student level', async () => {
    const g9 = await levelId(t, 'grade-9');
    const today = new Date(t.clock.now().getTime() + 3 * 3600_000);
    const inDays = (n: number) => new Date(today.getTime() + n * DAY).toISOString().slice(0, 10);
    await adminCall('POST', '/countdowns', {
      educationLevelId: g9,
      titleAr: 'امتحان سابق',
      examDate: inDays(-3),
    });
    const c = (
      await adminCall<{ id: string; daysLeft: number }>('POST', '/countdowns', {
        educationLevelId: g9,
        titleAr: 'امتحان الشهادة الإعدادية',
        examDate: inDays(87),
      })
    ).data;
    expect(c.daysLeft).toBe(87);
    const s = await student('grade-9');
    expect((await home(s)).countdown).toMatchObject({ titleAr: 'امتحان الشهادة الإعدادية', daysLeft: 87 });
    await adminCall('PATCH', `/countdowns/${c.id}`, { isActive: false });
    expect((await home(s)).countdown).toBeNull();
    expect((await adminCall('DELETE', `/countdowns/${c.id}`)).status).toBe(200);
  });
});

describe('notifications (§20)', () => {
  const push = () => t.c.push as RecordingPushSender;

  it('fans out to the target, honours consent, and keeps an inbox with read state', async () => {
    const g9 = await levelId(t, 'grade-9');
    const a = await student('grade-9');
    const b = await student('grade-9');
    const other = await student();
    await call(a, 'POST', '/push-tokens', {
      token: 'token-a-0123456789',
      platform: 'android',
      appVersion: '1.0.0',
    });
    await call(b, 'POST', '/push-tokens', { token: 'token-b-0123456789', platform: 'ios' });
    await call(b, 'PUT', '/notifications/preferences', { learning: false });
    push().invalid.add('token-a-0123456789');

    const sent = await adminCall<{ id: string; status: string }>('POST', '/notifications', {
      type: 'new_content',
      titleAr: 'محتوى جديد',
      bodyAr: 'أضفنا أسئلة جديدة',
      action: 'internal_route',
      actionTarget: '/subjects',
      targetType: 'level',
      target: { educationLevelId: g9 },
    });
    expect(sent.data.status).toBe('queued');
    await t.queue.drain(t.c.jobHandlers);

    type Page = { items: { id: string; titleAr: string; readAt: string | null }[]; unreadCount: number };
    const inboxA = (await call<Page>(a, 'GET', '/notifications')).data;
    expect(inboxA.items.map((i) => i.titleAr)).toContain('محتوى جديد');
    expect(inboxA.unreadCount).toBeGreaterThan(0);
    expect((await call<Page>(b, 'GET', '/notifications')).data.items.map((i) => i.titleAr)).toContain(
      'محتوى جديد',
    );
    expect((await call<Page>(other, 'GET', '/notifications')).data.items.map((i) => i.titleAr)).not.toContain(
      'محتوى جديد',
    );
    // Push: A's device only (B turned learning notifications off); A's token was stale and is revoked.
    const last = push().sent.at(-1)!;
    expect(last.tokens).toEqual(['token-a-0123456789']);
    const [tokenA] = await t.c.db.select().from(pushTokens).where(eq(pushTokens.token, 'token-a-0123456789'));
    expect(tokenA!.revokedAt).not.toBeNull();

    const list = (
      await adminCall<{
        items: { id: string; status: string; recipientCount: number; pushFailures: number }[];
      }>('GET', '/notifications')
    ).data;
    const row = list.items.find((i) => i.id === sent.data.id)!;
    expect(row.status).toBe('sent');
    expect(row.recipientCount).toBeGreaterThanOrEqual(2);
    expect(row.pushFailures).toBe(1);

    const entry = inboxA.items.find((i) => i.titleAr === 'محتوى جديد')!;
    const read = await call<{ unreadCount: number }>(a, 'POST', `/notifications/${entry.id}/read`);
    expect(read.data.unreadCount).toBe(inboxA.unreadCount - 1);
    expect((await call(b, 'POST', `/notifications/${entry.id}/read`)).status).toBe(404); // not B's entry
    expect((await call<{ unreadCount: number }>(a, 'POST', '/notifications/read-all')).data.unreadCount).toBe(
      0,
    );
    expect((await home(a)).unreadNotifications).toBe(0);
  });

  it('delivers promotions only to students who opted in (§20.2)', async () => {
    const a = await student();
    const b = await student();
    expect((await call<{ promotions: boolean }>(a, 'GET', '/notifications/preferences')).data).toMatchObject({
      learning: true,
      promotions: false,
      reminderTime: '18:00',
    });
    await call(b, 'PUT', '/notifications/preferences', { promotions: true });
    await call(b, 'POST', '/push-tokens', { token: 'token-promo-0123456789', platform: 'android' });
    await call(a, 'POST', '/push-tokens', { token: 'token-nopromo-0123456789', platform: 'android' });
    await adminCall('POST', '/notifications', {
      type: 'promotion',
      titleAr: 'عرض خاص',
      bodyAr: 'خصم',
      targetType: 'students',
      target: { userIds: [a.id, b.id] },
    });
    await t.queue.drain(t.c.jobHandlers);
    const titles = async (s: Student) =>
      (await call<{ items: { titleAr: string }[] }>(s, 'GET', '/notifications')).data.items.map(
        (i) => i.titleAr,
      );
    expect(await titles(a)).not.toContain('عرض خاص');
    expect(await titles(b)).toContain('عرض خاص');
    expect(push().sent.at(-1)!.tokens).toEqual(['token-promo-0123456789']);
  });

  it('validates targets', async () => {
    const bad = (target: Json, targetType: string) =>
      adminCall('POST', '/notifications', {
        type: 'announcement',
        titleAr: 'x',
        bodyAr: 'y',
        targetType,
        target,
      });
    expect((await bad({}, 'level')).status).toBe(400);
    expect((await bad({ subjectId: randomUUID() }, 'subject_entitlement')).status).toBe(400);
    expect((await bad({ userIds: [] }, 'students')).status).toBe(400);
    expect(
      (
        await adminCall('POST', '/notifications', {
          type: 'due_reminder',
          titleAr: 'x',
          bodyAr: 'y',
          targetType: 'all',
        })
      ).status,
    ).toBe(400);
  });

  it('reminds students with due cards once a day at their chosen time (§20.3)', async () => {
    const s = await student();
    const quiet = await student();
    const w = await deckWorld();
    const hour = String(new Date(t.clock.now().getTime() + 3 * 3600_000).getUTCHours()).padStart(2, '0');
    const due = new Date(t.clock.now().getTime() - 3600_000);
    for (const u of [s, quiet]) {
      await t.c.db.insert(cardStates).values({
        userId: u.id,
        flashcardId: w.cardId,
        state: 'review',
        dueAt: due,
        ease: 2.5,
        lastReviewedAt: new Date(due.getTime() - DAY),
      });
      await call(u, 'PUT', '/notifications/preferences', { reminderTime: `${hour}:30` });
    }
    await call(quiet, 'PUT', '/notifications/preferences', { learning: false });
    const sent = await t.c.notifications.dueReminders();
    await t.queue.drain(t.c.jobHandlers);
    expect(sent).toBeGreaterThanOrEqual(1);
    const inbox = async (u: Student) =>
      (await call<{ items: { bodyAr: string }[] }>(u, 'GET', '/notifications')).data.items.map(
        (i) => i.bodyAr,
      );
    expect(await inbox(s)).toContain('لديك بطاقة واحدة للمراجعة اليوم');
    expect(await inbox(quiet)).toEqual([]);
    // Once a day.
    await t.c.notifications.dueReminders();
    await t.queue.drain(t.c.jobHandlers);
    expect((await inbox(s)).filter((b) => b.startsWith('لديك'))).toHaveLength(1);
    expect(dueReminderText(35)).toBe('لديك 35 بطاقة للمراجعة اليوم');
    expect(dueReminderText(2)).toBe('لديك بطاقتان للمراجعة اليوم');
    expect(dueReminderText(5)).toBe('لديك 5 بطاقات للمراجعة اليوم');
  });

  it('tells a student their report was handled, when the admin asks (§21)', async () => {
    const s = await student();
    const w = await deckWorld();
    const r = (
      await call<{ id: string }>(s, 'POST', '/reports', {
        itemType: 'question',
        itemId: w.questionId,
        reason: 'typo',
      })
    ).data;
    await adminCall('POST', `/reports/${r.id}/resolve`, { status: 'resolved', notifyStudent: true });
    await t.queue.drain(t.c.jobHandlers);
    const items = (await call<{ items: { titleAr: string }[] }>(s, 'GET', '/notifications')).data.items;
    expect(items.map((i) => i.titleAr)).toContain('شكراً لبلاغك');
  });

  it('registers and revokes push tokens', async () => {
    const s = await student();
    expect((await call(s, 'POST', '/push-tokens', { token: 'short', platform: 'android' })).status).toBe(400);
    await call(s, 'POST', '/push-tokens', { token: 'token-s-0123456789', platform: 'android' });
    await call(s, 'POST', '/push-tokens/revoke', { token: 'token-s-0123456789' });
    const [row] = await t.c.db
      .select()
      .from(pushTokens)
      .where(and(eq(pushTokens.token, 'token-s-0123456789'), eq(pushTokens.userId, s.id)));
    expect(row!.revokedAt).not.toBeNull();
  });
});

describe('FCM sender', () => {
  it('authenticates with a signed JWT, sends, and reports unregistered tokens', async () => {
    const { privateKey } = generateKeyPairSync('rsa', { modulusLength: 2048 });
    const calls: { url: string; body: string }[] = [];
    const fake = (async (url: string, init?: RequestInit) => {
      calls.push({ url: String(url), body: String(init?.body ?? '') });
      if (String(url).includes('oauth2'))
        return new Response(JSON.stringify({ access_token: 'at', expires_in: 3600 }));
      if (String(init?.body).includes('"gone"')) {
        return new Response(JSON.stringify({ error: { status: 'NOT_FOUND' } }), { status: 404 });
      }
      return new Response('{}');
    }) as typeof fetch;
    const sender = new FcmPushSender(
      {
        projectId: 'plengo',
        clientEmail: 'push@plengo.iam',
        privateKey: privateKey.export({ type: 'pkcs8', format: 'pem' }).toString(),
      },
      t.app.log,
      fake,
    );
    const result = await sender.send(['ok-token', 'gone'], { title: 'عنوان', body: 'نص' });
    expect(result).toEqual({ sent: 1, failed: 1, invalidTokens: ['gone'] });
    expect(calls[0]!.url).toBe('https://oauth2.googleapis.com/token');
    const assertion = new URLSearchParams(calls[0]!.body).get('assertion')!;
    expect(assertion.split('.')).toHaveLength(3);
    expect(calls[1]!.url).toBe('https://fcm.googleapis.com/v1/projects/plengo/messages:send');
    // The access token is reused.
    await sender.send(['ok-token'], { title: 'a', body: 'b' });
    expect(calls.filter((c) => c.url.includes('oauth2'))).toHaveLength(1);
  });
});
