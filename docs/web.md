# Student web (Flutter web)

Same codebase as mobile (spec §24). Differences on web:

- Auth uses the API's httpOnly `SameSite=Lax` cookie (`/api/v1/auth/web/login`); no tokens are
  stored in the browser. Requests send `X-Requested-With` for the API's CSRF check.
- Drift runs on WASM SQLite (`web/sqlite3.wasm`, `web/drift_worker.js`, pinned to the
  `sqlite3`/`drift` package versions — update them together).
- Path URL strategy; hosting must fall back to `index.html` for unknown paths (Cloudflare Pages
  does this by default).
- Build with `--no-web-resources-cdn`; the Arabic font is bundled.

## First-load size (measured 2026-09-27, Phase 1 shell)

Release build, gzip -9 (Cloudflare serves brotli, which is smaller):

| File                             | Raw         | gzip          |
| -------------------------------- | ----------- | ------------- |
| main.dart.js                     | 3,429 KB    | 983 KB        |
| canvaskit.wasm                   | 7,114 KB    | 2,843 KB      |
| canvaskit.js                     | 85 KB       | 27 KB         |
| fonts (3 Arabic weights + icons) | 717 KB      | 311 KB        |
| other                            | 14 KB       | 6 KB          |
| **Total**                        | **11.4 MB** | **≈ 4.17 MB** |

The §34.3 target is ≤ 4 MB compressed. CanvasKit is two thirds of it. Options to evaluate in
Phase 12 with 3G-throttled measurements: brotli as served by Cloudflare, the `--wasm` (skwasm)
renderer, font subsetting. If targets remain out of reach, record the findings in
`web-fallback.md`.
