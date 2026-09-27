'use client';

import { useRouter } from 'next/navigation';
import { useState } from 'react';
import { AuthShell } from '@/components/auth-shell';
import { FormError } from '@/components/form-error';
import { Button } from '@/components/ui/button';
import { Input, Label } from '@/components/ui/input';
import { api, ApiError, unwrap } from '@/lib/api';

export default function LoginPage() {
  const router = useRouter();
  const [error, setError] = useState<string | null>(null);
  const [pending, setPending] = useState(false);

  async function onSubmit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const form = new FormData(event.currentTarget);
    setPending(true);
    setError(null);
    try {
      const res = await unwrap(
        api.POST('/api/v1/admin/auth/login', {
          body: { email: String(form.get('email')), password: String(form.get('password')) },
        }),
      );
      router.replace(res.next === 'totp' ? '/login/totp' : '/enroll');
    } catch (err) {
      setError(err instanceof ApiError ? err.message : 'حدث خطأ، حاول لاحقاً');
    } finally {
      setPending(false);
    }
  }

  return (
    <AuthShell title="تسجيل دخول المشرفين" description="أدخل بريدك الإلكتروني وكلمة المرور">
      <form onSubmit={onSubmit} className="space-y-4">
        <div className="space-y-2">
          <Label htmlFor="email">البريد الإلكتروني</Label>
          <Input id="email" name="email" type="email" dir="ltr" autoComplete="username" required />
        </div>
        <div className="space-y-2">
          <Label htmlFor="password">كلمة المرور</Label>
          <Input
            id="password"
            name="password"
            type="password"
            dir="ltr"
            autoComplete="current-password"
            required
          />
        </div>
        <FormError message={error} />
        <Button type="submit" className="w-full" disabled={pending}>
          {pending ? 'جارٍ الدخول…' : 'دخول'}
        </Button>
      </form>
    </AuthShell>
  );
}
