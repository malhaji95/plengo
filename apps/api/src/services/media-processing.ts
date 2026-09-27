import { and, eq, lt } from 'drizzle-orm';
import sharp, { type Metadata } from 'sharp';
import { mediaFiles, type Db, type MediaVariants } from '@plengo/db';
import type { FastifyBaseLogger } from 'fastify';
import type { ObjectStorage } from '../storage/storage.js';
import { objectKey, type KeyKind } from '../storage/keys.js';

type ImageKind = 'flashcard' | 'banner' | 'teacher' | 'cover' | 'user-card';

/** Variant sizes and WebP quality per kind (spec §12.4). */
export const VARIANT_SPECS: Record<ImageKind, { full: number; thumb: number; quality: number }> = {
  flashcard: { full: 1080, thumb: 360, quality: 75 },
  banner: { full: 1600, thumb: 800, quality: 75 },
  teacher: { full: 800, thumb: 200, quality: 75 },
  cover: { full: 800, thumb: 200, quality: 75 },
  'user-card': { full: 1080, thumb: 360, quality: 75 },
};

const ACCEPTED_FORMATS = new Set(['png', 'jpeg', 'webp']);
const MAX_INPUT_PIXELS = 40_000_000;
export const ORPHAN_TTL_MS = 24 * 3600 * 1000;

export function createMediaProcessor(deps: {
  db: Db;
  storage: ObjectStorage;
  appEnv: string;
  log: FastifyBaseLogger;
}) {
  const { db, storage, appEnv, log } = deps;

  async function fail(id: string, reason: string) {
    await db.update(mediaFiles).set({ status: 'failed', failureReason: reason }).where(eq(mediaFiles.id, id));
  }

  return {
    /** Verify the uploaded original by content, generate WebP variants, mark the row ready. */
    async process({ mediaId }: { mediaId: string }): Promise<void> {
      const [row] = await db.select().from(mediaFiles).where(eq(mediaFiles.id, mediaId)).limit(1);
      if (!row || row.status !== 'pending') return;
      const spec = VARIANT_SPECS[row.kind as ImageKind];
      if (!spec) return fail(mediaId, 'unsupported_kind');

      const original = await storage.get('private', row.storageKey);
      if (!original) return fail(mediaId, 'missing_object');
      if (original.length > row.originalSize) return fail(mediaId, 'size_mismatch');

      let meta: Metadata;
      try {
        // sharp detects the format from magic bytes, not from the declared content type.
        meta = await sharp(original, { limitInputPixels: MAX_INPUT_PIXELS }).metadata();
      } catch {
        return fail(mediaId, 'invalid_image');
      }
      if (!meta.format || !ACCEPTED_FORMATS.has(meta.format) || !meta.width || !meta.height) {
        return fail(mediaId, 'invalid_image');
      }

      const variants: MediaVariants = {};
      let optimizedSize = 0;
      for (const variant of ['full', 'thumb'] as const) {
        const { data, info } = await sharp(original, { limitInputPixels: MAX_INPUT_PIXELS })
          .rotate()
          .resize({ width: spec[variant], withoutEnlargement: true })
          .webp({ quality: spec.quality })
          .toBuffer({ resolveWithObject: true });
        const key = objectKey(appEnv, row.kind as KeyKind, row.id, variant, row.createdAt);
        await storage.put(row.bucket, key, data, 'image/webp');
        variants[variant] = { key, width: info.width, height: info.height, size: data.length };
        if (variant === 'full') optimizedSize = data.length;
      }

      await db
        .update(mediaFiles)
        .set({
          status: 'ready',
          width: meta.width,
          height: meta.height,
          optimizedSize,
          variants,
          failureReason: null,
        })
        .where(and(eq(mediaFiles.id, mediaId), eq(mediaFiles.status, 'pending')));
      log.info({ mediaId, optimizedSize }, 'media processed');
    },

    /** Delete pending uploads older than 24 h together with any uploaded original (spec §12.3). */
    async cleanupOrphans(now = new Date()): Promise<number> {
      const cutoff = new Date(now.getTime() - ORPHAN_TTL_MS);
      const stale = await db
        .select({ id: mediaFiles.id, key: mediaFiles.storageKey })
        .from(mediaFiles)
        .where(and(eq(mediaFiles.status, 'pending'), lt(mediaFiles.createdAt, cutoff)));
      for (const row of stale) {
        await storage.delete('private', row.key);
        await db.delete(mediaFiles).where(eq(mediaFiles.id, row.id));
      }
      return stale.length;
    },
  };
}

export type MediaProcessor = ReturnType<typeof createMediaProcessor>;
