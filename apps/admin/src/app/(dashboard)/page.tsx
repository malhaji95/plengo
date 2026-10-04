'use client';

import {
  BarChart3,
  Bell,
  ClipboardList,
  FileQuestion,
  Flag,
  FolderInput,
  History,
  Image as ImageIcon,
  Layers,
  ShieldCheck,
  Ticket,
  type LucideIcon,
} from 'lucide-react';
import Link from 'next/link';
import { Card } from '@/components/ui/card';
import { activityLabel, timeAgo } from '@/lib/activity';
import { api, unwrap } from '@/lib/api';
import { useLoad } from '@/lib/use-load';
import { cn } from '@/lib/utils';
import { useAdmin } from './layout';

/** "200+" when the first page was full and more remain. */
const count = (page: { items: unknown[]; nextCursor: string | null } | null) =>
  page ? `${page.items.length}${page.nextCursor ? '+' : ''}` : '—';

/**
 * The admin home: what needs attention now, recent activity and shortcuts. Every number comes from
 * an existing endpoint; there are no usage charts until the API records usage.
 */
export default function DashboardHome() {
  const admin = useAdmin();
  const reports = useLoad(
    () => unwrap(api.GET('/api/v1/admin/reports', { params: { query: { status: 'open', limit: 200 } } })),
    [],
  );
  const flagged = useLoad(
    () =>
      unwrap(
        api.GET('/api/v1/admin/question-analytics', { params: { query: { flagged: 'true', limit: 200 } } }),
      ),
    [],
  );
  const banners = useLoad(() => unwrap(api.GET('/api/v1/admin/banners')), []);
  const admins = useLoad(() => unwrap(api.GET('/api/v1/admin/admins')), []);
  const activity = useLoad(
    () => unwrap(api.GET('/api/v1/admin/audit-logs', { params: { query: { limit: 8 } } })),
    [],
  );

  const stats: Stat[] = [
    {
      label: 'بلاغات مفتوحة',
      value: count(reports.data),
      hint: 'بانتظار المراجعة',
      href: '/reports',
      icon: Flag,
      tone: 'red',
    },
    {
      label: 'أسئلة بحاجة لمراجعة',
      value: count(flagged.data),
      hint: 'علّمتها قاعدة التحليلات',
      href: '/question-analytics',
      icon: BarChart3,
      tone: 'orange',
    },
    {
      label: 'إعلانات نشطة',
      value: banners.data ? String(banners.data.filter((b) => b.isActive).length) : '—',
      hint: banners.data ? `من ${banners.data.length} إعلاناً` : '',
      href: '/banners',
      icon: ImageIcon,
      tone: 'blue',
    },
    {
      label: 'مشرفون نشطون',
      value: admins.data ? String(admins.data.filter((a) => a.status === 'active').length) : '—',
      hint: admins.data ? `من ${admins.data.length}` : '',
      href: '/admins',
      icon: ShieldCheck,
      tone: 'green',
    },
  ];

  return (
    <div className="mx-auto max-w-6xl space-y-6">
      <div>
        <h1 className="font-heading text-2xl font-bold">مرحباً بك، {admin?.fullName} 👋</h1>
        <p className="mt-1 text-sm text-muted">نظرة سريعة على ما يحتاج انتباهك اليوم.</p>
      </div>

      <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        {stats.map((s) => (
          <StatCard key={s.href} {...s} />
        ))}
      </div>

      <div className="grid gap-6 lg:grid-cols-5">
        <Card className="space-y-4 lg:col-span-3">
          <div className="flex items-center justify-between">
            <h2 className="font-semibold">آخر العمليات</h2>
            <Link href="/audit-log" className="text-sm font-medium text-brand hover:underline">
              السجل كاملاً
            </Link>
          </div>
          {activity.error ? (
            <p className="text-sm text-danger">{activity.error}</p>
          ) : !activity.data ? (
            <p className="text-sm text-muted">جارٍ التحميل…</p>
          ) : activity.data.items.length === 0 ? (
            <p className="text-sm text-muted">لا توجد عمليات بعد.</p>
          ) : (
            <ul className="divide-y divide-border">
              {activity.data.items.map((e) => {
                const label = activityLabel(e.action);
                return (
                  <li key={e.id} className="flex items-start gap-3 py-3">
                    <span className="mt-0.5 grid size-9 shrink-0 place-items-center rounded-lg bg-accent/25">
                      <History className="size-4" aria-hidden />
                    </span>
                    <div className="min-w-0 flex-1">
                      <p className="text-sm font-medium">
                        {label ?? (
                          <span dir="ltr" className="font-mono text-xs">
                            {e.action}
                          </span>
                        )}
                      </p>
                      <p className="text-xs text-muted">{e.actorName ?? 'النظام'}</p>
                    </div>
                    <time className="shrink-0 text-xs text-muted" dateTime={e.createdAt}>
                      {timeAgo(e.createdAt)}
                    </time>
                  </li>
                );
              })}
            </ul>
          )}
        </Card>

        <Card className="space-y-4 lg:col-span-2">
          <h2 className="font-semibold">اختصارات</h2>
          <div className="grid grid-cols-2 gap-3">
            {SHORTCUTS.map((s) => (
              <Link
                key={s.href}
                href={s.href}
                className="flex flex-col items-start gap-2 rounded-xl border border-border p-3 text-sm font-medium transition-colors hover:bg-surface-muted"
              >
                <span className="grid size-9 place-items-center rounded-lg bg-brand/10 text-brand">
                  <s.icon className="size-4" aria-hidden />
                </span>
                {s.label}
              </Link>
            ))}
          </div>
        </Card>
      </div>
    </div>
  );
}

const SHORTCUTS: { href: string; label: string; icon: LucideIcon }[] = [
  { href: '/questions', label: 'إضافة سؤال', icon: FileQuestion },
  { href: '/flashcards', label: 'رفع بطاقات', icon: Layers },
  { href: '/quizzes', label: 'اختبار جديد', icon: ClipboardList },
  { href: '/import-export', label: 'استيراد أسئلة', icon: FolderInput },
  { href: '/notifications', label: 'إرسال إشعار', icon: Bell },
  { href: '/coupons', label: 'دفعة كوبونات', icon: Ticket },
];

interface Stat {
  label: string;
  value: string;
  hint: string;
  href: string;
  icon: LucideIcon;
  tone: 'red' | 'orange' | 'blue' | 'green';
}

/** Pale logo-colour tints behind dark icons; the text itself stays on the card surface. */
const TONES: Record<Stat['tone'], string> = {
  red: 'bg-[#fbd5d5] text-[#1b1b1b]',
  orange: 'bg-[#fde3c2] text-[#1b1b1b]',
  blue: 'bg-[#cdebfa] text-[#1b1b1b]',
  green: 'bg-[#d9f7dd] text-[#1b1b1b]',
};

function StatCard({ label, value, hint, href, icon: Icon, tone }: Stat) {
  return (
    <Link
      href={href}
      className="group flex items-center gap-4 rounded-xl border border-border bg-surface p-5 shadow-sm transition-shadow hover:shadow-md"
    >
      <span className={cn('grid size-12 shrink-0 place-items-center rounded-xl', TONES[tone])}>
        <Icon className="size-5" aria-hidden />
      </span>
      <div className="min-w-0">
        <p className="text-sm text-muted">{label}</p>
        <p className="text-2xl font-bold tabular-nums">{value}</p>
        {hint && <p className="truncate text-xs text-muted">{hint}</p>}
      </div>
    </Link>
  );
}
