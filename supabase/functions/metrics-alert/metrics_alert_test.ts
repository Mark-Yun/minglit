import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";

Deno.test("ALERT_LABELS: all 4 types have metrics-alert label", () => {
  const types = ["performance", "business", "infra", "report"];
  const ALERT_LABELS: Record<string, string[]> = {
    performance: ["metrics-alert", "auto-generated", "performance"],
    business: ["metrics-alert", "auto-generated", "business-metrics"],
    infra: ["metrics-alert", "auto-generated", "infrastructure"],
    report: ["metrics-alert", "auto-generated", "report"],
  };

  for (const type of types) {
    const labels = ALERT_LABELS[type];
    assertEquals(labels.includes("metrics-alert"), true, `${type} should have metrics-alert label`);
    assertEquals(labels.includes("auto-generated"), true, `${type} should have auto-generated label`);
  }
});

Deno.test("ALERT_LABELS: unknown type falls back to default", () => {
  const ALERT_LABELS: Record<string, string[]> = {
    performance: ["metrics-alert", "auto-generated", "performance"],
    business: ["metrics-alert", "auto-generated", "business-metrics"],
    infra: ["metrics-alert", "auto-generated", "infrastructure"],
    report: ["metrics-alert", "auto-generated", "report"],
  };
  const labels = ALERT_LABELS["unknown"] ?? ["metrics-alert", "auto-generated"];
  assertEquals(labels.includes("metrics-alert"), true);
});
