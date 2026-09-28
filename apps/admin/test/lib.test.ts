import { describe, expect, it } from 'vitest';
import { damascusDate, scopeBody, scopeLabel, termBody } from '@/lib/access';
import { ApiError, unwrap } from '@/lib/api';
import { NAV_ITEMS, CURRENT_PHASE } from '@/lib/nav';
import { freeLabel, MODE_LABELS } from '@/lib/questions';

const response = (status: number) => new Response(null, { status });

describe('unwrap (§30.3 envelope)', () => {
  it('returns data on success', async () => {
    const data = { id: 'x' };
    await expect(
      unwrap(Promise.resolve({ data: { success: true, data, error: null }, response: response(200) })),
    ).resolves.toBe(data);
  });

  it('throws the API code and Arabic message on failure', async () => {
    const err = await unwrap(
      Promise.resolve({
        error: {
          success: false,
          data: null,
          error: { code: 'CONTENT_LOCKED', message: 'هذا المحتوى غير متاح على حسابك' },
        },
        response: response(403),
      }),
    ).catch((e: unknown) => e);
    expect(err).toBeInstanceOf(ApiError);
    expect(err).toMatchObject({
      code: 'CONTENT_LOCKED',
      message: 'هذا المحتوى غير متاح على حسابك',
      status: 403,
    });
  });

  it('maps a transport failure to NETWORK_ERROR', async () => {
    const err = await unwrap(Promise.reject(new TypeError('fetch failed'))).catch((e: unknown) => e);
    expect(err).toMatchObject({ code: 'NETWORK_ERROR', status: 0 });
  });
});

describe('access helpers', () => {
  it('sends only the id of the chosen scope and exactly one term (§9.1)', () => {
    expect(scopeBody({ scopeType: 'subject', subjectId: 's', teacherTrackId: 't' })).toEqual({
      scopeType: 'subject',
      subjectId: 's',
    });
    expect(scopeBody({ scopeType: 'teacher_track', subjectId: 's', teacherTrackId: 't' })).toEqual({
      scopeType: 'teacher_track',
      teacherTrackId: 't',
    });
    expect(termBody({ kind: 'permanent' })).toEqual({ permanentAccess: true });
    expect(termBody({ kind: 'duration', days: 30 })).toEqual({ accessDurationDays: 30 });
    expect(termBody({ kind: 'until', date: '2026-12-31' })).toEqual({ accessExpiresOn: '2026-12-31' });
  });

  it('labels scopes and gives Damascus dates', () => {
    expect(
      scopeLabel({
        scopeType: 'subject',
        subjectId: 's',
        subjectNameAr: 'الفيزياء',
        teacherTrackId: null,
        trackTitleAr: null,
        teacherNameAr: null,
        educationLevelId: 'l',
      }),
    ).toBe('الفيزياء (المحتوى العام)');
    expect(damascusDate()).toMatch(/^\d{4}-\d{2}-\d{2}$/);
  });

  it('labels free status and quiz modes', () => {
    expect(freeLabel({ isFree: true, freeSource: 'rule' })).toBe('مجاني (حسب القاعدة)');
    expect(freeLabel({ isFree: false, freeSource: 'manual_override' })).toBe('مدفوع (يدوي)');
    expect(MODE_LABELS.exam).toBe('امتحان فقط');
  });
});

describe('navigation (§26.1)', () => {
  it('lists the spec sections in order and enables those built so far', () => {
    expect(NAV_ITEMS.map((i) => i.label)[1]).toBe('المشرفون');
    const enabled = NAV_ITEMS.filter((i) => i.phase <= CURRENT_PHASE).map((i) => i.href);
    for (const href of ['/admins', '/students', '/questions', '/flashcards', '/quizzes', '/settings']) {
      expect(enabled).toContain(href);
    }
  });
});

describe('admin security headers (§31)', () => {
  it('in production: HSTS, no framing and a restrictive CSP', async () => {
    const env = process.env as Record<string, string | undefined>;
    const previous = env.NODE_ENV;
    env.NODE_ENV = 'production';
    env.NEXT_PUBLIC_API_BASE_URL = 'https://api.example.com';
    try {
      const { default: config } = await import('../next.config');
      const [rule] = await config.headers!();
      const h = Object.fromEntries(rule!.headers.map((x) => [x.key, x.value]));
      expect(h['Strict-Transport-Security']).toContain('max-age=31536000');
      expect(h['X-Frame-Options']).toBe('DENY');
      expect(h['Content-Security-Policy']).toContain("frame-ancestors 'none'");
      expect(h['Content-Security-Policy']).toContain("object-src 'none'");
      expect(h['Content-Security-Policy']).toContain('https://api.example.com');
    } finally {
      env.NODE_ENV = previous;
    }
  });
});
