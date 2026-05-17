// scripts/__tests__/fresh-doc-lint.test.ts — unit tests for fresh-doc-lint.ts validator logic

import { assertEquals } from "jsr:@std/assert@1";

// ─── Import validator internals via dynamic import (run as module) ────────────
// Since fresh-doc-lint.ts has a main() that calls Deno.exit(), we test
// the validation logic by running the script as a subprocess.

const LINT_SCRIPT = new URL("../fresh-doc-lint.ts", import.meta.url).pathname;
const REPO_ROOT = new URL("../../", import.meta.url).pathname.replace(/\/$/, "");
const FIXTURES = `${REPO_ROOT}/tests/doc-freshness/fixtures`;

async function runLint(args: string[]): Promise<{ code: number; stdout: string; stderr: string }> {
  const cmd = new Deno.Command("deno", {
    args: ["run", "--allow-read", "--allow-run", LINT_SCRIPT, ...args],
    cwd: REPO_ROOT,
    stdout: "piped",
    stderr: "piped",
  });
  const result = await cmd.output();
  return {
    code: result.code,
    stdout: new TextDecoder().decode(result.stdout),
    stderr: new TextDecoder().decode(result.stderr),
  };
}

// ─── Schema: trigger exclusivity ─────────────────────────────────────────────

Deno.test({
  name: "schema: valid cycle-only trigger → exit 0",
  fn: async () => {
    const { code, stdout } = await runLint([`${FIXTURES}/valid-cycle/FRESH_DOC`]);
    assertEquals(code, 0, `stdout: ${stdout}`);
  },
});

Deno.test({
  name: "schema: valid watched_paths-only trigger → exit 0",
  fn: async () => {
    const { code, stdout } = await runLint([`${FIXTURES}/valid-watched/FRESH_DOC`]);
    assertEquals(code, 0, `stdout: ${stdout}`);
  },
});

Deno.test({
  name: "schema: both cycle + watched_paths → exit 1",
  fn: async () => {
    const { code, stdout } = await runLint([`${FIXTURES}/invalid-both-triggers/FRESH_DOC`]);
    assertEquals(code, 1, `stdout: ${stdout}`);
    assertEquals(stdout.includes("trigger"), true);
  },
});

Deno.test({
  name: "schema: neither cycle nor watched_paths → exit 1",
  fn: async () => {
    const { code, stdout } = await runLint([`${FIXTURES}/invalid-no-trigger/FRESH_DOC`]);
    assertEquals(code, 1, `stdout: ${stdout}`);
    assertEquals(stdout.includes("trigger"), true);
  },
});

// ─── Schema: priority enum ────────────────────────────────────────────────────

Deno.test({
  name: "schema: invalid priority → exit 1 with field name",
  fn: async () => {
    const { code, stdout } = await runLint([`${FIXTURES}/invalid-schema/FRESH_DOC`]);
    assertEquals(code, 1);
    assertEquals(stdout.includes("priority"), true);
  },
});

// ─── Schema: last_verified format ─────────────────────────────────────────────

Deno.test({
  name: "schema: invalid date format (slashes) → exit 1",
  fn: async () => {
    const { code, stdout } = await runLint([`${FIXTURES}/invalid-schema/FRESH_DOC`]);
    assertEquals(code, 1);
    assertEquals(stdout.includes("last_verified"), true);
  },
});

// ─── Schema: cycle format ─────────────────────────────────────────────────────

Deno.test({
  name: "schema: cycle '30days' (invalid format) → exit 1",
  fn: async () => {
    const { code, stdout } = await runLint([`${FIXTURES}/invalid-schema/FRESH_DOC`]);
    assertEquals(code, 1);
    // invalid-schema has cycle: 30days which should fail
    assertEquals(stdout.includes("cycle"), true);
  },
});

// ─── Schema: recursive bool ───────────────────────────────────────────────────

Deno.test({
  name: "schema: recursive 'true' (string, not bool) → exit 1",
  fn: async () => {
    const { code, stdout } = await runLint([`${FIXTURES}/invalid-schema/FRESH_DOC`]);
    assertEquals(code, 1);
    assertEquals(stdout.includes("recursive"), true);
  },
});

// ─── Dry-run ──────────────────────────────────────────────────────────────────

Deno.test({
  name: "dry-run: cycle-based STALE when past cycle",
  fn: async () => {
    // valid-cycle has last_verified=2026-05-13, cycle=30d
    // Using today=2026-06-15 (33 days later) → STALE
    const { code, stdout } = await runLint([
      "--dry-run",
      "--today=2026-06-15",
      `${FIXTURES}/valid-cycle/FRESH_DOC`,
    ]);
    assertEquals(code, 0);
    assertEquals(stdout.includes("STALE"), true, `stdout: ${stdout}`);
  },
});

Deno.test({
  name: "dry-run: cycle-based FRESH when within cycle",
  fn: async () => {
    // valid-cycle: last_verified=2026-05-13, cycle=30d
    // Using today=2026-05-20 (7 days later) → FRESH
    const { code, stdout } = await runLint([
      "--dry-run",
      "--today=2026-05-20",
      `${FIXTURES}/valid-cycle/FRESH_DOC`,
    ]);
    assertEquals(code, 0);
    assertEquals(stdout.includes("FRESH"), true, `stdout: ${stdout}`);
  },
});

// ─── Recursive traversal ──────────────────────────────────────────────────────

Deno.test({
  name: "recursive: true + subdir .md files → exit 0 (files counted)",
  fn: async () => {
    const { code, stdout } = await runLint([`${FIXTURES}/valid-recursive/FRESH_DOC`]);
    assertEquals(code, 0, `stdout: ${stdout}`);
    assertEquals(stdout.includes("OK"), true, `stdout: ${stdout}`);
  },
});

Deno.test({
  name: "recursive: true + nested FRESH_DOC boundary → parent passes with own .md",
  fn: async () => {
    // recursive-with-nested/FRESH_DOC is recursive: true, has overview.md.
    // nested/ has its own FRESH_DOC so it's excluded from parent's count.
    const { code, stdout } = await runLint([`${FIXTURES}/recursive-with-nested/FRESH_DOC`]);
    assertEquals(code, 0, `stdout: ${stdout}`);
    assertEquals(stdout.includes("OK"), true, `stdout: ${stdout}`);
  },
});

Deno.test({
  name: "recursive: nested FRESH_DOC itself validates independently → exit 0",
  fn: async () => {
    const { code, stdout } = await runLint([
      `${FIXTURES}/recursive-with-nested/nested/FRESH_DOC`,
    ]);
    assertEquals(code, 0, `stdout: ${stdout}`);
  },
});

// ─── Output format ────────────────────────────────────────────────────────────

Deno.test({
  name: "output: valid file shows 'OK'",
  fn: async () => {
    const { code, stdout } = await runLint([`${FIXTURES}/valid-cycle/FRESH_DOC`]);
    assertEquals(code, 0);
    assertEquals(stdout.includes("OK"), true, `stdout: ${stdout}`);
  },
});

Deno.test({
  name: "output: error includes field name and message",
  fn: async () => {
    const { code, stdout } = await runLint([`${FIXTURES}/invalid-both-triggers/FRESH_DOC`]);
    assertEquals(code, 1);
    // Output format: "<path>: <field>: error: <message>"
    assertEquals(stdout.includes("error:"), true, `stdout: ${stdout}`);
  },
});
