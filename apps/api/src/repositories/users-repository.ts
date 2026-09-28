import { and, eq } from 'drizzle-orm';
import { accounts, mediaFiles, profiles, users, type Db, type Tx } from '@plengo/db';

type Conn = Db | Tx;

export function createUsersRepository(db: Db) {
  return {
    async findByEmail(email: string, conn: Conn = db) {
      const [row] = await conn.select().from(users).where(eq(users.email, email)).limit(1);
      return row ?? null;
    },

    async findById(id: string, conn: Conn = db) {
      const [row] = await conn.select().from(users).where(eq(users.id, id)).limit(1);
      return row ?? null;
    },

    async credentialPasswordHash(userId: string): Promise<string | null> {
      const [row] = await db
        .select({ password: accounts.password })
        .from(accounts)
        .where(and(eq(accounts.userId, userId), eq(accounts.providerId, 'credential')))
        .limit(1);
      return row?.password ?? null;
    },

    async upsertProfile(input: {
      userId: string;
      fullName: string;
      educationLevelId?: string | null;
      universityId?: string | null;
      facultyId?: string | null;
      academicYearId?: string | null;
    }) {
      await db
        .insert(profiles)
        .values({
          userId: input.userId,
          fullName: input.fullName,
          educationLevelId: input.educationLevelId ?? null,
          universityId: input.universityId ?? null,
          facultyId: input.facultyId ?? null,
          academicYearId: input.academicYearId ?? null,
        })
        .onConflictDoNothing();
    },

    async updateProfile(
      userId: string,
      fields: Partial<{
        fullName: string;
        educationLevelId: string;
        universityId: string | null;
        facultyId: string | null;
        academicYearId: string | null;
        avatarMediaId: string | null;
      }>,
    ) {
      await db
        .update(profiles)
        .set({ ...fields, updatedAt: new Date() })
        .where(eq(profiles.userId, userId));
      if (fields.fullName) {
        await db
          .update(users)
          .set({ name: fields.fullName, updatedAt: new Date() })
          .where(eq(users.id, userId));
      }
    },

    async getMe(userId: string) {
      const [row] = await db
        .select({
          id: users.id,
          email: users.email,
          emailVerified: users.emailVerified,
          role: users.role,
          name: users.name,
          fullName: profiles.fullName,
          educationLevelId: profiles.educationLevelId,
          universityId: profiles.universityId,
          facultyId: profiles.facultyId,
          academicYearId: profiles.academicYearId,
          avatar: mediaFiles,
        })
        .from(users)
        .leftJoin(profiles, eq(profiles.userId, users.id))
        .leftJoin(mediaFiles, eq(mediaFiles.id, profiles.avatarMediaId))
        .where(eq(users.id, userId))
        .limit(1);
      if (!row) return null;
      return {
        id: row.id,
        email: row.email,
        emailVerified: row.emailVerified,
        role: row.role,
        fullName: row.fullName ?? row.name,
        educationLevelId: row.educationLevelId ?? null,
        universityId: row.universityId ?? null,
        facultyId: row.facultyId ?? null,
        academicYearId: row.academicYearId ?? null,
        avatar: row.avatar && !row.avatar.deletedAt && row.avatar.status === 'ready' ? row.avatar : null,
      };
    },

    async getMedia(id: string) {
      const [row] = await db.select().from(mediaFiles).where(eq(mediaFiles.id, id)).limit(1);
      return row ?? null;
    },

    async setRoleAndVerified(userId: string, role: 'student' | 'admin', emailVerified: boolean) {
      await db.update(users).set({ role, emailVerified, updatedAt: new Date() }).where(eq(users.id, userId));
    },
  };
}

export type UsersRepository = ReturnType<typeof createUsersRepository>;
