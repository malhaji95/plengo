import { betterAuth } from 'better-auth';
import { drizzleAdapter } from 'better-auth/adapters/drizzle';
import { emailOTP } from 'better-auth/plugins/email-otp';
import { twoFactor } from 'better-auth/plugins/two-factor';
import { accounts, adminTwoFactor, sessions, users, verificationCodes, type Db } from '@plengo/db';
import type { Env } from '../env.js';
import { otpEmail, type EmailSender } from './email.js';

export const OTP_TTL_SECONDS = 600;
const WEB_SESSION_TTL_SECONDS = 30 * 24 * 3600;

/**
 * Better Auth is the identity/credential source (spec §2.3): email+password hashing, email OTP for
 * verification and reset, cookie sessions for student web and admin, TOTP 2FA for admins.
 * Its HTTP handler is not mounted; routes call `auth.api.*` so every response uses the §30.3
 * envelope and error codes (ADR-003). Mobile token pairs are issued by MobileTokenService.
 */
export function createAuth(deps: { env: Env; db: Db; email: EmailSender }) {
  const { env, db, email } = deps;
  const secureCookies = env.APP_ENV === 'staging' || env.APP_ENV === 'production';

  return betterAuth({
    appName: 'Plengo',
    baseURL: env.BETTER_AUTH_URL,
    basePath: '/api/v1/auth/core',
    secret: env.BETTER_AUTH_SECRET,
    trustedOrigins: [env.APP_WEB_ORIGIN, env.ADMIN_ORIGIN],
    database: drizzleAdapter(db, {
      provider: 'pg',
      schema: {
        user: users,
        session: sessions,
        account: accounts,
        verification: verificationCodes,
        twoFactor: adminTwoFactor,
      },
    }),
    emailAndPassword: {
      enabled: true,
      requireEmailVerification: true,
      autoSignIn: false,
      minPasswordLength: 8,
      maxPasswordLength: 128,
      revokeSessionsOnPasswordReset: true,
    },
    session: { expiresIn: WEB_SESSION_TTL_SECONDS, updateAge: 24 * 3600 },
    rateLimit: { enabled: false }, // the API applies §31 limits itself
    plugins: [
      emailOTP({
        otpLength: 6,
        expiresIn: OTP_TTL_SECONDS,
        allowedAttempts: 5,
        storeOTP: 'hashed',
        sendVerificationOnSignUp: true,
        overrideDefaultEmailVerification: true,
        async sendVerificationOTP({ email: to, otp, type }) {
          await email.send(otpEmail(to, otp, type));
        },
      }),
      twoFactor({ issuer: 'Plengo Admin', skipVerificationOnEnable: false }),
    ],
    advanced: {
      database: { generateId: 'uuid' },
      // Sessions keep only a salted IP hash (written by the API, spec §31), never the raw address.
      ipAddress: { disableIpTracking: true },
      cookiePrefix: 'plengo',
      useSecureCookies: secureCookies,
      defaultCookieAttributes: { sameSite: 'lax', httpOnly: true, secure: secureCookies },
    },
  });
}

export type Auth = ReturnType<typeof createAuth>;
