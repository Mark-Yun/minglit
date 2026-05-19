#!/usr/bin/env -S deno run --allow-read --allow-run
// scripts/fresh-doc-lint.ts — FRESH_DOC schema + reference validator
// Usage:
//   deno run --allow-read --allow-run scripts/fresh-doc-lint.ts [FILE...]
//   deno run --allow-read --allow-run scripts/fresh-doc-lint.ts --dry-run [--today=YYYY-MM-DD] [FILE...]
//
// Exit codes: 0 = all pass, 1 = schema error, 2 = reference error

import { parse as parseYaml } from "jsr:@std/yaml@1";
import { walkSync, expandGlobSync } from "jsr:@std/fs@1";
import { join, resolve, relative, dirname } from "jsr:@std/path@1";
import { globToRegExp } from "jsr:@std/path@1/glob-to-regexp";

// ─── Types ───────────────────────────────────────────────────────────────────

interface FreshDoc {
  cycle?: unknown;
  watched_paths?: unknown;
  priority?: unknown;
  // v2 (recommended)
  target_files?: unknown;
  // v1 (deprecated, backward-compat)
  last_verified?: unknown;
  recursive?: unknown;
  exclude?: unknown;
  refresh_method?: unknown;
}

type SchemaVersion = "v1" | "v2";

function detectSchemaVersion(doc: FreshDoc): SchemaVersion | "ambiguous" | "none" {
  const hasV2 = doc.target_files !== undefined && doc.target_files !== null;
  const hasV1 = doc.last_verified !== undefined && doc.last_verified !== null;
  if (hasV2 && hasV1) return "ambiguous";
  if (hasV2) return "v2";
  if (hasV1) return "v1";
  return "none";
}

type Severity = "error" | "warning";

interface Diagnostic {
  field?: string;
  message: string;
  severity: Severity;
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

// jsr:@std/yaml@1 parses bare YAML dates (e.g. `last_verified: 2026-05-13`)
// as JavaScript Date objects. Normalize to YYYY-MM-DD string.
function normalizeDate(val: unknown): string | null {
  if (val instanceof Date) {
    const y = val.getUTCFullYear();
    const m = String(val.getUTCMonth() + 1).padStart(2, "0");
    const d = String(val.getUTCDate()).padStart(2, "0");
    return `${y}-${m}-${d}`;
  }
  return typeof val === "string" ? val : null;
}

// ─── Validation ──────────────────────────────────────────────────────────────

const PRIORITY_VALUES = ["P0-critical", "P1-high", "P2-medium", "P3-low"];
const DATE_REGEX = /^\d{4}-\d{2}-\d{2}$/;
const CYCLE_REGEX = /^\d+d$/;

function validateSchema(doc: FreshDoc): Diagnostic[] {
  const diags: Diagnostic[] = [];

  // Required: priority (both versions)
  if (doc.priority === undefined || doc.priority === null) {
    diags.push({ field: "priority", message: "required field missing", severity: "error" });
  } else if (!PRIORITY_VALUES.includes(doc.priority as string)) {
    diags.push({
      field: "priority",
      message: `invalid value '${doc.priority}' (expected: ${PRIORITY_VALUES.join(" | ")})`,
      severity: "error",
    });
  }

  // Schema version detection
  const schemaVersion = detectSchemaVersion(doc);
  if (schemaVersion === "ambiguous") {
    diags.push({
      message: "both 'target_files' (v2) and 'last_verified' (v1) specified — use exactly one schema",
      severity: "error",
    });
    return diags;
  }
  if (schemaVersion === "none") {
    diags.push({
      message: "missing schema identifier — 'target_files' (v2 required) or 'last_verified' (v1 backward-compat)",
      severity: "error",
    });
    return diags;
  }

  if (schemaVersion === "v2") {
    diags.push(...validateV2Specific(doc));
  } else {
    diags.push(...validateV1Specific(doc));
  }

  // Common: trigger exclusivity + cycle format + watched_paths shape (shared between versions)
  diags.push(...validateTriggerAndCommon(doc));

  return diags;
}

function validateV2Specific(doc: FreshDoc): Diagnostic[] {
  const diags: Diagnostic[] = [];

  // target_files: required, non-empty string array
  if (!Array.isArray(doc.target_files)) {
    diags.push({ field: "target_files", message: "must be a string array", severity: "error" });
  } else {
    const tf = doc.target_files as unknown[];
    if (tf.length === 0) {
      diags.push({ field: "target_files", message: "must be a non-empty array", severity: "error" });
    }
    for (let i = 0; i < tf.length; i++) {
      const p = tf[i];
      if (typeof p !== "string" || (p as string).trim() === "") {
        diags.push({
          field: `target_files[${i}]`,
          message: "must be a non-empty string",
          severity: "error",
        });
        continue;
      }
      const s = (p as string).trim();
      if (s.startsWith("/")) {
        diags.push({
          field: `target_files[${i}]`,
          message: `absolute path '${s}' not allowed (must be relative to FRESH_DOC location)`,
          severity: "error",
        });
      }
      if (s.includes("..")) {
        diags.push({
          field: `target_files[${i}]`,
          message: `parent traversal '..' not allowed in '${s}'`,
          severity: "error",
        });
      }
    }
  }

  // v2 must NOT use v1-only fields
  for (const f of ["last_verified", "recursive", "exclude"] as const) {
    if (doc[f] !== undefined && doc[f] !== null) {
      diags.push({
        field: f,
        message: `not allowed in v2 schema (use target_files instead)`,
        severity: "error",
      });
    }
  }

  return diags;
}

function validateV1Specific(doc: FreshDoc): Diagnostic[] {
  const diags: Diagnostic[] = [];

  // Required: last_verified — normalize Date objects produced by the YAML parser
  if (doc.last_verified === undefined || doc.last_verified === null) {
    diags.push({ field: "last_verified", message: "required field missing", severity: "error" });
  } else {
    const lv = normalizeDate(doc.last_verified);
    if (lv === null) {
      diags.push({
        field: "last_verified",
        message: `must be a date string (YYYY-MM-DD), got ${typeof doc.last_verified}`,
        severity: "error",
      });
    } else if (!DATE_REGEX.test(lv)) {
      diags.push({
        field: "last_verified",
        message: `invalid date format '${lv}' (expected: YYYY-MM-DD)`,
        severity: "error",
      });
    } else {
      const d = new Date(`${lv}T00:00:00Z`);
      if (isNaN(d.getTime())) {
        diags.push({ field: "last_verified", message: `invalid date '${lv}'`, severity: "error" });
      } else if (d > new Date()) {
        diags.push({ field: "last_verified", message: `future date '${lv}' not allowed`, severity: "error" });
      }
    }
  }

  // recursive: must be boolean if present
  if (doc.recursive !== undefined && doc.recursive !== null) {
    if (typeof doc.recursive !== "boolean") {
      diags.push({
        field: "recursive",
        message: `must be a boolean, got ${typeof doc.recursive} ('${doc.recursive}')`,
        severity: "error",
      });
    }
  }

  // exclude: must be string array if present
  if (doc.exclude !== undefined && doc.exclude !== null) {
    if (!Array.isArray(doc.exclude)) {
      diags.push({ field: "exclude", message: "must be a string array", severity: "error" });
    } else {
      for (let i = 0; i < (doc.exclude as unknown[]).length; i++) {
        if (typeof (doc.exclude as unknown[])[i] !== "string") {
          diags.push({ field: `exclude[${i}]`, message: "must be a string", severity: "error" });
        }
      }
    }
  }

  return diags;
}

function validateTriggerAndCommon(doc: FreshDoc): Diagnostic[] {
  const diags: Diagnostic[] = [];

  // Trigger exclusivity: exactly one of cycle or watched_paths
  const hasCycle = doc.cycle !== undefined && doc.cycle !== null;
  const hasWatched = doc.watched_paths !== undefined && doc.watched_paths !== null;

  if (hasCycle && hasWatched) {
    diags.push({
      field: "trigger",
      message: "both 'cycle' and 'watched_paths' specified (must be exactly one)",
      severity: "error",
    });
  } else if (!hasCycle && !hasWatched) {
    diags.push({
      field: "trigger",
      message: "neither 'cycle' nor 'watched_paths' specified (must be exactly one)",
      severity: "error",
    });
  }

  // cycle format: \d+d
  if (hasCycle) {
    const c = String(doc.cycle);
    if (!CYCLE_REGEX.test(c)) {
      diags.push({
        field: "cycle",
        message: `invalid format '${c}' (expected: \\d+d, e.g. '30d')`,
        severity: "error",
      });
    }
  }

  // watched_paths: non-empty string array
  if (hasWatched) {
    if (!Array.isArray(doc.watched_paths)) {
      diags.push({ field: "watched_paths", message: "must be a string array", severity: "error" });
    } else {
      for (let i = 0; i < (doc.watched_paths as unknown[]).length; i++) {
        const p = (doc.watched_paths as unknown[])[i];
        if (typeof p !== "string" || (p as string).trim() === "") {
          diags.push({
            field: `watched_paths[${i}]`,
            message: "must be a non-empty string",
            severity: "error",
          });
        }
      }
    }
  }

  return diags;
}

// ─── Reference Validation ─────────────────────────────────────────────────────

function validateReferences(filePath: string, doc: FreshDoc, repoRoot: string): Diagnostic[] {
  const version = detectSchemaVersion(doc);
  if (version === "v2") return validateReferencesV2(filePath, doc, repoRoot);
  return validateReferencesV1(filePath, doc, repoRoot);
}

function validateReferencesV2(filePath: string, doc: FreshDoc, repoRoot: string): Diagnostic[] {
  const diags: Diagnostic[] = [];
  const fileAbsDir = dirname(resolve(repoRoot, filePath));
  const targetGlobs = Array.isArray(doc.target_files)
    ? (doc.target_files as unknown[]).filter((p) => typeof p === "string" && (p as string).trim() !== "") as string[]
    : [];

  if (targetGlobs.length === 0) return diags; // already covered in schema validation

  // Nested FRESH_DOC boundaries (any recursive-style glob like ** could cross)
  const nestedBoundaries = new Set<string>();
  try {
    for (const entry of walkSync(fileAbsDir, { includeDirs: false })) {
      if (entry.name === "FRESH_DOC" && entry.path !== join(fileAbsDir, "FRESH_DOC")) {
        nestedBoundaries.add(dirname(entry.path));
      }
    }
  } catch { /* not readable */ }

  function isUnderNestedBoundary(absPath: string): boolean {
    let dir = dirname(absPath);
    while (dir.length > fileAbsDir.length && dir.startsWith(fileAbsDir)) {
      if (nestedBoundaries.has(dir)) return true;
      dir = dirname(dir);
    }
    return false;
  }

  let totalMatches = 0;
  for (let i = 0; i < targetGlobs.length; i++) {
    const glob = targetGlobs[i];
    let matched = 0;
    try {
      for (const entry of expandGlobSync(glob, { root: fileAbsDir, includeDirs: false })) {
        if (isUnderNestedBoundary(entry.path)) continue;
        matched++;
      }
    } catch {
      diags.push({
        field: `target_files[${i}]`,
        message: `glob expansion error for '${glob}'`,
        severity: "error",
      });
      continue;
    }
    if (matched === 0) {
      diags.push({
        field: `target_files[${i}]`,
        message: `glob '${glob}' matches no files under '${relative(repoRoot, fileAbsDir)}'`,
        severity: "warning",
      });
    }
    totalMatches += matched;
  }

  if (totalMatches === 0) {
    diags.push({
      message: `target_files matched 0 files (FRESH_DOC has no trackable target — please verify globs)`,
      severity: "error",
    });
  }

  // Check watched_paths globs match at least one file in repo (shared with v1)
  if (Array.isArray(doc.watched_paths)) {
    for (const glob of doc.watched_paths as string[]) {
      if (typeof glob !== "string" || glob.trim() === "") continue;
      let found = false;
      try {
        for (const _ of expandGlobSync(glob, { root: repoRoot, includeDirs: false })) {
          found = true;
          break;
        }
      } catch { /* glob error */ }

      if (!found) {
        diags.push({
          field: "watched_paths",
          message: `glob '${glob}' matches no files in repo`,
          severity: "error",
        });
      }
    }
  }

  return diags;
}

function validateReferencesV1(filePath: string, doc: FreshDoc, repoRoot: string): Diagnostic[] {
  const diags: Diagnostic[] = [];
  const fileAbsDir = dirname(resolve(repoRoot, filePath));
  const isRecursive = doc.recursive === true;

  const excludePatterns: string[] = Array.isArray(doc.exclude)
    ? (doc.exclude as string[]).filter((p) => typeof p === "string")
    : [];

  // When recursive, pre-collect subdirs that have their own FRESH_DOC.
  // Files under those directories are managed by the nested FRESH_DOC, not this one.
  const nestedBoundaries = new Set<string>();
  if (isRecursive) {
    try {
      for (const entry of walkSync(fileAbsDir, { includeDirs: false })) {
        if (entry.name === "FRESH_DOC" && entry.path !== join(fileAbsDir, "FRESH_DOC")) {
          nestedBoundaries.add(dirname(entry.path));
        }
      }
    } catch { /* not readable */ }
  }

  function isUnderNestedBoundary(absPath: string): boolean {
    let dir = dirname(absPath);
    while (dir.length > fileAbsDir.length && dir.startsWith(fileAbsDir)) {
      if (nestedBoundaries.has(dir)) return true;
      dir = dirname(dir);
    }
    return false;
  }

  function matchesExclude(rel: string): boolean {
    return excludePatterns.some((pat) => {
      try {
        return globToRegExp(pat, { extended: true, globstar: true }).test(rel);
      } catch {
        return false;
      }
    });
  }

  // Collect .md files — depth=1 for non-recursive, unlimited for recursive
  const walkOpts = isRecursive
    ? { exts: [".md"], includeDirs: false }
    : { maxDepth: 1, exts: [".md"], includeDirs: false };

  const mdFiles: string[] = [];
  try {
    for (const entry of walkSync(fileAbsDir, walkOpts)) {
      if (isRecursive && isUnderNestedBoundary(entry.path)) continue;
      const rel = relative(fileAbsDir, entry.path);
      if (!matchesExclude(rel)) mdFiles.push(rel);
    }
  } catch {
    // Directory not readable — skip
  }

  if (mdFiles.length === 0) {
    const relDir = relative(repoRoot, fileAbsDir);
    diags.push({
      message: `directory '${relDir}' has no .md files after exclude patterns`,
      severity: "error",
    });
  }

  // Warn on unused exclude patterns
  for (const pat of excludePatterns) {
    let anyMatch = false;
    try {
      for (const entry of walkSync(fileAbsDir, walkOpts)) {
        if (isRecursive && isUnderNestedBoundary(entry.path)) continue;
        const rel = relative(fileAbsDir, entry.path);
        if (matchesExclude(rel)) { anyMatch = true; break; }
      }
    } catch { /* ignore walk errors */ }

    if (!anyMatch) {
      diags.push({
        field: "exclude",
        message: `pattern '${pat}' matches 0 files (unused)`,
        severity: "warning",
      });
    }
  }

  // Check watched_paths globs match at least one file in repo
  if (Array.isArray(doc.watched_paths)) {
    for (const glob of doc.watched_paths as string[]) {
      if (typeof glob !== "string" || glob.trim() === "") continue;
      let found = false;
      try {
        for (const _ of expandGlobSync(glob, { root: repoRoot, includeDirs: false })) {
          found = true;
          break;
        }
      } catch { /* glob error */ }

      if (!found) {
        diags.push({
          field: "watched_paths",
          message: `glob '${glob}' matches no files in repo`,
          severity: "error",
        });
      }
    }
  }

  return diags;
}

// ─── Dry-run ──────────────────────────────────────────────────────────────────

function deriveLastVerifiedV2(filePath: string, doc: FreshDoc, repoRoot: string): Date | null {
  if (!Array.isArray(doc.target_files)) return null;
  const fileAbsDir = dirname(resolve(repoRoot, filePath));
  const globs = (doc.target_files as unknown[]).filter((p) => typeof p === "string") as string[];
  let maxTs = 0;
  for (const glob of globs) {
    let files: string[] = [];
    try {
      for (const entry of expandGlobSync(glob, { root: fileAbsDir, includeDirs: false })) {
        files.push(entry.path);
      }
    } catch { continue; }
    for (const f of files) {
      try {
        const rel = relative(repoRoot, f);
        const result = new Deno.Command("git", {
          args: ["log", "-1", "--format=%ct", "--", rel],
          cwd: repoRoot,
          stdout: "piped",
          stderr: "null",
        }).outputSync();
        const out = new TextDecoder().decode(result.stdout).trim();
        const ts = parseInt(out, 10);
        if (!isNaN(ts) && ts > maxTs) maxTs = ts;
      } catch { /* no commits or git error */ }
    }
  }
  return maxTs > 0 ? new Date(maxTs * 1000) : null;
}

function dryRunStatus(doc: FreshDoc, today: Date, repoRoot: string, filePath?: string): string {
  const hasCycle = typeof doc.cycle === "string" && CYCLE_REGEX.test(doc.cycle);
  const hasWatched = Array.isArray(doc.watched_paths);
  const version = detectSchemaVersion(doc);

  let lastVerified: Date;
  let lvStr: string;
  if (version === "v2" && filePath) {
    const derived = deriveLastVerifiedV2(filePath, doc, repoRoot);
    if (!derived) return `UNKNOWN (v2 target_files have no git history)`;
    lastVerified = derived;
    lvStr = lastVerified.toISOString().split("T")[0];
  } else {
    const v1Str = normalizeDate(doc.last_verified);
    if (!v1Str) return `UNKNOWN (invalid last_verified)`;
    lvStr = v1Str;
    lastVerified = new Date(`${v1Str}T00:00:00Z`);
  }

  if (isNaN(lastVerified.getTime())) return `UNKNOWN (invalid last_verified)`;

  if (hasCycle) {
    const days = parseInt((doc.cycle as string).replace("d", ""), 10);
    const staleSince = new Date(lastVerified.getTime() + days * 86400_000);
    const elapsed = Math.floor((today.getTime() - lastVerified.getTime()) / 86400_000);
    if (today >= staleSince) {
      return `STALE (cycle ${doc.cycle}, ${elapsed}d elapsed)`;
    }
    const remaining = Math.floor((staleSince.getTime() - today.getTime()) / 86400_000);
    return `FRESH (cycle ${doc.cycle}, ${remaining}d remaining)`;
  }

  if (hasWatched) {
    const paths = (doc.watched_paths as string[]).filter((p) => typeof p === "string");
    try {
      const since = lastVerified.toISOString().split("T")[0];
      const result = new Deno.Command("git", {
        args: ["log", "--oneline", "--after", since, "--", ...paths],
        cwd: repoRoot,
        stdout: "piped",
        stderr: "null",
      }).outputSync();
      const out = new TextDecoder().decode(result.stdout).trim();
      if (out.length > 0) {
        const count = out.split("\n").length;
        return `STALE (watched_paths, ${count} commit${count > 1 ? "s" : ""} since ${lvStr})`;
      }
      return `FRESH (watched_paths, no commits since ${lvStr})`;
    } catch {
      return `UNKNOWN (git error)`;
    }
  }

  return `UNKNOWN (no valid trigger)`;
}

// ─── File discovery ───────────────────────────────────────────────────────────

function findFreshDocFiles(repoRoot: string): string[] {
  const files: string[] = [];
  for (const entry of walkSync(repoRoot, { includeDirs: false, skip: [/\.git/, /node_modules/, /\.claude/, /tests[/\\]doc-freshness[/\\]fixtures/] })) {
    if (entry.name === "FRESH_DOC") {
      files.push(relative(repoRoot, entry.path));
    }
  }
  return files.sort();
}

// ─── Main ─────────────────────────────────────────────────────────────────────

async function main(): Promise<void> {
  const args = Deno.args.slice();
  const isDryRun = args.includes("--dry-run");
  const todayArg = args.find((a) => a.startsWith("--today="));
  const today = todayArg ? new Date(`${todayArg.replace("--today=", "")}T00:00:00Z`) : new Date();
  const fileArgs = args.filter((a) => !a.startsWith("--"));

  const repoRoot = resolve(Deno.cwd());
  const files = fileArgs.length > 0
    ? fileArgs.map((f) => relative(repoRoot, resolve(repoRoot, f)))
    : findFreshDocFiles(repoRoot);

  let schemaError = false;
  let refError = false;

  for (const filePath of files) {
    const absPath = join(repoRoot, filePath);
    let raw: string;
    try {
      raw = await Deno.readTextFile(absPath);
    } catch (e) {
      console.error(`${filePath}: cannot read file: ${e}`);
      schemaError = true;
      continue;
    }

    let doc: FreshDoc;
    try {
      const parsed = parseYaml(raw);
      if (parsed === null || typeof parsed !== "object" || Array.isArray(parsed)) {
        console.error(`${filePath}: not a YAML mapping`);
        schemaError = true;
        continue;
      }
      doc = parsed as FreshDoc;
    } catch (e) {
      console.error(`${filePath}: YAML parse error: ${e}`);
      schemaError = true;
      continue;
    }

    const schemaDiags = validateSchema(doc);
    const hasSchemaErrors = schemaDiags.some((d) => d.severity === "error");

    // Skip reference validation if schema is invalid
    const refDiags = hasSchemaErrors ? [] : validateReferences(filePath, doc, repoRoot);
    const allDiags = [...schemaDiags, ...refDiags];

    if (allDiags.length === 0) {
      if (isDryRun) {
        const status = dryRunStatus(doc, today, repoRoot, filePath);
        console.log(`${filePath}: ${status}`);
      } else {
        console.log(`${filePath}: OK`);
      }
      continue;
    }

    for (const d of allDiags) {
      const loc = d.field ? `${filePath}: ${d.field}` : filePath;
      console.log(`${loc}: ${d.severity}: ${d.message}`);
      if (d.severity === "error") {
        if (schemaDiags.includes(d)) schemaError = true;
        else refError = true;
      }
    }
  }

  if (schemaError) Deno.exit(1);
  if (refError) Deno.exit(2);
}

await main();
