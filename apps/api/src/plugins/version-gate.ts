import type { FastifyInstance } from 'fastify';
import { AppError } from '../lib/app-error.js';
import { compareVersions } from '../lib/version.js';
import type { ConfigService } from '../services/config-service.js';

/**
 * Server-side force-update (spec §10.2): clients send X-App-Platform and X-App-Version; below the
 * platform's minSupportedVersion every endpoint except config/health answers APP_UPDATE_REQUIRED.
 */
export function registerVersionGate(app: FastifyInstance, config: ConfigService) {
  app.addHook('onRequest', async (request) => {
    const platform = request.headers['x-app-platform'];
    const version = request.headers['x-app-version'];
    if (typeof platform !== 'string' || typeof version !== 'string') return;
    if (platform !== 'android' && platform !== 'ios' && platform !== 'web') return;
    const url = request.url;
    if (url.startsWith('/api/v1/config') || url.startsWith('/health') || url.startsWith('/ready')) return;
    const { minSupportedVersion } = await config.getRemoteConfig();
    if (compareVersions(version, minSupportedVersion[platform]) < 0) {
      throw new AppError('APP_UPDATE_REQUIRED');
    }
  });
}
