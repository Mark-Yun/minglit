// tick/action_runner_test.ts — ActionRunner unit tests (#1331)

import { assertEquals } from "@std/assert";
import type { SupabaseClient } from "@supabase/supabase-js";
import { createMockSupabaseClient } from "../../_test_utils/mock_supabase_client.ts";
import { ActionRunner } from "./action_runner.ts";
import { SimAction } from "./sim_action.ts";
import type { AssertionResult, EFResponse, LogFn } from "./tick_types.ts";

// ─────────────────────────────────────────────────────────
// Test helpers
// ─────────────────────────────────────────────────────────

/**
 * Replace globalThis.fetch with a handler for the duration of fn(), then restore.
 */
function withMockFetch<T>(
  handler: (url: string, init: RequestInit) => Response,
  fn: () => Promise<T>,
): Promise<T> {
  const original = globalThis.fetch;
  globalThis.fetch = (url: string | URL | Request, init?: RequestInit) =>
    Promise.resolve(handler(url.toString(), init ?? {}));
  return fn().finally(() => {
    globalThis.fetch = original;
  });
}

/** Concrete SimAction subclass for testing */
class TestAction extends SimAction {
  readonly type = "test_action";
  readonly ef = "test-ef";
  readonly actorId = "actor-1";
  readonly description: string;

  private params: Record<string, unknown>;
  private efResult: AssertionResult;
  private dbResult: AssertionResult;

  constructor(opts: {
    token?: string;
    description?: string;
    params?: Record<string, unknown>;
    efResult?: AssertionResult;
    dbResult?: AssertionResult;
  } = {}) {
    super(opts.token ?? "test-token");
    this.description = opts.description ?? "test action";
    this.params = opts.params ?? { action: "test" };
    this.efResult = opts.efResult ?? { passed: true, name: "ef_check", details: "ok" };
    this.dbResult = opts.dbResult ?? { passed: true, name: "db_check", details: "ok" };
  }

  buildParams(): Record<string, unknown> {
    return this.params;
  }

  assertEFResponse(_response: EFResponse): AssertionResult {
    return this.efResult;
  }

  async assertDBState(_supabase: SupabaseClient): Promise<AssertionResult> {
    return await Promise.resolve(this.dbResult);
  }
}

/** Collects log entries during a test */
function makeLogCollector(): { log: LogFn; entries: Array<{ level: string; step: string; message: string }> } {
  const entries: Array<{ level: string; step: string; message: string }> = [];
  const log: LogFn = (entry) => {
    entries.push({ level: entry.level, step: entry.step, message: entry.message });
  };
  return { log, entries };
}

/** Returns a fetch handler that replies to EF calls with the given status and body */
function makeEFFetchHandler(opts: {
  efName?: string;
  status?: number;
  body?: Record<string, unknown>;
} = {}): (url: string, _init: RequestInit) => Response {
  const efName = opts.efName ?? "test-ef";
  const status = opts.status ?? 200;
  const body = opts.body ?? { success: true };
  return (url: string, _init: RequestInit): Response => {
    if (url.includes(`functions/v1/${efName}`)) {
      return new Response(JSON.stringify(body), {
        status,
        headers: { "Content-Type": "application/json" },
      });
    }
    return new Response(JSON.stringify({ error: "unexpected url" }), { status: 500 });
  };
}

// ─────────────────────────────────────────────────────────
// Tests
// ─────────────────────────────────────────────────────────

// sanitizeResources/sanitizeOps disabled: fetch mock interacts with Deno's resource tracking
Deno.test({
  name: "ActionRunner.execute - calls EF, validates response, checks DB state",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const mock = createMockSupabaseClient({});
    const { log, entries } = makeLogCollector();

    const runner = new ActionRunner(
      mock as unknown as SupabaseClient,
      "https://example.supabase.co",
      log,
    );

    const action = new TestAction({
      efResult: { passed: true, name: "ef_check", details: "status=200" },
      dbResult: { passed: true, name: "db_check", details: "row found" },
    });

    const results = await withMockFetch(
      makeEFFetchHandler({ efName: "test-ef", status: 200, body: { success: true } }),
      () => runner.execute([action]),
    );

    assertEquals(results.length, 1);
    assertEquals(results[0].passed, true);
    assertEquals(results[0].actionType, "test_action");
    assertEquals(results[0].efAssertion?.passed, true);
    assertEquals(results[0].dbAssertion?.passed, true);

    // Logged exactly one info entry
    assertEquals(entries.length, 1);
    assertEquals(entries[0].level, "info");
    assertEquals(entries[0].step, "test_action");
  },
});

Deno.test({
  name: "ActionRunner.execute - EF failure (non-2xx) does not throw; returns passed=false",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const mock = createMockSupabaseClient({});
    const { log, entries } = makeLogCollector();

    const runner = new ActionRunner(
      mock as unknown as SupabaseClient,
      "https://example.supabase.co",
      log,
    );

    // EF returns 500; the action's assertEFResponse sees it and returns passed=false
    const action = new TestAction({
      efResult: { passed: false, name: "ef_check", details: "status=500" },
      dbResult: { passed: true, name: "db_check", details: "row found" },
    });

    const results = await withMockFetch(
      makeEFFetchHandler({ efName: "test-ef", status: 500, body: { error: "server error" } }),
      () => runner.execute([action]),
    );

    assertEquals(results.length, 1);
    assertEquals(results[0].passed, false);
    assertEquals(results[0].efAssertion?.passed, false);
    assertEquals(results[0].dbAssertion?.passed, true);

    // Logged one error entry
    assertEquals(entries.length, 1);
    assertEquals(entries[0].level, "error");
  },
});

Deno.test({
  name: "ActionRunner.execute - fetch throws; catches error and returns passed=false",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const mock = createMockSupabaseClient({});
    const { log, entries } = makeLogCollector();

    const runner = new ActionRunner(
      mock as unknown as SupabaseClient,
      "https://example.supabase.co",
      log,
    );

    const action = new TestAction();

    // fetch throws a network error
    const results = await withMockFetch(
      (_url: string, _init: RequestInit): Response => {
        throw new Error("network error");
      },
      () => runner.execute([action]),
    );

    assertEquals(results.length, 1);
    assertEquals(results[0].passed, false);
    assertEquals(results[0].efAssertion, undefined);
    assertEquals(results[0].dbAssertion, undefined);
    // error captured on result
    assertEquals(results[0].error instanceof Error, true);

    // Logged one error entry with the exception message
    assertEquals(entries.length, 1);
    assertEquals(entries[0].level, "error");
    assertEquals(entries[0].message.includes("network error"), true);
  },
});

Deno.test({
  name: "ActionRunner.execute - processes multiple actions in sequence",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const mock = createMockSupabaseClient({});
    const { log, entries } = makeLogCollector();

    const runner = new ActionRunner(
      mock as unknown as SupabaseClient,
      "https://example.supabase.co",
      log,
    );

    const passing = new TestAction({
      description: "passing action",
      efResult: { passed: true, name: "ef_check", details: "ok" },
      dbResult: { passed: true, name: "db_check", details: "ok" },
    });
    const failing = new TestAction({
      description: "failing action",
      efResult: { passed: false, name: "ef_check", details: "wrong status" },
      dbResult: { passed: true, name: "db_check", details: "ok" },
    });

    const results = await withMockFetch(
      makeEFFetchHandler({ efName: "test-ef", status: 200 }),
      () => runner.execute([passing, failing]),
    );

    assertEquals(results.length, 2);
    assertEquals(results[0].passed, true);
    assertEquals(results[1].passed, false);

    // info for passing, error for failing
    assertEquals(entries[0].level, "info");
    assertEquals(entries[1].level, "error");
  },
});

Deno.test({
  name: "ActionRunner.execute - empty action list returns empty results",
  fn: async () => {
    const mock = createMockSupabaseClient({});
    const { log, entries } = makeLogCollector();

    const runner = new ActionRunner(
      mock as unknown as SupabaseClient,
      "https://example.supabase.co",
      log,
    );

    const results = await runner.execute([]);

    assertEquals(results.length, 0);
    assertEquals(entries.length, 0);
  },
});

Deno.test({
  name: "ActionRunner.execute - DB assertion failure causes passed=false",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const mock = createMockSupabaseClient({});
    const { log, entries } = makeLogCollector();

    const runner = new ActionRunner(
      mock as unknown as SupabaseClient,
      "https://example.supabase.co",
      log,
    );

    const action = new TestAction({
      efResult: { passed: true, name: "ef_check", details: "ok" },
      dbResult: { passed: false, name: "db_check", details: "row not found" },
    });

    const results = await withMockFetch(
      makeEFFetchHandler({ efName: "test-ef", status: 200 }),
      () => runner.execute([action]),
    );

    assertEquals(results.length, 1);
    assertEquals(results[0].passed, false);
    assertEquals(results[0].efAssertion?.passed, true);
    assertEquals(results[0].dbAssertion?.passed, false);

    assertEquals(entries[0].level, "error");
  },
});
