import { z } from 'zod';

export const emailSchema = z.string().trim().toLowerCase().pipe(z.email().max(254));

export const passwordSchema = z.string().min(8).max(128);

export const otpSchema = z.string().regex(/^\d{6}$/);

export const platformSchema = z.enum(['android', 'ios', 'web', 'admin']);
export type Platform = z.infer<typeof platformSchema>;

export const registerBodySchema = z.object({
  fullName: z.string().trim().min(2).max(100),
  email: emailSchema,
  password: passwordSchema,
  educationLevelId: z.uuid().optional(),
});

export const verifyEmailBodySchema = z.object({ email: emailSchema, otp: otpSchema });

export const resendOtpBodySchema = z.object({ email: emailSchema });

export const forgotPasswordBodySchema = z.object({ email: emailSchema });

export const resetPasswordBodySchema = z.object({
  email: emailSchema,
  otp: otpSchema,
  newPassword: passwordSchema,
});

export const mobileLoginBodySchema = z.object({
  email: emailSchema,
  password: z.string().min(1).max(128),
  platform: z.enum(['android', 'ios']),
  appVersion: z.string().max(32).optional(),
});

export const mobileRefreshBodySchema = z.object({ refreshToken: z.string().min(32).max(256) });

export const mobileLogoutBodySchema = z.object({ refreshToken: z.string().min(32).max(256) });

export const tokenPairSchema = z.object({
  accessToken: z.string(),
  accessTokenExpiresAt: z.iso.datetime(),
  refreshToken: z.string(),
  refreshTokenExpiresAt: z.iso.datetime(),
});
export type TokenPair = z.infer<typeof tokenPairSchema>;

export const meSchema = z.object({
  id: z.string(),
  email: z.string(),
  emailVerified: z.boolean(),
  role: z.enum(['student', 'admin']),
  fullName: z.string(),
  educationLevelId: z.string().nullable(),
});
export type Me = z.infer<typeof meSchema>;

export const sessionSummarySchema = z.object({
  id: z.string(),
  platform: platformSchema,
  appVersion: z.string().nullable(),
  userAgent: z.string().nullable(),
  createdAt: z.iso.datetime(),
  lastSeenAt: z.iso.datetime(),
  current: z.boolean(),
});
export type SessionSummary = z.infer<typeof sessionSummarySchema>;
