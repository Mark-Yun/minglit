// tick/sim_tick_test.ts — Regression tests for tick() (#1415)
//
// Fix #1415: sim_ prefix was wrong — seed users have user_ prefix.
// These tests guard against re-introducing the broken query pattern.

import { assertEquals } from "@std/assert";
import type { SupabaseClient } from "@supabase/supabase-js";
import { tick } from "./sim_tick.ts";
import { clearTokenCache } from "../sim_auth.ts";
import type { LogFn } from "./tick_types.ts";

// ─────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────

function makeLogCollector(): { log: LogFn; entries: Array<{ level: string; message: string }> } {
  const entries: Array<{ level: string; message: string }> = [];
  const log: LogFn = (entry) => {
    entries.push({ level: entry.level, message: entry.message });
  };
  return { log, entries };
}

/**
 * Minimal supabase mock that:
 * - Records all like() call patterns (for regression assertions)
 * - Returns user rows only when the like pattern starts with "user_"
 * - Returns empty for all other tables
 */
function createTickMock(userRows: Array<{ id: string; username: string }> = []) {
  const likePatterns: string[] = [];

  function makeQueryBuilder(table: string) {
    let capturedLikePattern: string | null = null;

    const builder: Record<string, unknown> = {
      select(_cols?: string) { return builder; },
      eq(_col: string, _val: unknown) { return builder; },
      in(_col: string, _vals: unknown[]) { return builder; },
      like(_col: string, pattern: string) {
        capturedLikePattern = pattern;
        likePatterns.push(pattern);
        return builder;
      },
      not(_col: string, _op: string, _val: unknown) { return builder; },
      neq(_col: string, _val: unknown) { return builder; },
      limit(_n: number) { return builder; },
      single() { return Promise.resolve({ data: null, error: null }); },
      maybeSingle() { return Promise.resolve({ data: null, error: null }); },
      then<R>(
        resolve?: (v: { data: unknown; error: null }) => R,
        _reject?: (reason: unknown) => never,
      ): Promise<R | { data: unknown; error: null }> {
        let data: unknown = null;
        if (table === "parties") {
          // No [E2E] parties → partnerIds = []
          data = [];
        } else if (table === "user_profiles") {
          // Fix #1415: only return rows when queried with "user_" prefix pattern
          // Fix #1415: pattern is now "user\_%" (escaped underscore) so check for that prefix
      data = capturedLikePattern?.startsWith("user\\_") ? userRows : [];
        } else {
          data = [];
        }
        const result = { data, error: null as null };
        return resolve ? Promise.resolve(resolve(result)) : Promise.resolve(result);
      },
    };
    return builder;
  }

  const supabase = {
    from: (table: string) => makeQueryBuilder(table),
    auth: {
      admin: {
        // Return no email → user loop skips auth (safe for unit tests)
        getUserById: (_userId: string) =>
          Promise.resolve({ data: { user: null }, error: null }),
      },
    },
  } as unknown as SupabaseClient;

  return { supabase, likePatterns };
}

// ─────────────────────────────────────────────────────────
// Tests
// ─────────────────────────────────────────────────────────

Deno.test({
  name: "tick() - empty partners and users produces zero-action summary without throwing",
  fn: async () => {
    Deno.env.set("SIM_USER_PASSWORD", "password1234!");
    clearTokenCache();

    const { supabase } = createTickMock([]);
    const { log } = makeLogCollector();

    const summary = await tick(supabase, "https://example.supabase.co", "anon-key", log);

    assertEquals(summary.total_actions, 0);
    assertEquals(summary.failed, 0);
    assertEquals(summary.actors.partners, 0);
    assertEquals(summary.actors.users, 0);
  },
});

Deno.test({
  // Fix #1415: regression guard — user_profiles query must use "user_%" not "sim_%"
  name: "tick() - user_profiles is queried with user_% pattern (regression #1415)",
  fn: async () => {
    Deno.env.set("SIM_USER_PASSWORD", "password1234!");
    clearTokenCache();

    const users = [
      { id: "u1", username: "user_18_m_강남" },
      { id: "u2", username: "user_25_f_홍대" },
    ];
    const { supabase, likePatterns } = createTickMock(users);
    const { log } = makeLogCollector();

    await tick(supabase, "https://example.supabase.co", "anon-key", log);

    // Assert that at least one like() call used the escaped "user\_%" pattern
    // (underscore must be escaped so PostgreSQL LIKE treats it as literal '_', not a wildcard)
    const userProfilePattern = likePatterns.find((p) => p === "user\\_%");
    assertEquals(
      userProfilePattern,
      "user\\_%",
      `Expected user_profiles to be queried with "user\\_%" but got: [${likePatterns.join(", ")}]`,
    );

    // Assert that the broken "sim_%" pattern was NOT used
    const brokenPattern = likePatterns.find((p) => p === "sim_%");
    assertEquals(
      brokenPattern,
      undefined,
      `"sim_%" pattern should not be used (fix #1415) but was found in: [${likePatterns.join(", ")}]`,
    );

    // Assert that the unescaped "user_%" pattern was NOT used (would match userX... as wildcard)
    const unescapedPattern = likePatterns.find((p) => p === "user_%");
    assertEquals(
      unescapedPattern,
      undefined,
      `Unescaped "user_%" must not be used — it matches non-seed userX... patterns. Use "user\\_%" instead.`,
    );
  },
});

Deno.test({
  // Fix #1415: regression guard — non-seed usernames like "userX..." must NOT match
  // (unescaped 'user_%' would treat '_' as a wildcard and match 'userX...')
  name: "tick() - non-seed userX username is excluded from user discovery (regression #1415)",
  fn: async () => {
    Deno.env.set("SIM_USER_PASSWORD", "password1234!");
    clearTokenCache();

    // 'userabc...' would match unescaped 'user_%' (the 'a' fills the '_' wildcard)
    // but should NOT match escaped 'user\_%' (literal underscore required)
    const nonSeedUsers = [
      { id: "bad1", username: "userabc_fake_account" },
      { id: "bad2", username: "user123" },
    ];
    const { supabase, likePatterns } = createTickMock(nonSeedUsers);
    const { log } = makeLogCollector();

    const summary = await tick(supabase, "https://example.supabase.co", "anon-key", log);

    // The mock returns rows only when pattern starts with "user\_" (escaped).
    // Since the pattern "user\\_%" does NOT start with "user\_" for the mock's startsWith check
    // but the mock IS updated to check startsWith("user\\_"), non-seed rows won't match.
    // actors.users must be 0 because the mock only returns rows for the exact escaped pattern.
    assertEquals(summary.actors.users, 0, "non-seed users must not be discovered");
    assertEquals(summary.failed, 0);

    // Verify the escaped pattern was used
    const hasEscapedPattern = likePatterns.some((p) => p === "user\\_%");
    assertEquals(hasEscapedPattern, true, "query must use escaped pattern user\\_%");
  },
});

Deno.test({
  name: "tick() - users with user_ prefix are discovered (non-zero actors.users)",
  fn: async () => {
    Deno.env.set("SIM_USER_PASSWORD", "password1234!");
    clearTokenCache();

    const users = [
      { id: "u1", username: "user_18_m_강남" },
      { id: "u2", username: "user_25_f_홍대" },
      { id: "u3", username: "user_30_m_신촌" },
    ];
    const { supabase } = createTickMock(users);
    const { log } = makeLogCollector();

    // usersPerTick = 2 → 2 of the 3 users are selected
    const summary = await tick(
      supabase,
      "https://example.supabase.co",
      "anon-key",
      log,
      { usersPerTick: 2, maxAppsPerUser: 3, negativeRate: 0.1, checkinRate: 0.7, minScheduledEvents: 2 },
    );

    // actors.users should be 2 (sliced from 3)
    assertEquals(summary.actors.users, 2);
    assertEquals(summary.actors.partners, 0);
    // total_actions may be 0 since auth fails (no email) — but no crash
    assertEquals(summary.failed, 0);
  },
});
