import type { FastifyPluginAsyncZod } from 'fastify-type-provider-zod';
import { z } from 'zod';
import { emailSchema, meSchema, successEnvelope } from '@plengo/contracts';
import { authOf } from '../../authorization/guards.js';
import { AppError, ok } from '../../lib/app-error.js';
import type { Container } from '../../container.js';
import { forwardCookies, ipAndEmailKey, requestMeta } from '../helpers.js';

const FIFTEEN_MIN = 15 * 60 * 1000;
const totpCode = z.string().regex(/^\d{6}$/);

/** Admin sign-in: password step, then TOTP verification or first-time enrollment (spec §11.3). */
export function adminAuthRoutes(c: Container): FastifyPluginAsyncZod {
  const tags = ['admin-auth'];
  const codeLimit = { max: 10, timeWindow: FIFTEEN_MIN };

  return async (app) => {
    app.post(
      '/auth/login',
      {
        config: {
          cookieAuth: true,
          rateLimit: { max: 10, timeWindow: FIFTEEN_MIN, keyGenerator: ipAndEmailKey },
        },
        schema: {
          operationId: 'adminLogin',
          tags,
          body: z.object({ email: emailSchema, password: z.string().min(1).max(128) }),
          response: { 200: successEnvelope(z.object({ next: z.enum(['totp', 'enroll']) })) },
        },
      },
      async (request, reply) => {
        const res = await c.authService.adminLogin(request.body, requestMeta(request, c.hashIp));
        forwardCookies(reply, res.setCookies);
        return ok(res.data);
      },
    );

    app.post(
      '/auth/2fa/verify',
      {
        config: { cookieAuth: true, rateLimit: codeLimit },
        schema: {
          operationId: 'adminVerifyTotp',
          tags,
          body: z.object({ code: totpCode }),
          response: { 200: successEnvelope(z.object({ signedIn: z.boolean() })) },
        },
      },
      async (request, reply) => {
        const res = await c.authService.verifyAdminTotp(request.body.code, requestMeta(request, c.hashIp));
        forwardCookies(reply, res.setCookies);
        return ok(res.data);
      },
    );

    app.post(
      '/auth/2fa/backup',
      {
        config: { cookieAuth: true, rateLimit: codeLimit },
        schema: {
          operationId: 'adminVerifyBackupCode',
          tags,
          body: z.object({ code: z.string().min(4).max(64) }),
          response: { 200: successEnvelope(z.object({ signedIn: z.boolean() })) },
        },
      },
      async (request, reply) => {
        const res = await c.authService.verifyAdminBackupCode(
          request.body.code,
          requestMeta(request, c.hashIp),
        );
        forwardCookies(reply, res.setCookies);
        return ok(res.data);
      },
    );

    app.post(
      '/auth/2fa/enroll',
      {
        preHandler: c.guards.requireAdminEnrolling,
        config: { cookieAuth: true, rateLimit: codeLimit },
        schema: {
          operationId: 'adminStartEnrollment',
          tags,
          body: z.object({ password: z.string().min(1).max(128) }),
          response: {
            200: successEnvelope(z.object({ totpUri: z.string(), backupCodes: z.array(z.string()) })),
          },
        },
      },
      async (request) => {
        if (authOf(request).twoFactorEnabled) throw new AppError('NOT_AUTHORIZED');
        return ok(
          await c.authService.startAdminEnrollment(request.body.password, requestMeta(request, c.hashIp)),
        );
      },
    );

    app.post(
      '/auth/2fa/confirm',
      {
        preHandler: c.guards.requireAdminEnrolling,
        config: { cookieAuth: true, rateLimit: codeLimit },
        schema: {
          operationId: 'adminConfirmEnrollment',
          tags,
          body: z.object({ code: totpCode }),
          response: { 200: successEnvelope(z.object({ enrolled: z.boolean() })) },
        },
      },
      async (request, reply) => {
        const auth = authOf(request);
        const res = await c.authService.confirmAdminEnrollment(
          request.body.code,
          requestMeta(request, c.hashIp),
        );
        forwardCookies(reply, res.setCookies);
        await c.audit.record({
          actorAdminId: auth.userId,
          action: 'admin.2fa_enrolled',
          resourceType: 'admin',
          resourceId: auth.userId,
          ip: request.ip,
        });
        return ok(res.data);
      },
    );

    app.post(
      '/auth/logout',
      {
        config: { cookieAuth: true },
        schema: {
          operationId: 'adminLogout',
          tags,
          response: { 200: successEnvelope(z.object({ signedOut: z.boolean() })) },
        },
      },
      async (request, reply) => {
        const res = await c.authService.cookieLogout(requestMeta(request, c.hashIp));
        forwardCookies(reply, res.setCookies);
        return ok(res.data);
      },
    );

    app.get(
      '/me',
      {
        preHandler: c.guards.requireAdmin,
        schema: { operationId: 'adminGetMe', tags, response: { 200: successEnvelope(meSchema) } },
      },
      async (request) => {
        const me = await c.usersRepo.getMe(authOf(request).userId);
        if (!me) throw new AppError('NOT_FOUND');
        return ok(me);
      },
    );
  };
}
