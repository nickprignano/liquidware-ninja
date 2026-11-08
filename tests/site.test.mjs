// Tests for the liquidware-ninja site (site/, published to https://liquidware-ninja.prignano.ai/ via Cloudflare Workers).
// Verifies the vendored avd-ops design system lock, app shell consistency, research-only notices,
// internal link resolution, KB docs + graph sync, blog posts sync, and public-safe hygiene.
// Run: node --test "tests/*.test.mjs"
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync, readdirSync, existsSync, statSync } from 'node:fs';
import { execFileSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = fileURLToPath(new URL('../', import.meta.url));
const walk = (d) => readdirSync(join(root, d)).flatMap((f) => (statSync(join(root, d, f)).isDirectory() ? walk(`${d}/${f}`) : [`${d}/${f}`]));
const pages = walk('site').filter((f) => f.endsWith('.html'));
const read = (f) => readFileSync(join(root, f), 'utf8');

test('the site includes overview, architecture, toolkit, all 4 Liquidware repo pages, blog, and KB docs', () => {
  for (const required of [
    'site/index.html',
    'site/architecture.html',
    'site/toolkit.html',
    'site/repos/liquidware-ninja.html',
    'site/repos/avd-liquidware.html',
    'site/repos/ux-assess.html',
    'site/repos/flexapp-factory.html',
    'site/blog/index.html',
    'site/docs/index.html',
    'site/docs/graph.html',
  ]) {
    assert.ok(pages.includes(required), `missing ${required}`);
  }
});

test('every page carries the liquidware-ninja brand, research-only notice, and credit line', () => {
  for (const f of pages) {
    const h = read(f);
    assert.match(h, /<a class="brand" href="[^"]*index\.html"><img class="mark" src="[^"]*assets\/brand\/mark\.svg" alt=""[^>]*><span class="name"><span class="word">liquidware-ninja<\/span><span class="tag">Second brain &amp; toolkit<\/span><\/span><\/a>/, f);
    const top = h.split('<main')[0];
    for (const re of [
      /Personal project\. Research and learning only\. Not for production\. No warranty\./,
      /Not affiliated with, endorsed by or supported by my employer, Liquidware or Microsoft\./,
      /Bring your own Liquidware licenses\./,
      /"as is", without warranty of any kind/,
      /Contributions and forks are welcome and encouraged/,
    ]) {
      assert.match(top, re, `${f} is missing ${re}`);
    }
    assert.match(h, /<p class="credit">A <a href="https:\/\/prignano\.ai\/">prignano\.ai<\/a> production · Part of <a href="https:\/\/avd-ops\.dev\/">avd-ops<\/a><\/p>/, `${f}: credit line`);
  }
});

test('every page uses the vendored avd-ops design system with no inline styles or external fonts', () => {
  for (const f of pages) {
    const h = read(f);
    assert.match(h, /<link rel="stylesheet" href="(\.\.\/)*assets\/avd-ops\.css">/, `${f}: no avd-ops.css`);
    assert.match(h, /<link rel="stylesheet" href="(\.\.\/)*assets\/avd-ops-shell\.css">/, `${f}: no avd-ops-shell.css`);
    assert.match(h, /<link rel="stylesheet" href="(\.\.\/)*assets\/site\.css">/, `${f}: no site.css`);
    assert.match(h, /<script src="(\.\.\/)*assets\/theme\.js"><\/script>/, `${f}: no theme.js`);
    assert.match(h, /<body class="shell">/, `${f}: not in the shell`);
    assert.match(h, /<link rel="icon" href="(\.\.\/)*assets\/brand\/favicon\.svg"/, `${f}: no favicon`);
    assert.doesNotMatch(h, /<style|style="/, `${f}: inline styles belong in assets/site.css`);
    assert.doesNotMatch(h, /fonts\.(googleapis|gstatic)\.com/, `${f}: fonts are served from assets/fonts`);
  }
  assert.doesNotMatch(read('site/assets/site.css'), /#[0-9a-fA-F]{3,6}\b/, 'hex color in site.css (must use design system tokens)');
});

test('vendored design system files match site/assets/design-system.lock.json', () => {
  const lock = JSON.parse(read('site/assets/design-system.lock.json'));
  assert.match(lock.tag, /^ds-v\d+\.\d+\.\d+$/, 'design system tag');
  for (const [relPath, expectedHash] of Object.entries(lock.files)) {
    const fullPath = join(root, 'site/assets', relPath);
    assert.ok(existsSync(fullPath), `missing vendored asset ${relPath}`);
    const raw = readFileSync(fullPath);
    const buf = /\.(css|js|svg)$|LICENSE$/.test(relPath)
      ? Buffer.from(raw.toString('utf8').replace(/\r\n/g, '\n'), 'utf8')
      : raw;
    const actualHash = createHash('sha256').update(buf).digest('hex');
    assert.equal(actualHash, expectedHash, `${relPath} hash mismatch against design-system.lock.json`);
  }
});

test('hand-written shell and generated docs/blog/llms.txt are up to date', () => {
  execFileSync(process.execPath, [join(root, 'scripts/site/build-site.mjs'), '--check'], { stdio: 'pipe' });
  execFileSync(process.execPath, [join(root, 'scripts/site/apply-shell.mjs'), '--check'], { stdio: 'pipe' });
  const graph = JSON.parse(read('site/docs/graph.json'));
  assert.ok(graph.nodes.length >= 20, 'knowledge base graph nodes');
  const ids = new Set(graph.nodes.map((n) => n.id));
  for (const l of graph.links) {
    assert.ok(ids.has(l.source) && ids.has(l.target), `${l.source} -> ${l.target}`);
  }
});

test('relative links and asset sources resolve to files in site/', () => {
  for (const f of pages) {
    for (const [, href] of read(f).matchAll(/(?:href|src)="([^"]+)"/g)) {
      if (/^(https?:|mailto:|#)/.test(href)) continue;
      const target = join(root, dirname(f), href.split('#')[0]);
      assert.ok(existsSync(target), `${f}: broken relative link ${href}`);
    }
  }
});

test('wrangler.jsonc configures Cloudflare Workers static assets for liquidware-ninja.prignano.ai', () => {
  const raw = read('wrangler.jsonc').replace(/\/\/.*$/gm, '');
  const cfg = JSON.parse(raw);
  assert.equal(cfg.name, 'liquidware-ninja');
  assert.equal(cfg.assets?.directory, './site');
  assert.ok(cfg.routes?.some((r) => r.pattern === 'liquidware-ninja.prignano.ai' && r.custom_domain === true), 'custom_domain route for liquidware-ninja.prignano.ai');
});
