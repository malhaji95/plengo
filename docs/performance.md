# Performance (spec §34)

## API load test

`pnpm --filter @plengo/api load-test` (`apps/api/src/scripts/load-test.ts`) builds the real app on a
scratch database, seeds the §40 content, registers students through the public endpoints (email OTP
included), listens on a local port and sends HTTP traffic in the mix of a study session: Home 20%,
deck page 10%, card batch 25%, answer checks 30%, statistics 15%.

- `RATE=100` — open loop: requests arrive at a fixed rate whatever the response times, like
  independent students. ≈ 1,000 active students at one request every 10 s is ≈ 100 req/s, the
  "nominal load" of §34.1.
- `CONCURRENCY=100` without `RATE` — closed loop, back-to-back requests: finds capacity.

It refuses production-looking database URLs and exits non-zero when a p95 target is missed.

### Results, 2026-09-28

One API process, Postgres 16 and the load generator on the same 4-vCPU container (they compete for
CPU, so production with a dedicated database has more headroom). 300 students, 60 s per run.

| Load                       | Home p95 | Deck p95 | Cards p95 | Check p95 | Stats p95 | Throughput |
| -------------------------- | -------- | -------- | --------- | --------- | --------- | ---------- |
| Target (§34.1)             | ≤ 500    | ≤ 400    | ≤ 400     | ≤ 500     | ≤ 500     |            |
| 100 req/s (nominal)        | **43**   | **22**   | **25**    | **28**    | **23**    | 100 req/s  |
| 150 req/s (1.5× nominal)   | 225      | 173      | 179       | 216       | 136       | 150 req/s  |
| 100 clients, no think time | 796      | 665      | 668       | 797       | 438       | 175 req/s  |

All times in ms. Nominal and 1.5× nominal load meet every target with a wide margin. The closed-loop
run saturates the shared CPUs at ≈ 175 req/s; latencies there are queueing, which is expected for
a capacity test. Scaling past that is horizontal: more API replicas (`JOBS_ENABLED=false` on all
but one) and a larger Neon compute.

The first run found Home doing its per-subject free-content counts one query at a time; they now
run in parallel with the rest of Home's reads, which halved Home's cost under saturation (p50 from
1,320 ms to 645 ms at 100 concurrent clients).

## App

- Lazy loading and pagination: lists are paged by the API (cursor pages), card images are
  prefetched three ahead and cached by media id (§13, §34.2).
- Android size target ≤ 30 MB (§34.2) is checked on the release AAB during the owner-run release
  (docs/release.md); it cannot be built in the cloud container.

## Web

See `web.md`: first load 3.24 MB brotli on Chromium (≤ 4 MB), CI budget, throttled measurements.
