#!/usr/bin/env node
/**
 * Render MDS spec assets (PNGs + index.md per spec folder).
 *
 * For each spec under `public/specs/{name}/index.html`:
 *
 *   1. PNG mockups (headless chromium):
 *      - blueprint.png, blueprint_2.png ...   ← .blueprint elements (wireframes, document order)
 *      - visual_1.png, visual_2.png ...       ← .visual-gallery (CSS-rendered components)
 *      - state_1.png, state_2.png ...         ← .state-mini__mock .viewport (state mockups, viewport only)
 *
 *   2. index.md (textual representation for AI workers, ~7x token reduction vs HTML):
 *      - Headings, tables, code, links preserved (turndown)
 *      - Visual elements replaced with MD image refs (relative paths in same folder)
 *      - State sections: heading + ![state](state_N.png) + meta table
 *      - Toolbar / scripts / styles stripped
 *
 * Worker access pattern:
 *   - Cheap text pass: read index.md (~13KB, structured content + image refs)
 *   - Vision pass: selectively Read referenced PNGs only when visual diff needed
 *
 * Usage:
 *   npm run tokens:sync
 *   node scripts/render-spec-mockups.js
 */

const http = require('http');
const fs = require('fs');
const path = require('path');
const { chromium } = require('playwright');
const TurndownService = require('turndown');

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
  return fs.readdirSync(SPEC_DIR)
    .filter(name => {
      if (name.startsWith('_')) return false;
      const folderPath = path.join(SPEC_DIR, name);
      if (!fs.statSync(folderPath).isDirectory()) return false;
      return fs.existsSync(path.join(folderPath, 'index.html'));
    })
    .sort();
}

// ────────────────────────────────────────────────────────────
// PNG capture
// ────────────────────────────────────────────────────────────

async function capturePngs(page, folderPath) {
  const result = { blueprints: [], visuals: [], states: [] };

  const blueprints = page.locator('.blueprint');
  const bpCount = await blueprints.count();
  for (let i = 0; i < bpCount; i++) {
    const file = i === 0 ? 'blueprint.png' : `blueprint_${i + 1}.png`;
    const out = path.join(folderPath, file);
    await blueprints.nth(i).scrollIntoViewIfNeeded();
    await blueprints.nth(i).screenshot({ path: out });
    result.blueprints.push(file);
  }

  const galleries = page.locator('.visual-gallery');
  const vgCount = await galleries.count();
  for (let i = 0; i < vgCount; i++) {
    const file = `visual_${i + 1}.png`;
    const out = path.join(folderPath, file);
    await galleries.nth(i).scrollIntoViewIfNeeded();
    await galleries.nth(i).screenshot({ path: out });
    result.visuals.push(file);
  }

  // State mockup viewport only (metadata text goes in MD, not in PNG)
  const states = page.locator('.state-mini');
  const stateCount = await states.count();
  for (let i = 0; i < stateCount; i++) {
    const file = `state_${i + 1}.png`;
    const out = path.join(folderPath, file);
    const viewport = states.nth(i).locator('.state-mini__mock .viewport, .state-mini__mock').first();
    if (await viewport.count() === 0) continue;
    await viewport.scrollIntoViewIfNeeded();
    await viewport.screenshot({ path: out });
    result.states.push(file);
  }

  return result;
}

// ────────────────────────────────────────────────────────────
// Markdown generation (turndown with custom rules)
// ────────────────────────────────────────────────────────────

// Turndown's DOM (htmlparser2-based) doesn't expose classList. Use getAttribute.
function hasClass(node, className) {
  const cls = node.getAttribute && node.getAttribute('class');
  if (!cls) return false;
  return cls.split(/\s+/).includes(className);
}

function makeTurndown() {
  const td = new TurndownService({
    headingStyle: 'atx',
    codeBlockStyle: 'fenced',
    bulletListMarker: '-',
  });

  td.remove(['style', 'script', 'meta', 'link']);

  td.addRule('skipToolbar', {
    filter: (node) => hasClass(node, 'toolbar') || hasClass(node, 'perspective__nav'),
    replacement: () => '',
  });

  // Counters maintained across rules — must match capture order exactly.
  const counters = { blueprint: 0, visual: 0, state: 0 };

  td.addRule('blueprintImg', {
    filter: (node) =>
      hasClass(node, 'blueprint') &&
      !hasClass(node, 'blueprint__region') &&
      !hasClass(node, 'blueprint__align-marker'),
    replacement: () => {
      counters.blueprint++;
      const file = counters.blueprint === 1 ? 'blueprint.png' : `blueprint_${counters.blueprint}.png`;
      return `\n\n![blueprint](${file})\n\n`;
    },
  });

  td.addRule('visualImg', {
    filter: (node) => hasClass(node, 'visual-gallery'),
    replacement: () => {
      counters.visual++;
      return `\n\n![visual](visual_${counters.visual}.png)\n\n`;
    },
  });

  td.addRule('stateMini', {
    filter: (node) => node.nodeName === 'TABLE' && hasClass(node, 'state-mini'),
    replacement: (content, node) => {
      counters.state++;
      const stateNum = counters.state;

      const headingEl = node.querySelector('thead th');
      const heading = headingEl
        ? headingEl.textContent.replace(/\s+/g, ' ').trim()
        : `State ${stateNum}`;

      const rows = Array.from(node.querySelectorAll('tbody tr'));
      const lines = [];
      rows.forEach(row => {
        const cells = Array.from(row.querySelectorAll('td')).filter(td =>
          !hasClass(td, 'state-mini__mock')
        );
        if (cells.length >= 2) {
          const label = cells[0].textContent.replace(/\s+/g, ' ').trim();
          const value = cells[1].textContent.replace(/\s+/g, ' ').replace(/\|/g, '\\|').trim();
          lines.push(`| ${label} | ${value} |`);
        }
      });

      const metaTable = lines.length
        ? `| 항목 | 내용 |\n|---|---|\n${lines.join('\n')}`
        : '_(no metadata)_';

      return `\n\n### ${heading}\n\n![state](state_${stateNum}.png)\n\n${metaTable}\n\n`;
    },
  });

  td.addRule('genericTable', {
    filter: (node) => node.nodeName === 'TABLE' && !hasClass(node, 'state-mini'),
    replacement: (content, node) => {
      const rows = Array.from(node.querySelectorAll('tr'));
      if (rows.length === 0) return '';
      const md = [];
      rows.forEach((row, idx) => {
        const cells = Array.from(row.querySelectorAll('th, td')).map(c =>
          c.textContent.replace(/\s+/g, ' ').replace(/\|/g, '\\|').trim()
        );
        md.push('| ' + cells.join(' | ') + ' |');
        if (idx === 0) md.push('|' + cells.map(() => '---').join('|') + '|');
      });
      return '\n\n' + md.join('\n') + '\n\n';
    },
  });

  return td;
}

function generateMd(folderPath, htmlPath) {
  const html = fs.readFileSync(htmlPath, 'utf8');
  const td = makeTurndown();
  const md = td.turndown(html);
  const out = path.join(folderPath, 'index.md');
  fs.writeFileSync(out, md);
  return { file: 'index.md', size: md.length };
}

// ────────────────────────────────────────────────────────────
// Main
// ────────────────────────────────────────────────────────────

async function renderSpec(page, folderName) {
  const folderPath = path.join(SPEC_DIR, folderName);
  const htmlPath = path.join(folderPath, 'index.html');
  const url = `http://127.0.0.1:${PORT}/specs/${folderName}/`;

  await page.goto(url, { waitUntil: 'networkidle', timeout: 15000 });

  const pngs = await capturePngs(page, folderPath);
  const md = generateMd(folderPath, htmlPath);

  return { ...pngs, md };
}

async function main() {
  if (!fs.existsSync(path.join(PUBLIC_DIR, 'tokens.css'))) {
    console.error('FAIL: public/tokens.css missing. Run `npm run tokens:sync` first.');
    process.exit(1);
  }

  const folders = listSpecFolders();
  if (folders.length === 0) {
    console.error('FAIL: no spec folders under public/specs/{name}/index.html.');
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

  let bpTotal = 0, vTotal = 0, sTotal = 0, mdTotal = 0, skipCount = 0;
  const startedAt = Date.now();

  for (const folder of folders) {
    try {
      const r = await renderSpec(page, folder);
      const parts = [];
      if (r.blueprints.length) { parts.push(`bp=${r.blueprints.length}`); bpTotal += r.blueprints.length; }
      if (r.visuals.length)    { parts.push(`v=${r.visuals.length}`);     vTotal += r.visuals.length; }
      if (r.states.length)     { parts.push(`s=${r.states.length}`);      sTotal += r.states.length; }
      parts.push(`md=${(r.md.size/1024).toFixed(1)}KB`); mdTotal += r.md.size;
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
  console.log(`완료: blueprints ${bpTotal}, visuals ${vTotal}, states ${sTotal}, md ${(mdTotal/1024).toFixed(1)}KB total, skipped ${skipCount} (${elapsed}s)`);
}

main().catch(err => { console.error('FATAL:', err); process.exit(1); });
