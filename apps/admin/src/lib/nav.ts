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
  /** Phase in which the section is implemented (spec §39); later sections render disabled. */
  phase: number;
}

export const CURRENT_PHASE = 11;

/** Admin navigation, in the order of spec §26.1. */
export const NAV_ITEMS: NavItem[] = [
  { href: '/', label: 'الرئيسية', icon: LayoutDashboard, phase: 1 },
  { href: '/admins', label: 'المشرفون', icon: ShieldCheck, phase: 1 },
  { href: '/students', label: 'الطلاب', icon: Users, phase: 4 },
  { href: '/teachers', label: 'المدرسون', icon: UserRound, phase: 3 },
  { href: '/tracks', label: 'المسارات', icon: Route, phase: 3 },
  { href: '/levels', label: 'المراحل التعليمية', icon: GraduationCap, phase: 2 },
  { href: '/universities', label: 'الجامعات · الكليات · السنوات', icon: School, phase: 2 },
  { href: '/subjects', label: 'المواد · الوحدات · الدروس', icon: Library, phase: 2 },
  { href: '/questions', label: 'الأسئلة', icon: FileQuestion, phase: 5 },
  { href: '/flashcards', label: 'البطاقات التعليمية', icon: Layers, phase: 6 },
  { href: '/quizzes', label: 'الاختبارات', icon: ClipboardList, phase: 7 },
  { href: '/free-rules', label: 'قواعد المحتوى المجاني', icon: BookOpen, phase: 4 },
  { href: '/promotions', label: 'العروض المؤقتة', icon: Gift, phase: 4 },
  { href: '/coupons', label: 'الكوبونات · دفعات الكوبونات', icon: Ticket, phase: 4 },
  { href: '/entitlements', label: 'صلاحيات الوصول', icon: KeyRound, phase: 4 },
  { href: '/banners', label: 'الإعلانات (البانرات)', icon: Image, phase: 10 },
  { href: '/countdowns', label: 'العد التنازلي للامتحانات', icon: CalendarClock, phase: 10 },
  { href: '/notifications', label: 'الإشعارات', icon: Bell, phase: 10 },
  { href: '/reports', label: 'البلاغات', icon: Flag, phase: 11 },
  { href: '/question-analytics', label: 'تحليلات الأسئلة', icon: BarChart3, phase: 11 },
  { href: '/import-export', label: 'الاستيراد والتصدير', icon: FolderInput, phase: 11 },
  { href: '/audit-log', label: 'سجل العمليات', icon: History, phase: 11 },
  { href: '/settings', label: 'الإعدادات', icon: Settings, phase: 4 },
];
