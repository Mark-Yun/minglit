/**
 * mds_icons codegen script.
 *
 * 1. Reads icons/*.svg
 * 2. Optimises each with svgo (currentColor substitution for theme awareness)
 * 3. Writes lib/generated/icons.g.dart — class MdsIcons with static SvgPicture accessors
 * 4. Writes react/src/generated/index.tsx — React components per icon
 * 5. Writes manifest.json — icon metadata for mds_docs /icons page
 *
 * Run: npm run build  (inside shared/packages/mds/icons/)
 */

import { readdir, readFile, writeFile, mkdir } from 'fs/promises';
import { join, basename } from 'path';
import { fileURLToPath } from 'url';
import { dirname } from 'path';
import { optimize } from 'svgo';

const __dirname = dirname(fileURLToPath(import.meta.url));
const PKG_ROOT = join(__dirname, '..');
const ICONS_DIR = join(PKG_ROOT, 'icons');
const DART_OUT_DIR = join(PKG_ROOT, 'lib', 'generated');
const REACT_OUT_DIR = join(PKG_ROOT, 'react', 'src', 'generated');
const MANIFEST_PATH = join(PKG_ROOT, 'manifest.json');

// ---------------------------------------------------------------------------
// svgo config: strip metadata, preserve viewBox, convert all colors to
// currentColor so Flutter's ColorFilter can recolour the icon at runtime.
// ---------------------------------------------------------------------------
const svgoConfig = {
  plugins: [
    {
      name: 'preset-default',
      params: { overrides: { removeViewBox: false } },
    },
    {
      name: 'convertColors',
      params: { currentColor: true },
    },
    'removeDimensions',
  ],
};

// ---------------------------------------------------------------------------
// snake_case → lowerCamelCase  (e.g. "arrow_back" → "arrowBack")
// ---------------------------------------------------------------------------
function toCamel(name) {
  return name.replace(/_([a-z])/g, (_, c) => c.toUpperCase());
}

// snake_case → PascalCase (e.g. "arrow_back" → "ArrowBack")
function toPascal(name) {
  const camel = toCamel(name);
  return camel.charAt(0).toUpperCase() + camel.slice(1);
}

// Convert SVG attribute names to React JSX (kebab-case → camelCase),
// and quote attribute values for JSX. Returns the inner SVG body
// (everything between <svg ...> and </svg>) ready for JSX embedding.
function svgInnerToJsx(svgString) {
  const inner = svgString
    .replace(/<\?xml[^?]*\?>/g, '')
    .replace(/<svg[^>]*>/, '')
    .replace(/<\/svg>/, '')
    .trim();
  return inner.replace(/([a-z]+)-([a-z])/g, (_, a, b) => a + b.toUpperCase());
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------
const files = (await readdir(ICONS_DIR)).filter((f) => f.endsWith('.svg'));
files.sort();

if (files.length === 0) {
  console.error('No SVG files found in', ICONS_DIR);
  process.exit(1);
}

const manifest = [];
const dartLines = [];
const reactLines = [];

reactLines.push('// GENERATED FILE — DO NOT EDIT.');
reactLines.push(
  '// Re-generate by running: npm run build (inside shared/packages/mds/icons/)',
);
reactLines.push(
  '// Source: icons/*.svg (svgo-optimised, currentColor for theme awareness)',
);
reactLines.push('');
reactLines.push("import * as React from 'react';");
reactLines.push('');
reactLines.push("export interface MdsIconProps extends React.SVGProps<SVGSVGElement> {");
reactLines.push("  size?: number | string;");
reactLines.push('}');
reactLines.push('');

dartLines.push('// GENERATED FILE — DO NOT EDIT.');
dartLines.push(
  '// Re-generate by running: npm run build (inside shared/packages/mds/icons/)',
);
dartLines.push(
  '// Source: icons/*.svg (svgo-optimised, currentColor for theme awareness)',
);
dartLines.push('//');
dartLines.push(
  '// ignore_for_file: lines_longer_than_80_chars, constant_identifier_names',
);
dartLines.push('');
dartLines.push("import 'package:flutter/widgets.dart';");
dartLines.push("import 'package:flutter_svg/flutter_svg.dart';");
dartLines.push('');
dartLines.push('// ignore: avoid_classes_with_only_static_members');
dartLines.push('class MdsIcons {');
dartLines.push('  MdsIcons._();');
dartLines.push('');

const reactExports = [];

for (const file of files) {
  const name = basename(file, '.svg'); // e.g. "chevron_right"
  const camel = toCamel(name); // e.g. "chevronRight"
  const pascal = toPascal(name); // e.g. "ChevronRight"

  const raw = await readFile(join(ICONS_DIR, file), 'utf8');
  const result = optimize(raw, svgoConfig);
  const optimized = result.data;

  // Extract viewBox for manifest
  const viewBoxMatch = optimized.match(/viewBox="([^"]+)"/);
  const viewBox = viewBoxMatch ? viewBoxMatch[1] : '0 0 24 24';

  manifest.push({ name, camel, pascal, viewBox });

  // ---------- React component ----------
  const jsxInner = svgInnerToJsx(optimized);
  reactLines.push(`/** ${name} icon. Inherits color via currentColor. */`);
  reactLines.push(`export const ${pascal}: React.FC<MdsIconProps> = ({ size = 24, ...props }) => (`);
  reactLines.push(`  <svg`);
  reactLines.push(`    width={size}`);
  reactLines.push(`    height={size}`);
  reactLines.push(`    viewBox="${viewBox}"`);
  reactLines.push(`    fill="none"`);
  reactLines.push(`    stroke="currentColor"`);
  reactLines.push(`    strokeWidth={2}`);
  reactLines.push(`    strokeLinecap="round"`);
  reactLines.push(`    strokeLinejoin="round"`);
  reactLines.push(`    aria-hidden="true"`);
  reactLines.push(`    {...props}`);
  reactLines.push(`  >`);
  reactLines.push(`    ${jsxInner}`);
  reactLines.push(`  </svg>`);
  reactLines.push(`);`);
  reactLines.push('');
  reactExports.push(pascal);

  // Escape SVG string for embedding in a Dart single-quoted string literal.
  const escaped = optimized
    .replace(/\\/g, '\\\\')
    .replace(/'/g, "\\'")
    .replace(/\$/g, '\\$');

  dartLines.push(`  // ---------------------------------------------------------------------------`);
  dartLines.push(`  // ${name}`);
  dartLines.push(`  // ---------------------------------------------------------------------------`);
  dartLines.push('');
  dartLines.push(`  static const String _${camel}Svg =`);
  // Split into ≤120-char chunks to keep lines manageable.
  // For simplicity emit as a single string — the ignore_for_file directive above
  // suppresses the lines_longer_than_80_chars lint.
  dartLines.push(`      '${escaped}';`);
  dartLines.push('');
  dartLines.push(`  /// ${name} icon (Lucide SVG, currentColor).`);
  dartLines.push(`  ///`);
  dartLines.push(
    `  /// Inherits [IconTheme] for color and size when not overridden,`,
  );
  dartLines.push(
    `  /// matching the behavior of Material's [Icon] widget.`,
  );
  dartLines.push(
    `  static Widget ${camel}({double? size, Color? color}) {`,
  );
  dartLines.push(`    return Builder(`);
  dartLines.push(`      builder: (context) {`);
  dartLines.push(
    `        final iconTheme = IconTheme.of(context);`,
  );
  dartLines.push(
    `        final effectiveSize = size ?? iconTheme.size ?? 24.0;`,
  );
  dartLines.push(
    `        final effectiveColor =`,
  );
  dartLines.push(
    `            color ?? iconTheme.color ?? const Color(0xFF000000);`,
  );
  dartLines.push(`        return SvgPicture.string(`);
  dartLines.push(`          _${camel}Svg,`);
  dartLines.push(`          width: effectiveSize,`);
  dartLines.push(`          height: effectiveSize,`);
  dartLines.push(
    `          colorFilter:`,
  );
  dartLines.push(
    `              ColorFilter.mode(effectiveColor, BlendMode.srcIn),`,
  );
  dartLines.push(`        );`);
  dartLines.push(`      },`);
  dartLines.push(`    );`);
  dartLines.push(`  }`);
  dartLines.push('');
}

dartLines.push('}');
dartLines.push('');

// React: also emit a registry object for dynamic lookup
reactLines.push('/** Registry of all icons keyed by snake_case name. */');
reactLines.push('export const MdsIcons = {');
for (const file of files) {
  const name = basename(file, '.svg');
  const pascal = toPascal(name);
  reactLines.push(`  '${name}': ${pascal},`);
}
reactLines.push('} as const;');
reactLines.push('');
reactLines.push('export type MdsIconName = keyof typeof MdsIcons;');
reactLines.push('');

await mkdir(DART_OUT_DIR, { recursive: true });
await mkdir(REACT_OUT_DIR, { recursive: true });
await writeFile(join(DART_OUT_DIR, 'icons.g.dart'), dartLines.join('\n'), 'utf8');
await writeFile(join(REACT_OUT_DIR, 'index.tsx'), reactLines.join('\n'), 'utf8');
await writeFile(
  MANIFEST_PATH,
  JSON.stringify(manifest, null, 2) + '\n',
  'utf8',
);

console.log(
  `Generated ${files.length} icons →\n  lib/generated/icons.g.dart\n  react/src/generated/index.tsx\n  manifest.json`,
);
