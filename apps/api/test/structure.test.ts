import { randomUUID } from 'node:crypto';
import { eq } from 'drizzle-orm';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { auditLogs, lessons } from '@plengo/db';
import {
  body,
  createTestApp,
  enrolledAdminSession,
  levelId,
  tokensFor,
  type TestContext,
} from './helpers.js';

let t: TestContext;
let admin: Record<string, string>;
let student: string;

beforeAll(async () => {
  t = await createTestApp();
  admin = (await enrolledAdminSession(t)).headers;
  student = (await tokensFor(t)).accessToken;
});
afterAll(async () => {
  await t.close();
});

const code = (prefix: string) => `${prefix}-${randomUUID().slice(0, 8)}`;

async function adminCall<T = Record<string, unknown>>(
  method: 'GET' | 'POST' | 'PATCH' | 'PUT' | 'DELETE',
  url: string,
  payload?: object,
) {
  const res = await t.app.inject({
    method,
    url: `/api/v1/admin${url}`,
    headers: admin,
    ...(payload ? { payload } : {}),
  });
  return { status: res.statusCode, ...body<T>(res) };
}

async function studentGet<T = Record<string, unknown>>(url: string) {
  const res = await t.app.inject({
    method: 'GET',
    url: `/api/v1${url}`,
    headers: { authorization: `Bearer ${student}` },
  });
  return { status: res.statusCode, ...body<T>(res) };
}

type Row = { id: string; code: string; sortOrder: number };

async function collegePath() {
  const uni = (await adminCall<Row>('POST', '/universities', { code: code('uni'), nameAr: 'جامعة دمشق' }))
    .data;
  const fac = (
    await adminCall<Row>('POST', '/faculties', {
      universityId: uni.id,
      code: code('fac'),
      nameAr: 'كلية الطب',
    })
  ).data;
  const year = (
    await adminCall<Row>('POST', '/academic-years', {
      facultyId: fac.id,
      code: code('y'),
      nameAr: 'السنة الأولى',
    })
  ).data;
  return { uni, fac, year };
}

describe('admin access', () => {
  it('requires a 2FA-verified admin session', async () => {
    const anon = await t.app.inject({ method: 'GET', url: '/api/v1/admin/universities' });
    expect(anon.statusCode).toBe(401);
    const asStudent = await t.app.inject({
      method: 'GET',
      url: '/api/v1/admin/universities',
      headers: { authorization: `Bearer ${student}` },
    });
    expect(asStudent.statusCode).toBe(403);
  });
});

describe('college hierarchy', () => {
  it('creates universities → faculties → years in order and normalizes codes', async () => {
    const c1 = code('Uni').toUpperCase();
    const a = await adminCall<Row>('POST', '/universities', { code: c1, nameAr: 'أ' });
    const b = await adminCall<Row>('POST', '/universities', { code: code('uni'), nameAr: 'ب' });
    expect(a.status).toBe(200);
    expect(a.data.code).toBe(c1.toLowerCase());
    expect(b.data.sortOrder).toBe(a.data.sortOrder + 1);
  });

  it('rejects a duplicate live code with CODE_TAKEN, and allows reuse after deletion', async () => {
    const c1 = code('dup');
    const first = await adminCall<Row>('POST', '/universities', { code: c1, nameAr: 'أ' });
    const dup = await adminCall('POST', '/universities', { code: c1, nameAr: 'ب' });
    expect(dup.status).toBe(409);
    expect(dup.error).toMatchObject({ code: 'CODE_TAKEN', message: 'هذا الرمز مستخدم مسبقاً' });
    expect((await adminCall('DELETE', `/universities/${first.data.id}`)).status).toBe(200);
    expect((await adminCall('POST', '/universities', { code: c1, nameAr: 'ج' })).status).toBe(200);
  });

  it('rejects malformed codes', async () => {
    const res = await adminCall('POST', '/universities', { code: 'مادة', nameAr: 'أ' });
    expect(res.error?.code).toBe('VALIDATION_ERROR');
  });

  it('refuses to delete a university that still has faculties', async () => {
    const { uni } = await collegePath();
    const res = await adminCall('DELETE', `/universities/${uni.id}`);
    expect(res.status).toBe(409);
    expect(res.error?.code).toBe('RESOURCE_IN_USE');
  });
});

describe('subjects', () => {
  it('derives the university and faculty from the academic year', async () => {
    const { uni, fac, year } = await collegePath();
    const res = await adminCall('POST', '/subjects', {
      educationLevelId: await levelId(t, 'college'),
      academicYearId: year.id,
      code: code('anat'),
      nameAr: 'التشريح',
    });
    expect(res.status).toBe(200);
    expect(res.data).toMatchObject({ universityId: uni.id, facultyId: fac.id, academicYearId: year.id });
  });

  it('accepts a college subject with no intermediate layers', async () => {
    const res = await adminCall('POST', '/subjects', {
      educationLevelId: await levelId(t, 'college'),
      code: code('general'),
      nameAr: 'ثقافة عامة',
    });
    expect(res.data).toMatchObject({ universityId: null, facultyId: null, academicYearId: null });
  });

  it('rejects college layers on school levels and mismatched layers', async () => {
    const { fac, year } = await collegePath();
    const other = await collegePath();
    const school = await adminCall('POST', '/subjects', {
      educationLevelId: await levelId(t, 'grade-12'),
      facultyId: fac.id,
      code: code('x'),
      nameAr: 'س',
    });
    expect(school.error?.code).toBe('VALIDATION_ERROR');
    const mismatch = await adminCall('POST', '/subjects', {
      educationLevelId: await levelId(t, 'college'),
      facultyId: other.fac.id,
      academicYearId: year.id,
      code: code('x'),
      nameAr: 'س',
    });
    expect(mismatch.error?.code).toBe('VALIDATION_ERROR');
  });

  it('moving a subject to another level clears its college path', async () => {
    const { year } = await collegePath();
    const created = await adminCall<Row>('POST', '/subjects', {
      educationLevelId: await levelId(t, 'college'),
      academicYearId: year.id,
      code: code('mv'),
      nameAr: 'مادة',
    });
    const moved = await adminCall('PATCH', `/subjects/${created.data.id}`, {
      educationLevelId: await levelId(t, 'grade-9'),
    });
    expect(moved.data).toMatchObject({ universityId: null, facultyId: null, academicYearId: null });
  });

  it('rejects a cover that is not a ready cover image', async () => {
    const res = await adminCall('POST', '/subjects', {
      educationLevelId: await levelId(t, 'grade-9'),
      code: code('cv'),
      nameAr: 'غلاف',
      coverMediaId: randomUUID(),
    });
    expect(res.error?.code).toBe('VALIDATION_ERROR');
  });
});

describe('units and lessons (spec §6.1)', () => {
  async function subjectWithUnit(level = 'grade-12') {
    const subject = (
      await adminCall<Row>('POST', '/subjects', {
        educationLevelId: await levelId(t, level),
        code: code('s'),
        nameAr: 'مادة',
      })
    ).data;
    const unit = (
      await adminCall<Row>('POST', '/units', { subjectId: subject.id, code: 'u1', titleAr: 'الوحدة الأولى' })
    ).data;
    return { subject, unit };
  }

  it('refuses a lesson whose unit belongs to another subject', async () => {
    const a = await subjectWithUnit();
    const b = await subjectWithUnit();
    const res = await adminCall('POST', '/lessons', {
      subjectId: a.subject.id,
      unitId: b.unit.id,
      code: 'l1',
      titleAr: 'درس',
    });
    expect(res.error?.code).toBe('VALIDATION_ERROR');
  });

  it('the database itself rejects a cross-subject lesson', async () => {
    const a = await subjectWithUnit();
    const b = await subjectWithUnit();
    await expect(
      t.c.db.insert(lessons).values({ subjectId: a.subject.id, unitId: b.unit.id, code: 'x', titleAr: 'x' }),
    ).rejects.toMatchObject({ cause: { code: '23503', constraint: 'lessons_unit_subject_fk' } });
  });

  it('unit codes are unique per subject only', async () => {
    const a = await subjectWithUnit();
    const b = await subjectWithUnit();
    expect(b.unit.code).toBe(a.unit.code);
    const dup = await adminCall('POST', '/units', { subjectId: a.subject.id, code: 'u1', titleAr: 'مكرر' });
    expect(dup.error?.code).toBe('CODE_TAKEN');
  });

  it('reorders only a complete set of siblings', async () => {
    const { subject } = await subjectWithUnit();
    const u2 = (
      await adminCall<Row>('POST', '/units', { subjectId: subject.id, code: 'u2', titleAr: 'الثانية' })
    ).data;
    const u3 = (
      await adminCall<Row>('POST', '/units', { subjectId: subject.id, code: 'u3', titleAr: 'الثالثة' })
    ).data;
    const all = (await adminCall<Row[]>('GET', `/units?subjectId=${subject.id}`)).data;
    expect(all.map((u) => u.code)).toEqual(['u1', 'u2', 'u3']);

    const incomplete = await adminCall('PUT', '/units/reorder', { ids: [u3.id, u2.id] });
    expect(incomplete.error?.code).toBe('VALIDATION_ERROR');

    const other = await subjectWithUnit();
    const mixed = await adminCall('PUT', '/units/reorder', {
      ids: [u3.id, u2.id, all[0]!.id, other.unit.id],
    });
    expect(mixed.error?.code).toBe('VALIDATION_ERROR');

    expect((await adminCall('PUT', '/units/reorder', { ids: [u3.id, all[0]!.id, u2.id] })).status).toBe(200);
    const after = (await adminCall<Row[]>('GET', `/units?subjectId=${subject.id}`)).data;
    expect(after.map((u) => u.code)).toEqual(['u3', 'u1', 'u2']);
  });

  it('deletes bottom-up only and audits every change', async () => {
    const { subject, unit } = await subjectWithUnit();
    const lesson = (
      await adminCall<Row>('POST', '/lessons', {
        subjectId: subject.id,
        unitId: unit.id,
        code: 'l1',
        titleAr: 'درس',
      })
    ).data;
    expect((await adminCall('DELETE', `/subjects/${subject.id}`)).error?.code).toBe('RESOURCE_IN_USE');
    expect((await adminCall('DELETE', `/units/${unit.id}`)).error?.code).toBe('RESOURCE_IN_USE');
    expect((await adminCall('DELETE', `/lessons/${lesson.id}`)).status).toBe(200);
    expect((await adminCall('DELETE', `/units/${unit.id}`)).status).toBe(200);
    expect((await adminCall('DELETE', `/subjects/${subject.id}`)).status).toBe(200);
    expect((await adminCall('DELETE', `/subjects/${subject.id}`)).status).toBe(404);

    const logs = await t.c.db.select().from(auditLogs).where(eq(auditLogs.resourceId, subject.id));
    expect(logs.map((l) => l.action).sort()).toEqual([
      'structure.subject.created',
      'structure.subject.deleted',
    ]);
  });

  it('moving a lesson into a unit appends it there', async () => {
    const { subject, unit } = await subjectWithUnit();
    await adminCall('POST', '/lessons', { subjectId: subject.id, unitId: unit.id, code: 'a', titleAr: 'أ' });
    const loose = (
      await adminCall<Row>('POST', '/lessons', { subjectId: subject.id, code: 'b', titleAr: 'ب' })
    ).data;
    expect(loose.sortOrder).toBe(0);
    const moved = await adminCall<Row & { unitId: string }>('PATCH', `/lessons/${loose.id}`, {
      unitId: unit.id,
    });
    expect(moved.data).toMatchObject({ unitId: unit.id, sortOrder: 1 });
  });
});

describe('levels', () => {
  it('admins can rename a level but students still see all three', async () => {
    const id = await levelId(t, 'grade-9');
    const res = await adminCall('PATCH', `/levels/${id}`, { nameAr: 'التاسع الأساسي' });
    expect(res.data).toMatchObject({ code: 'grade-9', nameAr: 'التاسع الأساسي', isCollege: false });
    await adminCall('PATCH', `/levels/${id}`, { nameAr: 'الصف التاسع' });
    const levels = (await studentGet<{ code: string; isCollege: boolean }[]>('/levels')).data;
    expect(levels.find((l) => l.code === 'college')?.isCollege).toBe(true);
  });
});

describe('student browsing', () => {
  it('requires sign-in', async () => {
    const res = await t.app.inject({ method: 'GET', url: '/api/v1/subjects' });
    expect(res.statusCode).toBe(401);
  });

  it('shows every level, but only active subjects under active college layers', async () => {
    const { uni, year } = await collegePath();
    const college = await levelId(t, 'college');
    const visible = (
      await adminCall<Row>('POST', '/subjects', {
        educationLevelId: college,
        academicYearId: year.id,
        code: code('v'),
        nameAr: 'ظاهرة',
      })
    ).data;
    const hidden = (
      await adminCall<Row>('POST', '/subjects', {
        educationLevelId: college,
        academicYearId: year.id,
        code: code('h'),
        nameAr: 'مخفية',
        isActive: false,
      })
    ).data;

    let list = (await studentGet<Row[]>(`/subjects?academicYearId=${year.id}`)).data;
    expect(list.map((s) => s.id)).toEqual([visible.id]);
    expect((await studentGet(`/subjects/${hidden.id}`)).status).toBe(404);

    await adminCall('PATCH', `/universities/${uni.id}`, { isActive: false });
    list = (await studentGet<Row[]>(`/subjects?academicYearId=${year.id}`)).data;
    expect(list).toEqual([]);
    expect((await studentGet(`/subjects/${visible.id}`)).status).toBe(404);
    expect((await studentGet<Row[]>('/universities')).data.some((u) => u.id === uni.id)).toBe(false);
    expect((await studentGet(`/faculties?universityId=${uni.id}`)).status).toBe(404);
  });

  it('returns a subject outline with units, their lessons, and loose lessons', async () => {
    const subject = (
      await adminCall<Row>('POST', '/subjects', {
        educationLevelId: await levelId(t, 'grade-12'),
        code: code('o'),
        nameAr: 'فيزياء',
      })
    ).data;
    const u1 = (
      await adminCall<Row>('POST', '/units', { subjectId: subject.id, code: 'u1', titleAr: 'الميكانيك' })
    ).data;
    const u2 = (
      await adminCall<Row>('POST', '/units', { subjectId: subject.id, code: 'u2', titleAr: 'الكهرباء' })
    ).data;
    await adminCall('POST', '/lessons', {
      subjectId: subject.id,
      unitId: u1.id,
      code: 'l1',
      titleAr: 'الحركة',
    });
    await adminCall('POST', '/lessons', { subjectId: subject.id, code: 'l0', titleAr: 'مقدمة' });
    await adminCall('DELETE', `/units/${u2.id}`);

    const outline = await studentGet<{
      subject: { id: string };
      units: { code: string; lessons: { code: string }[] }[];
      lessons: { code: string }[];
    }>(`/subjects/${subject.id}`);
    expect(outline.data.subject.id).toBe(subject.id);
    expect(outline.data.units.map((u) => [u.code, u.lessons.map((l) => l.code)])).toEqual([['u1', ['l1']]]);
    expect(outline.data.lessons.map((l) => l.code)).toEqual(['l0']);

    const unit = await studentGet<{ lessons: unknown[] }>(`/units/${u1.id}`);
    expect(unit.data.lessons).toHaveLength(1);
    expect((await studentGet(`/units/${u2.id}`)).status).toBe(404);
  });
});

describe('profile level (spec §8.9)', () => {
  const patchMe = (payload: object) =>
    t.app.inject({
      method: 'PATCH',
      url: '/api/v1/me',
      headers: { authorization: `Bearer ${student}` },
      payload,
    });

  it('switches to college with a derived path, then back to a school level', async () => {
    const { uni, fac, year } = await collegePath();
    const toCollege = body(
      await patchMe({ educationLevelId: await levelId(t, 'college'), academicYearId: year.id }),
    );
    expect(toCollege.data).toMatchObject({
      universityId: uni.id,
      facultyId: fac.id,
      academicYearId: year.id,
    });

    const toSchool = body(await patchMe({ educationLevelId: await levelId(t, 'grade-9') }));
    expect(toSchool.data).toMatchObject({ universityId: null, facultyId: null, academicYearId: null });
  });

  it('rejects college layers on a school level and inactive layers', async () => {
    const { uni, fac } = await collegePath();
    expect(
      body(await patchMe({ educationLevelId: await levelId(t, 'grade-12'), facultyId: fac.id })).error?.code,
    ).toBe('VALIDATION_ERROR');
    await adminCall('PATCH', `/universities/${uni.id}`, { isActive: false });
    expect(
      body(await patchMe({ educationLevelId: await levelId(t, 'college'), facultyId: fac.id })).error?.code,
    ).toBe('VALIDATION_ERROR');
  });

  it('accepts an optional college path at registration', async () => {
    const { year } = await collegePath();
    const email = `college-${randomUUID().slice(0, 8)}@example.com`;
    const res = await t.app.inject({
      method: 'POST',
      url: '/api/v1/auth/register',
      payload: {
        fullName: 'طالب جامعي',
        email,
        password: 'correct-horse-battery',
        educationLevelId: await levelId(t, 'college'),
        academicYearId: year.id,
      },
    });
    expect(res.statusCode).toBe(200);
  });
});
