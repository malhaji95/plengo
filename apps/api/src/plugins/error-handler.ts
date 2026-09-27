import * as Sentry from '@sentry/node';
import type { FastifyError, FastifyInstance } from 'fastify';
import { hasZodFastifySchemaValidationErrors, isResponseSerializationError } from 'fastify-type-provider-zod';
import { ERROR_MESSAGES, type ErrorCode } from '@plengo/contracts';
import { AppError } from '../lib/app-error.js';

function envelope(code: ErrorCode, details?: unknown, message: string = ERROR_MESSAGES[code]) {
  return { success: false as const, data: null, error: { code, message, ...(details ? { details } : {}) } };
}

/** Renders every failure as the §30.3 envelope with a §30.4 code. */
export function registerErrorHandling(app: FastifyInstance) {
  app.setNotFoundHandler((_request, reply) => {
    void reply.status(404).send(envelope('NOT_FOUND'));
  });

  app.setErrorHandler((error: FastifyError | AppError, request, reply) => {
    if (error instanceof AppError) {
      return reply.status(error.statusCode).send(envelope(error.code, error.details, error.message));
    }
    if (hasZodFastifySchemaValidationErrors(error)) {
      const details = error.validation.map((v) => ({ path: v.instancePath, message: v.message }));
      return reply.status(400).send(envelope('VALIDATION_ERROR', details));
    }
    if (error.statusCode === 429) {
      return reply.status(429).send(envelope('RATE_LIMITED'));
    }
    if (error.code === 'FST_ERR_CTP_INVALID_MEDIA_TYPE' || error.code === 'FST_ERR_CTP_EMPTY_JSON_BODY') {
      return reply.status(400).send(envelope('VALIDATION_ERROR'));
    }
    if (
      error.statusCode &&
      error.statusCode >= 400 &&
      error.statusCode < 500 &&
      !isResponseSerializationError(error)
    ) {
      return reply.status(error.statusCode).send(envelope('VALIDATION_ERROR'));
    }
    request.log.error({ err: error }, 'unhandled error');
    Sentry.captureException(error);
    return reply.status(500).send(envelope('SERVER_ERROR'));
  });
}
