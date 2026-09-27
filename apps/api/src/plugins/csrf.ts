import type { FastifyInstance } from 'fastify';
import { AppError } from '../lib/app-error.js';

declare module 'fastify' {
  interface FastifyContextConfig {
    /** Route sets/uses cookies and must pass the Origin + X-Requested-With check even without a cookie yet. */
    cookieAuth?: boolean;
  }
}

const SAFE_METHODS = new Set(['GET', 'HEAD', 'OPTIONS']);

/**
 * CSRF defense for cookie sessions (spec §11.2): mutating requests that carry cookies (or hit a
 * cookie-issuing route) need an allowed Origin and the X-Requested-With header. Bearer requests
 * from the mobile app are exempt because browsers never attach them automatically.
 */
export function registerCsrf(app: FastifyInstance, allowedOrigins: string[]) {
  const allowed = new Set(allowedOrigins.map((o) => new URL(o).origin));
  app.addHook('onRequest', async (request) => {
    if (SAFE_METHODS.has(request.method)) return;
    if (request.headers.authorization?.startsWith('Bearer ')) return;
    const usesCookies = Boolean(request.headers.cookie) || request.routeOptions.config?.cookieAuth === true;
    if (!usesCookies) return;
    const origin = request.headers.origin;
    if (!origin || !allowed.has(origin) || !request.headers['x-requested-with']) {
      throw new AppError('NOT_AUTHORIZED', { details: { reason: 'csrf' } });
    }
  });
}
