'use client';

import { useRouter } from 'next/navigation';
import { useState } from 'react';
import { AuthShell } from '@/components/auth-shell';
import { FormError } from '@/components/form-error';
import { Button } from '@/components/ui/button';
import { Input, Label } from '@/components/ui/input';
import { api, ApiError, unwrap } from '@/lib/api';

export default function TotpPage() {
  const router = useRouter();
  const [useBackup, setUseBackup] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [pending, setPending] = useState(false);

  async function onSubmit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const code = String(new FormData(event.currentTarget).get('code')).trim();
    setPending(true);
    setError(null);
    try {
      await unwrap(
        useBackup
          ? api.POST('/api/v1/admin/auth/2fa/backup', { body: { code } })
          : api.POST('/api/v1/admin/auth/2fa/verify', { body: { code } }),
      );
      router.replace('/');
    } catch (err) {
      if (err instanceof ApiError && err.code === 'AUTH_SESSION_EXPIRED') {
        router.replace('/login');
        return;
      }
      setError(err instanceof ApiError ? err.message : 'حدث خطأ، حاول لاحقاً');
    } finally {
      setPending(false);
    }
  }

  return (
    <AuthShell
      title="التحقق الثنائي"
      description={useBackup ? 'أدخل أحد رموز الاسترداد' : 'أدخل الرمز المكوّن من 6 أرقام من تطبيق المصادقة'}
    >
      <form onSubmit={onSubmit} className="space-y-4">
        <div className="space-y-2">
          <Label htmlFor="code">{useBackup ? 'رمز الاسترداد' : 'رمز التحقق'}</Label>
          <Input
            key={useBackup ? 'backup' : 'totp'}
            id="code"
            name="code"
            dir="ltr"
            className="text-center font-mono tracking-widest"
            inputMode={useBackup ? 'text' : 'numeric'}
            autoComplete="one-time-code"
            pattern={useBackup ? undefined : '\\d{6}'}
            maxLength={useBackup ? 64 : 6}
            required
            autoFocus
          />
        </div>
        <FormError message={error} />
        <Button type="submit" className="w-full" disabled={pending}>
          تحقق
        </Button>
        <Button type="button" variant="link" className="w-full" onClick={() => setUseBackup((v) => !v)}>
          {useBackup ? 'استخدام تطبيق المصادقة' : 'استخدام رمز استرداد'}
        </Button>
      </form>
    </AuthShell>
  );
}
