/**
 * Development seed (spec §40): idempotent, keyed by codes, slugs, emails and names. Later phases
 * extend it with content. Needs the full API environment (apps/api/.env.example works locally).
 *   pnpm --filter @plengo/api seed
 */
import { randomUUID } from 'node:crypto';
import { and, asc, eq, isNull } from 'drizzle-orm';
import sharp from 'sharp';
import {
  academicYears,
  couponBatches,
  coupons,
  educationLevels,
  faculties,
  flashcardDecks,
  lessons,
  mediaFiles,
  promotions,
  questions,
  quizAttempts,
  quizzes,
  subjects,
  teachers,
  teacherTracks,
  units,
  universities,
  users,
  type Db,
} from '@plengo/db';
import { createFastify } from '../app.js';
import { createContainer, type Container } from '../container.js';
import { loadEnv } from '../env.js';
import { InlineQueue } from '../jobs/queue.js';
import { AppError } from '../lib/app-error.js';
import { objectKey } from '../storage/keys.js';
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

type SeedQuestion = {
  type: 'mcq' | 'true_false' | 'written';
  questionText: string;
  lesson?: string;
  explanation?: string;
  options?: [string, boolean][];
  trueFalseAnswer?: boolean;
  acceptedAnswers?: string[];
  draft?: boolean;
  forceFree?: boolean;
};

const PHYSICS_QUESTIONS: SeedQuestion[] = [
  {
    type: 'mcq',
    lesson: 'motion',
    questionText: 'سيارة تتحرك بسرعة ثابتة 20 m/s لمدة 5 s. ما المسافة التي تقطعها؟',
    options: [
      ['100 m', true],
      ['4 m', false],
      ['25 m', false],
      ['15 m', false],
    ],
    explanation: 'المسافة = السرعة × الزمن = 20 × 5 = 100 m',
  },
  {
    type: 'true_false',
    lesson: 'motion',
    questionText: 'السرعة كمية قياسية.',
    trueFalseAnswer: false,
    explanation: 'السرعة كمية متجهة لها مقدار واتجاه.',
  },
  {
    type: 'written',
    lesson: 'forces',
    questionText: 'من صاحب قوانين الحركة الثلاثة؟',
    acceptedAnswers: ['نيوتن', 'إسحاق نيوتن', 'اسحق نيوتن'],
    explanation: 'وضع إسحاق نيوتن قوانين الحركة الثلاثة.',
  },
  {
    type: 'mcq',
    lesson: 'forces',
    questionText: 'ما وحدة قياس القوة في النظام الدولي؟',
    options: [
      ['النيوتن', true],
      ['الجول', false],
      ['الواط', false],
    ],
  },
  {
    type: 'written',
    lesson: 'forces',
    questionText: 'احسب القوة (بالنيوتن) اللازمة لتسريع جسم كتلته 2 kg بتسارع 1.75 m/s².',
    acceptedAnswers: ['3.5', '3.5 نيوتن'],
    explanation: 'F = m × a = 2 × 1.75 = 3.5 N',
  },
  {
    type: 'true_false',
    lesson: 'circuits',
    questionText: 'تتوزع شدة التيار بالتساوي على المقاومات الموصولة على التسلسل.',
    trueFalseAnswer: false,
    explanation: 'في التسلسل تمر شدة التيار نفسها في كل المقاومات.',
  },
  {
    type: 'mcq',
    lesson: 'circuits',
    questionText: 'ما وحدة قياس المقاومة الكهربائية؟',
    options: [
      ['الأوم', true],
      ['الفولط', false],
      ['الأمبير', false],
      ['الكولوم', false],
    ],
  },
  {
    type: 'mcq',
    questionText: 'سؤال قيد الإعداد',
    options: [
      ['أ', true],
      ['ب', false],
    ],
    draft: true,
  },
];

const TRACK_QUESTIONS: SeedQuestion[] = [
  {
    type: 'mcq',
    questionText: 'جسم يسقط سقوطاً حراً من السكون. ما سرعته بعد 2 s؟ (g = 10 m/s²)',
    options: [
      ['20 m/s', true],
      ['10 m/s', false],
      ['5 m/s', false],
    ],
    forceFree: true,
  },
  {
    type: 'true_false',
    questionText: 'التسارع في السقوط الحر ثابت بإهمال مقاومة الهواء.',
    trueFalseAnswer: true,
  },
  {
    type: 'written',
    questionText: 'ما اسم القوة التي تعاكس حركة جسم على سطح خشن؟',
    acceptedAnswers: ['الاحتكاك', 'قوة الاحتكاك'],
  },
];

/** §40 questions: free and premium of each type, in general and track scopes. */
export async function seedQuestions(c: Container) {
  const [admin] = await c.db.select().from(users).where(eq(users.email, 'seed-admin1@example.com'));
  const actor = { adminId: admin!.id, ip: null };
  const physics = (
    await c.db
      .select()
      .from(subjects)
      .where(and(eq(subjects.code, 'g12-physics'), isNull(subjects.deletedAt)))
  )[0]!;
  const track = (
    await c.db
      .select()
      .from(teacherTracks)
      .where(and(eq(teacherTracks.slug, 'ahmad-g12-physics'), isNull(teacherTracks.deletedAt)))
  )[0]!;
  const physicsLessons = await c.db
    .select()
    .from(lessons)
    .where(and(eq(lessons.subjectId, physics.id), isNull(lessons.deletedAt)));

  let created = 0;
  const add = async (list: SeedQuestion[], teacherTrackId: string | null) => {
    for (const q of list) {
      const [existing] = await c.db
        .select({ id: questions.id })
        .from(questions)
        .where(and(eq(questions.subjectId, physics.id), eq(questions.questionText, q.questionText)));
      if (existing) continue;
      const saved = await c.questions.create(actor, {
        type: q.type,
        subjectId: physics.id,
        teacherTrackId,
        lessonId: q.lesson ? physicsLessons.find((l) => l.code === q.lesson)?.id : undefined,
        questionText: q.questionText,
        explanation: q.explanation ?? null,
        options: q.options?.map(([text, isCorrect]) => ({ text, isCorrect })),
        trueFalseAnswer: q.trueFalseAnswer,
        acceptedAnswers: q.acceptedAnswers,
        publish: !q.draft,
      });
      if (q.forceFree) await c.questions.setFree(actor, saved.id, 'free');
      created++;
    }
  };
  await add(PHYSICS_QUESTIONS, null);
  await add(TRACK_QUESTIONS, track.id);
  return created;
}

/** A card image rendered from text and processed like an upload (dev seed only). */
async function seedImage(c: Container, kind: 'flashcard' | 'cover', lines: string[], background: string) {
  const id = randomUUID();
  const texts = lines
    .map(
      (line, i) =>
        `<text x="540" y="${300 + i * 140}" font-size="${i === 0 ? 72 : 88}" fill="${i === 0 ? '#ffffff' : '#fde68a'}" text-anchor="middle" font-family="sans-serif">${line}</text>`,
    )
    .join('');
  const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="1080" height="720"><rect width="100%" height="100%" fill="${background}"/>${texts}</svg>`;
  const png = await sharp(Buffer.from(svg)).png().toBuffer();
  const storageKey = objectKey(c.env.APP_ENV, 'original', id, 'original');
  await c.storage.put('private', storageKey, png, 'image/png');
  await c.db.insert(mediaFiles).values({
    id,
    bucket: kind === 'cover' ? 'public' : 'private',
    storageKey,
    kind,
    mimeType: 'image/png',
    originalSize: png.length,
  });
  await c.media.process({ mediaId: id });
  return id;
}

const DECKS: {
  titleAr: string;
  lesson?: string;
  track?: boolean;
  cards: [front: string[], back: string[]][];
}[] = [
  {
    titleAr: 'قوانين نيوتن',
    lesson: 'forces',
    cards: [
      [['القانون الأول لنيوتن'], ['يبقى الجسم ساكناً', 'أو متحركاً بسرعة ثابتة']],
      [['القانون الثاني لنيوتن'], ['F = m × a']],
      [['القانون الثالث لنيوتن'], ['لكل فعل رد فعل', 'مساوٍ له ومعاكس']],
      [['وحدة القوة'], ['النيوتن N', '1 N = 1 kg·m/s²']],
    ],
  },
  {
    titleAr: 'بطاقات أ. أحمد: السقوط الحر',
    track: true,
    cards: [
      [['تسارع الجاذبية الأرضية'], ['g ≈ 9.8 m/s²']],
      [['سرعة جسم يسقط من السكون'], ['v = g × t']],
      [['المسافة في السقوط الحر'], ['d = ½ g t²']],
    ],
  },
];

/** §40: an official general deck and one track deck (Grade 12 Physics). */
export async function seedFlashcards(c: Container) {
  const [admin] = await c.db.select().from(users).where(eq(users.email, 'seed-admin1@example.com'));
  const actor = { adminId: admin!.id, ip: null };
  const physics = (
    await c.db
      .select()
      .from(subjects)
      .where(and(eq(subjects.code, 'g12-physics'), isNull(subjects.deletedAt)))
  )[0]!;
  const track = (
    await c.db
      .select()
      .from(teacherTracks)
      .where(and(eq(teacherTracks.slug, 'ahmad-g12-physics'), isNull(teacherTracks.deletedAt)))
  )[0]!;
  const physicsLessons = await c.db
    .select()
    .from(lessons)
    .where(and(eq(lessons.subjectId, physics.id), isNull(lessons.deletedAt)));

  let created = 0;
  for (const d of DECKS) {
    const [existing] = await c.db
      .select({ id: flashcardDecks.id })
      .from(flashcardDecks)
      .where(and(eq(flashcardDecks.titleAr, d.titleAr), isNull(flashcardDecks.deletedAt)));
    if (existing) continue;
    const deck = await c.flashcards.createDeck(actor, {
      subjectId: physics.id,
      teacherTrackId: d.track ? track.id : null,
      lessonId: d.lesson ? physicsLessons.find((l) => l.code === d.lesson)?.id : undefined,
      titleAr: d.titleAr,
      coverMediaId: await seedImage(c, 'cover', [d.titleAr], '#134e4a'),
    });
    for (const [front, back] of d.cards) {
      await c.flashcards.createCard(actor, deck.id, {
        frontMediaId: await seedImage(c, 'flashcard', front, '#0f766e'),
        backMediaId: await seedImage(c, 'flashcard', ['', ...back], '#1e3a8a'),
      });
    }
    await c.flashcards.setDeckStatus(actor, deck.id, 'published');
    created++;
  }
  return created;
}

/**
 * §40 quizzes on Grade 12 Physics: a curated quiz (both modes), a mixed free/premium quiz and a
 * timed exam-only mock exam. Student 1 also gets a finished attempt (so mistakes and statistics
 * have data) and two bookmarks.
 */
export async function seedLearning(c: Container) {
  const [admin] = await c.db.select().from(users).where(eq(users.email, 'seed-admin1@example.com'));
  const actor = { adminId: admin!.id, ip: null };
  const physics = (
    await c.db
      .select()
      .from(subjects)
      .where(and(eq(subjects.code, 'g12-physics'), isNull(subjects.deletedAt)))
  )[0]!;
  const general = await c.db
    .select()
    .from(questions)
    .where(
      and(
        eq(questions.subjectId, physics.id),
        isNull(questions.teacherTrackId),
        eq(questions.status, 'published'),
        isNull(questions.deletedAt),
      ),
    )
    .orderBy(asc(questions.sortOrder));
  const physicsLessons = await c.db
    .select()
    .from(lessons)
    .where(and(eq(lessons.subjectId, physics.id), isNull(lessons.deletedAt)));
  const motion = physicsLessons.find((l) => l.code === 'motion');
  const free = general.filter((q) => q.isFree);

  const QUIZZES = [
    {
      titleAr: 'مراجعة درس الحركة',
      lessonId: motion?.id ?? null,
      questionIds: free.slice(0, 3).map((q) => q.id),
      settings: { allowedModes: 'both' as const, passingScorePercent: 60 },
      free: 'free' as const,
    },
    {
      titleAr: 'اختبار شامل في الفيزياء',
      lessonId: null,
      questionIds: general.map((q) => q.id),
      settings: { allowedModes: 'both' as const, shuffleOptions: true },
      free: 'paid' as const,
    },
    {
      titleAr: 'امتحان تجريبي — فيزياء البكالوريا',
      lessonId: null,
      questionIds: general.map((q) => q.id),
      settings: {
        isMockExam: true,
        allowedModes: 'exam' as const,
        timeLimitSeconds: 20 * 60,
        passingScorePercent: 50,
        shuffleQuestions: true,
      },
      free: 'paid' as const,
    },
  ];
  let created = 0;
  for (const q of QUIZZES) {
    const [existing] = await c.db
      .select({ id: quizzes.id })
      .from(quizzes)
      .where(and(eq(quizzes.titleAr, q.titleAr), isNull(quizzes.deletedAt)));
    if (existing) continue;
    const detail = await c.quizzes.create(actor, {
      subjectId: physics.id,
      teacherTrackId: null,
      lessonId: q.lessonId,
      titleAr: q.titleAr,
      questionIds: q.questionIds,
      ...q.settings,
    });
    await c.quizzes.setStatus(actor, detail.quiz.id, 'published');
    await c.quizzes.setFree(actor, detail.quiz.id, q.free);
    created++;
  }

  // Student 1: one finished practice attempt with a mistake, and two bookmarks.
  const [s1] = await c.db.select().from(users).where(eq(users.email, 'student1@example.com'));
  const [mixed] = await c.db
    .select()
    .from(quizzes)
    .where(and(eq(quizzes.titleAr, QUIZZES[1]!.titleAr), isNull(quizzes.deletedAt)));
  const [done] = await c.db
    .select({ id: quizAttempts.id })
    .from(quizAttempts)
    .where(eq(quizAttempts.userId, s1!.id));
  if (!done && mixed) {
    const a = await c.attempts.start(s1!.id, {
      clientAttemptId: randomUUID(),
      source: 'curated',
      mode: 'practice',
      quizId: mixed.id,
    });
    for (const [i, q] of a.questions.slice(0, 4).entries()) {
      const correct = q.options.length
        ? (await c.questions.adminGet(q.questionId)).options.find((o) => o.isCorrect)
        : null;
      const wrong = q.options.find((o) => o.id !== correct?.id);
      // Two right, two wrong: the wrong ones land in the mistake bank.
      const pick = i % 2 === 0 ? correct : wrong;
      if (q.type === 'written') {
        await c.attempts.check(s1!.id, a.attempt.id, q.questionId, {
          writtenAnswer: i % 2 === 0 ? 'نيوتن' : 'لا أعرف',
        });
      } else if (pick) {
        await c.attempts.check(s1!.id, a.attempt.id, q.questionId, { selectedOptionId: pick.id });
      }
    }
    await c.attempts.submit(s1!.id, a.attempt.id, { answers: [] });
  }
  const [firstDeck] = await c.db
    .select({ id: flashcardDecks.id })
    .from(flashcardDecks)
    .where(and(eq(flashcardDecks.subjectId, physics.id), isNull(flashcardDecks.teacherTrackId)));
  if (general[0]) await c.learning.addBookmark(s1!.id, 'question', general[0].id);
  if (firstDeck) await c.learning.addBookmark(s1!.id, 'deck', firstDeck.id);
  return created;
}

if (import.meta.url === `file://${process.argv[1]}`) {
  const env = loadEnv();
  const queue = new InlineQueue();
  const c = createContainer(env, createFastify({ logger: { level: 'warn' } }).log, { jobs: queue });
  try {
    await seedStructure(c.db);
    await seedTeachers(c.db);
    const access = await seedAccess(c, queue);
    const createdQuestions = await seedQuestions(c);
    const createdDecks = await seedFlashcards(c);
    const createdQuizzes = await seedLearning(c);
    console.log(
      `structure, teachers, access, questions, flashcards and quizzes seeded (${createdQuestions} new questions, ${createdDecks} new decks, ${createdQuizzes} new quizzes)`,
    );
    console.log(`students: ${access.students.join(', ')} · admins: ${access.admins.join(', ')}`);
    console.log(`password for all seed accounts: ${SEED_PASSWORD} (admins enroll in 2FA at first login)`);
    console.log('coupon batch (permanent, Grade 12 Physics):');
    for (const { code, status } of access.codes) console.log(`  ${code}  ${status}`);
  } finally {
    await c.pool.end();
  }
}
