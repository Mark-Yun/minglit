import { assertEquals } from "https://deno.land/std@0.168.0/testing/asserts.ts";
import {
  _resetStatsigForTesting,
  checkStatsigGate,
  initStatsig,
  logStatsigEvent,
} from "./statsig_utils.ts";

Deno.test("initStatsig: no-ops when no key provided", () => {
  _resetStatsigForTesting();
  // Should not throw
  initStatsig("");
});

Deno.test("logStatsigEvent: no-ops when not initialized", async () => {
  _resetStatsigForTesting();
  // Should complete without error
  await logStatsigEvent("user-123", "test_event");
});

Deno.test("checkStatsigGate: returns false when not initialized", async () => {
  _resetStatsigForTesting();
  const result = await checkStatsigGate("user-123", "test_gate");
  assertEquals(result, false);
});

Deno.test("logStatsigEvent: handles API failure gracefully", async () => {
  _resetStatsigForTesting();
  initStatsig("test-invalid-key-for-testing");
  // With an invalid key, API will return error — should not throw
  await logStatsigEvent("user-123", "test_event", 1.0, { source: "test" });
});

Deno.test("checkStatsigGate: returns false on API failure", async () => {
  _resetStatsigForTesting();
  initStatsig("test-invalid-key-for-testing");
  const result = await checkStatsigGate("user-123", "nonexistent_gate");
  assertEquals(result, false);
});
