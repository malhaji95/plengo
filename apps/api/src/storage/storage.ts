/** Logical buckets (spec §12.1). The physical bucket names come from env. */
export type BucketName = 'public' | 'private';

export interface PresignedUpload {
  url: string;
  headers: Record<string, string>;
  expiresAt: Date;
}

export interface ObjectHead {
  size: number;
  contentType: string | null;
}

/** Provider-neutral storage interface (spec §12.6). R2 is one implementation. */
export interface ObjectStorage {
  createPresignedPut(
    bucket: BucketName,
    key: string,
    contentType: string,
    contentLength: number,
    ttlSeconds: number,
  ): Promise<PresignedUpload>;
  getSignedGetUrl(bucket: BucketName, key: string, ttlSeconds: number): Promise<string>;
  getPublicUrl(key: string): string;
  put(bucket: BucketName, key: string, bytes: Buffer, contentType: string): Promise<void>;
  get(bucket: BucketName, key: string): Promise<Buffer | null>;
  head(bucket: BucketName, key: string): Promise<ObjectHead | null>;
  exists(bucket: BucketName, key: string): Promise<boolean>;
  delete(bucket: BucketName, key: string): Promise<void>;
  copy(bucket: BucketName, srcKey: string, dstKey: string): Promise<void>;
}
