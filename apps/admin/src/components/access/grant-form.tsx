'use client';

import { useState } from 'react';
import { FormError } from '@/components/form-error';
import { Button } from '@/components/ui/button';
import { api, unwrap } from '@/lib/api';
import { EMPTY_SCOPE, scopeBody, scopeReady, termBody, type ScopeValue, type TermValue } from '@/lib/access';
import { errorMessage } from '@/lib/use-load';
import { ScopePicker } from './scope-picker';
import { TermPicker } from './term-picker';

/**
 * Grants a student access to one scope (spec §8.3). A duplicate for an active scope is refused with
 * ALREADY_ENTITLED; extend the existing entitlement instead.
 */
export function GrantForm({ studentId, onGranted }: { studentId: string; onGranted: () => void }) {
  const [scope, setScope] = useState<ScopeValue>(EMPTY_SCOPE);
  const [term, setTerm] = useState<TermValue>({ kind: 'permanent' });
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    setBusy(true);
    setError(null);
    try {
      await unwrap(
        api.POST('/api/v1/admin/students/{id}/entitlements', {
          params: { path: { id: studentId } },
          body: { ...scopeBody(scope), ...termBody(term) },
        }),
      );
      setScope(EMPTY_SCOPE);
      onGranted();
    } catch (err) {
      setError(errorMessage(err));
    } finally {
      setBusy(false);
    }
  }

  return (
    <form onSubmit={submit} className="space-y-3">
      <ScopePicker value={scope} onChange={setScope} />
      <TermPicker value={term} onChange={setTerm} />
      <FormError message={error} />
      <Button type="submit" disabled={busy || !scopeReady(scope)}>
        منح الوصول
      </Button>
    </form>
  );
}
