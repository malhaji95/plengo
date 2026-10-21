import { APIError } from 'better-auth/api';
import type { ErrorCode } from '@plengo/contracts';
import type { Auth } from '../auth/better-auth.js';
import { AppError } from '../lib/app-error.js';
import type { SessionsRepository } from '../repositories/sessions-repository.js';
import type { UsersRepository } from '../repositories/users-repository.js';
import type { CatalogService } from './catalog-service.js';
import type { MobileTokenService } from './mobile-token-service.js';

const BETTER_AUTH_CODE_MAP: Record<string, ErrorCode> = {
  INVALID_EMAIL_OR_PASSWORD: 'AUTH_INVALID_CREDENTIALS',
  INVALID_PASSWORD: 'AUTH_INVALID_CREDENTIALS',
  CREDENTIAL_ACCOUNT_NOT_FOUND: 'AUTH_INVALID_CREDENTIALS',
  EMAIL_NOT_VERIFIED: 'AUTH_EMAIL_NOT_VERIFIED',
  USER_ALREADY_EXISTS: 'AUTH_EMAIL_TAKEN',
  USER_ALREADY_EXISTS_USE_ANOTHER_EMAIL: 'AUTH_EMAIL_TAKEN',
  INVALID_OTP: 'AUTH_OTP_INVALID',
  OTP_EXPIRED: 'AUTH_OTP_INVALID',
  TOO_MANY_ATTEMPTS: 'AUTH_OTP_INVALID',
  INVALID_CODE: 'AUTH_OTP_INVALID',
  INVALID_BACKUP_CODE: 'AUTH_OTP_INVALID',
  TOO_MANY_ATTEMPTS_REQUEST_NEW_CODE: 'RATE_LIMITED',
  INVALID_TWO_FACTOR_COOKIE: 'AUTH_SESSION_EXPIRED',
  FAILED_TO_GET_SESSION: 'UNAUTHENTICATED',
  PASSWORD_TOO_SHORT: 'VALIDATION_ERROR',
  PASSWORD_TOO_LONG: 'VALIDATION_ERROR',
};

/** Translate a Better Auth APIError into our §30.4 codes; rethrow anything else. */
/** What cookie sessions record (§11.2, §31): hashed IP, a user-agent summary, the app version. */
function sessionFields(meta: RequestMeta) {
  return {
    ipHash: meta.ipHash,
    userAgent: meta.userAgent,
    appVersion: meta.headers.get('x-app-version')?.slice(0, 20) ?? null,
  };
}

export function mapAuthError(err: unknown, fallback: ErrorCode = 'SERVER_ERROR'): never {
  if (err instanceof AppError) throw err;
  if (err instanceof APIError) {
    const body = err.body as { code?: string } | undefined;
    const mapped = body?.code ? BETTER_AUTH_CODE_MAP[body.code] : undefined;
    if (mapped) throw new AppError(mapped);
    if (err.statusCode === 401) throw new AppError('UNAUTHENTICATED');
    if (fallback !== 'SERVER_ERROR') throw new AppError(fallback);
  }
  throw err;
}

export interface RequestMeta {
  headers: Headers;
  ipHash: string | null;
  userAgent: string | null;
}

export interface AuthResultWithCookies<T> {
  data: T;
  setCookies: string[];
}

function cookiesOf(headers: Headers | undefined): string[] {
  return headers?.getSetCookie() ?? [];
}

export function createAuthService(deps: {
  auth: Auth;
  usersRepo: UsersRepository;
  sessionsRepo: SessionsRepository;
  mobileTokens: MobileTokenService;
  catalog: CatalogService;
  /** False only in a pre-launch demo (env ADMIN_2FA_REQUIRED). */
  adminTwoFactorRequired?: boolean;
}) {
  const { auth, usersRepo, sessionsRepo, mobileTokens, catalog } = deps;

  /** Constant-ish work for unknown emails so response timing does not reveal account existence. */
  let dummyHash: Promise<string> | null = null;
  async function burnPasswordCheck(password: string) {
    const ctx = await auth.$context;
    dummyHash ??= ctx.password.hash('dummy-password-for-timing');
    await ctx.password.verify({ hash: await dummyHash, password });
  }

  async function verifyCredentials(email: string, password: string) {
    const user = await usersRepo.findByEmail(email);
    const hash = user ? await usersRepo.credentialPasswordHash(user.id) : null;
    if (!user || !hash) {
      await burnPasswordCheck(password);
      throw new AppError('AUTH_INVALID_CREDENTIALS');
    }
    const ctx = await auth.$context;
    const valid = await ctx.password.verify({ hash, password });
    if (!valid) throw new AppError('AUTH_INVALID_CREDENTIALS');
    if (user.status !== 'active') throw new AppError('AUTH_INVALID_CREDENTIALS');
    if (!user.emailVerified) throw new AppError('AUTH_EMAIL_NOT_VERIFIED');
    return user;
  }

  async function sessionIdFromToken(token: string | undefined): Promise<string | null> {
    return token ? sessionsRepo.findIdByToken(token) : null;
  }

  return {
    /** Re-confirms a signed-in user's password (account deletion). */
    async checkPassword(email: string, password: string) {
      try {
        await verifyCredentials(email, password);
        return true;
      } catch (err) {
        if (err instanceof AppError && err.code === 'AUTH_INVALID_CREDENTIALS') return false;
        throw err;
      }
    },

    async register(input: {
      fullName: string;
      email: string;
      password: string;
      educationLevelId?: string | undefined;
      universityId?: string | undefined;
      facultyId?: string | undefined;
      academicYearId?: string | undefined;
    }) {
      const path = await catalog.validateRegistrationPath(input.educationLevelId, input);
      try {
        const res = await auth.api.signUpEmail({
          body: { name: input.fullName, email: input.email, password: input.password },
        });
        // For an existing email Better Auth returns a synthetic user (no enumeration); nothing to store.
        if (!(await usersRepo.findById(res.user.id))) return { verificationRequired: true };
        await usersRepo.upsertProfile({
          userId: res.user.id,
          fullName: input.fullName,
          educationLevelId: input.educationLevelId ?? null,
          ...path,
        });
      } catch (err) {
        mapAuthError(err);
      }
      return { verificationRequired: true };
    },

    async verifyEmail(email: string, otp: string) {
      try {
        await auth.api.verifyEmailOTP({ body: { email, otp } });
      } catch (err) {
        mapAuthError(err, 'AUTH_OTP_INVALID');
      }
      return { verified: true };
    },

    /** Always succeeds for unknown/verified emails so the endpoint cannot enumerate accounts. */
    async resendVerification(email: string) {
      const user = await usersRepo.findByEmail(email);
      if (user && !user.emailVerified) {
        await auth.api.sendVerificationOTP({ body: { email, type: 'email-verification' } });
      }
      return { sent: true };
    },

    async requestPasswordReset(email: string) {
      const user = await usersRepo.findByEmail(email);
      if (user && user.status === 'active') {
        await auth.api.requestPasswordResetEmailOTP({ body: { email } });
      }
      return { sent: true };
    },

    async resetPassword(email: string, otp: string, newPassword: string) {
      try {
        await auth.api.resetPasswordEmailOTP({ body: { email, otp, password: newPassword } });
      } catch (err) {
        mapAuthError(err, 'AUTH_OTP_INVALID');
      }
      // Better Auth revokes cookie sessions; also end mobile sessions/token families.
      const user = await usersRepo.findByEmail(email);
      if (user) await sessionsRepo.revokeAllForUser(user.id);
      return { reset: true };
    },

    async mobileLogin(
      input: {
        email: string;
        password: string;
        platform: 'android' | 'ios';
        appVersion?: string | undefined;
      },
      meta: RequestMeta,
    ) {
      const user = await verifyCredentials(input.email, input.password);
      if (user.role !== 'student') throw new AppError('AUTH_INVALID_CREDENTIALS');
      return mobileTokens.issueForLogin({
        userId: user.id,
        platform: input.platform,
        appVersion: input.appVersion ?? null,
        ipHash: meta.ipHash,
        userAgent: meta.userAgent,
      });
    },

    /** Student web cookie login. Admin accounts must use the admin login. */
    async webLogin(input: { email: string; password: string }, meta: RequestMeta) {
      const existing = await usersRepo.findByEmail(input.email);
      if (existing && existing.role !== 'student') {
        await burnPasswordCheck(input.password);
        throw new AppError('AUTH_INVALID_CREDENTIALS');
      }
      try {
        const { headers, response } = await auth.api.signInEmail({
          body: { email: input.email, password: input.password, rememberMe: true },
          headers: meta.headers,
          returnHeaders: true,
        });
        const sessionId = await sessionIdFromToken(response.token);
        if (sessionId) await sessionsRepo.annotate(sessionId, { platform: 'web', ...sessionFields(meta) });
        return { data: { signedIn: true }, setCookies: cookiesOf(headers) };
      } catch (err) {
        mapAuthError(err, 'AUTH_INVALID_CREDENTIALS');
      }
    },

    async cookieLogout(meta: RequestMeta) {
      try {
        const { headers } = await auth.api.signOut({ headers: meta.headers, returnHeaders: true });
        return { data: { signedOut: true }, setCookies: cookiesOf(headers) };
      } catch {
        return { data: { signedOut: true }, setCookies: [] };
      }
    },

    /**
     * Admin password step. Enrolled admins get a pending two-factor cookie and must call
     * verifyAdminTotp; un-enrolled admins get a session that only the enrollment routes accept.
     */
    async adminLogin(input: { email: string; password: string }, meta: RequestMeta) {
      const existing = await usersRepo.findByEmail(input.email);
      if (!existing || existing.role !== 'admin' || existing.status !== 'active') {
        await burnPasswordCheck(input.password);
        throw new AppError('AUTH_INVALID_CREDENTIALS');
      }
      try {
        const { headers, response } = await auth.api.signInEmail({
          body: { email: input.email, password: input.password, rememberMe: false },
          headers: meta.headers,
          returnHeaders: true,
        });
        const setCookies = cookiesOf(headers);
        if ('twoFactorRedirect' in response && response.twoFactorRedirect) {
          return { data: { next: 'totp' as const }, setCookies };
        }
        const sessionId = await sessionIdFromToken((response as { token?: string }).token);
        if (sessionId) await sessionsRepo.annotate(sessionId, { platform: 'admin', ...sessionFields(meta) });
        // Not enrolled yet: enrollment is next, unless a demo turned admin 2FA off.
        return {
          data: { next: deps.adminTwoFactorRequired === false ? ('done' as const) : ('enroll' as const) },
          setCookies,
        };
      } catch (err) {
        mapAuthError(err, 'AUTH_INVALID_CREDENTIALS');
      }
    },

    async verifyAdminTotp(code: string, meta: RequestMeta) {
      try {
        const { headers, response } = await auth.api.verifyTOTP({
          body: { code },
          headers: meta.headers,
          returnHeaders: true,
        });
        const sessionId = await sessionIdFromToken((response as { token?: string }).token);
        if (sessionId) await sessionsRepo.annotate(sessionId, { platform: 'admin', ...sessionFields(meta) });
        return { data: { signedIn: true }, setCookies: cookiesOf(headers) };
      } catch (err) {
        mapAuthError(err, 'AUTH_OTP_INVALID');
      }
    },

    async verifyAdminBackupCode(code: string, meta: RequestMeta) {
      try {
        const { headers, response } = await auth.api.verifyBackupCode({
          body: { code },
          headers: meta.headers,
          returnHeaders: true,
        });
        const sessionId = await sessionIdFromToken((response as { token?: string }).token);
        if (sessionId) await sessionsRepo.annotate(sessionId, { platform: 'admin', ...sessionFields(meta) });
        return { data: { signedIn: true }, setCookies: cookiesOf(headers) };
      } catch (err) {
        mapAuthError(err, 'AUTH_OTP_INVALID');
      }
    },

    /** Step 1 of enrollment: returns the otpauth URI and one-time recovery codes. */
    async startAdminEnrollment(password: string, meta: RequestMeta) {
      try {
        const res = await auth.api.enableTwoFactor({
          body: { password, method: 'totp' },
          headers: meta.headers,
        });
        if (res.method !== 'totp') throw new AppError('SERVER_ERROR');
        return { totpUri: res.totpURI, backupCodes: res.backupCodes };
      } catch (err) {
        mapAuthError(err, 'AUTH_INVALID_CREDENTIALS');
      }
    },

    /** Step 2: proving one TOTP code marks 2FA enabled for the account and this session. */
    async confirmAdminEnrollment(code: string, meta: RequestMeta) {
      try {
        const { headers } = await auth.api.verifyTOTP({
          body: { code },
          headers: meta.headers,
          returnHeaders: true,
        });
        return { data: { enrolled: true }, setCookies: cookiesOf(headers) };
      } catch (err) {
        mapAuthError(err, 'AUTH_OTP_INVALID');
      }
    },
  };
}

export type AuthService = ReturnType<typeof createAuthService>;
