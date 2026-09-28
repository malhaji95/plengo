# Deployment and local development

## Local development

Requirements: Node 22 (see `.nvmrc`), pnpm 10, PostgreSQL 16, Flutter 3.47 for the student app.

```bash
docker compose up -d postgres            # or any local Postgres 16
pnpm install
cp apps/api/.env.example apps/api/.env   # adjust DATABASE_URL if needed
set -a; . apps/api/.env; set +a
pnpm --filter @plengo/api migrate:dev
ADMIN_PASSWORD='choose-one' pnpm --filter @plengo/api admin:create --email admin@example.com --name "المشرف"
pnpm --filter @plengo/api seed           # development only: §40 structure, teachers, accounts, coupons, questions, decks
pnpm --filter @plengo/api dev            # http://localhost:4000, OTP emails are printed to the log
NEXT_PUBLIC_API_BASE_URL=http://localhost:4000 pnpm --filter @plengo/admin dev   # http://localhost:3000
cd apps/mobile && flutter run -d chrome --web-port 3001 --dart-define=API_BASE_URL=http://localhost:4000
```

With `STORAGE_DRIVER=memory` uploads stay in the API process; use R2 (or any S3-compatible
endpoint via `R2_ENDPOINT`) to test real uploads.

## Topology (spec §4)

| Component     | Host                                                                         |
| ------------- | ---------------------------------------------------------------------------- |
| API + workers | Docker image from `apps/api/Dockerfile` behind TLS (Caddy) or Railway/Fly EU |
| Admin         | Vercel (fra1) or the same VPS (`output: 'standalone'`)                       |
| Student web   | Cloudflare Pages, `flutter build web --release --no-web-resources-cdn`       |
| Database      | Neon Frankfurt, autosuspend disabled in production                           |
| Media         | Cloudflare R2 `media-private` + `media-public` (`cdn.<domain>`)              |

Release order: build image → `node dist/scripts/migrate.js` with the new image → start new API
containers. Workers run inside the API process (`JOBS_ENABLED=true`); set it to `false` on extra
replicas if job handling should stay on one instance.

Production requires `APP_ENV=production`, `STORAGE_DRIVER=r2` and `EMAIL_PROVIDER=resend`; the API
refuses to start otherwise. Secrets: `BETTER_AUTH_SECRET`, `MOBILE_ACCESS_JWT_SECRET`,
`MOBILE_REFRESH_TOKEN_PEPPER`, `COUPON_HMAC_SECRET` (each ≥ 32 random characters),
`COUPON_ENCRYPTION_KEY` (32 random bytes, base64: `openssl rand -base64 32`), R2 keys, email API key.
Never rotate the coupon secrets on a live system: existing codes stop matching and exports fail.

`TRUST_PROXY_HOPS` (default 1) is the number of proxies in front of the API that append to
`X-Forwarded-For` (Caddy alone: 1; Cloudflare → Caddy: 2). Only those hops are trusted, so a client
cannot spoof its IP for rate limits. HSTS is sent by the API when `APP_ENV` is `staging` or
`production`, and by the admin in production builds. Admin error reporting uses
`NEXT_PUBLIC_SENTRY_DSN` (optional).

### R2 CORS (spec §12.7)

`media-private` (uploads are presigned `PUT`s straight from the browser):

```json
[
  {
    "AllowedOrigins": ["https://admin.<domain>", "https://app.<domain>"],
    "AllowedMethods": ["PUT"],
    "AllowedHeaders": ["content-type"],
    "MaxAgeSeconds": 3600
  },
  {
    "AllowedOrigins": ["https://app.<domain>"],
    "AllowedMethods": ["GET"],
    "MaxAgeSeconds": 3600
  }
]
```

`media-public`: `GET` from any origin (`"AllowedOrigins": ["*"], "AllowedMethods": ["GET"]`).

Backups and the restore drill are Phase 13 (spec §35).
