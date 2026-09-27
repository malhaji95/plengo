# CLAUDE.md

Arabic education platform. The product spec is `docs/spec.md` (v5.2); read §0 and §41 before
changing anything. Architecture decisions live in `docs/architecture.md`.

## Layout

- `apps/api` — Fastify API + pg-boss workers. Route → Service → Repository (Drizzle).
- `apps/admin` — Next.js admin UI. Calls the API from the browser only; never touches the DB.
- `apps/mobile` — Flutter student app (Android, iOS, web).
- `packages/contracts` — Zod request/response schemas, error codes, generated `openapi.json`.
- `packages/db` — Drizzle schema, migrations, reference data.

## Commands

```bash
pnpm install
pnpm lint && pnpm typecheck && pnpm format:check
pnpm --filter @plengo/api test          # needs Postgres; TEST_DATABASE_URL (default postgres://postgres@localhost:5432/postgres)
pnpm db:generate                        # after editing packages/db/src/schema
pnpm --filter @plengo/api openapi       # after changing routes/contracts
pnpm --filter @plengo/admin api-types   # then regenerate admin types
cd apps/mobile && dart run swagger_parser && dart run build_runner build   # Dart client + codegen
cd apps/mobile && flutter analyze && flutter test
```

CI fails when migrations, `openapi.json`, admin types or the Dart client are stale.

## Rules that are easy to break

- Only the API talks to Postgres and R2. Authorization happens in API guards/helpers only.
- Every response uses the `{ success, data, error }` envelope with a code from
  `packages/contracts/src/errors.ts` and its Arabic message.
- Response/request schemas used by routes must be registered in `z.globalRegistry` with an `id`
  so the OpenAPI document and generated clients get named types.
- `COUPON_REDEMPTION` is a compile-time Flutter flag. Never make it remote.
- No Google/Apple sign-in, no AI, no teacher accounts, no device limits in V1.
- Arabic RTL everywhere; emails, codes and URLs render LTR.
- Schema changes only through Drizzle migrations; never edit an applied migration.
- Work phase by phase (spec §39) and finish a phase's tests before moving on.
