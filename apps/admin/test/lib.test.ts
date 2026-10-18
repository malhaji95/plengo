import { describe, expect, it } from 'vitest';
import { damascusDate, scopeBody, scopeLabel, termBody } from '@/lib/access';
import { ApiError, unwrap } from '@/lib/api';
import { activityLabel, timeAgo } from '@/lib/activity';
import { isActive, NAV_GROUPS } from '@/lib/nav';
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
  const SECTIONS = [
    '/',
    '/admins',
    '/students',
    '/teachers',
    '/tracks',
    '/levels',
    '/universities',
    '/subjects',
    '/questions',
    '/flashcards',
    '/quizzes',
    '/free-rules',
    '/promotions',
    '/coupons',
    '/entitlements',
    '/banners',
    '/countdowns',
    '/notifications',
    '/reports',
    '/question-analytics',
    '/import-export',
    '/audit-log',
    '/settings',
  ];

  it('keeps every spec section exactly once, grouped under a heading', () => {
    const hrefs = NAV_GROUPS.flatMap((g) => g.items.map((i) => i.href));
    expect([...hrefs].sort()).toEqual([...SECTIONS].sort());
    expect(new Set(hrefs).size).toBe(hrefs.length);
    expect(NAV_GROUPS[0]!.items[0]!.href).toBe('/');
    for (const group of NAV_GROUPS.slice(1)) expect(group.title).toBeTruthy();
  });

  it('highlights a section on its detail pages but the dashboard only on itself', () => {
    expect(isActive('/flashcards', '/flashcards/123')).toBe(true);
    expect(isActive('/flashcards', '/flashcards')).toBe(true);
    expect(isActive('/quizzes', '/question-analytics')).toBe(false);
    expect(isActive('/', '/')).toBe(true);
    expect(isActive('/', '/admins')).toBe(false);
  });
});

describe('dashboard activity', () => {
  it('turns audit actions into Arabic, and leaves unknown ones to the caller', () => {
    expect(activityLabel('question.created')).toBe('إنشاء سؤال');
    expect(activityLabel('coupon_batch.revoked')).toBe('إلغاء دفعة كوبونات');
    expect(activityLabel('structure.level.updated')).toBe('تعديل مرحلة تعليمية');
    expect(activityLabel('structure.teacher_track.created')).toBe('إنشاء مسار');
    expect(activityLabel('admin.2fa_enrolled')).toBe('تفعيل التحقق الثنائي لحساب مشرف');
    expect(activityLabel('quiz.published')).toBe('نشر اختبار');
    expect(activityLabel('question.free_override')).toBe('تغيير الوصول المجاني (سؤال)');
    expect(activityLabel('admin.created_via_cli')).toBe('إنشاء مشرف من سطر الأوامر');
    expect(activityLabel('question.flag_cleared')).toBe('إزالة علامة المراجعة عن سؤال');
    expect(activityLabel('mystery.thing')).toBeNull();
  });

  it('says how long ago something happened', () => {
    const now = Date.parse('2026-10-04T12:00:00Z');
    expect(timeAgo('2026-10-04T11:59:40Z', now)).toBe('الآن');
    expect(timeAgo('2026-10-04T11:55:00Z', now)).toContain('5');
    expect(timeAgo('2026-10-03T12:00:00Z', now)).toBe('أمس');
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

describe('demo API proxy (docs/demo-hosting.md)', () => {
  it('forwards /api to API_PROXY_TARGET only when it is set', async () => {
    const env = process.env as Record<string, string | undefined>;
    const { default: config } = await import('../next.config');
    delete env.API_PROXY_TARGET;
    expect(await config.rewrites!()).toEqual([]);
    env.API_PROXY_TARGET = 'https://plengo-api.onrender.com/';
    try {
      expect(await config.rewrites!()).toEqual([
        { source: '/api/:path*', destination: 'https://plengo-api.onrender.com/api/:path*' },
      ]);
    } finally {
      delete env.API_PROXY_TARGET;
    }
  });
});
