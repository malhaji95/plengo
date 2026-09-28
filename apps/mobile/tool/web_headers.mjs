#!/usr/bin/env node
/*
 * Writes `_headers` for Cloudflare Pages into a web build (spec §24, §31): security headers, a
 * Content-Security-Policy limited to the API, media and error-reporting origins, and caching.
 *
 *   API_BASE_URL=https://api.example.com MEDIA_ORIGINS=https://cdn.example.com,https://<acct>.r2.cloudflarestorage.com \
 *   SENTRY_ORIGIN=https://o0.ingest.sentry.io node tool/web_headers.mjs build/web
 *
 * Every file is served with `no-cache`: browsers keep it and revalidate with the ETag (a 304 on
 * repeat visits). Flutter's engine files are not content-hashed, so long max-age values could pair
 * an old CanvasKit with a new main.dart.js after a deploy.
 */
import { writeFileSync } from 'node:fs';
import { join } from 'node:path';

const out = process.argv[2] ?? 'build/web';
const origin = (url) => new URL(url).origin;
const api = process.env.API_BASE_URL;
if (!api) throw new Error('API_BASE_URL is required');
const media = (process.env.MEDIA_ORIGINS ?? '').split(',').filter(Boolean).map(origin);
const sentry = process.env.SENTRY_ORIGIN ? [origin(process.env.SENTRY_ORIGIN)] : [];

const csp = [
  "default-src 'self'",
  // CanvasKit and sqlite3 are WebAssembly.
  "script-src 'self' 'wasm-unsafe-eval'",
  // Flutter inserts <style> elements for its host view.
  "style-src 'self' 'unsafe-inline'",
  `img-src 'self' data: blob: ${media.join(' ')}`.trim(),
  "font-src 'self' data:",
  `connect-src 'self' ${[origin(api), ...media, ...sentry].join(' ')}`,
  "worker-src 'self' blob:",
  "manifest-src 'self'",
  "object-src 'none'",
  "base-uri 'self'",
  "form-action 'self'",
  "frame-ancestors 'none'",
].join('; ');

const headers = `/*
  Content-Security-Policy: ${csp}
  Strict-Transport-Security: max-age=31536000; includeSubDomains
  X-Content-Type-Options: nosniff
  X-Frame-Options: DENY
  Referrer-Policy: strict-origin-when-cross-origin
  Permissions-Policy: camera=(), microphone=(), geolocation=(), payment=()
  Cache-Control: no-cache
`;
writeFileSync(join(out, '_headers'), headers);
console.log(`wrote ${join(out, '_headers')}`);
