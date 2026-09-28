import type { FastifyReply, FastifyRequest } from 'fastify';
import type { FastifyPluginAsyncZod } from 'fastify-type-provider-zod';
import { z } from 'zod';
import {
  IMPORT_MAX_BYTES,
  confirmImportBodySchema,
  createImportBodySchema,
  importJobListSchema,
  importJobSchema,
  importTemplateQuerySchema,
  questionExportQuerySchema,
  successEnvelope,
} from '@plengo/contracts';
import { authOf } from '../../authorization/guards.js';
import { ok } from '../../lib/app-error.js';
import type { Container } from '../../container.js';
import type { AdminActor } from '../../services/structure-service.js';

const idParams = z.object({ id: z.uuid() });
const actor = (request: FastifyRequest): AdminActor => ({ adminId: authOf(request).userId, ip: request.ip });

const send = (reply: FastifyReply, file: { body: Buffer; contentType: string; filename: string }) =>
  reply
    .header('content-type', file.contentType)
    .header('content-disposition', `attachment; filename="${file.filename}"`)
    .header('cache-control', 'no-store')
    .send(file.body);

/** Bulk question import and export (spec §27). */
export function adminImportRoutes(c: Container): FastifyPluginAsyncZod {
  const tags = ['admin-imports'];
  return async (app) => {
    app.addHook('onRequest', c.guards.requireAdmin);

    app.get(
      '/imports',
      {
        schema: {
          operationId: 'adminListImports',
          tags,
          response: { 200: successEnvelope(importJobListSchema) },
        },
      },
      async () => ok(await c.imports.list()),
    );
    app.post(
      '/imports',
      {
        // A 5 MB file, base64-encoded, plus the JSON around it.
        bodyLimit: Math.ceil((IMPORT_MAX_BYTES * 4) / 3) + 64 * 1024,
        schema: {
          operationId: 'adminCreateImport',
          description: 'Uploads a CSV or XLSX file; a job parses and validates every row.',
          tags,
          body: createImportBodySchema,
          response: { 200: successEnvelope(importJobSchema) },
        },
      },
      async (request) => ok(await c.imports.create(actor(request), request.body)),
    );
    app.get(
      '/imports/template',
      {
        schema: {
          operationId: 'adminImportTemplate',
          description: 'The column layout with an example row, as CSV or XLSX.',
          tags,
          querystring: importTemplateQuerySchema,
        },
      },
      async (request, reply) => send(reply, c.imports.template(request.query.kind, request.query.format)),
    );
    app.get(
      '/imports/:id',
      {
        schema: {
          operationId: 'adminGetImport',
          tags,
          params: idParams,
          response: { 200: successEnvelope(importJobSchema) },
        },
      },
      async (request) => ok(await c.imports.get(request.params.id)),
    );
    app.post(
      '/imports/:id/confirm',
      {
        schema: {
          operationId: 'adminConfirmImport',
          tags,
          params: idParams,
          body: confirmImportBodySchema,
          response: { 200: successEnvelope(importJobSchema) },
        },
      },
      async (request) => ok(await c.imports.confirm(actor(request), request.params.id, request.body)),
    );
    app.get(
      '/questions/export',
      {
        schema: {
          operationId: 'adminExportQuestions',
          description: 'Questions of one type and scope in the import layout, as CSV or XLSX.',
          tags,
          querystring: questionExportQuerySchema,
        },
      },
      async (request, reply) => {
        const q = request.query;
        return send(reply, await c.imports.export(q.kind, q.format, q.subjectId, q.teacherTrackId ?? null));
      },
    );
  };
}
