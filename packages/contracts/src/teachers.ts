import { z } from 'zod';
import { scopeAccessSchema } from './access.js';
import { contentCountSchema } from './questions.js';
import { codeSchema, subjectSchema } from './structure.js';

/* Teachers and teacher tracks (spec §7). Slugs share the code format used by imports. */

const text = (max: number) => z.string().trim().max(max);

/** A teacher as students see it. */
export const teacherSchema = z.object({
  id: z.string(),
  nameAr: z.string(),
  slug: z.string(),
  photoUrl: z.string().nullable(),
  shortDescription: z.string().nullable(),
  followerCount: z.number(),
  isFollowing: z.boolean(),
});

export const teacherTrackSchema = z.object({
  id: z.string(),
  teacherId: z.string(),
  teacherNameAr: z.string(),
  subjectId: z.string(),
  subjectNameAr: z.string(),
  educationLevelId: z.string(),
  titleAr: z.string(),
  slug: z.string(),
  description: z.string().nullable(),
  coverUrl: z.string().nullable(),
});

/** A teacher with the long biography, shown on the profile page. */
export const teacherDetailSchema = teacherSchema.extend({ bio: z.string().nullable() });

export const teacherProfileSchema = z.object({
  teacher: teacherDetailSchema,
  tracks: z.array(teacherTrackSchema),
});

/** A track page: the track, its teacher and its subject. Content arrives with Phases 5–7. */
export const trackDetailSchema = z.object({
  track: teacherTrackSchema,
  teacher: teacherSchema,
  subject: subjectSchema,
  /** Access to this track's content (a subject entitlement does not unlock it, §8.1). */
  access: scopeAccessSchema,
  /** Published questions of the track. */
  questionCount: contentCountSchema,
  /** Published flashcard decks of the track. */
  deckCount: contentCountSchema,
});

export const followResultSchema = z.object({ following: z.boolean(), followerCount: z.number() });

export const teacherListSchema = z.array(teacherSchema);
export const teacherTrackListSchema = z.array(teacherTrackSchema);

// ---- admin ----

export const adminTeacherSchema = z.object({
  id: z.string(),
  nameAr: z.string(),
  slug: z.string(),
  photoMediaId: z.string().nullable(),
  photoUrl: z.string().nullable(),
  shortDescription: z.string().nullable(),
  bio: z.string().nullable(),
  isActive: z.boolean(),
  sortOrder: z.number(),
  followerCount: z.number(),
  trackCount: z.number(),
});

export const adminTrackSchema = z.object({
  id: z.string(),
  teacherId: z.string(),
  subjectId: z.string(),
  subjectNameAr: z.string(),
  educationLevelId: z.string(),
  titleAr: z.string(),
  slug: z.string(),
  description: z.string().nullable(),
  coverMediaId: z.string().nullable(),
  coverUrl: z.string().nullable(),
  isActive: z.boolean(),
  sortOrder: z.number(),
});

export const adminTeacherListSchema = z.array(adminTeacherSchema);
export const adminTrackListSchema = z.array(adminTrackSchema);

export const createTeacherBodySchema = z.object({
  nameAr: text(200).min(1),
  slug: codeSchema,
  shortDescription: text(300).nullable().optional(),
  bio: text(5000).nullable().optional(),
  photoMediaId: z.uuid().nullable().optional(),
  isActive: z.boolean().optional(),
});
export const updateTeacherBodySchema = createTeacherBodySchema.partial();

/** The subject of a track is fixed at creation: its content is tied to that subject (§7.3). */
export const createTrackBodySchema = z.object({
  teacherId: z.uuid(),
  subjectId: z.uuid(),
  titleAr: text(200).min(1),
  slug: codeSchema,
  description: text(2000).nullable().optional(),
  coverMediaId: z.uuid().nullable().optional(),
  isActive: z.boolean().optional(),
});
export const updateTrackBodySchema = createTrackBodySchema
  .omit({ teacherId: true, subjectId: true })
  .partial();

export const trackListQuerySchema = z.object({
  teacherId: z.uuid().optional(),
  subjectId: z.uuid().optional(),
});

export type Teacher = z.infer<typeof teacherSchema>;
export type TeacherTrack = z.infer<typeof teacherTrackSchema>;
export type AdminTeacher = z.infer<typeof adminTeacherSchema>;
export type AdminTrack = z.infer<typeof adminTrackSchema>;

const named: [z.ZodType, string][] = [
  [teacherSchema, 'Teacher'],
  [teacherTrackSchema, 'TeacherTrack'],
  [teacherDetailSchema, 'TeacherDetail'],
  [teacherProfileSchema, 'TeacherProfile'],
  [trackDetailSchema, 'TrackDetail'],
  [followResultSchema, 'FollowResult'],
  [teacherListSchema, 'TeacherList'],
  [teacherTrackListSchema, 'TeacherTrackList'],
  [adminTeacherSchema, 'AdminTeacher'],
  [adminTrackSchema, 'AdminTrack'],
  [adminTeacherListSchema, 'AdminTeacherList'],
  [adminTrackListSchema, 'AdminTrackList'],
  [createTeacherBodySchema, 'CreateTeacherRequest'],
  [updateTeacherBodySchema, 'UpdateTeacherRequest'],
  [createTrackBodySchema, 'CreateTrackRequest'],
  [updateTrackBodySchema, 'UpdateTrackRequest'],
];
for (const [schema, id] of named) z.globalRegistry.add(schema, { id });
