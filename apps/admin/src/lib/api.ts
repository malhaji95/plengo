import createClient from 'openapi-fetch';
import type { paths } from './api-schema';

export const API_BASE_URL = process.env.NEXT_PUBLIC_API_BASE_URL ?? 'http://localhost:4000';

/**
 * Typed client generated from packages/contracts/openapi.json. The admin never touches the
 * database; it calls the API from the browser with the httpOnly session cookie. The custom header
 * satisfies the API's CSRF check (spec §11.2).
 */
export const api = createClient<paths>({
  baseUrl: API_BASE_URL,
  credentials: 'include',
  headers: { 'X-Requested-With': 'XMLHttpRequest' },
});

interface Envelope<T> {
  success: boolean;
  data?: T | null;
  error?: { code: string; message: string } | null;
}

export class ApiError extends Error {
  constructor(
    readonly code: string,
    message: string,
    readonly status: number,
  ) {
    super(message);
  }
}

/** Unwraps the §30.3 envelope, throwing ApiError (with the Arabic message) on failure. */
export async function unwrap<T>(
  call: Promise<{ data?: Envelope<T>; error?: unknown; response: Response }>,
): Promise<T> {
  let result: Awaited<typeof call>;
  try {
    result = await call;
  } catch {
    throw new ApiError('NETWORK_ERROR', 'تعذر الاتصال بالخادم', 0);
  }
  const body = (result.data ?? result.error) as Envelope<T> | undefined;
  if (result.response.ok && body?.success && body.data != null) return body.data;
  throw new ApiError(
    body?.error?.code ?? 'SERVER_ERROR',
    body?.error?.message ?? 'حدث خطأ، حاول لاحقاً',
    result.response.status,
  );
}
