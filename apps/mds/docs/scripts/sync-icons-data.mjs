#!/usr/bin/env node
// Regenerates src/lib/mds-icons-data.ts from the monorepo source.
// Run from apps/mds/docs/: npm run icons:sync-data
import { readFileSync, writeFileSync } from 'fs';
import { resolve, dirname } from 'path';
import { fileURLToPath } from 'url';

const __dir = dirname(fileURLToPath(import.meta.url));
const ROOT = resolve(__dir, '../../../..');
const MANIFEST = resolve(ROOT, 'shared/packages/mds/icons/manifest.json');
const ICONS_DIR = resolve(ROOT, 'shared/packages/mds/icons/icons');
const OUT = resolve(__dir, '../src/lib/mds-icons-data.ts');

const entries = JSON.parse(readFileSync(MANIFEST, 'utf-8'));

const lines = [
  '// Auto-generated — do NOT edit manually.',
  '// To regenerate: npm run icons:sync-data (node scripts/sync-icons-data.mjs)',
  '// Source: shared/packages/mds/icons/manifest.json + icons/*.svg',
  '',
  'export interface IconEntry {',
  '  name: string;',
  '  camel: string;',
  '  viewBox: string;',
  '  svgContent: string;',
  '}',
  '',
  'export const MDS_ICONS_DATA: IconEntry[] = [',
];

for (const entry of entries) {
  const svg = readFileSync(resolve(ICONS_DIR, `${entry.name}.svg`), 'utf-8').trimEnd();
  lines.push(`  {`);
  lines.push(`    name: '${entry.name}',`);
  lines.push(`    camel: '${entry.camel}',`);
  lines.push(`    viewBox: '${entry.viewBox}',`);
  lines.push(`    svgContent: \`${svg}\`,`);
  lines.push(`  },`);
}

lines.push('];', '');
writeFileSync(OUT, lines.join('\n'));
console.log(`✓ mds-icons-data.ts updated (${entries.length} icons)`);
