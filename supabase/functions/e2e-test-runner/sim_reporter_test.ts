import { assertEquals, assertStringIncludes, assertExists } from "@std/assert";
import { stub } from "@std/testing/mock";
import { SimLogCollector, simUploadLog, simCreateGitHubIssue } from "./sim_reporter.ts";
import type { SimSummary } from "./sim_types.ts";

Deno.test("SimLogCollector.log() — adds entries with correct fields", () => {
  const collector = new SimLogCollector();
  collector.log("info", "setup", "create_user", "User created", { userId: "u1" });

  const entries = collector.getEntries();
  assertEquals(entries.length, 1);
  assertEquals(entries[0].level, "info");
  assertEquals(entries[0].phase, "setup");
  assertEquals(entries[0].step, "create_user");
  assertEquals(entries[0].message, "User created");
  assertEquals(entries[0].data, { userId: "u1" });
  assertExists(entries[0].timestamp);
});

Deno.test("SimLogCollector.getEntries() — returns all entries", () => {
  const collector = new SimLogCollector();
  collector.log("info", "phase1", "step1", "msg1");
  collector.log("warn", "phase2", "step2", "msg2");
  collector.log("error", "phase3", "step3", "msg3");

  const entries = collector.getEntries();
  assertEquals(entries.length, 3);
  assertEquals(entries[0].level, "info");
  assertEquals(entries[1].level, "warn");
  assertEquals(entries[2].level, "error");
});

Deno.test("SimLogCollector.formatAsText() — formats correctly", () => {
  const collector = new SimLogCollector();
  collector.log("info", "setup", "init", "Starting simulation");
  collector.log("error", "payment", "verify", "Payment failed", { code: 400 });

  const text = collector.formatAsText();

  assertStringIncludes(text, "[INFO]");
  assertStringIncludes(text, "[setup:init]");
  assertStringIncludes(text, "Starting simulation");
  assertStringIncludes(text, "[ERROR]");
  assertStringIncludes(text, "[payment:verify]");
  assertStringIncludes(text, "Payment failed");
  assertStringIncludes(text, '{"code":400}');
});

Deno.test("simUploadLog() — returns null gracefully when supabase errors", async () => {
  const mockSupabase = {
    storage: {
      from: (_bucket: string) => ({
        upload: (_path: string, _bytes: Uint8Array, _opts: unknown) => ({
          error: { message: "Storage unavailable" },
          data: null,
        }),
        getPublicUrl: (_path: string) => ({
          data: { publicUrl: "https://example.com/log.log" },
        }),
      }),
    },
  };

  const result = await simUploadLog(
    mockSupabase as unknown as Parameters<typeof simUploadLog>[0],
    "run-abc-123",
    "some log text",
  );

  assertEquals(result, null);
});

Deno.test("simCreateGitHubIssue() — mock fetch, title contains [E2E-SIM], labels correct", async () => {
  Deno.env.set("GITHUB_ACCESS_TOKEN", "test-token");

  let capturedBody: Record<string, unknown> = {};

  const fetchStub = stub(
    globalThis,
    "fetch",
    // deno-lint-ignore no-explicit-any
    (_url: any, options?: any): Promise<Response> => {
      capturedBody = JSON.parse(options?.body as string);
      return Promise.resolve(new Response(
        JSON.stringify({ html_url: "https://github.com/Mark-Yun/minglit/issues/999" }),
        { status: 201 },
      ));
    },
  );

  try {
    const summary: SimSummary = {
      total_checks: 5,
      passed: 3,
      failed: 2,
      assertion_results: [
        {
          check_name: "payment_balance_check",
          passed: false,
          expected: 1000,
          actual: 900,
          details: "Balance mismatch",
        },
        { check_name: "checkin_count", passed: false, expected: 3, actual: 2 },
      ],
    };

    const result = await simCreateGitHubIssue(
      summary,
      "https://storage.example.com/2026-03-15/run-abc.log",
      "run-abc-123",
      "full log text here",
    );

    assertExists(result);
    assertStringIncludes(result!, "github.com");
    assertStringIncludes(capturedBody.title as string, "[E2E-SIM]");
    assertEquals(
      (capturedBody.labels as string[]).includes("e2e-simulation"),
      true,
    );
    assertEquals(
      (capturedBody.labels as string[]).includes("automated"),
      true,
    );
  } finally {
    fetchStub.restore();
    Deno.env.delete("GITHUB_ACCESS_TOKEN");
  }
});
