import { ERROR_MESSAGES, type ErrorCode } from '@plengo/contracts';

const DEFAULT_STATUS: Partial<Record<ErrorCode, number>> = {
  AUTH_INVALID_CREDENTIALS: 401,
  AUTH_EMAIL_NOT_VERIFIED: 403,
  AUTH_OTP_INVALID: 400,
  AUTH_2FA_REQUIRED: 403,
  AUTH_SESSION_EXPIRED: 401,
  AUTH_EMAIL_TAKEN: 409,
  UNAUTHENTICATED: 401,
  APP_UPDATE_REQUIRED: 426,
  CONTENT_LOCKED: 403,
  NOT_AUTHORIZED: 403,
  NOT_FOUND: 404,
  QUOTA_EXCEEDED: 403,
  RATE_LIMITED: 429,
  VALIDATION_ERROR: 400,
  ALREADY_ENTITLED: 409,
  SERVER_ERROR: 500,
};

/** A domain error that the error handler renders as the §30.3 envelope. */
export class AppError extends Error {
  readonly code: ErrorCode;
  readonly statusCode: number;
  readonly details?: unknown;

  constructor(code: ErrorCode, options: { statusCode?: number; details?: unknown; message?: string } = {}) {
    super(options.message ?? ERROR_MESSAGES[code]);
    this.name = 'AppError';
    this.code = code;
    this.statusCode = options.statusCode ?? DEFAULT_STATUS[code] ?? 400;
    this.details = options.details;
  }
}

export function ok<T>(data: T) {
  return { success: true as const, data, error: null };
}
