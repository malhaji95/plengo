import { cleanup, fireEvent, render, screen, waitFor, within } from '@testing-library/react';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import type * as ApiModule from '@/lib/api';

type Call = {
  method: string;
  path: string;
  init?: { body?: unknown; params?: { query?: unknown; path?: unknown } };
};
const calls: Call[] = [];
const replies = new Map<string, unknown | ((init?: Call['init']) => unknown)>();
const ok = (data: unknown) => ({ data: { success: true, data, error: null }, response: new Response(null) });
let searchParams = new URLSearchParams();

vi.mock('@/lib/api', async (importActual) => {
  const actual = await importActual<typeof ApiModule>();
  const handler = (method: string) => (path: string, init?: Call['init']) => {
    calls.push({ method, path, init });
    const reply = replies.get(`${method} ${path}`);
    return Promise.resolve(typeof reply === 'function' ? reply(init) : (reply ?? ok(null)));
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
vi.mock('next/navigation', () => ({
  useParams: () => ({ id: 'deck-1' }),
  useRouter: () => ({ push: vi.fn(), replace: vi.fn() }),
  useSearchParams: () => searchParams,
  usePathname: () => '/',
}));
vi.mock('@/components/image-upload', () => ({
  uploadImage: vi.fn(async (_kind: string, file: File) => `m-${file.name}`),
  ImageUpload: () => null,
}));

beforeEach(() => {
  calls.length = 0;
  replies.clear();
  searchParams = new URLSearchParams();
  vi.spyOn(window, 'confirm').mockReturnValue(true);
});
afterEach(() => cleanup());

const report = (id: string, extra: Record<string, unknown> = {}) => ({
  id,
  itemType: 'question',
  itemId: `q-${id}`,
  reason: 'wrong_answer',
  note: 'الإجابة الصحيحة هي ب',
  status: 'open',
  createdAt: '2026-09-01T10:00:00Z',
  resolvedAt: null,
  studentId: 's1',
  studentName: 'سارة',
  studentEmail: 'sara@example.com',
  resolutionNote: null,
  resolvedByAdminId: null,
  itemTitleAr: 'ما وحدة القوة؟',
  subjectId: 'p',
  subjectNameAr: 'الفيزياء',
  deckId: null,
  openReportsOnItem: 2,
  ...extra,
});

describe('reports inbox (§21)', () => {
  it('filters, links to the editor, and resolves with a note and a student notification', async () => {
    replies.set(
      'GET /api/v1/admin/reports',
      ok({
        items: [
          report('r1'),
          report('r2', {
            itemType: 'flashcard',
            itemId: 'c1',
            deckId: 'd1',
            itemTitleAr: 'بطاقة الخلية',
            reason: 'image_problem',
            openReportsOnItem: 1,
          }),
        ],
        nextCursor: null,
      }),
    );
    replies.set('POST /api/v1/admin/reports/{id}/resolve', (init?: Call['init']) =>
      ok(report('r1', { status: (init?.body as { status: string }).status, resolutionNote: 'صُحّح' })),
    );
    const { default: ReportsPage } = await import('@/app/(dashboard)/reports/page');
    render(<ReportsPage />);
    await screen.findByText('ما وحدة القوة؟');
    expect(calls[0]!.init?.params?.query).toEqual({ status: 'open' });
    expect(screen.getByText(/2 بلاغات مفتوحة على العنصر/)).toBeTruthy();
    const links = screen.getAllByText('فتح للتعديل').map((a) => a.getAttribute('href'));
    expect(links).toEqual(['/questions/q-r1', '/flashcards/d1']);

    const first = screen.getByText('ما وحدة القوة؟').closest('div.space-y-2') as HTMLElement;
    fireEvent.change(within(first).getByLabelText('ملاحظة المعالجة'), { target: { value: 'صُحّح' } });
    fireEvent.click(within(first).getByRole('button', { name: 'تمت المعالجة' }));
    await screen.findByText('صُحّح');
    expect(calls.find((c) => c.method === 'POST')?.init).toMatchObject({
      params: { path: { id: 'r1' } },
      body: { status: 'resolved', resolutionNote: 'صُحّح', notifyStudent: true },
    });

    fireEvent.change(screen.getByLabelText('السبب'), { target: { value: 'typo' } });
    await waitFor(() =>
      expect(calls.filter((c) => c.method === 'GET').at(-1)?.init?.params?.query).toEqual({
        status: 'open',
        reason: 'typo',
      }),
    );
  });

  it('shows the reports of one item when opened from analytics', async () => {
    searchParams = new URLSearchParams('itemId=q-9');
    replies.set('GET /api/v1/admin/reports', ok({ items: [], nextCursor: null }));
    const { default: ReportsPage } = await import('@/app/(dashboard)/reports/page');
    render(<ReportsPage />);
    await screen.findByText('لا توجد بلاغات');
    expect(calls[0]!.init?.params?.query).toEqual({ status: 'open', itemId: 'q-9' });
  });
});

const analyticsRow = (id: string, extra: Record<string, unknown> = {}) => ({
  questionId: id,
  type: 'mcq',
  questionText: `سؤال ${id}`,
  status: 'published',
  subjectId: 'p',
  subjectNameAr: 'الفيزياء',
  teacherTrackId: null,
  trackTitleAr: null,
  attempts: 40,
  correctPercent: 15,
  averageTimeMs: 12_300,
  flagged: true,
  openReports: 1,
  offlineMismatches: 0,
  lastAttemptAt: '2026-09-20T10:00:00Z',
  ...extra,
});

describe('question analytics (§26.2)', () => {
  it('lists, filters flagged questions, shows the option spread and clears a flag', async () => {
    replies.set('GET /api/v1/admin/subjects', ok([{ id: 'p', nameAr: 'الفيزياء', code: 'g12-physics' }]));
    replies.set(
      'GET /api/v1/admin/question-analytics',
      ok({
        items: [analyticsRow('q1'), analyticsRow('q2', { flagged: false, correctPercent: 80 })],
        nextCursor: null,
      }),
    );
    let flagged = true;
    replies.set('GET /api/v1/admin/question-analytics/{id}', () =>
      ok({
        ...analyticsRow('q1', { flagged }),
        options: [
          { optionId: 'o1', text: 'النيوتن', isCorrect: true, count: 6, percent: 15 },
          { optionId: 'o2', text: 'الجول', isCorrect: false, count: 34, percent: 85 },
        ],
        flagReasons: flagged ? ['low_correct', 'wrong_option_preferred'] : [],
      }),
    );
    replies.set('POST /api/v1/admin/question-analytics/{id}/clear-flag', () => {
      flagged = false;
      return ok({});
    });
    const { default: AnalyticsPage } = await import('@/app/(dashboard)/question-analytics/page');
    render(<AnalyticsPage />);
    await screen.findByText('سؤال q1');
    expect(screen.getAllByLabelText('معلَّم للمراجعة')).toHaveLength(1);
    expect(screen.getAllByText('12.3 ث')).toHaveLength(2);

    fireEvent.click(screen.getByLabelText('المعلَّمة للمراجعة فقط'));
    await waitFor(() =>
      expect(
        calls.filter((c) => c.path === '/api/v1/admin/question-analytics').at(-1)?.init?.params?.query,
      ).toEqual({
        sort: 'attempts',
        flagged: 'true',
      }),
    );

    fireEvent.click(screen.getByText('سؤال q1'));
    expect(await screen.findByText('خيار خاطئ اختير أكثر من الصحيح')).toBeTruthy();
    expect(screen.getByText('34 · 85%')).toBeTruthy();
    expect(screen.getByText('البلاغات (1)').getAttribute('href')).toBe('/reports?itemId=q1');
    fireEvent.click(screen.getByRole('button', { name: 'تمت المراجعة' }));
    await waitFor(() => expect(screen.queryByText('معلَّم للمراجعة')).toBeNull());
    expect(calls.some((c) => c.path === '/api/v1/admin/question-analytics/{id}/clear-flag')).toBe(true);
  });
});

describe('audit log (§32)', () => {
  it('filters by admin, action and resource, and shows metadata', async () => {
    replies.set('GET /api/v1/admin/admins', ok([{ id: 'a1', fullName: 'بشرى', email: 'b@example.com' }]));
    replies.set(
      'GET /api/v1/admin/audit-logs',
      ok({
        items: [
          {
            id: 'l1',
            actorAdminId: 'a1',
            actorName: 'بشرى',
            actorEmail: 'b@example.com',
            action: 'coupon_batch.exported',
            resourceType: 'coupon_batch',
            resourceId: 'batch-1',
            metadata: { format: 'xlsx' },
            createdAt: '2026-09-01T10:00:00Z',
          },
        ],
        nextCursor: null,
      }),
    );
    const { default: AuditPage } = await import('@/app/(dashboard)/audit-log/page');
    render(<AuditPage />);
    await screen.findByText('coupon_batch.exported');
    fireEvent.click(screen.getByRole('button', { name: 'عرض' }));
    expect(screen.getByText(/"format": "xlsx"/)).toBeTruthy();

    fireEvent.change(screen.getByLabelText('المشرف'), { target: { value: 'a1' } });
    fireEvent.change(screen.getByLabelText('العملية'), { target: { value: 'coupon_batch.' } });
    fireEvent.change(screen.getByLabelText('من (دمشق)'), { target: { value: '2026-09-01' } });
    fireEvent.click(screen.getByText('batch-1'));
    await waitFor(() =>
      expect(calls.filter((c) => c.path === '/api/v1/admin/audit-logs').at(-1)?.init?.params?.query).toEqual({
        actorAdminId: 'a1',
        action: 'coupon_batch.',
        resourceId: 'batch-1',
        from: '2026-09-01',
      }),
    );
  });
});

describe('import and export (§27)', () => {
  const job = (extra: Record<string, unknown>) => ({
    id: 'j1',
    kind: 'mcq',
    format: 'csv',
    fileName: 'q.csv',
    status: 'parsing',
    totalRows: 0,
    validRows: 0,
    errorCount: 0,
    failureReason: null,
    errors: [],
    preview: [],
    summary: null,
    createdAt: '2026-09-01T10:00:00Z',
    completedAt: null,
    ...extra,
  });

  it('uploads a file, shows row errors, and blocks the import', async () => {
    replies.set('GET /api/v1/admin/imports', ok([]));
    replies.set('GET /api/v1/admin/subjects', ok([]));
    replies.set('POST /api/v1/admin/imports', ok(job({})));
    replies.set(
      'GET /api/v1/admin/imports/{id}',
      ok(
        job({
          status: 'ready',
          totalRows: 2,
          validRows: 1,
          errorCount: 1,
          errors: [{ rowNumber: 3, field: 'subject_code', message: 'رمز المادة غير معروف' }],
          preview: [
            {
              rowNumber: 2,
              questionText: 'ما وحدة القوة؟',
              subjectCode: 'g12-physics',
              unitCode: null,
              lessonCode: null,
              teacherTrackCode: null,
              answers: ['النيوتن', 'الجول'],
              isFree: null,
            },
          ],
        }),
      ),
    );
    const { default: ImportPage } = await import('@/app/(dashboard)/import-export/page');
    render(<ImportPage />);
    await screen.findByText('لا توجد عمليات بعد');
    const file = new File(['education_level_code,subject_code\n'], 'q.csv', { type: 'text/csv' });
    fireEvent.change(screen.getByLabelText('ملف الاستيراد'), { target: { files: [file] } });
    await waitFor(() => expect(calls.some((c) => c.method === 'POST')).toBe(true));
    const body = calls.find((c) => c.method === 'POST')!.init!.body as Record<string, string>;
    expect(body).toMatchObject({ kind: 'mcq', format: 'csv', fileName: 'q.csv' });
    expect(atob(body.contentBase64!)).toBe('education_level_code,subject_code\n');

    expect(await screen.findByText('رمز المادة غير معروف', {}, { timeout: 3000 })).toBeTruthy();
    expect(screen.getByText('ما وحدة القوة؟')).toBeTruthy();
    expect((screen.getByRole('button', { name: 'استيراد 1 سؤالاً' }) as HTMLButtonElement).disabled).toBe(
      true,
    );
  });

  it('confirms a clean file as published and reports the summary', async () => {
    replies.set('GET /api/v1/admin/imports', ok([job({ status: 'ready', totalRows: 1, validRows: 1 })]));
    replies.set('GET /api/v1/admin/subjects', ok([]));
    let status = 'ready';
    replies.set('GET /api/v1/admin/imports/{id}', () =>
      ok(
        job({
          status,
          totalRows: 1,
          validRows: 1,
          summary: status === 'completed' ? { created: 1, published: true, scopes: 1 } : null,
        }),
      ),
    );
    replies.set('POST /api/v1/admin/imports/{id}/confirm', () => {
      status = 'completed';
      return ok(job({ status: 'importing', totalRows: 1, validRows: 1 }));
    });
    const { default: ImportPage } = await import('@/app/(dashboard)/import-export/page');
    render(<ImportPage />);
    fireEvent.click(await screen.findByText('q.csv'));
    fireEvent.click(await screen.findByLabelText('نشر الأسئلة مباشرة'));
    fireEvent.click(screen.getByRole('button', { name: 'استيراد 1 سؤالاً' }));
    expect(await screen.findByText('تم استيراد 1 سؤالاً ونشرها.', {}, { timeout: 3000 })).toBeTruthy();
    expect(calls.find((c) => c.path === '/api/v1/admin/imports/{id}/confirm')?.init?.body).toEqual({
      publish: true,
    });
  });

  it('refuses files that are not CSV or XLSX before uploading', async () => {
    replies.set('GET /api/v1/admin/imports', ok([]));
    replies.set('GET /api/v1/admin/subjects', ok([]));
    const { default: ImportPage } = await import('@/app/(dashboard)/import-export/page');
    render(<ImportPage />);
    fireEvent.change(screen.getByLabelText('ملف الاستيراد'), {
      target: { files: [new File(['x'], 'q.pdf')] },
    });
    expect(await screen.findByText('الصيغ المقبولة: CSV أو XLSX')).toBeTruthy();
    expect(calls.some((c) => c.method === 'POST')).toBe(false);
  });
});

describe('global search (§26.2)', () => {
  it('groups hits by type and links each to its page', async () => {
    replies.set(
      'GET /api/v1/admin/search',
      ok({
        items: [
          { type: 'student', id: 's1', title: 'سارة', subtitle: 'sara@example.com', parentId: null },
          { type: 'coupon', id: 'c1', title: '…AB12', subtitle: 'دفعة', parentId: 'b1' },
          { type: 'track', id: 't1', title: 'مسار', subtitle: 'أ. أحمد', parentId: 'teacher-1' },
          { type: 'question', id: 'q1', title: 'ما وحدة القوة؟', subtitle: 'الفيزياء', parentId: null },
        ],
      }),
    );
    const { GlobalSearch } = await import('@/components/global-search');
    render(<GlobalSearch />);
    fireEvent.change(screen.getByLabelText('بحث شامل'), { target: { value: 'AB12' } });
    await screen.findByText('سارة', {}, { timeout: 2000 });
    expect(calls.at(-1)?.init?.params?.query).toEqual({ q: 'AB12' });
    const href = (text: string) => screen.getByText(text).closest('a')!.getAttribute('href');
    expect(href('سارة')).toBe('/students/s1');
    expect(href('…AB12')).toBe('/coupons/b1');
    expect(href('مسار')).toBe('/teachers?id=teacher-1');
    expect(href('ما وحدة القوة؟')).toBe('/questions/q1');
    expect(screen.getByText('الكوبونات')).toBeTruthy();
  });
});

describe('flashcard bulk upload (§27)', () => {
  it('pairs picked files, lets the admin fix a pair, and uploads them in order', async () => {
    const { BulkUpload } = await import('@/components/flashcards/bulk-upload');
    const done = vi.fn();
    replies.set('POST /api/v1/admin/decks/{id}/cards/bulk', ok([]));
    render(<BulkUpload deckId="deck-1" onDone={done} />);
    const files = [
      '002-back.png',
      '001-front.png',
      '001-back.png',
      '002-front.png',
      'extra.png',
      '003-front.png',
    ].map((n) => new File(['x'], n, { type: 'image/png' }));
    fireEvent.change(screen.getByLabelText('ملفات الرفع الجماعي'), { target: { files } });
    await screen.findByText('003');
    expect(screen.getByText(/ملفات غير مقترنة \(1\)/)).toBeTruthy();
    const upload = () => screen.getByRole('button', { name: /رفع 3 بطاقة/ }) as HTMLButtonElement;
    // 003 has no back yet.
    expect(upload().disabled).toBe(true);
    fireEvent.change(screen.getByLabelText('خلفي 003'), { target: { value: 'extra.png' } });
    fireEvent.click(screen.getByLabelText('تبديل الوجهين 002'));
    expect(upload().disabled).toBe(false);
    fireEvent.click(upload());
    await waitFor(() => expect(done).toHaveBeenCalled());
    expect(calls.find((c) => c.path === '/api/v1/admin/decks/{id}/cards/bulk')?.init).toMatchObject({
      params: { path: { id: 'deck-1' } },
      body: {
        cards: [
          { frontMediaId: 'm-001-front.png', backMediaId: 'm-001-back.png' },
          { frontMediaId: 'm-002-back.png', backMediaId: 'm-002-front.png' },
          { frontMediaId: 'm-003-front.png', backMediaId: 'm-extra.png' },
        ],
      },
    });
  });
});

describe('student account deletion (§33)', () => {
  it('deletes on confirmation and shows the account as deleted', async () => {
    let status = 'active';
    replies.set('GET /api/v1/admin/students/{id}', () =>
      ok({
        student: {
          id: 'deck-1',
          email: 'sara@example.com',
          fullName: 'سارة',
          educationLevelId: null,
          emailVerified: true,
          status,
          createdAt: '2026-01-01T00:00:00Z',
          activeEntitlements: 0,
        },
        entitlements: [],
      }),
    );
    replies.set('GET /api/v1/admin/students/{id}/sessions', ok([]));
    replies.set('GET /api/v1/admin/students/{id}/attempts', ok({ items: [], nextCursor: null }));
    replies.set('POST /api/v1/admin/students/{id}/delete', () => {
      status = 'deleted';
      return ok({ deleted: true });
    });
    const { default: StudentPage } = await import('@/app/(dashboard)/students/[id]/page');
    render(<StudentPage />);
    fireEvent.click(await screen.findByRole('button', { name: 'حذف الحساب نهائياً' }));
    expect(await screen.findByText(/الحساب محذوف/)).toBeTruthy();
    expect(calls.find((c) => c.path === '/api/v1/admin/students/{id}/delete')?.init?.params).toEqual({
      path: { id: 'deck-1' },
    });
    expect(screen.queryByRole('button', { name: 'حذف الحساب نهائياً' })).toBeNull();
  });
});
