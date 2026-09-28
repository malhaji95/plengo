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

## Phase 7 status (learning)

Done:

- Schema (migration 0007): `quizzes` (with `content_version` and `allow_offline`), `quiz_questions`,
  `quiz_attempts`, `quiz_attempt_answers`, `user_mistakes`, `user_subject_stats`, `question_stats`,
  `bookmarks`, `user_progress`.
- Admin: quizzes by subject/scope/unit/lesson with settings (modes, timer, passing score, max
  attempts, shuffles, mock exam, offline), a question picker limited to the quiz's own scope with
  ordering, publish/archive, free override and delete. `GET/PUT /admin/settings/learning` stores
  `mistakeMasteryStreak` (default 2).
- Students: quiz lists on subject and track pages, quiz detail ("12 من 30 سؤال متاح", locked CTA,
  mode choice, "متابعة الاختبار", past attempts); practice mode with server checks; exam mode with
  question grid, flags, review before "إنهاء الامتحان" and a server-deadline timer; results with
  الكل/الخاطئة/المتروكة/المعلّمة, "أعد الأخطاء فقط" and "أعد الاختبار"; random practice builder; mistake
  bank with "اختبر أخطائي"; إحصائياتي (overview, weekly trend, per subject/unit/lesson/type,
  flashcards); the Saved tab and bookmark buttons; progress on subject/track pages and "متابعة التعلم"
  on Home.
- Exams continue through connection drops: answers are stored locally (Drift schema 3) before they
  are sent; a submission made offline stays pending and is retried every minute while signed in.
- Nightly `attempts.abandon-stale` job; `question_stats` auto-flag rule.
- Seed: a curated quiz (both modes, free), a mixed free/premium quiz and a timed exam-only mock
  exam on Grade 12 Physics; Student 1 has a finished attempt (mistakes, statistics) and bookmarks.

Deferred: offline packs and local grading with server re-grade (Phase 9, which uses
`allow_offline`), student-card bookmarks (Phase 8, `user_card`), question analytics UI (Phase 11),
daily goal and streak on Home (Phase 10; statistics already show study days and the current streak).

## Phase 6 status (flashcards)

Done:

- `packages/srs`: the §13.4 scheduler (three buttons, learning/relearning steps, ease, late bonus,
  365-day cap), the exact SHA-256 fuzz, the 04:00 Asia/Damascus business day and Arabic interval
  labels. `fixtures/scheduler.json` is replayed by the TypeScript tests and by the Dart port
  (`apps/mobile/lib/core/srs/scheduler.dart`); the Dart port was also run on web (dart2js).
- Schema (migration 0006): `flashcard_decks` and `flashcards` (both with `content_version`),
  `card_states`, `review_logs`.
- Admin: decks by subject/scope/unit/lesson with cover, publish/archive, free override, reorder and
  delete; cards with front/back image upload, hide/show, reorder, replace images.
- Students: decks on subject and track pages (locked decks as metadata), Browse (flip,
  السابق/التالي, RTL arrow keys), Study (predicted intervals under the buttons, up to 10 undos,
  Space/1/2/3/Z shortcuts, "أنهيت مراجعة اليوم"), and the Review tab with every due card across
  accessible decks, filterable by subject.
- Device-side scheduling with SRS state and review logs in the encrypted local database; background
  sync (`POST /srs/sync`, `GET /srs/states`) with idempotent logs, undo and last-review-wins.
- Private card images are served with one-hour signed URLs and cached by `{media id}:{version}`.
- Seed: an official Grade 12 Physics deck (free by rule) and a track deck with rendered images.

Deferred: offline pack download (Phase 9), student decks and "أضف إلى بطاقاتي" (Phase 8), user
settings for daily limits (Phase 10), flashcard bulk upload (Phase 11).

## Phase 5 status (questions)

Done:

- `packages/arabic-normalizer`: the §14.4 rules (version 1) with shared fixtures in
  `fixtures/v1.json` (the Phase 9 Dart port must pass the same file); run in CI.
- Schema (migration 0005): `questions` (`content_version`, materialized `is_free`/`free_source`,
  composite keys that keep track, unit and lesson inside the question's subject), `question_options`
  (at most one correct option per question, enforced by a partial unique index) and
  `question_answers` (original, normalized form, normalizer version).
- Admin: question list by subject/scope/unit/lesson/status/type/text, editor for MCQ, true/false and
  written questions with a live normalized preview, publish/archive/draft, manual free override,
  reorder within a lesson, soft delete. All changes are audited.
- Students: question bank per subject, track and lesson in reading order, locked questions as metadata
  only, practice with a server check (تحقق) that returns correctness, the correct option or answer and
  the explanation only after grading.
- Grading and snapshot helpers used by the check endpoint now and by attempts in Phase 7; a
  `questions.renormalize` job regenerates accepted answers stored by an older normalizer version.
- Seed: 11 Grade 12 Physics questions of all types in general and track scopes (5 free by rule, one
  manual override in the track, one draft), written questions with several accepted answers.

Deferred: attempts, quizzes, mistakes and statistics (Phase 7); question analytics and import/export
(Phase 11); the Dart normalizer (Phase 9).

## Phase 4 status (access)

Done:

- Schema (migration 0004): `entitlements` with the two partial unique active-scope indexes,
  `coupon_batches`, `coupons` (HMAC hash, AES-256-GCM ciphertext, last 4), `coupon_redemptions`,
  `coupon_redemption_failures`, `promotions`, `free_access_rules`; the `free_source` enum for the
  content tables of Phases 5–7. Every scoped table has explicit subject/track FKs and the §8.1 CHECK.
- Redemption: the §9.4 transaction (`FOR UPDATE` on the coupon, stale-expiry cleanup, active-row lock,
  temporary→permanent upgrade, entitlement insert before coupon consumption, 23505 on the active-scope
  indexes → rollback + `ALREADY_ENTITLED`), failure log, §9.5 limits. Tested with 20 concurrent
  redemptions of one code and with two different codes for the same user and scope.
- Helpers (§8.6): `scopeOf`, `hasActiveEntitlement`, `isPromoted`, `canAccessItem`,
  `assertCanAccessItem` and a per-request access context for lists. Subject outlines and track pages
  carry the scope's access state; a subject entitlement does not open tracks and vice versa.
- Admin: coupon batches (background generation with progress, CSV/XLSX export, revoke, code search,
  failure report), students (search, entitlements, grant/extend/revoke), access settings, promotions,
  free rules with preview. Grants, extensions, revocations, exports, batches, rules, promotions and
  setting changes are audited.
- Students: locked notice for both `COUPON_REDEMPTION` builds, code screen (LTR, monospace, uppercase,
  dashes inserted, Arabic/Persian digits accepted), My access.
- Jobs: `coupons.generate`, `access.recompute-free`, nightly `access.expire-entitlements`
  (00:05 Asia/Damascus, reporting only).
- Seed: 2 admins (2FA pending), 2 students with the §40 entitlements, a 10-code permanent Grade 12
  Physics batch printed in plaintext, the two free rules and a past-dated promotion.

Deferred: per-item `is_free` and locked item metadata arrive with the content tables (Phases 5–7);
their free-content sources plug into the free-rule service (ADR-013).

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
IP+email, OTP-sending endpoints 5/hour per email, uploads 60/hour per user. Coupon limits are
different: they are counted from the database (ADR-013), so they already hold across replicas.

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

### ADR-013 — Access and coupons

- **Clock-based access.** An entitlement is active when `status='active' AND starts_at <= now AND
(expires_at IS NULL OR expires_at > now)`, evaluated per request with the service clock. The nightly
  job only updates the stored status. Every grant path (coupon, admin grant, extend) first expires
  stale rows for the same user and scope inside its transaction, then relies on the partial unique
  indexes as the final guard. Settings are read before the transaction so a transaction never waits
  for a second pool connection while holding row locks.
- **Date-only expiries** become 23:59:59 in `TZ_BUSINESS` (Asia/Damascus), computed with `Intl` so a
  future DST change is handled. Clients display dates on the Damascus calendar with a fixed UTC+3
  offset (Syria's rule since 2022) instead of shipping a time-zone database.
- **Coupon rate limits** are counted from `coupon_redemption_failures` and `coupon_redemptions`
  (which stores the hashed IP for this purpose): 5/min and 20/hour per user, 60/hour per IP.
  "10 consecutive failures" means 10 failures since the user's last successful redemption; the
  30-minute cooldown runs from the latest one, and a further failure after it starts another.
  Rate-limited attempts are not logged as failures. Malformed codes count as `COUPON_NOT_FOUND`.
  A code whose fixed access end date has passed answers `COUPON_EXPIRED`, as does a code before its
  `valid_from`.
- **Upgrade rule** applies to admin grants too: a permanent grant over an active temporary
  entitlement supersedes it when `allowTemporaryToPermanentUpgrade` (app setting `access`, default
  true) allows it. Extending an expired entitlement makes it active again unless another entitlement
  for the scope is active. Superseded rows are hidden from My access.
- **Exports** are produced by the API (`GET /admin/coupon-batches/{id}/export?format=csv|xlsx`),
  audited, with plaintext codes decrypted only there. XLSX is written by a small in-repo writer
  (inline strings, RTL sheet, `node:zlib`) instead of a spreadsheet dependency; CSV has a UTF-8 BOM
  and neutralises formula prefixes. `Content-Disposition` is exposed through CORS for the file name.
- **Free rules**: one rule per scope and content kind; a kind-specific rule overrides the scope's
  `all` rule; no rule behaves like `manual`. The order used by `first_n_*`, `first_unit` and
  `percentage` is: each unit in order (its unit-level items, then each of its lessons), then lessons
  directly under the subject, then items attached to neither. Manual overrides keep their place in
  that order but never change. Content tables register a `FreeContentSource` (list the scope's
  published items, apply the free set); Phase 4 has none, so previews report zero items.
- **`COUPON_REDEMPTION`** stays compile-time: the Flutter `couponRedemptionProvider` returns the
  `--dart-define` constant and exists only so widget tests can build both variants.

### ADR-014 — Questions

- **Student endpoints** `GET /questions`, `GET /questions/{id}` and `POST /questions/{id}/check` exist
  before quizzes so the bank can be browsed and practised question by question. They use the §8.6
  helpers; the check is stateless (nothing is stored) and reveals the answer only after grading, like
  practice mode. Attempts in Phase 7 reuse `grade()` and store `questionSnapshot()`.
- **Reading order** is the order of the free-rule engine: each unit in order (its unit-level
  questions, then each lesson), then lessons directly under the subject, then questions with neither;
  `sort_order` orders a slot. Lists page with an opaque offset cursor in that order. Reordering is per
  slot (same subject, track, unit and lesson) and must list every sibling.
- **Versioning**: text, explanation, difficulty, options or accepted answers bump `content_version`;
  moving between units/lessons and status/free changes do not. Option ids survive edits so later
  attempt answers keep pointing at them; accepted answers are replaced by deactivating the old rows
  and inserting new ones in the admin's order (the first is shown as the correct answer).
- **Validation**: MCQ 2–6 distinct options with exactly one correct; true/false uses two fixed
  options (صح، خطأ); written 1–10 accepted answers, non-empty and distinct after normalization. A
  lesson implies its unit. Structure (subject, unit, lesson, track) with live questions cannot be
  deleted.
- **Free status**: publishing evaluates the scope's effective rule for that question only; a rule
  change recomputes rule-sourced published questions through the `questions` free-content source.
  Returning an override to "rule" re-evaluates the question.
- **Bidi**: the student app wraps Latin/number runs in question text, options and explanations in
  Unicode isolates (`isolateLtr`), so units and formulas such as `20 m/s` keep their order in RTL.

### ADR-015 — Flashcards and spaced repetition

- **One algorithm, two languages.** The scheduler lives in `packages/srs` (TypeScript) and
  `lib/core/srs` (Dart) and must produce identical results for `packages/srs/fixtures/scheduler.json`.
  Fixture expectations were checked against §13.4 by hand and the fuzz vectors by an independent
  Python run. Ease is rounded to two decimals after each change; review intervals below 3 days are
  rounded half-up to whole days (fuzz applies only from 3 days); the fuzz reads the first four digest
  bytes with multiplication, not shifts, so dart2js gives the same numbers.
- **Business day** uses a fixed UTC+3 offset (Syria's rule since 2022) in both implementations, so the
  04:00 boundary never depends on a device time zone or a bundled tz database.
- **Relearning** keeps the interval to return to in `interval_days` (no extra column). Card states
  store whole days (`interval_days integer`) and `ease` as a double.
- **Sync**: logs are inserted once (client UUID); an undone log restores its `state_before` only if the
  stored state's last review is that log's; states then apply only when their last review is newer.
  The response returns what the server holds so the device adopts other devices' newer reviews. Logs
  stay local until acknowledged, so offline study loses nothing. Student card states (`user_card_id`)
  arrive with Phase 8, which adds that foreign key.
- **Queue** (device): due learning cards first, then today's reviews in a per-day stable pseudo-random
  order (so the current card does not jump when the queue is rebuilt), then new cards in deck order,
  then learn-ahead up to 20 minutes. Daily counts come from local logs of the current business day.
  The global due session (`GET /srs/due`) reviews cards already in progress; new cards come from deck
  sessions. Limits use remote `srsDefaults` until the student settings of Phase 10.
- **Content versions** (§22.3): deck metadata, card membership (add, remove, hide/show) and card order
  bump the deck; a card's images, order or status bump the card.
- **Images**: card images are private (`flashcard` kind) and returned with one-hour signed URLs only in
  `GET /decks/{id}/cards` and `GET /srs/due`, i.e. only for accessible decks. The app caches them with
  `cached_network_image` under `{media id}:{version}:{variant}` and prefetches the next three cards.
- **Dev storage**: `STORAGE_DRIVER=memory` with `LOCAL_STORAGE_DIR` also writes objects to disk, so
  uploads and seeded images survive API restarts and the seed script can create processed images the
  API then serves. Tests keep the pure in-memory store.

### ADR-016 — Quizzes, attempts and learning data

- **One attempt machine** serves curated quizzes, random practice and mistake reviews (`source`).
  The spec's `/practice/random` is `POST /attempts` with `source: "random"`; the app never needs a
  second endpoint. Starting is idempotent per `(user, client_attempt_id)`.
- **What an attempt contains** is fixed at start: question order and option order (shuffled once),
  only questions the student could open then (§8.8), and `deadline_at` for timed exams. Questions a
  quiz loses later stay in started attempts; results use the snapshot stored at grading, so admin
  edits never rewrite history. Skipped questions get a snapshot at submit for the results screen.
- **Quiz access**: a quiz the student can open (free, promoted or entitled) opens all its questions,
  which share its scope (§15.1.1); otherwise only free questions count. A mock exam is locked unless
  every question is open. Marking a quiz free is therefore how an admin shares premium questions as
  a free quiz.
- **Membership**: `PUT /admin/quizzes/{id}/questions` replaces the list in order (add, import,
  remove and reorder in one call) and checks the scope rule each time; publishing re-checks it and
  also requires every member to be published. Deleted or archived questions simply stop appearing.
- **Submission**: one batch with every answer, safe to repeat. Already-graded practice answers keep
  their grade; everything else is graded against the latest answer. A different batch after
  submission → `ATTEMPT_ALREADY_SUBMITTED`. Late = received after `deadline_at` + 2 minutes; there is
  no penalty. An option that no longer exists grades as wrong instead of failing the submission.
  Abandoned attempts can still be submitted (an exam finished offline for a week is not lost).
- **Grading side effects** run in the grading transaction as single-statement upserts: the answer
  and snapshot, `user_mistakes` (wrong → active, streak 0; correct on active → streak + 1, mastered
  at `mistakeMasteryStreak`), `user_subject_stats`, `question_stats` (auto-flagged at ≥ 30 attempts
  with < 20 % correct or a wrong option chosen more than the correct one; the flag stays until an
  admin clears it) and the `user_progress` pointer.
- **Statistics** use `user_subject_stats` for totals and graded answers (indexed by user and grading
  time, joined to the question's current placement) for breakdowns and trends. Weeks are rolling
  7-business-day windows ending today; study days and the streak count business days with graded
  answers or reviews.
- **Progress** percentages are computed on request from current accessible content (questions
  answered, quizzes submitted, official cards reviewed); `user_progress` only stores the resume
  pointer per subject scope (updated by grading, starting an attempt and SRS sync).
- **Bookmarks** accept locked items (shown locked, metadata only) but not unknown or unpublished ones;
  `user_card` bookmarks arrive with Phase 8.
- **Web storage**: where the browser lacks OPFS support (seen in headless Chromium), Drift picks
  `sharedIndexedDb`, which can lose its most recent writes if the page reloads right away. A cleared
  exam draft can then come back and be submitted again; this is harmless because submission (like SRS
  sync) is idempotent and the server returns the same result. Phase 12 revisits web persistence.
- **Generated enums** in the Dart client use `enums_to_json`, so enum path and query parameters
  are sent as their JSON values (`user_card`, not `userCard`).
  Because of this, a generated model's `toJson()` holds enum objects rather than strings; code that
  converts generated models into local ones (for example `FlashcardRepository.cardStateOf`) maps
  field by field instead of round-tripping through JSON.

### ADR-017 — Requirements audit of phases 1–7

- **Admin accounts** (§26.1) are managed in the admin UI: create, deactivate, reactivate and reset
  2FA. The last active admin cannot be deactivated. An admin cannot reset their own 2FA. Every
  change revokes the target's sessions and is audited. Student sessions can be revoked and recent
  attempts viewed from the student page.
- **Remote config** (`minSupportedVersion`, `latestVersion`, store URLs) and the mastery streak are
  edited under Settings. The app's force-update screen links to the store, or reloads the page on web.
- **Client IP**: only `TRUST_PROXY_HOPS` proxies are trusted. Sessions keep an IP hash and a
  200-character user-agent summary, never the raw IP (Better Auth IP tracking is off).
- **OTP emails** are limited to 5 per hour per address across register, resend and reset (one shared
  in-process `WindowLimiter`, ADR-006). Coupon redemptions are serialized per student in-process, so
  a burst cannot get past the failed-attempt limit.
- **Lists that can grow** (mistakes, bookmarks, student search, batch coupons) use the offset
  cursors from the question bank. A student's session list is bounded by the session lifetime, so
  it is not paginated.
- **Integrity**: time totals are `bigint` and each answer adds at most 30 minutes. Starting an
  attempt locks the (student, quiz) pair so `max_attempts` holds under concurrency. The stateless
  question check is refused while the question is in an open exam. Publishing, unpublishing or
  deleting a question bumps every quiz containing it. SRS sync only moves the resume pointer for
  decks the student can open.
- **Images** meet the §12 size budgets. The full variant lowers its quality until it fits (never
  below 45). Avatars are a media kind (400 px / 120 px); the app's picker arrived with Phase 8.
- **Repositories**: the learning, attempt, stats, SRS, access, student-deck and report services reach
  the database only through repositories. Older services (coupons, free rules, promotions, uploads,
  admins, config, mobile tokens, media processing) still query directly; each moves when it is next
  changed.
- **Admin tests** run in CI with Vitest + Testing Library (jsdom).

### ADR-018 — Student decks, student-card reviews and content reports (Phase 8)

- **Ids from the device.** Decks and cards get their UUIDs on the device so they can be created
  offline (§13.9). `POST /my-decks/sync` takes a batch of whole rows and keeps the newer one by the
  client's `updated_at` (clamped to the server clock, so a device whose clock runs ahead cannot win
  every later conflict). Refused items (quota, empty face, someone else's image, a locked official
  card) come back in `rejected` instead of failing the batch; the app drops them locally and fetches
  the feed again.
- **Changes feed.** Every accepted write takes the next value of a per-table sequence (`sync_seq`)
  while holding a per-student advisory lock, so one student's writes are numbered in commit order
  and `GET /my-decks/changes?since=` never skips a row. Timestamps were rejected as the cursor:
  rows written in the same millisecond could be skipped. Deletions stay in the feed as tombstones.
- **Quotas** (§12.8) are counted inside the locked transaction: 50 live decks, 5,000 live cards.
  Deleting a deck deletes its cards. Images that no live card uses any more are soft-deleted, which
  frees the 300-image quota.
- **"أضف إلى بطاقاتي"** stores an `official_ref` card. Adding needs access to the source card;
  afterwards the card shows the official images only while the student can open them (`locked`
  otherwise), leaves the due queue when locked, and can still be moved or deleted.
- **Reviews of student cards** use the same SRS sync with `userCardId` instead of `flashcardId`
  (exactly one per log and state). On the device, SRS rows are keyed `u:<id>` for student cards.
  The app sends a student card's reviews only once the card itself has synced, and drops reviews
  of cards the server refused.
- **App storage.** `local_decks`/`local_cards` (schema v4) mirror the server rows plus a `dirty` flag
  and the picked image bytes. Images are scaled on the device by the picker (≤ 1080 px, JPEG 80),
  uploaded by the sync before the card is sent, and shown from the local bytes until the processed
  image arrives. Browse and Study of the student's own decks work without a connection.
- **Content reports** (§21): one open report per student and item (a repeat returns it), at most 20
  new reports in any 24 hours, on published questions and cards the student can see. Admins list
  them with filters (and the deck id for "jump to edit") and resolve or dismiss them, audited. The
  inbox page and the optional "resolved" notification to the student come with Phases 11 and 10.
- **Remote flags** `studentDecks` and `contentReports` hide the entry points in the app; the API stays
  available so data syncs if a flag is turned back on.
- **Avatars**: the account screen picks an image (≤ 800 px), uploads it as `avatar`, waits for
  processing and then sets `avatarMediaId`.

### ADR-019 — Offline packs (Phase 9)

- **What is downloadable.** Per subject or track: free items for everyone, premium items only with
  an active entitlement (a promotion opens content online but gives no offline copy); quizzes only
  with `allow_offline`, and their question list is limited to what the student may download.
- **Pack keys** follow §22.10: `{scope_type}:{scope_id}:{unit_id|none}:{questions|decks|quizzes}`,
  plus `{scope_type}:{scope_id}:-:deck.{deck_id}` for "تحميل البطاقات". "تحميل الكل" is every unit
  pack of the scope. A pack's version is a hash of its item ids and versions, so any edit, addition
  or removal shows "تحديث متاح".
- **Delta downloads.** The device compares the manifest with what it holds and requests only new or
  changed items (`items?ids=`, 50 per request); removed items and their images are deleted. Items are
  stored per chunk, so an interrupted, paused or failed download resumes where it stopped. Accepted
  answers always carry the normalizer's current output and version.
- **Leases** (`offline_leases`) are per device session: `min(now + 30 days, entitlement end)`,
  renewed at most once a day, revoked when access ends. The device stores them with the last server
  time and treats a clock more than 5 minutes behind it as expired. A `none` answer deletes that
  scope's premium items and images; free items stay.
- **Encryption at rest.** The database is SQLCipher (Phase 1). Pack images are AES-256-GCM files in
  the app's private support directory, keyed by HKDF-SHA256 from the device's database key (never
  stored). Logout wipes the tables and every pack file. Web has no packs (conditional import keeps
  `dart:io` out of the web build).
- **Local grading.** A Dart port of the normalizer passes the shared fixtures. Quizzes held in packs
  run entirely on the device (`local-<uuid>` attempts through the same screens), questions held in
  packs are checked on the device even online, and random practice / "اختبر أخطائي" are built from
  pack questions when the server cannot be reached. Written questions from a pack with another
  normalizer version go to the server.
- **Sync.** Finished offline attempts are uploaded to `POST /offline/sync`, idempotent by client id.
  The server re-grades every answer (its grade drives stats, mistakes and progress), logs
  local/server differences in `offline_grade_mismatches`, and counts questions the student may use
  now or covers with a live lease. A local mirror of wrong answers feeds offline mistake practice
  until the server has them. The stats screen shows an approximation from local attempts when
  offline. Content reports written offline are queued and sent when the connection returns.
- **Limits.** Downloads run in the app's own background (they continue across screens, pause,
  resume and wait for Wi-Fi), not as OS background tasks, so they stop when the system kills the app
  and resume at the next start. The "free space below size + 500 MB" warning and OS background
  transfers need platform plugins and device testing; both are Phase 13 work. The admin view of
  grading mismatches comes with question analytics (Phase 11).

### ADR-020 — Home, daily goal, notifications and push (Phase 10)

- **One Home call.** `GET /home` returns everything the Home tab shows (§19.1): greeting, unread
  count, the nearest active exam countdown of the student's level, live banners, today's work,
  resume items, active entitlements, subjects with free content, followed teachers and the active
  mistake count. Offline, the tab falls back to links that work without a connection (review,
  downloads).
- **Banners** are admin-uploaded `banner` media in the public bucket. A banner is live when active
  and inside its optional schedule; an optional education level narrows the audience. Tap actions
  are validated on save (entity id, `https://` URL or an in-app path) and the app ignores any target
  it cannot route, so a bad banner never strands a student. In-app actions use `go`, switching tabs.
- **Daily goal and streak.** `user_daily_activity` counts graded answers (attempts and question
  checks) and SRS ratings per business day (04:00 Asia/Damascus, like SRS). Each day keeps the goal
  in force that day, so changing the goal never rewrites history. The streak counts consecutive days
  with the goal met, ending today, or yesterday while today is still open.
- **Notifications.** Admin notifications are stored once and fanned out by a pg-boss job into
  `user_notifications` (the inbox) in batches; the job is idempotent. Consent (§20.2): announcements
  and report outcomes always reach the inbox and push; learning notifications always reach the inbox
  but push only with "التعلّم" on; promotions reach neither inbox nor push unless the student opted
  in. Due-card reminders run hourly and send once per business day at the student's chosen hour.
- **Push.** The API talks to FCM HTTP v1 directly with a service-account JWT (no SDK); unregistered
  tokens are revoked. Without credentials a recording sender logs instead. The app registers its
  token after sign-in and revokes it before sign-out. The device side is the `PushMessaging`
  interface: builds without Firebase configuration use `NoPushMessaging` (inbox only). Wiring the
  FCM plugin needs the release Firebase files and device testing, so it is Phase 13 work.
- **Partial updates never default.** A `.default()` in an update schema filled omitted fields and
  wiped a banner's action when toggling it; update schemas now carry no defaults, and a contracts
  test enforces it.

### ADR-021 — Admin productivity (Phase 11)

- **Bulk import** (§27) is a two-step job. The upload (≤ 5 MB, base64 in JSON, ≤ 2000 rows) is
  stored on `import_jobs`; the `imports.parse` job reads CSV or XLSX, resolves every code (level,
  subject, unit, lesson, track slug) and validates each row, writing Arabic per-row errors to
  `import_errors` and the resolved rows to the job. The preview shows both. **A file with any error
  cannot be imported**: the admin fixes the file and uploads it again, so a partial import never
  happens. Confirm queues `imports.commit`, which re-resolves the codes (the structure may have
  changed), then inserts every question, the job's completion and the audit entry in one
  transaction. Imported questions are drafts or published; blank `is_free_override` follows the free
  rule (recomputed for each touched scope), a value becomes a manual override. Export writes the
  same layout, so an export re-imports unchanged (formula-looking cells are neutralised on export and
  restored on import).
- **No spreadsheet dependency.** CSV and XLSX are read by small in-house readers (RFC 4180, a ZIP
  central-directory reader with shared/inline strings) next to the existing writers. Entry and total
  sizes are capped before and during inflation (zip bombs).
- **Flashcard bulk upload** pairs files by prefix in the browser (`001-front.png`/`001-back.png`,
  `_a`/`_b`, أمامي/خلفي; single-letter markers need a separator), reads ZIPs with the platform's
  `DecompressionStream`, lets the admin correct the grid, uploads each image through the normal
  presigned flow (processing is the media job), then appends all pairs in one request and one deck
  version bump. Free status stays a deck setting.
- **Question analytics** read `question_stats` (maintained by graded attempts), open reports and
  offline grading mismatches. The auto-flag rule is unchanged (≥ 30 attempts; < 20% correct or a wrong
  option chosen more than the right one); clearing a flag is audited and stores the attempt count,
  so the rule looks again only after 30 further attempts.
- **Audit log** is listed newest first with actor, exact action or `prefix.` filter, resource and
  Damascus-day range. **Global search** queries each entity type with escaped ILIKE (a UUID also
  matches ids) and reuses coupon lookup by full code (hash) or last four.
- **Notification preview** (§26.2, missed in Phase 10) counts recipients and push consent with the
  same audience and consent rules as the fan-out; the admin sees the numbers before confirming.

### ADR-022 — Student web (Phase 12)

- **One codebase.** The web build is the Flutter app with web adaptations only where the platform
  differs: cookie auth, WASM SQLite, no offline packs, no secure storage. Browsers without
  persistent storage get drift's in-memory database and an "online only" notice rather than a
  failure.
- **Layout.** `ResponsiveList` (1–3 columns from 600 px) for lists; `ContentWidth` (720 px) for
  reading, study and quiz screens; the navigation rail from 600 px. Rows of a grid take the height of
  their tallest card.
- **Hosting.** Cloudflare Pages via a manual workflow per environment. Headers are generated at
  deploy time from the environment's API and media origins, so the CSP names exact origins. Every
  file is `no-cache` with ETag revalidation because Flutter's engine files are not content-hashed.
- **Service worker.** Network-first for same-origin files, cache as the offline fallback; it never
  serves stale files while online, avoiding a mismatched engine and app. Flutter's deprecated worker
  (which unregisters itself) is not used; the bootstrap is a custom template.
- **Measurement.** Budget in CI (brotli first-load set ≤ 4 MB) and a reproducible throttled
  measurement in headless Chromium over the DevTools protocol, with no npm dependencies. The skwasm
  build was evaluated and rejected: same bytes, and the wasm module loads after its JS loader.
