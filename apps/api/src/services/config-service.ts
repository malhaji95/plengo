import { eq } from 'drizzle-orm';
import { appSettings, type Db } from '@plengo/db';
import { remoteConfigSchema, type RemoteConfig } from '@plengo/contracts';

export const DEFAULT_REMOTE_CONFIG: RemoteConfig = {
  minSupportedVersion: { android: '1.0.0', ios: '1.0.0', web: '1.0.0' },
  latestVersion: { android: '1.0.0', ios: '1.0.0', web: '1.0.0' },
  features: {
    teacherFollowing: true,
    randomPractice: true,
    studentDecks: true,
    streaks: true,
    contentReports: true,
  },
  srsDefaults: { newCardsPerDay: 20, maxReviewsPerDay: 200 },
  support: { email: '', whatsapp: '' },
  privacyPolicyUrl: '',
  termsUrl: '',
};

const REMOTE_CONFIG_KEY = 'remote_config';
const CACHE_MS = 30_000;

/** Remote config lives in app_settings (admin-editable later); defaults fill any missing keys. */
export function createConfigService(db: Db) {
  let cache: { value: RemoteConfig; at: number } | null = null;

  return {
    async getRemoteConfig(): Promise<RemoteConfig> {
      if (cache && Date.now() - cache.at < CACHE_MS) return cache.value;
      const [row] = await db
        .select()
        .from(appSettings)
        .where(eq(appSettings.key, REMOTE_CONFIG_KEY))
        .limit(1);
      const stored = (row?.value ?? {}) as Partial<RemoteConfig>;
      const merged = remoteConfigSchema.parse({
        ...DEFAULT_REMOTE_CONFIG,
        ...stored,
        minSupportedVersion: { ...DEFAULT_REMOTE_CONFIG.minSupportedVersion, ...stored.minSupportedVersion },
        latestVersion: { ...DEFAULT_REMOTE_CONFIG.latestVersion, ...stored.latestVersion },
        features: { ...DEFAULT_REMOTE_CONFIG.features, ...stored.features },
        srsDefaults: { ...DEFAULT_REMOTE_CONFIG.srsDefaults, ...stored.srsDefaults },
        support: { ...DEFAULT_REMOTE_CONFIG.support, ...stored.support },
      });
      cache = { value: merged, at: Date.now() };
      return merged;
    },

    async setRemoteConfig(value: Partial<RemoteConfig>, adminId: string | null) {
      await db
        .insert(appSettings)
        .values({ key: REMOTE_CONFIG_KEY, value, updatedByAdminId: adminId })
        .onConflictDoUpdate({
          target: appSettings.key,
          set: { value, updatedByAdminId: adminId, updatedAt: new Date() },
        });
      cache = null;
    },
  };
}

export type ConfigService = ReturnType<typeof createConfigService>;
