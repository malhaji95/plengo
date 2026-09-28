'use client';

import { useCallback, useEffect, useState } from 'react';
import { selectClass } from '@/components/access/scope-picker';
import { FormError } from '@/components/form-error';
import { ActionFields, actionBody } from '@/components/home/action-fields';
import { Button } from '@/components/ui/button';
import { Card } from '@/components/ui/card';
import { Input, Label } from '@/components/ui/input';
import { formatDateTime } from '@/lib/access';
import { api, unwrap } from '@/lib/api';
import type { components } from '@/lib/api-schema';
import {
  NOTIFICATION_TYPE_LABELS,
  STATUS_LABELS,
  TARGET_LABELS,
  type BannerAction,
  type NotificationTargetType,
} from '@/lib/home';
import { errorMessage, useLoad } from '@/lib/use-load';

type ComposeType = components['schemas']['CreateNotificationRequest']['type'];
type AdminNotification = components['schemas']['AdminNotification'];

const COMPOSE_TYPES: ComposeType[] = [
  'announcement',
  'new_content',
  'teacher_update',
  'study_reminder',
  'promotion',
];
const UUID = /[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/gi;

/**
 * Compose and history (spec §20.2). Sending is queued: a background job resolves the audience,
 * writes inbox entries and pushes to devices, honouring each student's consent (§20.1).
 */
export default function NotificationsPage() {
  const [cursor, setCursor] = useState<string | null>(null);
  const [older, setOlder] = useState<AdminNotification[]>([]);
  const history = useLoad(
    () => unwrap(api.GET('/api/v1/admin/notifications', { params: { query: { limit: 30 } } })),
    [],
  );
  const levels = useLoad(() => unwrap(api.GET('/api/v1/admin/levels')), []);
  const subjects = useLoad(() => unwrap(api.GET('/api/v1/admin/subjects', { params: { query: {} } })), []);
  const tracks = useLoad(
    () => unwrap(api.GET('/api/v1/admin/teacher-tracks', { params: { query: {} } })),
    [],
  );
  const teachers = useLoad(() => unwrap(api.GET('/api/v1/admin/teachers')), []);

  const [type, setType] = useState<ComposeType>('announcement');
  const [title, setTitle] = useState('');
  const [body, setBody] = useState('');
  const [action, setAction] = useState<BannerAction>('none');
  const [target, setTarget] = useState('');
  const [targetType, setTargetType] = useState<NotificationTargetType>('all');
  const [targetId, setTargetId] = useState('');
  const [userIds, setUserIds] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [notice, setNotice] = useState<string | null>(null);
  const [preview, setPreview] = useState<{ recipients: number; pushConsented: number } | null>(null);

  useEffect(() => setPreview(null), [type, targetType, targetId, userIds]);

  const parsedUserIds = [...new Set(userIds.match(UUID) ?? [])].map((s) => s.toLowerCase());
  const targetReady =
    targetType === 'all' || (targetType === 'students' ? parsedUserIds.length > 0 : !!targetId);

  const targetOptions: Partial<Record<NotificationTargetType, { id: string; name: string }[]>> = {
    level: (levels.data ?? []).map((l) => ({ id: l.id, name: l.nameAr })),
    subject_entitlement: (subjects.data ?? []).map((s) => ({ id: s.id, name: s.nameAr })),
    track_entitlement: (tracks.data ?? []).map((t) => ({ id: t.id, name: t.titleAr })),
    teacher_followers: (teachers.data ?? []).map((t) => ({ id: t.id, name: t.nameAr })),
  };

  const targetBody = () => {
    switch (targetType) {
      case 'level':
        return { educationLevelId: targetId };
      case 'subject_entitlement':
        return { subjectId: targetId };
      case 'track_entitlement':
        return { teacherTrackId: targetId };
      case 'teacher_followers':
        return { teacherId: targetId };
      case 'students':
        return { userIds: parsedUserIds };
      default:
        return {};
    }
  };

  const previewCall = () =>
    unwrap(
      api.POST('/api/v1/admin/notifications/preview', { body: { type, targetType, target: targetBody() } }),
    );

  async function showPreview() {
    setError(null);
    try {
      setPreview(await previewCall());
    } catch (err) {
      setError(errorMessage(err));
    }
  }

  async function send(e: React.FormEvent) {
    e.preventDefault();
    setError(null);
    setNotice(null);
    try {
      // Always show who it will reach before sending (§26.2 targeting preview).
      const counts = await previewCall();
      setPreview(counts);
      if (counts.recipients === 0) {
        setError('لا يوجد مستلمون لهذا الاستهداف');
        return;
      }
      if (
        !window.confirm(
          `سيصل الإشعار إلى ${counts.recipients} طالباً (${counts.pushConsented} منهم يقبلون الإشعارات الفورية). إرسال؟`,
        )
      )
        return;
    } catch (err) {
      setError(errorMessage(err));
      return;
    }
    try {
      await unwrap(
        api.POST('/api/v1/admin/notifications', {
          body: {
            type,
            titleAr: title,
            bodyAr: body,
            ...actionBody(action, target),
            targetType,
            target: targetBody(),
          },
        }),
      );
      setTitle('');
      setBody('');
      setNotice('تمت جدولة الإرسال');
      setOlder([]);
      setCursor(null);
      await history.reload();
    } catch (err) {
      setError(errorMessage(err));
    }
  }

  const loadMore = useCallback(async () => {
    const from = cursor ?? history.data?.nextCursor;
    if (!from) return;
    try {
      const page = await unwrap(
        api.GET('/api/v1/admin/notifications', { params: { query: { limit: 30, cursor: from } } }),
      );
      setOlder((o) => [...o, ...page.items]);
      setCursor(page.nextCursor ?? '');
    } catch (err) {
      setError(errorMessage(err));
    }
  }, [cursor, history.data]);

  const items = [...(history.data?.items ?? []), ...older];
  const hasMore = cursor === null ? !!history.data?.nextCursor : !!cursor;

  return (
    <div className="mx-auto max-w-5xl space-y-4">
      <h1 className="text-xl font-semibold">الإشعارات</h1>
      <Card>
        <form onSubmit={send} className="space-y-3">
          <h2 className="font-semibold">إشعار جديد</h2>
          <div className="grid gap-3 sm:grid-cols-[12rem_1fr]">
            <div className="space-y-1">
              <Label htmlFor="notif-type">النوع</Label>
              <select
                id="notif-type"
                className={selectClass}
                value={type}
                onChange={(e) => setType(e.target.value as ComposeType)}
              >
                {COMPOSE_TYPES.map((t) => (
                  <option key={t} value={t}>
                    {NOTIFICATION_TYPE_LABELS[t]}
                  </option>
                ))}
              </select>
            </div>
            <div className="space-y-1">
              <Label htmlFor="notif-title">العنوان</Label>
              <Input
                id="notif-title"
                required
                maxLength={120}
                value={title}
                onChange={(e) => setTitle(e.target.value)}
              />
            </div>
          </div>
          <div className="space-y-1">
            <Label htmlFor="notif-body">النص</Label>
            <textarea
              id="notif-body"
              required
              maxLength={500}
              rows={3}
              className="w-full rounded-lg border border-border bg-surface p-3 text-sm"
              value={body}
              onChange={(e) => setBody(e.target.value)}
            />
          </div>
          {type === 'promotion' ? (
            <p className="text-sm text-muted">تصل العروض فقط للطلاب الذين وافقوا على استقبالها.</p>
          ) : null}
          <ActionFields
            idPrefix="notif"
            action={action}
            target={target}
            onChange={(a, t) => {
              setAction(a);
              setTarget(t);
            }}
          />
          <div className="grid gap-3 sm:grid-cols-[12rem_1fr]">
            <div className="space-y-1">
              <Label htmlFor="notif-target-type">المستلمون</Label>
              <select
                id="notif-target-type"
                className={selectClass}
                value={targetType}
                onChange={(e) => {
                  setTargetType(e.target.value as NotificationTargetType);
                  setTargetId('');
                }}
              >
                {(Object.keys(TARGET_LABELS) as NotificationTargetType[]).map((t) => (
                  <option key={t} value={t}>
                    {TARGET_LABELS[t]}
                  </option>
                ))}
              </select>
            </div>
            {targetOptions[targetType] ? (
              <div className="space-y-1">
                <Label htmlFor="notif-target">{TARGET_LABELS[targetType]}</Label>
                <select
                  id="notif-target"
                  className={selectClass}
                  required
                  value={targetId}
                  onChange={(e) => setTargetId(e.target.value)}
                >
                  <option value="">اختر</option>
                  {targetOptions[targetType]!.map((o) => (
                    <option key={o.id} value={o.id}>
                      {o.name}
                    </option>
                  ))}
                </select>
              </div>
            ) : null}
            {targetType === 'students' ? (
              <div className="space-y-1">
                <Label htmlFor="notif-users">معرّفات الطلاب (سطر لكل معرّف)</Label>
                <textarea
                  id="notif-users"
                  dir="ltr"
                  rows={3}
                  className="w-full rounded-lg border border-border bg-surface p-3 font-mono text-xs"
                  value={userIds}
                  onChange={(e) => setUserIds(e.target.value)}
                />
                <p className="text-xs text-muted">{parsedUserIds.length} طالب</p>
              </div>
            ) : null}
          </div>
          <div className="flex flex-wrap items-center gap-3">
            <Button
              type="button"
              variant="outline"
              disabled={!targetReady}
              onClick={() => void showPreview()}
            >
              معاينة المستلمين
            </Button>
            <Button type="submit" disabled={!title || !body || !targetReady}>
              إرسال
            </Button>
            {preview ? (
              <span className="text-sm text-muted">
                {preview.recipients} مستلم · {preview.pushConsented} إشعار فوري
              </span>
            ) : null}
          </div>
          {notice ? <p className="text-sm text-success">{notice}</p> : null}
        </form>
      </Card>
      <FormError message={history.error ?? error} />
      <Card className="overflow-x-auto p-0">
        <table className="w-full text-sm">
          <thead className="border-b border-border text-muted">
            <tr>
              <th className="p-3 text-start font-medium">الإشعار</th>
              <th className="p-3 text-start font-medium">المستلمون</th>
              <th className="p-3 text-start font-medium">الحالة</th>
              <th className="p-3 text-start font-medium">الوصول</th>
              <th className="p-3 text-start font-medium">التاريخ</th>
            </tr>
          </thead>
          <tbody>
            {items.map((n) => (
              <tr key={n.id} className="border-b border-border align-top last:border-0">
                <td className="p-3">
                  <div className="font-medium">{n.titleAr}</div>
                  <div className="text-muted">{n.bodyAr}</div>
                  <div className="text-xs text-muted">{NOTIFICATION_TYPE_LABELS[n.type]}</div>
                </td>
                <td className="p-3">{TARGET_LABELS[n.targetType]}</td>
                <td className="p-3">
                  <span
                    className={
                      n.status === 'sent'
                        ? 'text-success'
                        : n.status === 'failed'
                          ? 'text-danger'
                          : 'text-muted'
                    }
                  >
                    {STATUS_LABELS[n.status]}
                  </span>
                </td>
                <td className="p-3">
                  <div>{n.recipientCount} مستلم</div>
                  <div className="text-muted">
                    {n.pushCount} إشعار فوري
                    {n.pushFailures ? ` · ${n.pushFailures} فشل` : ''} · {n.readCount} مقروء
                  </div>
                </td>
                <td className="p-3">{formatDateTime(n.sentAt ?? n.createdAt)}</td>
              </tr>
            ))}
            {history.data && items.length === 0 ? (
              <tr>
                <td colSpan={5} className="p-6 text-center text-muted">
                  لم تُرسل إشعارات بعد
                </td>
              </tr>
            ) : null}
          </tbody>
        </table>
      </Card>
      {hasMore ? (
        <Button variant="outline" onClick={() => void loadMore()}>
          عرض المزيد
        </Button>
      ) : null}
    </div>
  );
}
