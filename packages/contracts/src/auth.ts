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
  // College students may optionally pick their place in the hierarchy (spec §11.1).
  universityId: z.uuid().optional(),
  facultyId: z.uuid().optional(),
  academicYearId: z.uuid().optional(),
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
  universityId: z.string().nullable(),
  facultyId: z.string().nullable(),
  academicYearId: z.string().nullable(),
});

/**
 * Profile changes (spec §8.9): the level only sets defaults, and students may change it at any time.
 * `null` clears an optional college layer.
 */
export const updateProfileBodySchema = z.object({
  fullName: z.string().trim().min(2).max(100).optional(),
  educationLevelId: z.uuid().optional(),
  universityId: z.uuid().nullable().optional(),
  facultyId: z.uuid().nullable().optional(),
  academicYearId: z.uuid().nullable().optional(),
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

export const webLoginBodySchema = z.object({ email: emailSchema, password: z.string().min(1).max(128) });

export const sessionListSchema = z.array(sessionSummarySchema);

// Component names for the generated OpenAPI document (and the Dart/TS clients built from it).
z.globalRegistry.add(platformSchema, { id: 'SessionPlatform' });
z.globalRegistry.add(registerBodySchema, { id: 'RegisterRequest' });
z.globalRegistry.add(verifyEmailBodySchema, { id: 'VerifyEmailRequest' });
z.globalRegistry.add(resendOtpBodySchema, { id: 'ResendOtpRequest' });
z.globalRegistry.add(forgotPasswordBodySchema, { id: 'ForgotPasswordRequest' });
z.globalRegistry.add(resetPasswordBodySchema, { id: 'ResetPasswordRequest' });
z.globalRegistry.add(mobileLoginBodySchema, { id: 'MobileLoginRequest' });
z.globalRegistry.add(mobileRefreshBodySchema, { id: 'MobileRefreshRequest' });
z.globalRegistry.add(mobileLogoutBodySchema, { id: 'MobileLogoutRequest' });
z.globalRegistry.add(webLoginBodySchema, { id: 'WebLoginRequest' });
z.globalRegistry.add(tokenPairSchema, { id: 'TokenPair' });
z.globalRegistry.add(meSchema, { id: 'Me' });
z.globalRegistry.add(updateProfileBodySchema, { id: 'UpdateProfileRequest' });
z.globalRegistry.add(sessionSummarySchema, { id: 'SessionSummary' });
z.globalRegistry.add(sessionListSchema, { id: 'SessionList' });
