import type { FastifyPluginAsyncZod } from 'fastify-type-provider-zod';
import { z } from 'zod';
import {
  loyaltyLedgerPageSchema,
  loyaltyRedeemResultSchema,
  loyaltyRedemptionListSchema,
  loyaltyRewardListSchema,
  loyaltySummarySchema,
  successEnvelope,
} from '@plengo/contracts';
import { authOf } from '../authorization/guards.js';
import { ok } from '../lib/app-error.js';
import type { Container } from '../container.js';

const idParams = z.object({ id: z.uuid() });

/** Loyalty points and rewards for students (v3 §10). */
export function loyaltyRoutes(c: Container): FastifyPluginAsyncZod {
  return async (app) => {
    app.addHook('onRequest', c.guards.requireUser);
    const tags = ['loyalty'];

    app.get(
      '/loyalty',
      {
        schema: {
          operationId: 'getLoyaltySummary',
          description: 'Balance, points earned today toward the daily cap, and the current rules.',
          tags,
          response: { 200: successEnvelope(loyaltySummarySchema) },
        },
      },
      async (request) => ok(await c.loyalty.summary(authOf(request).userId)),
    );
    app.get(
      '/loyalty/history',
      {
        schema: {
          operationId: 'listLoyaltyHistory',
          description: 'The latest 100 point changes, newest first.',
          tags,
          response: { 200: successEnvelope(loyaltyLedgerPageSchema) },
        },
      },
      async (request) => ok(await c.loyalty.ledger(authOf(request).userId)),
    );
    app.get(
      '/loyalty/rewards',
      {
        schema: {
          operationId: 'listLoyaltyRewards',
          tags,
          response: { 200: successEnvelope(loyaltyRewardListSchema) },
        },
      },
      async (request) => ok(await c.loyalty.rewards(authOf(request).userId)),
    );
    app.post(
      '/loyalty/rewards/:id/redeem',
      {
        schema: {
          operationId: 'redeemLoyaltyReward',
          description:
            'Spends points. `unlock_deck` opens the deck at once (ALREADY_ENTITLED if it is already open); `custom` is recorded for the admin. INSUFFICIENT_POINTS when the balance is short.',
          tags,
          params: idParams,
          response: { 200: successEnvelope(loyaltyRedeemResultSchema) },
        },
      },
      async (request) => ok(await c.loyalty.redeem(authOf(request).userId, request.params.id)),
    );
    app.get(
      '/loyalty/redemptions',
      {
        schema: {
          operationId: 'listMyLoyaltyRedemptions',
          tags,
          response: { 200: successEnvelope(loyaltyRedemptionListSchema) },
        },
      },
      async (request) => ok(await c.loyalty.myRedemptions(authOf(request).userId)),
    );
  };
}
