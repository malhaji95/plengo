'use client';

import * as Sentry from '@sentry/react';

/**
 * Crash reporting for the admin app (spec §2.8), on only when a DSN is configured. Sentry's browser
 * SDK sends no user data unless it is attached explicitly, and nothing here attaches it.
 */
const dsn = process.env.NEXT_PUBLIC_SENTRY_DSN;
if (dsn && typeof window !== 'undefined' && !Sentry.getClient()) {
  Sentry.init({ dsn, environment: process.env.NEXT_PUBLIC_APP_ENV ?? 'development' });
}

export function ErrorReporting() {
  return null;
}
