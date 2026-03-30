import { assertEquals } from "https://deno.land/std@0.168.0/testing/asserts.ts";
import {
  _resetStatsigForTesting,
  checkStatsigGate,
  initStatsig,
  logStatsigEvent,
} from "./statsig_utils.ts";

Deno.test("initStatsig: no-ops when no key provided", () => {
  _resetStatsigForTesting();
  initStatsig("");
});

Deno.test("logStatsigEvent: no-ops when not initialized", async () => {
  _resetStatsigForTesting();
  await logStatsigEvent("user-123", "test_event");
});

Deno.test("checkStatsigGate: returns false when not initialized", async () => {
  _resetStatsigForTesting();
  const result = await checkStatsigGate("user-123", "test_gate");
  assertEquals(result, false);
});

Deno.test("logStatsigEvent: handles API failure gracefully", async () => {
  const originalFetch = globalThis.fetch;
  globalThis.fetch = () => Promise.resolve(new Response('{"error":"unauthorized"}', { status: 401 }));
  try {
    _resetStatsigForTesting();
    initStatsig("test-invalid-key");
    await logStatsigEvent("user-123", "test_event", 1.0, { source: "test" });
  } finally {
    globalThis.fetch = originalFetch;
  }
});

Deno.test("checkStatsigGate: returns false on API failure", async () => {
  const originalFetch = globalThis.fetch;
  globalThis.fetch = () => Promise.resolve(new Response('{"error":"unauthorized"}', { status: 401 }));
  try {
    _resetStatsigForTesting();
    initStatsig("test-invalid-key");
    const result = await checkStatsigGate("user-123", "nonexistent_gate");
    assertEquals(result, false);
  } finally {
    globalThis.fetch = originalFetch;
  }
});

Deno.test("logStatsigEvent: handles network error gracefully", async () => {
  const originalFetch = globalThis.fetch;
  globalThis.fetch = () => Promise.reject(new Error("Network error"));
  try {
    _resetStatsigForTesting();
    initStatsig("test-key");
    await logStatsigEvent("user-123", "test_event");
  } finally {
    globalThis.fetch = originalFetch;
  }
});

Deno.test("checkStatsigGate: returns false on network error", async () => {
  const originalFetch = globalThis.fetch;
  globalThis.fetch = () => Promise.reject(new Error("Network error"));
  try {
    _resetStatsigForTesting();
    initStatsig("test-key");
    const result = await checkStatsigGate("user-123", "test_gate");
    assertEquals(result, false);
  } finally {
    globalThis.fetch = originalFetch;
  }
});
