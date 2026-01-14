import { assertEquals } from "@std/assert";
import { runWorkerLoop } from "./loop_worker.ts";

Deno.test("runWorkerLoop - stops after max duration", async () => {
  let callCount = 0;
  const mockTask = () => {
    callCount++;
    return Promise.resolve(false); // No work found
  };

  const start = Date.now();
  // Run for 100ms, check every 20ms
  await runWorkerLoop({ maxDurationMs: 100, intervalMs: 20 }, mockTask);
  const duration = Date.now() - start;

  // Should run at least 100ms
  assertEquals(duration >= 100, true);
  // Should have called multiple times
  assertEquals(callCount >= 4, true);
});


Deno.test("runWorkerLoop - drains queue quickly", async () => {
  let callCount = 0;
  let workItems = 3;
  
  const mockTask = () => {
    callCount++;
    if (workItems > 0) {
      workItems--;
      return Promise.resolve(true); // Work done
    }
    return Promise.resolve(false); // Empty
  };

  // Run for 500ms, normal interval 100ms
  // Should drain 3 items very quickly (100ms delay for safety), then wait
  await runWorkerLoop({ maxDurationMs: 500, intervalMs: 100 }, mockTask);
  
  // 3 items processed quickly + couple of empty checks
  assertEquals(callCount >= 3, true);
});
