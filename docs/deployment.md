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

Push notifications (spec §20.3) use FCM's HTTP v1 API with a Firebase service account:
`FCM_PROJECT_ID`, `FCM_CLIENT_EMAIL` and `FCM_PRIVATE_KEY` (the PEM from the service-account JSON;
`\n` escapes are accepted). Without them the API logs pushes instead of sending them; inbox entries
are written either way. Due-card reminders run hourly (`notifications.due-reminders`) and send at
most one reminder per student per business day.

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

## Backups and restore (spec §35)

Two independent layers:

1. **Neon point-in-time recovery** (enable it on the production project; keep the history window at
   ≥ 7 days). First choice for mistakes found within the window: restore to a new branch at a
   timestamp just before the incident, check it, then point `DATABASE_URL` at it.
2. **Daily logical dumps outside Neon** — `ops/backup/db-backup.sh`, run by
   `.github/workflows/backups.yml` at 04:15 Damascus: `pg_dump` custom format, verified with
   `pg_restore --list`, uploaded with rclone to storage in another account/provider, and pruned after
   35 days (the privacy policy's promise for deleted accounts). Media buckets are copied weekly with
   `ops/backup/media-sync.sh` (`rclone sync`, so deletions propagate too).

Setup: the workflow's `production` environment needs the secrets `DATABASE_URL` (a read-only role is
enough) and `RCLONE_CONFIG` (an rclone.conf defining the `r2` source and `backup` destination), and
the variables `BACKUP_REMOTE` and `MEDIA_BACKUP`.

### Restore procedure

1. Create an empty database (a new Neon project or branch with no tables).
2. `DUMP=latest BACKUP_REMOTE=backup:plengo-db RESTORE_URL=postgres://…/empty ops/backup/restore-drill.sh`
   restores the newest dump and checks it: migrations recorded, core tables readable, the three
   education levels present, no orphaned entitlements or options. It refuses a non-empty target.
   `DUMP=backup:plengo-db/plengo-<stamp>.dump` picks a specific day.
3. Run the migrator against it (`node dist/scripts/migrate.js`): it applies only migrations newer
   than the dump.
4. Point the API's `DATABASE_URL` at it and restart. pg-boss recreates its schema if missing; queued
   jobs from after the dump are lost, and the next schedules run normally.
5. Media: if objects were lost, `rclone sync backup:plengo-media/<bucket> r2:<bucket>` in the other
   direction. Database rows reference objects by key, so a database restore alone needs no media
   step.

### Drill

The workflow restores the newest dump into a throwaway Postgres on the first of every month; a
failure fails the run. Run it by hand before risky migrations (`workflow_dispatch`, task `drill`).

Local drill, 2026-09-28 (seeded development database): dump 1.1 MB, restored and checked in 2 s —
15/15 migrations, 20 users, 7,210 coupons, 156 audit entries; the migrator then found nothing to
apply, and a second run against the now non-empty database was refused.
