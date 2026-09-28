#!/usr/bin/env node
/*
 * First-load size budget for the web build (spec §34.3: ≤ 4 MB compressed). Sums the brotli size
 * (what Cloudflare serves) of everything a first visit downloads before the app is usable: the HTML,
 * bootstrap, compiled app, the renderer (Chrome's CanvasKit; other browsers get the full one),
 * the bundled fonts, and the WASM database.
 *
 *   node tool/web_size.mjs build/web [--budget-kb 4096]
 */
import { existsSync, readFileSync } from 'node:fs';
import { join } from 'node:path';
import { brotliCompressSync, constants, gzipSync } from 'node:zlib';

const root = process.argv[2] ?? 'build/web';
const i = process.argv.indexOf('--budget-kb');
const budgetKb = i > 0 ? Number(process.argv[i + 1]) : 4096;

const fonts = JSON.parse(readFileSync(join(root, 'assets/FontManifest.json'), 'utf8')).flatMap((f) =>
  f.fonts.map((x) => `assets/${x.asset}`),
);
const common = [
  'index.html',
  'flutter_bootstrap.js',
  'boot.js',
  'main.dart.js',
  ...fonts,
  'assets/fonts/fallback/Roboto-Regular.ttf',
  'sqlite3.wasm',
  'drift_worker.js',
];
const sets = {
  chrome: [...common, 'canvaskit/chromium/canvaskit.js', 'canvaskit/chromium/canvaskit.wasm'],
  other: [...common, 'canvaskit/canvaskit.js', 'canvaskit/canvaskit.wasm'],
};

const size = (file) => {
  const raw = readFileSync(join(root, file));
  return {
    raw: raw.length,
    gzip: gzipSync(raw, { level: 9 }).length,
    brotli: brotliCompressSync(raw, { params: { [constants.BROTLI_PARAM_QUALITY]: 11 } }).length,
  };
};
const kb = (n) => Math.round(n / 1024);

let failed = false;
for (const [name, files] of Object.entries(sets)) {
  const total = { raw: 0, gzip: 0, brotli: 0 };
  for (const f of files.filter((f) => existsSync(join(root, f)))) {
    const s = size(f);
    total.raw += s.raw;
    total.gzip += s.gzip;
    total.brotli += s.brotli;
  }
  console.log(`${name.padEnd(7)} raw ${kb(total.raw)} KB · gzip ${kb(total.gzip)} KB · brotli ${kb(total.brotli)} KB`);
  if (name === 'chrome' && kb(total.brotli) > budgetKb) failed = true;
}
if (failed) {
  console.error(`first load exceeds the ${budgetKb} KB budget (spec §34.3)`);
  process.exit(1);
}
