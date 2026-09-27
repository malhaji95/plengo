# Web fallback

Spec §0.5 / §34.3: if Flutter web cannot meet the web performance acceptance criteria, a Next.js
student web frontend may be built later against the same API. It is **not** being built; do not
start it unless explicitly requested.

Current evidence: see the first-load measurement in `web.md` (≈ 4.17 MB gzip for the Phase 1
shell, just above the 4 MB target). Re-measure in Phase 12 with the real content screens.
