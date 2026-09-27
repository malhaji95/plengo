import type { FastifyPluginAsyncZod } from 'fastify-type-provider-zod';
import { z } from 'zod';
import {
  emailSchema,
  forgotPasswordBodySchema,
  mobileLoginBodySchema,
  mobileLogoutBodySchema,
  mobileRefreshBodySchema,
  registerBodySchema,
  resendOtpBodySchema,
  resetPasswordBodySchema,
  successEnvelope,
  tokenPairSchema,
  verifyEmailBodySchema,
} from '@plengo/contracts';
import { ok } from '../lib/app-error.js';
import type { Container } from '../container.js';
import { emailKey, forwardCookies, ipAndEmailKey, requestMeta } from './helpers.js';

const FIFTEEN_MIN = 15 * 60 * 1000;
const HOUR = 60 * 60 * 1000;

/** Student authentication: email + password only (spec §11.1). */
export function authRoutes(c: Container): FastifyPluginAsyncZod {
  const loginLimit = { max: 10, timeWindow: FIFTEEN_MIN, keyGenerator: ipAndEmailKey };
  const otpLimit = { max: 5, timeWindow: HOUR, keyGenerator: emailKey };
  const tags = ['auth'];

  return async (app) => {
    app.post(
      '/register',
      {
        config: { rateLimit: otpLimit },
        schema: {
          operationId: 'register',
          tags,
          body: registerBodySchema,
          response: { 200: successEnvelope(z.object({ verificationRequired: z.boolean() })) },
        },
      },
      async (request) => ok(await c.authService.register(request.body)),
    );

    app.post(
      '/verify-email',
      {
        config: { rateLimit: loginLimit },
        schema: {
          operationId: 'verifyEmail',
          tags,
          body: verifyEmailBodySchema,
          response: { 200: successEnvelope(z.object({ verified: z.boolean() })) },
        },
      },
      async (request) => ok(await c.authService.verifyEmail(request.body.email, request.body.otp)),
    );

    app.post(
      '/resend-otp',
      {
        config: { rateLimit: otpLimit },
        schema: {
          operationId: 'resendOtp',
          tags,
          body: resendOtpBodySchema,
          response: { 200: successEnvelope(z.object({ sent: z.boolean() })) },
        },
      },
      async (request) => ok(await c.authService.resendVerification(request.body.email)),
    );

    app.post(
      '/forgot-password',
      {
        config: { rateLimit: otpLimit },
        schema: {
          operationId: 'forgotPassword',
          tags,
          body: forgotPasswordBodySchema,
          response: { 200: successEnvelope(z.object({ sent: z.boolean() })) },
        },
      },
      async (request) => ok(await c.authService.requestPasswordReset(request.body.email)),
    );

    app.post(
      '/reset-password',
      {
        config: { rateLimit: loginLimit },
        schema: {
          operationId: 'resetPassword',
          tags,
          body: resetPasswordBodySchema,
          response: { 200: successEnvelope(z.object({ reset: z.boolean() })) },
        },
      },
      async (request) =>
        ok(await c.authService.resetPassword(request.body.email, request.body.otp, request.body.newPassword)),
    );

    app.post(
      '/mobile/login',
      {
        config: { rateLimit: loginLimit },
        schema: {
          operationId: 'mobileLogin',
          tags,
          body: mobileLoginBodySchema,
          response: { 200: successEnvelope(tokenPairSchema) },
        },
      },
      async (request) => ok(await c.authService.mobileLogin(request.body, requestMeta(request, c.hashIp))),
    );

    app.post(
      '/mobile/refresh',
      {
        config: { rateLimit: { max: 60, timeWindow: FIFTEEN_MIN } },
        schema: {
          operationId: 'mobileRefresh',
          tags,
          body: mobileRefreshBodySchema,
          response: { 200: successEnvelope(tokenPairSchema) },
        },
      },
      async (request) => ok(await c.mobileTokens.refresh(request.body.refreshToken)),
    );

    app.post(
      '/mobile/logout',
      {
        schema: {
          operationId: 'mobileLogout',
          tags,
          body: mobileLogoutBodySchema,
          response: { 200: successEnvelope(z.object({ signedOut: z.boolean() })) },
        },
      },
      async (request) => {
        await c.mobileTokens.logout(request.body.refreshToken);
        return ok({ signedOut: true });
      },
    );

    app.post(
      '/web/login',
      {
        config: { rateLimit: loginLimit, cookieAuth: true },
        schema: {
          operationId: 'webLogin',
          tags,
          body: z.object({ email: emailSchema, password: z.string().min(1).max(128) }),
          response: { 200: successEnvelope(z.object({ signedIn: z.boolean() })) },
        },
      },
      async (request, reply) => {
        const res = await c.authService.webLogin(request.body, requestMeta(request, c.hashIp));
        forwardCookies(reply, res.setCookies);
        return ok(res.data);
      },
    );

    app.post(
      '/web/logout',
      {
        config: { cookieAuth: true },
        schema: {
          operationId: 'webLogout',
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
  };
}
