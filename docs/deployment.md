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
pnpm --filter @plengo/api seed           # optional: §40 levels/subjects/units/lessons for development
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
`MOBILE_REFRESH_TOKEN_PEPPER` (each ≥ 32 random characters), R2 keys, email API key.

Backups and the restore drill are Phase 13 (spec §35).
