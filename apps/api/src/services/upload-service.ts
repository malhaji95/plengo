import { randomUUID } from 'node:crypto';
import { and, count, eq, isNull, ne } from 'drizzle-orm';
import { mediaFiles, type Db } from '@plengo/db';
import { IMAGE_CONTENT_TYPES, type MediaFileDto, type MediaKind } from '@plengo/contracts';
import { AppError } from '../lib/app-error.js';
import type { JobQueue } from '../jobs/queue.js';
import { objectKey } from '../storage/keys.js';
import type { BucketName, ObjectStorage } from '../storage/storage.js';

export const PRESIGN_TTL_SECONDS = 15 * 60;
export const MAX_ADMIN_UPLOAD_BYTES = 10 * 1024 * 1024;
export const MAX_STUDENT_UPLOAD_BYTES = 2 * 1024 * 1024;
export const STUDENT_IMAGE_QUOTA = 300;

const ADMIN_KINDS: readonly MediaKind[] = ['flashcard', 'banner', 'teacher', 'cover'];
const STUDENT_KINDS: readonly MediaKind[] = ['user-card', 'avatar'];
const PUBLIC_KINDS: readonly MediaKind[] = ['banner', 'teacher', 'cover'];

export type UploadActor = { role: 'student' | 'admin'; userId: string };

function toDto(row: typeof mediaFiles.$inferSelect): MediaFileDto {
  return {
    id: row.id,
    kind: row.kind as MediaKind,
    status: row.status,
    width: row.width,
    height: row.height,
    version: row.version,
  };
}

/** Direct-to-R2 upload flow (spec §12.3): no file bytes pass through the API. */
export function createUploadService(deps: {
  db: Db;
  storage: ObjectStorage;
  jobs: JobQueue;
  appEnv: string;
}) {
  const { db, storage, jobs, appEnv } = deps;

  async function ownedRow(actor: UploadActor, id: string) {
    const ownerCol = actor.role === 'admin' ? mediaFiles.uploadedByAdminId : mediaFiles.ownerUserId;
    const [row] = await db
      .select()
      .from(mediaFiles)
      .where(and(eq(mediaFiles.id, id), eq(ownerCol, actor.userId), isNull(mediaFiles.deletedAt)))
      .limit(1);
    if (!row) throw new AppError('NOT_FOUND');
    return row;
  }

  return {
    async create(actor: UploadActor, input: { kind: MediaKind; contentType: string; size: number }) {
      const allowedKinds = actor.role === 'admin' ? ADMIN_KINDS : STUDENT_KINDS;
      if (!allowedKinds.includes(input.kind)) throw new AppError('NOT_AUTHORIZED');
      if (!(IMAGE_CONTENT_TYPES as readonly string[]).includes(input.contentType)) {
        throw new AppError('VALIDATION_ERROR', { details: { field: 'contentType' } });
      }
      const maxBytes = actor.role === 'admin' ? MAX_ADMIN_UPLOAD_BYTES : MAX_STUDENT_UPLOAD_BYTES;
      if (input.size > maxBytes)
        throw new AppError('VALIDATION_ERROR', { details: { field: 'size', maxBytes } });

      if (actor.role === 'student') {
        const [used] = await db
          .select({ n: count() })
          .from(mediaFiles)
          .where(
            and(
              eq(mediaFiles.ownerUserId, actor.userId),
              eq(mediaFiles.kind, 'user-card'),
              isNull(mediaFiles.deletedAt),
              ne(mediaFiles.status, 'failed'),
            ),
          );
        if ((used?.n ?? 0) >= STUDENT_IMAGE_QUOTA) throw new AppError('QUOTA_EXCEEDED');
      }

      const id = randomUUID();
      const now = new Date();
      const originalKey = objectKey(appEnv, 'original', id, 'original', now);
      const bucket: BucketName = PUBLIC_KINDS.includes(input.kind) ? 'public' : 'private';
      await db.insert(mediaFiles).values({
        id,
        bucket,
        storageKey: originalKey,
        kind: input.kind,
        ownerUserId: actor.role === 'student' ? actor.userId : null,
        uploadedByAdminId: actor.role === 'admin' ? actor.userId : null,
        mimeType: input.contentType,
        originalSize: input.size,
        createdAt: now,
      });
      const presigned = await storage.createPresignedPut(
        'private',
        originalKey,
        input.contentType,
        input.size,
        PRESIGN_TTL_SECONDS,
      );
      return {
        id,
        uploadUrl: presigned.url,
        method: 'PUT' as const,
        headers: presigned.headers,
        expiresAt: presigned.expiresAt.toISOString(),
      };
    },

    async complete(actor: UploadActor, id: string): Promise<MediaFileDto> {
      const row = await ownedRow(actor, id);
      if (row.status !== 'pending') return toDto(row);
      const head = await storage.head('private', row.storageKey);
      if (!head) throw new AppError('VALIDATION_ERROR', { details: { reason: 'object_missing' } });
      if (head.size !== row.originalSize) {
        throw new AppError('VALIDATION_ERROR', { details: { reason: 'size_mismatch' } });
      }
      await jobs.send('media.process', { mediaId: row.id }, { singletonKey: row.id });
      return toDto(row);
    },

    async get(actor: UploadActor, id: string): Promise<MediaFileDto> {
      return toDto(await ownedRow(actor, id));
    },
  };
}

export type UploadService = ReturnType<typeof createUploadService>;
