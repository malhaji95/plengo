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
import { adminAuthRoutes } from './routes/admin/auth.js';
import { adminStructureRoutes } from './routes/admin/structure.js';
import { authRoutes } from './routes/auth.js';
import { catalogRoutes } from './routes/catalog.js';
import { configRoutes } from './routes/config.js';
import { healthRoutes } from './routes/health.js';
import { meRoutes } from './routes/me.js';
import { uploadRoutes } from './routes/uploads.js';

export function loggerOptions(level: string, pretty: boolean): FastifyServerOptions['logger'] {
  return {
    level,
    redact: ['req.headers.authorization', 'req.headers.cookie', 'res.headers["set-cookie"]'],
    ...(pretty ? { transport: { target: 'pino-pretty' } } : {}),
  };
}

export function createFastify(options: FastifyServerOptions = {}) {
  return Fastify({
    trustProxy: true,
    genReqId: (req) => {
      const incoming = req.headers['x-request-id'];
      return typeof incoming === 'string' && /^[\w-]{8,64}$/.test(incoming) ? incoming : randomUUID();
    },
    ...options,
  }).withTypeProvider<ZodTypeProvider>();
}

export type App = ReturnType<typeof createFastify>;

/** Registers plugins and routes. `app` is created first so the container can share its logger. */
export async function buildApp(app: App, c: Container): Promise<App> {
  app.setValidatorCompiler(validatorCompiler);
  app.setSerializerCompiler(serializerCompiler);
  app.decorateRequest('auth', null);
  app.addHook('onRequest', async (request, reply) => {
    void reply.header('x-request-id', request.id);
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
    exposedHeaders: ['X-Request-Id'],
  });
  await app.register(cookie);
  // In-memory limits suit the single V1 API instance; see ADR-006 before scaling horizontally.
  await app.register(rateLimit, { global: false, hook: 'preHandler' });

  registerCsrf(app, origins);
  registerVersionGate(app, c.configService);

  await app.register(healthRoutes(c));
  await app.register(configRoutes(c), { prefix: '/api/v1' });
  await app.register(authRoutes(c), { prefix: '/api/v1/auth' });
  await app.register(meRoutes(c), { prefix: '/api/v1' });
  await app.register(uploadRoutes(c, 'student'), { prefix: '/api/v1' });
  await app.register(catalogRoutes(c), { prefix: '/api/v1' });
  await app.register(adminAuthRoutes(c), { prefix: '/api/v1/admin' });
  await app.register(uploadRoutes(c, 'admin'), { prefix: '/api/v1/admin' });
  await app.register(adminStructureRoutes(c), { prefix: '/api/v1/admin' });

  return app;
}
