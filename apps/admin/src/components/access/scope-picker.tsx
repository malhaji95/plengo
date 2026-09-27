'use client';

import { Label } from '@/components/ui/input';
import { api, unwrap } from '@/lib/api';
import type { ScopeValue } from '@/lib/access';
import { useLoad } from '@/lib/use-load';

export const selectClass =
  'h-10 w-full rounded-lg border border-border bg-surface px-3 text-sm focus-visible:outline-2 focus-visible:outline-brand';

/**
 * Picks one access scope (spec §8.1): a subject's general content, or one teacher track. The two never
 * unlock each other, so the admin chooses explicitly.
 */
export function ScopePicker({
  value,
  onChange,
  disabled,
}: {
  value: ScopeValue;
  onChange: (v: ScopeValue) => void;
  disabled?: boolean;
}) {
  const levels = useLoad(() => unwrap(api.GET('/api/v1/admin/levels')), []);
  const subjects = useLoad(() => unwrap(api.GET('/api/v1/admin/subjects', { params: { query: {} } })), []);
  const tracks = useLoad(
    () => unwrap(api.GET('/api/v1/admin/teacher-tracks', { params: { query: {} } })),
    [],
  );

  return (
    <div className="grid gap-3 sm:grid-cols-[12rem_1fr]">
      <div className="space-y-1">
        <Label htmlFor="scope-type">نوع النطاق</Label>
        <select
          id="scope-type"
          className={selectClass}
          value={value.scopeType}
          disabled={disabled}
          onChange={(e) =>
            onChange({
              scopeType: e.target.value as ScopeValue['scopeType'],
              subjectId: null,
              teacherTrackId: null,
            })
          }
        >
          <option value="subject">مادة (المحتوى العام)</option>
          <option value="teacher_track">مسار مدرس</option>
        </select>
      </div>
      {value.scopeType === 'subject' ? (
        <div className="space-y-1">
          <Label htmlFor="scope-subject">المادة</Label>
          <select
            id="scope-subject"
            className={selectClass}
            value={value.subjectId ?? ''}
            disabled={disabled}
            onChange={(e) => onChange({ ...value, subjectId: e.target.value || null })}
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
      ) : (
        <div className="space-y-1">
          <Label htmlFor="scope-track">المسار</Label>
          <select
            id="scope-track"
            className={selectClass}
            value={value.teacherTrackId ?? ''}
            disabled={disabled}
            onChange={(e) => onChange({ ...value, teacherTrackId: e.target.value || null })}
          >
            <option value="">اختر المسار</option>
            {(tracks.data ?? []).map((t) => (
              <option key={t.id} value={t.id}>
                {t.titleAr} · {t.subjectNameAr}
              </option>
            ))}
          </select>
        </div>
      )}
    </div>
  );
}
