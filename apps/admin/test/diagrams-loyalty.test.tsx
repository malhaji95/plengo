import { cleanup, fireEvent, render, screen, waitFor } from '@testing-library/react';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import type * as ApiModule from '@/lib/api';
import {
  addLabel,
  labelProblems,
  matchImages,
  moveLabel,
  relativePoint,
  renumber,
  splitAnswers,
  toLabelInputs,
  type AdminDiagram,
  type LabelDraft,
} from '@/lib/diagrams';
import { EMPTY_REWARD, rewardBody, rewardProblems, settingsProblems } from '@/lib/loyalty';

type Call = { method: string; path: string; init?: { body?: unknown; params?: unknown } };
const calls: Call[] = [];
const replies = new Map<string, unknown>();
const ok = (data: unknown) => ({ data: { success: true, data, error: null }, response: new Response(null) });
let params: Record<string, string> = {};

vi.mock('@/lib/api', async (importActual) => {
  const actual = await importActual<typeof ApiModule>();
  const handler = (method: string) => (path: string, init?: Call['init']) => {
    calls.push({ method, path, init });
    return Promise.resolve(replies.get(`${method} ${path}`) ?? ok(null));
  };
  return {
    ...actual,
    api: {
      GET: handler('GET'),
      POST: handler('POST'),
      PUT: handler('PUT'),
      PATCH: handler('PATCH'),
      DELETE: handler('DELETE'),
    },
  };
});
vi.mock('@/app/(dashboard)/layout', () => ({ useAdmin: () => ({ id: 'me', email: 'me@example.com' }) }));
vi.mock('next/navigation', () => ({ useParams: () => params, useRouter: () => ({ push: vi.fn() }) }));

beforeEach(() => {
  calls.length = 0;
  replies.clear();
  params = {};
  vi.spyOn(window, 'confirm').mockReturnValue(true);
});
afterEach(() => cleanup());

const draft = (
  number: number,
  answers: string,
  x: number | null = null,
  y: number | null = null,
): LabelDraft => ({
  key: `k${number}`,
  number,
  x,
  y,
  answers,
});

describe('diagram label helpers (v3 §9)', () => {
  it('splits answers on «|», adds, moves and renumbers rows', () => {
    expect(splitAnswers(' الغشاء  البلازمي | |الغشاء الخلوي ')).toEqual(['الغشاء البلازمي', 'الغشاء الخلوي']);
    const rows = addLabel([draft(1, 'أ'), draft(4, 'ب')]);
    expect(rows.map((r) => r.number)).toEqual([1, 4, 5]);
    const moved = moveLabel(rows, 0, 1);
    expect(moved.map((r) => r.number)).toEqual([4, 1, 5]);
    expect(moveLabel(rows, 0, -1)).toBe(rows);
    expect(renumber(moved).map((r) => r.number)).toEqual([1, 2, 3]);
    expect(toLabelInputs([draft(2, 'أ | ب', 0.5, 0.25)])).toEqual([
      { number: 2, x: 0.5, y: 0.25, answers: ['أ', 'ب'] },
    ]);
  });

  it('reports duplicate numbers, empty answers and half positions', () => {
    expect(labelProblems([])).toEqual(['أضف جزءاً واحداً على الأقل']);
    expect(labelProblems([draft(1, 'أ'), draft(1, ' | ', 0.2)])).toEqual([
      'أرقام الأجزاء مكررة',
      'الجزء 1 بلا إجابة',
      'موضع الجزء 1 غير مكتمل',
    ]);
    expect(labelProblems([draft(1, 'أ', 0.1, 0.9)])).toEqual([]);
  });

  it('turns a click into clamped 0..1 coordinates', () => {
    const box = { left: 100, top: 50, width: 200, height: 100 };
    expect(relativePoint({ clientX: 150, clientY: 75 }, box)).toEqual({ x: 0.25, y: 0.25 });
    expect(relativePoint({ clientX: 400, clientY: 0 }, box)).toEqual({ x: 1, y: 0 });
  });

  it('matches the sheet’s image names to picked files by base name, ignoring case', () => {
    const { found, missing } = matchImages(['Cell.PNG', 'virus.png'], [{ name: 'images/cell.png' }]);
    expect([...found.keys()]).toEqual(['Cell.PNG']);
    expect(missing).toEqual(['virus.png']);
  });
});

describe('loyalty form helpers (v3 §10)', () => {
  it('validates rewards and settings', () => {
    expect(rewardProblems(EMPTY_REWARD)).toEqual([
      'أدخل عنوان المكافأة',
      'اختر المجموعة التي تفتحها المكافأة',
    ]);
    const custom = {
      ...EMPTY_REWARD,
      titleAr: ' دفتر ',
      kind: 'custom' as const,
      deckId: 'd1',
      costPoints: '30',
    };
    expect(rewardProblems(custom)).toEqual([]);
    expect(rewardBody(custom)).toEqual({
      titleAr: 'دفتر',
      description: null,
      costPoints: 30,
      kind: 'custom',
      deckId: null,
      isActive: true,
      sortOrder: 0,
    });
    expect(settingsProblems({ pointsPerReview: '1', dailyCap: '0', pointsPerCorrectQuestion: '2' })).toEqual(
      [],
    );
    expect(
      settingsProblems({ pointsPerReview: '-1', dailyCap: 'x', pointsPerCorrectQuestion: '2' }),
    ).toHaveLength(2);
  });
});

const diagram = (patch: Partial<AdminDiagram> = {}): AdminDiagram => ({
  id: 'd1',
  subjectId: 's1',
  subjectNameAr: 'العلوم',
  teacherTrackId: null,
  trackTitleAr: null,
  unitId: 'u1',
  lessonId: 'l1',
  titleAr: 'الخلية',
  description: null,
  imageMediaId: 'm1',
  image: {
    mediaId: 'm1',
    cacheKey: 'm1:1',
    fullUrl: 'https://img/full',
    thumbUrl: 'https://img/thumb',
    width: 10,
    height: 10,
  },
  isFree: true,
  freeSource: 'rule',
  status: 'published',
  sortOrder: 0,
  contentVersion: 1,
  labels: [
    { id: 'a', number: 1, x: null, y: null, answers: ['النواة'], sortOrder: 0 },
    { id: 'b', number: 2, x: 0.5, y: 0.5, answers: ['الغشاء البلازمي', 'الغشاء الخلوي'], sortOrder: 1 },
  ],
  createdAt: '2026-11-01T00:00:00Z',
  updatedAt: '2026-11-01T00:00:00Z',
  ...patch,
});

describe('diagram pages (v3 §9)', () => {
  it('lists diagrams with filters', async () => {
    replies.set('GET /api/v1/admin/diagrams', ok({ items: [diagram()], nextCursor: null, totalCount: 1 }));
    const { default: Page } = await import('@/app/(dashboard)/diagrams/page');
    render(<Page />);
    expect(await screen.findByText('الخلية')).toBeTruthy();
    fireEvent.change(screen.getByLabelText('الحالة'), { target: { value: 'draft' } });
    await waitFor(() =>
      expect(calls.filter((c) => c.path === '/api/v1/admin/diagrams').at(-1)?.init?.params).toEqual({
        query: { status: 'draft' },
      }),
    );
  });

  it('edits the labels of a diagram and saves them with the placement', async () => {
    params = { id: 'd1' };
    replies.set('GET /api/v1/admin/diagrams/{id}', ok(diagram()));
    replies.set('PATCH /api/v1/admin/diagrams/{id}', ok(diagram({ contentVersion: 2 })));
    const { default: Page } = await import('@/app/(dashboard)/diagrams/[id]/page');
    render(<Page />);
    const answers = await screen.findByLabelText('إجابات الجزء 1');
    fireEvent.change(answers, { target: { value: 'النواة | النويه' } });
    fireEvent.click(screen.getByRole('button', { name: 'حذف الجزء 2' }));
    fireEvent.click(screen.getByRole('button', { name: 'حفظ التعديلات' }));
    await waitFor(() =>
      expect(calls.find((c) => c.method === 'PATCH')?.init).toEqual({
        params: { path: { id: 'd1' } },
        body: {
          unitId: 'u1',
          lessonId: 'l1',
          titleAr: 'الخلية',
          description: null,
          imageMediaId: 'm1',
          labels: [{ number: 1, x: null, y: null, answers: ['النواة', 'النويه'] }],
        },
      }),
    );
  });

  it('validates an import sheet with a dry run and shows row errors', async () => {
    replies.set(
      'POST /api/v1/admin/diagrams/import',
      ok({
        dryRun: true,
        totalRows: 2,
        diagrams: [
          {
            ref: 'cell',
            titleAr: 'الخلية',
            subjectCode: 'bio',
            unitCode: null,
            lessonCode: null,
            teacherTrackCode: null,
            imageFile: 'cell.png',
            labels: [{ number: 1, answers: ['النواة'] }],
          },
        ],
        requiredImages: ['cell.png'],
        missingImages: ['cell.png'],
        errors: [{ rowNumber: 3, field: 'lesson_code', message: 'رمز الدرس غير معروف في هذه المادة' }],
        createdIds: [],
      }),
    );
    const { DiagramImport } = await import('@/components/diagrams/diagram-import');
    render(<DiagramImport onDone={() => {}} />);
    const sheet = new File(['diagram_ref\ncell'], 'd.csv', { type: 'text/csv' });
    fireEvent.change(screen.getByLabelText('ملف الجدول (xlsx أو csv)'), { target: { files: [sheet] } });
    fireEvent.click(screen.getByRole('button', { name: 'تحقق' }));
    expect(await screen.findByText(/رمز الدرس غير معروف/)).toBeTruthy();
    const body = calls.find((c) => c.path === '/api/v1/admin/diagrams/import')?.init?.body as Record<
      string,
      unknown
    >;
    expect(body).toMatchObject({ format: 'csv', fileName: 'd.csv', dryRun: true });
    expect(typeof body.contentBase64).toBe('string');
    expect(screen.getByText(/صور غير محددة/)).toBeTruthy();
    expect((screen.getByRole('button', { name: 'استيراد' }) as HTMLButtonElement).disabled).toBe(true);
  });
});

describe('loyalty admin (v3 §10)', () => {
  it('creates a custom reward and cancels a pending redemption', async () => {
    replies.set('GET /api/v1/admin/loyalty/rewards', ok([]));
    replies.set('GET /api/v1/admin/decks', ok([]));
    replies.set(
      'GET /api/v1/admin/loyalty/redemptions',
      ok({
        items: [
          {
            id: 'r1',
            rewardId: 'w1',
            titleAr: 'دفتر بلينغو',
            kind: 'custom',
            costPoints: 30,
            deckId: null,
            status: 'pending',
            note: null,
            createdAt: '2026-11-01T00:00:00Z',
            handledAt: null,
            userId: 'u1',
            studentEmail: 'a@example.com',
            studentName: 'سارة',
            handledByAdminId: null,
          },
        ],
        nextCursor: null,
      }),
    );
    vi.spyOn(window, 'prompt').mockReturnValue('نفدت الكمية');
    const { default: Page } = await import('@/app/(dashboard)/loyalty/page');
    render(<Page />);
    expect(await screen.findByText('سارة')).toBeTruthy();

    fireEvent.change(screen.getByLabelText('العنوان'), { target: { value: 'دفتر' } });
    fireEvent.change(screen.getByLabelText('النوع'), { target: { value: 'custom' } });
    fireEvent.change(screen.getByLabelText('التكلفة (نقاط)'), { target: { value: '40' } });
    fireEvent.click(screen.getByRole('button', { name: 'إضافة' }));
    await waitFor(() =>
      expect(
        calls.find((c) => c.method === 'POST' && c.path === '/api/v1/admin/loyalty/rewards')?.init?.body,
      ).toEqual({
        titleAr: 'دفتر',
        description: null,
        costPoints: 40,
        kind: 'custom',
        deckId: null,
        isActive: true,
        sortOrder: 0,
      }),
    );

    fireEvent.click(screen.getByRole('button', { name: 'إلغاء واسترداد' }));
    await waitFor(() =>
      expect(calls.find((c) => c.path === '/api/v1/admin/loyalty/redemptions/{id}/status')?.init).toEqual({
        params: { path: { id: 'r1' } },
        body: { status: 'cancelled', note: 'نفدت الكمية' },
      }),
    );
  });

  it('saves the earning rules from the settings card', async () => {
    replies.set(
      'GET /api/v1/admin/settings/loyalty',
      ok({ enabled: true, pointsPerReview: 1, dailyCap: 50, pointsPerCorrectQuestion: 0 }),
    );
    const { LoyaltySettingsCard } = await import('@/components/loyalty/settings-card');
    render(<LoyaltySettingsCard />);
    const cap = await screen.findByLabelText('الحد الأقصى اليومي');
    await waitFor(() => expect(cap).toHaveProperty('value', '50'));
    fireEvent.change(cap, { target: { value: '80' } });
    fireEvent.change(screen.getByLabelText('نقاط لكل إجابة صحيحة'), { target: { value: '2' } });
    fireEvent.click(screen.getByRole('button', { name: 'حفظ' }));
    await waitFor(() =>
      expect(calls.find((c) => c.method === 'PUT')?.init?.body).toEqual({
        enabled: true,
        pointsPerReview: 1,
        dailyCap: 80,
        pointsPerCorrectQuestion: 2,
      }),
    );
  });

  it('shows a student’s balance and adjusts it with a reason', async () => {
    replies.set(
      'GET /api/v1/admin/students/{id}/loyalty',
      ok({
        userId: 'u1',
        balance: 42,
        earnedToday: 5,
        ledger: [
          {
            id: 'e1',
            delta: 1,
            reason: 'review',
            refId: 'x',
            day: '2026-11-01',
            note: null,
            createdAt: '2026-11-01T00:00:00Z',
          },
        ],
        redemptions: [],
        unlockedDeckIds: [],
      }),
    );
    const { StudentLoyalty } = await import('@/components/loyalty/student-loyalty');
    render(<StudentLoyalty studentId="u1" />);
    expect(await screen.findByText('42')).toBeTruthy();
    expect(screen.getByText('مراجعة بطاقة')).toBeTruthy();
    fireEvent.change(screen.getByLabelText('تعديل (+/−)'), { target: { value: '-10' } });
    fireEvent.change(screen.getByLabelText('السبب'), { target: { value: 'تصحيح' } });
    fireEvent.click(screen.getByRole('button', { name: 'تطبيق' }));
    await waitFor(() =>
      expect(calls.find((c) => c.method === 'POST')?.init).toEqual({
        params: { path: { id: 'u1' } },
        body: { delta: -10, note: 'تصحيح' },
      }),
    );
  });
});
