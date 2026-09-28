import { randomUUID } from 'node:crypto';
import { and, eq } from 'drizzle-orm';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import {
  auditLogs,
  bookmarks,
  entitlements,
  mediaFiles,
  profiles,
  pushTokens,
  sessions,
  userDailyActivity,
  userDecks,
  users,
} from '@plengo/db';
import {
  PASSWORD,
  WEB_ORIGIN,
  body,
  cookieHeader,
  csrfHeaders,
  createTestApp,
  enrolledAdminSession,
  levelId,
  mobileLogin,
  registerVerifiedStudent,
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

const bearer = (token: string) => ({ authorization: `Bearer ${token}` });

/** A student with something in every category §33 names. */
async function populatedStudent() {
  const s = await tokensFor(t);
  const [u] = await t.c.db.select().from(users).where(eq(users.email, s.email));
  const userId = u!.id;
  const image = async (kind: 'avatar' | 'user-card') => {
    const id = randomUUID();
    const key = `test/${kind}/${id}`;
    await t.storage.put('private', `${key}/original`, Buffer.from('o'), 'image/png');
    await t.storage.put('private', `${key}/full.webp`, Buffer.from('f'), 'image/webp');
    await t.c.db.insert(mediaFiles).values({
      id,
      bucket: 'private',
      storageKey: `${key}/original`,
      kind,
      ownerUserId: userId,
      mimeType: 'image/png',
      originalSize: 1,
      variants: { full: { key: `${key}/full.webp`, width: 1, height: 1, size: 1 } },
      status: 'ready',
    });
    return { id, keys: [`${key}/original`, `${key}/full.webp`] };
  };
  const avatar = await image('avatar');
  await t.c.db.update(profiles).set({ avatarMediaId: avatar.id }).where(eq(profiles.userId, userId));
  const cardImage = await image('user-card');
  const deckId = randomUUID();
  const at = new Date().toISOString();
  const sync = await t.app.inject({
    method: 'POST',
    url: '/api/v1/my-decks/sync',
    headers: bearer(s.accessToken),
    payload: {
      decks: [{ id: deckId, name: 'بطاقاتي', color: null, sortOrder: 0, createdAt: at, updatedAt: at }],
      cards: [
        {
          id: randomUUID(),
          deckId,
          kind: 'custom',
          frontText: 'سؤال',
          backText: null,
          backMediaId: cardImage.id,
          sortOrder: 0,
          createdAt: at,
          updatedAt: at,
        },
      ],
    },
  });
  expect(sync.statusCode).toBe(200);
  await t.app.inject({
    method: 'POST',
    url: '/api/v1/push-tokens',
    headers: bearer(s.accessToken),
    payload: { token: `token-${randomUUID()}`, platform: 'android' },
  });
  // An entitlement granted by the admin, a bookmark and a day of activity.
  const subject = await t.app.inject({
    method: 'POST',
    url: '/api/v1/admin/subjects',
    headers: admin,
    payload: { educationLevelId: await levelId(t), code: `del-${randomUUID().slice(0, 8)}`, nameAr: 'مادة' },
  });
  const subjectId = body<{ id: string }>(subject).data.id;
  const grant = await t.app.inject({
    method: 'POST',
    url: `/api/v1/admin/students/${userId}/entitlements`,
    headers: admin,
    payload: { scopeType: 'subject', subjectId, permanentAccess: true },
  });
  expect(grant.statusCode).toBe(200);
  await t.c.db.insert(bookmarks).values({ userId, itemType: 'question', itemId: randomUUID() });
  await t.c.db
    .insert(userDailyActivity)
    .values({ userId, day: '2026-09-01', itemsDone: 5, goal: 20, goalMet: false });
  return { ...s, userId, media: [avatar, cardImage] };
}

describe('account deletion (§33)', () => {
  it('needs the password, then removes personal data and access but keeps anonymous history', async () => {
    const s = await populatedStudent();
    const del = (password: string) =>
      t.app.inject({
        method: 'POST',
        url: '/api/v1/me/delete',
        headers: bearer(s.accessToken),
        payload: { password },
      });

    const wrong = await del('not-the-password');
    expect(wrong.statusCode).toBe(401);
    expect(body(wrong).error?.code).toBe('AUTH_INVALID_CREDENTIALS');

    const ok = await del(PASSWORD);
    expect(ok.statusCode).toBe(200);
    expect(body(ok).data).toEqual({ deleted: true });

    // Signed out everywhere; the old credentials no longer work.
    const me = await t.app.inject({ method: 'GET', url: '/api/v1/me', headers: bearer(s.accessToken) });
    expect(body(me).error?.code).toBe('AUTH_SESSION_EXPIRED');
    expect((await mobileLogin(t, s.email)).statusCode).toBe(401);
    const refresh = await t.app.inject({
      method: 'POST',
      url: '/api/v1/auth/mobile/refresh',
      payload: { refreshToken: s.refreshToken },
    });
    expect(refresh.statusCode).toBe(401);

    // The tombstone keeps no personal data.
    const [u] = await t.c.db.select().from(users).where(eq(users.id, s.userId));
    expect(u).toMatchObject({ status: 'deleted', name: 'حساب محذوف', image: null, emailVerified: false });
    expect(u!.email).toBe(`deleted-${s.userId}@deleted.invalid`);
    expect(u!.deletedAt).not.toBeNull();
    const [p] = await t.c.db.select().from(profiles).where(eq(profiles.userId, s.userId));
    expect(p).toMatchObject({ fullName: 'حساب محذوف', avatarMediaId: null });

    // Gone: sessions, push tokens, bookmarks, student decks and their images (rows and objects).
    expect(await t.c.db.select().from(sessions).where(eq(sessions.userId, s.userId))).toHaveLength(0);
    expect(await t.c.db.select().from(pushTokens).where(eq(pushTokens.userId, s.userId))).toHaveLength(0);
    expect(await t.c.db.select().from(bookmarks).where(eq(bookmarks.userId, s.userId))).toHaveLength(0);
    expect(await t.c.db.select().from(userDecks).where(eq(userDecks.userId, s.userId))).toHaveLength(0);
    expect(await t.c.db.select().from(mediaFiles).where(eq(mediaFiles.ownerUserId, s.userId))).toHaveLength(
      0,
    );
    for (const m of s.media) {
      for (const key of m.keys) expect(await t.storage.get('private', key).catch(() => null)).toBeNull();
    }
    // Access revoked; learning history kept for aggregate statistics.
    const ents = await t.c.db.select().from(entitlements).where(eq(entitlements.userId, s.userId));
    expect(ents.map((e) => [e.status, e.revokeReason])).toEqual([['revoked', 'account_deleted']]);
    expect(
      await t.c.db.select().from(userDailyActivity).where(eq(userDailyActivity.userId, s.userId)),
    ).toHaveLength(1);

    const [log] = await t.c.db
      .select()
      .from(auditLogs)
      .where(and(eq(auditLogs.resourceId, s.userId), eq(auditLogs.action, 'account.deleted')));
    expect(log).toMatchObject({ actorAdminId: null, resourceType: 'user' });

    // The address is free again; admins no longer find the old account.
    await registerVerifiedStudent(t, s.email);
    const search = await t.app.inject({
      method: 'GET',
      url: `/api/v1/admin/students?q=${s.userId}`,
      headers: admin,
    });
    expect(body<{ items: unknown[] }>(search).data.items).toHaveLength(0);
    const regrant = await t.app.inject({
      method: 'POST',
      url: `/api/v1/admin/students/${s.userId}/entitlements`,
      headers: admin,
      payload: { scopeType: 'subject', subjectId: ents[0]!.subjectId, permanentAccess: true },
    });
    expect(regrant.statusCode).toBe(404);
  });

  it('signs the web cookie out', async () => {
    const email = await registerVerifiedStudent(t);
    const login = await t.app.inject({
      method: 'POST',
      url: '/api/v1/auth/web/login',
      headers: csrfHeaders(WEB_ORIGIN),
      payload: { email, password: PASSWORD },
    });
    const cookie = cookieHeader(login);
    const res = await t.app.inject({
      method: 'POST',
      url: '/api/v1/me/delete',
      headers: { cookie, ...csrfHeaders(WEB_ORIGIN) },
      payload: { password: PASSWORD },
    });
    expect(res.statusCode).toBe(200);
    const cleared = res.cookies.find((c) => c.name.endsWith('session_token'));
    expect(cleared?.value ?? '').toBe('');
    const me = await t.app.inject({ method: 'GET', url: '/api/v1/me', headers: { cookie } });
    expect(me.statusCode).not.toBe(200);
  });

  it('can be done by an admin on request, audited, once', async () => {
    const s = await tokensFor(t);
    const [u] = await t.c.db.select().from(users).where(eq(users.email, s.email));
    const del = (id: string) =>
      t.app.inject({ method: 'POST', url: `/api/v1/admin/students/${id}/delete`, headers: admin });
    expect((await del(u!.id)).statusCode).toBe(200);
    expect((await del(u!.id)).statusCode).toBe(404);
    const [adminRow] = await t.c.db.select().from(users).where(eq(users.role, 'admin')).limit(1);
    expect((await del(adminRow!.id)).statusCode).toBe(404);
    const [log] = await t.c.db
      .select()
      .from(auditLogs)
      .where(and(eq(auditLogs.resourceId, u!.id), eq(auditLogs.action, 'account.deleted_by_admin')));
    expect(log!.actorAdminId).not.toBeNull();
    // Students cannot use the admin route.
    const other = await tokensFor(t);
    const forbidden = await t.app.inject({
      method: 'POST',
      url: `/api/v1/admin/students/${u!.id}/delete`,
      headers: bearer(other.accessToken),
    });
    expect(forbidden.statusCode).toBe(403);
  });
});

describe('store review account', () => {
  it('is a verified student with permanent access to the listed subjects, granted by an admin', async () => {
    const { createReviewAccount } = await import('../src/services/review-account.js');
    const [adminRow] = await t.c.db.select().from(users).where(eq(users.role, 'admin')).limit(1);
    const code = `rev-${randomUUID().slice(0, 8)}`;
    await t.app.inject({
      method: 'POST',
      url: '/api/v1/admin/subjects',
      headers: admin,
      payload: { educationLevelId: await levelId(t), code, nameAr: 'مادة المراجعة' },
    });
    const email = `review-${randomUUID().slice(0, 6)}@example.com`;
    const input = {
      email,
      name: 'حساب المراجعة',
      password: 'review-password-1',
      levelCode: 'grade-12',
      subjectCodes: [code],
      grantedByAdminEmail: adminRow!.email,
    };
    const created = await createReviewAccount(t.c, input);
    expect(created.subjects).toEqual([code]);
    expect((await mobileLogin(t, email, 'review-password-1')).statusCode).toBe(200);
    const ents = await t.c.db.select().from(entitlements).where(eq(entitlements.userId, created.userId));
    expect(ents).toMatchObject([{ isPermanent: true, status: 'active', grantedByAdminId: adminRow!.id }]);
    await expect(createReviewAccount(t.c, input)).rejects.toThrow('already exists');
    await expect(
      createReviewAccount(t.c, { ...input, email: `x${email}`, subjectCodes: ['nope'] }),
    ).rejects.toThrow('unknown subjects');
  });
});
