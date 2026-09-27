import { z } from 'zod';

/** Image kinds accepted by the upload flow (spec §12.3). CSV/XLSX `import` uploads arrive with Phase 11. */
export const MEDIA_KINDS = ['flashcard', 'banner', 'teacher', 'cover', 'user-card'] as const;
export const mediaKindSchema = z.enum(MEDIA_KINDS);
export type MediaKind = z.infer<typeof mediaKindSchema>;

export const IMAGE_CONTENT_TYPES = ['image/png', 'image/jpeg', 'image/webp'] as const;

export const createUploadBodySchema = z.object({
  kind: mediaKindSchema,
  contentType: z.string().max(100),
  size: z.number().int().positive(),
});

export const createUploadResponseSchema = z.object({
  id: z.uuid(),
  uploadUrl: z.string(),
  method: z.literal('PUT'),
  headers: z.record(z.string(), z.string()),
  expiresAt: z.iso.datetime(),
});

export const mediaFileSchema = z.object({
  id: z.uuid(),
  kind: mediaKindSchema,
  status: z.enum(['pending', 'ready', 'failed']),
  width: z.number().int().nullable(),
  height: z.number().int().nullable(),
  version: z.number().int(),
});
export type MediaFileDto = z.infer<typeof mediaFileSchema>;

z.globalRegistry.add(mediaKindSchema, { id: 'MediaKind' });
z.globalRegistry.add(createUploadBodySchema, { id: 'CreateUploadRequest' });
z.globalRegistry.add(createUploadResponseSchema, { id: 'CreateUploadResult' });
z.globalRegistry.add(mediaFileSchema, { id: 'MediaFile' });
