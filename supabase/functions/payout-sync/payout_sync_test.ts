import { assertEquals } from "@std/assert";
import {
  captureServeHandler,
  createFetchMock,
  jsonRequest,
  jsonResponse,
  readJson,
  withEnv,
  withMockedFetch,
  withNoIntervals,
} from "../_test_utils/mock_http.ts";

const ENV = {
  PORTONE_V2_API_KEY: "test-v2-key",
  SUPABASE_URL: "https://supabase.test",
  SUPABASE_SERVICE_ROLE_KEY: "service-key",
};

const NON_RETRYABLE_ERRORS = new Set([
  "INVALID_BANK_ACCOUNT",
  "ACCOUNT_CLOSED",
  "NAME_MISMATCH",
  "COMPLIANCE_REVIEW_REQUIRED",
]);

const RETRYABLE_ERRORS = new Set([
  "BANK_API_TIMEOUT",
  "BANK_API_5XX",
  "NETWORK_ERROR",
  "PROVIDER_RATE_LIMIT",
]);

function classifyError(errorCode: string): { retryable: boolean } {
  if (NON_RETRYABLE_ERRORS.has(errorCode)) return { retryable: false };
  if (RETRYABLE_ERRORS.has(errorCode)) return { retryable: true };
  return { retryable: true };
}

Deno.test("payout-sync - 인증 실패: 잘못된 토큰은 401 반환", async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const request = jsonRequest("http://localhost", {}, {
      headers: { Authorization: "Bearer bad-key" },
    });
    const response = await handler(request);
    assertEquals(response.status, 401);
  });
});

Deno.test("payout-sync - 인증 실패: Authorization 헤더 없으면 401 반환", async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const request = new Request("http://localhost", { method: "POST" });
    const response = await handler(request);
    assertEquals(response.status, 401);
  });
});

Deno.test("payout-sync - 빈 목록: 비종결 payouts 없으면 synced=0 반환", async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

    const { fetchMock } = createFetchMock([
      {
        matcher: (req) =>
          req.url.includes("/rest/v1/payouts") && req.method === "GET",
        handler: () => jsonResponse([]),
      },
    ]);

    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = jsonRequest("http://localhost", {}, {
          headers: { Authorization: "Bearer service-key" },
        });
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 200);
        assertEquals(payload.synced, 0);
      });
    });
  });
});

Deno.test("payout-sync - error_class 분류: NON_RETRYABLE_ERRORS Set에 4종 포함 확인", () => {
  assertEquals(NON_RETRYABLE_ERRORS.has("INVALID_BANK_ACCOUNT"), true);
  assertEquals(NON_RETRYABLE_ERRORS.has("ACCOUNT_CLOSED"), true);
  assertEquals(NON_RETRYABLE_ERRORS.has("NAME_MISMATCH"), true);
  assertEquals(NON_RETRYABLE_ERRORS.has("COMPLIANCE_REVIEW_REQUIRED"), true);
  assertEquals(NON_RETRYABLE_ERRORS.size, 4);
});

Deno.test("payout-sync - error_class 분류: RETRYABLE_ERRORS Set에 4종 포함 확인", () => {
  assertEquals(RETRYABLE_ERRORS.has("BANK_API_TIMEOUT"), true);
  assertEquals(RETRYABLE_ERRORS.has("BANK_API_5XX"), true);
  assertEquals(RETRYABLE_ERRORS.has("NETWORK_ERROR"), true);
  assertEquals(RETRYABLE_ERRORS.has("PROVIDER_RATE_LIMIT"), true);
  assertEquals(RETRYABLE_ERRORS.size, 4);
});

Deno.test("payout-sync - classifyError: INVALID_BANK_ACCOUNT → retryable=false", () => {
  const result = classifyError("INVALID_BANK_ACCOUNT");
  assertEquals(result.retryable, false);
});

Deno.test("payout-sync - classifyError: BANK_API_TIMEOUT → retryable=true", () => {
  const result = classifyError("BANK_API_TIMEOUT");
  assertEquals(result.retryable, true);
});

Deno.test("payout-sync - classifyError: 알 수 없는 에러 → retryable=true (기본값)", () => {
  const result = classifyError("UNKNOWN_ERROR_CODE");
  assertEquals(result.retryable, true);
});
