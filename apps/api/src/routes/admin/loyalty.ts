import type { FastifyRequest } from 'fastify';
import type { FastifyPluginAsyncZod } from 'fastify-type-provider-zod';
import { z } from 'zod';
import {
  adminLoyaltyRedemptionPageSchema,
  adminLoyaltyRedemptionQuerySchema,
  adminLoyaltyRewardListSchema,
  adminLoyaltyRewardSchema,
  adminStudentLoyaltySchema,
  createLoyaltyRewardBodySchema,
  deletedSchema,
  loyaltyAdjustBodySchema,
  loyaltyRedemptionSchema,
  loyaltySettingsSchema,
  redemptionStatusBodySchema,
  successEnvelope,
  updateLoyaltyRewardBodySchema,
} from '@plengo/contracts';
import { authOf } from '../../authorization/guards.js';
import { ok } from '../../lib/app-error.js';
import type { Container } from '../../container.js';
import type { AdminActor } from '../../services/structure-service.js';

const idParams = z.object({ id: z.uuid() });
const actor = (request: FastifyRequest): AdminActor => ({ adminId: authOf(request).userId, ip: request.ip });

/** Loyalty rules, rewards, redemptions and student balances (v3 §10). */
export function adminLoyaltyRoutes(c: Container): FastifyPluginAsyncZod {
  const tags = ['admin-loyalty'];
  const l = c.loyalty;
  return async (app) => {
    app.addHook('onRequest', c.guards.requireAdmin);

    app.get(
      '/settings/loyalty',
      {
        schema: {
          operationId: 'adminGetLoyaltySettings',
          tags,
          response: { 200: successEnvelope(loyaltySettingsSchema) },
        },
      },
      async () => ok(await l.getSettings()),
    );
    app.put(
      '/settings/loyalty',
      {
        schema: {
          operationId: 'adminUpdateLoyaltySettings',
          tags,
          body: loyaltySettingsSchema,
          response: { 200: successEnvelope(loyaltySettingsSchema) },
        },
      },
      async (request) => ok(await l.setSettings(actor(request), request.body)),
    );

    app.get(
      '/loyalty/rewards',
      {
        schema: {
          operationId: 'adminListLoyaltyRewards',
          tags,
          response: { 200: successEnvelope(adminLoyaltyRewardListSchema) },
        },
      },
      async () => ok(await l.adminRewards()),
    );
    app.post(
      '/loyalty/rewards',
      {
        schema: {
          operationId: 'adminCreateLoyaltyReward',
          tags,
          body: createLoyaltyRewardBodySchema,
          response: { 200: successEnvelope(adminLoyaltyRewardSchema) },
        },
      },
      async (request) => ok(await l.createReward(actor(request), request.body)),
    );
    app.patch(
      '/loyalty/rewards/:id',
      {
        schema: {
          operationId: 'adminUpdateLoyaltyReward',
          tags,
          params: idParams,
          body: updateLoyaltyRewardBodySchema,
          response: { 200: successEnvelope(adminLoyaltyRewardSchema) },
        },
      },
      async (request) => ok(await l.updateReward(actor(request), request.params.id, request.body)),
    );
    app.delete(
      '/loyalty/rewards/:id',
      {
        schema: {
          operationId: 'adminDeleteLoyaltyReward',
          tags,
          params: idParams,
          response: { 200: successEnvelope(deletedSchema) },
        },
      },
      async (request) => ok(await l.removeReward(actor(request), request.params.id)),
    );

    app.get(
      '/loyalty/redemptions',
      {
        schema: {
          operationId: 'adminListLoyaltyRedemptions',
          tags,
          querystring: adminLoyaltyRedemptionQuerySchema,
          response: { 200: successEnvelope(adminLoyaltyRedemptionPageSchema) },
        },
      },
      async (request) => {
        const { cursor, limit, ...filter } = request.query;
        return ok(await l.redemptions(filter, cursor, limit));
      },
    );
    app.post(
      '/loyalty/redemptions/:id/status',
      {
        schema: {
          operationId: 'adminSetLoyaltyRedemptionStatus',
          description: '`fulfilled` marks a custom reward handed over; `cancelled` refunds the points.',
          tags,
          params: idParams,
          body: redemptionStatusBodySchema,
          response: { 200: successEnvelope(loyaltyRedemptionSchema) },
        },
      },
      async (request) => ok(await l.setRedemptionStatus(actor(request), request.params.id, request.body)),
    );

    app.get(
      '/students/:id/loyalty',
      {
        schema: {
          operationId: 'adminGetStudentLoyalty',
          tags,
          params: idParams,
          response: { 200: successEnvelope(adminStudentLoyaltySchema) },
        },
      },
      async (request) => ok(await l.studentLoyalty(request.params.id)),
    );
    app.post(
      '/students/:id/loyalty/adjust',
      {
        schema: {
          operationId: 'adminAdjustStudentLoyalty',
          tags,
          params: idParams,
          body: loyaltyAdjustBodySchema,
          response: { 200: successEnvelope(adminStudentLoyaltySchema) },
        },
      },
      async (request) => ok(await l.adjust(actor(request), request.params.id, request.body)),
    );
  };
}
