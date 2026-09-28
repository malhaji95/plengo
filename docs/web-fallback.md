# Web fallback

Spec §0.5 / §34.3: if Flutter web cannot meet the web performance acceptance criteria, a Next.js
student web frontend may be built later against the same API. It is **not** being built; do not
start it unless explicitly requested.

**Phase 12 finding: not needed.** The full app's first load is 3.24 MB brotli on Chromium and
3.92 MB on other browsers (target ≤ 4 MB), and repeat loads are served from the cache (see the
measurements in `web.md`). CI enforces the 4 MB budget, so a regression is caught at the pull
request.

What would reopen the question: the budget failing after new dependencies, or field data showing the
first 3G visit (≈ 40 s to first frame under DevTools Fast 3G with 4× CPU slowdown) costs too many
students. The cheaper steps come first — deferred imports for rarely used screens and font
subsetting — before any second frontend.
