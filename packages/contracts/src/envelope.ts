import { z } from 'zod';
import { ERROR_CODES, type ErrorCode } from './errors.js';

/** Response envelope (spec §30.3). */
export const errorBodySchema = z.object({
  code: z.enum(ERROR_CODES as [ErrorCode, ...ErrorCode[]]),
  message: z.string(),
  details: z.unknown().optional(),
});

export const errorEnvelopeSchema = z.object({
  success: z.literal(false),
  data: z.null(),
  error: errorBodySchema,
});

export function successEnvelope<T extends z.ZodType>(data: T) {
  return z.object({ success: z.literal(true), data, error: z.null() });
}

export type ErrorEnvelope = z.infer<typeof errorEnvelopeSchema>;
export type SuccessEnvelope<T> = { success: true; data: T; error: null };
