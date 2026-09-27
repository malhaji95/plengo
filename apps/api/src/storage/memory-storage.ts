import type { BucketName, ObjectHead, ObjectStorage, PresignedUpload } from './storage.js';

interface StoredObject {
  bytes: Buffer;
  contentType: string;
}

/** In-process storage for tests and offline development. Presigned URLs are not fetchable. */
export class MemoryStorage implements ObjectStorage {
  readonly objects = new Map<string, StoredObject>();

  private id(bucket: BucketName, key: string) {
    return `${bucket}/${key}`;
  }

  async createPresignedPut(
    bucket: BucketName,
    key: string,
    contentType: string,
    contentLength: number,
    ttlSeconds: number,
  ): Promise<PresignedUpload> {
    const expiresAt = new Date(Date.now() + ttlSeconds * 1000);
    return {
      url: `memory://${bucket}/${key}?len=${contentLength}&exp=${expiresAt.getTime()}`,
      headers: { 'Content-Type': contentType },
      expiresAt,
    };
  }

  async getSignedGetUrl(bucket: BucketName, key: string, ttlSeconds: number): Promise<string> {
    return `memory://${bucket}/${key}?exp=${Date.now() + ttlSeconds * 1000}`;
  }

  getPublicUrl(key: string): string {
    return `memory://public/${key}`;
  }

  async put(bucket: BucketName, key: string, bytes: Buffer, contentType: string): Promise<void> {
    this.objects.set(this.id(bucket, key), { bytes, contentType });
  }

  async get(bucket: BucketName, key: string): Promise<Buffer | null> {
    return this.objects.get(this.id(bucket, key))?.bytes ?? null;
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
