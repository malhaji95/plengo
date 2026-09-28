import { randomUUID } from 'node:crypto';
import { and, eq, isNull } from 'drizzle-orm';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { auditLogs, mediaFiles, questionAnswers, questions } from '@plengo/db';
import { parseCsv, readXlsx, toCsv, toXlsx } from '../src/lib/tabular.js';
import { COLUMNS } from '../src/services/import-service.js';
import { body, createTestApp, enrolledAdminSession, levelId, type TestContext } from './helpers.js';

let t: TestContext;
let admin: Record<string, string>;
beforeAll(async () => {
  t = await createTestApp();
  admin = (await enrolledAdminSession(t)).headers;
});
afterAll(async () => {
  await t.close();
});

type Json = Record<string, unknown>;
const tag = () => randomUUID().slice(0, 8);

async function adminCall<T = Json>(method: 'GET' | 'POST' | 'DELETE', url: string, payload?: object) {
  const res = await t.app.inject({
    method,
    url: `/api/v1/admin${url}`,
    headers: admin,
    ...(payload ? { payload } : {}),
  });
  return { status: res.statusCode, ...body<T>(res) };
}

/** A file response (template or export). */
async function download(url: string) {
  const res = await t.app.inject({ method: 'GET', url: `/api/v1/admin${url}`, headers: admin });
  expect(res.statusCode).toBe(200);
  return res;
}

/** A Grade 12 subject with a unit, a lesson in it, another lesson outside it, and a track. */
async function structure() {
  const s = tag();
  const subject = (
    await adminCall<{ id: string }>('POST', '/subjects', {
      educationLevelId: await levelId(t, 'grade-12'),
      code: `phys-${s}`,
      nameAr: 'الفيزياء',
    })
  ).data;
  const unit = (
    await adminCall<{ id: string }>('POST', '/units', {
      subjectId: subject.id,
      code: 'u1',
      titleAr: 'الميكانيك',
    })
  ).data;
  const lesson = (
    await adminCall<{ id: string }>('POST', '/lessons', {
      subjectId: subject.id,
      unitId: unit.id,
      code: 'motion',
      titleAr: 'الحركة',
    })
  ).data;
  await adminCall('POST', '/lessons', { subjectId: subject.id, code: 'loose', titleAr: 'درس مستقل' });
  const teacher = (
    await adminCall<{ id: string }>('POST', '/teachers', { nameAr: 'أ. أحمد', slug: `t-${s}` })
  ).data;
  const track = (
    await adminCall<{ id: string }>('POST', '/teacher-tracks', {
      teacherId: teacher.id,
      subjectId: subject.id,
      titleAr: 'مسار',
      slug: `track-${s}`,
    })
  ).data;
  return {
    code: `phys-${s}`,
    subjectId: subject.id,
    unitId: unit.id,
    lessonId: lesson.id,
    track: `track-${s}`,
    trackId: track.id,
  };
}

type Job = {
  id: string;
  status: string;
  totalRows: number;
  validRows: number;
  errorCount: number;
  failureReason: string | null;
  errors: { rowNumber: number; field: string | null; message: string }[];
  preview: { rowNumber: number; questionText: string; answers: string[]; isFree: boolean | null }[];
  summary: { created: number; published: boolean; scopes: number } | null;
};

async function upload(kind: string, format: 'csv' | 'xlsx', header: string[], rows: string[][]) {
  const file = format === 'csv' ? toCsv({ header, rows }) : toXlsx({ header, rows });
  const created = await adminCall<Job>('POST', '/imports', {
    kind,
    format,
    fileName: `q.${format}`,
    contentBase64: file.toString('base64'),
  });
  expect(created.status).toBe(200);
  expect(created.data.status).toBe('parsing');
  await t.queue.drain(t.c.jobHandlers);
  return (await adminCall<Job>('GET', `/imports/${created.data.id}`)).data;
}

const row = (columns: string[], values: Record<string, string>) => columns.map((c) => values[c] ?? '');

describe('question import (§27)', () => {
  it('validates every row and reports per-row errors; a file with errors cannot be imported', async () => {
    const w = await structure();
    const cols = COLUMNS.mcq;
    const base = {
      education_level_code: 'grade-12',
      subject_code: w.code,
      option_a: 'أ',
      option_b: 'ب',
      correct_option: 'a',
    };
    const job = await upload('mcq', 'csv', cols, [
      row(cols, { ...base, unit_code: 'u1', lesson_code: 'motion', question: 'صالح' }),
      row(cols, { ...base, subject_code: 'nope', question: 'مادة مجهولة' }),
      row(cols, { ...base, education_level_code: 'grade-9', question: 'مرحلة خاطئة' }),
      row(cols, { ...base, unit_code: 'u1', lesson_code: 'loose', question: 'درس خارج الوحدة' }),
      row(cols, { ...base, correct_option: 'c', question: 'خيار صحيح فارغ' }),
      row(cols, { ...base, option_b: 'أ', question: 'خيارات مكررة' }),
      row(cols, { ...base, difficulty: 'impossible', is_free_override: 'maybe', question: 'قيم خاطئة' }),
      row(cols, { ...base, teacher_track_code: 'no-track', question: 'مسار مجهول' }),
      row(cols, {}),
      row(cols, { ...base, question: '' }),
    ]);
    expect(job).toMatchObject({ status: 'ready', totalRows: 9, validRows: 1 });
    const byRow = (n: number) =>
      job.errors.filter((e) => e.rowNumber === n).map((e) => `${e.field}:${e.message}`);
    expect(byRow(3)).toEqual(['subject_code:رمز المادة غير معروف']);
    expect(byRow(4)).toEqual(['subject_code:المادة لا تتبع هذه المرحلة']);
    expect(byRow(5)).toEqual(['lesson_code:الدرس لا يتبع هذه الوحدة']);
    expect(byRow(6)).toEqual(['correct_option:الخيار الصحيح فارغ']);
    expect(byRow(7)).toEqual(['option_a:خيارات مكررة']);
    expect(byRow(8)).toHaveLength(2);
    expect(byRow(9)).toEqual(['teacher_track_code:رمز المسار غير معروف']);
    // The blank line (10) is skipped; row 11 lacks its question.
    expect(byRow(10)).toEqual([]);
    expect(byRow(11)).toEqual(['question:مطلوب']);
    expect(job.preview.map((p) => p.questionText)).toEqual(['صالح']);

    const confirm = await adminCall('POST', `/imports/${job.id}/confirm`, { publish: true });
    expect(confirm.status).toBe(400);
    const created = await t.c.db.select().from(questions).where(eq(questions.subjectId, w.subjectId));
    expect(created).toHaveLength(0);
  });

  it('imports written questions from XLSX in one transaction, publishes them and applies free rules', async () => {
    const w = await structure();
    const cols = COLUMNS.written;
    const job = await upload('written', 'xlsx', cols, [
      row(cols, {
        education_level_code: 'grade-12',
        subject_code: w.code,
        unit_code: 'u1',
        lesson_code: 'motion',
        question: 'ما عاصمة سوريا؟',
        accepted_answer_1: 'دِمَشْق',
        accepted_answer_2: 'الشام',
        difficulty: 'سهل',
        is_free_override: 'true',
      }),
      row(cols, {
        education_level_code: 'grade-12',
        subject_code: w.code,
        teacher_track_code: w.track,
        question: 'سؤال المسار',
        accepted_answer_1: 'جواب',
        explanation: 'شرح',
      }),
    ]);
    expect(job).toMatchObject({ status: 'ready', validRows: 2, errorCount: 0 });
    expect(job.preview[0]).toMatchObject({ answers: ['دِمَشْق', 'الشام'], isFree: true });

    const confirmed = await adminCall<Job>('POST', `/imports/${job.id}/confirm`, { publish: true });
    expect(confirmed.data.status).toBe('importing');
    // Confirming twice is refused.
    expect((await adminCall('POST', `/imports/${job.id}/confirm`, { publish: true })).status).toBe(400);
    await t.queue.drain(t.c.jobHandlers);
    const done = (await adminCall<Job>('GET', `/imports/${job.id}`)).data;
    expect(done).toMatchObject({ status: 'completed', summary: { created: 2, published: true, scopes: 2 } });

    const rows = await t.c.db
      .select()
      .from(questions)
      .where(and(eq(questions.subjectId, w.subjectId), isNull(questions.deletedAt)));
    expect(rows).toHaveLength(2);
    const general = rows.find((r) => r.teacherTrackId === null)!;
    expect(general).toMatchObject({
      type: 'written',
      status: 'published',
      unitId: w.unitId,
      lessonId: w.lessonId,
      difficulty: 'easy',
      isFree: true,
      freeSource: 'manual_override',
    });
    const answers = await t.c.db
      .select()
      .from(questionAnswers)
      .where(eq(questionAnswers.questionId, general.id));
    expect(answers.map((a) => a.answerNormalized)).toEqual(['دمشق', 'الشام']);
    expect(rows.find((r) => r.teacherTrackId === w.trackId)).toMatchObject({
      freeSource: 'rule',
      explanation: 'شرح',
    });

    const [log] = await t.c.db.select().from(auditLogs).where(eq(auditLogs.resourceId, job.id));
    expect(log).toMatchObject({ action: 'import.completed', metadata: { kind: 'written', created: 2 } });
    const list = await adminCall<{ id: string; status: string }[]>('GET', '/imports');
    expect(list.data.find((j) => j.id === job.id)?.status).toBe('completed');
  });

  it('exports questions in the import layout, and the export imports back unchanged', async () => {
    const w = await structure();
    for (const [text, answer] of [
      ['الضوء أسرع من الصوت', true],
      ['الصوت ينتقل في الفراغ', false],
    ] as const) {
      await adminCall('POST', '/questions', {
        type: 'true_false',
        subjectId: w.subjectId,
        unitId: w.unitId,
        questionText: text,
        trueFalseAnswer: answer,
      });
    }
    await adminCall('POST', '/questions', {
      type: 'mcq',
      subjectId: w.subjectId,
      questionText: 'ستة خيارات',
      options: ['١', '٢', '٣', '٤', '٥', '=6'].map((text, i) => ({ text, isCorrect: i === 5 })),
    });

    const tf = await download(`/questions/export?kind=true_false&format=csv&subjectId=${w.subjectId}`);
    expect(tf.headers['content-disposition']).toContain('questions-true_false.csv');
    const table = parseCsv(tf.rawPayload);
    expect(table[0]).toEqual(COLUMNS.true_false);
    expect(table.slice(1).map((r) => [r[5], r[6], r[2]])).toEqual([
      ['الضوء أسرع من الصوت', 'صح', 'u1'],
      ['الصوت ينتقل في الفراغ', 'خطأ', 'u1'],
    ]);

    const mcq = await download(`/questions/export?kind=mcq&format=xlsx&subjectId=${w.subjectId}`);
    const sheet = readXlsx(mcq.rawPayload);
    expect(sheet[0]).toContain('option_f');
    expect(sheet[1]![sheet[0]!.indexOf('option_f')]).toBe('=6');
    expect(sheet[1]![sheet[0]!.indexOf('correct_option')]).toBe('f');

    const again = await upload('mcq', 'xlsx', sheet[0]!, sheet.slice(1));
    expect(again).toMatchObject({ status: 'ready', validRows: 1, errorCount: 0 });
    expect(again.preview[0]!.answers[0]).toBe('=6');
  });

  it('downloads templates, and fails unreadable files, missing columns and changed structure', async () => {
    for (const kind of ['mcq', 'written', 'true_false'] as const) {
      const csv = await download(`/imports/template?kind=${kind}&format=csv`);
      expect(parseCsv(csv.rawPayload)[0]).toEqual(COLUMNS[kind]);
      const xlsx = await download(`/imports/template?kind=${kind}&format=xlsx`);
      expect(readXlsx(xlsx.rawPayload)[0]).toEqual(COLUMNS[kind]);
    }

    const garbage = await adminCall<Job>('POST', '/imports', {
      kind: 'mcq',
      format: 'xlsx',
      fileName: 'x.xlsx',
      contentBase64: Buffer.from('not a spreadsheet').toString('base64'),
    });
    await t.queue.drain(t.c.jobHandlers);
    expect((await adminCall<Job>('GET', `/imports/${garbage.data.id}`)).data).toMatchObject({
      status: 'failed',
      failureReason: 'تعذرت قراءة ملف Excel',
    });

    const missing = await upload('true_false', 'csv', ['subject_code', 'question'], [['x', 'y']]);
    expect(missing.status).toBe('failed');
    expect(missing.failureReason).toContain('education_level_code');

    // Too large a file is refused before any job exists.
    const big = await adminCall('POST', '/imports', {
      kind: 'mcq',
      format: 'csv',
      fileName: 'big.csv',
      contentBase64: Buffer.alloc(5 * 1024 * 1024 + 10).toString('base64'),
    });
    expect([400, 413]).toContain(big.status);

    // The lesson is deleted between preview and confirm: nothing is imported.
    const w = await structure();
    const cols = COLUMNS.true_false;
    const job = await upload('true_false', 'csv', cols, [
      row(cols, {
        education_level_code: 'grade-12',
        subject_code: w.code,
        unit_code: 'u1',
        lesson_code: 'motion',
        question: 'سؤال',
        correct_answer: 'صح',
      }),
    ]);
    expect(job.status).toBe('ready');
    expect((await adminCall('DELETE', `/lessons/${w.lessonId}`)).status).toBe(200);
    await adminCall('POST', `/imports/${job.id}/confirm`, { publish: false });
    await t.queue.drain(t.c.jobHandlers);
    expect((await adminCall<Job>('GET', `/imports/${job.id}`)).data).toMatchObject({
      status: 'failed',
      failureReason: 'تغيّرت بنية المحتوى منذ المعاينة؛ ارفع الملف من جديد',
    });
    expect(await t.c.db.select().from(questions).where(eq(questions.subjectId, w.subjectId))).toHaveLength(0);
  });
});

describe('flashcard bulk upload (§27)', () => {
  async function image(status: 'ready' | 'pending' = 'ready', kind: 'flashcard' | 'banner' = 'flashcard') {
    const id = randomUUID();
    await t.c.db.insert(mediaFiles).values({
      id,
      bucket: 'private',
      storageKey: `test/fc/${id}`,
      kind,
      mimeType: 'image/png',
      originalSize: 1,
      variants: { full: { key: `test/fc/${id}/f`, width: 1, height: 1, size: 1 } },
      status,
    });
    return id;
  }

  it('appends image pairs in order in one step, with one deck version bump', async () => {
    const w = await structure();
    const deck = (
      await adminCall<{ id: string; contentVersion: number }>('POST', '/decks', {
        subjectId: w.subjectId,
        titleAr: 'بطاقات',
      })
    ).data;
    await adminCall('POST', `/decks/${deck.id}/cards`, {
      frontMediaId: await image(),
      backMediaId: await image(),
    });
    const before = (await adminCall<{ contentVersion: number }>('GET', `/decks/${deck.id}`)).data
      .contentVersion;

    const pairs = [];
    for (let i = 0; i < 3; i++) pairs.push({ frontMediaId: await image(), backMediaId: await image() });
    const res = await adminCall<{ id: string; front: { mediaId: string }; sortOrder: number }[]>(
      'POST',
      `/decks/${deck.id}/cards/bulk`,
      { cards: pairs },
    );
    expect(res.status).toBe(200);
    expect(res.data.map((c) => c.front.mediaId)).toEqual(pairs.map((p) => p.frontMediaId));
    expect(res.data.map((c) => c.sortOrder)).toEqual([1, 2, 3]);
    expect(
      (await adminCall<{ contentVersion: number }>('GET', `/decks/${deck.id}`)).data.contentVersion,
    ).toBe(before + 1);
    const [log] = await t.c.db
      .select()
      .from(auditLogs)
      .where(and(eq(auditLogs.resourceId, deck.id), eq(auditLogs.action, 'card.bulk_created')));
    expect(log!.metadata).toEqual({ count: 3 });

    // Duplicates, unprocessed and wrong-kind images are refused; nothing is added.
    const one = await image();
    const bad = async (cards: object[]) =>
      (await adminCall('POST', `/decks/${deck.id}/cards/bulk`, { cards })).status;
    expect(await bad([{ frontMediaId: one, backMediaId: one }])).toBe(400);
    expect(await bad([{ frontMediaId: await image('pending'), backMediaId: await image() }])).toBe(400);
    expect(await bad([{ frontMediaId: await image('ready', 'banner'), backMediaId: await image() }])).toBe(
      400,
    );
    expect(await bad([])).toBe(400);
    const cards = await adminCall<unknown[]>('GET', `/decks/${deck.id}/cards`);
    expect(cards.data).toHaveLength(4);
    expect(
      (await adminCall('POST', `/decks/${randomUUID()}/cards/bulk`, { cards: pairs.slice(0, 1) })).status,
    ).toBe(404);
  });
});
