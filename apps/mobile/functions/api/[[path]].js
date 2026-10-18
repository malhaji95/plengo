/*
 * Cloudflare Pages Function for demo hosting without a shared domain (docs/demo-hosting.md).
 * The student web calls /api on its own origin (build with API_BASE_URL = this site's URL) and
 * this forwards the request to the API, so the session cookie stays first-party.
 * Set API_ORIGIN (for example https://plengo-api.onrender.com) in the Pages project's variables.
 * Without API_ORIGIN the route answers 503, so a production deploy that talks to the API directly
 * is unaffected.
 */
export async function onRequest({ request, env }) {
  if (!env.API_ORIGIN) return new Response('API_ORIGIN is not configured', { status: 503 });
  const url = new URL(request.url);
  const target = new URL(url.pathname + url.search, env.API_ORIGIN);
  const headers = new Headers(request.headers);
  headers.delete('host');
  const hasBody = request.method !== 'GET' && request.method !== 'HEAD';
  return fetch(target, {
    method: request.method,
    headers,
    body: hasBody ? request.body : undefined,
    // Streams the body through (required by the fetch standard for stream bodies).
    duplex: 'half',
    redirect: 'manual',
  });
}
