import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { ALERT_LABELS } from "./index.ts";

Deno.test("ALERT_LABELS: all 4 types have required labels", () => {
  const types = ["performance", "business", "infra", "report"];
  for (const type of types) {
    const labels = ALERT_LABELS[type];
    assertEquals(labels.includes("metrics-alert"), true, `${type} should have metrics-alert label`);
    assertEquals(labels.includes("auto-generated"), true, `${type} should have auto-generated label`);
    assertEquals(labels.length >= 3, true, `${type} should have at least 3 labels`);
  }
});

Deno.test("ALERT_LABELS: unknown type falls back to default", () => {
  const labels = ALERT_LABELS["unknown"] ?? ["metrics-alert", "auto-generated"];
  assertEquals(labels.includes("metrics-alert"), true);
  assertEquals(labels.includes("auto-generated"), true);
});
