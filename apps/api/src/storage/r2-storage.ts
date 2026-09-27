import {
  CopyObjectCommand,
  DeleteObjectCommand,
  GetObjectCommand,
  HeadObjectCommand,
  NotFound,
  PutObjectCommand,
  S3Client,
  S3ServiceException,
} from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import type { BucketName, ObjectHead, ObjectStorage, PresignedUpload } from './storage.js';

export interface R2Config {
  endpoint: string;
  accessKeyId: string;
  secretAccessKey: string;
  privateBucket: string;
  publicBucket: string;
  publicBaseUrl: string;
}

function isNotFound(err: unknown): boolean {
  return (
    err instanceof NotFound ||
    (err instanceof S3ServiceException && (err.$metadata.httpStatusCode === 404 || err.name === 'NoSuchKey'))
  );
}

/** Cloudflare R2 via the S3 API. Also works against MinIO for local development. */
export class R2Storage implements ObjectStorage {
  private readonly client: S3Client;

  constructor(private readonly config: R2Config) {
    this.client = new S3Client({
      region: 'auto',
      endpoint: config.endpoint,
      forcePathStyle: true,
      credentials: { accessKeyId: config.accessKeyId, secretAccessKey: config.secretAccessKey },
    });
  }

  private bucket(name: BucketName): string {
    return name === 'public' ? this.config.publicBucket : this.config.privateBucket;
  }

  async createPresignedPut(
    bucket: BucketName,
    key: string,
    contentType: string,
    contentLength: number,
    ttlSeconds: number,
  ): Promise<PresignedUpload> {
    // Content-Type and Content-Length are signed, so the client must upload exactly what was declared.
    const command = new PutObjectCommand({
      Bucket: this.bucket(bucket),
      Key: key,
      ContentType: contentType,
      ContentLength: contentLength,
    });
    const url = await getSignedUrl(this.client, command, {
      expiresIn: ttlSeconds,
      signableHeaders: new Set(['content-type', 'content-length']),
    });
    return {
      url,
      headers: { 'Content-Type': contentType },
      expiresAt: new Date(Date.now() + ttlSeconds * 1000),
    };
  }

  async getSignedGetUrl(bucket: BucketName, key: string, ttlSeconds: number): Promise<string> {
    return getSignedUrl(this.client, new GetObjectCommand({ Bucket: this.bucket(bucket), Key: key }), {
      expiresIn: ttlSeconds,
    });
  }

  getPublicUrl(key: string): string {
    return `${this.config.publicBaseUrl.replace(/\/$/, '')}/${key}`;
  }

  async put(bucket: BucketName, key: string, bytes: Buffer, contentType: string): Promise<void> {
    await this.client.send(
      new PutObjectCommand({
        Bucket: this.bucket(bucket),
        Key: key,
        Body: bytes,
        ContentType: contentType,
        CacheControl: bucket === 'public' ? 'public, max-age=31536000, immutable' : undefined,
      }),
    );
  }

  async get(bucket: BucketName, key: string): Promise<Buffer | null> {
    try {
      const res = await this.client.send(new GetObjectCommand({ Bucket: this.bucket(bucket), Key: key }));
      if (!res.Body) return null;
      return Buffer.from(await res.Body.transformToByteArray());
    } catch (err) {
      if (isNotFound(err)) return null;
      throw err;
    }
  }

  async head(bucket: BucketName, key: string): Promise<ObjectHead | null> {
    try {
      const res = await this.client.send(new HeadObjectCommand({ Bucket: this.bucket(bucket), Key: key }));
      return { size: res.ContentLength ?? 0, contentType: res.ContentType ?? null };
    } catch (err) {
      if (isNotFound(err)) return null;
      throw err;
    }
  }

  async exists(bucket: BucketName, key: string): Promise<boolean> {
    return (await this.head(bucket, key)) !== null;
  }

  async delete(bucket: BucketName, key: string): Promise<void> {
    await this.client.send(new DeleteObjectCommand({ Bucket: this.bucket(bucket), Key: key }));
  }

  async copy(bucket: BucketName, srcKey: string, dstKey: string): Promise<void> {
    const name = this.bucket(bucket);
    await this.client.send(
      new CopyObjectCommand({ Bucket: name, Key: dstKey, CopySource: `${name}/${srcKey}` }),
    );
  }
}
