import { cleanup, fireEvent, render, screen, waitFor } from '@testing-library/react';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import type * as ApiModule from '@/lib/api';
import { singleFaceRows } from '@/lib/bulk-pairs';
import { allowedParents, categoryLabel, depthOf, type QuestionCategory } from '@/lib/categories';

type Call = { method: string; path: string; init?: { body?: unknown; params?: unknown } };
const calls: Call[] = [];
const replies = new Map<string, unknown>();
const ok = (data: unknown) => ({ data: { success: true, data, error: null }, response: new Response(null) });

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
vi.mock('next/navigation', () => ({ useParams: () => ({}), useRouter: () => ({ push: vi.fn() }) }));

beforeEach(() => {
  calls.length = 0;
  replies.clear();
  vi.spyOn(window, 'confirm').mockReturnValue(true);
});
afterEach(() => cleanup());

const cat = (id: string, patch: Partial<QuestionCategory> = {}): QuestionCategory => ({
  id,
  subjectId: null,
  subjectNameAr: null,
  parentId: null,
  code: id,
  nameAr: `تصنيف ${id}`,
  sortOrder: 0,
  questionCount: 0,
  createdAt: '2026-11-01T00:00:00Z',
  updatedAt: '2026-11-01T00:00:00Z',
  ...patch,
});

describe('question category helpers (v3 §3)', () => {
  const tree = [
    cat('a', { nameAr: 'علل' }),
    cat('b', { parentId: 'a', nameAr: 'علل فيزيائياً', subjectId: 's1' }),
    cat('c', { parentId: 'b', nameAr: 'فرعي', subjectId: 's1' }),
    cat('d', { subjectId: 's2' }),
  ];

  it('computes depth and the full label', () => {
    const depth = depthOf(tree);
    expect([...depth.entries()]).toEqual([
      ['a', 0],
      ['b', 1],
      ['c', 2],
      ['d', 0],
    ]);
    expect(categoryLabel(tree, 'c')).toBe('علل › علل فيزيائياً › فرعي');
  });

  it('never offers a category itself, its descendants or another subject’s as parent', () => {
    expect(allowedParents(tree, tree[0]!).map((c) => c.id)).toEqual([]);
    expect(allowedParents(tree, tree[1]!).map((c) => c.id)).toEqual(['a']);
    expect(allowedParents(tree, null)).toHaveLength(4);
  });
});

describe('single-face bulk rows (v3 §6)', () => {
  it('turns each file into a front-only row in natural order', () => {
    expect(singleFaceRows([{ name: 'cards/10.png' }, { name: 'cards/2.jpg' }])).toEqual([
      { key: '2', front: 'cards/2.jpg', back: '' },
      { key: '10', front: 'cards/10.png', back: '' },
    ]);
  });
});

describe('question categories page (v3 §3)', () => {
  it('creates a global category and saves an edited one', async () => {
    replies.set('GET /api/v1/admin/subjects', ok([]));
    replies.set(
      'GET /api/v1/admin/question-categories',
      ok([cat('explain', { nameAr: 'علل', questionCount: 4 })]),
    );
    const { default: Page } = await import('@/app/(dashboard)/question-categories/page');
    render(<Page />);
    await screen.findByDisplayValue('علل');
    expect(calls.find((c) => c.path === '/api/v1/admin/question-categories')?.init?.params).toEqual({
      query: { globalOnly: 'true' },
    });

    fireEvent.change(screen.getByLabelText('الاسم'), { target: { value: 'قارن' } });
    fireEvent.change(screen.getByLabelText('الرمز (لاتيني)'), { target: { value: 'Compare' } });
    fireEvent.click(screen.getByRole('button', { name: 'إضافة' }));
    await waitFor(() =>
      expect(calls.find((c) => c.method === 'POST')?.init?.body).toEqual({
        subjectId: null,
        parentId: null,
        code: 'compare',
        nameAr: 'قارن',
      }),
    );

    fireEvent.change(screen.getByLabelText('ترتيب علل'), { target: { value: '5' } });
    fireEvent.click(screen.getByRole('button', { name: 'حفظ علل' }));
    await waitFor(() =>
      expect(calls.find((c) => c.method === 'PATCH')).toMatchObject({
        path: '/api/v1/admin/question-categories/{id}',
        init: {
          params: { path: { id: 'explain' } },
          body: { nameAr: 'علل', code: 'explain', parentId: null, sortOrder: 5 },
        },
      }),
    );
  });
});

describe('settings: default free lessons (v3 §3)', () => {
  it('saves the number with the other access settings', async () => {
    replies.set(
      'GET /api/v1/admin/settings/access',
      ok({ allowTemporaryToPermanentUpgrade: true, defaultFreeLessons: 3 }),
    );
    replies.set('GET /api/v1/admin/settings/learning', ok({ mistakeMasteryStreak: 2 }));
    const { default: Page } = await import('@/app/(dashboard)/settings/page');
    render(<Page />);
    const field = await screen.findByLabelText('عدد الدروس المجانية افتراضياً لكل مادة');
    await waitFor(() => expect(field).toHaveProperty('value', '3'));
    fireEvent.change(field, { target: { value: '5' } });
    const save = field.closest('div.flex')!.querySelector('button')!;
    fireEvent.click(save);
    await waitFor(() =>
      expect(
        calls.find((c) => c.method === 'PUT' && c.path === '/api/v1/admin/settings/access')?.init?.body,
      ).toEqual({ allowTemporaryToPermanentUpgrade: true, defaultFreeLessons: 5 }),
    );
  });
});
