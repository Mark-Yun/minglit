import { assertEquals } from "@std/assert";

import { positiveInteger, sampleDeterministic } from "./sampling.ts";
import { createPRNG } from "./types.ts";

Deno.test("sampleDeterministic returns a stable bounded sample", () => {
  const items = ["a", "b", "c", "d", "e"];

  const first = sampleDeterministic(items, 3, createPRNG(123));
  const second = sampleDeterministic(items, 3, createPRNG(123));

  assertEquals(first, second);
  assertEquals(first.length, 3);
  assertEquals(new Set(first).size, 3);
});

Deno.test("sampleDeterministic clamps over-sized and zero counts", () => {
  const items = ["a", "b"];

  assertEquals(sampleDeterministic(items, 10, createPRNG(1)).length, 2);
  assertEquals(sampleDeterministic(items, 0, createPRNG(1)), []);
  assertEquals(items, ["a", "b"]);
});

Deno.test("positiveInteger accepts finite numbers only", () => {
  assertEquals(positiveInteger(3.8, 1), 3);
  assertEquals(positiveInteger(-4, 1), 0);
  assertEquals(positiveInteger(Number.NaN, 7), 7);
  assertEquals(positiveInteger("5", 7), 7);
});
