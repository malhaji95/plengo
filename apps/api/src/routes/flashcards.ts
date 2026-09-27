import type { FastifyPluginAsyncZod } from 'fastify-type-provider-zod';
import { z } from 'zod';
import {
  deckCardsSchema,
  deckListQuerySchema,
  dueCardsSchema,
  dueQuerySchema,
  srsStatesPageSchema,
  srsStatesQuerySchema,
  srsSyncBodySchema,
  srsSyncResultSchema,
  studentDeckListSchema,
  studentDeckSchema,
  successEnvelope,
} from '@plengo/contracts';
import { authOf } from '../authorization/guards.js';
import { ok } from '../lib/app-error.js';
import type { Container } from '../container.js';

const idParams = z.object({ id: z.uuid() });

/** Flashcard decks and spaced-repetition sync for students (spec §13, §30.2). */
export function flashcardRoutes(c: Container): FastifyPluginAsyncZod {
  return async (app) => {
    app.addHook('onRequest', c.guards.requireUser);

    const tags = ['flashcards'];
    app.get(
      '/decks',
      {
        schema: {
          operationId: 'listDecks',
          tags,
          querystring: deckListQuerySchema,
          response: { 200: successEnvelope(studentDeckListSchema) },
        },
      },
      async (request) => ok(await c.flashcards.studentDecks(authOf(request).userId, request.query)),
    );
    app.get(
      '/decks/:id',
      {
        schema: {
          operationId: 'getDeck',
          tags,
          params: idParams,
          response: { 200: successEnvelope(studentDeckSchema) },
        },
      },
      async (request) => ok(await c.flashcards.studentDeck(authOf(request).userId, request.params.id)),
    );
    app.get(
      '/decks/:id/cards',
      {
        schema: {
          operationId: 'getDeckCards',
          tags,
          params: idParams,
          response: { 200: successEnvelope(deckCardsSchema) },
        },
      },
      async (request) => ok(await c.flashcards.deckCards(authOf(request).userId, request.params.id)),
    );

    const srsTags = ['srs'];
    app.get(
      '/srs/states',
      {
        schema: {
          operationId: 'listSrsStates',
          tags: srsTags,
          querystring: srsStatesQuerySchema,
          response: { 200: successEnvelope(srsStatesPageSchema) },
        },
      },
      async (request) =>
        ok(await c.srs.states(authOf(request).userId, request.query.since, request.query.limit)),
    );
    app.post(
      '/srs/sync',
      {
        schema: {
          operationId: 'syncSrs',
          tags: srsTags,
          body: srsSyncBodySchema,
          response: { 200: successEnvelope(srsSyncResultSchema) },
        },
      },
      async (request) => {
        const platform = request.headers['x-app-platform'];
        return ok(
          await c.srs.sync(
            authOf(request).userId,
            typeof platform === 'string' ? platform.slice(0, 20) : null,
            request.body,
          ),
        );
      },
    );
    app.get(
      '/srs/due',
      {
        schema: {
          operationId: 'listDueCards',
          tags: srsTags,
          querystring: dueQuerySchema,
          response: { 200: successEnvelope(dueCardsSchema) },
        },
      },
      async (request) => ok(await c.srs.due(authOf(request).userId, request.query.subjectId)),
    );
  };
}
