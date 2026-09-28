import type { FastifyPluginAsyncZod } from 'fastify-type-provider-zod';
import { z } from 'zod';
import {
  attemptListQuerySchema,
  attemptSchema,
  attemptSummaryPageSchema,
  bookmarkBodySchema,
  bookmarkItemTypeSchema,
  bookmarkKeyListSchema,
  bookmarkListSchema,
  bookmarkQuerySchema,
  bookmarkSchema,
  checkAttemptAnswerBodySchema,
  checkResultSchema,
  deletedSchema,
  flashcardStatsSchema,
  mistakeListSchema,
  mistakeQuerySchema,
  progressQuerySchema,
  quizListQuerySchema,
  resumeListSchema,
  saveAnswerBodySchema,
  savedAnswerSchema,
  scopeProgressSchema,
  startAttemptBodySchema,
  statsOverviewSchema,
  statsTrendQuerySchema,
  statsTrendSchema,
  studentQuizListSchema,
  studentQuizSchema,
  subjectStatsSchema,
  submitAttemptBodySchema,
  successEnvelope,
} from '@plengo/contracts';
import { authOf } from '../authorization/guards.js';
import { ok } from '../lib/app-error.js';
import type { Container } from '../container.js';

const idParams = z.object({ id: z.uuid() });
const answerParams = z.object({ id: z.uuid(), questionId: z.uuid() });
const questionParams = z.object({ questionId: z.uuid() });
const bookmarkParams = z.object({ itemType: bookmarkItemTypeSchema, itemId: z.uuid() });

/** Quizzes, attempts, mistake bank, statistics, bookmarks and progress (spec §15–§18, §30.2). */
export function learningRoutes(c: Container): FastifyPluginAsyncZod {
  return async (app) => {
    app.addHook('onRequest', c.guards.requireUser);
    const user = (request: Parameters<typeof authOf>[0]) => authOf(request).userId;

    // ---- quizzes ----
    const quizTags = ['quizzes'];
    app.get(
      '/quizzes',
      {
        schema: {
          operationId: 'listQuizzes',
          tags: quizTags,
          querystring: quizListQuerySchema,
          response: { 200: successEnvelope(studentQuizListSchema) },
        },
      },
      async (request) => ok(await c.quizzes.studentList(user(request), request.query)),
    );
    app.get(
      '/quizzes/:id',
      {
        schema: {
          operationId: 'getQuiz',
          tags: quizTags,
          params: idParams,
          response: { 200: successEnvelope(studentQuizSchema) },
        },
      },
      async (request) => ok(await c.quizzes.studentGet(user(request), request.params.id)),
    );

    // ---- attempts ----
    const tags = ['attempts'];
    app.post(
      '/attempts',
      {
        schema: {
          operationId: 'startAttempt',
          tags,
          body: startAttemptBodySchema,
          response: { 200: successEnvelope(attemptSchema) },
        },
      },
      async (request) => ok(await c.attempts.start(user(request), request.body)),
    );
    app.get(
      '/attempts',
      {
        schema: {
          operationId: 'listAttempts',
          tags,
          querystring: attemptListQuerySchema,
          response: { 200: successEnvelope(attemptSummaryPageSchema) },
        },
      },
      async (request) => ok(await c.attempts.list(user(request), request.query)),
    );
    app.get(
      '/attempts/:id',
      {
        schema: {
          operationId: 'getAttempt',
          tags,
          params: idParams,
          response: { 200: successEnvelope(attemptSchema) },
        },
      },
      async (request) => ok(await c.attempts.get(user(request), request.params.id)),
    );
    app.put(
      '/attempts/:id/answers/:questionId',
      {
        schema: {
          operationId: 'saveAttemptAnswer',
          tags,
          params: answerParams,
          body: saveAnswerBodySchema,
          response: { 200: successEnvelope(savedAnswerSchema) },
        },
      },
      async (request) =>
        ok(await c.attempts.save(user(request), request.params.id, request.params.questionId, request.body)),
    );
    app.post(
      '/attempts/:id/answers/:questionId/check',
      {
        schema: {
          operationId: 'checkAttemptAnswer',
          tags,
          params: answerParams,
          body: checkAttemptAnswerBodySchema,
          response: { 200: successEnvelope(checkResultSchema) },
        },
      },
      async (request) =>
        ok(await c.attempts.check(user(request), request.params.id, request.params.questionId, request.body)),
    );
    app.post(
      '/attempts/:id/submit',
      {
        schema: {
          operationId: 'submitAttempt',
          tags,
          params: idParams,
          body: submitAttemptBodySchema,
          response: { 200: successEnvelope(attemptSchema) },
        },
      },
      async (request) => ok(await c.attempts.submit(user(request), request.params.id, request.body)),
    );

    // ---- mistake bank ----
    app.get(
      '/mistakes',
      {
        schema: {
          operationId: 'listMistakes',
          tags: ['mistakes'],
          querystring: mistakeQuerySchema,
          response: { 200: successEnvelope(mistakeListSchema) },
        },
      },
      async (request) => ok(await c.learning.mistakes(user(request), request.query)),
    );
    app.delete(
      '/mistakes/:questionId',
      {
        schema: {
          operationId: 'removeMistake',
          tags: ['mistakes'],
          params: questionParams,
          response: { 200: successEnvelope(deletedSchema) },
        },
      },
      async (request) => ok(await c.learning.removeMistake(user(request), request.params.questionId)),
    );

    // ---- statistics ----
    const statsTags = ['stats'];
    app.get(
      '/stats/overview',
      {
        schema: {
          operationId: 'getStatsOverview',
          tags: statsTags,
          response: { 200: successEnvelope(statsOverviewSchema) },
        },
      },
      async (request) => ok(await c.stats.overview(user(request))),
    );
    app.get(
      '/stats/subjects/:id',
      {
        schema: {
          operationId: 'getSubjectStats',
          tags: statsTags,
          params: idParams,
          response: { 200: successEnvelope(subjectStatsSchema) },
        },
      },
      async (request) => ok(await c.stats.subject(user(request), request.params.id)),
    );
    app.get(
      '/stats/trend',
      {
        schema: {
          operationId: 'getStatsTrend',
          tags: statsTags,
          querystring: statsTrendQuerySchema,
          response: { 200: successEnvelope(statsTrendSchema) },
        },
      },
      async (request) => ok(await c.stats.trend(user(request), request.query.weeks)),
    );
    app.get(
      '/stats/flashcards',
      {
        schema: {
          operationId: 'getFlashcardStats',
          tags: statsTags,
          response: { 200: successEnvelope(flashcardStatsSchema) },
        },
      },
      async (request) => ok(await c.stats.flashcards(user(request))),
    );

    // ---- bookmarks ----
    const bookmarkTags = ['bookmarks'];
    app.get(
      '/bookmarks',
      {
        schema: {
          operationId: 'listBookmarks',
          tags: bookmarkTags,
          querystring: bookmarkQuerySchema,
          response: { 200: successEnvelope(bookmarkListSchema) },
        },
      },
      async (request) => ok(await c.learning.bookmarks(user(request), request.query)),
    );
    app.get(
      '/bookmarks/keys',
      {
        schema: {
          operationId: 'listBookmarkKeys',
          tags: bookmarkTags,
          response: { 200: successEnvelope(bookmarkKeyListSchema) },
        },
      },
      async (request) => ok(await c.learning.bookmarkKeys(user(request))),
    );
    app.put(
      '/bookmarks',
      {
        schema: {
          operationId: 'addBookmark',
          tags: bookmarkTags,
          body: bookmarkBodySchema,
          response: { 200: successEnvelope(bookmarkSchema) },
        },
      },
      async (request) =>
        ok(await c.learning.addBookmark(user(request), request.body.itemType, request.body.itemId)),
    );
    app.delete(
      '/bookmarks/:itemType/:itemId',
      {
        schema: {
          operationId: 'removeBookmark',
          tags: bookmarkTags,
          params: bookmarkParams,
          response: { 200: successEnvelope(deletedSchema) },
        },
      },
      async (request) =>
        ok(await c.learning.removeBookmark(user(request), request.params.itemType, request.params.itemId)),
    );

    // ---- progress ----
    app.get(
      '/progress',
      {
        schema: {
          operationId: 'getProgress',
          tags: ['progress'],
          querystring: progressQuerySchema,
          response: { 200: successEnvelope(scopeProgressSchema) },
        },
      },
      async (request) =>
        ok(
          await c.learning.progress(
            user(request),
            request.query.subjectId,
            request.query.teacherTrackId ?? null,
          ),
        ),
    );
    app.get(
      '/progress/resume',
      {
        schema: {
          operationId: 'getResume',
          tags: ['progress'],
          response: { 200: successEnvelope(resumeListSchema) },
        },
      },
      async (request) => ok(await c.learning.resume(user(request))),
    );
  };
}
