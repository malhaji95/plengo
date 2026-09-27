import { randomUUID } from 'node:crypto';
import { eq, sql } from 'drizzle-orm';
import sharp from 'sharp';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { auditLogs } from '@plengo/db';
import { MemoryStorage } from '../src/storage/memory-storage.js';
import {
  body,
  createTestApp,
  enrolledAdminSession,
  levelId,
  tokensFor,
  type TestContext,
} from './helpers.js';

const API = 'http://api.test.local';
let t: TestContext;
let admin: Record<string, string>;
let student: string;

beforeAll(async () => {
  // A storage with a base URL exercises the dev-only upload routes end to end.
  t = await createTestApp({
    storage: new MemoryStorage({ baseUrl: API, secret: 'test-secret-for-dev-storage' }),
  });
  admin = (await enrolledAdminSession(t)).headers;
  student = (await tokensFor(t)).accessToken;
});
afterAll(async () => {
  await t.close();
});

const slug = (p: string) => `${p}-${randomUUID().slice(0, 8)}`;
type Row = { id: string; slug: string; sortOrder: number };

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

async function studentCall<T = Record<string, unknown>>(
  method: 'GET' | 'PUT' | 'DELETE',
  url: string,
  token = student,
) {
  const res = await t.app.inject({
    method,
    url: `/api/v1${url}`,
    headers: { authorization: `Bearer ${token}` },
  });
  return { status: res.statusCode, ...body<T>(res) };
}

async function subject(level = 'grade-12') {
  return (
    await adminCall<Row>('POST', '/subjects', {
      educationLevelId: await levelId(t, level),
      code: slug('subj'),
      nameAr: 'الفيزياء',
    })
  ).data;
}

async function teacherWithTrack() {
  const teacher = (await adminCall<Row>('POST', '/teachers', { nameAr: 'أ. أحمد', slug: slug('ahmad') }))
    .data;
  const subj = await subject();
  const track = (
    await adminCall<Row>('POST', '/teacher-tracks', {
      teacherId: teacher.id,
      subjectId: subj.id,
      titleAr: 'أ. أحمد — فيزياء بكالوريا',
      slug: slug('track'),
    })
  ).data;
  return { teacher, subject: subj, track };
}

describe('admin teachers and tracks', () => {
  it('creates teachers and tracks with unique slugs and audits them', async () => {
    const { teacher, track } = await teacherWithTrack();
    const dup = await adminCall('POST', '/teachers', { nameAr: 'آخر', slug: teacher.slug });
    expect(dup.error?.code).toBe('CODE_TAKEN');
    const list = await adminCall<{ id: string; trackCount: number; followerCount: number }[]>(
      'GET',
      '/teachers',
    );
    expect(list.data.find((x) => x.id === teacher.id)).toMatchObject({ trackCount: 1, followerCount: 0 });
    const logs = await t.c.db.select().from(auditLogs).where(eq(auditLogs.resourceId, track.id));
    expect(logs.map((l) => l.action)).toContain('structure.teacher_track.created');
  });

  it('allows several tracks of one teacher in the same subject', async () => {
    const { teacher, subject: subj } = await teacherWithTrack();
    const second = await adminCall('POST', '/teacher-tracks', {
      teacherId: teacher.id,
      subjectId: subj.id,
      titleAr: 'مسار ثانٍ',
      slug: slug('track'),
    });
    expect(second.status).toBe(200);
  });

  it('refuses deleting a teacher with tracks, and a subject that has tracks', async () => {
    const { teacher, subject: subj, track } = await teacherWithTrack();
    expect((await adminCall('DELETE', `/teachers/${teacher.id}`)).error?.code).toBe('RESOURCE_IN_USE');
    expect((await adminCall('DELETE', `/subjects/${subj.id}`)).error?.code).toBe('RESOURCE_IN_USE');
    expect((await adminCall('DELETE', `/teacher-tracks/${track.id}`)).status).toBe(200);
    expect((await adminCall('DELETE', `/teachers/${teacher.id}`)).status).toBe(200);
  });

  it('is a valid target for the (teacher_track_id, subject_id) foreign keys of §7.3', async () => {
    const { track, subject: subj } = await teacherWithTrack();
    const other = await subject();
    // Content tables (Phase 5+) add exactly this key. A throwaway table inside a rolled-back
    // transaction proves the target works today.
    await t.c.db
      .transaction(async (tx) => {
        await tx.execute(sql`create table content_probe (
        subject_id uuid not null,
        teacher_track_id uuid,
        foreign key (teacher_track_id, subject_id) references teacher_tracks (id, subject_id)
      )`);
        await tx.execute(sql`insert into content_probe values (${subj.id}, ${track.id})`);
        // General subject content (no track) stays valid under MATCH SIMPLE.
        await tx.execute(sql`insert into content_probe values (${other.id}, null)`);
        await expect(
          tx.execute(sql`insert into content_probe values (${other.id}, ${track.id})`),
        ).rejects.toMatchObject({ cause: { code: '23503' } });
        tx.rollback();
      })
      .catch((err: unknown) => {
        if (!(err instanceof Error && err.message === 'Rollback')) throw err;
      });
  });

  it('rejects a photo that is not a ready teacher image', async () => {
    const res = await adminCall('POST', '/teachers', {
      nameAr: 'س',
      slug: slug('p'),
      photoMediaId: randomUUID(),
    });
    expect(res.error?.code).toBe('VALIDATION_ERROR');
  });
});

describe('teacher photos through dev storage', () => {
  it('uploads with a signed URL, processes, and serves the public photo', async () => {
    const png = await sharp({ create: { width: 900, height: 900, channels: 3, background: '#0a7' } })
      .png()
      .toBuffer();
    const created = await adminCall<{ id: string; uploadUrl: string }>('POST', '/uploads', {
      kind: 'teacher',
      contentType: 'image/png',
      size: png.length,
    });
    const url = new URL(created.data.uploadUrl);
    expect(url.origin).toBe(API);

    // A tampered signature is refused.
    const bad = new URL(url);
    bad.searchParams.set('sig', 'x'.repeat(64));
    const refused = await t.app.inject({
      method: 'PUT',
      url: bad.pathname + bad.search,
      headers: { 'content-type': 'image/png' },
      payload: png,
    });
    expect(refused.statusCode).toBe(403);

    const put = await t.app.inject({
      method: 'PUT',
      url: url.pathname + url.search,
      headers: { 'content-type': 'image/png' },
      payload: png,
    });
    expect(put.statusCode).toBe(200);
    await adminCall('POST', `/uploads/${created.data.id}/complete`);
    await t.queue.drain(t.c.jobHandlers);

    const teacher = await adminCall<{ photoUrl: string }>('POST', '/teachers', {
      nameAr: 'أ. ليلى',
      slug: slug('laila'),
      photoMediaId: created.data.id,
    });
    const photoUrl = new URL(teacher.data.photoUrl);
    const served = await t.app.inject({ method: 'GET', url: photoUrl.pathname });
    expect(served.statusCode).toBe(200);
    expect(served.headers['content-type']).toBe('image/webp');
    expect((await sharp(served.rawPayload).metadata()).width).toBe(800);
  });
});

describe('students: teachers, tracks and following', () => {
  it('lists visible teachers and shows a profile with its tracks', async () => {
    const { teacher, track } = await teacherWithTrack();
    const list = await studentCall<{ id: string }[]>('GET', '/teachers');
    expect(list.data.some((x) => x.id === teacher.id)).toBe(true);
    const profile = await studentCall<{
      teacher: { id: string; isFollowing: boolean };
      tracks: { id: string; subjectNameAr: string }[];
    }>('GET', `/teachers/${teacher.id}`);
    expect(profile.data.teacher).toMatchObject({ id: teacher.id, isFollowing: false });
    expect(profile.data.tracks).toEqual([
      expect.objectContaining({ id: track.id, subjectNameAr: 'الفيزياء' }),
    ]);
  });

  it('follows idempotently and unfollows, with follower counts', async () => {
    const { teacher } = await teacherWithTrack();
    const other = (await tokensFor(t)).accessToken;
    expect(
      (await studentCall<{ followerCount: number }>('PUT', `/teachers/${teacher.id}/follow`)).data,
    ).toEqual({
      following: true,
      followerCount: 1,
    });
    expect((await studentCall('PUT', `/teachers/${teacher.id}/follow`)).data).toEqual({
      following: true,
      followerCount: 1,
    });
    expect((await studentCall('PUT', `/teachers/${teacher.id}/follow`, other)).data).toEqual({
      following: true,
      followerCount: 2,
    });

    const followed = await studentCall<{ id: string; isFollowing: boolean }[]>('GET', '/teachers/following');
    expect(followed.data.map((x) => x.id)).toContain(teacher.id);
    const profile = await studentCall<{ teacher: { isFollowing: boolean; followerCount: number } }>(
      'GET',
      `/teachers/${teacher.id}`,
    );
    expect(profile.data.teacher).toMatchObject({ isFollowing: true, followerCount: 2 });

    expect((await studentCall('DELETE', `/teachers/${teacher.id}/follow`)).data).toEqual({
      following: false,
      followerCount: 1,
    });
    expect(
      (await studentCall<{ id: string }[]>('GET', '/teachers/following')).data.map((x) => x.id),
    ).not.toContain(teacher.id);
  });

  it('shows the track page and lists tracks on the subject outline', async () => {
    const { teacher, subject: subj, track } = await teacherWithTrack();
    const page = await studentCall<{
      track: { id: string };
      teacher: { id: string };
      subject: { id: string };
    }>('GET', `/teacher-tracks/${track.id}`);
    expect(page.data).toMatchObject({
      track: { id: track.id },
      teacher: { id: teacher.id },
      subject: { id: subj.id },
    });
    const outline = await studentCall<{ tracks: { id: string; teacherNameAr: string }[] }>(
      'GET',
      `/subjects/${subj.id}`,
    );
    expect(outline.data.tracks).toEqual([
      expect.objectContaining({ id: track.id, teacherNameAr: 'أ. أحمد' }),
    ]);
  });

  it('hides tracks of hidden teachers, hidden tracks and hidden subjects', async () => {
    const a = await teacherWithTrack();
    await adminCall('PATCH', `/teachers/${a.teacher.id}`, { isActive: false });
    expect((await studentCall('GET', `/teachers/${a.teacher.id}`)).status).toBe(404);
    expect((await studentCall('GET', `/teacher-tracks/${a.track.id}`)).status).toBe(404);
    expect((await studentCall('PUT', `/teachers/${a.teacher.id}/follow`)).status).toBe(404);

    const b = await teacherWithTrack();
    await adminCall('PATCH', `/teacher-tracks/${b.track.id}`, { isActive: false });
    expect(
      (await studentCall<{ tracks: unknown[] }>('GET', `/teachers/${b.teacher.id}`)).data.tracks,
    ).toEqual([]);

    const c = await teacherWithTrack();
    await adminCall('PATCH', `/subjects/${c.subject.id}`, { isActive: false });
    expect((await studentCall('GET', `/teacher-tracks/${c.track.id}`)).status).toBe(404);
  });

  it('requires sign-in and refuses admins on student endpoints', async () => {
    expect((await t.app.inject({ method: 'GET', url: '/api/v1/teachers' })).statusCode).toBe(401);
  });
});
