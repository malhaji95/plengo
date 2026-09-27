import { pgEnum } from 'drizzle-orm/pg-core';

export const userRoleEnum = pgEnum('user_role', ['student', 'admin']);
export const userStatusEnum = pgEnum('user_status', ['active', 'disabled']);
export const sessionPlatformEnum = pgEnum('session_platform', ['android', 'ios', 'web', 'admin']);
export const mediaKindEnum = pgEnum('media_kind', [
  'flashcard',
  'banner',
  'teacher',
  'cover',
  'user-card',
  'import',
  'original',
]);
export const mediaBucketEnum = pgEnum('media_bucket', ['public', 'private']);
export const mediaStatusEnum = pgEnum('media_status', ['pending', 'ready', 'failed']);
