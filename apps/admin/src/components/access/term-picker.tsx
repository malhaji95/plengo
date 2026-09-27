'use client';

import { Input, Label } from '@/components/ui/input';
import { damascusDate, type TermValue } from '@/lib/access';
import { selectClass } from './scope-picker';

/** How long access lasts: permanent, a number of days from activation, or until a date (Damascus). */
export function TermPicker({
  value,
  onChange,
  label = 'مدة الوصول',
}: {
  value: TermValue;
  onChange: (v: TermValue) => void;
  label?: string;
}) {
  return (
    <div className="grid gap-3 sm:grid-cols-[12rem_1fr]">
      <div className="space-y-1">
        <Label htmlFor="term-kind">{label}</Label>
        <select
          id="term-kind"
          className={selectClass}
          value={value.kind}
          onChange={(e) => {
            const kind = e.target.value as TermValue['kind'];
            onChange(
              kind === 'permanent'
                ? { kind }
                : kind === 'duration'
                  ? { kind, days: 30 }
                  : { kind, date: damascusDate(30) },
            );
          }}
        >
          <option value="permanent">دائم</option>
          <option value="duration">عدد أيام من التفعيل</option>
          <option value="until">حتى تاريخ محدد</option>
        </select>
      </div>
      {value.kind === 'duration' ? (
        <div className="space-y-1">
          <Label htmlFor="term-days">عدد الأيام</Label>
          <Input
            id="term-days"
            type="number"
            min={1}
            max={3650}
            dir="ltr"
            value={value.days}
            onChange={(e) => onChange({ kind: 'duration', days: Number(e.target.value) })}
          />
        </div>
      ) : value.kind === 'until' ? (
        <div className="space-y-1">
          <Label htmlFor="term-date">ينتهي في (23:59:59 بتوقيت دمشق)</Label>
          <Input
            id="term-date"
            type="date"
            dir="ltr"
            min={damascusDate(1)}
            value={value.date}
            onChange={(e) => onChange({ kind: 'until', date: e.target.value })}
          />
        </div>
      ) : (
        <div />
      )}
    </div>
  );
}
