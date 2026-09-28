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
