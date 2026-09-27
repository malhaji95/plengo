/**
 * Development seed (spec §40): idempotent, keyed by codes, slugs, emails and names. Later phases
 * extend it with content. Needs the full API environment (apps/api/.env.example works locally).
 *   pnpm --filter @plengo/api seed
 */
import { and, eq, isNull } from 'drizzle-orm';
import {
  couponBatches,
  coupons,
  promotions,
  academicYears,
  educationLevels,
  faculties,
  lessons,
  subjects,
  teacherTracks,
  teachers,
  units,
  universities,
  type Db,
} from '@plengo/db';
import { createFastify } from '../app.js';
import { createContainer, type Container } from '../container.js';
import { loadEnv } from '../env.js';
import { InlineQueue } from '../jobs/queue.js';
import { AppError } from '../lib/app-error.js';
import { createCouponCrypto, formatCouponCode } from '../lib/coupon-code.js';
import { subjectScope, trackScope } from '../services/access-service.js';

type SeedSubject = {
  code: string;
  nameAr: string;
  units?: { code: string; titleAr: string; lessons: { code: string; titleAr: string }[] }[];
  looseLessons?: { code: string; titleAr: string }[];
};

const SCHOOL_SUBJECTS: Record<string, SeedSubject[]> = {
  'grade-9': [
    { code: 'g9-math', nameAr: 'الرياضيات' },
    { code: 'g9-physics', nameAr: 'الفيزياء' },
  ],
  'grade-12': [
    {
      code: 'g12-math',
      nameAr: 'الرياضيات',
      units: [
        {
          code: 'calculus',
          titleAr: 'التفاضل والتكامل',
          lessons: [
            { code: 'limits', titleAr: 'النهايات' },
            { code: 'derivatives', titleAr: 'المشتقات' },
          ],
        },
      ],
    },
    {
      code: 'g12-physics',
      nameAr: 'الفيزياء',
      units: [
        {
          code: 'mechanics',
          titleAr: 'الميكانيك',
          lessons: [
            { code: 'motion', titleAr: 'الحركة المستقيمة' },
            { code: 'forces', titleAr: 'القوى وقوانين نيوتن' },
          ],
        },
        {
          code: 'electricity',
          titleAr: 'الكهرباء',
          lessons: [{ code: 'circuits', titleAr: 'الدارات الكهربائية' }],
        },
      ],
      looseLessons: [{ code: 'review', titleAr: 'مراجعة عامة' }],
    },
  ],
};

async function upsert<T extends { id: string }>(
  find: () => Promise<T | undefined>,
  create: () => Promise<T>,
) {
  return (await find()) ?? (await create());
}

async function seedSubject(
  db: Db,
  levelId: string,
  path: Partial<typeof subjects.$inferInsert>,
  s: SeedSubject,
  order: number,
) {
  const subject = await upsert(
    async () =>
      (
        await db
          .select()
          .from(subjects)
          .where(and(eq(subjects.code, s.code), isNull(subjects.deletedAt)))
      )[0],
    async () =>
      (
        await db
          .insert(subjects)
          .values({ educationLevelId: levelId, ...path, code: s.code, nameAr: s.nameAr, sortOrder: order })
          .returning()
      )[0]!,
  );
  for (const [ui, u] of (s.units ?? []).entries()) {
    const unit = await upsert(
      async () =>
        (
          await db
            .select()
            .from(units)
            .where(and(eq(units.subjectId, subject.id), eq(units.code, u.code), isNull(units.deletedAt)))
        )[0],
      async () =>
        (
          await db
            .insert(units)
            .values({ subjectId: subject.id, code: u.code, titleAr: u.titleAr, sortOrder: ui })
            .returning()
        )[0]!,
    );
    for (const [li, l] of u.lessons.entries()) {
      await upsert(
        async () =>
          (
            await db
              .select()
              .from(lessons)
              .where(
                and(eq(lessons.subjectId, subject.id), eq(lessons.code, l.code), isNull(lessons.deletedAt)),
              )
          )[0],
        async () =>
          (
            await db
              .insert(lessons)
              .values({
                subjectId: subject.id,
                unitId: unit.id,
                code: l.code,
                titleAr: l.titleAr,
                sortOrder: li,
              })
              .returning()
          )[0]!,
      );
    }
  }
  for (const [li, l] of (s.looseLessons ?? []).entries()) {
    await upsert(
      async () =>
        (
          await db
            .select()
            .from(lessons)
            .where(
              and(eq(lessons.subjectId, subject.id), eq(lessons.code, l.code), isNull(lessons.deletedAt)),
            )
        )[0],
      async () =>
        (
          await db
            .insert(lessons)
            .values({ subjectId: subject.id, code: l.code, titleAr: l.titleAr, sortOrder: li })
            .returning()
        )[0]!,
    );
  }
}

export async function seedStructure(db: Db) {
  const levels = Object.fromEntries((await db.select().from(educationLevels)).map((l) => [l.code, l.id]));
  for (const [levelCode, list] of Object.entries(SCHOOL_SUBJECTS)) {
    for (const [i, s] of list.entries()) await seedSubject(db, levels[levelCode]!, {}, s, i);
  }

  const university = await upsert(
    async () =>
      (
        await db
          .select()
          .from(universities)
          .where(and(eq(universities.code, 'sample-university'), isNull(universities.deletedAt)))
      )[0],
    async () =>
      (
        await db
          .insert(universities)
          .values({ code: 'sample-university', nameAr: 'جامعة تجريبية' })
          .returning()
      )[0]!,
  );
  const faculty = await upsert(
    async () =>
      (
        await db
          .select()
          .from(faculties)
          .where(
            and(
              eq(faculties.universityId, university.id),
              eq(faculties.code, 'sample-faculty'),
              isNull(faculties.deletedAt),
            ),
          )
      )[0],
    async () =>
      (
        await db
          .insert(faculties)
          .values({ universityId: university.id, code: 'sample-faculty', nameAr: 'كلية تجريبية' })
          .returning()
      )[0]!,
  );
  const year = await upsert(
    async () =>
      (
        await db
          .select()
          .from(academicYears)
          .where(
            and(
              eq(academicYears.facultyId, faculty.id),
              eq(academicYears.code, 'year-1'),
              isNull(academicYears.deletedAt),
            ),
          )
      )[0],
    async () =>
      (
        await db
          .insert(academicYears)
          .values({ facultyId: faculty.id, code: 'year-1', nameAr: 'السنة الأولى' })
          .returning()
      )[0]!,
  );
  await seedSubject(
    db,
    levels['college']!,
    { universityId: university.id, facultyId: faculty.id, academicYearId: year.id },
    { code: 'sample-subject', nameAr: 'مادة تجريبية', looseLessons: [{ code: 'intro', titleAr: 'مقدمة' }] },
    0,
  );
}

/** §40: two teachers with one track each. */
export async function seedTeachers(db: Db) {
  const seeds = [
    {
      slug: 'ahmad',
      nameAr: 'أ. أحمد',
      shortDescription: 'مدرّس فيزياء للشهادة الثانوية',
      track: { slug: 'ahmad-g12-physics', titleAr: 'أ. أحمد — فيزياء بكالوريا', subjectCode: 'g12-physics' },
    },
    {
      slug: 'sara',
      nameAr: 'أ. سارة',
      shortDescription: 'مدرّسة رياضيات للصف التاسع',
      track: { slug: 'sara-g9-math', titleAr: 'أ. سارة — رياضيات تاسع', subjectCode: 'g9-math' },
    },
  ];
  for (const [i, t] of seeds.entries()) {
    const teacher = await upsert(
      async () =>
        (
          await db
            .select()
            .from(teachers)
            .where(and(eq(teachers.slug, t.slug), isNull(teachers.deletedAt)))
        )[0],
      async () =>
        (
          await db
            .insert(teachers)
            .values({ slug: t.slug, nameAr: t.nameAr, shortDescription: t.shortDescription, sortOrder: i })
            .returning()
        )[0]!,
    );
    const [subject] = await db
      .select()
      .from(subjects)
      .where(and(eq(subjects.code, t.track.subjectCode), isNull(subjects.deletedAt)));
    if (!subject) continue;
    await upsert(
      async () =>
        (
          await db
            .select()
            .from(teacherTracks)
            .where(and(eq(teacherTracks.slug, t.track.slug), isNull(teacherTracks.deletedAt)))
        )[0],
      async () =>
        (
          await db
            .insert(teacherTracks)
            .values({
              teacherId: teacher.id,
              subjectId: subject.id,
              slug: t.track.slug,
              titleAr: t.track.titleAr,
            })
            .returning()
        )[0]!,
    );
  }
}

const SEED_PASSWORD = 'seed-pass-12345';
const SEED_BATCH = 'بذرة — فيزياء بكالوريا';

async function seedUser(c: Container, email: string, name: string, role: 'student' | 'admin') {
  const existing = await c.usersRepo.findByEmail(email);
  if (existing) return existing.id;
  const res = await c.auth.api.signUpEmail({ body: { name, email, password: SEED_PASSWORD } });
  await c.usersRepo.setRoleAndVerified(res.user.id, role, true);
  const levelId =
    role === 'student'
      ? (await c.db.select().from(educationLevels).where(eq(educationLevels.code, 'grade-12')))[0]?.id
      : undefined;
  await c.usersRepo.upsertProfile({ userId: res.user.id, fullName: name, educationLevelId: levelId ?? null });
  return res.user.id;
}

const ignoreAlreadyEntitled = (err: unknown) => {
  if (!(err instanceof AppError && err.code === 'ALREADY_ENTITLED')) throw err;
};

/**
 * §40 access data: 2 admins (2FA enrollment pending), 2 students with entitlements, a 10-code
 * permanent Grade 12 Physics batch (plaintext printed), free rules, and a past-dated promotion.
 */
export async function seedAccess(c: Container, queue: InlineQueue) {
  const admin1 = await seedUser(c, 'seed-admin1@example.com', 'مشرف أول', 'admin');
  await seedUser(c, 'seed-admin2@example.com', 'مشرف ثانٍ', 'admin');
  const student1 = await seedUser(c, 'student1@example.com', 'الطالب الأول', 'student');
  const student2 = await seedUser(c, 'student2@example.com', 'الطالبة الثانية', 'student');
  const actor = { adminId: admin1, ip: null };

  const subjectByCode = async (code: string) =>
    (
      await c.db
        .select()
        .from(subjects)
        .where(and(eq(subjects.code, code), isNull(subjects.deletedAt)))
    )[0]!;
  const trackBySlug = async (slug: string) =>
    (
      await c.db
        .select()
        .from(teacherTracks)
        .where(and(eq(teacherTracks.slug, slug), isNull(teacherTracks.deletedAt)))
    )[0]!;
  const physics = await subjectByCode('g12-physics');
  const math = await subjectByCode('g12-math');
  const ahmadTrack = await trackBySlug('ahmad-g12-physics');
  const saraTrack = await trackBySlug('sara-g9-math');

  // Student 1: permanent subject entitlement (Grade 12 Mathematics, so the Physics codes below can
  // still be tried with this account). Student 2: temporary track entitlement ending in 7 days.
  await c.access
    .grant(actor, student1, { scope: subjectScope(math.id), permanentAccess: true })
    .catch(ignoreAlreadyEntitled);
  await c.access
    .grant(actor, student2, { scope: trackScope(ahmadTrack.id), accessDurationDays: 7 })
    .catch(ignoreAlreadyEntitled);

  let [batch] = await c.db.select().from(couponBatches).where(eq(couponBatches.name, SEED_BATCH));
  if (!batch) {
    const created = await c.coupons.createBatch(actor, {
      name: SEED_BATCH,
      distributorName: 'بيانات تجريبية',
      scope: subjectScope(physics.id),
      quantity: 10,
      permanentAccess: true,
    });
    await queue.drain(c.jobHandlers);
    [batch] = await c.db.select().from(couponBatches).where(eq(couponBatches.id, created.id));
  }

  const rules = await c.freeRules.list();
  const hasRule = (scopeId: string) =>
    rules.some((r) => (r.scope.teacherTrackId ?? r.scope.subjectId) === scopeId && r.contentKind === 'all');
  if (!hasRule(physics.id)) {
    await c.freeRules.upsert(actor, {
      scope: subjectScope(physics.id),
      contentKind: 'all',
      ruleType: 'first_n_items',
      ruleValue: 5,
    });
  }
  if (!hasRule(saraTrack.id)) {
    await c.freeRules.upsert(actor, {
      scope: trackScope(saraTrack.id),
      contentKind: 'all',
      ruleType: 'manual',
    });
  }
  await queue.drain(c.jobHandlers);

  const promoTitle = 'عرض تجريبي منتهٍ';
  const [promo] = await c.db.select().from(promotions).where(eq(promotions.titleAr, promoTitle));
  if (!promo) {
    const day = 86_400_000;
    await c.promotions.create(actor, {
      scope: subjectScope(physics.id),
      titleAr: promoTitle,
      startsAt: new Date(Date.now() - 30 * day).toISOString(),
      endsAt: new Date(Date.now() - 23 * day).toISOString(),
      isActive: false,
    });
  }

  const crypto = createCouponCrypto(c.env.COUPON_HMAC_SECRET, c.env.COUPON_ENCRYPTION_KEY);
  const codes = await c.db.select().from(coupons).where(eq(coupons.batchId, batch!.id));
  return {
    codes: codes.map((row) => ({
      code: formatCouponCode(crypto.decrypt(row.codeEncrypted)),
      status: row.status,
    })),
    students: ['student1@example.com', 'student2@example.com'],
    admins: ['seed-admin1@example.com', 'seed-admin2@example.com'],
  };
}

if (import.meta.url === `file://${process.argv[1]}`) {
  const env = loadEnv();
  const queue = new InlineQueue();
  const c = createContainer(env, createFastify({ logger: { level: 'warn' } }).log, { jobs: queue });
  try {
    await seedStructure(c.db);
    await seedTeachers(c.db);
    const access = await seedAccess(c, queue);
    console.log('structure, teachers and access seeded');
    console.log(`students: ${access.students.join(', ')} · admins: ${access.admins.join(', ')}`);
    console.log(`password for all seed accounts: ${SEED_PASSWORD} (admins enroll in 2FA at first login)`);
    console.log('coupon batch (permanent, Grade 12 Physics):');
    for (const { code, status } of access.codes) console.log(`  ${code}  ${status}`);
  } finally {
    await c.pool.end();
  }
}
