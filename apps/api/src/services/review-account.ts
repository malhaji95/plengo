import { eq, inArray } from 'drizzle-orm';
import { educationLevels, subjects } from '@plengo/db';
import type { Container } from '../container.js';
import { subjectScope } from './access-service.js';

/**
 * The App Review / Play review demo account (spec §39 Phase 13): a verified student with permanent
 * access to the listed subjects, so reviewers see premium content without redeeming a coupon (the
 * iOS build may ship with coupon redemption off, §44). Grants are attributed to the named admin and
 * audited like any other.
 */
export async function createReviewAccount(
  c: Container,
  input: {
    email: string;
    name: string;
    password: string;
    levelCode: string;
    subjectCodes: string[];
    grantedByAdminEmail: string;
  },
) {
  const email = input.email.trim().toLowerCase();
  if (await c.usersRepo.findByEmail(email)) throw new Error(`a user with ${email} already exists`);
  const admin = await c.usersRepo.findByEmail(input.grantedByAdminEmail.trim().toLowerCase());
  if (!admin || admin.role !== 'admin' || admin.status !== 'active')
    throw new Error('granting admin not found');
  const [level] = await c.db.select().from(educationLevels).where(eq(educationLevels.code, input.levelCode));
  if (!level) throw new Error(`unknown education level ${input.levelCode}`);
  const found = input.subjectCodes.length
    ? await c.db.select().from(subjects).where(inArray(subjects.code, input.subjectCodes))
    : [];
  const missing = input.subjectCodes.filter((code) => !found.some((s) => s.code === code));
  if (missing.length) throw new Error(`unknown subjects: ${missing.join(', ')}`);

  const res = await c.auth.api.signUpEmail({ body: { name: input.name, email, password: input.password } });
  await c.usersRepo.setRoleAndVerified(res.user.id, 'student', true);
  await c.usersRepo.upsertProfile({ userId: res.user.id, fullName: input.name, educationLevelId: level.id });
  const actor = { adminId: admin.id, ip: null };
  for (const s of found) {
    await c.access.grant(actor, res.user.id, { scope: subjectScope(s.id), permanentAccess: true });
  }
  await c.audit.record({
    actorAdminId: admin.id,
    action: 'review_account.created',
    resourceType: 'user',
    resourceId: res.user.id,
    metadata: { subjects: input.subjectCodes },
  });
  return { userId: res.user.id, subjects: found.map((s) => s.code) };
}
