'use client';

import { useState } from 'react';
import { FormError } from '@/components/form-error';
import { Button } from '@/components/ui/button';
import { Card } from '@/components/ui/card';
import { Input, Label } from '@/components/ui/input';
import { formatDate } from '@/lib/access';
import { api, unwrap } from '@/lib/api';
import { errorMessage, useLoad } from '@/lib/use-load';
import { useAdmin } from '../layout';

/**
 * Admin accounts (spec §11.3, §26.2): create, deactivate, reactivate, and reset another admin's
 * 2FA. The last active admin cannot be deactivated. Every action is audited.
 */
export default function AdminsPage() {
  const admins = useLoad(() => unwrap(api.GET('/api/v1/admin/admins')), []);
  const me = useAdmin();
  const [form, setForm] = useState({ email: '', fullName: '', password: '' });
  const [error, setError] = useState<string | null>(null);

  async function run(call: () => Promise<unknown>) {
    setError(null);
    try {
      await call();
      await admins.reload();
    } catch (err) {
      setError(errorMessage(err));
    }
  }

  const action = (id: string, path: 'deactivate' | 'reactivate' | 'reset-2fa') =>
    run(() => {
      const opts = { params: { path: { id } } };
      if (path === 'deactivate') return unwrap(api.POST('/api/v1/admin/admins/{id}/deactivate', opts));
      if (path === 'reactivate') return unwrap(api.POST('/api/v1/admin/admins/{id}/reactivate', opts));
      return unwrap(api.POST('/api/v1/admin/admins/{id}/reset-2fa', opts));
    });

  return (
    <div className="mx-auto max-w-5xl space-y-4">
      <h1 className="text-xl font-semibold">المشرفون</h1>
      <Card className="space-y-3">
        <h2 className="font-semibold">إضافة مشرف</h2>
        <form
          className="grid gap-3 md:grid-cols-3"
          onSubmit={(e) => {
            e.preventDefault();
            void run(async () => {
              await unwrap(api.POST('/api/v1/admin/admins', { body: form }));
              setForm({ email: '', fullName: '', password: '' });
            });
          }}
        >
          <div className="space-y-1">
            <Label htmlFor="admin-name">الاسم</Label>
            <Input
              id="admin-name"
              value={form.fullName}
              onChange={(e) => setForm({ ...form, fullName: e.target.value })}
            />
          </div>
          <div className="space-y-1">
            <Label htmlFor="admin-email">البريد الإلكتروني</Label>
            <Input
              id="admin-email"
              dir="ltr"
              type="email"
              value={form.email}
              onChange={(e) => setForm({ ...form, email: e.target.value })}
            />
          </div>
          <div className="space-y-1">
            <Label htmlFor="admin-password">كلمة مرور مؤقتة (10 أحرف على الأقل)</Label>
            <Input
              id="admin-password"
              dir="ltr"
              type="password"
              value={form.password}
              onChange={(e) => setForm({ ...form, password: e.target.value })}
            />
          </div>
          <div className="md:col-span-3">
            <Button
              type="submit"
              disabled={!form.email || form.fullName.trim().length < 2 || form.password.length < 10}
            >
              إضافة
            </Button>
            <p className="mt-2 text-xs text-muted">
              يُطلب من المشرف الجديد تفعيل التحقق الثنائي عند أول دخول.
            </p>
          </div>
        </form>
      </Card>
      <FormError message={admins.error ?? error} />
      <Card className="overflow-x-auto p-0">
        <table className="w-full text-sm">
          <thead className="border-b border-border text-muted">
            <tr>
              <th className="p-3 text-start font-medium">المشرف</th>
              <th className="p-3 text-start font-medium">الحالة</th>
              <th className="p-3 text-start font-medium">التحقق الثنائي</th>
              <th className="p-3 text-start font-medium">آخر نشاط</th>
              <th className="p-3" />
            </tr>
          </thead>
          <tbody>
            {(admins.data ?? []).map((a) => {
              const self = a.id === me?.id;
              return (
                <tr key={a.id} className="border-b border-border last:border-0">
                  <td className="p-3">
                    {a.fullName}
                    {self ? ' (أنت)' : ''}
                    <div dir="ltr" className="text-start text-xs text-muted">
                      {a.email}
                    </div>
                  </td>
                  <td className="p-3">{a.status === 'active' ? 'نشط' : 'معطّل'}</td>
                  <td className="p-3">{a.twoFactorEnabled ? 'مفعّل' : 'بانتظار التفعيل'}</td>
                  <td className="p-3">{a.lastSeenAt ? formatDate(a.lastSeenAt) : '—'}</td>
                  <td className="space-x-2 p-3 text-end">
                    {a.status === 'active' ? (
                      <Button
                        variant="outline"
                        onClick={() => {
                          if (window.confirm(`تعطيل حساب ${a.fullName}؟ ستنتهي جلساته فوراً.`))
                            void action(a.id, 'deactivate');
                        }}
                      >
                        تعطيل
                      </Button>
                    ) : (
                      <Button variant="outline" onClick={() => void action(a.id, 'reactivate')}>
                        إعادة التفعيل
                      </Button>
                    )}
                    {!self && a.twoFactorEnabled ? (
                      <Button
                        variant="ghost"
                        onClick={() => {
                          if (window.confirm(`إعادة ضبط التحقق الثنائي لـ ${a.fullName}؟`))
                            void action(a.id, 'reset-2fa');
                        }}
                      >
                        إعادة ضبط التحقق الثنائي
                      </Button>
                    ) : null}
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </Card>
    </div>
  );
}
