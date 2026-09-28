import { randomUUID } from 'node:crypto';
import cookie from '@fastify/cookie';
import cors from '@fastify/cors';
import rateLimit from '@fastify/rate-limit';
import swagger from '@fastify/swagger';
import Fastify, { type FastifyServerOptions } from 'fastify';
import {
  jsonSchemaTransform,
  jsonSchemaTransformObject,
  serializerCompiler,
  validatorCompiler,
  type ZodTypeProvider,
} from 'fastify-type-provider-zod';
import type { Container } from './container.js';
import { registerCsrf } from './plugins/csrf.js';
import { registerErrorHandling } from './plugins/error-handler.js';
import { registerVersionGate } from './plugins/version-gate.js';
import { accessRoutes } from './routes/access.js';
import { adminAccessRoutes } from './routes/admin/access.js';
import { adminAccountRoutes } from './routes/admin/admins.js';
import { adminReportRoutes } from './routes/admin/reports.js';
import { adminAuthRoutes } from './routes/admin/auth.js';
import { adminFlashcardRoutes } from './routes/admin/flashcards.js';
import { adminQuestionRoutes } from './routes/admin/questions.js';
import { adminQuizRoutes } from './routes/admin/quizzes.js';
import { adminStructureRoutes } from './routes/admin/structure.js';
import { adminTeacherRoutes } from './routes/admin/teachers.js';
import { authRoutes } from './routes/auth.js';
import { catalogRoutes, collegeReferenceRoutes } from './routes/catalog.js';
import { configRoutes } from './routes/config.js';
import { devStorageRoutes } from './routes/dev-storage.js';
import { MemoryStorage } from './storage/memory-storage.js';
import { flashcardRoutes } from './routes/flashcards.js';
import { healthRoutes } from './routes/health.js';
import { learningRoutes } from './routes/learning.js';
import { myDeckRoutes } from './routes/my-decks.js';
import { meRoutes } from './routes/me.js';
import { questionRoutes } from './routes/questions.js';
import { teacherRoutes } from './routes/teachers.js';
import { uploadRoutes } from './routes/uploads.js';

export function loggerOptions(level: string, pretty: boolean): FastifyServerOptions['logger'] {
  return {
    level,
    redact: ['req.headers.authorization', 'req.headers.cookie', 'res.headers["set-cookie"]'],
    ...(pretty ? { transport: { target: 'pino-pretty' } } : {}),
  };
}

/**
 * `trustProxy` is a hop count, not `true`: only the address added by our own proxy is trusted, so
 * a client cannot choose its IP (and so its rate-limit key) with a forged `X-Forwarded-For` (§31).
 */
export function createFastify(options: FastifyServerOptions & { proxyHops?: number } = {}) {
  const { proxyHops = 1, ...rest } = options;
  return Fastify({
    // Trust only the nearest `proxyHops` addresses (our own load balancer).
    trustProxy: (_address: string, hop: number) => hop < proxyHops,
    genReqId: (req) => {
      const incoming = req.headers['x-request-id'];
      return typeof incoming === 'string' && /^[\w-]{8,64}$/.test(incoming) ? incoming : randomUUID();
    },
    ...rest,
  }).withTypeProvider<ZodTypeProvider>();
}

export type App = ReturnType<typeof createFastify>;

/** Registers plugins and routes. `app` is created first so the container can share its logger. */
export async function buildApp(app: App, c: Container): Promise<App> {
  app.setValidatorCompiler(validatorCompiler);
  app.setSerializerCompiler(serializerCompiler);
  app.decorateRequest('auth', null);
  const https = c.env.APP_ENV === 'staging' || c.env.APP_ENV === 'production';
  app.addHook('onRequest', async (request, reply) => {
    void reply.header('x-request-id', request.id);
    // HTTPS only in deployed environments (§31).
    if (https) void reply.header('strict-transport-security', 'max-age=31536000; includeSubDomains');
  });

  registerErrorHandling(app);

  await app.register(swagger, {
    openapi: {
      openapi: '3.1.0',
      info: { title: 'Plengo API', version: '1.0.0' },
      components: {
        securitySchemes: {
          bearer: { type: 'http', scheme: 'bearer', bearerFormat: 'JWT' },
          cookie: { type: 'apiKey', in: 'cookie', name: 'plengo.session_token' },
        },
      },
    },
    transform: jsonSchemaTransform,
    transformObject: jsonSchemaTransformObject,
  });

  const origins = [c.env.APP_WEB_ORIGIN, c.env.ADMIN_ORIGIN];
  await app.register(cors, {
    origin: origins,
    credentials: true,
    methods: ['GET', 'HEAD', 'POST', 'PUT', 'PATCH', 'DELETE'],
    allowedHeaders: [
      'Content-Type',
      'Authorization',
      'X-Requested-With',
      'X-App-Platform',
      'X-App-Version',
      'X-Request-Id',
    ],
    // Content-Disposition carries export file names (coupon batches, §9.6).
    exposedHeaders: ['X-Request-Id', 'Content-Disposition'],
  });
  await app.register(cookie);
  // In-memory limits suit the single V1 API instance; see ADR-006 before scaling horizontally.
  await app.register(rateLimit, { global: false, hook: 'preHandler' });

  registerCsrf(app, origins);
  registerVersionGate(app, c.configService);

  await app.register(healthRoutes(c));
  if (c.storage instanceof MemoryStorage && c.env.APP_ENV !== 'production') {
    await app.register(devStorageRoutes(c.storage), { prefix: '/api/v1/dev-storage' });
  }
  await app.register(configRoutes(c), { prefix: '/api/v1' });
  await app.register(authRoutes(c), { prefix: '/api/v1/auth' });
  await app.register(meRoutes(c), { prefix: '/api/v1' });
  await app.register(uploadRoutes(c, 'student'), { prefix: '/api/v1' });
  await app.register(collegeReferenceRoutes(c), { prefix: '/api/v1' });
  await app.register(catalogRoutes(c), { prefix: '/api/v1' });
  await app.register(teacherRoutes(c), { prefix: '/api/v1' });
  await app.register(accessRoutes(c), { prefix: '/api/v1' });
  await app.register(questionRoutes(c), { prefix: '/api/v1' });
  await app.register(flashcardRoutes(c), { prefix: '/api/v1' });
  await app.register(learningRoutes(c), { prefix: '/api/v1' });
  await app.register(myDeckRoutes(c), { prefix: '/api/v1' });
  await app.register(adminAuthRoutes(c), { prefix: '/api/v1/admin' });
  await app.register(uploadRoutes(c, 'admin'), { prefix: '/api/v1/admin' });
  await app.register(adminStructureRoutes(c), { prefix: '/api/v1/admin' });
  await app.register(adminTeacherRoutes(c), { prefix: '/api/v1/admin' });
  await app.register(adminAccessRoutes(c), { prefix: '/api/v1/admin' });
  await app.register(adminQuestionRoutes(c), { prefix: '/api/v1/admin' });
  await app.register(adminFlashcardRoutes(c), { prefix: '/api/v1/admin' });
  await app.register(adminQuizRoutes(c), { prefix: '/api/v1/admin' });
  await app.register(adminAccountRoutes(c), { prefix: '/api/v1/admin' });
  await app.register(adminReportRoutes(c), { prefix: '/api/v1/admin' });

  return app;
}
