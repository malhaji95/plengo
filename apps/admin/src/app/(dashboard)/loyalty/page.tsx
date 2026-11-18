'use client';

import Link from 'next/link';
import { useState } from 'react';
import { selectClass } from '@/components/access/scope-picker';
import { FormError } from '@/components/form-error';
import { Button } from '@/components/ui/button';
import { Card } from '@/components/ui/card';
import { Input, Label } from '@/components/ui/input';
import { formatDateTime } from '@/lib/access';
import { api, unwrap } from '@/lib/api';
import {
  EMPTY_REWARD,
  REDEMPTION_STATUS_LABELS,
  REWARD_KIND_LABELS,
  rewardBody,
  rewardProblems,
  toRewardForm,
  type AdminLoyaltyReward,
  type RedemptionStatus,
  type RewardForm,
} from '@/lib/loyalty';
import { errorMessage, useLoad } from '@/lib/use-load';

/**
 * Loyalty programme (v3 §10): rewards students spend points on, and their redemptions. The earning
 * rules live in the settings page; a student's balance and manual adjustments on their page.
 */
export default function LoyaltyPage() {
  const rewards = useLoad(() => unwrap(api.GET('/api/v1/admin/loyalty/rewards')), []);
  const decks = useLoad(() => unwrap(api.GET('/api/v1/admin/decks', { params: { query: {} } })), []);
  const [status, setStatus] = useState<RedemptionStatus | ''>('pending');
  const [cursor, setCursor] = useState<string | undefined>(undefined);
  const redemptions = useLoad(
    () =>
      unwrap(
        api.GET('/api/v1/admin/loyalty/redemptions', {
          params: { query: { ...(status ? { status } : {}), ...(cursor ? { cursor } : {}) } },
        }),
      ),
    [status, cursor],
  );
  const [form, setForm] = useState<RewardForm>(EMPTY_REWARD);
  const [editing, setEditing] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const problems = rewardProblems(form);

  async function run(call: () => Promise<unknown>) {
    setError(null);
    try {
      await call();
      return true;
    } catch (err) {
      setError(errorMessage(err));
      return false;
    }
  }

  async function save(e: React.FormEvent) {
    e.preventDefault();
    const done = await run(() =>
      editing
        ? unwrap(
            api.PATCH('/api/v1/admin/loyalty/rewards/{id}', {
              params: { path: { id: editing } },
              body: rewardBody(form),
            }),
          )
        : unwrap(api.POST('/api/v1/admin/loyalty/rewards', { body: rewardBody(form) })),
    );
    if (done) {
      setForm(EMPTY_REWARD);
      setEditing(null);
      await rewards.reload();
    }
  }

  const edit = (r: AdminLoyaltyReward) => {
    setEditing(r.id);
    setForm(toRewardForm(r));
  };

  return (
    <div className="mx-auto max-w-6xl space-y-4">
      <h1 className="text-xl font-semibold">برنامج الولاء</h1>
      <p className="text-sm text-muted">
        قواعد كسب النقاط في{' '}
        <Link href="/settings" className="text-brand">
          الإعدادات
        </Link>
        ، ورصيد كل طالب وتعديله اليدوي في صفحة الطالب.
      </p>
      <FormError message={rewards.error ?? redemptions.error ?? error} />

      <Card className="space-y-3">
        <h2 className="font-semibold">{editing ? 'تعديل المكافأة' : 'مكافأة جديدة'}</h2>
        <form onSubmit={save} className="grid gap-3 md:grid-cols-3">
          <div className="space-y-1">
            <Label htmlFor="r-title">العنوان</Label>
            <Input
              id="r-title"
              value={form.titleAr}
              onChange={(e) => setForm({ ...form, titleAr: e.target.value })}
            />
          </div>
          <div className="space-y-1">
            <Label htmlFor="r-cost">التكلفة (نقاط)</Label>
            <Input
              id="r-cost"
              type="number"
              dir="ltr"
              min={1}
              value={form.costPoints}
              onChange={(e) => setForm({ ...form, costPoints: e.target.value })}
            />
          </div>
          <div className="space-y-1">
            <Label htmlFor="r-kind">النوع</Label>
            <select
              id="r-kind"
              className={selectClass}
              value={form.kind}
              onChange={(e) => setForm({ ...form, kind: e.target.value as RewardForm['kind'] })}
            >
              {Object.entries(REWARD_KIND_LABELS).map(([k, label]) => (
                <option key={k} value={k}>
                  {label}
                </option>
              ))}
            </select>
          </div>
          {form.kind === 'unlock_deck' ? (
            <div className="space-y-1">
              <Label htmlFor="r-deck">المجموعة</Label>
              <select
                id="r-deck"
                className={selectClass}
                value={form.deckId}
                onChange={(e) => setForm({ ...form, deckId: e.target.value })}
              >
                <option value="">اختر مجموعة</option>
                {(decks.data ?? []).map((d) => (
                  <option key={d.id} value={d.id}>
                    {d.subjectNameAr} · {d.titleAr}
                  </option>
                ))}
              </select>
            </div>
          ) : null}
          <div className="space-y-1 md:col-span-2">
            <Label htmlFor="r-description">الوصف</Label>
            <Input
              id="r-description"
              value={form.description}
              onChange={(e) => setForm({ ...form, description: e.target.value })}
            />
          </div>
          <div className="space-y-1">
            <Label htmlFor="r-order">الترتيب</Label>
            <Input
              id="r-order"
              type="number"
              dir="ltr"
              min={0}
              value={form.sortOrder}
              onChange={(e) => setForm({ ...form, sortOrder: e.target.value })}
            />
          </div>
          <label className="flex items-center gap-2 text-sm">
            <input
              type="checkbox"
              checked={form.isActive}
              onChange={(e) => setForm({ ...form, isActive: e.target.checked })}
            />
            متاحة للطلاب
          </label>
          <div className="flex gap-2 md:col-span-3">
            <Button type="submit" disabled={problems.length > 0}>
              {editing ? 'حفظ' : 'إضافة'}
            </Button>
            {editing ? (
              <Button
                type="button"
                variant="outline"
                onClick={() => {
                  setEditing(null);
                  setForm(EMPTY_REWARD);
                }}
              >
                إلغاء
              </Button>
            ) : null}
            {problems.length && form.titleAr ? (
              <span className="text-sm text-danger">{problems[0]}</span>
            ) : null}
          </div>
        </form>
      </Card>

      <Card className="overflow-x-auto p-0">
        <table className="w-full text-sm">
          <thead className="border-b border-border text-muted">
            <tr>
              <th className="p-3 text-start font-medium">المكافأة</th>
              <th className="p-3 text-start font-medium">النوع</th>
              <th className="p-3 text-start font-medium">التكلفة</th>
              <th className="p-3 text-start font-medium">الاستبدالات</th>
              <th className="p-3 text-start font-medium">الحالة</th>
              <th className="p-3" />
            </tr>
          </thead>
          <tbody>
            {(rewards.data ?? []).map((r) => (
              <tr key={r.id} className="border-b border-border last:border-0">
                <td className="p-3">
                  {r.titleAr}
                  {r.description ? <div className="text-xs text-muted">{r.description}</div> : null}
                </td>
                <td className="p-3">
                  {REWARD_KIND_LABELS[r.kind]}
                  {r.deckTitleAr ? <div className="text-xs text-muted">{r.deckTitleAr}</div> : null}
                </td>
                <td className="p-3" dir="ltr">
                  {r.costPoints}
                </td>
                <td className="p-3">{r.redemptionCount}</td>
                <td className="p-3">{r.isActive ? 'متاحة' : 'موقوفة'}</td>
                <td className="p-3">
                  <div className="flex gap-1">
                    <Button size="sm" variant="ghost" onClick={() => edit(r)}>
                      تعديل
                    </Button>
                    <Button
                      size="sm"
                      variant="ghost"
                      className="text-danger"
                      onClick={() => {
                        if (!window.confirm(`حذف المكافأة «${r.titleAr}»؟`)) return;
                        void run(async () => {
                          await unwrap(
                            api.DELETE('/api/v1/admin/loyalty/rewards/{id}', {
                              params: { path: { id: r.id } },
                            }),
                          );
                          await rewards.reload();
                        });
                      }}
                    >
                      حذف
                    </Button>
                  </div>
                </td>
              </tr>
            ))}
            {rewards.data?.length === 0 ? (
              <tr>
                <td colSpan={6} className="p-6 text-center text-muted">
                  لا توجد مكافآت بعد
                </td>
              </tr>
            ) : null}
          </tbody>
        </table>
      </Card>

      <Card className="space-y-3 p-0 pt-4">
        <div className="flex flex-wrap items-center justify-between gap-2 px-4">
          <h2 className="font-semibold">طلبات الاستبدال</h2>
          <select
            aria-label="حالة الطلب"
            className={`${selectClass} w-40`}
            value={status}
            onChange={(e) => {
              setStatus(e.target.value as RedemptionStatus | '');
              setCursor(undefined);
            }}
          >
            <option value="">كل الحالات</option>
            {Object.entries(REDEMPTION_STATUS_LABELS).map(([k, label]) => (
              <option key={k} value={k}>
                {label}
              </option>
            ))}
          </select>
        </div>
        <table className="w-full text-sm">
          <thead className="border-b border-border text-muted">
            <tr>
              <th className="p-3 text-start font-medium">الطالب</th>
              <th className="p-3 text-start font-medium">المكافأة</th>
              <th className="p-3 text-start font-medium">النقاط</th>
              <th className="p-3 text-start font-medium">الحالة</th>
              <th className="p-3 text-start font-medium">التاريخ</th>
              <th className="p-3" />
            </tr>
          </thead>
          <tbody>
            {(redemptions.data?.items ?? []).map((r) => (
              <tr key={r.id} className="border-b border-border last:border-0">
                <td className="p-3">
                  <Link href={`/students/${r.userId}`} className="text-brand hover:underline">
                    {r.studentName ?? '—'}
                  </Link>
                  <div dir="ltr" className="text-start text-xs text-muted">
                    {r.studentEmail}
                  </div>
                </td>
                <td className="p-3">
                  {r.titleAr}
                  <div className="text-xs text-muted">{REWARD_KIND_LABELS[r.kind]}</div>
                </td>
                <td className="p-3" dir="ltr">
                  {r.costPoints}
                </td>
                <td className="p-3">
                  {REDEMPTION_STATUS_LABELS[r.status]}
                  {r.note ? <div className="text-xs text-muted">{r.note}</div> : null}
                </td>
                <td className="p-3">{formatDateTime(r.createdAt)}</td>
                <td className="p-3">
                  {r.status !== 'cancelled' ? (
                    <div className="flex gap-1">
                      {r.status === 'pending' ? (
                        <Button
                          size="sm"
                          variant="outline"
                          onClick={() =>
                            void run(async () => {
                              await unwrap(
                                api.POST('/api/v1/admin/loyalty/redemptions/{id}/status', {
                                  params: { path: { id: r.id } },
                                  body: { status: 'fulfilled' },
                                }),
                              );
                              await redemptions.reload();
                            })
                          }
                        >
                          تم التسليم
                        </Button>
                      ) : null}
                      <Button
                        size="sm"
                        variant="ghost"
                        className="text-danger"
                        onClick={() => {
                          const note = window.prompt('سبب الإلغاء (تُعاد النقاط للطالب):');
                          if (note === null) return;
                          void run(async () => {
                            await unwrap(
                              api.POST('/api/v1/admin/loyalty/redemptions/{id}/status', {
                                params: { path: { id: r.id } },
                                body: { status: 'cancelled', note: note.trim() || null },
                              }),
                            );
                            await redemptions.reload();
                          });
                        }}
                      >
                        إلغاء واسترداد
                      </Button>
                    </div>
                  ) : null}
                </td>
              </tr>
            ))}
            {redemptions.data?.items.length === 0 ? (
              <tr>
                <td colSpan={6} className="p-6 text-center text-muted">
                  لا توجد طلبات
                </td>
              </tr>
            ) : null}
          </tbody>
        </table>
        {redemptions.data?.nextCursor ? (
          <div className="px-4 pb-4">
            <Button variant="outline" size="sm" onClick={() => setCursor(redemptions.data!.nextCursor!)}>
              التالي
            </Button>
          </div>
        ) : null}
      </Card>
    </div>
  );
}
