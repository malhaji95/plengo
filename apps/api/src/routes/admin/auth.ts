import type { FastifyPluginAsyncZod } from 'fastify-type-provider-zod';
import {
  adminCredentialsSchema,
  adminLoginResultSchema,
  backupCodeBodySchema,
  enrolledSchema,
  meSchema,
  passwordConfirmBodySchema,
  signedInSchema,
  signedOutSchema,
  successEnvelope,
  totpCodeBodySchema,
  totpEnrollmentSchema,
} from '@plengo/contracts';
import { authOf } from '../../authorization/guards.js';
import { AppError, ok } from '../../lib/app-error.js';
import type { Container } from '../../container.js';
import { forwardCookies, ipAndEmailKey, requestMeta } from '../helpers.js';

const FIFTEEN_MIN = 15 * 60 * 1000;

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
          body: adminCredentialsSchema,
          response: { 200: successEnvelope(adminLoginResultSchema) },
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
          body: totpCodeBodySchema,
          response: { 200: successEnvelope(signedInSchema) },
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
          body: backupCodeBodySchema,
          response: { 200: successEnvelope(signedInSchema) },
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
          body: passwordConfirmBodySchema,
          response: { 200: successEnvelope(totpEnrollmentSchema) },
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
          body: totpCodeBodySchema,
          response: { 200: successEnvelope(enrolledSchema) },
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
          response: { 200: successEnvelope(signedOutSchema) },
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
        return ok(await c.catalog.me(authOf(request).userId));
      },
    );
  };
}
