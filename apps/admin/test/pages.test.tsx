import { cleanup, fireEvent, render, screen, waitFor } from '@testing-library/react';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import type * as ApiModule from '@/lib/api';

type Call = { method: string; path: string; init?: { body?: unknown; params?: unknown } };
const calls: Call[] = [];
const replies = new Map<string, unknown>();
const ok = (data: unknown) => ({ data: { success: true, data, error: null }, response: new Response(null) });
const fail = (code: string, message: string) => ({
  error: { success: false, data: null, error: { code, message } },
  response: new Response(null, { status: 422 }),
});

vi.mock('@/lib/api', async (importActual) => {
  const actual = await importActual<typeof ApiModule>();
  const handler = (method: string) => (path: string, init?: Call['init']) => {
    calls.push({ method, path, init });
    const reply = replies.get(`${method} ${path}`);
    return Promise.resolve(reply ?? ok(null));
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
vi.mock('next/navigation', () => ({
  useParams: () => ({ id: 'quiz-1' }),
  useRouter: () => ({ push: vi.fn() }),
}));

const admins = [
  {
    id: 'me',
    email: 'me@example.com',
    fullName: 'أنا',
    status: 'active',
    twoFactorEnabled: true,
    createdAt: '2026-01-01T00:00:00Z',
    lastSeenAt: null,
  },
  {
    id: 'a2',
    email: 'b@example.com',
    fullName: 'بشرى',
    status: 'active',
    twoFactorEnabled: true,
    createdAt: '2026-01-01T00:00:00Z',
    lastSeenAt: null,
  },
];

beforeEach(() => {
  calls.length = 0;
  replies.clear();
  vi.spyOn(window, 'confirm').mockReturnValue(true);
});
afterEach(() => cleanup());

describe('admin accounts page (§11.3, §26.2)', () => {
  it('lists admins, creates one, deactivates and resets another admin 2FA (never your own)', async () => {
    replies.set('GET /api/v1/admin/admins', ok(admins));
    const { default: AdminsPage } = await import('@/app/(dashboard)/admins/page');
    render(<AdminsPage />);
    await screen.findByText('بشرى');
    // No 2FA reset for yourself.
    expect(screen.getAllByText('إعادة ضبط التحقق الثنائي')).toHaveLength(1);

    fireEvent.change(screen.getByLabelText('الاسم'), { target: { value: 'مشرف جديد' } });
    fireEvent.change(screen.getByLabelText('البريد الإلكتروني'), { target: { value: 'new@example.com' } });
    fireEvent.change(screen.getByLabelText('كلمة مرور مؤقتة (10 أحرف على الأقل)'), {
      target: { value: 'long-password-1' },
    });
    fireEvent.click(screen.getByRole('button', { name: 'إضافة' }));
    await waitFor(() =>
      expect(calls.some((c) => c.method === 'POST' && c.path === '/api/v1/admin/admins')).toBe(true),
    );
    expect(calls.find((c) => c.path === '/api/v1/admin/admins' && c.method === 'POST')?.init?.body).toEqual({
      email: 'new@example.com',
      fullName: 'مشرف جديد',
      password: 'long-password-1',
    });

    fireEvent.click(screen.getByText('إعادة ضبط التحقق الثنائي'));
    await waitFor(() =>
      expect(calls.some((c) => c.path === '/api/v1/admin/admins/{id}/reset-2fa')).toBe(true),
    );
    expect(calls.find((c) => c.path === '/api/v1/admin/admins/{id}/reset-2fa')?.init?.params).toEqual({
      path: { id: 'a2' },
    });
  });

  it('shows the Arabic error when the last active admin cannot be deactivated', async () => {
    replies.set('GET /api/v1/admin/admins', ok([admins[0]]));
    replies.set(
      'POST /api/v1/admin/admins/{id}/deactivate',
      fail('VALIDATION_ERROR', 'البيانات المدخلة غير صحيحة'),
    );
    const { default: AdminsPage } = await import('@/app/(dashboard)/admins/page');
    render(<AdminsPage />);
    fireEvent.click(await screen.findByText('تعطيل'));
    expect(await screen.findByText('البيانات المدخلة غير صحيحة')).toBeTruthy();
  });
});

describe('quiz editor (§15.1.1)', () => {
  it('offers only questions of the quiz scope and saves membership in order', async () => {
    const quiz = {
      id: 'quiz-1',
      subjectId: 's1',
      subjectNameAr: 'الفيزياء',
      teacherTrackId: null,
      trackTitleAr: null,
      unitId: null,
      lessonId: null,
      titleAr: 'اختبار',
      description: null,
      allowedModes: 'both',
      timeLimitSeconds: null,
      shuffleQuestions: false,
      shuffleOptions: false,
      passingScorePercent: null,
      maxAttempts: null,
      isMockExam: false,
      allowOffline: true,
      isFree: false,
      freeSource: 'rule',
      status: 'draft',
      sortOrder: 0,
      contentVersion: 1,
      questionCount: 0,
      createdAt: '2026-01-01T00:00:00Z',
      updatedAt: '2026-01-01T00:00:00Z',
    };
    replies.set('GET /api/v1/admin/quizzes/{id}', ok({ quiz, questions: [] }));
    replies.set(
      'GET /api/v1/admin/questions',
      ok({
        items: [
          { id: 'q1', type: 'mcq', questionText: 'سؤال أول', status: 'published', isFree: true },
          { id: 'q2', type: 'written', questionText: 'سؤال ثان', status: 'published', isFree: false },
        ],
        nextCursor: null,
        totalCount: 2,
      }),
    );
    for (const path of [
      'GET /api/v1/admin/levels',
      'GET /api/v1/admin/subjects',
      'GET /api/v1/admin/teacher-tracks',
      'GET /api/v1/admin/units',
      'GET /api/v1/admin/lessons',
    ]) {
      replies.set(path, ok([]));
    }
    const { default: QuizPage } = await import('@/app/(dashboard)/quizzes/[id]/page');
    render(<QuizPage />);
    await screen.findByText('سؤال أول');
    // General quiz → the picker asks for the subject's general questions only.
    const picker = calls.find((c) => c.path === '/api/v1/admin/questions');
    expect(picker?.init?.params).toMatchObject({ query: { subjectId: 's1', generalOnly: 'true' } });

    const add = screen.getAllByRole('button', { name: 'إضافة' });
    fireEvent.click(add[1]!);
    fireEvent.click(screen.getAllByRole('button', { name: 'إضافة' })[0]!);
    fireEvent.click(screen.getByRole('button', { name: 'حفظ الأسئلة والترتيب' }));
    await waitFor(() => expect(calls.some((c) => c.method === 'PUT')).toBe(true));
    expect(calls.find((c) => c.method === 'PUT')?.init?.body).toEqual({ questionIds: ['q2', 'q1'] });
  });
});

const banner = (id: string, titleAr: string, extra: Record<string, unknown> = {}) => ({
  id,
  titleAr,
  imageMediaId: `m-${id}`,
  imageUrl: null,
  action: 'none',
  actionTarget: null,
  educationLevelId: null,
  startsAt: null,
  endsAt: null,
  isActive: true,
  sortOrder: 0,
  live: true,
  updatedAt: '2026-01-01T00:00:00Z',
  ...extra,
});

describe('banners (§19.2)', () => {
  it('reorders, toggles and edits banners without losing their action', async () => {
    replies.set(
      'GET /api/v1/admin/banners',
      ok([
        banner('b1', 'أول', { action: 'external_url', actionTarget: 'https://example.com' }),
        banner('b2', 'ثان', { isActive: false, live: false }),
      ]),
    );
    replies.set('GET /api/v1/admin/levels', ok([{ id: 'l12', code: 'grade-12', nameAr: 'البكالوريا' }]));
    const { default: BannersPage } = await import('@/app/(dashboard)/banners/page');
    render(<BannersPage />);
    await screen.findByText('أول');
    expect(screen.getByText('ظاهر الآن')).toBeTruthy();
    expect(screen.getAllByText('معطّل').length).toBeGreaterThan(0);

    fireEvent.click(screen.getAllByRole('button', { name: 'تحريك للأسفل' })[0]!);
    await waitFor(() => expect(calls.some((c) => c.path === '/api/v1/admin/banners/reorder')).toBe(true));
    expect(calls.find((c) => c.path === '/api/v1/admin/banners/reorder')?.init?.body).toEqual({
      ids: ['b2', 'b1'],
    });

    fireEvent.click(screen.getByRole('button', { name: 'تفعيل' }));
    await waitFor(() => expect(calls.some((c) => c.method === 'PATCH')).toBe(true));
    expect(calls.find((c) => c.method === 'PATCH')?.init).toMatchObject({
      params: { path: { id: 'b2' } },
      body: { isActive: true },
    });

    calls.length = 0;
    fireEvent.click(screen.getAllByRole('button', { name: 'تعديل' })[0]!);
    expect((screen.getByLabelText('الوجهة') as HTMLInputElement).value).toBe('https://example.com');
    fireEvent.change(screen.getByLabelText('العنوان'), { target: { value: 'أول معدّل' } });
    fireEvent.change(screen.getByLabelText('المرحلة'), { target: { value: 'l12' } });
    fireEvent.click(screen.getByRole('button', { name: 'حفظ التعديلات' }));
    await waitFor(() => expect(calls.some((c) => c.method === 'PATCH')).toBe(true));
    expect(calls.find((c) => c.method === 'PATCH')?.init).toMatchObject({
      params: { path: { id: 'b1' } },
      body: {
        titleAr: 'أول معدّل',
        imageMediaId: 'm-b1',
        action: 'external_url',
        actionTarget: 'https://example.com',
        educationLevelId: 'l12',
        startsAt: null,
        endsAt: null,
      },
    });
  });
});

describe('exam countdowns (§19.3)', () => {
  it('adds a countdown for a level and shows the days left', async () => {
    replies.set('GET /api/v1/admin/levels', ok([{ id: 'l12', code: 'grade-12', nameAr: 'البكالوريا' }]));
    replies.set(
      'GET /api/v1/admin/countdowns',
      ok([
        {
          id: 'c1',
          educationLevelId: 'l12',
          titleAr: 'امتحان الشهادة',
          examDate: '2027-06-01',
          isActive: true,
          daysLeft: 42,
        },
      ]),
    );
    const { default: CountdownsPage } = await import('@/app/(dashboard)/countdowns/page');
    render(<CountdownsPage />);
    await screen.findByText('42 يوم');
    fireEvent.change(screen.getByLabelText('المرحلة'), { target: { value: 'l12' } });
    fireEvent.change(screen.getByLabelText('العنوان'), { target: { value: 'الدورة الثانية' } });
    fireEvent.change(screen.getByLabelText('تاريخ الامتحان'), { target: { value: '2027-08-01' } });
    fireEvent.click(screen.getByRole('button', { name: 'إضافة' }));
    await waitFor(() => expect(calls.some((c) => c.method === 'POST')).toBe(true));
    expect(calls.find((c) => c.method === 'POST')?.init?.body).toEqual({
      educationLevelId: 'l12',
      titleAr: 'الدورة الثانية',
      examDate: '2027-08-01',
    });
  });
});

describe('notifications (§20.2)', () => {
  const u1 = '0190a8e4-6a1e-7c3e-9d2f-6b1c2d3e4f50';
  const u2 = '0190a8e4-6a1e-7c3e-9d2f-6b1c2d3e4f51';

  it('composes a targeted notification and shows delivery counts in the history', async () => {
    replies.set('GET /api/v1/admin/levels', ok([{ id: 'l12', code: 'grade-12', nameAr: 'البكالوريا' }]));
    for (const path of ['subjects', 'teacher-tracks', 'teachers'])
      replies.set(`GET /api/v1/admin/${path}`, ok([]));
    replies.set(
      'GET /api/v1/admin/notifications',
      ok({
        items: [
          {
            id: 'n1',
            type: 'announcement',
            titleAr: 'إعلان سابق',
            bodyAr: 'نص',
            action: 'none',
            actionTarget: null,
            targetType: 'all',
            target: {},
            status: 'sent',
            recipientCount: 120,
            pushCount: 80,
            pushFailures: 2,
            readCount: 30,
            createdAt: '2026-01-01T00:00:00Z',
            sentAt: '2026-01-01T00:01:00Z',
          },
        ],
        nextCursor: null,
      }),
    );
    const { default: NotificationsPage } = await import('@/app/(dashboard)/notifications/page');
    render(<NotificationsPage />);
    await screen.findByText('إعلان سابق');
    expect(screen.getByText('120 مستلم')).toBeTruthy();
    expect(screen.getByText(/80 إشعار فوري · 2 فشل · 30 مقروء/)).toBeTruthy();

    fireEvent.change(screen.getByLabelText('النوع'), { target: { value: 'promotion' } });
    expect(screen.getByText('تصل العروض فقط للطلاب الذين وافقوا على استقبالها.')).toBeTruthy();
    fireEvent.change(screen.getByLabelText('العنوان'), { target: { value: 'خصم' } });
    fireEvent.change(screen.getByLabelText('النص'), { target: { value: 'عرض لطلاب البكالوريا' } });
    fireEvent.change(screen.getByLabelText('المستلمون'), { target: { value: 'level' } });
    replies.set('POST /api/v1/admin/notifications', ok({ id: 'n2' }));
    const send = screen.getByRole('button', { name: 'إرسال' }) as HTMLButtonElement;
    expect(send.disabled).toBe(true);
    fireEvent.change(screen.getByLabelText('مرحلة تعليمية'), { target: { value: 'l12' } });
    fireEvent.click(send);
    await waitFor(() => expect(calls.some((c) => c.method === 'POST')).toBe(true));
    expect(calls.find((c) => c.method === 'POST')?.init?.body).toEqual({
      type: 'promotion',
      titleAr: 'خصم',
      bodyAr: 'عرض لطلاب البكالوريا',
      action: 'none',
      actionTarget: null,
      targetType: 'level',
      target: { educationLevelId: 'l12' },
    });
    expect(await screen.findByText('تمت جدولة الإرسال')).toBeTruthy();
  });

  it('parses pasted student ids and reports API validation errors', async () => {
    for (const path of ['levels', 'subjects', 'teacher-tracks', 'teachers']) {
      replies.set(`GET /api/v1/admin/${path}`, ok([]));
    }
    replies.set('GET /api/v1/admin/notifications', ok({ items: [], nextCursor: null }));
    replies.set('POST /api/v1/admin/notifications', fail('VALIDATION_ERROR', 'البيانات المدخلة غير صحيحة'));
    const { default: NotificationsPage } = await import('@/app/(dashboard)/notifications/page');
    render(<NotificationsPage />);
    await screen.findByText('لم تُرسل إشعارات بعد');
    fireEvent.change(screen.getByLabelText('العنوان'), { target: { value: 'تنبيه' } });
    fireEvent.change(screen.getByLabelText('النص'), { target: { value: 'نص' } });
    fireEvent.change(screen.getByLabelText('المستلمون'), { target: { value: 'students' } });
    fireEvent.change(screen.getByLabelText('معرّفات الطلاب (سطر لكل معرّف)'), {
      target: { value: `${u1}\n${u2.toUpperCase()}, ${u1}\nnot-an-id` },
    });
    expect(screen.getByText('2 طالب')).toBeTruthy();
    fireEvent.change(screen.getByLabelText('الإجراء عند الضغط'), { target: { value: 'internal_route' } });
    fireEvent.change(screen.getByLabelText('الوجهة'), { target: { value: '/home/review' } });
    fireEvent.click(screen.getByRole('button', { name: 'إرسال' }));
    expect(await screen.findByText('البيانات المدخلة غير صحيحة')).toBeTruthy();
    expect(calls.find((c) => c.method === 'POST')?.init?.body).toMatchObject({
      action: 'internal_route',
      actionTarget: '/home/review',
      targetType: 'students',
      target: { userIds: [u1, u2] },
    });
  });
});
