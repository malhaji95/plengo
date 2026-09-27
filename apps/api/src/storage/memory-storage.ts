import { hmacHex, safeEqual } from '../lib/crypto.js';
import type { BucketName, ObjectHead, ObjectStorage, PresignedUpload } from './storage.js';

interface StoredObject {
  bytes: Buffer;
  contentType: string;
}

/**
 * In-process storage for tests and local development without R2. With `baseUrl` + `secret`, the
 * presigned and public URLs point at the API's dev-only `/api/v1/dev-storage` routes (ADR-012), so
 * browsers can upload and display images end to end. Never used in production (env validation).
 */
export class MemoryStorage implements ObjectStorage {
  readonly objects = new Map<string, StoredObject>();

  constructor(private readonly opts: { baseUrl?: string; secret?: string } = {}) {}

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
  }

  async get(bucket: BucketName, key: string): Promise<Buffer | null> {
    return this.objects.get(this.id(bucket, key))?.bytes ?? null;
  }

  async getWithType(bucket: BucketName, key: string): Promise<StoredObject | null> {
    return this.objects.get(this.id(bucket, key)) ?? null;
  }

  async head(bucket: BucketName, key: string): Promise<ObjectHead | null> {
    const obj = this.objects.get(this.id(bucket, key));
    return obj ? { size: obj.bytes.length, contentType: obj.contentType } : null;
  }

  async exists(bucket: BucketName, key: string): Promise<boolean> {
    return this.objects.has(this.id(bucket, key));
  }

  async delete(bucket: BucketName, key: string): Promise<void> {
    this.objects.delete(this.id(bucket, key));
  }

  async copy(bucket: BucketName, srcKey: string, dstKey: string): Promise<void> {
    const obj = this.objects.get(this.id(bucket, srcKey));
    if (obj) this.objects.set(this.id(bucket, dstKey), obj);
  }
}
