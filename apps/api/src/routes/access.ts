import type { FastifyPluginAsyncZod } from 'fastify-type-provider-zod';
import {
  myEntitlementListSchema,
  redeemCouponBodySchema,
  redeemResultSchema,
  successEnvelope,
} from '@plengo/contracts';
import { authOf } from '../authorization/guards.js';
import { ok } from '../lib/app-error.js';
import type { Container } from '../container.js';

/**
 * Student access (spec §30.2): "My access" and coupon redemption. The endpoint exists for every
 * client; builds with COUPON_REDEMPTION=false simply never reach it (§10.1).
 */
export function accessRoutes(c: Container): FastifyPluginAsyncZod {
  const tags = ['access'];

  return async (app) => {
    app.addHook('onRequest', c.guards.requireUser);

    app.get(
      '/access',
      {
        schema: {
          operationId: 'listMyEntitlements',
          tags,
          response: { 200: successEnvelope(myEntitlementListSchema) },
        },
      },
      async (request) => ok(await c.access.myEntitlements(authOf(request).userId)),
    );

    app.post(
      '/coupons/redeem',
      {
        schema: {
          operationId: 'redeemCoupon',
          tags,
          body: redeemCouponBodySchema,
          response: { 200: successEnvelope(redeemResultSchema) },
        },
      },
      async (request) => {
        const auth = authOf(request);
        return ok(
          await c.coupons.redeem(
            { userId: auth.userId, sessionId: auth.sessionId, ip: request.ip },
            request.body.code,
          ),
        );
      },
    );
  };
}
