# Plengo student app (Flutter)

One codebase for Android, iOS and web (spec §0.5, §24). Arabic only, right-to-left.

## Run

```bash
flutter pub get
dart run build_runner build            # drift + json_serializable + retrofit code
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:4000       # Android emulator
flutter run -d chrome --web-port 3001 --dart-define=API_BASE_URL=http://localhost:4000
```

Build-time flags (`--dart-define`, spec §10.1, §36):

| Name | Default | Notes |
|---|---|---|
| `API_BASE_URL` | `http://localhost:4000` | Public API origin |
| `COUPON_REDEMPTION` | `true` | Compile-time only. `false` removes the redeem route entirely (iOS fallback, §0.6) |
| `SENTRY_DSN_PUBLIC` | empty | Crash reporting disabled when empty |

Web release builds must use `--no-web-resources-cdn` so CanvasKit is served from the app origin;
the Arabic font is bundled, so nothing is fetched from Google's CDNs (§24).

## Regenerating the API client

The client in `lib/core/api/generated` comes from `packages/contracts/openapi.json`:

```bash
dart run swagger_parser && dart run build_runner build
```

CI fails if the committed client differs from the generated one.

## Layout

```
lib/app/        bootstrap, router, theme, flags, providers
lib/core/       api client (generated + interceptors), auth, drift database, config
lib/features/   auth, shell (5-tab navigation), account, sessions, update, splash
lib/shared/     widgets and validators
web/            index.html, manifest, drift_worker.js + sqlite3.wasm (drift on web)
```

## Local database

`AppDatabase` (drift) is SQLCipher-encrypted on Android/iOS through `package:sqlite3`'s
`source: sqlcipher` build hook; the key is generated per device and kept in Keychain/Keystore.
On web it uses the WASM SQLite build (no secure key storage in browsers, §22.8).
