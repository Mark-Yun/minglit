import { assertEquals } from "@std/assert";
import { HybridCalculator } from "./calculator.ts";

Deno.test("HybridCalculator - merge vectors with positive weight", () => {
  const calculator = new HybridCalculator({
    decayRate: 0.1, // Moving average decay (keeps 90% of old)
  });

  const existingProfile = [1, 0, 0];
  const newActionVector = [0, 1, 0];
  const weight = 3; // e.g. Like

  const result = calculator.calculate(existingProfile, newActionVector, weight);
  
  // Expected Calculation:
  // v_old = [1, 0, 0] * 0.9 = [0.9, 0, 0]
  // v_new = [0, 1, 0] * 3 = [0, 3, 0]
  // v_combined = [0.9, 3, 0]
  // Normalize...
  
  const magnitude = Math.sqrt(0.9 * 0.9 + 3 * 3);
  assertEquals(result[0], 0.9 / magnitude);
  assertEquals(result[1], 3 / magnitude);
  assertEquals(result[2], 0);
});

Deno.test("HybridCalculator - merge vectors with negative weight (Dislike)", () => {
  const calculator = new HybridCalculator({
    decayRate: 0.0, // No decay for simple test
  });

  const existingProfile = [1, 1, 0];
  const newActionVector = [0, 1, 0];
  const weight = -0.5;

  const result = calculator.calculate(existingProfile, newActionVector, weight);
  
  // v_old = [1, 1, 0]
  // v_new = [0, 1, 0] * -0.5 = [0, -0.5, 0]
  // v_combined = [1, 0.5, 0]
  // Normalize...
  
  const magnitude = Math.sqrt(1*1 + 0.5*0.5);
  assertEquals(result[0], 1 / magnitude);
  assertEquals(result[1], 0.5 / magnitude);
});
