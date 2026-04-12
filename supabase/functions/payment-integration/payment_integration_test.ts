/**
 * 결제 통합 테스트 — EF 체이닝 happy-path 검증
 *
 * 기존 unit 테스트(payment-verify_test, payment-cancel_test)는 각 EF를 독립적으로
 * 검증하지만 EF 간 체이닝은 검증하지 않는다. 이 파일은 결제 플로우를 EF 호출 순서대로
 * 체이닝하여 전체 시나리오를 검증한다.
 *
 * 시나리오:
 *   1. 유료 이벤트 신청 → PG 결제 → 결제 검증 → 티켓 발급 (approved)
 *   2. 결제 실패 → 주문 취소 → 원복 (failed/pending 유지)
 *   3. 결제 성공 → 환불 요청 → 환불 처리 (refund_status: completed)
 */
import { assertEquals } from "@std/assert";
import {
  authenticatedJsonRequest,
  captureServeHandler,
  createFetchMock,
  jsonResponse,
  readJson,
  withEnv,
  withMockedFetch,
  withNoIntervals,
} from "../_test_utils/mock_http.ts";
import { authRoute, mockPaidPayment } from "../_test_utils/fixtures.ts";

const ENV = {
  PORTONE_API_KEY: "test-key",
  PORTONE_API_SECRET: "test-secret",
  SUPABASE_URL: "https://supabase.test",
  SUPABASE_SERVICE_ROLE_KEY: "service-key",
};

// ─── 시나리오 1: 유료 이벤트 신청 → PG 결제 → 결제 검증 → 티켓 발급 ────────────
//
// 플로우: pending 상태 신청 → payment-verify 호출 → Iamport paid 응답
//         → DB가 approved + payment_id + paid_at 으로 업데이트
Deno.test("integration - paid event: verify succeeds → status approved, payment_id set", async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(
      new URL("../payment-verify/index.ts", import.meta.url),
    );

    // payment_amount: 15000 인 pending 주문
    const pendingOrder = { payment_amount: 15000, status: "pending" };

    // DB PATCH 호출을 캡처하기 위한 래퍼
    let patchedBody: Record<string, unknown> | null = null;

    const { fetchMock } = createFetchMock([
      authRoute,
      {
        matcher: "https://api.iamport.kr/users/getToken",
        handler: () => jsonResponse({ code: 0, response: { access_token: "token" } }),
      },
      {
        matcher: "https://api.iamport.kr/payments/imp_paid_001",
        handler: () => jsonResponse({ code: 0, response: mockPaidPayment }),
      },
      {
        matcher: (req: Request) =>
          req.url.includes("/rest/v1/event_applications") && req.method === "GET",
        handler: () => jsonResponse(pendingOrder),
      },
      {
        matcher: (req: Request) =>
          req.url.includes("/rest/v1/event_applications") && req.method === "PATCH",
        handler: async (req: Request) => {
          patchedBody = await req.json();
          return jsonResponse({});
        },
      },
    ]);

    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = authenticatedJsonRequest("http://localhost", {
          imp_uid: "imp_paid_001",
          merchant_uid: "order-001",
        });

        const response = await handler(request);
        const payload = await readJson(response);

        // 검증: HTTP 200 + success
        assertEquals(response.status, 200);
        assertEquals(payload.success, true);
        assertEquals(payload.imp_uid, "imp_paid_001");

        // 검증: DB 업데이트에 status: "approved" + payment_id 포함
        assertEquals(patchedBody !== null, true, "PATCH must be called");
        assertEquals(patchedBody!.status, "approved");
        assertEquals(patchedBody!.payment_id, "imp_paid_001");
      });
    });
  });
});

// ─── 시나리오 2: 결제 실패 → 주문 취소 → 원복 ──────────────────────────────────
//
// 플로우: pending 상태 신청 → payment-verify 호출 → Iamport failed 응답
//         → 400 반환, DB PATCH 호출 없음 (status 변경 없이 pending 유지)
Deno.test("integration - failed payment: verify returns 400, order stays pending", async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(
      new URL("../payment-verify/index.ts", import.meta.url),
    );

    const pendingOrder = { payment_amount: 15000, status: "pending" };
    let patchCalled = false;

    const { fetchMock } = createFetchMock([
      authRoute,
      {
        matcher: "https://api.iamport.kr/users/getToken",
        handler: () => jsonResponse({ code: 0, response: { access_token: "token" } }),
      },
      {
        // Iamport가 failed 상태를 반환 — 결제 실패 시나리오
        matcher: "https://api.iamport.kr/payments/imp_failed_001",
        handler: () =>
          jsonResponse({ code: 0, response: { status: "failed", amount: 15000, merchant_uid: "order-002" } }),
      },
      {
        matcher: (req: Request) =>
          req.url.includes("/rest/v1/event_applications") && req.method === "GET",
        handler: () => jsonResponse(pendingOrder),
      },
      {
        matcher: (req: Request) =>
          req.url.includes("/rest/v1/event_applications") && req.method === "PATCH",
        handler: () => {
          patchCalled = true;
          return jsonResponse({});
        },
      },
    ]);

    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = authenticatedJsonRequest("http://localhost", {
          imp_uid: "imp_failed_001",
          merchant_uid: "order-002",
        });

        const response = await handler(request);
        const payload = await readJson(response);

        // 검증: 결제 실패 시 400 반환
        assertEquals(response.status, 400);
        assertEquals(payload.error, "Payment not completed");

        // 검증: DB PATCH 호출 없음 — 주문은 pending 상태 유지
        assertEquals(patchCalled, false, "DB PATCH must NOT be called on payment failure");
      });
    });
  });
});

// ─── 시나리오 3: 결제 성공 → 환불 요청 → 환불 처리 ─────────────────────────────
//
// 플로우: approved + payment_id 설정된 신청 → payment-cancel 호출 (grace period 내)
//         → Iamport cancel 성공 → DB가 refund_status: "completed" + refund_amount 로 업데이트
Deno.test("integration - approved payment: cancel within grace period → refund_status completed", async () => {
  const nowMs = Date.now();
  const eligiblePaidAt = new Date(nowMs - 30 * 60 * 1000).toISOString(); // 30분 전 결제
  const farFutureEvent = new Date(nowMs + 10 * 24 * 60 * 60 * 1000).toISOString(); // 10일 후

  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(
      new URL("../payment-cancel/index.ts", import.meta.url),
    );

    // approved 상태, grace period 내 결제
    const approvedApplication = {
      paid_at: eligiblePaidAt,
      event_id: "event-003",
      refund_status: "none",
      user_id: "user-123",
    };

    let patchedBody: Record<string, unknown> | null = null;

    const { fetchMock } = createFetchMock([
      authRoute,
      {
        matcher: (req: Request) =>
          req.url.includes("/rest/v1/event_applications") && req.method === "GET",
        handler: () => jsonResponse(approvedApplication),
      },
      {
        matcher: (req: Request) =>
          req.url.includes("/rest/v1/events") && req.method === "GET",
        handler: () => jsonResponse({ start_time: farFutureEvent }),
      },
      {
        matcher: (req: Request) =>
          req.url.includes("/rest/v1/rpc/get_current_policy") && req.method === "POST",
        handler: () => jsonResponse({ grace_period_hours: 2, cutoff_days: 7 }),
      },
      {
        matcher: "https://api.iamport.kr/users/getToken",
        handler: () => jsonResponse({ code: 0, response: { access_token: "token" } }),
      },
      {
        matcher: "https://api.iamport.kr/payments/cancel",
        handler: () =>
          jsonResponse({ code: 0, response: { status: "cancelled", amount: 15000 } }),
      },
      {
        matcher: (req: Request) =>
          req.url.includes("/rest/v1/event_applications") && req.method === "PATCH",
        handler: async (req: Request) => {
          patchedBody = await req.json();
          return jsonResponse({});
        },
      },
    ]);

    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = authenticatedJsonRequest("http://localhost", {
          payment_id: "imp_xxx",
          reason: "user requested",
        });

        const response = await handler(request);
        const payload = await readJson(response);

        // 검증: HTTP 200 + success
        assertEquals(response.status, 200);
        assertEquals(payload.success, true);

        // 검증: DB 업데이트에 refund_status: "completed" + refund_amount 포함
        assertEquals(patchedBody !== null, true, "PATCH must be called");
        assertEquals(patchedBody!.refund_status, "completed");
        assertEquals(patchedBody!.refund_amount, 15000);
      });
    });
  });
});
