#!/usr/bin/env node
/**
 * Render MDS spec mockups to PNG (per-folder layout).
 *
 * Expected input layout (post folder migration):
 *   public/specs/
 *     {screen_name}/
 *       index.html          ← spec source
 *
 * Output (committed alongside index.html):
 *     {screen_name}/
 *       blueprint.png       ← top-level Layout > .blueprint (wireframe)
 *       blueprint_2.png     ← Sub-anatomy ② .blueprint
 *       blueprint_3.png     ← Sub-anatomy ③ .blueprint
 *       visual_1.png        ← .visual-gallery (component-level CSS render)
 *       visual_2.png
 *       state_1.png         ← .state-mini (page-level state variant, full table incl. header)
 *       state_2.png
 *
 * State naming: each `.state-mini` is a discrete state variant (Default / Empty /
 * Loading / Error / etc) — captured as a separate PNG so spec walker can compare
 * app's actual state vs spec's intended state side by side.
 *
 * Loads spec html via a temporary local http server so absolute paths
 * (/specs/_spec.css, /tokens.css, /logos/*.svg) resolve. No external server.
 *
 * Usage:
 *   npm run tokens:sync
 *   node scripts/render-spec-mockups.js
 */

const http = require('http');
const fs = require('fs');
const path = require('path');
const { chromium } = require('playwright');

const PUBLIC_DIR = path.resolve(__dirname, '../public');
const SPEC_DIR = path.join(PUBLIC_DIR, 'specs');
const PORT = 4567;

const MIME = {
  '.html': 'text/html; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.js': 'application/javascript; charset=utf-8',
  '.svg': 'image/svg+xml',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.json': 'application/json',
  '.woff': 'font/woff',
  '.woff2': 'font/woff2',
};

function startServer() {
  return new Promise((resolve, reject) => {
    const server = http.createServer((req, res) => {
      const url = decodeURIComponent(req.url.split('?')[0]);
      let filePath = path.join(PUBLIC_DIR, url);
      if (!filePath.startsWith(PUBLIC_DIR)) {
        res.writeHead(403); res.end('forbidden'); return;
      }
      // Auto-serve index.html for folder URLs (mimics conventional static servers).
      if (fs.existsSync(filePath) && fs.statSync(filePath).isDirectory()) {
        filePath = path.join(filePath, 'index.html');
      }
      fs.readFile(filePath, (err, data) => {
        if (err) { res.writeHead(404); res.end('not found'); return; }
        const ext = path.extname(filePath).toLowerCase();
        res.writeHead(200, { 'Content-Type': MIME[ext] || 'application/octet-stream' });
        res.end(data);
      });
    });
    server.listen(PORT, '127.0.0.1', () => resolve(server));
    server.on('error', reject);
  });
}

function listSpecFolders() {
  // Each spec lives under specs/{name}/index.html.
  // Skip names starting with underscore (e.g. _template, _authoring).
  return fs.readdirSync(SPEC_DIR)
    .filter(name => {
      if (name.startsWith('_')) return false;
      const folderPath = path.join(SPEC_DIR, name);
      if (!fs.statSync(folderPath).isDirectory()) return false;
      return fs.existsSync(path.join(folderPath, 'index.html'));
    })
    .sort();
}

async function captureAllByLocator(page, selector, outDir, baseName) {
  const items = page.locator(selector);
  const count = await items.count();
  const written = [];
  for (let i = 0; i < count; i++) {
    const suffix = baseName === 'blueprint' && i === 0
      ? 'blueprint.png'              // top-level wireframe gets unsuffixed name
      : `${baseName}_${i + 1}.png`;
    const out = path.join(outDir, suffix);
    await items.nth(i).scrollIntoViewIfNeeded();
    await items.nth(i).screenshot({ path: out });
    written.push(suffix);
  }
  return written;
}

async function renderSpec(page, folderName) {
  const folderPath = path.join(SPEC_DIR, folderName);
  const url = `http://127.0.0.1:${PORT}/specs/${folderName}/`;
  const results = { blueprints: [], visuals: [], states: [], skipped: [] };

  await page.goto(url, { waitUntil: 'networkidle', timeout: 15000 });

  // 1. Layout blueprints (top-level + sub-anatomy + atom anatomies).
  results.blueprints = await captureAllByLocator(page, '.blueprint', folderPath, 'blueprint');
  if (results.blueprints.length === 0) results.skipped.push('no .blueprint');

  // 2. Component-level visual galleries (CSS-rendered actual visuals).
  results.visuals = await captureAllByLocator(page, '.visual-gallery', folderPath, 'visual');

  // 3. Page-level state variants (each state-mini is one state).
  results.states = await captureAllByLocator(page, '.state-mini', folderPath, 'state');

  return results;
}

async function main() {
  if (!fs.existsSync(path.join(PUBLIC_DIR, 'tokens.css'))) {
    console.error('FAIL: public/tokens.css missing. Run `npm run tokens:sync` first.');
    process.exit(1);
  }

  const folders = listSpecFolders();
  if (folders.length === 0) {
    console.error('FAIL: no spec folders found under public/specs/{name}/index.html.');
    console.error('      Folder migration may not be complete yet (looking for {name}/index.html structure).');
    process.exit(1);
  }

  const server = await startServer();
  console.log(`temp server: http://127.0.0.1:${PORT}/`);

  const launchOpts = {};
  if (process.env.CHROMIUM_BIN) launchOpts.executablePath = process.env.CHROMIUM_BIN;
  const browser = await chromium.launch(launchOpts);
  const context = await browser.newContext({
    viewport: { width: 1400, height: 2400 },
    deviceScaleFactor: 2,
  });
  const page = await context.newPage();

  console.log(`렌더링 대상: ${folders.length}개 spec`);

  let blueprintTotal = 0;
  let visualTotal = 0;
  let stateTotal = 0;
  let skipCount = 0;
  const startedAt = Date.now();

  for (const folder of folders) {
    try {
      const r = await renderSpec(page, folder);
      const parts = [];
      if (r.blueprints.length) { parts.push(`blueprints=${r.blueprints.length}`); blueprintTotal += r.blueprints.length; }
      if (r.visuals.length)    { parts.push(`visuals=${r.visuals.length}`);       visualTotal += r.visuals.length; }
      if (r.states.length)     { parts.push(`states=${r.states.length}`);         stateTotal += r.states.length; }
      if (r.skipped.length)    { parts.push(`skipped=${r.skipped.join(',')}`);    skipCount++; }
      console.log(`  ✓ ${folder.padEnd(45)} ${parts.join(' · ')}`);
    } catch (err) {
      console.log(`  ✗ ${folder.padEnd(45)} ERROR: ${err.message}`);
      skipCount++;
    }
  }

  await browser.close();
  server.close();

  const elapsed = ((Date.now() - startedAt) / 1000).toFixed(1);
  console.log('');
  console.log(`완료: blueprints ${blueprintTotal}, visuals ${visualTotal}, states ${stateTotal}, skipped ${skipCount} (${elapsed}s)`);
}

main().catch(err => { console.error('FATAL:', err); process.exit(1); });
