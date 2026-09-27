import { z } from 'zod';

const perPlatform = z.object({ android: z.string(), ios: z.string(), web: z.string() });

/** GET /api/v1/config (spec §10.2). Nothing payment-related may ever appear here. */
export const remoteConfigSchema = z.object({
  minSupportedVersion: perPlatform,
  latestVersion: perPlatform,
  features: z.object({
    teacherFollowing: z.boolean(),
    randomPractice: z.boolean(),
    studentDecks: z.boolean(),
    streaks: z.boolean(),
    contentReports: z.boolean(),
  }),
  srsDefaults: z.object({ newCardsPerDay: z.number().int(), maxReviewsPerDay: z.number().int() }),
  support: z.object({ email: z.string(), whatsapp: z.string() }),
  privacyPolicyUrl: z.string(),
  termsUrl: z.string(),
});
export type RemoteConfig = z.infer<typeof remoteConfigSchema>;

export const educationLevelSchema = z.object({
  id: z.string(),
  code: z.string(),
  nameAr: z.string(),
  sortOrder: z.number(),
  /** Only the college level has the optional University → Faculty → Academic Year layers. */
  isCollege: z.boolean(),
});
export type EducationLevel = z.infer<typeof educationLevelSchema>;
export const educationLevelListSchema = z.array(educationLevelSchema);

z.globalRegistry.add(remoteConfigSchema, { id: 'RemoteConfig' });
z.globalRegistry.add(educationLevelSchema, { id: 'EducationLevel' });
z.globalRegistry.add(educationLevelListSchema, { id: 'EducationLevelList' });
