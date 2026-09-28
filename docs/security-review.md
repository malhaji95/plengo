# Security review (Phase 13)

Reviewed 2026-09-28 against spec §31 and common web/mobile risks. Each item names where it is
enforced and the test that proves it.

## §31 requirements

| Requirement                                                                                              | Where                                                                                                             | Evidence                                                                                              |
| -------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------- |
| Validate all input with Zod                                                                              | Every route declares `body`/`querystring`/`params` schemas; unknown shapes → `VALIDATION_ERROR`                   | contracts tests; every API suite sends invalid payloads                                               |
| Server verifies identity, admin role + 2FA, ownership, access, coupon validity, free status, quotas      | `authorization/guards.ts` (`requireUser`, `requireAdmin` with TOTP), services check ownership and `canAccessItem` | `auth.test`, `admin-auth.test`, `access.test` (§37.5 cases), `my-decks.test` (quotas), `offline.test` |
| HTTPS only; HSTS everywhere                                                                              | API sends HSTS in staging/production; admin in production builds; web via `_headers`                              | `hardening.test` (API), admin `lib.test`, `tool/web_headers.mjs`                                      |
| No secrets in Flutter                                                                                    | Only `API_BASE_URL`, `COUPON_REDEMPTION`, `SENTRY_DSN_PUBLIC` dart-defines (`lib/app/flags.dart`)                 | code review                                                                                           |
| Modern password hashing                                                                                  | Better Auth scrypt; admin TOTP                                                                                    | Better Auth defaults                                                                                  |
| Rate limits: login 10/15 min per IP+email; OTP 5/h per email; coupons §9.5; reports 20/day; uploads 60/h | `routes/auth.ts`, `coupon-service.ts`, `report-service.ts`, `routes/uploads.ts`; `/me/delete` 10/15 min           | `auth.test`, `access.test`, `my-decks.test`, `uploads.test`                                           |
| Private bucket never public; signed URLs only for accessible items                                       | `storage/`, `flashcard-service` image URLs after `canAccessItem`                                                  | `flashcards.test` ("no URL issued for a locked card"), `r2-storage.test`                              |
| CSRF for cookie sessions; strict CORS                                                                    | Origin + `X-Requested-With` check on cookie requests; CORS allowlist = web and admin origins                      | `auth.test` (evil origin refused)                                                                     |
| IPs hashed where kept                                                                                    | `hashIp` for audit, sessions, coupon failures                                                                     | code review                                                                                           |
| RLS optional, not a second source of truth                                                               | Not used; authorization lives in the API only                                                                     | architecture ADR                                                                                      |

## Other checks

- **Authorization boundaries**: students are refused on every admin route (403) and admins on
  student routes; tests in `admin-tools.test`, `account.test`, `learning.test`.
- **Injection**: all SQL through Drizzle parameters. `ILIKE` searches escape `%`, `_` and `\`
  (admin search, student search) so user input cannot widen a query.
- **Spreadsheet injection**: exports neutralise leading `= + - @` (`toCsv`), imports restore them.
- **Zip bombs**: XLSX import and bulk-upload ZIPs cap entry and total inflated size
  (`tabular.test`).
- **Upload validation**: MIME and size are checked on presign; images are decoded and re-encoded
  by the media job (a non-image fails processing).
- **Error disclosure**: unexpected errors return the generic Arabic `SERVER_ERROR` envelope with no
  stack or message, and are reported to Sentry; expected errors are not (`hardening.test`).
- **Account deletion** removes credentials, sessions, tokens and personal data immediately
  (`account.test`); the privacy policy states the 35-day backup window.
- **Admin UI**: CSP with `frame-ancestors 'none'`, `object-src 'none'`, `base-uri 'self'`,
  `X-Frame-Options: DENY`. Scripts keep `'unsafe-inline'` because Next.js inlines its bootstrap;
  a nonce-based CSP via middleware is a possible later hardening.
- **Student web**: CSP without inline scripts, exact API/media/Sentry origins (`web.md`).
- **Local data**: SQLCipher database and AES-GCM pack files on mobile; wiped on logout and on
  account deletion.
- **Audit**: sensitive admin actions and account deletions are in `audit_logs`, viewable in the
  admin with filters.

## Dependencies

`pnpm audit --prod` (2026-09-28): one moderate advisory — esbuild ≤ 0.24.2 (GHSA-67mh-4wv8-2f99,
the development server answers cross-origin requests). It is reached only through
better-auth → drizzle-kit, a schema tool never started by the API at runtime, so it is not
exploitable in deployment. Re-check on dependency upgrades.

## Open items for the owner

- Penetration test by a third party before a large launch (not possible from the build container).
- Production secrets: generate every secret fresh (≥ 32 random characters); never reuse the example
  values; never rotate the coupon secrets on a live system (docs/deployment.md).
