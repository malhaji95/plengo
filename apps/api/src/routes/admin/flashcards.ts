import type { FastifyRequest } from 'fastify';
import type { FastifyPluginAsyncZod } from 'fastify-type-provider-zod';
import { z } from 'zod';
import {
  adminCardListSchema,
  bulkCardsBodySchema,
  adminCardSchema,
  adminDeckListSchema,
  adminDeckQuerySchema,
  adminDeckSchema,
  createCardBodySchema,
  createDeckBodySchema,
  deletedSchema,
  questionFreeBodySchema,
  questionReorderBodySchema,
  questionStatusBodySchema,
  reorderedSchema,
  successEnvelope,
  updateCardBodySchema,
  updateDeckBodySchema,
} from '@plengo/contracts';
import { authOf } from '../../authorization/guards.js';
import { ok } from '../../lib/app-error.js';
import type { Container } from '../../container.js';
import type { AdminActor } from '../../services/structure-service.js';

const idParams = z.object({ id: z.uuid() });
const actor = (request: FastifyRequest): AdminActor => ({ adminId: authOf(request).userId, ip: request.ip });

/** Official decks and cards (spec §13.1, §26.2). Status, free and reorder bodies match questions. */
export function adminFlashcardRoutes(c: Container): FastifyPluginAsyncZod {
  const tags = ['admin-flashcards'];
  const f = c.flashcards;

  return async (app) => {
    app.addHook('onRequest', c.guards.requireAdmin);

    app.get(
      '/decks',
      {
        schema: {
          operationId: 'adminListDecks',
          tags,
          querystring: adminDeckQuerySchema,
          response: { 200: successEnvelope(adminDeckListSchema) },
        },
      },
      async (request) => ok(await f.adminList(request.query)),
    );
    app.get(
      '/decks/:id',
      {
        schema: {
          operationId: 'adminGetDeck',
          tags,
          params: idParams,
          response: { 200: successEnvelope(adminDeckSchema) },
        },
      },
      async (request) => ok(await f.adminGet(request.params.id)),
    );
    app.post(
      '/decks',
      {
        schema: {
          operationId: 'adminCreateDeck',
          tags,
          body: createDeckBodySchema,
          response: { 200: successEnvelope(adminDeckSchema) },
        },
      },
      async (request) => ok(await f.createDeck(actor(request), request.body)),
    );
    app.patch(
      '/decks/:id',
      {
        schema: {
          operationId: 'adminUpdateDeck',
          tags,
          params: idParams,
          body: updateDeckBodySchema,
          response: { 200: successEnvelope(adminDeckSchema) },
        },
      },
      async (request) => ok(await f.updateDeck(actor(request), request.params.id, request.body)),
    );
    app.post(
      '/decks/:id/status',
      {
        schema: {
          operationId: 'adminSetDeckStatus',
          tags,
          params: idParams,
          body: questionStatusBodySchema,
          response: { 200: successEnvelope(adminDeckSchema) },
        },
      },
      async (request) => ok(await f.setDeckStatus(actor(request), request.params.id, request.body.status)),
    );
    app.put(
      '/decks/:id/free',
      {
        schema: {
          operationId: 'adminSetDeckFree',
          tags,
          params: idParams,
          body: questionFreeBodySchema,
          response: { 200: successEnvelope(adminDeckSchema) },
        },
      },
      async (request) => ok(await f.setDeckFree(actor(request), request.params.id, request.body.mode)),
    );
    app.post(
      '/decks/reorder',
      {
        schema: {
          operationId: 'adminReorderDecks',
          tags,
          body: questionReorderBodySchema,
          response: { 200: successEnvelope(reorderedSchema) },
        },
      },
      async (request) => ok(await f.reorderDecks(actor(request), request.body.ids)),
    );
    app.delete(
      '/decks/:id',
      {
        schema: {
          operationId: 'adminDeleteDeck',
          tags,
          params: idParams,
          response: { 200: successEnvelope(deletedSchema) },
        },
      },
      async (request) => ok(await f.removeDeck(actor(request), request.params.id)),
    );

    app.get(
      '/decks/:id/cards',
      {
        schema: {
          operationId: 'adminListCards',
          tags,
          params: idParams,
          response: { 200: successEnvelope(adminCardListSchema) },
        },
      },
      async (request) => ok(await f.adminCards(request.params.id)),
    );
    app.post(
      '/decks/:id/cards',
      {
        schema: {
          operationId: 'adminCreateCard',
          tags,
          params: idParams,
          body: createCardBodySchema,
          response: { 200: successEnvelope(adminCardSchema) },
        },
      },
      async (request) => ok(await f.createCard(actor(request), request.params.id, request.body)),
    );
    app.post(
      '/decks/:id/cards/bulk',
      {
        schema: {
          operationId: 'adminBulkCreateCards',
          description: 'Flashcard bulk upload (spec §27): image pairs already uploaded and processed.',
          tags,
          params: idParams,
          body: bulkCardsBodySchema,
          response: { 200: successEnvelope(adminCardListSchema) },
        },
      },
      async (request) => ok(await f.createCards(actor(request), request.params.id, request.body.cards)),
    );
    app.post(
      '/decks/:id/cards/reorder',
      {
        schema: {
          operationId: 'adminReorderCards',
          tags,
          params: idParams,
          body: questionReorderBodySchema,
          response: { 200: successEnvelope(reorderedSchema) },
        },
      },
      async (request) => ok(await f.reorderCards(actor(request), request.params.id, request.body.ids)),
    );
    app.patch(
      '/cards/:id',
      {
        schema: {
          operationId: 'adminUpdateCard',
          tags,
          params: idParams,
          body: updateCardBodySchema,
          response: { 200: successEnvelope(adminCardSchema) },
        },
      },
      async (request) => ok(await f.updateCard(actor(request), request.params.id, request.body)),
    );
    app.delete(
      '/cards/:id',
      {
        schema: {
          operationId: 'adminDeleteCard',
          tags,
          params: idParams,
          response: { 200: successEnvelope(deletedSchema) },
        },
      },
      async (request) => ok(await f.removeCard(actor(request), request.params.id)),
    );
  };
}
