import { z } from 'zod';

/** Small named result payloads shared by several endpoints. */
export const verificationRequiredSchema = z
  .object({ verificationRequired: z.boolean() })
  .meta({ id: 'VerificationRequiredResult' });
export const verifiedSchema = z.object({ verified: z.boolean() }).meta({ id: 'VerifiedResult' });
export const sentSchema = z.object({ sent: z.boolean() }).meta({ id: 'SentResult' });
export const resetSchema = z.object({ reset: z.boolean() }).meta({ id: 'ResetResult' });
export const signedInSchema = z.object({ signedIn: z.boolean() }).meta({ id: 'SignedInResult' });
export const signedOutSchema = z.object({ signedOut: z.boolean() }).meta({ id: 'SignedOutResult' });
export const revokedSchema = z.object({ revoked: z.boolean() }).meta({ id: 'RevokedResult' });
export const registeredSchema = z.object({ registered: z.boolean() }).meta({ id: 'RegisteredResult' });
export const enrolledSchema = z.object({ enrolled: z.boolean() }).meta({ id: 'EnrolledResult' });
export const adminLoginResultSchema = z
  .object({ next: z.enum(['totp', 'enroll']) })
  .meta({ id: 'AdminLoginResult' });
export const totpEnrollmentSchema = z
  .object({ totpUri: z.string(), backupCodes: z.array(z.string()) })
  .meta({ id: 'TotpEnrollment' });
export const adminCredentialsSchema = z
  .object({
    email: z.string().trim().toLowerCase().pipe(z.email().max(254)),
    password: z.string().min(1).max(128),
  })
  .meta({ id: 'AdminLoginRequest' });
export const totpCodeBodySchema = z
  .object({ code: z.string().regex(/^\d{6}$/) })
  .meta({ id: 'TotpCodeRequest' });
export const backupCodeBodySchema = z
  .object({ code: z.string().min(4).max(64) })
  .meta({ id: 'BackupCodeRequest' });
export const passwordConfirmBodySchema = z
  .object({ password: z.string().min(1).max(128) })
  .meta({ id: 'PasswordConfirmRequest' });
