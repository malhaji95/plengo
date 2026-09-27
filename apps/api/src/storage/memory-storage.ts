import { mkdirSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { hmacHex, safeEqual } from '../lib/crypto.js';
import type { BucketName, ObjectHead, ObjectStorage, PresignedUpload } from './storage.js';

interface StoredObject {
  bytes: Buffer;
  contentType: string;
}

/**
 * In-process storage for tests and local development without R2. With `baseUrl` + `secret`, the
 * presigned and public URLs point at the API's dev-only `/api/v1/dev-storage` routes (ADR-012), so
 * browsers can upload and display images end to end. With `dir`, objects are also written to disk so
 * they survive restarts and are shared with scripts such as the seed. Never used in production.
 */
export class MemoryStorage implements ObjectStorage {
  readonly objects = new Map<string, StoredObject>();

  constructor(private readonly opts: { baseUrl?: string; secret?: string; dir?: string } = {}) {}

  private file(bucket: BucketName, key: string) {
    if (!this.opts.dir || key.includes('..')) return null;
    return join(this.opts.dir, bucket, key);
  }

  /** Map first, then disk (another process may have written it). */
  private load(bucket: BucketName, key: string): StoredObject | null {
    const cached = this.objects.get(this.id(bucket, key));
    if (cached) return cached;
    const path = this.file(bucket, key);
    if (!path) return null;
    try {
      const obj = { bytes: readFileSync(path), contentType: readFileSync(`${path}.type`, 'utf8') };
      this.objects.set(this.id(bucket, key), obj);
      return obj;
    } catch {
      return null;
    }
  }

  private id(bucket: BucketName, key: string) {
    return `${bucket}/${key}`;
  }

  private sign(bucket: BucketName, key: string, method: 'PUT' | 'GET', len: number, exp: number): string {
    return hmacHex(this.opts.secret ?? 'memory-storage', `${method} ${bucket}/${key} ${len} ${exp}`);
  }

  private url(bucket: BucketName, key: string, query: Record<string, string | number>): string {
    const qs = new URLSearchParams(
      Object.entries(query).map(([k, v]): [string, string] => [k, String(v)]),
    ).toString();
    return this.opts.baseUrl
      ? `${this.opts.baseUrl.replace(/\/$/, '')}/api/v1/dev-storage/${bucket}/${key}${qs ? `?${qs}` : ''}`
      : `memory://${bucket}/${key}${qs ? `?${qs}` : ''}`;
  }

  /** Validates a dev-storage request signature produced by this instance. */
  verify(
    bucket: BucketName,
    key: string,
    method: 'PUT' | 'GET',
    len: number,
    exp: number,
    sig: string,
  ): boolean {
    return exp > Date.now() && safeEqual(sig, this.sign(bucket, key, method, len, exp));
  }

  async createPresignedPut(
    bucket: BucketName,
    key: string,
    contentType: string,
    contentLength: number,
    ttlSeconds: number,
  ): Promise<PresignedUpload> {
    const exp = Date.now() + ttlSeconds * 1000;
    return {
      url: this.url(bucket, key, {
        len: contentLength,
        exp,
        sig: this.sign(bucket, key, 'PUT', contentLength, exp),
      }),
      headers: { 'Content-Type': contentType },
      expiresAt: new Date(exp),
    };
  }

  async getSignedGetUrl(bucket: BucketName, key: string, ttlSeconds: number): Promise<string> {
    const exp = Date.now() + ttlSeconds * 1000;
    return this.url(bucket, key, { exp, sig: this.sign(bucket, key, 'GET', 0, exp) });
  }

  getPublicUrl(key: string): string {
    return this.url('public', key, {});
  }

  async put(bucket: BucketName, key: string, bytes: Buffer, contentType: string): Promise<void> {
    this.objects.set(this.id(bucket, key), { bytes, contentType });
    const path = this.file(bucket, key);
    if (path) {
      mkdirSync(dirname(path), { recursive: true });
      writeFileSync(path, bytes);
      writeFileSync(`${path}.type`, contentType);
    }
  }

  async get(bucket: BucketName, key: string): Promise<Buffer | null> {
    return this.load(bucket, key)?.bytes ?? null;
  }

  async getWithType(bucket: BucketName, key: string): Promise<StoredObject | null> {
    return this.load(bucket, key);
  }

  async head(bucket: BucketName, key: string): Promise<ObjectHead | null> {
    const obj = this.load(bucket, key);
    return obj ? { size: obj.bytes.length, contentType: obj.contentType } : null;
  }

  async exists(bucket: BucketName, key: string): Promise<boolean> {
    return this.load(bucket, key) !== null;
  }

  async delete(bucket: BucketName, key: string): Promise<void> {
    this.objects.delete(this.id(bucket, key));
    const path = this.file(bucket, key);
    if (path) {
      rmSync(path, { force: true });
      rmSync(`${path}.type`, { force: true });
    }
  }

  async copy(bucket: BucketName, srcKey: string, dstKey: string): Promise<void> {
    const obj = this.load(bucket, srcKey);
    if (obj) await this.put(bucket, dstKey, obj.bytes, obj.contentType);
  }
}
