import { eq } from 'drizzle-orm';
import { appSettings, type Db } from '@plengo/db';
import {
  accessSettingsSchema,
  remoteConfigSchema,
  type AccessSettings,
  type RemoteConfig,
} from '@plengo/contracts';

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
const ACCESS_SETTINGS_KEY = 'access';

/** spec §8.3: a permanent code may replace an active temporary entitlement unless an admin disables it. */
export const DEFAULT_ACCESS_SETTINGS: AccessSettings = { allowTemporaryToPermanentUpgrade: true };
const CACHE_MS = 30_000;

/** Remote config lives in app_settings (admin-editable later); defaults fill any missing keys. */
export function createConfigService(db: Db) {
  let cache: { value: RemoteConfig; at: number } | null = null;

  async function read(key: string) {
    const [row] = await db.select().from(appSettings).where(eq(appSettings.key, key)).limit(1);
    return row?.value ?? null;
  }

  async function write(key: string, value: unknown, adminId: string | null) {
    await db
      .insert(appSettings)
      .values({ key, value, updatedByAdminId: adminId })
      .onConflictDoUpdate({
        target: appSettings.key,
        set: { value, updatedByAdminId: adminId, updatedAt: new Date() },
      });
  }

  return {
    async getRemoteConfig(): Promise<RemoteConfig> {
      if (cache && Date.now() - cache.at < CACHE_MS) return cache.value;
      const stored = ((await read(REMOTE_CONFIG_KEY)) ?? {}) as Partial<RemoteConfig>;
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
      await write(REMOTE_CONFIG_KEY, value, adminId);
      cache = null;
    },

    /** Read on every grant; not cached so an admin change applies to the next redemption. */
    async getAccessSettings(): Promise<AccessSettings> {
      const stored = ((await read(ACCESS_SETTINGS_KEY)) ?? {}) as Partial<AccessSettings>;
      return accessSettingsSchema.parse({ ...DEFAULT_ACCESS_SETTINGS, ...stored });
    },

    async setAccessSettings(value: AccessSettings, adminId: string | null) {
      await write(ACCESS_SETTINGS_KEY, value, adminId);
      return value;
    },
  };
}

export type ConfigService = ReturnType<typeof createConfigService>;
