'use client';

import { useState } from 'react';
import { ScopePicker, selectClass } from '@/components/access/scope-picker';
import { FormError } from '@/components/form-error';
import { Button } from '@/components/ui/button';
import { Card } from '@/components/ui/card';
import { Input, Label } from '@/components/ui/input';
import {
  EMPTY_SCOPE,
  formatDateTime,
  scopeBody,
  scopeLabel,
  scopeReady,
  type ScopeValue,
} from '@/lib/access';
import { api, unwrap } from '@/lib/api';
import type { components } from '@/lib/api-schema';
import { errorMessage, useLoad } from '@/lib/use-load';

type RuleRequest = components['schemas']['FreeRuleRequest'];
type Preview = components['schemas']['FreeRulePreview'];

const KINDS: Record<RuleRequest['contentKind'], string> = {
  all: 'كل المحتوى',
  questions: 'الأسئلة',
  flashcard_decks: 'مجموعات البطاقات',
  quizzes: 'الاختبارات',
};
const RULES: Record<RuleRequest['ruleType'], string> = {
  manual: 'يدوي (العناصر المحددة فقط)',
  first_n_items: 'أول N عنصر',
  first_n_lessons: 'محتوى أول N درس',
  first_unit: 'محتوى الوحدة الأولى',
  percentage: 'نسبة مئوية من البداية',
};
const needsValue = (r: RuleRequest['ruleType']) =>
  r === 'first_n_items' || r === 'first_n_lessons' || r === 'percentage';

function ruleText(r: { ruleType: RuleRequest['ruleType']; ruleValue?: number | null }) {
  const label = RULES[r.ruleType];
  return needsValue(r.ruleType)
    ? `${label.replace('N', String(r.ruleValue))}${r.ruleType === 'percentage' ? ` (${r.ruleValue}%)` : ''}`
    : label;
}

/**
 * Free content rules (spec §8.4). Changing a rule shows how many items become free before it is
 * applied; a background job then recomputes `is_free` for rule-based items in the scope.
 */
export default function FreeRulesPage() {
  const rules = useLoad(() => unwrap(api.GET('/api/v1/admin/free-rules')), []);
  const [scope, setScope] = useState<ScopeValue>(EMPTY_SCOPE);
  const [contentKind, setContentKind] = useState<RuleRequest['contentKind']>('all');
  const [ruleType, setRuleType] = useState<RuleRequest['ruleType']>('first_n_items');
  const [ruleValue, setRuleValue] = useState(10);
  const [preview, setPreview] = useState<Preview | null>(null);
  const [error, setError] = useState<string | null>(null);

  const body = (): RuleRequest => ({
    ...scopeBody(scope),
    contentKind,
    ruleType,
    ruleValue: needsValue(ruleType) ? ruleValue : null,
  });
  const reset = () => setPreview(null);

  async function run<T>(call: () => Promise<T>) {
    setError(null);
    try {
      return await call();
    } catch (err) {
      setError(errorMessage(err));
      return null;
    }
  }

  return (
    <div className="mx-auto max-w-5xl space-y-4">
      <h1 className="text-xl font-semibold">قواعد المحتوى المجاني</h1>
      <Card className="space-y-3">
        <h2 className="font-semibold">تعيين قاعدة</h2>
        <ScopePicker
          value={scope}
          onChange={(v) => {
            setScope(v);
            reset();
          }}
        />
        <div className="grid gap-3 sm:grid-cols-3">
          <div className="space-y-1">
            <Label htmlFor="rule-kind">نوع المحتوى</Label>
            <select
              id="rule-kind"
              className={selectClass}
              value={contentKind}
              onChange={(e) => {
                setContentKind(e.target.value as RuleRequest['contentKind']);
                reset();
              }}
            >
              {Object.entries(KINDS).map(([k, label]) => (
                <option key={k} value={k}>
                  {label}
                </option>
              ))}
            </select>
          </div>
          <div className="space-y-1">
            <Label htmlFor="rule-type">القاعدة</Label>
            <select
              id="rule-type"
              className={selectClass}
              value={ruleType}
              onChange={(e) => {
                setRuleType(e.target.value as RuleRequest['ruleType']);
                reset();
              }}
            >
              {Object.entries(RULES).map(([k, label]) => (
                <option key={k} value={k}>
                  {label}
                </option>
              ))}
            </select>
          </div>
          {needsValue(ruleType) ? (
            <div className="space-y-1">
              <Label htmlFor="rule-value">{ruleType === 'percentage' ? 'النسبة %' : 'N'}</Label>
              <Input
                id="rule-value"
                type="number"
                dir="ltr"
                min={1}
                max={ruleType === 'percentage' ? 100 : 100000}
                value={ruleValue}
                onChange={(e) => {
                  setRuleValue(Number(e.target.value));
                  reset();
                }}
              />
            </div>
          ) : null}
        </div>
        <FormError message={error} />
        {preview ? (
          <div className="space-y-2 rounded-lg bg-surface-muted p-3 text-sm">
            <p>
              سيصبح {preview.freeCount} عنصراً مجانياً و{preview.paidCount} مدفوعة.
            </p>
            {preview.freeCount + preview.paidCount === 0 ? (
              <p className="text-muted">
                لا يوجد محتوى منشور في هذا النطاق بعد؛ ستُطبّق القاعدة على المحتوى عند نشره.
              </p>
            ) : null}
            <div className="flex gap-2">
              <Button
                onClick={async () => {
                  const saved = await run(() =>
                    unwrap(api.PUT('/api/v1/admin/free-rules', { body: body() })),
                  );
                  if (saved) {
                    reset();
                    await rules.reload();
                  }
                }}
              >
                تأكيد وتطبيق
              </Button>
              <Button variant="ghost" onClick={reset}>
                إلغاء
              </Button>
            </div>
          </div>
        ) : (
          <Button
            variant="outline"
            disabled={!scopeReady(scope)}
            onClick={async () => {
              const p = await run(() =>
                unwrap(api.POST('/api/v1/admin/free-rules/preview', { body: body() })),
              );
              if (p) setPreview(p);
            }}
          >
            معاينة
          </Button>
        )}
      </Card>

      <FormError message={rules.error} />
      <Card className="overflow-x-auto p-0">
        <table className="w-full text-sm">
          <thead className="border-b border-border text-muted">
            <tr>
              <th className="p-3 text-start font-medium">النطاق</th>
              <th className="p-3 text-start font-medium">المحتوى</th>
              <th className="p-3 text-start font-medium">القاعدة</th>
              <th className="p-3 text-start font-medium">آخر تعديل</th>
              <th className="p-3" />
            </tr>
          </thead>
          <tbody>
            {(rules.data ?? []).map((r) => (
              <tr key={r.id} className="border-b border-border last:border-0">
                <td className="p-3">{scopeLabel(r.scope)}</td>
                <td className="p-3">{KINDS[r.contentKind]}</td>
                <td className="p-3">{ruleText(r)}</td>
                <td className="p-3">{formatDateTime(r.updatedAt)}</td>
                <td className="p-3">
                  <Button
                    size="sm"
                    variant="ghost"
                    className="text-danger"
                    onClick={async () => {
                      if (!window.confirm('حذف القاعدة؟ تعود العناصر المرتبطة بها إلى الوضع اليدوي.')) return;
                      const done = await run(() =>
                        unwrap(
                          api.DELETE('/api/v1/admin/free-rules/{id}', { params: { path: { id: r.id } } }),
                        ),
                      );
                      if (done) await rules.reload();
                    }}
                  >
                    حذف
                  </Button>
                </td>
              </tr>
            ))}
            {rules.data?.length === 0 ? (
              <tr>
                <td colSpan={5} className="p-6 text-center text-muted">
                  لا توجد قواعد؛ كل المحتوى مدفوع ما لم يُحدَّد يدوياً
                </td>
              </tr>
            ) : null}
          </tbody>
        </table>
      </Card>
    </div>
  );
}
