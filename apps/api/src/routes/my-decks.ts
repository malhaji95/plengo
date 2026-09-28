import type { FastifyPluginAsyncZod } from 'fastify-type-provider-zod';
import { z } from 'zod';
import {
  createReportBodySchema,
  reportListSchema,
  reportSchema,
  successEnvelope,
  userContentChangesQuerySchema,
  userContentChangesSchema,
  userContentSyncBodySchema,
  userContentSyncResultSchema,
  userDeckCardsSchema,
  userDeckListSchema,
} from '@plengo/contracts';
import { authOf } from '../authorization/guards.js';
import { ok } from '../lib/app-error.js';
import type { Container } from '../container.js';

const idParams = z.object({ id: z.uuid() });

/** Private student decks (spec §13.9) and content problem reports (§21). */
export function myDeckRoutes(c: Container): FastifyPluginAsyncZod {
  return async (app) => {
    app.addHook('onRequest', c.guards.requireUser);

    const tags = ['my-decks'];
    app.get(
      '/my-decks',
      {
        schema: { operationId: 'listMyDecks', tags, response: { 200: successEnvelope(userDeckListSchema) } },
      },
      async (request) => ok(await c.userContent.listDecks(authOf(request).userId)),
    );
    app.get(
      '/my-decks/changes',
      {
        schema: {
          operationId: 'myDeckChanges',
          tags,
          querystring: userContentChangesQuerySchema,
          response: { 200: successEnvelope(userContentChangesSchema) },
        },
      },
      async (request) =>
        ok(await c.userContent.changes(authOf(request).userId, request.query.since, request.query.limit)),
    );
    app.post(
      '/my-decks/sync',
      {
        schema: {
          operationId: 'syncMyDecks',
          tags,
          body: userContentSyncBodySchema,
          response: { 200: successEnvelope(userContentSyncResultSchema) },
        },
      },
      async (request) => ok(await c.userContent.sync(authOf(request).userId, request.body)),
    );
    app.get(
      '/my-decks/:id/cards',
      {
        schema: {
          operationId: 'getMyDeckCards',
          tags,
          params: idParams,
          response: { 200: successEnvelope(userDeckCardsSchema) },
        },
      },
      async (request) => ok(await c.userContent.deckCards(authOf(request).userId, request.params.id)),
    );

    const reportTags = ['reports'];
    app.post(
      '/reports',
      {
        schema: {
          operationId: 'createReport',
          tags: reportTags,
          body: createReportBodySchema,
          response: { 200: successEnvelope(reportSchema) },
        },
      },
      async (request) => ok(await c.reports.create(authOf(request).userId, request.body)),
    );
    app.get(
      '/reports',
      {
        schema: {
          operationId: 'listMyReports',
          tags: reportTags,
          response: { 200: successEnvelope(reportListSchema) },
        },
      },
      async (request) => ok(await c.reports.mine(authOf(request).userId)),
    );
  };
}
