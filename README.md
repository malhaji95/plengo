# Plengo

Arabic-only education platform for students in Syria (Grade 9, Grade 12, College).

| Part             | Stack                                       | Path                 |
| ---------------- | ------------------------------------------- | -------------------- |
| Student app      | Flutter (Android, iOS, web)                 | `apps/mobile`        |
| Admin dashboard  | Next.js, Tailwind                           | `apps/admin`         |
| API + jobs       | Fastify, Zod, Drizzle, Better Auth, pg-boss | `apps/api`           |
| Shared contracts | Zod schemas + OpenAPI                       | `packages/contracts` |
| Database         | Drizzle schema + migrations (PostgreSQL)    | `packages/db`        |

Specification: [`docs/spec.md`](docs/spec.md). Decisions: [`docs/architecture.md`](docs/architecture.md).
Local setup: [`docs/deployment.md`](docs/deployment.md).

## Status

Phases 1 (Foundation), 2 (Education structure) and 3 (Teachers) — see `docs/architecture.md`.
