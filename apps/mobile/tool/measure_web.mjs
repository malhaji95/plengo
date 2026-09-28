#!/usr/bin/env node
/*
 * Web acceptance measurement (spec §34.3): serves a release build the way Cloudflare Pages does
 * (brotli, SPA fallback, the cache headers of web/_headers and the service worker), loads it in
 * headless Chromium under a throttled 3G profile, and reports transferred bytes and the time to
 * Flutter's first frame for a first visit and a repeat visit.
 *
 *   node tool/measure_web.mjs [build/web] [--profile fast3g|slow3g] [--cpu 4] [--json out.json]
 *
 * Needs a Chromium binary: CHROME=/path/to/chrome (defaults to the Playwright download under
 * PLAYWRIGHT_BROWSERS_PATH). No npm dependencies: the DevTools protocol is spoken over WebSocket.
 */
import { spawn } from 'node:child_process';
import { existsSync, mkdtempSync, readFileSync, readdirSync, rmSync, statSync, writeFileSync } from 'node:fs';
import { createServer } from 'node:http';
import { tmpdir } from 'node:os';
import { extname, join, normalize } from 'node:path';
import { createHash } from 'node:crypto';
import { brotliCompressSync, constants, gzipSync } from 'node:zlib';

const args = process.argv.slice(2);
const flag = (name, fallback) => {
  const i = args.indexOf(`--${name}`);
  return i >= 0 ? args[i + 1] : fallback;
};
const root = args.find((a, i) => !a.startsWith('--') && !args[i - 1]?.startsWith('--')) ?? 'build/web';
const profileName = flag('profile', 'fast3g');
const cpu = Number(flag('cpu', '4'));
const jsonOut = flag('json', null);
const waterfall = args.includes('--waterfall');

// Chrome DevTools presets (bytes per second, ms).
const PROFILES = {
  fast3g: { latency: 562.5, downloadThroughput: 180_000, uploadThroughput: 84_375 },
  slow3g: { latency: 2000, downloadThroughput: 50_000, uploadThroughput: 50_000 },
};
const profile = PROFILES[profileName];
if (!profile) throw new Error(`unknown profile ${profileName}`);

const TYPES = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'text/javascript',
  '.mjs': 'text/javascript',
  '.json': 'application/json',
  '.wasm': 'application/wasm',
  '.png': 'image/png',
  '.ttf': 'font/ttf',
  '.otf': 'font/otf',
  '.bin': 'application/octet-stream',
  '.frag': 'application/octet-stream',
};

/** Headers per path from the `_headers` file shipped with the build (Cloudflare Pages syntax). */
function headerRules() {
  const file = join(root, '_headers');
  if (!existsSync(file)) return [];
  const rules = [];
  let current = null;
  for (const line of readFileSync(file, 'utf8').split('\n')) {
    if (!line.trim() || line.trim().startsWith('#')) continue;
    if (!/^\s/.test(line)) {
      current = { pattern: line.trim(), headers: {} };
      rules.push(current);
    } else if (current) {
      const at = line.indexOf(':');
      current.headers[line.slice(0, at).trim().toLowerCase()] = line.slice(at + 1).trim();
    }
  }
  return rules.map((r) => ({
    re: new RegExp(`^${r.pattern.replace(/[.+?^${}()|[\]\\]/g, '\\$&').replace(/\*/g, '.*')}$`),
    headers: r.headers,
  }));
}
const rules = headerRules();
const compressed = new Map();

const server = createServer((req, res) => {
  const url = new URL(req.url, 'http://x');
  let path = normalize(decodeURIComponent(url.pathname)).replace(/^(\.\.[/\\])+/, '');
  let file = join(root, path);
  if (!existsSync(file) || statSync(file).isDirectory()) {
    file = join(root, 'index.html'); // SPA fallback, as on Cloudflare Pages
    path = '/index.html';
  }
  const type = TYPES[extname(file)] ?? 'application/octet-stream';
  const raw = readFileSync(file);
  const accept = req.headers['accept-encoding'] ?? '';
  // Strong validators, as Cloudflare Pages sends: repeat visits revalidate with 304s.
  const etag = `"${createHash('sha1').update(raw).digest('hex')}"`;
  const headers = { 'content-type': type, vary: 'accept-encoding', etag };
  for (const rule of rules) if (rule.re.test(path)) Object.assign(headers, rule.headers);
  headers['cache-control'] ??= 'no-cache';
  if (req.headers['if-none-match'] === etag) {
    res.writeHead(304, headers);
    res.end();
    return;
  }
  let body = raw;
  if (/\bbr\b/.test(accept) && raw.length > 1024) {
    const key = `br:${file}`;
    if (!compressed.has(key))
      compressed.set(key, brotliCompressSync(raw, { params: { [constants.BROTLI_PARAM_QUALITY]: 11 } }));
    body = compressed.get(key);
    headers['content-encoding'] = 'br';
  } else if (/\bgzip\b/.test(accept) && raw.length > 1024) {
    const key = `gz:${file}`;
    if (!compressed.has(key)) compressed.set(key, gzipSync(raw, { level: 9 }));
    body = compressed.get(key);
    headers['content-encoding'] = 'gzip';
  }
  headers['content-length'] = body.length;
  res.writeHead(200, headers);
  res.end(req.method === 'HEAD' ? undefined : body);
});
await new Promise((r) => server.listen(0, '127.0.0.1', r));
const origin = `http://127.0.0.1:${server.address().port}`;

function chromePath() {
  if (process.env.CHROME) return process.env.CHROME;
  const base = process.env.PLAYWRIGHT_BROWSERS_PATH ?? '/opt/pw-browsers';
  const dir = readdirSync(base).find((d) => /^chromium-\d+$/.test(d));
  if (!dir) throw new Error('no Chromium found; set CHROME');
  return join(base, dir, 'chrome-linux', 'chrome');
}

const profileDir = mkdtempSync(join(tmpdir(), 'measure-web-'));
const chrome = spawn(
  chromePath(),
  [
    '--headless=new',
    '--remote-debugging-port=0',
    `--user-data-dir=${profileDir}`,
    '--no-sandbox',
    '--no-first-run',
    '--enable-unsafe-swiftshader',
    '--window-size=412,915',
    'about:blank',
  ],
  { stdio: ['ignore', 'ignore', 'pipe'] },
);
const wsUrl = await new Promise((resolve, reject) => {
  let buf = '';
  chrome.stderr.on('data', (d) => {
    buf += d;
    const m = /DevTools listening on (ws:\/\/\S+)/.exec(buf);
    if (m) resolve(m[1]);
  });
  chrome.on('exit', () => reject(new Error(`chrome exited: ${buf.slice(-500)}`)));
});

// ---- minimal DevTools protocol client ----
const ws = new WebSocket(wsUrl);
await new Promise((r) => ws.addEventListener('open', r, { once: true }));
let nextId = 0;
const pending = new Map();
const listeners = [];
ws.addEventListener('message', (e) => {
  const msg = JSON.parse(e.data);
  if (msg.id !== undefined && pending.has(msg.id)) {
    const { resolve, reject } = pending.get(msg.id);
    pending.delete(msg.id);
    msg.error ? reject(new Error(msg.error.message)) : resolve(msg.result);
  } else if (msg.method) for (const l of listeners) l(msg);
});
const send = (method, params = {}, sessionId) =>
  new Promise((resolve, reject) => {
    const id = ++nextId;
    pending.set(id, { resolve, reject });
    ws.send(JSON.stringify({ id, method, params, ...(sessionId ? { sessionId } : {}) }));
  });

async function visit(sessionId, label) {
  let bytes = 0;
  let requests = 0;
  const timeline = new Map();
  const problems = [];
  let t0 = null;
  const onEvent = (msg) => {
    if (msg.sessionId !== sessionId) return;
    if (msg.method === 'Log.entryAdded' && msg.params.entry.level === 'error') problems.push(msg.params.entry.text);
    if (msg.method === 'Runtime.exceptionThrown') problems.push(msg.params.exceptionDetails.exception?.description ?? msg.params.exceptionDetails.text);
    if (msg.method === 'Network.requestWillBeSent') {
      t0 ??= msg.params.timestamp;
      timeline.set(msg.params.requestId, { url: msg.params.request.url.replace(origin, ''), start: msg.params.timestamp });
    }
    if (msg.method === 'Network.loadingFinished') {
      bytes += msg.params.encodedDataLength;
      requests++;
      const t = timeline.get(msg.params.requestId);
      if (t) Object.assign(t, { end: msg.params.timestamp, kb: Math.round(msg.params.encodedDataLength / 1024) });
    }
  };
  listeners.push(onEvent);
  const start = Date.now();
  await send('Page.navigate', { url: `${origin}/` }, sessionId);
  const { result } = await send(
    'Runtime.evaluate',
    {
      expression: `new Promise((resolve, reject) => {
        const t = setTimeout(() => reject(new Error('timeout')), 300000);
        const done = () => { clearTimeout(t); resolve(performance.now()); };
        if (window.__firstFrame) done(); else window.addEventListener('flutter-first-frame', done, { once: true });
      })`,
      awaitPromise: true,
      returnByValue: true,
    },
    sessionId,
  );
  const firstFrameMs = Math.round(result.value);
  // Let late requests (fonts, wasm workers) finish before counting.
  await new Promise((r) => setTimeout(r, 3000));
  listeners.splice(listeners.indexOf(onEvent), 1);
  if (waterfall) {
    for (const t of timeline.values()) {
      const at = (x) => (x === undefined ? '   -  ' : ((x - t0) * 1000).toFixed(0).padStart(6));
      console.error(`${label.padEnd(13)} ${at(t.start)} → ${at(t.end)} ms  ${String(t.kb ?? '?').padStart(5)} KB  ${t.url}`);
    }
  }
  // The API is not running during the measurement: its connection errors are expected.
  const errors = problems.filter((p) => !/127\.0\.0\.1:4999|ERR_CONNECTION_REFUSED|Failed to load resource/.test(p));
  return { label, firstFrameMs, transferredKB: Math.round(bytes / 1024), requests, wallMs: Date.now() - start, errors };
}

try {
  const { targetId } = await send('Target.createTarget', { url: 'about:blank' });
  const { sessionId } = await send('Target.attachToTarget', { targetId, flatten: true });
  await send('Page.enable', {}, sessionId);
  await send('Network.enable', {}, sessionId);
  await send('Runtime.enable', {}, sessionId);
  await send('Log.enable', {}, sessionId);
  await send('Network.emulateNetworkConditions', { offline: false, ...profile }, sessionId);
  if (cpu > 1) await send('Emulation.setCPUThrottlingRate', { rate: cpu }, sessionId);
  await send(
    'Page.addScriptToEvaluateOnNewDocument',
    { source: "window.addEventListener('flutter-first-frame', () => { window.__firstFrame = true; });" },
    sessionId,
  );
  // Measured visits bypass the service worker: its own fetches are not throttled by the page's
  // network emulation, so only the HTTP cache counts toward the repeat-visit numbers.
  await send('Network.setBypassServiceWorker', { bypass: true }, sessionId);
  const first = await visit(sessionId, 'first visit');
  const repeat = await visit(sessionId, 'repeat visit');
  // Offline shell: a visit through the service worker fills its cache, then the server stops and the
  // app must still start from the cache (spec §24).
  await send('Network.setBypassServiceWorker', { bypass: false }, sessionId);
  await visit(sessionId, 'warm worker');
  server.closeAllConnections();
  await new Promise((r) => server.close(r));
  const offline = await visit(sessionId, 'offline visit').catch((err) => ({ label: 'offline visit', error: String(err) }));
  const report = { profile: profileName, ...profile, cpuSlowdown: cpu, results: [first, repeat, offline] };
  console.log(JSON.stringify(report, null, 2));
  if (jsonOut) writeFileSync(jsonOut, JSON.stringify(report, null, 2));
} finally {
  ws.close();
  chrome.kill('SIGKILL');
  if (server.listening) server.close();
  rmSync(profileDir, { recursive: true, force: true });
}
