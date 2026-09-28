import type { FastifyPluginAsyncZod } from 'fastify-type-provider-zod';
import {
  forgotPasswordBodySchema,
  mobileLoginBodySchema,
  mobileLogoutBodySchema,
  mobileRefreshBodySchema,
  registerBodySchema,
  resendOtpBodySchema,
  resetPasswordBodySchema,
  resetSchema,
  sentSchema,
  signedInSchema,
  signedOutSchema,
  successEnvelope,
  tokenPairSchema,
  verificationRequiredSchema,
  verifiedSchema,
  verifyEmailBodySchema,
  webLoginBodySchema,
} from '@plengo/contracts';
import type { FastifyRequest } from 'fastify';
import { AppError, ok } from '../lib/app-error.js';
import { WindowLimiter } from '../lib/window-limiter.js';
import type { Container } from '../container.js';
import { emailKey, forwardCookies, ipAndEmailKey, requestMeta } from './helpers.js';

const FIFTEEN_MIN = 15 * 60 * 1000;
const HOUR = 60 * 60 * 1000;

/** Student authentication: email + password only (spec §11.1). */
export function authRoutes(c: Container): FastifyPluginAsyncZod {
  const loginLimit = { max: 10, timeWindow: FIFTEEN_MIN, keyGenerator: ipAndEmailKey };
  // §31: 5 OTP emails per hour per address, across register, resend and password reset together.
  const otpEmails = new WindowLimiter(5, HOUR);
  const otpLimit = async (request: FastifyRequest) => {
    if (!otpEmails.hit(emailKey(request))) throw new AppError('RATE_LIMITED');
  };
  const tags = ['auth'];

  return async (app) => {
    app.post(
      '/register',
      {
        preHandler: otpLimit,
        schema: {
          operationId: 'register',
          tags,
          body: registerBodySchema,
          response: { 200: successEnvelope(verificationRequiredSchema) },
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
          response: { 200: successEnvelope(verifiedSchema) },
        },
      },
      async (request) => ok(await c.authService.verifyEmail(request.body.email, request.body.otp)),
    );

    app.post(
      '/resend-otp',
      {
        preHandler: otpLimit,
        schema: {
          operationId: 'resendOtp',
          tags,
          body: resendOtpBodySchema,
          response: { 200: successEnvelope(sentSchema) },
        },
      },
      async (request) => ok(await c.authService.resendVerification(request.body.email)),
    );

    app.post(
      '/forgot-password',
      {
        preHandler: otpLimit,
        schema: {
          operationId: 'forgotPassword',
          tags,
          body: forgotPasswordBodySchema,
          response: { 200: successEnvelope(sentSchema) },
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
          response: { 200: successEnvelope(resetSchema) },
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
          response: { 200: successEnvelope(signedOutSchema) },
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
          body: webLoginBodySchema,
          response: { 200: successEnvelope(signedInSchema) },
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
          response: { 200: successEnvelope(signedOutSchema) },
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
