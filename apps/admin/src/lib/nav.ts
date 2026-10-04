import {
  BarChart3,
  Bell,
  BookOpen,
  CalendarClock,
  ClipboardList,
  FileQuestion,
  Flag,
  FolderInput,
  Gift,
  GraduationCap,
  History,
  Image,
  KeyRound,
  Layers,
  LayoutDashboard,
  Library,
  Route,
  School,
  Settings,
  ShieldCheck,
  Ticket,
  UserRound,
  Users,
  type LucideIcon,
} from 'lucide-react';

export interface NavItem {
  href: string;
  label: string;
  icon: LucideIcon;
}

export interface NavGroup {
  /** Omitted for the dashboard link at the top. */
  title?: string;
  items: NavItem[];
}

/** Every admin section of spec §26.1, grouped by task so the sidebar stays scannable. */
export const NAV_GROUPS: NavGroup[] = [
  { items: [{ href: '/', label: 'الرئيسية', icon: LayoutDashboard }] },
  {
    title: 'الحسابات',
    items: [
      { href: '/admins', label: 'المشرفون', icon: ShieldCheck },
      { href: '/students', label: 'الطلاب', icon: Users },
    ],
  },
  {
    title: 'البنية التعليمية',
    items: [
      { href: '/levels', label: 'المراحل التعليمية', icon: GraduationCap },
      { href: '/universities', label: 'الجامعات · الكليات · السنوات', icon: School },
      { href: '/subjects', label: 'المواد · الوحدات · الدروس', icon: Library },
      { href: '/teachers', label: 'المدرسون', icon: UserRound },
      { href: '/tracks', label: 'المسارات', icon: Route },
    ],
  },
  {
    title: 'المحتوى',
    items: [
      { href: '/questions', label: 'الأسئلة', icon: FileQuestion },
      { href: '/flashcards', label: 'البطاقات التعليمية', icon: Layers },
      { href: '/quizzes', label: 'الاختبارات', icon: ClipboardList },
      { href: '/import-export', label: 'الاستيراد والتصدير', icon: FolderInput },
    ],
  },
  {
    title: 'الوصول',
    items: [
      { href: '/free-rules', label: 'قواعد المحتوى المجاني', icon: BookOpen },
      { href: '/promotions', label: 'العروض المؤقتة', icon: Gift },
      { href: '/coupons', label: 'الكوبونات · دفعات الكوبونات', icon: Ticket },
      { href: '/entitlements', label: 'صلاحيات الوصول', icon: KeyRound },
    ],
  },
  {
    title: 'التواصل مع الطلاب',
    items: [
      { href: '/banners', label: 'الإعلانات (البانرات)', icon: Image },
      { href: '/countdowns', label: 'العد التنازلي للامتحانات', icon: CalendarClock },
      { href: '/notifications', label: 'الإشعارات', icon: Bell },
    ],
  },
  {
    title: 'الجودة والمتابعة',
    items: [
      { href: '/reports', label: 'البلاغات', icon: Flag },
      { href: '/question-analytics', label: 'تحليلات الأسئلة', icon: BarChart3 },
      { href: '/audit-log', label: 'سجل العمليات', icon: History },
    ],
  },
  { title: 'النظام', items: [{ href: '/settings', label: 'الإعدادات', icon: Settings }] },
];

/** The dashboard matches only itself; every other section also owns its detail pages. */
export function isActive(href: string, pathname: string): boolean {
  return href === '/' ? pathname === '/' : pathname === href || pathname.startsWith(`${href}/`);
}
