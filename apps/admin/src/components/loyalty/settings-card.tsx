'use client';

import { useEffect, useState } from 'react';
import { FormError } from '@/components/form-error';
import { Button } from '@/components/ui/button';
import { Card } from '@/components/ui/card';
import { Input, Label } from '@/components/ui/input';
import { api, unwrap } from '@/lib/api';
import { settingsProblems } from '@/lib/loyalty';
import { errorMessage, useLoad } from '@/lib/use-load';

type Fields = { pointsPerReview: string; dailyCap: string; pointsPerCorrectQuestion: string };

/** Loyalty earning rules (v3 §10), stored in app settings. Audited by the API. */
export function LoyaltySettingsCard() {
  const settings = useLoad(() => unwrap(api.GET('/api/v1/admin/settings/loyalty')), []);
  const [enabled, setEnabled] = useState(true);
  const [fields, setFields] = useState<Fields>({
    pointsPerReview: '1',
    dailyCap: '50',
    pointsPerCorrectQuestion: '0',
  });
  const [message, setMessage] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!settings.data) return;
    setEnabled(settings.data.enabled);
    setFields({
      pointsPerReview: String(settings.data.pointsPerReview),
      dailyCap: String(settings.data.dailyCap),
      pointsPerCorrectQuestion: String(settings.data.pointsPerCorrectQuestion),
    });
  }, [settings.data]);

  const problems = settingsProblems(fields);

  async function save() {
    setError(null);
    setMessage(null);
    try {
      await unwrap(
        api.PUT('/api/v1/admin/settings/loyalty', {
          body: {
            enabled,
            pointsPerReview: Number(fields.pointsPerReview),
            dailyCap: Number(fields.dailyCap),
            pointsPerCorrectQuestion: Number(fields.pointsPerCorrectQuestion),
          },
        }),
      );
      setMessage('تم الحفظ');
      await settings.reload();
    } catch (err) {
      setError(errorMessage(err));
    }
  }

  const field = (key: keyof Fields, id: string, label: string) => (
    <div className="space-y-1">
      <Label htmlFor={id}>{label}</Label>
      <Input
        id={id}
        type="number"
        min={0}
        dir="ltr"
        className="w-32"
        value={fields[key]}
        onChange={(e) => setFields((f) => ({ ...f, [key]: e.target.value }))}
      />
    </div>
  );

  return (
    <Card className="space-y-3">
      <h2 className="font-semibold">برنامج الولاء</h2>
      <FormError message={settings.error ?? error} />
      <label className="flex items-center gap-2 text-sm">
        <input type="checkbox" checked={enabled} onChange={(e) => setEnabled(e.target.checked)} />
        تفعيل كسب النقاط واستبدالها
      </label>
      <div className="flex flex-wrap items-end gap-3">
        {field('pointsPerReview', 'loyalty-review', 'نقاط لكل بطاقة مُراجعة')}
        {field('dailyCap', 'loyalty-cap', 'الحد الأقصى اليومي')}
        {field('pointsPerCorrectQuestion', 'loyalty-correct', 'نقاط لكل إجابة صحيحة')}
        <Button disabled={problems.length > 0 || !settings.data} onClick={() => void save()}>
          حفظ
        </Button>
      </div>
      {problems.length ? <p className="text-sm text-danger">{problems[0]}</p> : null}
      {message ? <p className="text-sm text-brand">{message}</p> : null}
      <p className="text-xs text-muted">
        تُحتسب النقاط عند مزامنة مراجعات البطاقات الرسمية (مرة واحدة لكل مراجعة)، والإجابة الصحيحة مرة واحدة
        لكل سؤال في اليوم. يبدأ اليوم الساعة 4 فجراً بتوقيت دمشق كالسلسلة اليومية. 0 في الحد اليومي يعني بلا
        حد.
      </p>
    </Card>
  );
}
