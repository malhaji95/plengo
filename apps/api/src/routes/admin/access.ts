import type { FastifyRequest } from 'fastify';
import type { FastifyPluginAsyncZod } from 'fastify-type-provider-zod';
import { z } from 'zod';
import {
  accessSettingsSchema,
  adminCouponListSchema,
  adminEntitlementSchema,
  adminStudentDetailSchema,
  adminStudentListSchema,
  couponBatchListSchema,
  couponBatchSchema,
  couponExportQuerySchema,
  couponFailureReportSchema,
  couponSearchQuerySchema,
  createCouponBatchBodySchema,
  createPromotionBodySchema,
  deletedSchema,
  extendEntitlementBodySchema,
  freeRuleBodySchema,
  freeRuleListSchema,
  freeRulePreviewSchema,
  freeRuleSchema,
  grantEntitlementBodySchema,
  promotionListSchema,
  promotionSchema,
  revokeEntitlementBodySchema,
  studentSearchQuerySchema,
  successEnvelope,
  updatePromotionBodySchema,
} from '@plengo/contracts';
import { authOf } from '../../authorization/guards.js';
import { ok } from '../../lib/app-error.js';
import type { Container } from '../../container.js';
import type { Scope } from '../../repositories/access-repository.js';
import type { AdminActor } from '../../services/structure-service.js';

const idParams = z.object({ id: z.uuid() });
const actor = (request: FastifyRequest): AdminActor => ({ adminId: authOf(request).userId, ip: request.ip });

/** Request scope fields → Scope. The contracts already guarantee exactly one matching id. */
function scopeOf(body: {
  scopeType: 'subject' | 'teacher_track';
  subjectId?: string | null | undefined;
  teacherTrackId?: string | null | undefined;
}): Scope {
  return body.scopeType === 'subject'
    ? { scopeType: 'subject', subjectId: body.subjectId!, teacherTrackId: null }
    : { scopeType: 'teacher_track', subjectId: null, teacherTrackId: body.teacherTrackId! };
}

/** Admin access management (spec §26.2): students' entitlements, coupons, promotions, free rules. */
export function adminAccessRoutes(c: Container): FastifyPluginAsyncZod {
  return async (app) => {
    app.addHook('onRequest', c.guards.requireAdmin);

    // ---- students & entitlements ----
    {
      const tags = ['admin-students'];
      app.get(
        '/students',
        {
          schema: {
            operationId: 'adminListStudents',
            tags,
            querystring: studentSearchQuerySchema,
            response: { 200: successEnvelope(adminStudentListSchema) },
          },
        },
        async (request) => ok(await c.access.searchStudents(request.query.q)),
      );
      app.get(
        '/students/:id',
        {
          schema: {
            operationId: 'adminGetStudent',
            tags,
            params: idParams,
            response: { 200: successEnvelope(adminStudentDetailSchema) },
          },
        },
        async (request) => ok(await c.access.studentDetail(request.params.id)),
      );
      app.post(
        '/students/:id/entitlements',
        {
          schema: {
            operationId: 'adminGrantEntitlement',
            tags,
            params: idParams,
            body: grantEntitlementBodySchema,
            response: { 200: successEnvelope(adminEntitlementSchema) },
          },
        },
        async (request) =>
          ok(
            await c.access.grant(actor(request), request.params.id, {
              ...request.body,
              scope: scopeOf(request.body),
            }),
          ),
      );
      app.post(
        '/entitlements/:id/extend',
        {
          schema: {
            operationId: 'adminExtendEntitlement',
            tags,
            params: idParams,
            body: extendEntitlementBodySchema,
            response: { 200: successEnvelope(adminEntitlementSchema) },
          },
        },
        async (request) => ok(await c.access.extend(actor(request), request.params.id, request.body)),
      );
      app.post(
        '/entitlements/:id/revoke',
        {
          schema: {
            operationId: 'adminRevokeEntitlement',
            tags,
            params: idParams,
            body: revokeEntitlementBodySchema,
            response: { 200: successEnvelope(adminEntitlementSchema) },
          },
        },
        async (request) => ok(await c.access.revoke(actor(request), request.params.id, request.body.reason)),
      );
    }

    const tags = ['admin-access'];

    // ---- coupons ----
    app.get(
      '/coupon-batches',
      {
        schema: {
          operationId: 'adminListCouponBatches',
          tags,
          response: { 200: successEnvelope(couponBatchListSchema) },
        },
      },
      async () => ok(await c.coupons.listBatches()),
    );
    app.post(
      '/coupon-batches',
      {
        schema: {
          operationId: 'adminCreateCouponBatch',
          tags,
          body: createCouponBatchBodySchema,
          response: { 200: successEnvelope(couponBatchSchema) },
        },
      },
      async (request) =>
        ok(await c.coupons.createBatch(actor(request), { ...request.body, scope: scopeOf(request.body) })),
    );
    app.get(
      '/coupon-batches/:id',
      {
        schema: {
          operationId: 'adminGetCouponBatch',
          tags,
          params: idParams,
          response: { 200: successEnvelope(couponBatchSchema) },
        },
      },
      async (request) => ok(await c.coupons.getBatch(request.params.id)),
    );
    app.get(
      '/coupon-batches/:id/coupons',
      {
        schema: {
          operationId: 'adminListBatchCoupons',
          tags,
          params: idParams,
          response: { 200: successEnvelope(adminCouponListSchema) },
        },
      },
      async (request) => ok(await c.coupons.batchCoupons(request.params.id)),
    );
    app.get(
      '/coupon-batches/:id/export',
      {
        schema: {
          operationId: 'adminExportCouponBatch',
          description: 'CSV or XLSX file with the plaintext codes (spec §9.6). Audited.',
          tags,
          params: idParams,
          querystring: couponExportQuerySchema,
        },
      },
      async (request, reply) => {
        const file = await c.coupons.exportBatch(actor(request), request.params.id, request.query.format);
        return reply
          .header('content-type', file.contentType)
          .header('content-disposition', `attachment; filename="${file.filename}"`)
          .header('cache-control', 'no-store')
          .send(file.body);
      },
    );
    app.post(
      '/coupon-batches/:id/revoke',
      {
        schema: {
          operationId: 'adminRevokeCouponBatch',
          tags,
          params: idParams,
          response: { 200: successEnvelope(couponBatchSchema) },
        },
      },
      async (request) => ok(await c.coupons.revokeBatch(actor(request), request.params.id)),
    );
    app.get(
      '/coupons',
      {
        schema: {
          operationId: 'adminSearchCoupons',
          tags,
          querystring: couponSearchQuerySchema,
          response: { 200: successEnvelope(adminCouponListSchema) },
        },
      },
      async (request) => ok(await c.coupons.searchCoupons(request.query.q)),
    );
    app.get(
      '/coupon-failures',
      {
        schema: {
          operationId: 'adminCouponFailureReport',
          tags,
          response: { 200: successEnvelope(couponFailureReportSchema) },
        },
      },
      async () => ok(await c.coupons.failureReport()),
    );
    app.get(
      '/settings/access',
      {
        schema: {
          operationId: 'adminGetAccessSettings',
          tags,
          response: { 200: successEnvelope(accessSettingsSchema) },
        },
      },
      async () => ok(await c.configService.getAccessSettings()),
    );
    app.put(
      '/settings/access',
      {
        schema: {
          operationId: 'adminUpdateAccessSettings',
          tags,
          body: accessSettingsSchema,
          response: { 200: successEnvelope(accessSettingsSchema) },
        },
      },
      async (request) => {
        const before = await c.configService.getAccessSettings();
        const saved = await c.configService.setAccessSettings(request.body, authOf(request).userId);
        await c.audit.record({
          actorAdminId: authOf(request).userId,
          action: 'settings.changed',
          resourceType: 'app_setting',
          resourceId: 'access',
          metadata: { from: before, to: saved },
          ip: request.ip,
        });
        return ok(saved);
      },
    );

    // ---- promotions ----
    app.get(
      '/promotions',
      {
        schema: {
          operationId: 'adminListPromotions',
          tags,
          response: { 200: successEnvelope(promotionListSchema) },
        },
      },
      async () => ok(await c.promotions.list()),
    );
    app.post(
      '/promotions',
      {
        schema: {
          operationId: 'adminCreatePromotion',
          tags,
          body: createPromotionBodySchema,
          response: { 200: successEnvelope(promotionSchema) },
        },
      },
      async (request) =>
        ok(await c.promotions.create(actor(request), { ...request.body, scope: scopeOf(request.body) })),
    );
    app.patch(
      '/promotions/:id',
      {
        schema: {
          operationId: 'adminUpdatePromotion',
          tags,
          params: idParams,
          body: updatePromotionBodySchema,
          response: { 200: successEnvelope(promotionSchema) },
        },
      },
      async (request) => ok(await c.promotions.update(actor(request), request.params.id, request.body)),
    );
    app.delete(
      '/promotions/:id',
      {
        schema: {
          operationId: 'adminDeletePromotion',
          tags,
          params: idParams,
          response: { 200: successEnvelope(deletedSchema) },
        },
      },
      async (request) => ok(await c.promotions.remove(actor(request), request.params.id)),
    );

    // ---- free rules ----
    app.get(
      '/free-rules',
      {
        schema: {
          operationId: 'adminListFreeRules',
          tags,
          response: { 200: successEnvelope(freeRuleListSchema) },
        },
      },
      async () => ok(await c.freeRules.list()),
    );
    app.post(
      '/free-rules/preview',
      {
        schema: {
          operationId: 'adminPreviewFreeRule',
          tags,
          body: freeRuleBodySchema,
          response: { 200: successEnvelope(freeRulePreviewSchema) },
        },
      },
      async (request) => ok(await c.freeRules.preview({ ...request.body, scope: scopeOf(request.body) })),
    );
    app.put(
      '/free-rules',
      {
        schema: {
          operationId: 'adminSaveFreeRule',
          tags,
          body: freeRuleBodySchema,
          response: { 200: successEnvelope(freeRuleSchema) },
        },
      },
      async (request) =>
        ok(await c.freeRules.upsert(actor(request), { ...request.body, scope: scopeOf(request.body) })),
    );
    app.delete(
      '/free-rules/:id',
      {
        schema: {
          operationId: 'adminDeleteFreeRule',
          tags,
          params: idParams,
          response: { 200: successEnvelope(deletedSchema) },
        },
      },
      async (request) => ok(await c.freeRules.remove(actor(request), request.params.id)),
    );
  };
}
