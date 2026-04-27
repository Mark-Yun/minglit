import fs from 'fs';
import path from 'path';

// ---------------------------------------------------------------------------
// W3C Design Token types
// ---------------------------------------------------------------------------
interface W3CToken {
  $value: string | number;
  $type: string;
  $description?: string;
  [key: string]: unknown;
}

interface TokenGroup {
  [key: string]: W3CToken | TokenGroup;
}

// ---------------------------------------------------------------------------
// Parsed token shapes
// ---------------------------------------------------------------------------
export interface ColorToken {
  name: string;          // e.g. "color-primary"
  cssVar: string;        // e.g. "--color-primary"
  dartName: string;      // e.g. "MdsTokens.colorPrimary"
  hex: string;
  description: string;
  group: 'semantic' | 'dark' | 'partner';
}

export interface SpacingToken {
  name: string;
  cssVar: string;
  value: number;
  description: string;
}

export interface RadiusToken {
  name: string;
  cssVar: string;
  value: number;
  description: string;
}

export interface TypographyToken {
  name: string;
  cssVar: string;
  value: string | number;
  type: 'fontFamily' | 'fontSize' | 'fontWeight';
  description: string;
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------
function toCssVar(path: string[]): string {
  return '--' + path.map(p => p.replace(/([A-Z])/g, '-$1').toLowerCase()).join('-');
}

function toDartName(path: string[]): string {
  return path
    .map((p, i) => (i === 0 ? p : p.charAt(0).toUpperCase() + p.slice(1)))
    .join('');
}

function toKebabName(path: string[]): string {
  return path.map(p => p.replace(/([A-Z])/g, '-$1').toLowerCase()).join('-');
}

function isW3CToken(obj: unknown): obj is W3CToken {
  return (
    typeof obj === 'object' &&
    obj !== null &&
    '$value' in obj &&
    '$type' in obj
  );
}

function flattenTokens(
  obj: TokenGroup,
  prefix: string[] = []
): Array<{ path: string[]; token: W3CToken }> {
  const results: Array<{ path: string[]; token: W3CToken }> = [];
  for (const [key, value] of Object.entries(obj)) {
    if (isW3CToken(value)) {
      results.push({ path: [...prefix, key], token: value });
    } else {
      results.push(...flattenTokens(value as TokenGroup, [...prefix, key]));
    }
  }
  return results;
}

// ---------------------------------------------------------------------------
// Token directory — resolved relative to repo root from mds/docs
// ---------------------------------------------------------------------------
const TOKEN_DIR = path.resolve(
  process.cwd(),
  '../../../shared/packages/mds/tokens/tokens'
);

function readTokenFile(filename: string): TokenGroup {
  const filePath = path.join(TOKEN_DIR, filename);
  const raw = fs.readFileSync(filePath, 'utf-8');
  return JSON.parse(raw) as TokenGroup;
}

// ---------------------------------------------------------------------------
// Color tokens
// ---------------------------------------------------------------------------
export function getColorTokens(): ColorToken[] {
  const data = readTokenFile('color.json');
  const flat = flattenTokens(data);

  return flat.map(({ path, token }) => {
    const cssVar = toCssVar(path);
    const dartName = 'MdsTokens.' + toDartName(path);

    // Determine group by path structure
    let group: ColorToken['group'] = 'semantic';
    if (path.includes('dark') && path[0] === 'color') group = 'dark';
    if (path.includes('partner')) group = 'partner';

    return {
      name: toKebabName(path),
      cssVar,
      dartName,
      hex: String(token.$value),
      description: token.$description ?? '',
      group,
    };
  });
}

// ---------------------------------------------------------------------------
// Spacing tokens
// ---------------------------------------------------------------------------
export function getSpacingTokens(): SpacingToken[] {
  const data = readTokenFile('spacing.json');
  const flat = flattenTokens(data);

  return flat.map(({ path, token }) => ({
    name: toKebabName(path),
    cssVar: toCssVar(path),
    value: Number(token.$value),
    description: token.$description ?? '',
  }));
}

// ---------------------------------------------------------------------------
// Radius tokens
// ---------------------------------------------------------------------------
export function getRadiusTokens(): RadiusToken[] {
  const data = readTokenFile('radius.json');
  const flat = flattenTokens(data);

  return flat.map(({ path, token }) => ({
    name: toKebabName(path),
    cssVar: toCssVar(path),
    value: Number(token.$value),
    description: token.$description ?? '',
  }));
}

// ---------------------------------------------------------------------------
// Typography tokens
// ---------------------------------------------------------------------------
export function getTypographyTokens(): TypographyToken[] {
  const data = readTokenFile('typography.json');
  const flat = flattenTokens(data);

  return flat.map(({ path, token }) => ({
    name: toKebabName(path),
    cssVar: toCssVar(path),
    value: token.$value,
    type: token.$type as TypographyToken['type'],
    description: token.$description ?? '',
  }));
}
