import { eq } from 'drizzle-orm';
import sharp from 'sharp';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { mediaFiles } from '@plengo/db';
import { STUDENT_IMAGE_QUOTA } from '../src/services/upload-service.js';
import { objectKey } from '../src/storage/keys.js';
import { body, createTestApp, tokensFor, type TestContext } from './helpers.js';

let t: TestContext;
beforeAll(async () => {
  t = await createTestApp();
});
afterAll(async () => {
  await t.close();
});

async function png(width: number, height: number): Promise<Buffer> {
  return sharp({ create: { width, height, channels: 3, background: { r: 200, g: 30, b: 90 } } })
    .png()
    .toBuffer();
}

function keyFromUrl(url: string): string {
  // memory://private/<key>?...
  return new URL(url).pathname.replace(/^\//, '');
}

async function studentUpload(accessToken: string, bytes: Buffer, contentType = 'image/png') {
  const res = await t.app.inject({
    method: 'POST',
    url: '/api/v1/uploads',
    headers: { authorization: `Bearer ${accessToken}` },
    payload: { kind: 'user-card', contentType, size: bytes.length },
  });
  return res;
}

describe('student uploads', () => {
  it('presigns, completes, and processes into WebP full + thumb variants', async () => {
    const { accessToken } = await tokensFor(t);
    const bytes = await png(2400, 1200);
    const created = await studentUpload(accessToken, bytes);
    expect(created.statusCode).toBe(200);
    const up = body<{ id: string; uploadUrl: string; method: string; headers: Record<string, string> }>(
      created,
    ).data;
    expect(up.method).toBe('PUT');
    expect(up.headers['Content-Type']).toBe('image/png');

    // Client PUTs straight to storage.
    const key = keyFromUrl(up.uploadUrl);
    expect(key).toMatch(/^test\/original\/\d{4}\/\d{2}\/[0-9a-f-]{36}\/original$/);
    await t.storage.put('private', key, bytes, 'image/png');

    const done = await t.app.inject({
      method: 'POST',
      url: `/api/v1/uploads/${up.id}/complete`,
      headers: { authorization: `Bearer ${accessToken}` },
    });
    expect(body(done).data).toMatchObject({ id: up.id, status: 'pending' });

    await t.queue.drain(t.c.jobHandlers);

    const [row] = await t.c.db.select().from(mediaFiles).where(eq(mediaFiles.id, up.id));
    expect(row!.status).toBe('ready');
    expect(row!.bucket).toBe('private');
    expect(row!.width).toBe(2400);
    expect(row!.variants.full!.width).toBe(1080);
    expect(row!.variants.thumb!.width).toBe(360);
    expect(row!.variants.full!.key).toBe(objectKey('test', 'user-card', up.id, 'full', row!.createdAt));
    const full = await t.storage.get('private', row!.variants.full!.key);
    expect((await sharp(full!).metadata()).format).toBe('webp');

    const status = await t.app.inject({
      method: 'GET',
      url: `/api/v1/uploads/${up.id}`,
      headers: { authorization: `Bearer ${accessToken}` },
    });
    expect(body(status).data).toMatchObject({ status: 'ready', width: 2400, height: 1200 });
  });

  it('marks non-images as failed even when the declared type is an image', async () => {
    const { accessToken } = await tokensFor(t);
    const bytes = Buffer.from('this is definitely not a png file at all');
    const up = body<{ id: string; uploadUrl: string }>(await studentUpload(accessToken, bytes)).data;
    await t.storage.put('private', keyFromUrl(up.uploadUrl), bytes, 'image/png');
    await t.app.inject({
      method: 'POST',
      url: `/api/v1/uploads/${up.id}/complete`,
      headers: { authorization: `Bearer ${accessToken}` },
    });
    await t.queue.drain(t.c.jobHandlers);
    const [row] = await t.c.db.select().from(mediaFiles).where(eq(mediaFiles.id, up.id));
    expect(row).toMatchObject({ status: 'failed', failureReason: 'invalid_image' });
  });

  it('refuses completion when nothing (or the wrong size) was uploaded', async () => {
    const { accessToken } = await tokensFor(t);
    const bytes = await png(10, 10);
    const up = body<{ id: string; uploadUrl: string }>(await studentUpload(accessToken, bytes)).data;
    const complete = () =>
      t.app.inject({
        method: 'POST',
        url: `/api/v1/uploads/${up.id}/complete`,
        headers: { authorization: `Bearer ${accessToken}` },
      });
    expect(body(await complete()).error?.code).toBe('VALIDATION_ERROR');
    await t.storage.put('private', keyFromUrl(up.uploadUrl), Buffer.concat([bytes, bytes]), 'image/png');
    expect(body(await complete()).error?.code).toBe('VALIDATION_ERROR');
  });

  it('enforces student kind, type and 2 MB size limits', async () => {
    const { accessToken } = await tokensFor(t);
    const post = (payload: object) =>
      t.app.inject({
        method: 'POST',
        url: '/api/v1/uploads',
        headers: { authorization: `Bearer ${accessToken}` },
        payload,
      });
    expect(body(await post({ kind: 'flashcard', contentType: 'image/png', size: 100 })).error?.code).toBe(
      'NOT_AUTHORIZED',
    );
    expect(body(await post({ kind: 'user-card', contentType: 'image/gif', size: 100 })).error?.code).toBe(
      'VALIDATION_ERROR',
    );
    expect(
      body(await post({ kind: 'user-card', contentType: 'image/png', size: 2 * 1024 * 1024 + 1 })).error
        ?.code,
    ).toBe('VALIDATION_ERROR');
  });

  it('returns QUOTA_EXCEEDED past 300 student images', async () => {
    const { accessToken } = await tokensFor(t);
    const probe = body<{ id: string }>(await studentUpload(accessToken, await png(4, 4))).data;
    const [row] = await t.c.db.select().from(mediaFiles).where(eq(mediaFiles.id, probe.id));
    const filler = Array.from({ length: STUDENT_IMAGE_QUOTA - 1 }, (_, i) => ({
      bucket: 'private' as const,
      storageKey: `quota-test/${probe.id}/${i}`,
      kind: 'user-card' as const,
      ownerUserId: row!.ownerUserId,
      mimeType: 'image/png',
      originalSize: 1,
      status: 'ready' as const,
    }));
    await t.c.db.insert(mediaFiles).values(filler);
    const res = await studentUpload(accessToken, await png(4, 4));
    expect(res.statusCode).toBe(403);
    expect(body(res).error?.code).toBe('QUOTA_EXCEEDED');
  });

  it("cannot see or complete another student's upload", async () => {
    const a = await tokensFor(t);
    const b = await tokensFor(t);
    const up = body<{ id: string }>(await studentUpload(a.accessToken, await png(4, 4))).data;
    const res = await t.app.inject({
      method: 'POST',
      url: `/api/v1/uploads/${up.id}/complete`,
      headers: { authorization: `Bearer ${b.accessToken}` },
    });
    expect(res.statusCode).toBe(404);
  });

  it('requires authentication', async () => {
    const res = await t.app.inject({
      method: 'POST',
      url: '/api/v1/uploads',
      payload: { kind: 'user-card', contentType: 'image/png', size: 10 },
    });
    expect(res.statusCode).toBe(401);
    expect(body(res).error?.code).toBe('UNAUTHENTICATED');
  });
});

describe('orphan cleanup', () => {
  it('deletes pending uploads older than 24 hours and their originals', async () => {
    const { accessToken } = await tokensFor(t);
    const bytes = await png(4, 4);
    const up = body<{ id: string; uploadUrl: string }>(await studentUpload(accessToken, bytes)).data;
    await t.storage.put('private', keyFromUrl(up.uploadUrl), bytes, 'image/png');
    const fresh = body<{ id: string }>(await studentUpload(accessToken, bytes)).data;

    await t.c.db
      .update(mediaFiles)
      .set({ createdAt: new Date(Date.now() - 25 * 3600_000) })
      .where(eq(mediaFiles.id, up.id));
    await t.c.media.cleanupOrphans();

    expect(await t.c.db.select().from(mediaFiles).where(eq(mediaFiles.id, up.id))).toHaveLength(0);
    expect(await t.storage.exists('private', keyFromUrl(up.uploadUrl))).toBe(false);
    expect(await t.c.db.select().from(mediaFiles).where(eq(mediaFiles.id, fresh.id))).toHaveLength(1);
  });
});
