import { z } from 'zod';

const bool = z.enum(['true', 'false', '1', '0']).transform((v) => v === 'true' || v === '1');

const envSchema = z
  .object({
    NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
    APP_ENV: z.enum(['development', 'test', 'staging', 'production']).default('development'),
    HOST: z.string().default('0.0.0.0'),
    PORT: z.coerce.number().int().default(4000),
    LOG_LEVEL: z.enum(['fatal', 'error', 'warn', 'info', 'debug', 'trace', 'silent']).default('info'),

    DATABASE_URL: z.string().min(1),
    DATABASE_POOL_MAX: z.coerce.number().int().default(10),

    BETTER_AUTH_SECRET: z.string().min(32),
    BETTER_AUTH_URL: z.url(),
    APP_WEB_ORIGIN: z.url(),
    ADMIN_ORIGIN: z.url(),

    MOBILE_ACCESS_JWT_SECRET: z.string().min(32),
    MOBILE_REFRESH_TOKEN_PEPPER: z.string().min(32),

    /** Keys coupon lookups: code_hash = HMAC-SHA256(secret, normalized code) (spec §9.2). */
    COUPON_HMAC_SECRET: z.string().min(32),
    /** 32 bytes, base64: AES-256-GCM key so admins can re-export a batch's codes. */
    COUPON_ENCRYPTION_KEY: z
      .string()
      .refine((v) => Buffer.from(v, 'base64').length === 32, 'must be 32 bytes encoded as base64'),

    STORAGE_DRIVER: z.enum(['r2', 'memory']).default('r2'),
    R2_ACCOUNT_ID: z.string().optional(),
    R2_ACCESS_KEY_ID: z.string().optional(),
    R2_SECRET_ACCESS_KEY: z.string().optional(),
    R2_PRIVATE_BUCKET: z.string().optional(),
    R2_PUBLIC_BUCKET: z.string().optional(),
    R2_PUBLIC_BASE_URL: z.string().optional(),
    /** Override for S3-compatible endpoints (MinIO in local dev). Defaults to the R2 account endpoint. */
    R2_ENDPOINT: z.string().optional(),

    EMAIL_PROVIDER: z.enum(['console', 'resend']).default('console'),
    EMAIL_PROVIDER_API_KEY: z.string().optional(),
    EMAIL_FROM: z.string().default('Plengo <no-reply@example.com>'),

    SENTRY_DSN: z.string().optional(),
    JOBS_ENABLED: bool.default(true),
    TZ_BUSINESS: z.string().default('Asia/Damascus'),
  })
  .superRefine((env, ctx) => {
    if (env.STORAGE_DRIVER === 'r2') {
      for (const key of [
        'R2_ACCESS_KEY_ID',
        'R2_SECRET_ACCESS_KEY',
        'R2_PRIVATE_BUCKET',
        'R2_PUBLIC_BUCKET',
        'R2_PUBLIC_BASE_URL',
      ] as const) {
        if (!env[key])
          ctx.addIssue({ code: 'custom', path: [key], message: 'required when STORAGE_DRIVER=r2' });
      }
      if (!env.R2_ACCOUNT_ID && !env.R2_ENDPOINT) {
        ctx.addIssue({
          code: 'custom',
          path: ['R2_ACCOUNT_ID'],
          message: 'R2_ACCOUNT_ID or R2_ENDPOINT required',
        });
      }
    }
    if (env.EMAIL_PROVIDER === 'resend' && !env.EMAIL_PROVIDER_API_KEY) {
      ctx.addIssue({ code: 'custom', path: ['EMAIL_PROVIDER_API_KEY'], message: 'required for resend' });
    }
    if (
      env.APP_ENV === 'production' &&
      (env.STORAGE_DRIVER === 'memory' || env.EMAIL_PROVIDER === 'console')
    ) {
      ctx.addIssue({ code: 'custom', message: 'production requires r2 storage and a real email provider' });
    }
  });

export type Env = z.infer<typeof envSchema>;

export function loadEnv(source: Record<string, string | undefined> = process.env): Env {
  const parsed = envSchema.safeParse(source);
  if (!parsed.success) {
    throw new Error(`Invalid environment:\n${z.prettifyError(parsed.error)}`);
  }
  return parsed.data;
}
