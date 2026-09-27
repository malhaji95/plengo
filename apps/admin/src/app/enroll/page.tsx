'use client';

import { useRouter } from 'next/navigation';
import QRCode from 'qrcode';
import { useEffect, useState } from 'react';
import { AuthShell } from '@/components/auth-shell';
import { FormError } from '@/components/form-error';
import { Button } from '@/components/ui/button';
import { Input, Label } from '@/components/ui/input';
import { api, ApiError, unwrap } from '@/lib/api';

type Setup = { totpUri: string; backupCodes: string[] };

/** First-login TOTP enrollment, mandatory for every admin (spec §0.3, §11.3). */
export default function EnrollPage() {
  const router = useRouter();
  const [setup, setSetup] = useState<Setup | null>(null);
  const [qr, setQr] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [pending, setPending] = useState(false);

  useEffect(() => {
    if (setup) void QRCode.toDataURL(setup.totpUri, { margin: 1, width: 200 }).then(setQr);
  }, [setup]);

  function handle(err: unknown) {
    if (err instanceof ApiError && (err.code === 'UNAUTHENTICATED' || err.code === 'AUTH_SESSION_EXPIRED')) {
      router.replace('/login');
      return;
    }
    setError(err instanceof ApiError ? err.message : 'حدث خطأ، حاول لاحقاً');
  }

  async function start(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setPending(true);
    setError(null);
    try {
      const password = String(new FormData(event.currentTarget).get('password'));
      setSetup(await unwrap(api.POST('/api/v1/admin/auth/2fa/enroll', { body: { password } })));
    } catch (err) {
      handle(err);
    } finally {
      setPending(false);
    }
  }

  async function confirm(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setPending(true);
    setError(null);
    try {
      const code = String(new FormData(event.currentTarget).get('code')).trim();
      await unwrap(api.POST('/api/v1/admin/auth/2fa/confirm', { body: { code } }));
      router.replace('/');
    } catch (err) {
      handle(err);
    } finally {
      setPending(false);
    }
  }

  if (!setup) {
    return (
      <AuthShell
        title="تفعيل التحقق الثنائي"
        description="التحقق الثنائي إلزامي لجميع المشرفين. أكّد كلمة المرور للبدء."
      >
        <form onSubmit={start} className="space-y-4">
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
            متابعة
          </Button>
        </form>
      </AuthShell>
    );
  }

  return (
    <AuthShell title="امسح الرمز" description="امسح الرمز بتطبيق المصادقة ثم أدخل الرمز الظاهر فيه.">
      <div className="flex justify-center">
        {qr ? <img src={qr} alt="رمز QR لتطبيق المصادقة" width={200} height={200} /> : null}
      </div>
      <div className="space-y-2">
        <p className="text-sm font-medium">رموز الاسترداد (احفظها في مكان آمن، تظهر مرة واحدة):</p>
        <ul dir="ltr" className="grid grid-cols-2 gap-1 rounded-lg bg-surface-muted p-3 font-mono text-sm">
          {setup.backupCodes.map((code) => (
            <li key={code}>{code}</li>
          ))}
        </ul>
      </div>
      <form onSubmit={confirm} className="space-y-4">
        <div className="space-y-2">
          <Label htmlFor="code">رمز التحقق</Label>
          <Input
            id="code"
            name="code"
            dir="ltr"
            className="text-center font-mono tracking-widest"
            inputMode="numeric"
            pattern="\d{6}"
            maxLength={6}
            autoComplete="one-time-code"
            required
          />
        </div>
        <FormError message={error} />
        <Button type="submit" className="w-full" disabled={pending}>
          تأكيد التفعيل
        </Button>
      </form>
    </AuthShell>
  );
}
