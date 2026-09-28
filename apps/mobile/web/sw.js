/*
 * Offline fallback for the web app shell (spec §24). Same-origin GETs go to the network first and
 * are cached; when the network fails, the cached copy answers, so a student who has opened the app
 * once can reload it offline and keep studying from local data. Online behaviour is unchanged:
 * freshness comes from HTTP revalidation, never from a stale cache (old engine files must not meet
 * a new main.dart.js). API and media requests are cross-origin and never touched.
 */
const CACHE = 'plengo-shell-v1';

self.addEventListener('install', () => self.skipWaiting());

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches
      .keys()
      .then((keys) => Promise.all(keys.filter((k) => k !== CACHE).map((k) => caches.delete(k))))
      .then(() => self.clients.claim()),
  );
});

self.addEventListener('fetch', (event) => {
  const request = event.request;
  const url = new URL(request.url);
  if (request.method !== 'GET' || url.origin !== self.location.origin) return;
  event.respondWith(
    (async () => {
      const cache = await caches.open(CACHE);
      try {
        const response = await fetch(request);
        if (response.ok && response.type === 'basic') {
          // Navigations are stored under the app root: any deep link falls back to index.html.
          await cache.put(request.mode === 'navigate' ? '/' : request, response.clone());
        }
        return response;
      } catch (err) {
        const cached = await cache.match(request.mode === 'navigate' ? '/' : request, { ignoreSearch: true });
        if (cached) return cached;
        throw err;
      }
    })(),
  );
});
