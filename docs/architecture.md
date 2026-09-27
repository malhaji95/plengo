# Architecture

See `spec.md` §0 for the locked decisions. This file records how they were implemented and any
decision the spec left open (ADR list, spec §41 rule 20).

```text
Flutter student app (Android · iOS · Web)      Next.js admin (browser)
        │ bearer JWT (mobile) / cookie (web)            │ cookie + TOTP
        └───────────────┬───────────────────────────────┘
                        ▼
              apps/api (Fastify, Zod, OpenAPI)
      routes → services → repositories (Drizzle, node-postgres)
                        │
        ┌───────────────┼──────────────────┐
        ▼               ▼                  ▼
   PostgreSQL      pg-boss (schema      Cloudflare R2
   (Neon)          `pgboss`)            public + private buckets
```

## Phase 3 status (teachers)

Done:

- Schema: `teachers`, `teacher_tracks` with `UNIQUE(id, subject_id)` (the target of the §7.3 composite
  keys that content tables add in Phases 5–7; a test proves the key works), `teacher_followers`.
- Admin: teachers (photo, bio, visibility, order, follower/track counts) and their tracks; tracks
  overview; image uploads for teacher photos and subject covers.
- Students: teacher list, profile with tracks, track page, follow/unfollow (idempotent, never grants
  access), followed teachers, tracks listed on the subject page. The follow UI obeys the remote
  `features.teacherFollowing` flag.
- Seed: the two §40 teachers and their tracks.

Deferred: notifying followers / track holders (Phase 10), track content and access (Phases 4–7).

## Phase 2 status (education structure)

Done:

- Schema: universities, faculties, academic years, subjects, units, lessons. Soft delete, codes unique
  among live rows, composite foreign keys for the college chain and for unit/lesson subject ownership
  (§6.1), a check constraint that a year implies its faculty and a faculty its university.
- Admin API + UI: rename/reorder levels; CRUD, show/hide, reorder and delete for every node; audit log
  entries for every change.
- Student API + Flutter: all levels browsable, the profile placement only picks the default tab and
  college filter (§8.9); subject outline with units, lessons and general lessons; placement editable
  in settings and optionally at registration; web deep links survive reloads.
- Dev seed (`pnpm --filter @plengo/api seed`) with the §40 structure.

Known issue: on Flutter web in RTL, the accessibility (semantics) boxes of the bottom navigation bar
and chips are reported at mirrored/scaled positions. Visual rendering and taps are correct; screen
readers on web may misplace focus. Re-check with the next Flutter release (Phase 12 web work).

## Phase 1 status

Done:

- Monorepo, shared TS/ESLint/Prettier, CI (lint, typecheck, migration check, OpenAPI/client drift
  checks, API integration tests on Postgres, admin build, Flutter analyze/test/web build, Docker build).
- API: envelope + Arabic error codes, request IDs, `/health`, `/ready`, `/api/v1/config`, server-side
  minimum-version gate, CORS allowlist, CSRF checks for cookie requests, §31 rate limits.
- Auth: registration, 6-digit email OTP verification, OTP password reset, mobile token pair with
  rotation / retry grace / replay detection, student web cookie sessions, sessions list + revoke,
  admin password + mandatory TOTP (enrollment, recovery codes, 12 h idle timeout), admin CLI.
- Storage: provider-neutral interface, R2 (S3) implementation, presigned uploads with signed
  content-type and length, pg-boss processing into WebP variants, 24 h orphan cleanup, student quota.
- Admin shell: sign-in, TOTP enrollment/verification, RTL navigation (§26.1).
- Flutter shell: RTL theme + dark mode + 3 font sizes, auth screens, five-tab shell, sessions,
  force update, generated API client, token refresh, encrypted drift database, coupon flag gating.

Not verifiable in the cloud build environment (deferred per spec):

- Physical Android/iOS runs (Phase 13 owner smoke tests). Android/iOS builds are not run in CI yet.
- Live R2 round trip: `apps/api/test/r2-storage.test.ts` has a live suite that runs when
  `S3_TEST_ENDPOINT`, `S3_TEST_ACCESS_KEY_ID`, `S3_TEST_SECRET_ACCESS_KEY` and `S3_TEST_BUCKET` are set.
- Sentry is wired but inactive without DSNs.

## Decisions

### ADR-001 — pnpm workspace with a source export condition

Packages export `./src/index.ts` under the custom condition `@plengo/source` and compiled `dist`
otherwise. Dev (`tsx`), typecheck and tests read sources directly; production images run compiled
JavaScript produced by `pnpm build` and packaged with `pnpm deploy`.

### ADR-002 — OpenAPI from Zod, named components, generated clients

Routes declare Zod schemas; `fastify-type-provider-zod` emits OpenAPI 3.1. Schemas are registered
in `z.globalRegistry` with an `id` so they become named components, and the export script
(`apps/api/src/scripts/openapi.ts`) collapses the provider's identical `…Input` twins and drops
unreferenced components. Clients: `openapi-typescript` + `openapi-fetch` (admin),
`swagger_parser` → retrofit/json_serializable (Flutter; pure Dart, no Java in CI).
Admin endpoints are excluded from the Dart client.

### ADR-003 — Better Auth as a library, not a mounted handler

Better Auth provides password hashing, email OTP (verification + reset), cookie sessions and TOTP.
Its HTTP handler is not mounted: API routes call `auth.api.*` and translate results into the §30
envelope and error codes, so every client sees one API surface. Tables are mapped onto the spec's
names (`users`, `sessions`, `accounts`, `verification_codes`, `admin_two_factor`) with UUID ids.
OTPs are stored hashed, 6 digits, 10-minute lifetime, 5 attempts.

Registering an email that already exists returns the same success response and sends nothing
(Better Auth's enumeration protection); forgot-password and resend-OTP also never reveal whether an
account exists. `AUTH_EMAIL_TAKEN` is therefore not used by registration.

### ADR-004 — Mobile refresh tokens: families, grace window, revocation

- Each mobile login creates a `sessions` row (`platform = android|ios`) and a token family. The
  family is tied to the session, so the student's session list and "revoke session" cover mobile
  and web alike.
- Access token: HS256 JWT, 15 min, claims `sub` (user) and `sid` (session). Every authenticated
  request also checks that the session is unexpired, so logout/revocation take effect immediately
  rather than after up to 15 minutes.
- Refresh token: 256-bit random, stored as HMAC-SHA256 with `MOBILE_REFRESH_TOKEN_PEPPER`,
  30-day lifetime, rotated on every refresh (row lock serializes concurrent refreshes).
- Retry grace (30 s): the spec's "replay the same response" is impossible when only hashes are
  stored, so a rotated token presented inside the window mints a **sibling** successor instead.
  Both successors stay valid; at most 5 siblings per rotated token. Outside the window the whole
  family is revoked (tokens `revoked_at`, session expired).
- Password reset revokes every session and token family of the user.

### ADR-005 — What "2FA-verified admin session" means

When an admin has TOTP enabled, Better Auth only creates a session after the TOTP (or a recovery
code) is verified. Before enrollment, the password step yields a session that only the enrollment
routes accept; confirming the first TOTP code enables 2FA. `requireAdmin` therefore requires
`role = admin`, an active account, `two_factor_enabled = true`, a cookie (never bearer) session and
activity within 12 hours (`sessions.last_seen_at`, refreshed at most once a minute).
Admins cannot sign in through the student mobile or web endpoints, and students cannot use admin
endpoints.

### ADR-006 — Rate limits are in-process

`@fastify/rate-limit` uses its in-memory store. That is correct for the single V1 API instance;
before running more than one API replica, switch to a shared store. Limits: login 10/15 min per
IP+email, OTP-sending endpoints 5/hour per email, uploads 60/hour per user (coupon and report
limits arrive with their phases).

### ADR-007 — Upload pipeline

Originals always go to the private bucket under `{env}/original/{yyyy}/{mm}/{uuid}/original`,
uploaded directly by the client with a presigned PUT whose `Content-Type` and `Content-Length` are
signed. `complete` checks the object size and enqueues `media.process`; the worker detects the
format from magic bytes (sharp), rejects non-images, and writes `full`/`thumb` WebP variants into
the bucket for the kind (public for banners/teachers/covers, private otherwise).
Pending uploads older than 24 h are deleted hourly with their originals.

### ADR-008 — Flutter local database

`package:sqlite3` bundles the SQLCipher build (`hooks.user_defines.sqlite3.source: sqlcipher`),
replacing the discontinued `sqlcipher_flutter_libs`. The key is 32 random bytes generated on first
launch and kept in Keychain/Keystore. On web the regular WASM SQLite is used (no offline packs on
web, §22.8). Logout wipes the database except device preferences (`settings.*`: theme, font size).

### ADR-009 — Web build without third-party CDNs

The Arabic font is bundled (IBM Plex Sans Arabic, OFL, a placeholder until branding is decided,
§44) and web builds use `--no-web-resources-cdn` so CanvasKit is served from the app origin.
The PWA manifest ships with `display: browser` so browsers do not offer installation under Plan A;
Plan B changes it to `standalone`.

### ADR-010 — Education levels are reference data

The three levels are inserted by migration `0001_reference_data` because registration needs them
from Phase 1; Phase 2 adds the college hierarchy and admin CRUD.

### ADR-011 — Education structure rules

- **Deletes are refused while live children exist** (`RESOURCE_IN_USE`): a university with faculties
  or subjects, a faculty with years or subjects, a year or subject with children, a unit with lessons.
  No cascades, so an admin can never remove a whole subtree by accident. Rows are soft-deleted and a
  deleted code can be reused.
- **Ordering is per sibling set.** Subjects are ordered within one level + college path; lessons within
  their unit, or among the lessons directly under the subject. Reorder requests must list exactly the
  live siblings of one set; moving a node to another set appends it at the end.
- **Placement updates replace the whole placement.** Sending the level or any college layer (for a
  subject or a student profile) sets the placement to exactly what was sent: the deepest layer given
  determines the ones above it, and layers not sent become empty. The Dart client omits unset fields
  (`include_if_null`), and sending only the level clears the college layers.
- **Visibility cascades down.** A subject is visible to students only if it and every college layer
  above it are active and not deleted; students may only pick active layers for their placement.
- **Reference lists are public, content is not.** `/levels`, `/universities`, `/faculties` and
  `/academic-years` are public because registration offers them before sign-in; subjects and their
  outlines require sign-in. These bounded lists are returned whole; cursor pagination (§30.1) is used
  for unbounded lists from Phase 5 on.
- **CORS** must list every method the admin uses (`GET, HEAD, POST, PUT, PATCH, DELETE`); the plugin
  default omits `PUT/PATCH/DELETE`, which silently blocks browser edits. Covered by a preflight test.

### ADR-012 — Dev storage and image handling

- With `STORAGE_DRIVER=memory` (local development and tests) the API serves signed
  `/api/v1/dev-storage/{bucket}/{key}` URLs in place of R2's presigned URLs, so the real browser upload
  flow (presign → direct PUT → complete → processing) works without R2. Uploads and private reads
  need an HMAC signature from the memory store; the routes are never registered in production, where
  the environment check also forbids the memory driver. Objects live in the API process and vanish
  when it restarts.
- Images are attached (teacher photo, subject/track cover) only after processing succeeded and only
  for their intended kind (`teacher`, `cover`).
- Generated clients name inline objects after their property, so a nested object whose property
  name equals a component (e.g. `teacher` vs `Teacher`) silently loses fields in the Dart client. The
  OpenAPI export now fails on such collisions; register those objects with an id instead.
- Hand-written Dart code is formatted with `dart format` at 120 columns and checked in CI; generated
  code is excluded.
