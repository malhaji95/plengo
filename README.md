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

All thirteen phases of spec §39 are built and tested in the repository — decisions in
`docs/architecture.md` (ADR-001 to ADR-023). What remains needs the owner's accounts, machines and
devices (store signing and submission, the FCM client, the physical-device smoke test):
see [`docs/release.md`](docs/release.md). Also: [`docs/web.md`](docs/web.md) (student web and its
measurements), [`docs/performance.md`](docs/performance.md) (load test),
[`docs/security-review.md`](docs/security-review.md).
