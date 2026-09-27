# Arabic Education App — Project Specification for Claude Code
## Flutter (Android + iOS + Web) Student App · Next.js Admin · Fastify API

> **Version:** v5.2 — Email/Password Auth + Consistency Fixes
> **Date:** 2026-09-24
> **Supersedes:** v5.1, v5 and v4 where this version differs (all conflicting older text is void)
> **Primary market:** Syria
> **Student platforms:** Android, iOS (Plan A) + Web from the same Flutter codebase
> **Admin platform:** Responsive web dashboard (Next.js)
> **Language:** Arabic only, full RTL
> **Initial scale:** ~1,000 students, thousands of questions and flashcard images
> **Plan B:** If store distribution fails, the student web app becomes the primary client and PWA installation is enabled. No new frontend, no backend changes.

---

## v5.1 consistency resolutions

This revision resolves implementation gaps found during the v5 review:

1. Offline packs are a dedicated **Phase 9**; later phases are renumbered.
2. `content_version` and `allow_offline` are explicit schema fields.
3. The database entity inventory is reconciled with concrete definitions; redundant `teacher_subjects`, `roles`, and `user_roles` are removed; `offline_leases` is included.
4. Teacher-track / subject consistency is enforced both by service validation and **composite foreign keys**.
5. "One active entitlement per scope" uses partial unique indexes plus stale-expiry cleanup inside the same grant/redemption transaction.
6. Student authentication is **Email + Password only** in V1. Google Sign-In, Sign in with Apple, OAuth/PKCE, and social account linking are removed. Flutter uses native email/password fields; the API issues first-party mobile access/refresh tokens after credential verification.
7. SRS fuzz uses an exact deterministic SHA-256 based algorithm shared by Dart and TypeScript.
8. SRS, streaks, daily limits, and study-day calculations all use one **04:00 Asia/Damascus** business-day boundary.
9. Temporary → permanent upgrade defaults to **allowed**. The production domain is not a Phase-1 blocker; it is required before Phase 12 web/staging deployment.

## Changes from v4 (summary)

| Area | v4 | v5 |
|---|---|---|
| Backend hosting | Ambiguous (separate API vs Next.js API on Vercel) | Standalone Fastify API in Docker; Next.js is admin UI only and calls the API |
| Jobs | Not specified | pg-boss (Postgres-backed queue) |
| Storage | Generic object storage | Cloudflare R2: private bucket + public bucket, signed URLs |
| Auth | Unspecified library | Better Auth; bearer tokens (mobile), httpOnly cookies (web/admin); admin TOTP 2FA required |
| Access scopes | Polymorphic `scope_type/scope_id`, undefined | Exactly two scopes: `subject` and `teacher_track`, real FKs; they never unlock each other |
| Overlapping coupons | Undefined | Rejected with `ALREADY_ENTITLED`; coupon not consumed |
| Free content | Rule-based + `is_free` import column conflict | Rules materialized into `is_free` at publish time; import column = optional manual override |
| Levels | Undefined | Students browse all levels; profile level only sets defaults |
| Flashcards | Flip + prev/next, no rating | Browse mode (prev/next) + Study mode with Anki-style spaced repetition (Again / Good / Easy) |
| Student decks | None | Private student-created decks (text + optional images) |
| MCQ | Admin config only | Student chooses Practice mode (check each) or Exam mode (grade at end); admin can force exam-only |
| Mistake review | Basic list | Mistake bank with mastery rule + statistics dashboard |
| Web | Plan B only (Next.js PWA) | Flutter Web student app in V1 (Phase 12); PWA install enabled only under Plan B |
| New features | — | Question problem reports, per-question admin analytics, mock exams, exam countdown, daily goal & streak, due-card reminders, dark mode, font size |

---

# 0. Locked Architecture Decisions

Claude Code must read this section first. These decisions override anything else.

## 0.1 Architecture

```text
 Flutter Student App                Next.js Admin Dashboard
 Android · iOS · Web                (UI only, multiple admins)
        │  HTTPS (bearer / cookie)          │  HTTPS (cookie + 2FA)
        └──────────────┬────────────────────┘
                       ▼
            apps/api — Fastify (Node, TypeScript)
            Controllers → Services → Repositories
                       │
        ┌──────────────┼──────────────────────┐
        ▼              ▼                      ▼
 Neon PostgreSQL   pg-boss jobs         Cloudflare R2
 (Drizzle, migr.)  (in Postgres)        media-private + media-public
```

- The API is the **only** component that talks to PostgreSQL and R2 credentials.
- The admin dashboard never queries the database directly.
- The API is client-agnostic: Flutter mobile, Flutter web, admin, and any future client use the same `/api/v1` endpoints.

## 0.2 Teachers are content entities only

Teachers have no accounts, logins, passwords, roles, dashboards, or upload access. Admins manage teachers and their **teacher tracks** (see §7). Students can browse and follow teachers. Following never grants access.

## 0.3 Multiple administrators

Multiple admin accounts from V1. Role column supports future roles (`super_admin`, `content_admin`, `support_admin`) but V1 uses a single `admin` role with full access. Every sensitive admin action is attributed to the acting admin ID. TOTP 2FA is mandatory for admins.

## 0.4 Admin-only content

All educational and commercial content is created and managed by admins. No approval workflow. The only student-authored content is **private** student flashcard decks (§13.9) and **problem reports** sent to admins (§21).

## 0.5 Platforms, Plan A and Plan B

**Plan A (primary):** Flutter app on Google Play and Apple App Store.

**Student web (V1, Phase 12):** the same Flutter codebase built for web, hosted at `app.<domain>`. Same accounts, same API, same features, with web-specific adaptations (§24). PWA manifest and service worker ship but install prompts are **off**.

**Plan B (if store distribution fails or is blocked):** promote the web app to primary, enable PWA install prompts, and direct students to it. No new frontend and no backend changes are needed.

If Flutter Web fails the web performance acceptance criteria (§34.3), a Next.js student web frontend may be built later against the same API. Document this in `docs/web-fallback.md`. Do not build it unless explicitly requested.

## 0.6 Store strategy and coupon compliance

- Coupon redemption is isolated from the entitlement engine. Entitlements work regardless of whether the redeem UI exists.
- `couponRedemption` is a **compile-time** flag per platform build (`--dart-define`). It must never be switched on or off remotely. Remote toggling of features around App Review violates Apple's rules and risks developer account termination.
- The iOS app must not link to, mention, or direct users to web-based coupon redemption.
- App Review notes must describe the coupon flow honestly and include a demo account with active entitlements.
- If iOS review rejects coupon redemption: ship the iOS build with `couponRedemption=false`. Locked content then shows the neutral message (§8.7). Whether to add Apple In-App Purchase is an open business decision (§44); the entitlement source `future_purchase` already supports it.
- Web builds always have `couponRedemption=true`.
- Do not implement Apple IAP or Google Play Billing in V1.

## 0.7 Backend is the authority

The API alone decides authentication, roles, access, entitlements, free content, coupons, grading, progress writes, bookmarks, follows, and notifications. Never send premium content, correct answers, or accepted answers to a client that is not entitled to receive them.

## 0.8 No device limit

No device cap. Sessions are recorded for security, diagnostics, and revocation only.

## 0.9 No AI in V1

No AI grading, AI generation, semantic matching, fuzzy matching, or chatbots. Written answers use deterministic normalization and exact matching against accepted answers.

---

# 1. Product Summary

An Arabic educational app for students in Syria at three levels: **Grade 9, Grade 12, College**.

Core learning content:

1. Flashcards (official image cards + private student text/image cards), with spaced repetition
2. Multiple-choice questions
3. True/False questions
4. Written short-answer questions
5. Quizzes and mock exams in Practice or Exam mode

Free students get configurable limited access. Premium access is represented by server-side **entitlements**. Coupons are the main V1 activation mechanism.

---

# 2. Technology Stack

## 2.1 Student app (Flutter)

- Flutter, Dart; targets Android, iOS, Web
- Riverpod (state), GoRouter (routing, path URL strategy on web)
- Dio + client generated from the API's OpenAPI spec
- Drift (SQLite; web via sqlite3 WASM) for offline data: SRS card states, review logs, student decks, exam answer drafts, cache metadata
- flutter_secure_storage (mobile tokens only; not used on web)
- cached_network_image with explicit `cacheKey`
- firebase_messaging (push; best-effort)
- sentry_flutter (crash reporting)
- Use the latest stable compatible versions at implementation time.

## 2.2 Admin dashboard

- Next.js (App Router), TypeScript, Tailwind CSS, shadcn/ui, Arabic RTL, responsive
- Calls the API only; uses the generated TypeScript API types
- Cookie session + TOTP 2FA

## 2.3 API

- Node.js LTS, TypeScript, **Fastify**
- Zod schemas (validation + OpenAPI generation via a Zod type provider)
- Drizzle ORM, node-postgres driver (supports interactive transactions and row locks)
- **Better Auth** for user identity, email/password credentials, email OTP verification/reset, cookie sessions for web/admin, and TOTP 2FA for admins.
- **No Google Sign-In, Sign in with Apple, OAuth, or PKCE in V1.**
- Flutter presents native **email + password fields** and calls the API directly.
- **Mobile token model:** after the API verifies the email/password credentials, a small first-party mobile token service issues:
  - access JWT: 15-minute lifetime
  - opaque refresh token: 30-day lifetime, random 256-bit value
  - only a SHA-256/HMAC hash of the refresh token is stored server-side
  - refresh tokens rotate on every successful refresh
  - each token belongs to a `session_family_id`
  - reuse of an already-rotated token outside a **30-second retry grace window** revokes the entire family
- Store access/refresh tokens only in `flutter_secure_storage`.
- The mobile token service is intentionally separate from Better Auth's browser cookie/session transport. Better Auth remains the credentials/identity source; the API owns the mobile token pair.
- Phase 1 must prove this flow with automated backend integration tests: login, invalid password, unverified email, refresh rotation, duplicate refresh inside the grace window, replay outside the window, logout/revocation, expired access token, expired refresh token. No Apple/Google developer account, registered OAuth domain, or physical device is required for the Phase 1→2 gate.
- **pg-boss** for background jobs
- `@fastify/rate-limit`
- sharp (image processing)
- pino (structured logs), Sentry

Layering:

```text
Route (thin) → Service (business logic) → Repository (Drizzle) → PostgreSQL
```

## 2.4 Database

Neon PostgreSQL, region `eu-central-1` (Frankfurt). Production compute: autosuspend (scale-to-zero) **disabled**. All schema changes via Drizzle migrations.

## 2.5 Storage

Cloudflare R2 (S3-compatible). See §12.

## 2.6 Email

Transactional email provider (Resend or Postmark). Used for verification and password reset via **6-digit OTP codes** (no deep links required).

## 2.7 Push

Firebase Cloud Messaging for Android, iOS (APNs via FCM), and Web. Push is best-effort; the in-app notification inbox is the source of truth.

## 2.8 Observability

Sentry for API, admin, and Flutter. `/health` and `/ready` endpoints. Structured logs with request IDs.

---

# 3. Repository Structure

```text
education-platform/
├── apps/
│   ├── mobile/                 # Flutter: android, ios, web targets
│   │   ├── lib/
│   │   │   ├── app/            # bootstrap, router, theme, flags
│   │   │   ├── core/           # api client, db (drift), errors, rtl utils
│   │   │   ├── features/       # auth, home, subjects, teachers, flashcards,
│   │   │   │                   # srs, my_decks, practice, exam, mistakes,
│   │   │   │                   # stats, bookmarks, access, notifications,
│   │   │   │                   # profile, settings
│   │   │   └── shared/         # widgets, formatters
│   │   ├── web/                # index.html, manifest.json, icons
│   │   └── test/
│   ├── admin/                  # Next.js admin UI
│   └── api/                    # Fastify API + job workers
│       └── src/
│           ├── routes/
│           ├── services/
│           ├── repositories/
│           ├── authorization/
│           ├── jobs/
│           ├── storage/
│           └── plugins/
├── packages/
│   ├── db/                     # Drizzle schema, migrations, seeds
│   ├── contracts/              # Zod schemas shared by api + admin; OpenAPI output
│   ├── arabic-normalizer/      # TS normalizer (server-side grading only)
│   └── srs/                    # Reference SRS algorithm in TS (tests + server validation)
├── docs/
│   ├── architecture.md
│   ├── api.md                  # generated OpenAPI + notes
│   ├── database.md
│   ├── access-model.md
│   ├── srs.md
│   ├── storage-r2.md
│   ├── mobile.md
│   ├── web.md
│   ├── admin.md
│   ├── deployment.md
│   ├── store-compliance.md
│   └── web-fallback.md
└── CLAUDE.md
```

The SRS algorithm is implemented in Dart (runs on device) and mirrored in `packages/srs` (TS). Both must pass the same shared test vectors (JSON fixtures in `packages/srs/fixtures`).

---

# 4. Deployment Topology

| Component | Host | Domain |
|---|---|---|
| API + workers | Docker on a VPS (e.g., Hetzner, Germany) behind Caddy (TLS), or Railway/Fly.io EU region | `api.<domain>` |
| Admin | Vercel (region fra1) or same VPS | `admin.<domain>` |
| Student web | Cloudflare Pages (static Flutter web build) | `app.<domain>` |
| Database | Neon (Frankfurt) | — |
| Media | Cloudflare R2 | public: `cdn.<domain>` |

- Environments: `development`, `staging`, `production`, each with its own database branch and buckets.
- CI (GitHub Actions): lint, typecheck, unit/integration tests, migration check, Flutter analyze/test, Flutter web build, OpenAPI client regeneration check.
- `app.<domain>`, `admin.<domain>`, and `api.<domain>` share the same registrable domain so cookies can be `SameSite=Lax`.

---

# 5. Roles

Only two authenticated roles: `student`, `admin`. No teacher role.

---

# 6. Education Structure and Content Hierarchy

```text
Education Level (Grade 9 | Grade 12 | College)
  └─ College only: University? → Faculty? → Academic Year?
       └─ Subject
            ├─ Unit?            (optional)
            │    └─ Lesson?     (optional)
            └─ Content: questions, flashcard decks, quizzes
                 └─ optionally belongs to a Teacher Track (§7)
```

- College intermediate layers are optional; do not hard-code them as mandatory.
- Units and lessons are optional. Content may attach directly to a subject.
- Every orderable entity has `sort_order`.

### 6.1 Subject / unit / lesson integrity

Use explicit subject ownership:

```text
units:   id, subject_id, ... , UNIQUE(id, subject_id)
lessons: id, subject_id, unit_id?, ... , UNIQUE(id, subject_id)
```

For `lessons.unit_id`, service validation and an FK ensure the unit belongs to the same `subject_id`.

Every content table carrying `subject_id` plus optional `unit_id` / `lesson_id` (`questions`, `flashcard_decks`, `quizzes`) must enforce:
- if `unit_id` is present, `(unit_id, subject_id)` references `units(id, subject_id)`
- if `lesson_id` is present, `(lesson_id, subject_id)` references `lessons(id, subject_id)`
- if both `unit_id` and `lesson_id` are present, service validation requires the lesson's `unit_id` to equal the content's `unit_id`

This prevents a Physics question from accidentally referencing a Chemistry unit/lesson.

---

# 7. Teachers, Teacher Tracks, Following

## 7.1 Teacher

```text
teachers: id, name_ar, slug, photo_media_id?, short_description?, bio?,
          is_active, sort_order, created_at, updated_at, deleted_at?
```

## 7.2 Teacher track

A teacher track is a teacher's own collection of content within one subject, e.g. "أ. أحمد — فيزياء بكالوريا".

```text
teacher_tracks: id, teacher_id, subject_id, title_ar, slug, description?,
                cover_media_id?, is_active, sort_order,
                created_at, updated_at, deleted_at?
```

- A teacher may have multiple tracks, including multiple tracks in the same subject.
- Track content reuses the subject's units and lessons (optional).

## 7.3 Content ownership rule

Every question, flashcard deck, and quiz has:

```text
subject_id        NOT NULL
teacher_track_id  NULL
```

- `teacher_track_id IS NULL` → **general subject content**, governed by the subject scope.
- `teacher_track_id IS NOT NULL` → **teacher track content**, governed by the track scope.
- Enforce track/subject consistency **twice**:
  1. Service validation with a clear `VALIDATION_ERROR`.
  2. A real PostgreSQL composite foreign key. Add `UNIQUE(id, subject_id)` on `teacher_tracks`, then for each table that stores both columns (`questions`, `flashcard_decks`, `quizzes`) add:
     `FOREIGN KEY (teacher_track_id, subject_id) REFERENCES teacher_tracks(id, subject_id)`.
     With PostgreSQL's default `MATCH SIMPLE`, rows with `teacher_track_id IS NULL` remain valid general-subject content.

## 7.4 Following

```text
teacher_followers: id, teacher_id, user_id, created_at   UNIQUE(teacher_id, user_id)
```

Following enables: followed-teachers list, home feed section, targeted notifications. **Following never grants access.**

---

# 8. Access Model

## 8.1 Scopes

Exactly two access scopes:

| scope_type | Unlocks |
|---|---|
| `subject` | General content of that subject (`teacher_track_id IS NULL`) |
| `teacher_track` | Content of that teacher track only |

**A subject entitlement does not unlock teacher track content, and a teacher track entitlement does not unlock general subject content.**

Scope columns (used by entitlements, coupons, coupon batches, free rules, promotions):

```text
scope_type        enum('subject','teacher_track') NOT NULL
subject_id        FK NULL
teacher_track_id  FK NULL
CHECK ((scope_type='subject' AND subject_id IS NOT NULL AND teacher_track_id IS NULL)
    OR (scope_type='teacher_track' AND teacher_track_id IS NOT NULL AND subject_id IS NULL))
```

No polymorphic `scope_id` columns.

## 8.2 Entitlements

```text
entitlements: id, user_id, scope_type, subject_id?, teacher_track_id?,
              source enum('coupon','admin_grant','promotion','future_purchase'),
              coupon_id?, granted_by_admin_id?,
              starts_at, expires_at?, is_permanent,
              status enum('active','revoked','expired','superseded'),
              revoked_at?, revoked_by_admin_id?, revoke_reason?,
              created_at, updated_at
```

- Permanent: `is_permanent=true, expires_at=null`.
- Temporary: fixed `expires_at` (duration-based or fixed date, e.g., academic-year end).
- All dates are stored in UTC. Date-only expiries (e.g., `2027-06-30`) mean **23:59:59 Asia/Damascus** on that date.
- An entitlement is **active** when `status='active' AND starts_at <= now AND (expires_at IS NULL OR expires_at > now)`. This is evaluated on every request; expiry takes effect immediately. A nightly job sets `status='expired'` for reporting only.
- Never use `is_premium` flags on users.

## 8.3 Overlap rule

A student may hold at most one `status='active'` entitlement per scope.

Database safety:

```sql
CREATE UNIQUE INDEX entitlements_one_active_subject
ON entitlements(user_id, subject_id)
WHERE status = 'active' AND scope_type = 'subject';

CREATE UNIQUE INDEX entitlements_one_active_track
ON entitlements(user_id, teacher_track_id)
WHERE status = 'active' AND scope_type = 'teacher_track';
```

Time cannot appear safely in the predicate of this uniqueness rule. Therefore **every coupon redemption and admin-grant/upgrade transaction must first expire stale rows for the same user+scope**:

```text
UPDATE matching entitlements
SET status='expired'
WHERE status='active'
  AND expires_at IS NOT NULL
  AND expires_at <= now();
```

Then lock/check the remaining active entitlement and perform the grant. The partial unique indexes are the final concurrency guard if two different coupons for the same scope race each other.

If two **different coupons** for the same user+scope race:
- one entitlement insert succeeds
- the other insert may hit PostgreSQL unique-violation `23505` on `entitlements_one_active_subject` or `entitlements_one_active_track`
- the API must **ROLL BACK the entire losing transaction**
- map that known constraint violation to `ALREADY_ENTITLED`
- because coupon consumption happens after the entitlement insert and the transaction is rolled back, the losing coupon remains **unused and redeemable by someone else**
- any other/unrecognized unique violation remains a server error

This mapping is required in both coupon redemption and admin-grant services.

V1 does not schedule future-start entitlements; new grants use `starts_at=now`. Future scheduled grants require an explicit `scheduled` status before being added.

- Redeeming a coupon (or an admin grant) for a scope where the student still has an active entitlement is **rejected** with `ALREADY_ENTITLED`. The coupon is **not consumed**.
- After expiration cleanup, a new coupon for the same scope works normally.
- `allowTemporaryToPermanentUpgrade` defaults to **true**. A permanent coupon over an active temporary entitlement supersedes the temporary row and creates the permanent entitlement in the same transaction. The coupon is consumed only after the upgrade succeeds.
- Temporary-over-temporary and permanent-over-permanent redemptions remain `ALREADY_ENTITLED`.
- Admins can **extend** an existing entitlement (change `expires_at` or make permanent) instead of granting a duplicate. Audited.

## 8.4 Free content (materialized)

```text
free_access_rules: id, scope_type, subject_id?, teacher_track_id?,
                   content_kind enum('questions','flashcard_decks','quizzes','all'),
                   rule_type enum('manual','first_n_items','first_n_lessons','first_unit','percentage'),
                   rule_value int?, updated_by_admin_id, updated_at
```

Each content item stores:

```text
is_free       boolean NOT NULL default false
free_source   enum('rule','manual_override')
```

- When an item is **published**, the API evaluates the scope's rule against current ordering and sets `is_free` (unless a manual override exists).
- Existing items do **not** change when new content is added.
- When an admin **changes a rule**, the dashboard shows a preview ("سيصبح 12 عنصراً مجانياً و3 مدفوعة") and, on confirmation, a job recomputes `is_free` for all items in scope with `free_source='rule'`. Audited.
- `manual` rule: only manual overrides make items free.
- Selected free quiz / free flashcard deck = manual override on that item.

## 8.5 Promotions (temporary free access)

```text
promotions: id, scope_type, subject_id?, teacher_track_id?, title_ar,
            starts_at, ends_at, is_active, created_by_admin_id, created_at
```

During an active promotion, all content in the scope is accessible to all students. No entitlement rows are created.

## 8.6 Authorization helpers (API)

```text
requireUser()           requireAdmin()   (admin also requires 2FA-verified session)
scopeOf(item)           → subject scope or teacher_track scope
hasActiveEntitlement(user, scope)
isPromoted(scope, now)
canAccessItem(user, item) = item.is_free OR isPromoted(scopeOf(item)) OR hasActiveEntitlement(user, scopeOf(item))
canAccessQuestion / canAccessDeck / canAccessQuiz / canAccessFlashcard → canAccessItem
canRedeemCoupon(user, coupon)
```

All content endpoints use these helpers. Locked items are returned as **metadata only** (title, counts, `locked: true`, lock reason); never payloads.

## 8.7 Locked content UX

- Build with `couponRedemption=true`: "هذا المحتوى يحتاج إلى تفعيل" + button "إدخال كود التفعيل".
- Build with `couponRedemption=false`: "هذا المحتوى غير متاح على حسابك" (no button, no redeem route registered).

## 8.8 Mixed quizzes

- A quiz containing free and premium questions shows only the questions the student can access.
- Quiz detail returns `total_count`, `accessible_count`, `locked_count`. UI: "12 من 30 سؤال متاح" + locked CTA.
- Attempts include only accessible questions; score is computed over those.
- If `accessible_count = 0`, the quiz is shown as locked.
- **Exception — mock exams** (`is_mock_exam=true`) are all-or-nothing: locked unless every question is accessible.
- Random practice and mistake-bank quizzes only draw accessible questions.

## 8.9 Levels and browsing

- A student's profile `education_level_id` only sets defaults (home screen, subject list tab).
- Students may browse **all levels** and see free content everywhere, plus entitled content in any level.
- The student may change their profile level at any time from settings.
- Coupon eligibility does **not** depend on the profile level. `COUPON_NOT_ELIGIBLE` is reserved for future batch restrictions and unused in V1.

---

# 9. Coupons

## 9.1 Tables

```text
coupon_batches: id, name, distributor_name?, notes?, scope_type, subject_id?, teacher_track_id?,
                quantity, valid_from?, expires_at?, access_duration_days?, access_expires_at?,
                permanent_access, status enum('active','revoked'),
                created_by_admin_id, created_at, revoked_at?, revoked_by_admin_id?

coupons: id, batch_id, code_hash (unique), code_encrypted, code_last4,
         scope_type, subject_id?, teacher_track_id?,        -- copied from batch
         valid_from?, expires_at?, access_duration_days?, access_expires_at?, permanent_access,
         max_uses default 1, current_uses default 0,
         status enum('active','redeemed','revoked'),
         created_by_admin_id, created_at

coupon_redemptions: id, coupon_id, user_id?, redeemed_at, session_id?, entitlement_id,
                    UNIQUE(coupon_id, user_id)

coupon_redemption_failures: id, user_id?, ip_hash, code_last4?, reason, created_at
```

- `valid_from/expires_at` = when the **code** can be redeemed.
- `access_duration_days` or `access_expires_at` or `permanent_access` = what the **entitlement** gets.

## 9.2 Code format

- Alphabet (31 chars, no ambiguous characters): `23456789ABCDEFGHJKMNPQRSTUVWXYZ`
- 10 random characters from a CSPRNG, displayed as `XXXX-XXXX-XX`.
- Codes contain no subject, level, or teacher information.
- `code_hash = HMAC-SHA256(COUPON_HMAC_SECRET, normalized_code)`
- `code_encrypted = AES-256-GCM(COUPON_ENCRYPTION_KEY, code)` so admins can re-export a batch.
- `code_last4` for admin search and support.

## 9.3 Input normalization (server)

1. Trim, remove spaces and dashes
2. Convert Arabic-Indic (٠–٩) and Persian (۰–۹) digits to ASCII
3. Uppercase
4. If length ≠ 10 or contains characters outside the alphabet → `COUPON_NOT_FOUND` (counts as a failure)

The Flutter coupon field is LTR, uppercase, monospace, and auto-inserts dashes.

## 9.4 Redemption transaction

Single database transaction (node-postgres, not an HTTP driver):

```text
1.  requireUser; check rate limit / cooldown
2.  normalize code; compute HMAC
3.  SELECT coupon ... WHERE code_hash = $1 FOR UPDATE
4.  not found → COUPON_NOT_FOUND
5.  status revoked or batch revoked → COUPON_REVOKED
6.  outside valid_from/expires_at → COUPON_EXPIRED
7.  current_uses >= max_uses or already redeemed by this user → COUPON_ALREADY_USED
8.  UPDATE stale active entitlements for this user+scope to `expired` when `expires_at <= now()`
9.  SELECT remaining active entitlement for this user+scope FOR UPDATE
10. active entitlement exists → ALREADY_ENTITLED (coupon untouched)
      except: permanent coupon over temporary when `allowTemporaryToPermanentUpgrade=true`
      → mark old entitlement `superseded`
11. INSERT entitlement (source='coupon', starts_at=now())
12. UPDATE coupon current_uses+1; status='redeemed' if exhausted
13. INSERT coupon_redemption
14. COMMIT
15. return updated access summary for the scope
```

Failures (4–10) are logged to `coupon_redemption_failures`.

## 9.5 Abuse protection

- Per user: 5 attempts/minute, 20/hour.
- 10 consecutive failures → 30-minute cooldown (`RATE_LIMITED`).
- Per IP: 60 attempts/hour.
- Admin dashboard shows users/IPs with high failure counts.

## 9.6 Batch generation and export

Admin selects scope, quantity (max 5,000 per batch), code validity window, access duration/permanent, distributor name. Generation runs as a background job; the admin sees progress. Export CSV or XLSX:

```text
code, batch_name, distributor, scope_type, subject, teacher_track, access, code_expires_at, status, created_at
```

Exports are audited. Admin can revoke a whole batch (unredeemed codes become unusable; existing entitlements are unaffected unless the admin also revokes them explicitly).

## 9.7 Concurrency requirement

20 concurrent redemptions of one single-use code → exactly 1 success, 19 failures, 1 entitlement, 1 redemption row. Automated integration test.

Also test **two different valid coupons for the same user+scope concurrently**: exactly one entitlement is created; the loser returns `ALREADY_ENTITLED`; the losing coupon remains `current_uses=0`, `status='active'`, with no redemption row.

---

# 10. Feature Flags, Remote Config, App Version

## 10.1 Compile-time flags (per platform build)

```text
COUPON_REDEMPTION=true|false     # never remote-controlled
```

## 10.2 Remote config (`GET /api/v1/config`)

Returns per-platform values:

```json
{
  "minSupportedVersion": { "android": "1.0.0", "ios": "1.0.0", "web": "1.0.0" },
  "latestVersion": { "android": "1.2.0", "ios": "1.2.0", "web": "1.2.0" },
  "features": {
    "teacherFollowing": true,
    "randomPractice": true,
    "studentDecks": true,
    "streaks": true,
    "contentReports": true
  },
  "srsDefaults": { "newCardsPerDay": 20, "maxReviewsPerDay": 200 },
  "support": { "email": "...", "whatsapp": "..." },
  "privacyPolicyUrl": "...",
  "termsUrl": "..."
}
```

- Below `minSupportedVersion` → blocking "يرجى تحديث التطبيق" screen with store link (web: reload).
- Remote flags may only toggle features that are visible and described in store listings. Nothing payment-related is remote.

---

# 11. Authentication, Sessions, Accounts

## 11.1 Students

- **Email + password only in V1.**
- Flutter uses native Arabic email/password forms; no browser authentication sheet is opened.
- Email verification uses a 6-digit OTP.
- Password reset uses a 6-digit email OTP followed by a new password.
- Registration fields: full name, email, password, education level; optional university/faculty/academic year for College; optional avatar.
- Google Sign-In, Sign in with Apple, social-login account linking, OAuth, and PKCE are explicitly out of V1.

## 11.2 Tokens and sessions

- **Mobile:** native email/password login → API credential verification → first-party token pair from §2.3. Access token lifetime = **15 minutes**; refresh token lifetime = **30 days**; refresh token rotates on use. A 30-second retry grace window handles concurrent/retried refresh calls; reuse after that window revokes the session family. Tokens are stored only in `flutter_secure_storage`.
- **Phase-1 automated gate:** server integration tests must pass for registration, email OTP verification, email/password login, token issuance, rotation, retry grace, replay detection, logout and revocation. Flutter widget/integration tests must cover form validation and API success/error handling.
- **Physical Android/iOS smoke tests are not a Phase-1 blocker.** They must be performed by the project owner/local CI/device environment before Phase 13 release, covering login, secure token persistence, refresh after app restart, logout, and account deletion.
- **Web (student) and admin:** httpOnly, Secure, `SameSite=Lax` cookies. Mutating requests require an `Origin` check against allowed origins plus a custom header (`X-Requested-With`) for CSRF defense.
- `sessions` table records platform, app version, created/last seen, IP hash, user agent summary, status. Students can view and revoke sessions.

## 11.3 Admins

- Email + password + mandatory TOTP 2FA (enroll on first login; recovery codes).
- Admin sessions expire after 12 hours of inactivity.
- The last active admin cannot be deactivated.
- Admins are created only by other admins (first admin via seed/CLI).

## 11.4 Account deletion

In-app, with a confirmation screen that explicitly warns: "سيتم حذف حسابك وفقدان جميع صلاحيات الوصول المفعّلة ولا يمكن استرجاعها". See §33 for data handling.

---

# 12. Media and Storage (Cloudflare R2)

## 12.1 Buckets

| Bucket | Access | Contents |
|---|---|---|
| `media-public` | Public via custom domain `cdn.<domain>` with Cloudflare caching | Banners, teacher photos, subject/track covers |
| `media-private` | No public access; signed URLs only | Flashcard images (official), student deck images, import files, originals |

## 12.2 Object keys

Opaque keys with no business meaning:

```text
{env}/{kind}/{yyyy}/{mm}/{uuid}/{variant}.webp
kind: flashcard | banner | teacher | cover | user-card | import | original
variant: full | thumb | original
```

Relationships live in the database (`media_files`), never in paths.

## 12.3 Upload flow (admin and student)

```text
1. Client → POST /api/v1/uploads { kind, contentType, size }
2. API validates kind, type, size, quota → creates media_files row (status='pending')
   → returns presigned PUT URL (15 min TTL, exact content-type and max size)
3. Client PUTs file directly to R2 (no file bytes pass through the API)
4. Client → POST /api/v1/uploads/{id}/complete
5. Job: download original, verify magic bytes, read dimensions, generate variants with sharp,
   upload variants, update media_files (status='ready', metadata)
6. Orphaned pending uploads older than 24h are deleted by a cleanup job
```

## 12.4 Image variants and budgets

| Kind | full | thumb | Target size |
|---|---|---|---|
| Flashcard (official) | WebP, max 1080 px wide, quality ~75 | 360 px | ≤ 150 KB full |
| Banner | WebP, 1600 px | 800 px | ≤ 200 KB |
| Teacher / cover | WebP, 800 px | 200 px | ≤ 80 KB |
| Student card image | client-compressed to ≤ 1080 px before upload; server makes WebP | 360 px | ≤ 200 KB |

Accepted inputs: PNG, JPEG, WebP. Max upload: 10 MB (admin), 2 MB (student).

```text
media_files: id, bucket, storage_key, kind, owner_user_id?, uploaded_by_admin_id?,
             mime_type, width, height, original_size, optimized_size,
             variants jsonb, status enum('pending','ready','failed'), version int,
             created_at, deleted_at?
```

## 12.5 Delivery

- Public media: `https://cdn.<domain>/<key>` (cacheable).
- Private media: the API includes **signed GET URLs (1 hour TTL)** in content responses, only for items the student can access.
- Flutter caches images with `cacheKey = "{media_id}:{variant}:{version}"` so changing signed URLs don't re-download.
- When an entitlement expires, cached images may remain on the device, but the app stops displaying locked content (access is checked through the API).

## 12.6 Storage abstraction (API)

```text
createPresignedPut(key, contentType, maxBytes, ttl)
getSignedGetUrl(key, ttl)
getPublicUrl(key)
put(key, bytes, contentType)
get(key)
delete(key)
exists(key)
copy(srcKey, dstKey)
```

R2 is the implementation; the interface stays provider-neutral.

## 12.7 CORS

- `media-private`: allow `PUT` from `admin.<domain>` and `app.<domain>`; allow `GET` from `app.<domain>` (web image loading).
- `media-public`: allow `GET` from any origin.

## 12.8 Student quotas

50 decks, 5,000 cards, 300 images per student. Enforced when issuing presigned URLs (`QUOTA_EXCEEDED`).

---

# 13. Flashcards

## 13.1 Official decks and cards

```text
flashcard_decks: id, subject_id, teacher_track_id?, unit_id?, lesson_id?, title_ar, description?,
                 cover_media_id?, is_free, free_source, status enum('draft','published','archived'),
                 sort_order, content_version int NOT NULL default 1,
                 created_at, updated_at, deleted_at?

flashcards: id, deck_id, front_media_id, back_media_id, sort_order, status,
            content_version int NOT NULL default 1,
            created_at, updated_at, deleted_at?
```

Official cards are front image + back image.

## 13.2 Two modes

Every deck (official or student-owned) offers:

| Mode | Arabic | Behaviour |
|---|---|---|
| Browse | تصفح | Flip, السابق / التالي, no scheduling, no rating |
| Study | مراجعة | Spaced repetition queue, rating buttons, undo |

A global "كل البطاقات المستحقة" study session combines due cards across all accessible decks (filterable by subject).

## 13.3 Study screen

```text
┌─────────────────────────────┐
│          Front              │   tap / "اقلب البطاقة" → flip animation
└─────────────────────────────┘
after flip:
 [ مرة أخرى ]   [ جيد ]    [ سهل ]
   < 1 د        10 د       4 أيام      ← predicted next interval under each button
                  ↶ تراجع               ← undo last rating
 progress: جديدة 12 · تعلّم 3 · مراجعة 40
```

- "Previous" in Study mode = **undo last rating** (restores the previous card state; up to 10 undos per session).
- Web keyboard shortcuts: Space = flip, 1/2/3 = Again/Good/Easy, Z = undo; in Browse mode arrow keys navigate (RTL-aware).

## 13.4 Scheduling algorithm (SM-2 / Anki-style, three buttons)

**Defaults (constants in `packages/srs` and Dart; not user-editable in V1 except daily limits):**

```text
learningSteps        = [1 min, 10 min]
graduatingInterval   = 1 day
easyInterval         = 4 days
relearningSteps      = [10 min]
startingEase         = 2.50
minimumEase          = 1.30
easyBonus            = 1.30
lapseIntervalFactor  = 0.0     (new interval after a lapse = max(1 day, interval × factor) → 1 day)
maximumInterval      = 365 days
learnAheadLimit      = 20 min
dayStartsAt          = 04:00 Asia/Damascus (single business-day boundary; never device-local)
newCardsPerDay       = 20 (student setting 0–100)
maxReviewsPerDay     = 200 (student setting 50–1000)
```

**Card state:**

```text
state        enum('new','learning','review','relearning')
step         int            (index into learning/relearning steps)
due_at       timestamptz
interval_days numeric
ease         numeric
reps         int
lapses       int
last_reviewed_at timestamptz?
```

**Transitions:**

New / Learning:
- **Again** → `state=learning, step=0, due=now+1min`
- **Good** → if another learning step exists: `step+1, due=now+step duration`; else graduate: `state=review, interval=1d, due=start of day(today+1d)`
- **Easy** → graduate immediately: `state=review, interval=4d, due=start of day(today+4d)`

Review (let `late = max(0, days overdue)`):
- **Again** → `lapses+1, ease=max(1.30, ease−0.20), pendingInterval=max(1d, interval×0.0)=1d, state=relearning, step=0, due=now+10min`
- **Good** → `interval = min(365, max(interval+1, (interval + late/2) × ease))`, apply fuzz, `due = start of day(today+interval)`
- **Easy** → `interval = min(365, max(interval+1, (interval + late) × ease × 1.30))`, `ease += 0.15`, apply fuzz

Relearning:
- **Again** → `step=0, due=now+10min`
- **Good** → next relearning step, or finish: `state=review, interval=pendingInterval, due=start of day(today+interval)`
- **Easy** → finish immediately as above

**Fuzz (exact cross-language algorithm):** apply only when the pre-fuzz interval is ≥ 3 whole days.

```text
baseDays = floor(preFuzzIntervalDays + 0.5)       # positive half-up rounding
span     = max(1, floor(baseDays * 0.05 + 0.5))
seedText = "{stableCardId}:{reps + 1}:{rating}"   # rating = good|easy
digest   = SHA-256(UTF-8(seedText))
n        = first 4 digest bytes interpreted as unsigned big-endian uint32
bucket   = n % (2 * span + 1)
offset   = bucket - span
result   = clamp(baseDays + offset, 1, maximumInterval)
```

`stableCardId` is the official `flashcard_id` or private `user_card_id`. `reps` is incremented exactly once for every committed rating before the new state is persisted. Both Dart and TypeScript implementations must use this exact byte order, modulo rule, rounding rule, and fixture set. This avoids runtime RNG differences and keeps predicted interval labels identical across clients/server tests.

**Where fuzz applies:** fuzz is applied **only** to Review-state `Good` and `Easy` intervals. It is **not** applied to:
- learning steps (1 min, 10 min)
- graduation from Learning via `Good` (exactly 1 day)
- graduation from Learning via `Easy` (exactly 4 days)
- relearning steps
- completion of Relearning back to its `pendingInterval`

Therefore fixture `new card → Easy` must always produce exactly **4 days**, not a fuzzed value.

**Interval labels:** minutes → "د", hours → "س", days → "يوم/أيام", months → "شهر". Always show the predicted value for each button.

## 13.5 Queue building

**Study-day boundary:** SRS due-day calculations, `newCardsPerDay`, `maxReviewsPerDay`, daily goal/streak accounting, and daily aggregate statistics all use the same business day: **04:00 Asia/Damascus → next 04:00 Asia/Damascus**. Device timezone never changes the business day. `due_at` remains stored as UTC; clients convert the Damascus boundary to UTC when calculating offline.

1. Learning/relearning cards whose `due_at <= now` (earliest first)
2. Review cards due today, up to `maxReviewsPerDay` (random order)
3. New cards in deck order, up to `newCardsPerDay` (counted per day across all decks)
4. If nothing is due but a learning card is due within `learnAheadLimit`, show it early
5. Otherwise: "أنهيت مراجعة اليوم 🎉" with the next due time

Only cards the student can currently access enter the queue.

## 13.6 Where scheduling runs

- The algorithm runs **on the device** (Dart) so 1-minute steps work offline.
- Every rating writes a review log locally and queues it for sync.
- The server stores states and logs. Study data is not security-sensitive, so the server accepts client-computed states after schema validation.

## 13.7 SRS tables

```text
card_states: id, user_id, flashcard_id?, user_card_id?,
             state, step, due_at, interval_days, ease, reps, lapses,
             last_reviewed_at, updated_at,
             CHECK (exactly one of flashcard_id, user_card_id),
             UNIQUE(user_id, flashcard_id), UNIQUE(user_id, user_card_id)

review_logs: id (client UUID, idempotency key), user_id, flashcard_id?, user_card_id?,
             rating enum('again','good','easy'),
             state_before jsonb, state_after jsonb,
             reviewed_at, duration_ms, undone boolean default false,
             device_platform, created_at
```

## 13.8 Sync

- `POST /api/v1/srs/sync` with pending review logs (batched, idempotent by log id) and current states.
- Server applies each card state if its `last_reviewed_at` is newer than the stored one (last review wins).
- Undo marks the log `undone=true` and restores `state_before`.
- `GET /api/v1/srs/states?since=<cursor>` returns states changed on other devices.
- When an entitlement expires, card states and logs are kept; cards leave the queue until access returns.

## 13.9 Student-created decks (private)

```text
user_decks: id (client UUID), user_id, name, subject_id? (optional tag), color?,
            sort_order, created_at, updated_at, deleted_at?

user_cards: id (client UUID), deck_id, user_id,
            kind enum('custom','official_ref'),
            front_text?, back_text?, front_media_id?, back_media_id?,
            official_flashcard_id?,
            sort_order, created_at, updated_at, deleted_at?
```

- Custom cards: front and back each have text (max 1,000 characters, RTL, plain text with line breaks) and/or one image.
- "أضف إلى بطاقاتي" on an official card creates an `official_ref` card that renders the official images; it is available only while the student can access the source card.
- Created and edited offline; synced with last-write-wins on `updated_at`.
- Decks are **private**: no sharing, publishing, or discovery in V1.
- Student decks support Browse and Study modes identically.
- Quotas in §12.8.

---

# 14. Questions

## 14.1 Types

1. MCQ (single correct option)
2. True/False (reuses MCQ infrastructure with fixed options صح / خطأ)
3. Written short answer

## 14.2 Tables

```text
questions: id, type enum('mcq','true_false','written'),
           subject_id, teacher_track_id?, unit_id?, lesson_id?,
           question_text, explanation?, difficulty?,
           is_free, free_source, status enum('draft','published','archived'),
           sort_order, content_version int NOT NULL default 1,
           created_by_admin_id, updated_by_admin_id,
           created_at, updated_at, deleted_at?

question_options: id, question_id, text, is_correct, sort_order

question_answers: id, question_id, answer_original, answer_normalized,
                  normalization_version, is_active, created_at
```

## 14.3 Answer protection

- Online content responses never include `is_correct` or accepted answers before the server grades the student's answer.
- **Exception:** offline packs (§22) include answers for questions the student is allowed to access (free or entitled), encrypted at rest and bound to an offline license.
- The server is the authority: answers graded locally from packs are re-graded by the server on sync.

## 14.4 Arabic normalization (version 1)

Applied server-side only (`packages/arabic-normalizer`), in this order:

1. Unicode NFKC (also folds Arabic presentation forms)
2. Remove tatweel `ـ` (U+0640)
3. Remove diacritics U+064B–U+0652 and superscript alef U+0670
4. Alef forms `أ إ آ ٱ` → `ا`
5. `ى` → `ي`
6. Arabic-Indic digits `٠–٩` and Persian digits `۰–۹` → `0–9`; Arabic decimal separator `٫` → `.`
7. Latin letters → lowercase
8. Punctuation `. , ، ؛ ; : ! ? ؟ " ' « » ( ) - _ /` → space, **except** `.` or `,` between two digits (kept as decimal separator; `,` → `.`)
9. Collapse whitespace; trim

Not normalized (admins add variants explicitly): `ة/ه`, `ؤ/ئ/ء`, synonyms.

Matching: correct if the normalized input equals any active accepted answer's `answer_normalized`. No partial credit.

## 14.5 Normalization versioning

`normalization_version` stored per accepted answer. When rules change: bump version, regenerate `answer_normalized` from originals via migration job, run regression fixtures. Never leave stale values.

## 14.6 Attempt snapshots

Each graded answer stores a JSONB snapshot of the question text, options (with the correct one), and explanation as shown, so later edits never change the student's history.

---

# 15. Quizzes, Practice and Exams

## 15.1 Quiz definition

```text
quizzes: id, title_ar, subject_id, teacher_track_id?, unit_id?, lesson_id?,
         allowed_modes enum('practice','exam','both') default 'both',
         time_limit_seconds? (exam mode only),
         shuffle_questions, shuffle_options, passing_score_percent?,
         max_attempts?, is_mock_exam boolean,
         allow_offline boolean NOT NULL default true,
         is_free, free_source, status, sort_order,
         content_version int NOT NULL default 1,
         created_at, updated_at, deleted_at?

quiz_questions: quiz_id, question_id, sort_order
```

Admins can force exam-only (`allowed_modes='exam'`), e.g., for mock exams.

### 15.1.1 Quiz-question scope invariant

Every question added to a curated quiz must have the **same access scope** as the quiz:

```text
question.subject_id == quiz.subject_id
AND
question.teacher_track_id IS NOT DISTINCT FROM quiz.teacher_track_id
```

This means:
- general-subject quiz → only general-subject questions from that same subject
- teacher-track quiz → only questions from that exact teacher track
- cross-scope curated quizzes are not allowed in V1

Enforce this in the service on add/import/reorder and re-validate the entire quiz before publish. Return `VALIDATION_ERROR` rather than silently including a question that would later appear locked. The unit/lesson integrity rules in §6.1 apply independently.

## 15.2 Student-chosen mode

When starting a quiz (if `allowed_modes='both'`), the student chooses:

**وضع التدريب — Practice**
- Answer → tap **تحقق** → server grades → shows correct/incorrect, correct answer, explanation → **التالي**.
- An answer cannot be changed after checking.
- Grading: local and instant if the question is in a downloaded offline pack (§22); otherwise a server check (requires connection). The server re-grades locally graded answers on sync.

**وضع الامتحان — Exam**
- No feedback until the end.
- Question grid to jump between questions; flag questions (علّم للمراجعة); answers can be changed until submission.
- Review screen before **إنهاء الامتحان** (shows unanswered and flagged).
- Optional timer (server-authoritative `deadline_at`).
- Answers are autosaved locally (Drift) and to the server when online. **The exam continues through connection drops**; submission is sent when the connection returns.

## 15.3 Other practice sources

Same attempt machinery with `source`:

- `curated` — admin quiz
- `random` — "20 random questions, Grade 12 Physics, Unit 2, types X" (server selects from accessible, published questions)
- `mistakes` — from the student's mistake bank (§16)

## 15.4 Attempt tables

```text
quiz_attempts: id, client_attempt_id (unique, idempotency), user_id, quiz_id?,
               source enum('curated','random','mistakes'),
               mode enum('practice','exam'),
               filters jsonb?,                       -- for random/mistakes
               question_order jsonb, option_orders jsonb,
               status enum('in_progress','submitted','abandoned'),
               started_at, deadline_at?, submitted_at?, submitted_late boolean default false,
               score_percent?, correct_count?, total_count, time_spent_ms?

quiz_attempt_answers: id, attempt_id, question_id,
                      selected_option_id?, written_answer?,
                      is_correct?, graded_at?, flagged boolean,
                      answered_at?, time_spent_ms?,
                      question_snapshot jsonb?,
                      UNIQUE(attempt_id, question_id)
```

## 15.5 Grading rules

- Practice: `POST /attempts/{id}/answers/{questionId}/check` grades one answer and returns correctness, correct option/answer, explanation.
- Exam: `PUT /attempts/{id}/answers/{questionId}` saves without grading; `POST /attempts/{id}/submit` grades all and returns results.
- Timed exams: submissions received after `deadline_at + 2 minutes` are graded but marked `submitted_late=true` and shown to the student as "تم التسليم بعد انتهاء الوقت". No penalty in V1.
- Submission is idempotent; repeat submissions return the same result (`ATTEMPT_ALREADY_SUBMITTED` only if answers differ).
- Unfinished attempts can be resumed ("متابعة الاختبار"). Attempts inactive for 7 days become `abandoned`.

## 15.6 Results screen

Score, correct/incorrect/skipped counts, time taken, pass/fail if a passing score exists, then every question with the student's answer, the correct answer, and the explanation. Filters: الكل / الخاطئة / المتروكة / المعلّمة. Buttons: "أعد الأخطاء فقط", "أعد الاختبار".

---

# 16. Mistake Bank and Statistics

## 16.1 Mistake bank (مراجعة الأخطاء)

```text
user_mistakes: user_id, question_id, first_wrong_at, last_wrong_at, wrong_count,
               correct_streak, status enum('active','mastered','removed'), updated_at,
               PRIMARY KEY(user_id, question_id)
```

- A wrong graded answer → status `active`, `correct_streak=0`, `wrong_count+1`.
- A correct graded answer on an active mistake → `correct_streak+1`; at **2** (config `mistakeMasteryStreak`) → `mastered`.
- Student can remove manually (`removed`); a new wrong answer re-activates it.
- Screen: list grouped by subject/unit, filters (subject, unit, lesson, teacher track, type), "اختبر أخطائي" (starts a `mistakes` attempt, choose count and mode), link to the related lesson/unit.
- Questions the student can no longer access are hidden (not deleted).

## 16.2 Statistics (إحصائياتي)

Endpoints: `/stats/overview`, `/stats/subjects/{id}`, `/stats/trend?weeks=12`, `/stats/flashcards`.

- Overall: questions answered, accuracy %, quizzes completed, study days, current streak
- Accuracy by subject → unit → lesson, by teacher track, by question type
- Weekly accuracy trend (last 12 weeks)
- Weakest units (lowest accuracy with ≥ 10 answers)
- Most-missed questions
- Average time per question
- Mistake bank: active vs mastered counts
- Flashcards: due today, 7-day due forecast, reviews per day, retention rate (share of review-state ratings that were not Again, last 30 days), cards by state

Implementation: summary table `user_subject_stats(user_id, subject_id, teacher_track_id?, answered, correct, time_ms, updated_at)` updated inside the grading transaction; trends computed from indexed attempt answers. Target p95 ≤ 500 ms.

---

# 17. Bookmarks (المحفوظات)

```text
bookmarks: id, user_id, item_type enum('question','flashcard','user_card','deck'), item_id, created_at,
           UNIQUE(user_id, item_type, item_id)
```

Locked bookmarked items show as locked.

---

# 18. Progress

Tracked per subject, unit, lesson, and teacher track: questions attempted/correct, quizzes completed, flashcards studied, completion % (= distinct accessible published items interacted with / total accessible published items), last activity. "متابعة التعلم" on home resumes the last activity.

---

# 19. Home, Banners, Exam Countdown, Goals

## 19.1 Home sections

```text
Header (greeting, notifications bell)
Exam countdown
Banner slider
Today: due flashcards count + daily goal progress + streak
Continue learning
My subjects / my teacher tracks
Free content
Teachers I follow
Mistake review shortcut
```

## 19.2 Banners

Upload, replace, activate/deactivate, reorder, schedule (start/end), target level, click action: `subject | teacher | teacher_track | quiz | deck | internal_route | external_url | none`. Changes never need an app update.

## 19.3 Exam countdown

```text
exam_countdowns: id, education_level_id, title_ar, exam_date, is_active
```

Shows "باقي 87 يوماً على امتحان الشهادة الثانوية" for the student's profile level.

## 19.4 Daily goal and streak

- Student sets a daily goal (default 20 items = flashcard ratings + graded answers).
- A day counts toward the streak when the goal is met. Day boundary: **04:00 Asia/Damascus**, exactly the same boundary used by SRS due days, daily card limits, and daily statistics (§13.5).
- No XP, points, or leaderboards.

```text
user_daily_activity: user_id, day, items_done, goal, goal_met, PRIMARY KEY(user_id, day)
```

---

# 20. Notifications

## 20.1 Types and targets

Types: new content, teacher updates, due-flashcard reminders, study reminders, announcements, promotions.

Targets: all students, level, subject entitlement holders, teacher track entitlement holders, teacher followers, specific students.

## 20.2 Consent

- Categories in settings: التعلّم (content + reminders, default on), العروض (promotions, **default off**, explicit opt-in).
- Promotions are never pushed to students who have not opted in.

## 20.3 Delivery

- Every notification is stored in the in-app inbox (`notifications`, `user_notifications` with read state).
- Push via FCM is sent in addition when a token exists; failures are logged, not retried indefinitely.
- Fan-out runs as a pg-boss job in batches.
- Due-card reminder: daily job at the student's chosen time (default 18:00 Damascus) if they have due cards: "لديك 35 بطاقة للمراجعة اليوم".

```text
push_tokens: id, user_id, platform, token, app_version, created_at, last_seen_at, revoked_at?
```

---

# 21. Content Problem Reports (إبلاغ عن مشكلة)

Students can report a problem on any question or official flashcard.

```text
content_reports: id, user_id, item_type enum('question','flashcard'), item_id,
                 reason enum('wrong_answer','typo','unclear','image_problem','other'),
                 note? (≤ 500 chars),
                 status enum('open','resolved','dismissed'),
                 resolved_by_admin_id?, resolution_note?, created_at, resolved_at?
```

Rate limit: 20 reports/day per student. Admin inbox with filters, jump-to-edit, and resolve/dismiss. Optional notification to the student when resolved.

---

# 22. Offline Mode (Offline Packs)

Offline use is a first-class feature on **Android and iOS**. Content is made available offline through explicitly downloaded **offline packs**, protected by encryption at rest and a time-limited offline license. This section overrides any conflicting online-only statement elsewhere for content inside a downloaded pack.

## 22.1 What can be downloaded

| Pack level | Button | Contents |
|---|---|---|
| Deck | "تحميل البطاقات" on the deck page | One flashcard deck: card metadata + front/back images |
| Unit | "تحميل الوحدة" on the unit page | All accessible decks, questions, and quizzes of that unit |
| Subject / teacher track | "تحميل الكل" on the subject or track page | Everything accessible in that scope, split into unit packs internally |

- Question content in a pack includes: question text, options with correctness, accepted answers (original + normalized + `normalization_version`), explanations, and quiz definitions.
- Free content can be downloaded by anyone; premium content only by students with an active entitlement for its scope.
- Student-created decks are always available offline (§13.9) and are not packs.
- Each quiz has `allow_offline boolean NOT NULL default true` in §15.1. When an admin enables `is_mock_exam=true`, the UI defaults `allow_offline=false` unless explicitly overridden before publish. A quiz with `allow_offline=false` can still be **taken** offline once started (Exam mode grades at the end), but its answers are never included in packs.

## 22.2 When downloads happen

- **After a successful coupon redemption:** a sheet appears — "تم تفعيل المادة ✓ هل تريد تحميلها لاستخدامها دون اتصال؟ الحجم التقريبي: 180 ميغابايت" with [تحميل الآن] [عبر Wi-Fi فقط] [لاحقاً].
- **Manually at any time:** deck, unit, and subject/track download buttons always show the size before downloading.
- **Never silently:** full subjects are never auto-downloaded without the student's choice (bandwidth and storage in Syria are limited).
- **Settings:**
  - "التحميل عبر Wi-Fi فقط" (default on)
  - "تحديث المحتوى المحمّل تلقائياً" (default on)
  - "المساحة المستخدمة" screen listing packs with size, last update, and delete buttons
- Downloads are resumable, run in the background, show progress, and can be paused or cancelled.
- Warn before downloading if free device space is below pack size + 500 MB.

## 22.3 Updates

- `questions`, `flashcard_decks`, `flashcards`, and `quizzes` each have `content_version int NOT NULL default 1`.
- Editing a question **or any of its options/accepted answers/explanation** bumps `questions.content_version`; option/answer rows do not need their own version column.
- Editing deck metadata, deck membership, or deck ordering bumps `flashcard_decks.content_version`. Editing a card's images/order/status bumps `flashcards.content_version`.
- Editing quiz metadata, `allow_offline`, question membership, or quiz question order bumps `quizzes.content_version`.
- The pack manifest lists item IDs and versions. The client downloads only new or changed items and removes deleted or archived ones (delta sync).
- Packs show "تحديث متاح" when the server manifest is newer; auto-update runs when allowed by the settings above.
- Learning history is never deleted when content is updated or removed.

## 22.4 Offline license (lease)

- Premium content in packs is usable only while the device holds a valid **offline license** for its scope.
- `lease_expires_at = min(now + 30 days, entitlement expires_at)`. The license refreshes automatically whenever the app is online (at most once per day per scope).
- After the lease expires, premium pack content is hidden until the device goes online and refreshes. Free packs have no lease.
- Clock protection: the app stores the last known server time; if device time is earlier than that, the lease is treated as expired until the next online check.
- If the entitlement was revoked or expired, the next check deletes that scope's premium pack data from the device.

```text
offline_leases: id, user_id, session_id, scope_type, subject_id?, teacher_track_id?,
                issued_at, expires_at, revoked_at?
```

## 22.5 Encryption at rest

- The local database (Drift) uses SQLCipher. The database key is generated on the device and stored in Keychain (iOS) / Keystore (Android) via flutter_secure_storage.
- Downloaded pack images are stored in the app's private directory, encrypted with AES-GCM using a key derived from the same secret.
- Logging out or deleting the account wipes the local database, keys, and pack files.
- This raises the cost of extracting premium content and answers but cannot stop a determined user on a rooted or jailbroken device. This is an accepted trade-off.

## 22.6 Offline grading and sync

- **Practice mode:** if the question is in a downloaded pack, grading is local and instant (online or offline). Otherwise the server checks the answer (requires connection).
- **Exam mode:** graded locally at submission when all questions are in packs; otherwise graded by the server when the submission reaches it.
- **Written answers:** graded locally with a Dart port of the Arabic normalizer. The Dart and TypeScript normalizers must pass the same fixtures in `packages/arabic-normalizer/fixtures`. If a pack's `normalization_version` differs from the app's normalizer version, the pack is marked for update and those questions fall back to server grading.
- **Random practice offline:** built locally from downloaded, accessible questions.
- **Mistake bank offline:** a local mirror is updated immediately and reconciled on sync.
- **Sync:** offline attempts and answers are uploaded with client UUIDs (idempotent). The **server re-grades every synced answer**; the server result is authoritative for stats, mistakes, progress, and streaks. Local/server mismatches are logged for admin review (signals version drift or tampering).
- **Statistics offline:** the app shows a local approximation, replaced by server figures after sync.

## 22.7 Still requires a connection

Login, registration, OTP, coupon redemption (never queued), entitlement changes, first download and license refresh of packs, profile/account changes, notifications fetch. Content reports are queued offline and sent later.

## 22.8 Web

Offline packs are **not** available on web in V1 (browser storage quotas and no secure key storage). Web keeps: SRS states and review logs, student decks, and in-progress exam answers stored locally and synced. Offline packs on web are a V2 candidate.

## 22.9 Caching outside packs

- Flashcard viewing prefetches the next 3 images and keeps the previous card cached.
- Subject metadata, banners, home data, and recent results are cached for fast startup and read-only offline display.

## 22.10 API

```text
GET  /offline/catalog                         downloadable packs for accessible scopes, with sizes and versions
GET  /offline/packs/{packKey}/manifest        item IDs + content_version (+ since=<version> for deltas)
GET  /offline/packs/{packKey}/items?cursor=   JSON item chunks; image entries carry signed URLs (1 h)
POST /offline/licenses/refresh                returns leases for all scopes held on this device
POST /offline/sync                            offline attempts, answers, mistakes; server re-grades
```

Pack keys: `{scope_type}:{scope_id}:{unit_id|all}:{kind}`.

## 22.11 Tests

| Case | Expected |
|---|---|
| Download deck, go offline, Browse + Study | works; reviews sync later |
| Download unit, go offline, Practice mode | instant local grading; server re-grade matches on sync |
| Written answer offline with Alef/diacritics/digits variants | same result as server |
| Lease expired (30 days offline) | premium pack hidden; free packs still work |
| Device clock set backwards | lease treated as expired |
| Entitlement revoked, device comes online | premium pack data deleted |
| Admin edits a question | pack shows update; delta downloads only that item |
| Same offline attempt synced twice | one attempt stored |
| Mock exam (`allow_offline=false`) | answers absent from packs; exam still submittable after reconnect |
| Logout | local DB, keys, and pack files wiped |

## 22.12 Phase

Offline packs are built as dedicated **Phase 9 — Offline Packs**, after Student Content and before Home & Communication. Earlier phases must already include `content_version`, Drift + SQLCipher foundations, SRS local state, idempotent attempt IDs, and the storage abstractions required by this phase. Phase 6 does **not** implement offline-pack download itself.

---

# 23. Student App Navigation and Screens

## 23.1 Bottom navigation (side rail on wide web screens)

```text
الرئيسية | المواد | المراجعة | المحفوظات | حسابي
```

"المراجعة" contains: due flashcards, my decks, mistake bank, statistics.

## 23.2 Screens

1. Splash / force-update
2. Onboarding (optional)
3. Login
4. Register
5. Email OTP verification
6. Forgot password / reset (OTP)
7. Select education level
8. Home
9. Levels & subjects browser (all levels)
10. Subject details (general content + teacher tracks)
11. Units / lessons
12. Teachers list, teacher profile, teacher track page
13. Followed teachers
14. Deck details (Browse / Study / download for offline / add to my deck)
15. Flashcard Browse
16. Flashcard Study (SRS)
17. Study session complete
18. My decks, deck editor, card editor
19. Quiz details (mode selection, accessible count)
20. Practice mode
21. Exam mode (+ question grid + review before submit)
22. Results
23. Random practice builder
24. Mistake bank
25. Statistics
26. Bookmarks
27. Coupon redemption (only if `COUPON_REDEMPTION=true`)
28. My access (active/expired entitlements)
29. Notifications inbox
30. Profile
31. Settings (level, daily goal, SRS limits, notification categories, reminder time, dark mode, font size)
32. Sessions
33. Report a problem sheet
34. Privacy policy / terms / support
35. Delete account

---

# 24. Student Web (Flutter Web)

- Same codebase and features as mobile, built with `flutter build web`, hosted on Cloudflare Pages at `app.<domain>`.
- Arabic font bundled locally (no external font CDN).
- Path URL strategy with deep links for subjects, decks, quizzes, teacher pages.
- Responsive: phone layout below 600 px; above that, side navigation rail and max content width 720 px for study/quiz screens, multi-column grids for lists.
- Auth via httpOnly cookies (§11.2); no tokens in browser storage.
- Offline data via Drift (SQLite WASM). If the browser lacks required storage support, the app works online-only and shows a notice.
- Push via FCM web push where supported (on iOS Safari only when installed to the home screen). The inbox covers the rest.
- Student web uses the same Email + Password + OTP flow as mobile. No social-login providers are configured in V1.
- `COUPON_REDEMPTION=true` on web.
- PWA manifest and service worker are included; install prompts disabled until Plan B.
- Keyboard shortcuts (§13.3).
- No public SEO pages in V1 (content is behind login).

---

# 25. Arabic RTL Requirements

- All student and admin UI in Arabic, RTL, with Arabic validation, errors, and empty states.
- Correct directional icons and RTL page transitions.
- LTR rendering for email addresses, URLs, coupon codes, technical IDs, and numbers in formulas.
- Numbers displayed with Western digits (0–9) by default.
- Dark mode and adjustable font size (3 steps) with centralized theme tokens.

---

# 26. Admin Dashboard

## 26.1 Navigation

```text
الرئيسية
المشرفون
الطلاب
المدرسون
المسارات (مسارات المدرسين)
المراحل التعليمية
الجامعات · الكليات · السنوات الدراسية
المواد · الوحدات · الدروس
الأسئلة
البطاقات التعليمية
الاختبارات
قواعد المحتوى المجاني
العروض المؤقتة
الكوبونات · دفعات الكوبونات
صلاحيات الوصول
الإعلانات (البانرات)
العد التنازلي للامتحانات
الإشعارات
البلاغات
تحليلات الأسئلة
الاستيراد والتصدير
سجل العمليات
الإعدادات
```

## 26.2 Capabilities

- Admins: create, deactivate, reactivate; 2FA reset by another admin (audited).
- Students: search, view profile, entitlements, attempts summary, sessions; grant/extend/revoke entitlements; revoke sessions.
- Teachers and teacher tracks: CRUD, photos, subject assignment, visibility, follower counts, notify followers/track holders.
- Education structure: full CRUD with ordering.
- Content: questions (all types, accepted answers with normalized preview), flashcard decks and bulk upload, quizzes (modes, timer, mock exam flag).
- Access: free rules with preview, manual free overrides, promotions, coupon batches (generate, export, revoke), entitlements.
- Communications: banners, exam countdowns, notifications with targeting preview (recipient count).
- Reports inbox.
- Question analytics: attempts, % correct, option distribution, average time, open reports. Auto-flag a question for review when it has ≥ 30 attempts and either < 20% correct or a wrong option chosen more often than the correct one.
- Import/export, audit log, settings (config values from §10.2, `allowTemporaryToPermanentUpgrade` default **true**, `mistakeMasteryStreak`).
- Global admin search: admins, students, teachers, tracks, subjects, questions, coupons (by last 4 or full code), batches.

---

# 27. Bulk Import / Export

Formats: CSV and XLSX. Rows reference entities by **code/slug**, never by display name.

## MCQ

```text
education_level_code, subject_code, unit_code, lesson_code, teacher_track_code,
question, option_a, option_b, option_c, option_d, correct_option (a|b|c|d),
explanation, difficulty, is_free_override (blank|true|false)
```

## Written

```text
education_level_code, subject_code, unit_code, lesson_code, teacher_track_code,
question, accepted_answer_1 … accepted_answer_5, explanation, difficulty, is_free_override
```

## True/False

```text
education_level_code, subject_code, unit_code, lesson_code, teacher_track_code,
question, correct_answer (صح|خطأ|true|false), explanation, difficulty, is_free_override
```

`is_free_override` blank = use the scope's free rule.

Flow (runs as a job): upload → parse → validate every row → preview with per-row errors → confirm → single transactional import → summary. Stored in `import_jobs` / `import_errors`. Downloadable templates and export of existing content in the same formats.

Flashcard bulk upload: select files (or ZIP) named `001-front.png`, `001-back.png`, …; auto-pair by prefix; manual correction grid; assign scope, deck, order, free override; upload via presigned URLs; process as a job.

---

# 28. Database Entities

```text
-- identity / auth
users, profiles, accounts (Better Auth credential account), sessions, verification_codes,
mobile_refresh_tokens, admin_two_factor

-- structure
education_levels, universities, faculties, academic_years, subjects, units, lessons

-- teachers
teachers, teacher_tracks, teacher_followers

-- content
questions, question_options, question_answers,
flashcard_decks, flashcards,
quizzes, quiz_questions

-- student content
user_decks, user_cards

-- learning
card_states, review_logs,
quiz_attempts, quiz_attempt_answers,
user_mistakes, user_subject_stats, user_progress, user_daily_activity,
bookmarks

-- access
free_access_rules, promotions, entitlements,
coupon_batches, coupons, coupon_redemptions, coupon_redemption_failures,
offline_leases

-- communication
banners, exam_countdowns, notifications, user_notifications, push_tokens,
notification_preferences

-- operations
media_files, content_reports, question_stats,
import_jobs, import_errors, audit_logs, app_settings
```

There are no teacher authentication tables. `roles` / `user_roles` are intentionally removed: V1 stores `users.role enum('student','admin')`; future admin sub-roles can extend that field or add RBAC later. `teacher_subjects` is intentionally removed because teacher↔subject association is already represented by `teacher_tracks(subject_id)` and duplicating it would create two sources of truth.

### 28.1 Tables that need explicit definitions

Better Auth owns the exact physical columns of `users`, `accounts`, `sessions`, and `verification_codes`; in V1 `accounts` is credential/email-password only (no Google/Apple providers). Migrations generated for the selected Better Auth version are authoritative. Add the application fields/relations below without replacing Better Auth's required columns.

```text
users:
  Better Auth user fields
  role enum('student','admin') NOT NULL default 'student'
  status enum('active','disabled') NOT NULL default 'active'

mobile_refresh_tokens:
  id UUID PK
  user_id FK users
  session_family_id UUID NOT NULL
  token_hash bytea UNIQUE NOT NULL
  previous_token_hash bytea?
  retry_grace_expires_at timestamptz?
  expires_at timestamptz NOT NULL
  revoked_at timestamptz?
  replaced_by_id UUID?
  created_at
  last_used_at?
  -- raw refresh tokens are never stored

profiles:
  user_id PK/FK users
  full_name
  education_level_id?
  university_id?
  faculty_id?
  academic_year_id?
  avatar_media_id?
  daily_goal int NOT NULL default 20
  created_at, updated_at

user_progress:
  id
  user_id
  subject_id
  teacher_track_id?
  unit_id?
  lesson_id?
  last_activity_type
  last_item_id?
  last_activity_at
  updated_at
  -- stores resume/progress pointers; completion percentages may be derived from
  -- attempts/reviews + current accessible-content counts rather than trusted as authority

question_stats:
  question_id PK/FK questions
  attempt_count
  correct_count
  total_time_ms
  option_distribution jsonb
  flagged_for_review boolean default false
  last_attempt_at?
  updated_at

notification_preferences:
  user_id PK/FK users
  learning_enabled boolean default true
  promotions_enabled boolean default false
  due_reminders_enabled boolean default true
  reminder_time time default '18:00'
  reminder_timezone text NOT NULL default 'Asia/Damascus'
  updated_at
  -- reminder_timezone affects notification delivery time only.
  -- It NEVER changes the 04:00 Asia/Damascus SRS/streak/business-day boundary.

app_settings:
  key text PK
  value jsonb NOT NULL
  updated_by_admin_id?
  updated_at
```

`offline_leases` is defined in §22.4 and is part of the access schema.

`user_subject_stats` is defined in §16.2. `question_stats` is the question-level aggregate used by Admin analytics; update it in the same grading transaction (or via an idempotent job if the grading path becomes too heavy).

---

# 29. Indexes (minimum)

```text
questions(subject_id, teacher_track_id, status, sort_order)
questions(unit_id), questions(lesson_id)
flashcard_decks(subject_id, teacher_track_id), flashcards(deck_id, sort_order)
quizzes(subject_id, teacher_track_id)
entitlements(user_id, scope_type, subject_id, teacher_track_id, status)
entitlements(expires_at)
UNIQUE entitlements(user_id, subject_id) WHERE status='active' AND scope_type='subject'
UNIQUE entitlements(user_id, teacher_track_id) WHERE status='active' AND scope_type='teacher_track'
coupons(code_hash) UNIQUE, coupons(batch_id), coupons(code_last4)
coupon_redemptions(user_id), coupon_redemption_failures(user_id, created_at)
card_states(user_id, due_at)
review_logs(user_id, reviewed_at)
quiz_attempts(user_id, started_at), quiz_attempt_answers(attempt_id)
quiz_attempt_answers(question_id)
user_mistakes(user_id, status)
teacher_followers(user_id), teacher_followers(teacher_id)
user_notifications(user_id, read_at)
push_tokens(user_id), sessions(user_id)
content_reports(status, created_at)
audit_logs(actor_admin_id, created_at), audit_logs(resource_type, resource_id)
```

---

# 30. API

## 30.1 Conventions

- Base path `/api/v1`; OpenAPI generated from Zod; Dart and TS clients generated in CI.
- Cursor pagination for lists (`?cursor=&limit=`).
- Idempotency keys for all offline-capable writes.
- Every response carries `X-Request-Id`.

## 30.2 Endpoint groups (student)

```text
/auth/*                 register, login, OTP verify, password reset, google, apple, refresh, logout
/config                 remote config + versions
/me                     profile, level, settings, delete account
/sessions               list, revoke
/levels, /subjects, /units, /lessons
/teachers, /teacher-tracks, /teachers/{id}/follow
/decks, /decks/{id}/cards (signed URLs), /srs/sync, /srs/states
/my-decks, /my-decks/{id}/cards
/uploads, /uploads/{id}/complete
/quizzes, /attempts, /attempts/{id}/answers/{qid}, /attempts/{id}/answers/{qid}/check, /attempts/{id}/submit
/practice/random (creates attempt)
/mistakes, /mistakes/{questionId} (remove)
/stats/*
/bookmarks
/progress
/coupons/redeem
/access (my entitlements)
/home
/notifications, /notifications/preferences, /push-tokens
/reports
```

Admin endpoints under `/api/v1/admin/*`, all requiring `requireAdmin()` with a 2FA-verified session.

## 30.3 Response shape

```json
{ "success": true, "data": {}, "error": null }
```

```json
{ "success": false, "data": null,
  "error": { "code": "COUPON_ALREADY_USED", "message": "تم استخدام هذا الكود مسبقاً" } }
```

## 30.4 Error codes

| Code | Arabic message |
|---|---|
| AUTH_INVALID_CREDENTIALS | بيانات الدخول غير صحيحة |
| AUTH_EMAIL_NOT_VERIFIED | البريد الإلكتروني غير مُفعّل |
| AUTH_OTP_INVALID | رمز التحقق غير صحيح أو منتهي |
| AUTH_2FA_REQUIRED | مطلوب رمز التحقق الثنائي |
| APP_UPDATE_REQUIRED | يرجى تحديث التطبيق للمتابعة |
| COUPON_NOT_FOUND | كود التفعيل غير موجود |
| COUPON_ALREADY_USED | تم استخدام هذا الكود مسبقاً |
| COUPON_EXPIRED | انتهت صلاحية هذا الكود |
| COUPON_REVOKED | هذا الكود لم يعد صالحاً |
| COUPON_NOT_ELIGIBLE | هذا الكود لا يناسب حسابك (reserved) |
| ALREADY_ENTITLED | لديك وصول مفعّل لهذا المحتوى مسبقاً |
| ENTITLEMENT_EXPIRED | انتهت صلاحية وصولك لهذا المحتوى |
| CONTENT_LOCKED | هذا المحتوى غير متاح على حسابك |
| ATTEMPT_ALREADY_SUBMITTED | تم تسليم هذا الاختبار مسبقاً |
| QUOTA_EXCEEDED | وصلت إلى الحد الأقصى المسموح |
| RATE_LIMITED | محاولات كثيرة، حاول لاحقاً |
| VALIDATION_ERROR | البيانات المدخلة غير صحيحة |
| NOT_FOUND | العنصر غير موجود |
| NOT_AUTHORIZED | لا تملك صلاحية لهذا الإجراء |
| SERVER_ERROR | حدث خطأ، حاول لاحقاً |

---

# 31. Security

- Never trust client input; validate everything with Zod.
- Server verifies identity, admin role + 2FA, ownership, access, coupon validity, free status, quotas.
- HTTPS only; HSTS on all domains.
- No secrets in Flutter (web or mobile); only public config.
- Passwords hashed with a modern algorithm (per Better Auth defaults: scrypt/argon2).
- Rate limits: login 10 / 15 min per IP+email; OTP requests 5 / hour per email; coupon limits §9.5; reports §21; uploads 60 / hour per student.
- R2 private bucket never public; signed URLs only for accessible items.
- CSRF defenses for cookie sessions (§11.2); strict CORS allowlist (`app.`, `admin.` origins).
- IP addresses stored hashed where only needed for abuse detection.
- Row-Level Security is optional defense-in-depth and must not become a second source of authorization truth.

---

# 32. Audit Logging

```text
audit_logs: id, actor_admin_id, action, resource_type, resource_id, metadata jsonb, ip_hash, created_at
```

Log at least: admin created/deactivated/reactivated, 2FA reset, teacher/track created/archived, content deleted/archived, free rule changed (with preview counts), promotion created, coupon batch generated/exported/revoked, entitlement granted/extended/revoked, import completed, notification sent, settings changed, report resolved.

---

# 33. Soft Delete and Data Lifecycle

- Soft delete (`deleted_at`) for teachers, tracks, subjects, units, lessons, questions, decks, cards, quizzes, coupons, user decks/cards.
- Never destroy student learning history because content was archived.

On account deletion:

- Delete/anonymize PII (name, email, avatar, provider links)
- Revoke sessions, delete push tokens
- Revoke entitlements
- Delete bookmarks, student decks/cards and their media
- Anonymize attempts, review logs, stats (keep for aggregate question analytics with `user_id` set to null)
- Keep coupon redemptions with `user_id` nulled so codes stay consumed

The final retention policy must be written in the privacy policy before launch.

---

# 34. Performance

## 34.1 API targets (nominal load, ~1,000 users)

- Home p95 ≤ 500 ms
- Deck page / card batch p95 ≤ 400 ms
- Grading (check/submit) p95 ≤ 500 ms
- Stats p95 ≤ 500 ms

## 34.2 App

- Lazy loading and pagination everywhere; never load whole subjects.
- Prefetch next 3 flashcard images; cache by media ID.
- Image budgets §12.4.
- Android APK/AAB size target ≤ 30 MB.

## 34.3 Web acceptance

- Measure compressed first-load size and time to interactive on a throttled 3G profile and report them.
- Target: first load ≤ 4 MB compressed, repeat loads served from cache.
- If targets cannot be met, document findings in `docs/web-fallback.md` (Next.js student web on the same API).

---

# 35. Backups

- Neon: point-in-time recovery enabled + daily logical dump (pg_dump) to a separate storage location outside Neon.
- R2: weekly sync of `media-private` and `media-public` to a separate bucket or provider (rclone job).
- Documented and tested restore procedure in `docs/deployment.md`.

---

# 36. Environment Variables

```text
# API
DATABASE_URL
BETTER_AUTH_SECRET
BETTER_AUTH_URL
APP_WEB_ORIGIN
ADMIN_ORIGIN
MOBILE_ACCESS_JWT_SECRET
MOBILE_REFRESH_TOKEN_PEPPER
R2_ACCOUNT_ID
R2_ACCESS_KEY_ID
R2_SECRET_ACCESS_KEY
R2_PRIVATE_BUCKET
R2_PUBLIC_BUCKET
R2_PUBLIC_BASE_URL
COUPON_HMAC_SECRET
COUPON_ENCRYPTION_KEY
EMAIL_PROVIDER_API_KEY
EMAIL_FROM
FCM_PROJECT_ID
FCM_SERVICE_ACCOUNT
SENTRY_DSN
TZ_BUSINESS=Asia/Damascus

# Flutter (--dart-define, public only)
API_BASE_URL
COUPON_REDEMPTION
SENTRY_DSN_PUBLIC
```

---

# 37. Testing

## 37.1 API unit

- Arabic normalizer (every rule + fixtures), accepted-answer matching, version regeneration
- SRS algorithm against shared fixtures (identical results in TS and Dart)
- Coupon normalization, HMAC lookup, overlap rule, upgrade flag
- Entitlement activity/expiry (including Damascus end-of-day)
- `canAccessItem` matrix: free / promoted / subject-entitled / track-entitled / none × general / track content
- Free-rule materialization and recomputation
- Mistake bank transitions, stats updates

## 37.2 API integration

Registration, OTP, login (all providers mocked), refresh rotation and reuse detection, coupon redemption, admin grants/extends/revokes with audit logs, practice checks, exam save/submit (late and on-time), random practice filtering, mixed quiz filtering, mock exam all-or-nothing, SRS sync idempotency and last-review-wins, uploads with presign/complete/quota, signed URL issuance only for accessible items, notifications targeting and consent, reports, account deletion.

## 37.3 Flutter

Login, RTL navigation, level browsing, teacher follow, Browse mode, Study mode (ratings, labels, undo, offline queue, sync), student deck CRUD offline, practice mode, exam mode (grid, flag, offline autosave, resume, submit), results, mistake bank, stats, coupon flow, locked states for both flag values, force update, offline banners. Web: cookie auth, deep links, keyboard shortcuts, responsive layouts.

## 37.4 Admin

Multi-admin login with 2FA, teacher/track CRUD, content CRUD, bulk import with errors, flashcard bulk upload pairing, free rule preview, coupon generation/export/revoke, entitlement tools, banners, countdowns, notifications targeting, reports inbox, question analytics.

## 37.5 Critical test cases

| Case | Expected |
|---|---|
| 20 concurrent redemptions of one single-use code | 1 success, 19 failures, 1 entitlement, 1 redemption |
| Redeem coupon for already-active scope | `ALREADY_ENTITLED`, coupon `current_uses` unchanged |
| Subject entitlement, request teacher-track question | `CONTENT_LOCKED`, no payload |
| Track entitlement, request general subject question | `CONTENT_LOCKED`, no payload |
| Mixed quiz, no entitlement | only free questions in attempt; counts correct |
| Mock exam with one premium question, no entitlement | whole quiz locked |
| Expired entitlement (Damascus 23:59:59 boundary) | locked immediately after |
| Quiz payload before grading | no `is_correct`, no accepted answers |
| Alef: accepted `أحمد`, input `احمد` | correct |
| Diacritics: accepted `دِمَشْق`, input `دمشق` | correct |
| Digits: accepted `3.5`, input `٣٫٥` | correct |
| Tatweel: accepted `سوريا`, input `سـوريـا` | correct |
| Unconfigured synonym | incorrect |
| SRS: new card Good, Good | learning 10 min, then review 1 day |
| SRS: new card Easy | review 4 days |
| SRS: review Again | relearning 10 min, ease −0.20 (min 1.30) |
| SRS: same review log synced twice | one log, state unchanged |
| Exam offline mid-attempt | answers kept, submitted on reconnect |
| `COUPON_REDEMPTION=false` build | no redeem route or button reachable |
| Signed URL request for locked card | no URL issued |
| Student image upload beyond quota | `QUOTA_EXCEEDED` |

---

# 38. Deferred (not V1)

AI features, video, audio, question images, LaTeX/math rendering, deck sharing between students, XP/leaderboards, live classes, chat, teacher accounts/dashboards, device limits, **Google Sign-In / Sign in with Apple**, Apple IAP / Google Play Billing (pending §44), FSRS scheduler, public SEO pages, Next.js student web (only if §34.3 fails).

---

# 39. Development Phases

| Phase | Scope |
|---|---|
| 1 Foundation | Monorepo, Fastify API skeleton, Drizzle + migrations, Neon, Better Auth email/password + email OTP + **first-party mobile access/refresh token service**, admins with 2FA, sessions, pg-boss, R2 storage module + upload flow, remote config + min version, Sentry, OpenAPI + client generation, CI, Drift + SQLCipher foundation, Flutter shell with RTL theme/dark mode, admin shell |
| 2 Education structure | Levels, college hierarchy, subjects, units, lessons (admin CRUD + student browsing of all levels) |
| 3 Teachers | Teachers, teacher tracks, composite track/subject FK constraints, follow/unfollow, teacher pages |
| 4 Access | Scopes, entitlements, stale-expiry transaction cleanup, partial unique active-scope indexes, free rules (materialized), promotions, `canAccessItem`, coupon batches/redemption/export/revoke, temporary→permanent upgrade, rate limits, locked states, My Access |
| 5 Questions | MCQ, T/F, written, accepted answers, normalizer v1, snapshots; `questions.content_version` included from first migration |
| 6 Flashcards | Official decks, image pipeline, Browse mode, SRS Study mode (Dart + TS fixtures), exact deterministic fuzz, undo, local SRS state + sync foundations; `content_version` included. **No offline-pack download yet.** |
| 7 Learning | Quizzes (`content_version`, `allow_offline` included), practice mode, exam mode (connection-drop tolerant), random practice, results, mistake bank, statistics, bookmarks, progress |
| 8 Student content | Student decks and cards (offline, images, quotas), add-to-my-deck, content reports |
| 9 Offline packs | §22 end-to-end: catalog/manifests/delta sync, deck/unit/scope downloads, signed media download, SQLCipher/AES-GCM storage, offline leases, local grading, server re-grade, resumable/background downloads, pack management UI |
| 10 Home & communication | Home, banners, exam countdown, **Damascus-boundary** daily goal & streak, notifications inbox, push, consent, due-card reminders |
| 11 Admin productivity | Import/export, flashcard bulk upload, audit log UI, question analytics, reports inbox, admin search |
| 12 Student web | Flutter web build, cookie auth, Drift web, responsive layouts, keyboard shortcuts, Cloudflare Pages deploy, performance measurement |
| 13 Hardening & release | Security review, load test, backups + restore drill, account deletion, privacy policy/terms, store listings, App Review notes + demo account, **owner-run Android/iOS physical-device auth smoke tests**, release builds |

**Phase 1→2 gate:** automated backend auth tests + Flutter login-form/widget tests must pass. Real Android/iOS device execution is explicitly deferred to Phase 13 and is performed outside the cloud coding container.

---

# 40. Seed Data

```text
Grade 9:  Mathematics, Physics
Grade 12: Mathematics, Physics
College:  Sample University → Sample Faculty → Year 1 → Sample Subject
```

Also seed:

- 2 admins (with 2FA enrollment pending), 2 students
- 2 teachers; teacher tracks: "أ. أحمد — فيزياء بكالوريا", "أ. سارة — رياضيات تاسع"
- Free and premium questions of each type in general and track scopes
- Written questions with multiple accepted answers
- Official flashcard deck (general) and one track deck
- Curated quiz (both modes), mixed free/premium quiz, mock exam (exam-only, timed)
- Free rules: `first_n_items` on Grade 12 Physics; `manual` on a track
- One active promotion (past-dated, inactive) for testing
- Coupon batch (10 codes, permanent, Grade 12 Physics) with plaintext export in the seed output
- Student 1: permanent subject entitlement; Student 2: temporary track entitlement expiring in 7 days
- Student 1: SRS states in all four states, one private deck with 3 cards, mistakes, bookmarks
- Banner, exam countdowns for Grade 9 and 12

No teacher login accounts.

---

# 41. Claude Code Rules

1. Read §0 and "Changes from v4" first.
2. Work phase by phase; finish tests for a phase before moving on.
3. All schema changes via migrations.
4. Only the API touches PostgreSQL and R2.
5. Authorization is server-side through the §8.6 helpers only.
6. Never return premium payloads, correct answers, or accepted answers to unauthorized or ungraded requests.
7. Thin routes; business logic in services; data access in repositories.
8. Keep the storage module provider-neutral.
9. Keep the API portable (Docker; no host-specific APIs).
10. Preserve Arabic RTL everywhere.
11. Reusable Flutter widgets; one codebase for Android, iOS, and web.
12. SRS algorithm: Dart and TS implementations must pass the same fixtures.
13. `COUPON_REDEMPTION` is compile-time only; never add remote control of it.
14. No AI, no teacher auth, no teacher dashboard, no device cap.
15. No student deck sharing in V1.
16. Do not build a Next.js student frontend unless explicitly requested.
17. Support multiple admins with 2FA.
18. Coupon redemption stays separate from entitlement authorization.
19. Avoid unnecessary dependencies; prefer maintainable code.
20. Record architecture decisions in `docs/architecture.md` (ADR list).
21. Use current stable compatible dependency versions.

---

# 42. Business Rules

```text
1.  Student app: Flutter for Android, iOS, and web (one codebase).
1b. Student sign-in in V1 is Email + Password only; verification/password reset use email OTP. No Google or Apple social sign-in.
2.  Admin: Next.js web dashboard; multiple admins with mandatory 2FA.
3.  Teachers are content entities only; no accounts or dashboards.
4.  Teacher tracks are separate access scopes from general subject content.
5.  A subject entitlement never unlocks teacher-track content, and vice versa.
6.  Following a teacher never unlocks content.
7.  Levels: Grade 9, Grade 12, College. Students may browse all levels.
8.  Units and lessons are optional.
9.  Free status is materialized per item from configurable rules; manual overrides allowed.
10. Mixed quizzes show only accessible questions; mock exams are all-or-nothing.
11. Premium access = entitlements. One `status='active'` entitlement per scope per student, enforced by partial unique indexes; stale expired rows are transitioned inside each grant/redemption transaction before renewal.
12. Coupons for an already-active scope are rejected and not consumed.
13. Coupons are generated and exported by admins; single-use by default; temporary or permanent access.
14. Written answers: deterministic normalization, exact match, no partial credit, no AI.
15. The server is the grading authority; offline packs grade locally for instant feedback and the server re-grades on sync.
15b. Offline packs (decks, units, subjects/tracks) are downloaded by explicit choice, encrypted on the device, and valid for up to 30 days offline per online check-in (mobile only in V1).
16. Flashcards: Browse mode and Anki-style Study mode (Again / Good / Easy) with undo.
17. Students may create private decks; no sharing in V1.
18. Quizzes: Practice mode (check each) or Exam mode (grade at end); admins may force exam-only.
19. Mistake bank: questions leave after 2 consecutive correct answers.
20. Banner and content changes never require an app update.
21. No device limit.
22. Entire UI is Arabic RTL.
23. Coupon redemption UI is a compile-time per-platform flag, independent of entitlements.
24. Promotional push notifications require opt-in.
25. Plan B = web app becomes primary + PWA install; same backend, no new frontend.
```

---

# 43. V1 Acceptance Criteria

## Student (mobile and web unless noted)

1. Install on Android and iOS; open the web app.
2. Register with Email + Password, verify with email OTP, login with Email + Password, refresh the mobile session securely, and reset a forgotten password by OTP.
3. Choose level; browse all levels and subjects.
4. View free content; see locked metadata for premium content.
5. Redeem a coupon (where enabled); receive `ALREADY_ENTITLED` for a duplicate scope.
6. See correct access separation between subject and teacher-track content.
7. View My Access with expiry dates.
8. Browse teachers and tracks; follow/unfollow.
9. Flashcards: Browse (flip, previous/next) and Study (Again/Good/Easy with interval labels, undo), offline, synced across devices.
10. Create, edit, delete private decks and cards (text + images), offline; add official cards to own deck.
11. Answer MCQ, True/False, written Arabic questions with normalized grading.
12. Take quizzes in Practice mode and Exam mode (timer, grid, flags, review, offline tolerance, resume).
13. See results with explanations; retry mistakes only.
14. Use random practice.
15. Use the mistake bank and statistics dashboard.
16. Bookmark items; view progress.
17. See exam countdown, daily goal, and streak.
18. Receive in-app notifications and push (where supported); manage notification categories.
19. Report a problem with a question or card.
20. Manage profile, settings, sessions; delete account.
21. Forced update works when below minimum version.

## Admin

1. Login with 2FA; manage other admins.
2. Manage students, their entitlements (grant, extend, revoke) and sessions.
3. Manage teachers and teacher tracks.
4. Manage levels, college hierarchy, subjects, units, lessons.
5. Create all question types with accepted answers and normalized preview.
6. Upload flashcards individually and in bulk.
7. Create quizzes with mode settings, timers, mock exam flag.
8. Configure free rules with preview; set manual overrides; create promotions.
9. Generate, export, and revoke coupon batches.
10. Manage banners and exam countdowns.
11. Send targeted notifications with recipient preview.
12. Import/export content via CSV/XLSX.
13. Handle reports; view question analytics.
14. View audit logs.

---

# 44. Open Items (decide before the named phase)

| Item | Default in this spec | Decide before |
|---|---|---|
| Temporary → permanent upgrade | **Allowed** (`allowTemporaryToPermanentUpgrade=true`): supersede active temporary entitlement and create permanent entitlement atomically | Resolved for Phase 4 |
| iOS if coupon redemption is rejected by App Review | Ship with `COUPON_REDEMPTION=false`; consider Apple IAP later | Phase 13 |
| Branding: name, logo, colors, Arabic font, icon, splash | Placeholder theme tokens | Phase 12 |
| Production domain name | `<domain>` placeholder is fine for Phases 1–11. With Email/Password-only auth there is no OAuth-domain dependency. Choose/reserve the real domain before Phase 12 web/staging deployment and before production email/support/legal URLs are finalized. | Before Phase 12 |
| Apple/Google store developer accounts | Not needed for V1 authentication; required only for signing/submission and store services. | Phase 13 |
| Data retention policy text | §33 defaults | Phase 13 |
| National exam dates | Admin-configurable | Phase 10 |
| Support channels (email / WhatsApp) | Remote config | Phase 10 |

---

# 45. Final Principle

Build the API as a reusable platform. Flutter is the single student client across Android, iOS, and web. Next.js is the admin control surface. Teachers are content; teacher tracks are their own access scope. Entitlements are the access backbone; coupons are one way to create them. If store distribution succeeds, continue with Plan A; if it fails, the web app becomes primary with PWA install enabled — same backend, same data, no rewrite.
