'use client';

import { selectClass } from '@/components/access/scope-picker';
import { Input, Label } from '@/components/ui/input';
import { ACTION_HINTS, ACTION_LABELS, ID_ACTIONS, type BannerAction } from '@/lib/home';

/** The tap action of a banner or notification; the API validates the target (spec §19.2). */
export function ActionFields(props: {
  idPrefix: string;
  action: BannerAction;
  target: string;
  onChange: (action: BannerAction, target: string) => void;
}) {
  const needsTarget = props.action !== 'none';
  return (
    <div className="grid gap-3 sm:grid-cols-[12rem_1fr]">
      <div className="space-y-1">
        <Label htmlFor={`${props.idPrefix}-action`}>الإجراء عند الضغط</Label>
        <select
          id={`${props.idPrefix}-action`}
          className={selectClass}
          value={props.action}
          onChange={(e) => props.onChange(e.target.value as BannerAction, '')}
        >
          {(Object.keys(ACTION_LABELS) as BannerAction[]).map((a) => (
            <option key={a} value={a}>
              {ACTION_LABELS[a]}
            </option>
          ))}
        </select>
      </div>
      {needsTarget ? (
        <div className="space-y-1">
          <Label htmlFor={`${props.idPrefix}-target`}>
            {ID_ACTIONS.includes(props.action) ? 'المعرّف (UUID)' : 'الوجهة'}
          </Label>
          <Input
            id={`${props.idPrefix}-target`}
            dir="ltr"
            required
            placeholder={ACTION_HINTS[props.action]}
            value={props.target}
            onChange={(e) => props.onChange(props.action, e.target.value)}
          />
        </div>
      ) : null}
    </div>
  );
}

/** Keeps a form's action and target together and produces the request fields. */
export const actionBody = (action: BannerAction, target: string) => ({
  action,
  actionTarget: action === 'none' ? null : target.trim(),
});
