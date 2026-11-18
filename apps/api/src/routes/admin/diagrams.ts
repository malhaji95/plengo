import type { FastifyRequest } from 'fastify';
import type { FastifyPluginAsyncZod } from 'fastify-type-provider-zod';
import { z } from 'zod';
import {
  IMPORT_MAX_BYTES,
  adminDiagramPageSchema,
  adminDiagramQuerySchema,
  adminDiagramSchema,
  createDiagramBodySchema,
  deletedSchema,
  diagramImportBodySchema,
  diagramImportResultSchema,
  diagramImportTemplateQuerySchema,
  questionFreeBodySchema,
  questionStatusBodySchema,
  successEnvelope,
  updateDiagramBodySchema,
} from '@plengo/contracts';
import { authOf } from '../../authorization/guards.js';
import { ok } from '../../lib/app-error.js';
import type { Container } from '../../container.js';
import type { AdminActor } from '../../services/structure-service.js';

const idParams = z.object({ id: z.uuid() });
const actor = (request: FastifyRequest): AdminActor => ({ adminId: authOf(request).userId, ip: request.ip });

/** «رسمات العلوم» authoring and bulk import (v3 §9). */
export function adminDiagramRoutes(c: Container): FastifyPluginAsyncZod {
  const tags = ['admin-diagrams'];
  const d = c.diagrams;
  return async (app) => {
    app.addHook('onRequest', c.guards.requireAdmin);

    app.get(
      '/diagrams',
      {
        schema: {
          operationId: 'adminListDiagrams',
          tags,
          querystring: adminDiagramQuerySchema,
          response: { 200: successEnvelope(adminDiagramPageSchema) },
        },
      },
      async (request) => {
        const { cursor, limit, ...filter } = request.query;
        return ok(await d.adminList(filter, cursor, limit));
      },
    );
    app.get(
      '/diagrams/import/template',
      {
        schema: {
          operationId: 'adminDiagramImportTemplate',
          description: 'The diagram import layout with example rows, as CSV or XLSX.',
          tags,
          querystring: diagramImportTemplateQuerySchema,
        },
      },
      async (request, reply) => {
        const file = d.template(request.query.format);
        return reply
          .header('content-type', file.contentType)
          .header('content-disposition', `attachment; filename="${file.filename}"`)
          .header('cache-control', 'no-store')
          .send(file.body);
      },
    );
    app.post(
      '/diagrams/import',
      {
        bodyLimit: Math.ceil((IMPORT_MAX_BYTES * 4) / 3) + 256 * 1024,
        schema: {
          operationId: 'adminImportDiagrams',
          description:
            'One row per label (diagram_ref groups rows). A dry run validates and lists the image files needed; the real run creates every diagram in one transaction, or nothing when any row has an error.',
          tags,
          body: diagramImportBodySchema,
          response: { 200: successEnvelope(diagramImportResultSchema) },
        },
      },
      async (request) => ok(await d.importDiagrams(actor(request), request.body)),
    );
    app.get(
      '/diagrams/:id',
      {
        schema: {
          operationId: 'adminGetDiagram',
          tags,
          params: idParams,
          response: { 200: successEnvelope(adminDiagramSchema) },
        },
      },
      async (request) => ok(await d.adminGet(request.params.id)),
    );
    app.post(
      '/diagrams',
      {
        schema: {
          operationId: 'adminCreateDiagram',
          tags,
          body: createDiagramBodySchema,
          response: { 200: successEnvelope(adminDiagramSchema) },
        },
      },
      async (request) => ok(await d.create(actor(request), request.body)),
    );
    app.patch(
      '/diagrams/:id',
      {
        schema: {
          operationId: 'adminUpdateDiagram',
          tags,
          params: idParams,
          body: updateDiagramBodySchema,
          response: { 200: successEnvelope(adminDiagramSchema) },
        },
      },
      async (request) => ok(await d.update(actor(request), request.params.id, request.body)),
    );
    app.post(
      '/diagrams/:id/status',
      {
        schema: {
          operationId: 'adminSetDiagramStatus',
          tags,
          params: idParams,
          body: questionStatusBodySchema,
          response: { 200: successEnvelope(adminDiagramSchema) },
        },
      },
      async (request) => ok(await d.setStatus(actor(request), request.params.id, request.body.status)),
    );
    app.put(
      '/diagrams/:id/free',
      {
        schema: {
          operationId: 'adminSetDiagramFree',
          tags,
          params: idParams,
          body: questionFreeBodySchema,
          response: { 200: successEnvelope(adminDiagramSchema) },
        },
      },
      async (request) => ok(await d.setFree(actor(request), request.params.id, request.body.mode)),
    );
    app.delete(
      '/diagrams/:id',
      {
        schema: {
          operationId: 'adminDeleteDiagram',
          tags,
          params: idParams,
          response: { 200: successEnvelope(deletedSchema) },
        },
      },
      async (request) => ok(await d.remove(actor(request), request.params.id)),
    );
  };
}
