'use client';

import { selectClass } from '@/components/access/scope-picker';
import { Label } from '@/components/ui/input';
import { api, unwrap } from '@/lib/api';
import { useLoad } from '@/lib/use-load';

export interface Placement {
  subjectId: string | null;
  /** `general` = the subject's general content, a track id, or `any` (filters only). */
  track: string;
  unitId: string | null;
  lessonId: string | null;
}

export const EMPTY_PLACEMENT: Placement = { subjectId: null, track: 'general', unitId: null, lessonId: null };
export const trackIdOf = (p: Placement) => (p.track === 'general' || p.track === 'any' ? null : p.track);

/**
 * Subject → (general content | teacher track) → unit → lesson (spec §6, §8.1). `lockScope` keeps the
 * subject and track fixed (they decide a question's access scope and cannot change after creation).
 */
export function PlacementPicker({
  value,
  onChange,
  lockScope,
  allowAnyTrack,
}: {
  value: Placement;
  onChange: (v: Placement) => void;
  lockScope?: boolean;
  /** Filters: "all questions of the subject" in addition to general / a track. */
  allowAnyTrack?: boolean;
}) {
  const levels = useLoad(() => unwrap(api.GET('/api/v1/admin/levels')), []);
  const subjects = useLoad(() => unwrap(api.GET('/api/v1/admin/subjects', { params: { query: {} } })), []);
  const tracks = useLoad(
    () =>
      value.subjectId
        ? unwrap(
            api.GET('/api/v1/admin/teacher-tracks', { params: { query: { subjectId: value.subjectId } } }),
          )
        : Promise.resolve([]),
    [value.subjectId],
  );
  const units = useLoad(
    () =>
      value.subjectId
        ? unwrap(api.GET('/api/v1/admin/units', { params: { query: { subjectId: value.subjectId } } }))
        : Promise.resolve([]),
    [value.subjectId],
  );
  const lessons = useLoad(
    () =>
      value.subjectId
        ? unwrap(api.GET('/api/v1/admin/lessons', { params: { query: { subjectId: value.subjectId } } }))
        : Promise.resolve([]),
    [value.subjectId],
  );
  const shownLessons = (lessons.data ?? []).filter((l) => !value.unitId || l.unitId === value.unitId);

  return (
    <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
      <div className="space-y-1">
        <Label htmlFor="q-subject">المادة</Label>
        <select
          id="q-subject"
          className={selectClass}
          disabled={lockScope}
          value={value.subjectId ?? ''}
          onChange={(e) =>
            onChange({
              subjectId: e.target.value || null,
              track: allowAnyTrack ? 'any' : 'general',
              unitId: null,
              lessonId: null,
            })
          }
        >
          <option value="">اختر المادة</option>
          {(levels.data ?? []).map((level) => (
            <optgroup key={level.id} label={level.nameAr}>
              {(subjects.data ?? [])
                .filter((s) => s.educationLevelId === level.id)
                .map((s) => (
                  <option key={s.id} value={s.id}>
                    {s.nameAr}
                  </option>
                ))}
            </optgroup>
          ))}
        </select>
      </div>
      <div className="space-y-1">
        <Label htmlFor="q-track">النطاق</Label>
        <select
          id="q-track"
          className={selectClass}
          disabled={lockScope || !value.subjectId}
          value={value.track}
          onChange={(e) => onChange({ ...value, track: e.target.value })}
        >
          {allowAnyTrack ? <option value="any">كل الأسئلة</option> : null}
          <option value="general">المحتوى العام للمادة</option>
          {(tracks.data ?? []).map((t) => (
            <option key={t.id} value={t.id}>
              {t.titleAr}
            </option>
          ))}
        </select>
      </div>
      <div className="space-y-1">
        <Label htmlFor="q-unit">الوحدة</Label>
        <select
          id="q-unit"
          className={selectClass}
          disabled={!value.subjectId}
          value={value.unitId ?? ''}
          onChange={(e) => onChange({ ...value, unitId: e.target.value || null, lessonId: null })}
        >
          <option value="">{allowAnyTrack ? 'كل الوحدات' : 'بدون وحدة'}</option>
          {(units.data ?? []).map((u) => (
            <option key={u.id} value={u.id}>
              {u.titleAr}
            </option>
          ))}
        </select>
      </div>
      <div className="space-y-1">
        <Label htmlFor="q-lesson">الدرس</Label>
        <select
          id="q-lesson"
          className={selectClass}
          disabled={!value.subjectId}
          value={value.lessonId ?? ''}
          onChange={(e) => {
            const lesson = shownLessons.find((l) => l.id === e.target.value);
            onChange({
              ...value,
              lessonId: lesson?.id ?? null,
              unitId: lesson ? lesson.unitId : value.unitId,
            });
          }}
        >
          <option value="">{allowAnyTrack ? 'كل الدروس' : 'بدون درس'}</option>
          {shownLessons.map((l) => (
            <option key={l.id} value={l.id}>
              {l.titleAr}
            </option>
          ))}
        </select>
      </div>
    </div>
  );
}
