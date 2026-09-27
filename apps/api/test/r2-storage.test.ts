import { randomUUID } from 'node:crypto';
import { describe, expect, it } from 'vitest';
import { R2Storage } from '../src/storage/r2-storage.js';

const offline = new R2Storage({
  endpoint: 'https://account.r2.cloudflarestorage.com',
  accessKeyId: 'AKIDEXAMPLE',
  secretAccessKey: 'secret',
  privateBucket: 'media-private',
  publicBucket: 'media-public',
  publicBaseUrl: 'https://cdn.example.com/',
});

describe('R2Storage (offline)', () => {
  it('signs content-type and content-length into presigned PUTs with a 15 min TTL', async () => {
    const res = await offline.createPresignedPut('private', 'test/original/k', 'image/png', 1234, 900);
    const url = new URL(res.url);
    expect(url.pathname).toBe('/media-private/test/original/k');
    expect(url.searchParams.get('X-Amz-Expires')).toBe('900');
    expect(url.searchParams.get('X-Amz-SignedHeaders')?.split(';')).toEqual(
      expect.arrayContaining(['content-length', 'content-type', 'host']),
    );
  });

  it('builds public CDN URLs and 1 h signed GET URLs', async () => {
    expect(offline.getPublicUrl('a/b.webp')).toBe('https://cdn.example.com/a/b.webp');
    const signed = new URL(await offline.getSignedGetUrl('private', 'a/b.webp', 3600));
    expect(signed.pathname).toBe('/media-private/a/b.webp');
    expect(signed.searchParams.get('X-Amz-Expires')).toBe('3600');
  });
});

/** Runs against a real S3-compatible endpoint when S3_TEST_ENDPOINT etc. are provided (CI or local MinIO). */
const live = process.env.S3_TEST_ENDPOINT ? describe : describe.skip;
live('R2Storage (live S3 endpoint)', () => {
  const storage = new R2Storage({
    endpoint: process.env.S3_TEST_ENDPOINT ?? '',
    accessKeyId: process.env.S3_TEST_ACCESS_KEY_ID ?? '',
    secretAccessKey: process.env.S3_TEST_SECRET_ACCESS_KEY ?? '',
    privateBucket: process.env.S3_TEST_BUCKET ?? '',
    publicBucket: process.env.S3_TEST_BUCKET ?? '',
    publicBaseUrl: 'https://cdn.example.com',
  });

  it('round-trips a presigned PUT, head, get, copy and delete', async () => {
    const key = `test/${randomUUID()}/original`;
    const bytes = Buffer.from('hello presigned world');
    const presigned = await storage.createPresignedPut('private', key, 'image/png', bytes.length, 60);
    const put = await fetch(presigned.url, { method: 'PUT', headers: presigned.headers, body: bytes });
    expect(put.ok).toBe(true);
    expect(await storage.head('private', key)).toMatchObject({ size: bytes.length });
    expect((await storage.get('private', key))?.toString()).toBe('hello presigned world');
    await storage.copy('private', key, `${key}-copy`);
    expect(await storage.exists('private', `${key}-copy`)).toBe(true);
    await storage.delete('private', key);
    await storage.delete('private', `${key}-copy`);
    expect(await storage.exists('private', key)).toBe(false);
    expect(await storage.get('private', key)).toBeNull();
  });

  it('rejects an upload whose size differs from the signed length', async () => {
    const key = `test/${randomUUID()}/original`;
    const presigned = await storage.createPresignedPut('private', key, 'image/png', 5, 60);
    const put = await fetch(presigned.url, {
      method: 'PUT',
      headers: presigned.headers,
      body: 'too many bytes',
    });
    expect(put.ok).toBe(false);
  });
});
