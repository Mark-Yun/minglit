import { assertEquals } from "@std/assert";
import { maskValue, maskPii, maskMetadata, maskJsonString, EXCLUDED_KEYS } from "./pii_masker.ts";

// --- maskValue ---

Deno.test("maskValue - Korean name 3 chars", () => {
  assertEquals(maskValue("홍길동"), "홍*동");
});

Deno.test("maskValue - Korean name 2 chars", () => {
  assertEquals(maskValue("홍길"), "홍*");
});

Deno.test("maskValue - single char", () => {
  assertEquals(maskValue("홍"), "*");
});

Deno.test("maskValue - empty string", () => {
  assertEquals(maskValue(""), "");
});

Deno.test("maskValue - English name", () => {
  assertEquals(maskValue("John"), "J**n");
});

Deno.test("maskValue - phone with dashes", () => {
  assertEquals(maskValue("010-1234-5678"), "010-****-5678");
});

Deno.test("maskValue - phone without dashes", () => {
  assertEquals(maskValue("01012345678"), "010****5678");
});

Deno.test("maskValue - email", () => {
  assertEquals(maskValue("user@example.com"), "u***@example.com");
});

Deno.test("maskValue - long string", () => {
  assertEquals(maskValue("서울특별시 강남구 역삼동"), "서***동");
});

// --- maskPii ---

Deno.test("maskPii - masks name field", () => {
  const result = maskPii({ name: "홍길동", age: 30 }) as Record<string, unknown>;
  assertEquals(result.name, "홍*동");
  assertEquals(result.age, 30);
});

Deno.test("maskPii - masks phone_number field", () => {
  const result = maskPii({ phone_number: "010-1234-5678" }) as Record<string, unknown>;
  assertEquals(result.phone_number, "010-****-5678");
});

Deno.test("maskPii - masks phoneNumber (camelCase)", () => {
  const result = maskPii({ phoneNumber: "01012345678" }) as Record<string, unknown>;
  assertEquals(result.phoneNumber, "010****5678");
});

Deno.test("maskPii - masks birth_date field", () => {
  const result = maskPii({ birth_date: "1990-01-15" }) as Record<string, unknown>;
  assertEquals(result.birth_date, "1***5");
});

Deno.test("maskPii - masks ci/di with truncation", () => {
  const longCi = "abcdef1234567890abcdef1234567890";
  const result = maskPii({ ci: longCi, di: longCi }) as Record<string, unknown>;
  assertEquals(result.ci, "abcdef12...");
  assertEquals(result.di, "abcdef12...");
});

Deno.test("maskPii - masks email field", () => {
  const result = maskPii({ email: "test@example.com" }) as Record<string, unknown>;
  assertEquals(result.email, "t***@example.com");
});

Deno.test("maskPii - masks address field", () => {
  const result = maskPii({ address: "서울시 강남구" }) as Record<string, unknown>;
  assertEquals(result.address, "서***구");
});

Deno.test("maskPii - handles nested objects", () => {
  const input = {
    user: { name: "홍길동", id: "abc-123" },
    status: "ok",
  };
  const result = maskPii(input) as Record<string, unknown>;
  const user = result.user as Record<string, unknown>;
  assertEquals(user.name, "홍*동");
  assertEquals(user.id, "abc-123");
  assertEquals(result.status, "ok");
});

Deno.test("maskPii - handles arrays", () => {
  const input = [{ name: "김철수" }, { name: "이영희" }];
  const result = maskPii(input) as Record<string, unknown>[];
  assertEquals(result[0].name, "김*수");
  assertEquals(result[1].name, "이*희");
});

Deno.test("maskPii - handles null and undefined", () => {
  assertEquals(maskPii(null), null);
  assertEquals(maskPii(undefined), undefined);
});

Deno.test("maskPii - does not mask non-PII fields", () => {
  const input = { user_id: "abc-123", status: "VERIFIED", amount: 50000 };
  const result = maskPii(input) as Record<string, unknown>;
  assertEquals(result.user_id, "abc-123");
  assertEquals(result.status, "VERIFIED");
  assertEquals(result.amount, 50000);
});

Deno.test("maskPii - handles non-string PII values gracefully", () => {
  const input = { name: 12345, phone: null };
  const result = maskPii(input) as Record<string, unknown>;
  assertEquals(result.name, 12345);
  assertEquals(result.phone, null);
});

// --- Fix #763: depth limit returns original object ---

Deno.test("maskPii - depth limit returns original object (not string)", () => {
  const deepObj = { level: "deep", name: "홍길동" };
  const result = maskPii(deepObj, 11); // MAX_DEPTH(10) 초과
  assertEquals(result, deepObj); // 원본 객체 그대로 반환
  assertEquals(typeof result, "object"); // 문자열이 아닌 객체
});

Deno.test("maskPii - depth limit preserves array type", () => {
  const deepArr = [{ name: "홍길동" }];
  const result = maskPii(deepArr, 11);
  assertEquals(result, deepArr);
  assertEquals(Array.isArray(result), true);
});

Deno.test("maskPii - deeply nested object returns object at depth limit", () => {
  // deno-lint-ignore no-explicit-any
  let deep: any = { name: "홍길동" };
  for (let i = 0; i < 12; i++) {
    deep = { nested: deep };
  }
  const result = maskPii(deep) as Record<string, unknown>;
  // 깊이 초과 시 원본 객체를 반환해야 함 (문자열 "[depth limit]"이 아닌)
  assertEquals(typeof result, "object");

  // 깊이 내의 레벨까지는 정상 순회되어야 함
  let cursor = result;
  for (let i = 0; i < 10; i++) {
    assertEquals(typeof cursor.nested, "object");
    cursor = cursor.nested as Record<string, unknown>;
  }
});

// --- Fix #763: EXCLUDED_KEYS ---

Deno.test("maskPii - EXCLUDED_KEYS are not masked even if in PII_FIELD_NAMES", () => {
  // "type", "module" 등 Sentry 구조적 키는 마스킹하지 않는다
  const input = {
    type: "TypeError",
    module: "auth",
    mechanism: "unhandledrejection",
    handled: "false",
    category: "error",
    level: "fatal",
  };
  const result = maskPii(input) as Record<string, unknown>;
  assertEquals(result.type, "TypeError");
  assertEquals(result.module, "auth");
  assertEquals(result.mechanism, "unhandledrejection");
  assertEquals(result.handled, "false");
  assertEquals(result.category, "error");
  assertEquals(result.level, "fatal");
});

Deno.test("maskPii - EXCLUDED_KEYS set contains expected Sentry structural keys", () => {
  assertEquals(EXCLUDED_KEYS.has("type"), true);
  assertEquals(EXCLUDED_KEYS.has("module"), true);
  assertEquals(EXCLUDED_KEYS.has("mechanism"), true);
  assertEquals(EXCLUDED_KEYS.has("handled"), true);
  assertEquals(EXCLUDED_KEYS.has("synthetic"), true);
  assertEquals(EXCLUDED_KEYS.has("category"), true);
  assertEquals(EXCLUDED_KEYS.has("level"), true);
});

Deno.test("maskPii - name field is still masked (not in EXCLUDED_KEYS)", () => {
  const input = { name: "홍길동", id: "user-1" };
  const result = maskPii(input) as Record<string, unknown>;
  assertEquals(result.name, "홍*동");
});

// --- maskJsonString ---

Deno.test("maskJsonString - masks PII in JSON string", () => {
  const jsonStr = JSON.stringify({ name: "홍길동", phone: "010-1234-5678", code: "ERR001" });
  const result = maskJsonString(jsonStr);
  const parsed = JSON.parse(result);
  assertEquals(parsed.name, "홍*동");
  assertEquals(parsed.phone, "010-****-5678");
  assertEquals(parsed.code, "ERR001");
});

Deno.test("maskJsonString - returns fallback for non-JSON string", () => {
  const result = maskJsonString("not a json string");
  assertEquals(result, "[masked: unparseable error]");
});

Deno.test("maskJsonString - returns custom fallback", () => {
  const result = maskJsonString("not json", "custom fallback");
  assertEquals(result, "custom fallback");
});

Deno.test("maskJsonString - returns fallback for non-object JSON", () => {
  const result = maskJsonString('"just a string"');
  assertEquals(result, "[masked: unparseable error]");
});

Deno.test("maskPii - depth limit returns original object instead of string", () => {
  // Build a deeply nested object exceeding MAX_DEPTH (10)
  let deep: Record<string, unknown> = { name: "홍길동" };
  for (let i = 0; i < 12; i++) {
    deep = { nested: deep };
  }
  const result = maskPii(deep);
  // Should return an object, not "[depth limit]" string
  assertEquals(typeof result, "object");
});

// --- maskMetadata ---

Deno.test("maskMetadata - returns undefined for undefined input", () => {
  assertEquals(maskMetadata(undefined), undefined);
});

Deno.test("maskMetadata - masks PII in metadata", () => {
  const meta = { detail: { name: "홍길동", error: "something" } };
  const result = maskMetadata(meta)!;
  const detail = result.detail as Record<string, unknown>;
  assertEquals(detail.name, "홍*동");
  assertEquals(detail.error, "something");
});
