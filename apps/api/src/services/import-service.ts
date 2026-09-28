import { NORMALIZATION_VERSION, normalizeArabic } from '@plengo/arabic-normalizer';
import { IMPORT_MAX_BYTES, IMPORT_MAX_ROWS, type ImportJob, type ImportPreviewRow } from '@plengo/contracts';
import type { Db } from '@plengo/db';
import type { JobQueue } from '../jobs/queue.js';
import { AppError } from '../lib/app-error.js';
import { parseCsv, readXlsx, toCsv, toXlsx, type Table } from '../lib/tabular.js';
import type { ImportJobRow, ImportRepository } from '../repositories/import-repository.js';
import type { QuestionRepository } from '../repositories/question-repository.js';
import type { AuditService } from './audit-service.js';
import { questionScope } from './question-service.js';
import type { AdminActor } from './structure-service.js';

type Kind = ImportJobRow['kind'];
type Format = ImportJobRow['format'];
type Difficulty = 'easy' | 'medium' | 'hard';

/** A row that passed validation, resolved to ids, as stored until the import is committed. */
export interface ValidRow {
  rowNumber: number;
  codes: { subject: string; unit: string | null; lesson: string | null; track: string | null; level: string };
  subjectId: string;
  teacherTrackId: string | null;
  unitId: string | null;
  lessonId: string | null;
  questionText: string;
  explanation: string | null;
  difficulty: Difficulty | null;
  options: { text: string; isCorrect: boolean }[];
  acceptedAnswers: string[];
  isFree: boolean | null;
}

type RowError = { rowNumber: number; field: string | null; message: string };

const LETTERS = ['a', 'b', 'c', 'd', 'e', 'f'] as const;
const PLACEMENT = ['education_level_code', 'subject_code', 'unit_code', 'lesson_code', 'teacher_track_code'];
const TAIL = ['explanation', 'difficulty', 'is_free_override'];

/** Column layouts of spec §27; MCQ may add option_e/f and written answers up to 10. */
export const COLUMNS: Record<Kind, string[]> = {
  mcq: [...PLACEMENT, 'question', 'option_a', 'option_b', 'option_c', 'option_d', 'correct_option', ...TAIL],
  written: [...PLACEMENT, 'question', ...[1, 2, 3, 4, 5].map((n) => `accepted_answer_${n}`), ...TAIL],
  true_false: [...PLACEMENT, 'question', 'correct_answer', ...TAIL],
};
const REQUIRED: Record<Kind, string[]> = {
  mcq: ['education_level_code', 'subject_code', 'question', 'option_a', 'option_b', 'correct_option'],
  written: ['education_level_code', 'subject_code', 'question', 'accepted_answer_1'],
  true_false: ['education_level_code', 'subject_code', 'question', 'correct_answer'],
};

const EXAMPLES: Record<Kind, Record<string, string>> = {
  mcq: {
    question: 'ما وحدة قياس القوة؟',
    option_a: 'النيوتن',
    option_b: 'الجول',
    option_c: 'الواط',
    option_d: 'الباسكال',
    correct_option: 'a',
    explanation: 'القوة تقاس بالنيوتن',
    difficulty: 'easy',
  },
  written: {
    question: 'ما عاصمة سوريا؟',
    accepted_answer_1: 'دمشق',
    accepted_answer_2: 'الشام',
    difficulty: 'easy',
  },
  true_false: { question: 'الضوء أسرع من الصوت', correct_answer: 'صح', difficulty: 'easy' },
};

const TRUE_WORDS = new Set(['true', 'صح', 'صحيح', '1', 'نعم', 'yes']);
const FALSE_WORDS = new Set(['false', 'خطأ', 'خطا', '0', 'لا', 'no']);
const DIFFICULTY: Record<string, Difficulty> = {
  easy: 'easy',
  medium: 'medium',
  hard: 'hard',
  سهل: 'easy',
  متوسط: 'medium',
  صعب: 'hard',
};

export const CONTENT_TYPES: Record<Format, string> = {
  csv: 'text/csv; charset=utf-8',
  xlsx: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
};

const header = (h: string) => h.trim().toLowerCase().replace(/\s+/g, '_');

/**
 * Bulk question import and export (spec §27). Upload → parse and validate every row in a job →
 * preview with per-row errors → confirm → one transaction → summary. Files reference structure by
 * code and tracks by slug, never by display name.
 */
export function createImportService(deps: {
  db: Db;
  repo: ImportRepository;
  questionRepo: QuestionRepository;
  audit: AuditService;
  jobs: JobQueue;
  now?: (() => Date) | undefined;
}) {
  const { db, repo, questionRepo, audit, jobs } = deps;
  const now = deps.now ?? (() => new Date());

  type Codes = ValidRow['codes'];
  type Placement = Pick<ValidRow, 'subjectId' | 'teacherTrackId' | 'unitId' | 'lessonId'>;

  /** Resolves structure codes to ids; unknown or mismatched codes become field errors. */
  async function placements(list: Codes[]) {
    const distinct = (pick: (c: Codes) => string | null) => [
      ...new Set(list.map(pick).filter((x): x is string => !!x)),
    ];
    const levels = new Map((await repo.levels(distinct((c) => c.level))).map((l) => [l.code, l]));
    const subjectRows = await repo.subjects(distinct((c) => c.subject));
    const subjectsByCode = new Map(subjectRows.map((s) => [s.code, s]));
    const subjectIds = subjectRows.map((s) => s.id);
    const [unitRows, lessonRows, trackRows] = await Promise.all([
      repo.units(subjectIds),
      repo.lessons(subjectIds),
      repo.tracks(distinct((c) => c.track)),
    ]);
    const tracks = new Map(trackRows.map((t) => [t.slug, t]));

    return list.map((c): { placement: Placement | null; errors: { field: string; message: string }[] } => {
      const errors: { field: string; message: string }[] = [];
      const fail = (field: string, message: string) => errors.push({ field, message });
      const level = levels.get(c.level);
      if (!c.level) fail('education_level_code', 'مطلوب');
      else if (!level) fail('education_level_code', 'رمز المرحلة غير معروف');
      const subject = subjectsByCode.get(c.subject);
      if (!c.subject) fail('subject_code', 'مطلوب');
      else if (!subject) fail('subject_code', 'رمز المادة غير معروف');
      else if (level && subject.educationLevelId !== level.id)
        fail('subject_code', 'المادة لا تتبع هذه المرحلة');
      const unit =
        subject && c.unit ? unitRows.find((u) => u.subjectId === subject.id && u.code === c.unit) : null;
      if (subject && c.unit && !unit) fail('unit_code', 'رمز الوحدة غير معروف في هذه المادة');
      const lesson =
        subject && c.lesson
          ? lessonRows.find((l) => l.subjectId === subject.id && l.code === c.lesson)
          : null;
      if (subject && c.lesson && !lesson) fail('lesson_code', 'رمز الدرس غير معروف في هذه المادة');
      else if (lesson && unit && lesson.unitId !== unit.id) fail('lesson_code', 'الدرس لا يتبع هذه الوحدة');
      const track = c.track ? tracks.get(c.track) : null;
      if (c.track && !track) fail('teacher_track_code', 'رمز المسار غير معروف');
      else if (track && subject && track.subjectId !== subject.id)
        fail('teacher_track_code', 'المسار لا يتبع هذه المادة');
      if (errors.length || !subject) return { placement: null, errors };
      return {
        placement: {
          subjectId: subject.id,
          teacherTrackId: track?.id ?? null,
          unitId: unit?.id ?? lesson?.unitId ?? null,
          lessonId: lesson?.id ?? null,
        },
        errors,
      };
    });
  }

  /** Validates every row: placement codes, then the content of the question type. */
  async function resolve(
    raw: { rowNumber: number; get: (column: string) => string }[],
    kind: Kind,
  ): Promise<{ rows: ValidRow[]; errors: RowError[] }> {
    const codes = raw.map((r): Codes => ({
      level: r.get('education_level_code'),
      subject: r.get('subject_code'),
      unit: r.get('unit_code') || null,
      lesson: r.get('lesson_code') || null,
      track: r.get('teacher_track_code') || null,
    }));
    const placed = await placements(codes);
    const rows: ValidRow[] = [];
    const errors: RowError[] = [];
    for (const [i, r] of raw.entries()) {
      const rowErrors: RowError[] = placed[i]!.errors.map((e) => ({ rowNumber: r.rowNumber, ...e }));
      const fail = (field: string | null, message: string) =>
        rowErrors.push({ rowNumber: r.rowNumber, field, message });
      const v = r.get;

      const questionText = v('question');
      if (!questionText) fail('question', 'مطلوب');
      else if (questionText.length > 4000) fail('question', 'النص أطول من 4000 حرف');
      const explanation = v('explanation') || null;
      if (explanation && explanation.length > 4000) fail('explanation', 'النص أطول من 4000 حرف');

      const difficultyText = v('difficulty').toLowerCase();
      const difficulty = difficultyText ? (DIFFICULTY[difficultyText] ?? null) : null;
      if (difficultyText && !difficulty) fail('difficulty', 'القيم المقبولة: easy أو medium أو hard');

      const freeText = v('is_free_override').toLowerCase();
      const isFree = !freeText
        ? null
        : TRUE_WORDS.has(freeText)
          ? true
          : FALSE_WORDS.has(freeText)
            ? false
            : undefined;
      if (isFree === undefined) fail('is_free_override', 'القيم المقبولة: فارغ أو true أو false');

      let options: { text: string; isCorrect: boolean }[] = [];
      let acceptedAnswers: string[] = [];
      if (kind === 'mcq') {
        const filled = LETTERS.map((l) => ({ letter: l, text: v(`option_${l}`) })).filter((o) => o.text);
        const correct = v('correct_option').toLowerCase();
        if (filled.length < 2) fail('option_a', 'يلزم خياران على الأقل');
        if (!(LETTERS as readonly string[]).includes(correct))
          fail('correct_option', 'القيم المقبولة: a أو b أو c أو d');
        else if (!filled.some((o) => o.letter === correct)) fail('correct_option', 'الخيار الصحيح فارغ');
        if (new Set(filled.map((o) => o.text)).size !== filled.length) fail('option_a', 'خيارات مكررة');
        options = filled.map((o) => ({ text: o.text, isCorrect: o.letter === correct }));
      } else if (kind === 'true_false') {
        const answer = v('correct_answer').toLowerCase();
        const value = TRUE_WORDS.has(answer) ? true : FALSE_WORDS.has(answer) ? false : null;
        if (value === null) fail('correct_answer', 'القيم المقبولة: صح أو خطأ أو true أو false');
        options = [
          { text: 'صح', isCorrect: value === true },
          { text: 'خطأ', isCorrect: value === false },
        ];
      } else {
        acceptedAnswers = Array.from({ length: 10 }, (_, i) => v(`accepted_answer_${i + 1}`)).filter(Boolean);
        if (!acceptedAnswers.length) fail('accepted_answer_1', 'إجابة مقبولة واحدة على الأقل');
        const normalized = acceptedAnswers.map((a) => normalizeArabic(a));
        if (normalized.some((n) => !n)) fail('accepted_answer_1', 'إجابة فارغة بعد التطبيع');
        else if (new Set(normalized).size !== normalized.length)
          fail('accepted_answer_1', 'إجابات مكررة بعد التطبيع');
      }

      if (rowErrors.length) {
        errors.push(...rowErrors);
        continue;
      }
      rows.push({
        rowNumber: r.rowNumber,
        codes: codes[i]!,
        ...placed[i]!.placement!,
        questionText,
        explanation,
        difficulty,
        options,
        acceptedAnswers,
        isFree: isFree ?? null,
      });
    }
    return { rows, errors };
  }

  const toRaw = (table: string[][]) => {
    const [head = [], ...body] = table;
    const index = new Map(head.map((h, i) => [header(h), i]));
    return {
      columns: new Set(index.keys()),
      rows: body
        .map((cells, i) => ({
          rowNumber: i + 2,
          get: (column: string) => {
            const at = index.get(column);
            return at === undefined ? '' : (cells[at] ?? '').trim();
          },
          empty: cells.every((c) => !c.trim()),
        }))
        .filter((r) => !r.empty),
    };
  };

  function preview(row: ValidRow): ImportPreviewRow {
    return {
      rowNumber: row.rowNumber,
      questionText: row.questionText,
      subjectCode: row.codes.subject,
      unitCode: row.codes.unit,
      lessonCode: row.codes.lesson,
      teacherTrackCode: row.codes.track,
      answers: row.acceptedAnswers.length
        ? row.acceptedAnswers
        : [...row.options].sort((a, b) => Number(b.isCorrect) - Number(a.isCorrect)).map((o) => o.text),
      isFree: row.isFree,
    };
  }

  async function view(job: ImportJobRow): Promise<ImportJob> {
    const errors = await repo.errors(job.id, 500);
    const rows = (job.rows ?? []) as ValidRow[];
    return {
      id: job.id,
      kind: job.kind,
      format: job.format,
      fileName: job.fileName,
      status: job.status,
      totalRows: job.totalRows,
      validRows: job.validRows,
      errorCount: job.errorCount,
      failureReason: job.failureReason,
      errors: errors.map((e) => ({ rowNumber: e.rowNumber, field: e.field, message: e.message })),
      preview: rows.slice(0, 50).map(preview),
      summary: (job.summary as ImportJob['summary']) ?? null,
      createdAt: job.createdAt.toISOString(),
      completedAt: job.completedAt?.toISOString() ?? null,
    };
  }

  async function getJob(id: string) {
    const job = await repo.job(id);
    if (!job) throw new AppError('NOT_FOUND');
    return job;
  }

  return {
    /** Stores the upload and queues parsing; the admin polls the job for the preview. */
    async create(
      actor: AdminActor,
      input: { kind: Kind; format: Format; fileName: string; contentBase64: string },
    ) {
      const bytes = Buffer.from(input.contentBase64, 'base64');
      if (!bytes.length || bytes.length > IMPORT_MAX_BYTES)
        throw new AppError('VALIDATION_ERROR', { details: { field: 'contentBase64', reason: 'size' } });
      const job = await repo.insertJob({
        kind: input.kind,
        format: input.format,
        fileName: input.fileName,
        fileData: bytes.toString('base64'),
        createdByAdminId: actor.adminId,
        createdAt: now(),
      });
      await jobs.send('imports.parse', { jobId: job.id }, { singletonKey: job.id });
      return view(job);
    },

    list: async () => {
      const rows = await repo.jobs(30);
      return Promise.all(
        rows.map(async (r) => {
          const { errors: _e, preview: _p, ...rest } = await view({ ...r, rows: null });
          return rest;
        }),
      );
    },

    get: async (id: string) => view(await getJob(id)),

    /** Job: parse the file and validate every row (§27). */
    async parse(jobId: string) {
      const job = await repo.job(jobId);
      if (!job || job.status !== 'parsing' || !job.fileData) return;
      const failed = (reason: string) =>
        repo.transition(job.id, 'parsing', { status: 'failed', failureReason: reason, fileData: null });
      let table: string[][];
      try {
        const bytes = Buffer.from(job.fileData, 'base64');
        table = job.format === 'csv' ? parseCsv(bytes) : readXlsx(bytes);
      } catch {
        await failed(job.format === 'csv' ? 'تعذرت قراءة ملف CSV' : 'تعذرت قراءة ملف Excel');
        return;
      }
      const raw = toRaw(table);
      const missing = REQUIRED[job.kind].filter((c) => !raw.columns.has(c));
      if (missing.length) {
        await failed(`أعمدة ناقصة: ${missing.join('، ')}`);
        return;
      }
      if (!raw.rows.length) {
        await failed('الملف لا يحتوي على صفوف');
        return;
      }
      if (raw.rows.length > IMPORT_MAX_ROWS) {
        await failed(`الحد الأقصى ${IMPORT_MAX_ROWS} صف في الملف الواحد`);
        return;
      }
      const { rows, errors } = await resolve(raw.rows, job.kind);
      await repo.replaceErrors(job.id, errors);
      await repo.transition(job.id, 'parsing', {
        status: 'ready',
        totalRows: raw.rows.length,
        validRows: rows.length,
        errorCount: errors.length,
        rows,
        fileData: null,
      });
    },

    /** Queues the import. Only a file without errors can be imported: fix the rows and upload again. */
    async confirm(actor: AdminActor, id: string, input: { publish: boolean }) {
      const job = await getJob(id);
      if (job.status !== 'ready' || job.errorCount > 0 || job.validRows === 0)
        throw new AppError('VALIDATION_ERROR', { details: { field: 'status', reason: job.status } });
      if (!(await repo.transition(id, 'ready', { status: 'importing' })))
        throw new AppError('VALIDATION_ERROR', { details: { field: 'status' } });
      await jobs.send(
        'imports.commit',
        { jobId: id, publish: input.publish, adminId: actor.adminId, ip: actor.ip },
        { singletonKey: id },
      );
      return view((await repo.job(id))!);
    },

    /** Job: one transaction for every row, then free rules for the scopes touched (§8.4). */
    async commit(data: { jobId: string; publish: boolean; adminId: string; ip: string | null }) {
      const job = await repo.job(data.jobId);
      if (!job || job.status !== 'importing') return;
      const stored = (job.rows ?? []) as ValidRow[];
      // The structure may have changed since the preview: resolve the codes again.
      const again = await placements(stored.map((r) => r.codes));
      const moved = again.some(({ placement: p }, i) => {
        const r = stored[i]!;
        return (
          !p ||
          p.subjectId !== r.subjectId ||
          p.unitId !== r.unitId ||
          p.lessonId !== r.lessonId ||
          p.teacherTrackId !== r.teacherTrackId
        );
      });
      if (moved) {
        await repo.transition(job.id, 'importing', {
          status: 'failed',
          failureReason: 'تغيّرت بنية المحتوى منذ المعاينة؛ ارفع الملف من جديد',
        });
        return;
      }

      const at = now();
      const scopes = new Map<string, ReturnType<typeof questionScope>>();
      try {
        await db.transaction(async (tx) => {
          const next = new Map<string, number>();
          for (const r of stored) {
            const scope = questionScope({ subjectId: r.subjectId, teacherTrackId: r.teacherTrackId });
            const key = `${scope.scopeType}:${scope.subjectId}:${scope.teacherTrackId}`;
            scopes.set(key, scope);
            const sortOrder = next.get(key) ?? (await questionRepo.nextSortOrder(tx, scope));
            next.set(key, sortOrder + 1);
            const q = await questionRepo.insert(tx, {
              type: job.kind,
              subjectId: r.subjectId,
              teacherTrackId: r.teacherTrackId,
              unitId: r.unitId,
              lessonId: r.lessonId,
              questionText: r.questionText,
              explanation: r.explanation,
              difficulty: r.difficulty,
              status: data.publish ? 'published' : 'draft',
              isFree: r.isFree ?? false,
              freeSource: r.isFree === null ? 'rule' : 'manual_override',
              sortOrder,
              createdByAdminId: data.adminId,
              updatedByAdminId: data.adminId,
              createdAt: at,
              updatedAt: at,
            });
            if (r.options.length) await questionRepo.syncOptions(tx, q.id, r.options);
            if (r.acceptedAnswers.length) {
              await questionRepo.syncAnswers(
                tx,
                q.id,
                r.acceptedAnswers.map((original) => ({ original, normalized: normalizeArabic(original) })),
                NORMALIZATION_VERSION,
              );
            }
          }
          const summary = { created: stored.length, published: data.publish, scopes: scopes.size };
          // Status, summary and the audit entry commit with the questions or not at all.
          await repo.complete(tx, job.id, summary, at);
          await audit.record(
            {
              actorAdminId: data.adminId,
              action: 'import.completed',
              resourceType: 'import_job',
              resourceId: job.id,
              metadata: { kind: job.kind, fileName: job.fileName, ...summary },
              ip: data.ip,
            },
            tx,
          );
        });
      } catch (err) {
        await repo.transition(job.id, 'importing', {
          status: 'failed',
          failureReason: 'فشل الاستيراد، لم يُحفظ أي سؤال',
        });
        throw err;
      }
      if (data.publish) {
        for (const scope of scopes.values()) await jobs.send('access.recompute-free', { ...scope });
      }
    },

    /** The column layout with one example row (§27 "downloadable templates"). */
    template(kind: Kind, format: Format) {
      const columns = COLUMNS[kind];
      const example = {
        education_level_code: 'grade-12',
        subject_code: 'g12-physics',
        ...EXAMPLES[kind],
      } as Record<string, string>;
      return file(
        { header: columns, rows: [columns.map((c) => example[c] ?? '')] },
        format,
        `template-${kind}`,
      );
    },

    /** Existing questions of one type and scope, in the import layout (§27). */
    async export(kind: Kind, format: Format, subjectId: string, trackId: string | null) {
      const rows = await repo.exportRows(kind, subjectId, trackId);
      const maxOptions = Math.max(4, ...rows.map((r) => r.options.length));
      const maxAnswers = Math.max(5, ...rows.map((r) => r.answers.length));
      const columns =
        kind === 'mcq'
          ? [
              ...PLACEMENT,
              'question',
              ...LETTERS.slice(0, maxOptions).map((l) => `option_${l}`),
              'correct_option',
              ...TAIL,
            ]
          : kind === 'written'
            ? [
                ...PLACEMENT,
                'question',
                ...Array.from({ length: maxAnswers }, (_, i) => `accepted_answer_${i + 1}`),
                ...TAIL,
              ]
            : COLUMNS.true_false;
      const table: Table = {
        header: columns,
        rows: rows.map((r) => {
          const values: Record<string, string> = {
            education_level_code: r.levelCode,
            subject_code: r.subjectCode,
            unit_code: r.unitCode ?? '',
            lesson_code: r.lessonCode ?? '',
            teacher_track_code: r.trackSlug ?? '',
            question: r.q.questionText,
            explanation: r.q.explanation ?? '',
            difficulty: r.q.difficulty ?? '',
            is_free_override: r.q.freeSource === 'manual_override' ? String(r.q.isFree) : '',
            correct_answer: r.options[0]?.isCorrect ? 'صح' : 'خطأ',
          };
          r.options.forEach((o, i) => {
            values[`option_${LETTERS[i]}`] = o.text;
            if (o.isCorrect) values.correct_option = LETTERS[i]!;
          });
          r.answers.forEach((a, i) => (values[`accepted_answer_${i + 1}`] = a));
          return columns.map((c) => values[c] ?? '');
        }),
      };
      return file(table, format, `questions-${kind}`);
    },
  };
}

function file(table: Table, format: Format, name: string) {
  return {
    body: format === 'csv' ? toCsv(table) : toXlsx(table, 'questions'),
    contentType: CONTENT_TYPES[format],
    filename: `${name}.${format}`,
  };
}

export type ImportService = ReturnType<typeof createImportService>;
