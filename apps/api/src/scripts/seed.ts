/**
 * Development seed (spec §40), structure part: idempotent, keyed by codes. Later phases extend it
 * with teachers, content, coupons and students.
 *   pnpm --filter @plengo/api seed
 */
import { and, eq, isNull } from 'drizzle-orm';
import {
  academicYears,
  createDb,
  createPool,
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

if (import.meta.url === `file://${process.argv[1]}`) {
  const url = process.env.DATABASE_URL;
  if (!url) throw new Error('DATABASE_URL is required');
  const pool = createPool(url, 1);
  try {
    const db = createDb(pool);
    await seedStructure(db);
    await seedTeachers(db);
    console.log('structure and teachers seeded');
  } finally {
    await pool.end();
  }
}
