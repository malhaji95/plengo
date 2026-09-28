# Student web (Flutter web)

Same codebase as mobile (spec §24). Differences on web:

- Auth uses the API's httpOnly `SameSite=Lax` cookie (`/api/v1/auth/web/login`); no tokens are
  stored in the browser. Requests send `X-Requested-With` for the API's CSRF check.
- Drift runs on WASM SQLite (`web/sqlite3.wasm`, `web/drift_worker.js`, pinned to the
  `sqlite3`/`drift` package versions — update them together). When the browser offers no persistent
  storage (OPFS/IndexedDB unavailable, some private modes), drift falls back to memory; the app then
  shows an "online only" notice above every tab (`ephemeralDatabase`).
- No offline packs on web (§22.8): no secure key storage in browsers.
- Path URL strategy; hosting falls back to `index.html` for unknown paths (Cloudflare Pages does
  this by default when no `404.html` exists).
- Built with `--no-web-resources-cdn`: CanvasKit and the Arabic font are served from the app's own
  origin.
- Responsive (§24): below 600 px a bottom bar; above it a navigation rail, reading/study/quiz
  screens capped at 720 px (`ContentWidth`), and lists as 2–3 column grids (`ResponsiveList`).
- Keyboard (§13.3): Study — Space flips, 1/2/3 rate Again/Good/Easy, Z undoes; Browse — Space flips,
  arrows move (mirrored for RTL).
- An HTML loading screen (`web/index.html`, removed by `web/boot.js` at Flutter's first frame)
  covers the download on slow networks.
- PWA: `manifest.json` with `display: browser`, so browsers offer no install prompt until Plan B.
  `web/sw.js` is a network-first service worker for same-origin files only: online behaviour is
  unchanged, and a student who opened the app once can reload it offline. Flutter's own deprecated
  worker is not registered (custom `web/flutter_bootstrap.js`).
- Push on web (FCM web push) arrives with the FCM client wiring in Phase 13; the in-app inbox works
  everywhere.

## Deployment (Cloudflare Pages)

`.github/workflows/deploy-web.yml` (manual, per environment) builds the app, writes `_headers`, checks
the size budget and publishes with `wrangler pages deploy`. Environment variables: `API_BASE_URL`,
`MEDIA_ORIGINS` (comma-separated: the public CDN origin and the private bucket's R2 origin used by
presigned URLs), `SENTRY_ORIGIN`, `SENTRY_DSN_PUBLIC`, `CLOUDFLARE_PAGES_PROJECT`; secrets
`CLOUDFLARE_API_TOKEN`, `CLOUDFLARE_ACCOUNT_ID`. The API's `WEB_ORIGIN` must be the Pages domain
(`app.<domain>`) for cookies and CORS.

`tool/web_headers.mjs` writes the headers: a Content-Security-Policy that allows scripts only from
the app origin (plus `wasm-unsafe-eval` for CanvasKit and SQLite), network access only to the API,
media and Sentry origins, and no framing; HSTS, `nosniff`, a strict referrer policy and a
permissions policy. Every file is `Cache-Control: no-cache`: browsers keep the files and revalidate
them by ETag, so a repeat visit costs a round of 304s. Longer lifetimes are unsafe because Flutter's
engine files are not content-hashed (an old CanvasKit must never meet a new `main.dart.js`).

## Performance (§34.3)

`tool/web_size.mjs build/web` sums the brotli size of the first-load set and fails above 4 MB; CI runs
it after the web build. `tool/measure_web.mjs build/web --profile fast3g|slow3g --cpu 4` serves the
build like Cloudflare (brotli, ETags, the generated `_headers` including the CSP), loads it in
headless Chromium with DevTools network and CPU throttling, and reports bytes and the time to
Flutter's first frame for a first visit, a repeat visit (HTTP cache only) and a reload with the
server stopped (service worker). Any console error or CSP violation is reported.

### Measured 2026-09-28 (Phase 12, full app)

First-load set, release build (`tool/web_size.mjs`):

| Browser                          | Raw     | gzip    | brotli (served) |
| -------------------------------- | ------- | ------- | --------------- |
| Chrome/Edge (Chromium CanvasKit) | 12.1 MB | 4.22 MB | **3.24 MB**     |
| Firefox/Safari (full CanvasKit)  | 13.8 MB | 5.04 MB | **3.92 MB**     |

Throttled loads in Chromium, 4× CPU slowdown, API unreachable (the app stops at the login screen):

| Profile (DevTools preset)       | Visit                  | Transferred | First frame |
| ------------------------------- | ---------------------- | ----------- | ----------- |
| Fast 3G (1.44 Mbps, 562 ms RTT) | first                  | 2,862 KB    | 40.6 s      |
|                                 | repeat (HTTP cache)    | 12 KB       | 4.4 s       |
|                                 | reload, server offline | 0 KB        | 1.7 s       |
| Slow 3G (400 kbps, 2 s RTT)     | first                  | 2,862 KB    | 87.1 s      |
|                                 | repeat (HTTP cache)    | 12 KB       | 13.6 s      |
|                                 | reload, server offline | 0 KB        | 1.9 s       |

No console errors or CSP violations in any run.

**Assessment.** The size target is met: 3.24 MB compressed on Chromium and 3.92 MB elsewhere,
against ≤ 4 MB. Repeat loads come from the cache (a few KB of revalidation), meeting the second
target. The first visit on 3G is slow: CanvasKit (1.5 MB) and the compiled app (1 MB) must arrive
before anything renders, which the loading screen makes visible rather than blank. The `--wasm`
(skwasm) build was measured and does not help: its wasm module is only requested after its JS
loader, and the bytes are about the same. Remaining options, not needed to meet §34.3: deferred
imports to split rarely used screens out of `main.dart.js`, and subsetting the Arabic font weights.
