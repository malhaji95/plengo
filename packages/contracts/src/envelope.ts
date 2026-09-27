import { z } from 'zod';
import { ERROR_CODES, type ErrorCode } from './errors.js';

/** Response envelope (spec §30.3). */
export const errorBodySchema = z
  .object({
    code: z.enum(ERROR_CODES as [ErrorCode, ...ErrorCode[]]),
    message: z.string(),
    details: z.unknown().optional(),
  })
  .meta({ id: 'ApiError' });

export const errorEnvelopeSchema = z
  .object({ success: z.literal(false), data: z.null(), error: errorBodySchema })
  .meta({ id: 'ErrorEnvelope' });

const envelopes = new Map<string, z.ZodType>();

/**
 * `{ success: true, data, error: null }` around a named schema. The envelope is registered as
 * `<Name>Envelope` so generated clients get readable types instead of anonymous ones.
 */
export function successEnvelope<T extends z.ZodType>(data: T) {
  const id = z.globalRegistry.get(data)?.id;
  if (!id) throw new Error('successEnvelope requires a schema registered with .meta({ id })');
  const name = `${id}Envelope`;
  let schema = envelopes.get(name);
  if (!schema) {
    schema = z.object({ success: z.literal(true), data, error: z.null() }).meta({ id: name });
    envelopes.set(name, schema);
  }
  return schema as z.ZodObject<{ success: z.ZodLiteral<true>; data: T; error: z.ZodNull }>;
}

export type ErrorEnvelope = z.infer<typeof errorEnvelopeSchema>;
export type SuccessEnvelope<T> = { success: true; data: T; error: null };
