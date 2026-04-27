/**
 * Style Dictionary v4 configuration for mds_tokens.
 *
 * Reads tokens/**\/*.json (W3C Design Tokens format) and generates:
 *   lib/generated/tokens.g.dart — Dart const class MdsTokens
 *
 * Run: npm run build
 */

import StyleDictionary from 'style-dictionary';

// ---------------------------------------------------------------------------
// Helper: convert a hex color string to a Dart 0xAARRGGBB int literal.
// Supports: #RRGGBB  and  #RRGGBBAA (CSS alpha-last).
// ---------------------------------------------------------------------------
function hexToDartColor(hex) {
  const clean = hex.replace('#', '');
  if (clean.length === 6) {
    // #RRGGBB → 0xFFRRGGBB (fully opaque)
    return `0xFF${clean.toUpperCase()}`;
  }
  if (clean.length === 8) {
    // Style Dictionary stores as RRGGBBAA (CSS convention).
    // Dart Color() expects 0xAARRGGBB.
    const rr = clean.slice(0, 2);
    const gg = clean.slice(2, 4);
    const bb = clean.slice(4, 6);
    const aa = clean.slice(6, 8);
    return `0x${(aa + rr + gg + bb).toUpperCase()}`;
  }
  return `/* unrecognised hex: ${hex} */ 0x00000000`;
}

// ---------------------------------------------------------------------------
// Helper: build a camelCase const name from a token path array.
// e.g. ['color', 'dark', 'primary'] → 'colorDarkPrimary'
// ---------------------------------------------------------------------------
function toCamelCase(pathParts) {
  return pathParts
    .map((part, i) => (i === 0 ? part : part.charAt(0).toUpperCase() + part.slice(1)))
    .join('');
}

// ---------------------------------------------------------------------------
// Custom name transform — preserve raw camelCase from path, ignore SD name.
// ---------------------------------------------------------------------------
StyleDictionary.registerTransform({
  name: 'name/dart/camelCase',
  type: 'name',
  transform: (token) => toCamelCase(token.path),
});

// ---------------------------------------------------------------------------
// Custom value transform — emit raw numeric value for dimensions/sizes.
// Without this the default 'js' transform converts numbers to "Npx" strings.
// ---------------------------------------------------------------------------
StyleDictionary.registerTransform({
  name: 'value/dart/passthrough',
  type: 'value',
  filter: (token) => {
    const type = token.$type ?? token.type ?? '';
    return type === 'dimension' || type === 'size' || type === 'fontWeight' || type === 'fontFamily';
  },
  transform: (token) => token.$value ?? token.value,
});

// ---------------------------------------------------------------------------
// Custom transform group combining our transforms.
// ---------------------------------------------------------------------------
StyleDictionary.registerTransformGroup({
  name: 'dart',
  transforms: ['name/dart/camelCase', 'value/dart/passthrough'],
});

// ---------------------------------------------------------------------------
// Custom CSS dimension transform — emit raw px instead of rem.
// Default `size/rem` transform appends 'rem' without dividing by 16, producing
// huge values (e.g. 16 → '16rem' = 256px). For a design system, fixed px
// matches the Dart side and is what the docs site needs.
// ---------------------------------------------------------------------------
StyleDictionary.registerTransform({
  name: 'size/css/px',
  type: 'value',
  filter: (token) => {
    const type = token.$type ?? token.type ?? '';
    return type === 'dimension' || type === 'size';
  },
  transform: (token) => {
    const raw = token.$value ?? token.value;
    const num = Number(raw);
    if (Number.isNaN(num) || num === 0) return '0';
    return `${num}px`;
  },
});

StyleDictionary.registerTransformGroup({
  name: 'css-px',
  transforms: [
    'attribute/cti',
    'name/kebab',
    'time/seconds',
    'html/icon',
    'size/css/px',
    'color/css',
    'asset/url',
    'fontFamily/css',
    'cubicBezier/css',
    'strokeStyle/css/shorthand',
    'border/css/shorthand',
    'typography/css/shorthand',
    'transition/css/shorthand',
    'shadow/css/shorthand',
  ],
});

// ---------------------------------------------------------------------------
// Custom Dart format
// ---------------------------------------------------------------------------
StyleDictionary.registerFormat({
  name: 'dart/class',
  format: ({ dictionary }) => {
    const lines = [];
    lines.push('// GENERATED FILE — DO NOT EDIT.');
    lines.push('// Re-generate by running: npm run build (inside shared/packages/mds_tokens/)');
    lines.push('// Source: tokens/**/*.json (W3C Design Tokens format)');
    lines.push('//');
    lines.push('// ignore_for_file: lines_longer_than_80_chars, constant_identifier_names');
    lines.push('');
    lines.push('// ignore: avoid_classes_with_only_static_members');
    lines.push('class MdsTokens {');
    lines.push('  MdsTokens._();');
    lines.push('');

    for (const token of dictionary.allTokens) {
      const name = token.name; // already transformed by name/dart/camelCase
      const type = token.$type ?? token.type ?? '';
      const rawValue = token.$value ?? token.value;
      const description = token.$description ?? token.comment ?? '';

      let dartType;
      let dartValue;

      if (type === 'color') {
        dartType = 'int';
        dartValue = hexToDartColor(String(rawValue));
      } else if (type === 'dimension' || type === 'size') {
        dartType = 'double';
        const num = Number(rawValue);
        dartValue = `${num}.0`;
      } else if (type === 'fontFamily') {
        dartType = 'String';
        dartValue = `'${rawValue}'`;
      } else if (type === 'fontWeight') {
        dartType = 'int';
        dartValue = String(rawValue);
      } else {
        dartType = 'String';
        dartValue = `'${rawValue}'`;
      }

      if (description) {
        lines.push(`  /// ${description}`);
      }
      lines.push(`  static const ${dartType} ${name} = ${dartValue};`);
      lines.push('');
    }

    lines.push('}');
    lines.push('');
    return lines.join('\n');
  },
});

// ---------------------------------------------------------------------------
// Style Dictionary configuration
// ---------------------------------------------------------------------------
export default {
  source: ['tokens/**/*.json'],
  platforms: {
    dart: {
      transformGroup: 'dart',
      buildPath: 'lib/generated/',
      files: [
        {
          destination: 'tokens.g.dart',
          format: 'dart/class',
        },
      ],
    },
    css: {
      transformGroup: 'css-px',
      buildPath: 'lib/generated/',
      files: [
        {
          destination: 'tokens.css',
          format: 'css/variables',
          options: { selector: ':root' },
        },
      ],
    },
  },
};
