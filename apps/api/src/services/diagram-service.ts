import { randomInt } from 'node:crypto';
import { normalizeArabic } from '@plengo/arabic-normalizer';
import type {
  AdminDiagram,
  CardImage,
  DiagramCheckResult,
  DiagramImportResult,
  PracticeDiagram,
  StudentDiagram,
} from '@plengo/contracts';
import {
  DIAGRAM_ANSWERS_MAX,
  DIAGRAM_LABELS_MAX,
  IMPORT_MAX_BYTES,
  IMPORT_MAX_ROWS,
} from '@plengo/contracts';
import type { Db } from '@plengo/db';
import { AppError } from '../lib/app-error.js';
import { parseCsv, readXlsx, toCsv, toXlsx } from '../lib/tabular.js';
import type { Scope } from '../repositories/access-repository.js';
import type {
  DiagramFilter,
  DiagramRepository,
  DiagramRow,
  DiagramWithLabels,
} from '../repositories/diagram-repository.js';
import type { MediaRow } from '../repositories/flashcard-repository.js';
import type { StructureRepository } from '../repositories/structure-repository.js';
import type { TeacherRepository } from '../repositories/teacher-repository.js';
import { scopeOf, type AccessService } from './access-service.js';
import type { AuditService } from './audit-service.js';
import { assertVisibleScope, invalid, resolvePlacement, validateContentScope } from './content-placement.js';
import { SIGNED_URL_TTL_SECONDS } from './flashcard-service.js';
import type { FreeContentSource, FreeRuleService } from './free-rule-service.js';
import { CONTENT_TYPES, type ImportService } from './import-service.js';
import type { AdminActor } from './structure-service.js';

type LabelInput = {
  number: number;
  x?: number | null | undefined;
  y?: number | null | undefined;
  answers: string[];
};
type Label = { number: number; x: number | null; y: number | null; answers: string[] };

interface ContentInput {
  unitId?: string | null | undefined;
  lessonId?: string | null | undefined;
  titleAr?: string | undefined;
  description?: string | null | undefined;
  imageMediaId?: string | undefined;
  labels?: LabelInput[] | undefined;
}

/** Plugs diagrams into the free-rule engine (§8.4, v3 §9). */
export function diagramFreeSource(repo: DiagramRepository): FreeContentSource {
  return {
    kind: 'diagrams',
    items: async (scope) =>
      (await repo.publishedInScope(scope)).map((r) => ({
        id: r.id,
        unitId: r.unitId,
        lessonId: r.lessonId,
        sortOrder: r.sortOrder,
        isFree: r.isFree,
        manual: r.freeSource === 'manual_override',
      })),
    applyRule: (scope, freeIds) => repo.applyRule(scope, freeIds),
  };
}

/**
 * Validates labels: unique numbers, both coordinates or neither, answers non-empty after
 * normalisation and distinct (duplicates by normalised form are dropped). Throws VALIDATION_ERROR.
 */
export function cleanLabels(input: LabelInput[]): Label[] {
  if (input.length < 1 || input.length > DIAGRAM_LABELS_MAX) invalid('labels', 'count');
  if (new Set(input.map((l) => l.number)).size !== input.length) invalid('labels', 'duplicate_number');
  return input.map((l) => {
    const x = l.x ?? null;
    const y = l.y ?? null;
    if ((x === null) !== (y === null)) invalid('labels', 'position');
    const seen = new Set<string>();
    const answers: string[] = [];
    for (const raw of l.answers) {
      const original = raw.trim().replace(/\s+/g, ' ');
      const normalized = diagramAnswerKey(original);
      if (!normalized) invalid('labels', 'empty_answer');
      if (seen.has(normalized)) continue;
      seen.add(normalized);
      answers.push(original);
    }
    if (answers.length < 1 || answers.length > DIAGRAM_ANSWERS_MAX) invalid('labels', 'answers');
    return { number: l.number, x, y, answers };
  });
}

/**
 * A part name's comparison key: the written-answer normaliser (§14.5: trim, spaces, tashkeel, tatweel,
 * alef and alef-maksura forms, punctuation), then ة → ه. Written answers keep ة/ه apart on purpose;
 * part names are short nouns where students often type either, so diagrams fold them (v3 §9).
 */
export const diagramAnswerKey = (s: string) => normalizeArabic(s).replace(/ة/g, 'ه');

/** An answer is correct when its key matches one accepted answer's key. */
export function matchesAnswer(answer: string | null | undefined, accepted: string[]) {
  if (!answer) return false;
  const given = diagramAnswerKey(answer);
  return !!given && accepted.some((a) => diagramAnswerKey(a) === given);
}

const DIAGRAM_COLUMNS = [
  'diagram_ref',
  'education_level_code',
  'subject_code',
  'unit_code',
  'lesson_code',
  'teacher_track_code',
  'title',
  'image_file',
  'label_number',
  'answers',
  'x',
  'y',
];
const DIAGRAM_REQUIRED = [
  'diagram_ref',
  'education_level_code',
  'subject_code',
  'image_file',
  'label_number',
  'answers',
];

/**
 * «رسمات العلوم» (v3 §9): admin authoring, bulk import, and the student list / practice / check.
 * Student payloads carry the labels' numbers and marker positions, never their answers, until a check.
 */
export function createDiagramService(deps: {
  db: Db;
  repo: DiagramRepository;
  structureRepo: StructureRepository;
  teacherRepo: TeacherRepository;
  access: AccessService;
  freeRules: FreeRuleService;
  imports: ImportService;
  audit: AuditService;
  /** Signed URLs for a processed private image (the flashcard image helper). */
  image: (m: MediaRow) => Promise<CardImage>;
  /** A checked diagram counts toward the daily goal (§19.4). */
  onChecked?: (userId: string) => Promise<void>;
  now?: () => Date;
}) {
  const { db, repo, structureRepo, teacherRepo, access, freeRules, imports, audit } = deps;
  const now = deps.now ?? (() => new Date());
  const notFound = (): never => {
    throw new AppError('NOT_FOUND');
  };
  const record = (actor: AdminActor, action: string, id: string, metadata: Record<string, unknown> = {}) =>
    audit.record({
      actorAdminId: actor.adminId,
      action,
      resourceType: 'diagram',
      resourceId: id,
      metadata,
      ip: actor.ip,
    });

  const diagramScope = (d: { subjectId: string; teacherTrackId: string | null }): Scope => scopeOf(d);

  async function assertImage(mediaId: string) {
    const m = await repo.getMedia(mediaId);
    if (!m || m.deletedAt || m.kind !== 'flashcard' || m.status !== 'ready') invalid('imageMediaId');
  }

  async function toAdmin(rows: DiagramWithLabels[]): Promise<AdminDiagram[]> {
    const [names, media] = await Promise.all([
      repo.names(
        [...new Set(rows.map((r) => r.subjectId))],
        [...new Set(rows.flatMap((r) => (r.teacherTrackId ? [r.teacherTrackId] : [])))],
      ),
      repo.mediaByIds([...new Set(rows.map((r) => r.imageMediaId))]),
    ]);
    return Promise.all(
      rows.map(async (d) => {
        const m = media.get(d.imageMediaId);
        return {
          id: d.id,
          subjectId: d.subjectId,
          subjectNameAr: names.subjects.get(d.subjectId) ?? '',
          teacherTrackId: d.teacherTrackId,
          trackTitleAr: d.teacherTrackId ? (names.tracks.get(d.teacherTrackId) ?? null) : null,
          unitId: d.unitId,
          lessonId: d.lessonId,
          titleAr: d.titleAr,
          description: d.description,
          imageMediaId: d.imageMediaId,
          image: m && m.status === 'ready' ? await deps.image(m) : null,
          isFree: d.isFree,
          freeSource: d.freeSource,
          status: d.status,
          sortOrder: d.sortOrder,
          contentVersion: d.contentVersion,
          labels: d.labels.map((l) => ({
            id: l.id,
            number: l.number,
            x: l.x,
            y: l.y,
            answers: l.answers,
            sortOrder: l.sortOrder,
          })),
          createdAt: d.createdAt.toISOString(),
          updatedAt: d.updatedAt.toISOString(),
        };
      }),
    );
  }

  const adminGet = async (id: string) => (await toAdmin([(await repo.get(id)) ?? notFound()]))[0]!;

  const ruleFree = (d: DiagramRow) =>
    d.status === 'published' ? freeRules.isFreeOnPublish(diagramScope(d), 'diagrams', d.id) : false;

  async function setStatus(actor: AdminActor, id: string, status: DiagramRow['status']) {
    const current = (await repo.get(id)) ?? notFound();
    if (current.status === status) return adminGet(id);
    if (status === 'published') {
      if (!current.labels.length) invalid('labels', 'count');
      await assertImage(current.imageMediaId);
    }
    await repo.update(db, id, { status, updatedByAdminId: actor.adminId, updatedAt: now() });
    if (status === 'published' && current.freeSource === 'rule')
      await repo.update(db, id, { isFree: await ruleFree({ ...current, status }) });
    await record(
      actor,
      `diagram.${status === 'published' ? 'published' : status === 'archived' ? 'archived' : 'unpublished'}`,
      id,
    );
    return adminGet(id);
  }

  async function create(
    actor: AdminActor,
    input: ContentInput & {
      subjectId: string;
      teacherTrackId?: string | null | undefined;
      titleAr: string;
      imageMediaId: string;
      labels: LabelInput[];
      publish?: boolean | undefined;
    },
  ) {
    const trackId = input.teacherTrackId ?? null;
    await validateContentScope({ structureRepo, teacherRepo }, input.subjectId, trackId);
    const place = await resolvePlacement(
      structureRepo,
      input.subjectId,
      input.unitId ?? null,
      input.lessonId ?? null,
    );
    const labels = cleanLabels(input.labels);
    await assertImage(input.imageMediaId);
    const scope = diagramScope({ subjectId: input.subjectId, teacherTrackId: trackId });
    const at = now();
    const id = await db.transaction(async (tx) => {
      const d = await repo.insert(tx, {
        subjectId: input.subjectId,
        teacherTrackId: trackId,
        ...place,
        titleAr: input.titleAr.trim(),
        description: input.description ?? null,
        imageMediaId: input.imageMediaId,
        sortOrder: await repo.nextSortOrder(tx, scope),
        createdByAdminId: actor.adminId,
        updatedByAdminId: actor.adminId,
        createdAt: at,
        updatedAt: at,
      });
      await repo.replaceLabels(tx, d.id, labels);
      await audit.record(
        {
          actorAdminId: actor.adminId,
          action: 'diagram.created',
          resourceType: 'diagram',
          resourceId: d.id,
          metadata: { ...scope, labels: labels.length },
          ip: actor.ip,
        },
        tx,
      );
      return d.id;
    });
    if (input.publish) return setStatus(actor, id, 'published');
    return adminGet(id);
  }

  // ---- student helpers ----

  async function publishedDiagram(id: string) {
    const d = await repo.get(id);
    if (!d || d.status !== 'published') notFound();
    await assertVisibleScope({ structureRepo, teacherRepo }, d!.subjectId, d!.teacherTrackId);
    return d!;
  }

  /** Published diagrams of a practice scope: unit (with its lessons), some lessons, or the subject. */
  async function scopeDiagrams(q: {
    subjectId: string;
    teacherTrackId?: string | null | undefined;
    unitId?: string | null | undefined;
    lessonIds?: string[] | undefined;
  }) {
    await assertVisibleScope({ structureRepo, teacherRepo }, q.subjectId, q.teacherTrackId ?? null);
    const filter: DiagramFilter = {
      subjectId: q.subjectId,
      ...(q.teacherTrackId ? { teacherTrackId: q.teacherTrackId } : { generalOnly: true }),
      status: 'published',
    };
    if (q.lessonIds?.length) filter.lessonIds = q.lessonIds;
    else if (q.unitId) filter.unitId = q.unitId;
    return repo.list(filter);
  }

  // ---- bulk import ----

  type ImportGroup = {
    ref: string;
    firstRow: number;
    codes: {
      level: string;
      subject: string;
      unit: string | null;
      lesson: string | null;
      track: string | null;
    };
    title: string;
    imageFile: string;
    labels: { rowNumber: number; number: number; answers: string[]; x: number | null; y: number | null }[];
  };

  function readTable(input: { format: 'csv' | 'xlsx'; contentBase64: string }) {
    const bytes = Buffer.from(input.contentBase64, 'base64');
    if (!bytes.length || bytes.length > IMPORT_MAX_BYTES)
      throw new AppError('VALIDATION_ERROR', { details: { field: 'contentBase64', reason: 'size' } });
    try {
      return input.format === 'csv' ? parseCsv(bytes) : readXlsx(bytes);
    } catch {
      throw new AppError('VALIDATION_ERROR', { details: { field: 'contentBase64', reason: 'unreadable' } });
    }
  }

  async function importDiagrams(
    actor: AdminActor,
    input: {
      format: 'csv' | 'xlsx';
      fileName: string;
      contentBase64: string;
      images?: Record<string, string> | undefined;
      dryRun: boolean;
      publish?: boolean | undefined;
    },
  ): Promise<DiagramImportResult> {
    const raw = imports.rowsOf(readTable(input));
    const missingColumns = DIAGRAM_REQUIRED.filter((c) => !raw.columns.has(c));
    if (missingColumns.length)
      throw new AppError('VALIDATION_ERROR', {
        details: { field: 'columns', reason: 'missing', columns: missingColumns },
      });
    if (!raw.rows.length)
      throw new AppError('VALIDATION_ERROR', { details: { field: 'rows', reason: 'empty' } });
    if (raw.rows.length > IMPORT_MAX_ROWS)
      throw new AppError('VALIDATION_ERROR', { details: { field: 'rows', reason: 'too_many' } });

    const errors: DiagramImportResult['errors'] = [];
    const fail = (rowNumber: number, field: string | null, message: string) =>
      errors.push({ rowNumber, field, message });
    const groups = new Map<string, ImportGroup>();
    for (const r of raw.rows) {
      const ref = r.get('diagram_ref');
      if (!ref) {
        fail(r.rowNumber, 'diagram_ref', 'مطلوب');
        continue;
      }
      let g = groups.get(ref);
      if (!g) {
        g = {
          ref,
          firstRow: r.rowNumber,
          codes: {
            level: r.get('education_level_code'),
            subject: r.get('subject_code'),
            unit: r.get('unit_code') || null,
            lesson: r.get('lesson_code') || null,
            track: r.get('teacher_track_code') || null,
          },
          title: r.get('title'),
          imageFile: r.get('image_file'),
          labels: [],
        };
        groups.set(ref, g);
      } else {
        // Later rows of the same diagram may repeat the diagram columns; they must agree.
        const same = (column: string, value: string | null) => {
          const v = r.get(column);
          if (v && v !== (value ?? '')) fail(r.rowNumber, column, 'يختلف عن الصف الأول لهذه الرسمة');
        };
        same('subject_code', g.codes.subject);
        same('unit_code', g.codes.unit);
        same('lesson_code', g.codes.lesson);
        same('teacher_track_code', g.codes.track);
        same('image_file', g.imageFile);
        if (!g.title && r.get('title')) g.title = r.get('title');
      }
      const number = Number(r.get('label_number'));
      if (!/^\d{1,3}$/.test(r.get('label_number')) || number < 1)
        fail(r.rowNumber, 'label_number', 'رقم الجزء يجب أن يكون عدداً صحيحاً موجباً');
      else if (g.labels.some((l) => l.number === number))
        fail(r.rowNumber, 'label_number', 'رقم الجزء مكرر في هذه الرسمة');
      const answers = r
        .get('answers')
        .split('|')
        .map((a) => a.trim())
        .filter(Boolean);
      if (!answers.length) fail(r.rowNumber, 'answers', 'مطلوب');
      else if (answers.length > DIAGRAM_ANSWERS_MAX)
        fail(r.rowNumber, 'answers', `الحد الأقصى ${DIAGRAM_ANSWERS_MAX} إجابات`);
      else if (answers.some((a) => !normalizeArabic(a) || a.length > 300))
        fail(r.rowNumber, 'answers', 'إجابة فارغة أو طويلة جداً');
      const coord = (column: string) => {
        const v = r.get(column);
        if (!v) return null;
        const n = Number(v);
        if (!Number.isFinite(n) || n < 0 || n > 1) {
          fail(r.rowNumber, column, 'قيمة بين 0 و 1');
          return null;
        }
        return n;
      };
      const x = coord('x');
      const y = coord('y');
      if ((x === null) !== (y === null) && (r.get('x') || r.get('y')))
        fail(r.rowNumber, 'x', 'حدد x و y معاً أو اتركهما فارغين');
      g.labels.push({ rowNumber: r.rowNumber, number, answers, x, y });
    }

    const list = [...groups.values()];
    const placed = await imports.placements(list.map((g) => ({ ...g.codes, category: null })));
    const images = input.images ?? {};
    const required = [...new Set(list.map((g) => g.imageFile).filter(Boolean))];
    const missingImages = required.filter((f) => !images[f]);
    for (const [i, g] of list.entries()) {
      for (const e of placed[i]!.errors) fail(g.firstRow, e.field, e.message);
      if (!g.imageFile) fail(g.firstRow, 'image_file', 'مطلوب');
      if (g.labels.length > DIAGRAM_LABELS_MAX)
        fail(g.firstRow, 'label_number', `الحد الأقصى ${DIAGRAM_LABELS_MAX} جزءاً في الرسمة`);
    }
    if (!input.dryRun) {
      for (const g of list) {
        const mediaId = images[g.imageFile];
        if (!g.imageFile) continue;
        if (!mediaId) {
          fail(g.firstRow, 'image_file', 'الصورة غير مرفوعة');
          continue;
        }
        const m = await repo.getMedia(mediaId);
        if (!m || m.deletedAt || m.kind !== 'flashcard' || m.status !== 'ready')
          fail(g.firstRow, 'image_file', 'الصورة غير جاهزة');
      }
    }
    errors.sort((a, b) => a.rowNumber - b.rowNumber);
    const preview = list.map((g) => ({
      ref: g.ref,
      titleAr: g.title || g.ref,
      subjectCode: g.codes.subject,
      unitCode: g.codes.unit,
      lessonCode: g.codes.lesson,
      teacherTrackCode: g.codes.track,
      imageFile: g.imageFile,
      labels: [...g.labels]
        .sort((a, b) => a.number - b.number)
        .map((l) => ({ number: l.number, answers: l.answers })),
    }));
    const result = {
      dryRun: input.dryRun,
      totalRows: raw.rows.length,
      diagrams: preview.slice(0, 200),
      requiredImages: required,
      missingImages,
      errors: errors.slice(0, 500),
      createdIds: [] as string[],
    };
    if (input.dryRun || errors.length) return result;

    const at = now();
    const created = await db.transaction(async (tx) => {
      const ids: string[] = [];
      const nextOrder = new Map<string, number>();
      for (const [i, g] of list.entries()) {
        const p = placed[i]!.placement!;
        const scope = diagramScope(p);
        const key = `${scope.scopeType}:${scope.subjectId ?? scope.teacherTrackId}`;
        const sortOrder = nextOrder.get(key) ?? (await repo.nextSortOrder(tx, scope));
        nextOrder.set(key, sortOrder + 1);
        const d = await repo.insert(tx, {
          subjectId: p.subjectId,
          teacherTrackId: p.teacherTrackId,
          unitId: p.unitId,
          lessonId: p.lessonId,
          titleAr: g.title || g.ref,
          imageMediaId: images[g.imageFile]!,
          sortOrder,
          createdByAdminId: actor.adminId,
          updatedByAdminId: actor.adminId,
          createdAt: at,
          updatedAt: at,
        });
        await repo.replaceLabels(tx, d.id, cleanLabels([...g.labels].sort((a, b) => a.number - b.number)));
        ids.push(d.id);
      }
      await audit.record(
        {
          actorAdminId: actor.adminId,
          action: 'diagram.imported',
          resourceType: 'diagram',
          resourceId: ids[0] ?? 'none',
          metadata: { fileName: input.fileName, count: ids.length, publish: !!input.publish },
          ip: actor.ip,
        },
        tx,
      );
      return ids;
    });
    if (input.publish) for (const id of created) await setStatus(actor, id, 'published');
    return { ...result, createdIds: created };
  }

  return {
    counts: (scope: Scope) => repo.scopeCounts(scope),

    // ---- admin ----

    async adminList(filter: DiagramFilter, cursor: string | undefined, limit: number) {
      const page = await repo.page(filter, cursor, limit);
      return { items: await toAdmin(page.items), nextCursor: page.nextCursor, totalCount: page.total };
    },

    adminGet,
    create,
    setStatus,

    /** Title, description, image and labels bump `content_version`; placement does not. */
    async update(actor: AdminActor, id: string, patch: ContentInput) {
      const current = (await repo.get(id)) ?? notFound();
      const place = await resolvePlacement(
        structureRepo,
        current.subjectId,
        patch.unitId !== undefined ? patch.unitId : current.unitId,
        patch.lessonId !== undefined ? patch.lessonId : current.lessonId,
      );
      const labels = patch.labels ? cleanLabels(patch.labels) : null;
      if (patch.imageMediaId && patch.imageMediaId !== current.imageMediaId)
        await assertImage(patch.imageMediaId);
      const sameLabels =
        !labels ||
        (labels.length === current.labels.length &&
          labels.every((l, i) => {
            const c = current.labels[i]!;
            return (
              l.number === c.number &&
              l.x === c.x &&
              l.y === c.y &&
              l.answers.length === c.answers.length &&
              l.answers.every((a, j) => a === c.answers[j])
            );
          }));
      const titleAr = patch.titleAr?.trim() ?? current.titleAr;
      const description = patch.description !== undefined ? patch.description : current.description;
      const imageMediaId = patch.imageMediaId ?? current.imageMediaId;
      const contentChanged =
        !sameLabels ||
        titleAr !== current.titleAr ||
        (description ?? null) !== current.description ||
        imageMediaId !== current.imageMediaId;
      const placementChanged = place.unitId !== current.unitId || place.lessonId !== current.lessonId;
      if (!contentChanged && !placementChanged) return adminGet(id);
      await db.transaction(async (tx) => {
        const locked = (await repo.getForUpdate(tx, id)) ?? notFound();
        await repo.update(tx, id, {
          ...place,
          titleAr,
          description: description ?? null,
          imageMediaId,
          contentVersion: contentChanged ? locked.contentVersion + 1 : locked.contentVersion,
          updatedByAdminId: actor.adminId,
          updatedAt: now(),
        });
        if (!sameLabels) await repo.replaceLabels(tx, id, labels!);
        await audit.record(
          {
            actorAdminId: actor.adminId,
            action: 'diagram.updated',
            resourceType: 'diagram',
            resourceId: id,
            metadata: { contentChanged, placementChanged },
            ip: actor.ip,
          },
          tx,
        );
      });
      return adminGet(id);
    },

    /** Manual free/paid override, or back to the scope's rule (§8.4). Audited. */
    async setFree(actor: AdminActor, id: string, mode: 'rule' | 'free' | 'paid') {
      const current = (await repo.get(id)) ?? notFound();
      const values =
        mode === 'rule'
          ? { freeSource: 'rule' as const, isFree: await ruleFree(current) }
          : { freeSource: 'manual_override' as const, isFree: mode === 'free' };
      await repo.update(db, id, { ...values, updatedByAdminId: actor.adminId, updatedAt: now() });
      await record(actor, 'diagram.free_override', id, { mode, isFree: values.isFree });
      return adminGet(id);
    },

    /** Soft delete. Audited. */
    async remove(actor: AdminActor, id: string) {
      if (!(await repo.get(id))) notFound();
      await repo.update(db, id, { deletedAt: now(), updatedByAdminId: actor.adminId });
      await record(actor, 'diagram.deleted', id);
      return { deleted: true };
    },

    importDiagrams,

    template(format: 'csv' | 'xlsx') {
      const example = (ref: string, n: number, answers: string, extra: Record<string, string> = {}) =>
        DIAGRAM_COLUMNS.map(
          (c) =>
            ({
              diagram_ref: ref,
              education_level_code: 'grade-12',
              subject_code: 'biology',
              unit_code: 'unit-1',
              lesson_code: 'lesson-1',
              title: 'الخلية الحيوانية',
              image_file: 'cell.png',
              label_number: String(n),
              answers,
              ...extra,
            })[c] ?? '',
        );
      const table = {
        header: DIAGRAM_COLUMNS,
        rows: [
          example('cell-1', 1, 'النواة'),
          example('cell-1', 2, 'الغشاء الخلوي|الغشاء البلازمي'),
          example('cell-1', 3, 'الميتوكوندريا|المتقدرة', { x: '0.25', y: '0.6' }),
        ],
      };
      return {
        body: format === 'csv' ? toCsv(table) : toXlsx(table, 'diagrams'),
        contentType: CONTENT_TYPES[format],
        filename: `diagrams-template.${format}`,
      };
    },

    // ---- student ----

    /** Diagrams of a scope with locked flags; locked ones stay listed (metadata only). */
    async studentList(
      userId: string,
      q: {
        subjectId: string;
        teacherTrackId?: string | undefined;
        unitId?: string | undefined;
        lessonIds?: string[] | undefined;
      },
    ) {
      const [rows, ctx] = await Promise.all([scopeDiagrams(q), access.context(userId)]);
      const items: StudentDiagram[] = rows.map((d) => ({
        id: d.id,
        subjectId: d.subjectId,
        teacherTrackId: d.teacherTrackId,
        unitId: d.unitId,
        lessonId: d.lessonId,
        titleAr: d.titleAr,
        labelCount: d.labelCount,
        isFree: d.isFree,
        locked: !ctx.canAccessItem(d),
        sortOrder: d.sortOrder,
      }));
      const accessible = items.filter((i) => !i.locked).length;
      return {
        items,
        totalCount: items.length,
        accessibleCount: accessible,
        lockedCount: items.length - accessible,
      };
    },

    /** `count` random accessible diagrams of the scope, labels without answers (v3 §9). */
    async practice(
      userId: string,
      q: {
        subjectId: string;
        teacherTrackId?: string | null | undefined;
        unitId?: string | null | undefined;
        lessonIds?: string[] | undefined;
        count: number;
      },
    ) {
      const [rows, ctx] = await Promise.all([scopeDiagrams(q), access.context(userId)]);
      const open = rows.filter((d) => ctx.canAccessItem(d) && d.labelCount > 0);
      // Fisher–Yates over the accessible ones.
      for (let i = open.length - 1; i > 0; i--) {
        const j = randomInt(i + 1);
        [open[i], open[j]] = [open[j]!, open[i]!];
      }
      const picked = await repo.withLabels(open.slice(0, q.count));
      const media = await repo.mediaByIds([...new Set(picked.map((d) => d.imageMediaId))]);
      const diagrams: PracticeDiagram[] = [];
      for (const d of picked) {
        const m = media.get(d.imageMediaId);
        if (!m || m.status !== 'ready') continue;
        diagrams.push({
          id: d.id,
          subjectId: d.subjectId,
          unitId: d.unitId,
          lessonId: d.lessonId,
          titleAr: d.titleAr,
          image: await deps.image(m),
          labels: [...d.labels]
            .sort((a, b) => a.number - b.number)
            .map((l) => ({ id: l.id, number: l.number, x: l.x, y: l.y })),
          contentVersion: d.contentVersion,
        });
      }
      return {
        diagrams,
        availableCount: open.length,
        lockedCount: rows.length - rows.filter((d) => ctx.canAccessItem(d)).length,
        urlsExpireAt: new Date(now().getTime() + SIGNED_URL_TTL_SECONDS * 1000).toISOString(),
      };
    },

    /** Grades every label (missing ones are wrong) and reveals the accepted answers. */
    async check(
      userId: string,
      id: string,
      body: { answers: { number: number; answer: string }[] },
    ): Promise<DiagramCheckResult> {
      const d = await publishedDiagram(id);
      await access.assertCanAccessItem(userId, d);
      const given = new Map(body.answers.map((a) => [a.number, a.answer]));
      if (given.size !== body.answers.length) invalid('answers', 'duplicate_number');
      const known = new Set(d.labels.map((l) => l.number));
      if (body.answers.some((a) => !known.has(a.number))) invalid('answers', 'unknown_number');
      const labels = [...d.labels]
        .sort((a, b) => a.number - b.number)
        .map((l) => {
          const answer = given.get(l.number)?.trim() || null;
          return {
            labelId: l.id,
            number: l.number,
            answer,
            isCorrect: matchesAnswer(answer, l.answers),
            acceptedAnswers: l.answers,
          };
        });
      await deps.onChecked?.(userId);
      return {
        diagramId: d.id,
        correctCount: labels.filter((l) => l.isCorrect).length,
        totalCount: labels.length,
        labels,
      };
    },
  };
}

export type DiagramService = ReturnType<typeof createDiagramService>;
