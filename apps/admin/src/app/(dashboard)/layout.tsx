'use client';

import { LogOut, Menu } from 'lucide-react';
import Link from 'next/link';
import { usePathname, useRouter } from 'next/navigation';
import { createContext, useContext, useEffect, useState } from 'react';
import { Button } from '@/components/ui/button';
import { api, ApiError, unwrap } from '@/lib/api';
import { CURRENT_PHASE, NAV_ITEMS } from '@/lib/nav';
import { cn } from '@/lib/utils';

type Admin = { id: string; email: string; fullName: string };

const AdminContext = createContext<Admin | null>(null);
export const useAdmin = () => useContext(AdminContext);

/**
 * Authenticated shell. Identity is resolved in the browser because the session cookie belongs to
 * the API origin; the API remains the only authority (spec §0.1).
 */
export default function DashboardLayout({ children }: { children: React.ReactNode }) {
  const router = useRouter();
  const pathname = usePathname();
  const [admin, setAdmin] = useState<Admin | null>(null);
  const [menuOpen, setMenuOpen] = useState(false);

  useEffect(() => {
    unwrap(api.GET('/api/v1/admin/me'))
      .then(setAdmin)
      .catch((err: unknown) => {
        router.replace(err instanceof ApiError && err.code === 'AUTH_2FA_REQUIRED' ? '/enroll' : '/login');
      });
  }, [router]);

  async function logout() {
    await unwrap(api.POST('/api/v1/admin/auth/logout')).catch(() => undefined);
    router.replace('/login');
  }

  if (!admin) {
    return <div className="flex min-h-dvh items-center justify-center text-muted">جارٍ التحميل…</div>;
  }

  return (
    <AdminContext.Provider value={admin}>
      <div className="flex min-h-dvh">
        <aside
          className={cn(
            'fixed inset-y-0 start-0 z-20 w-64 shrink-0 overflow-y-auto border-e border-border bg-surface p-3 shadow-lg lg:static lg:block lg:shadow-none',
            menuOpen ? 'block' : 'hidden',
          )}
        >
          <div className="mb-4 px-2 py-3 text-lg font-semibold">لوحة الإدارة</div>
          <nav className="space-y-0.5">
            {NAV_ITEMS.map((item) => {
              const enabled = item.phase <= CURRENT_PHASE;
              const active = pathname === item.href;
              const Icon = item.icon;
              const classes = cn(
                'flex items-center gap-3 rounded-lg px-3 py-2 text-sm',
                active ? 'bg-brand/10 font-medium text-brand' : 'hover:bg-surface-muted',
                !enabled && 'pointer-events-none opacity-45',
              );
              return enabled ? (
                <Link key={item.href} href={item.href} className={classes} onClick={() => setMenuOpen(false)}>
                  <Icon className="size-4 shrink-0" aria-hidden />
                  {item.label}
                </Link>
              ) : (
                <span key={item.href} className={classes} aria-disabled title={`المرحلة ${item.phase}`}>
                  <Icon className="size-4 shrink-0" aria-hidden />
                  {item.label}
                </span>
              );
            })}
          </nav>
        </aside>

        <div className="flex min-w-0 flex-1 flex-col">
          <header className="flex h-14 items-center justify-between border-b border-border bg-surface px-4">
            <Button
              variant="ghost"
              size="sm"
              className="lg:hidden"
              onClick={() => setMenuOpen((v) => !v)}
              aria-label="القائمة"
            >
              <Menu className="size-5" />
            </Button>
            <div className="ms-auto flex items-center gap-3 text-sm">
              <span className="text-muted">{admin.fullName}</span>
              <Button variant="outline" size="sm" onClick={logout}>
                <LogOut className="size-4" aria-hidden />
                خروج
              </Button>
            </div>
          </header>
          <main className="flex-1 p-4 lg:p-6">{children}</main>
        </div>
      </div>
    </AdminContext.Provider>
  );
}
