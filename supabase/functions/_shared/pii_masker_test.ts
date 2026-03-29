import { assertEquals } from "@std/assert";
import { maskValue, maskPii, maskMetadata } from "./pii_masker.ts";

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
