'use client';

import { useCallback, useEffect, useState } from 'react';
import { ApiError } from './api';

/** Loads data on mount (and when `deps` change); `reload` re-runs the loader. */
export function useLoad<T>(loader: () => Promise<T>, deps: unknown[]) {
  const [data, setData] = useState<T | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  const run = useCallback(loader, deps);

  const reload = useCallback(async () => {
    setLoading(true);
    try {
      setData(await run());
      setError(null);
    } catch (err) {
      setError(err instanceof ApiError ? err.message : 'حدث خطأ، حاول لاحقاً');
    } finally {
      setLoading(false);
    }
  }, [run]);

  useEffect(() => {
    void reload();
  }, [reload]);

  return { data, error, loading, reload };
}

export function errorMessage(err: unknown): string {
  return err instanceof ApiError ? err.message : 'حدث خطأ، حاول لاحقاً';
}
