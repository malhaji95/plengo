'use client';

import { useEffect, useState } from 'react';
import { FormError } from '@/components/form-error';
import { Button } from '@/components/ui/button';
import { Card } from '@/components/ui/card';
import { Input, Label } from '@/components/ui/input';
import { api, unwrap } from '@/lib/api';
import type { components } from '@/lib/api-schema';
import { errorMessage, useLoad } from '@/lib/use-load';

type RemoteConfig = components['schemas']['RemoteConfig'];

const PLATFORMS = ['android', 'ios', 'web'] as const;
const FEATURES: [keyof RemoteConfig['features'], string][] = [
  ['teacherFollowing', 'متابعة المدرسين'],
  ['randomPractice', 'التدريب العشوائي'],
  ['studentDecks', 'بطاقات الطالب'],
  ['streaks', 'السلاسل اليومية'],
  ['contentReports', 'الإبلاغ عن المحتوى'],
];

/** Settings (spec §10.2, §26.2): remote config, access and learning settings. All audited. */
export default function SettingsPage() {
  const remote = useLoad(() => unwrap(api.GET('/api/v1/admin/settings/remote-config')), []);
  const access = useLoad(() => unwrap(api.GET('/api/v1/admin/settings/access')), []);
  const learning = useLoad(() => unwrap(api.GET('/api/v1/admin/settings/learning')), []);
  const [config, setConfig] = useState<RemoteConfig | null>(null);
  const [streak, setStreak] = useState('2');
  const [message, setMessage] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => setConfig(remote.data ?? null), [remote.data]);
  useEffect(() => {
    if (learning.data) setStreak(String(learning.data.mistakeMasteryStreak));
  }, [learning.data]);

  async function run(call: () => Promise<unknown>) {
    setError(null);
    setMessage(null);
    try {
      await call();
      setMessage('تم الحفظ');
    } catch (err) {
      setError(errorMessage(err));
    }
  }

  const set = (patch: Partial<RemoteConfig>) => setConfig((c) => (c ? { ...c, ...patch } : c));

  return (
    <div className="mx-auto max-w-5xl space-y-4">
      <h1 className="text-xl font-semibold">الإعدادات</h1>
      <FormError message={remote.error ?? access.error ?? learning.error ?? error} />
      {message ? <p className="text-sm text-brand">{message}</p> : null}
      {config ? (
        <Card className="space-y-4">
          <h2 className="font-semibold">إعدادات التطبيق عن بُعد</h2>
          <div className="grid gap-3 md:grid-cols-3">
            {PLATFORMS.map((p) => (
              <div key={p} className="space-y-2">
                <Label htmlFor={`min-${p}`}>أدنى إصدار مدعوم ({p})</Label>
                <Input
                  id={`min-${p}`}
                  dir="ltr"
                  value={config.minSupportedVersion[p]}
                  onChange={(e) =>
                    set({ minSupportedVersion: { ...config.minSupportedVersion, [p]: e.target.value } })
                  }
                />
                <Label htmlFor={`latest-${p}`}>أحدث إصدار ({p})</Label>
                <Input
                  id={`latest-${p}`}
                  dir="ltr"
                  value={config.latestVersion[p]}
                  onChange={(e) => set({ latestVersion: { ...config.latestVersion, [p]: e.target.value } })}
                />
              </div>
            ))}
          </div>
          <div className="flex flex-wrap gap-4">
            {FEATURES.map(([key, label]) => (
              <label key={key} className="flex items-center gap-2 text-sm">
                <input
                  type="checkbox"
                  checked={config.features[key]}
                  onChange={(e) => set({ features: { ...config.features, [key]: e.target.checked } })}
                />
                {label}
              </label>
            ))}
          </div>
          <div className="grid gap-3 md:grid-cols-2">
            <div className="space-y-1">
              <Label htmlFor="new-per-day">البطاقات الجديدة يومياً (افتراضي)</Label>
              <Input
                id="new-per-day"
                type="number"
                dir="ltr"
                value={config.srsDefaults.newCardsPerDay}
                onChange={(e) =>
                  set({ srsDefaults: { ...config.srsDefaults, newCardsPerDay: Number(e.target.value) } })
                }
              />
            </div>
            <div className="space-y-1">
              <Label htmlFor="reviews-per-day">أقصى عدد مراجعات يومياً (افتراضي)</Label>
              <Input
                id="reviews-per-day"
                type="number"
                dir="ltr"
                value={config.srsDefaults.maxReviewsPerDay}
                onChange={(e) =>
                  set({ srsDefaults: { ...config.srsDefaults, maxReviewsPerDay: Number(e.target.value) } })
                }
              />
            </div>
            {(
              [
                [
                  'support-email',
                  'بريد الدعم',
                  config.support.email,
                  (v: string) => set({ support: { ...config.support, email: v } }),
                ],
                [
                  'support-whatsapp',
                  'واتساب الدعم',
                  config.support.whatsapp,
                  (v: string) => set({ support: { ...config.support, whatsapp: v } }),
                ],
                [
                  'store-android',
                  'رابط Google Play',
                  config.storeUrls.android,
                  (v: string) => set({ storeUrls: { ...config.storeUrls, android: v } }),
                ],
                [
                  'store-ios',
                  'رابط App Store',
                  config.storeUrls.ios,
                  (v: string) => set({ storeUrls: { ...config.storeUrls, ios: v } }),
                ],
                [
                  'privacy-url',
                  'رابط سياسة الخصوصية',
                  config.privacyPolicyUrl,
                  (v: string) => set({ privacyPolicyUrl: v }),
                ],
                ['terms-url', 'رابط الشروط', config.termsUrl, (v: string) => set({ termsUrl: v })],
              ] as const
            ).map(([id, label, value, onChange]) => (
              <div key={id} className="space-y-1">
                <Label htmlFor={id}>{label}</Label>
                <Input id={id} dir="ltr" value={value} onChange={(e) => onChange(e.target.value)} />
              </div>
            ))}
          </div>
          <Button
            onClick={() =>
              void run(async () =>
                setConfig(await unwrap(api.PUT('/api/v1/admin/settings/remote-config', { body: config }))),
              )
            }
          >
            حفظ إعدادات التطبيق
          </Button>
        </Card>
      ) : null}
      {access.data ? (
        <Card className="space-y-3">
          <h2 className="font-semibold">الوصول</h2>
          <label className="flex items-center gap-2 text-sm">
            <input
              type="checkbox"
              checked={access.data.allowTemporaryToPermanentUpgrade}
              onChange={(e) =>
                void run(async () => {
                  await unwrap(
                    api.PUT('/api/v1/admin/settings/access', {
                      body: { allowTemporaryToPermanentUpgrade: e.target.checked },
                    }),
                  );
                  await access.reload();
                })
              }
            />
            السماح بترقية الوصول المؤقت إلى دائم بكود دائم
          </label>
        </Card>
      ) : null}
      <Card className="space-y-3">
        <h2 className="font-semibold">التعلم</h2>
        <div className="flex items-end gap-2">
          <div className="space-y-1">
            <Label htmlFor="mastery">عدد الإجابات الصحيحة المتتالية لإتقان خطأ</Label>
            <Input
              id="mastery"
              type="number"
              min={1}
              max={10}
              dir="ltr"
              className="w-32"
              value={streak}
              onChange={(e) => setStreak(e.target.value)}
            />
          </div>
          <Button
            onClick={() =>
              void run(() =>
                unwrap(
                  api.PUT('/api/v1/admin/settings/learning', {
                    body: { mistakeMasteryStreak: Number(streak) },
                  }),
                ),
              )
            }
          >
            حفظ
          </Button>
        </div>
      </Card>
    </div>
  );
}
