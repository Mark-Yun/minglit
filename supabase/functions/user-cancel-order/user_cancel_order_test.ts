import { assertEquals } from "@std/assert";
import {
  captureServeHandler,
  createFetchMock,
  authenticatedJsonRequest,
  jsonResponse,
  readJson,
  textRequest,
  withEnv,
  withMockedFetch,
  withNoIntervals,
} from "../_test_utils/mock_http.ts";
import { authRoute } from "../_test_utils/fixtures.ts";

const TEST_OPTS = { sanitizeOps: false, sanitizeResources: false };

const ENV = {
  PORTONE_API_KEY: "test-key",
  PORTONE_API_SECRET: "test-secret",
  SUPABASE_URL: "https://supabase.test",
  SUPABASE_SERVICE_ROLE_KEY: "service-key",
};

const nowMs = Date.now();
const eligiblePaidAt = new Date(nowMs - 1 * 60 * 60 * 1000).toISOString(); // 1시간 전
const ineligiblePaidAt = new Date(nowMs - 3 * 60 * 60 * 1000).toISOString(); // 3시간 전
const farFutureEvent = new Date(nowMs + 10 * 24 * 60 * 60 * 1000).toISOString(); // 10일 후
const nearFutureEvent = new Date(nowMs + 3 * 24 * 60 * 60 * 1000).toISOString(); // 3일 후

// --- Route helpers ---

function appRoute(overrides?: {
  status?: string;
  payment_id?: string | null;
  payment_amount?: number | null;
  paid_at?: string | null;
  refund_status?: string;
  user_id?: string;
}) {
  return {
    matcher: (req: Request) =>
      req.url.includes("/rest/v1/event_applications") && req.method === "GET",
    handler: () =>
      jsonResponse({
        id: "app-123",
        status: overrides?.status ?? "pending",
        payment_id: overrides?.payment_id ?? "imp_123",
        payment_amount: overrides?.payment_amount !== undefined ? overrides.payment_amount : 30000,
        paid_at: overrides?.paid_at !== undefined ? overrides.paid_at : null,
        refund_status: overrides?.refund_status ?? "none",
        event_id: "event-123",
        user_id: overrides?.user_id ?? "user-123",
      }),
  };
}

function eventRoute(start_time?: string) {
  return {
    matcher: (req: Request) =>
      req.url.includes("/rest/v1/events") && req.method === "GET",
    handler: () => jsonResponse({ start_time: start_time ?? farFutureEvent }),
  };
}

function policyRoute() {
  return {
    matcher: (req: Request) =>
      req.url.includes("/rest/v1/rpc/get_current_policy") && req.method === "POST",
    handler: () => jsonResponse({ grace_period_hours: 2, cutoff_days: 7 }),
  };
}

const portoneTokenRoute = {
  matcher: "https://api.iamport.kr/users/getToken",
  handler: () => jsonResponse({ code: 0, response: { access_token: "token" } }),
};

const portoneCancelRoute = {
  matcher: "https://api.iamport.kr/payments/cancel",
  handler: () => jsonResponse({ code: 0, response: { status: "cancelled", amount: 30000 } }),
};

const dbUpdateRoute = {
  matcher: (req: Request) =>
    req.url.includes("/rest/v1/event_applications") && req.method === "PATCH",
  handler: () => jsonResponse({}),
};

const dbDeleteAppRoute = {
  matcher: (req: Request) =>
    req.url.includes("/rest/v1/event_applications") && req.method === "DELETE",
  handler: () => jsonResponse({}),
};

const dbDeleteVerificationRoute = {
  matcher: (req: Request) =>
    req.url.includes("/rest/v1/verification_submissions") && req.method === "DELETE",
  handler: () => jsonResponse({}),
};

const appNotFoundRoute = {
  matcher: (req: Request) =>
    req.url.includes("/rest/v1/event_applications") && req.method === "GET",
  handler: () => jsonResponse({ error: { message: "not found" } }, { status: 406 }),
};

// ===== Pre-payment cancellation tests =====

Deno.test("pending 신청 → 취소 → event_applications 삭제", TEST_OPTS, async () => {
  const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

  const { fetchMock, calls } = createFetchMock([
    authRoute,
    appRoute({ status: "pending" }),
    dbDeleteVerificationRoute,
    dbDeleteAppRoute,
  ]);

  await withEnv(ENV, async () => {
    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = authenticatedJsonRequest("http://localhost", { event_id: "event-123" });
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 200);
        assertEquals(payload.success, true);
        assertEquals(payload.type, "cancelled");

        // Verify deletion calls were made
        const deleteVerification = calls.find(
          (c) => c.url.includes("/rest/v1/verification_submissions") && c.method === "DELETE",
        );
        assertEquals(!!deleteVerification, true);

        const deleteApp = calls.find(
          (c) => c.url.includes("/rest/v1/event_applications") && c.method === "DELETE",
        );
        assertEquals(!!deleteApp, true);
      });
    });
  });
});

Deno.test("pending + verification_submissions → 함께 삭제", TEST_OPTS, async () => {
  const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

  const { fetchMock, calls } = createFetchMock([
    authRoute,
    appRoute({ status: "pending" }),
    dbDeleteVerificationRoute,
    dbDeleteAppRoute,
  ]);

  await withEnv(ENV, async () => {
    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = authenticatedJsonRequest("http://localhost", { event_id: "event-123" });
        const response = await handler(request);

        assertEquals(response.status, 200);

        const deleteVerification = calls.find(
          (c) => c.url.includes("/rest/v1/verification_submissions") && c.method === "DELETE",
        );
        assertEquals(!!deleteVerification, true, "verification_submissions should be deleted");
      });
    });
  });
});

Deno.test("payment_failed → 취소 → 삭제", TEST_OPTS, async () => {
  const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

  const { fetchMock } = createFetchMock([
    authRoute,
    appRoute({ status: "payment_failed" }),
    dbDeleteVerificationRoute,
    dbDeleteAppRoute,
  ]);

  await withEnv(ENV, async () => {
    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = authenticatedJsonRequest("http://localhost", { event_id: "event-123" });
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 200);
        assertEquals(payload.success, true);
        assertEquals(payload.type, "cancelled");
      });
    });
  });
});

// ===== Free event cancellation =====

Deno.test("무료 이벤트 (payment_amount = 0) → 취소 → status = 'cancelled'", TEST_OPTS, async () => {
  const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

  const { fetchMock, calls } = createFetchMock([
    authRoute,
    appRoute({ status: "paid", payment_amount: 0, paid_at: eligiblePaidAt }),
    dbUpdateRoute,
  ]);

  await withEnv(ENV, async () => {
    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = authenticatedJsonRequest("http://localhost", { event_id: "event-123" });
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 200);
        assertEquals(payload.success, true);
        assertEquals(payload.type, "cancelled");

        const dbCall = calls.find(
          (c) => c.url.includes("/rest/v1/event_applications") && c.method === "PATCH",
        );
        const dbBody = JSON.parse(dbCall!.body!);
        assertEquals(dbBody.status, "cancelled");
      });
    });
  });
});

Deno.test("무료 이벤트 (payment_amount = null) → 취소", TEST_OPTS, async () => {
  const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

  const { fetchMock } = createFetchMock([
    authRoute,
    appRoute({ status: "paid", payment_amount: null, paid_at: eligiblePaidAt }),
    dbUpdateRoute,
  ]);

  await withEnv(ENV, async () => {
    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = authenticatedJsonRequest("http://localhost", { event_id: "event-123" });
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 200);
        assertEquals(payload.type, "cancelled");
      });
    });
  });
});

Deno.test("이미 cancelled → 400", TEST_OPTS, async () => {
  const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

  const { fetchMock } = createFetchMock([
    authRoute,
    appRoute({ status: "cancelled" }),
  ]);

  await withEnv(ENV, async () => {
    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = authenticatedJsonRequest("http://localhost", { event_id: "event-123" });
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 400);
        assertEquals(payload.error, "이미 취소/거절된 신청입니다");
      });
    });
  });
});

// ===== Paid event refund tests =====

Deno.test("paid → grace period 내 → 환불 성공 + refund_status = 'completed'", TEST_OPTS, async () => {
  const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

  const { fetchMock, calls } = createFetchMock([
    authRoute,
    appRoute({ status: "paid", paid_at: eligiblePaidAt, payment_amount: 30000 }),
    eventRoute(nearFutureEvent),
    policyRoute(),
    portoneTokenRoute,
    portoneCancelRoute,
    dbUpdateRoute,
  ]);

  await withEnv(ENV, async () => {
    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = authenticatedJsonRequest("http://localhost", { event_id: "event-123" });
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 200);
        assertEquals(payload.success, true);
        assertEquals(payload.type, "refunded");
        assertEquals(payload.data.refund_amount, 30000);

        const dbCall = calls.find(
          (c) => c.url.includes("/rest/v1/event_applications") && c.method === "PATCH",
        );
        const dbBody = JSON.parse(dbCall!.body!);
        assertEquals(dbBody.refund_status, "completed");
        assertEquals(dbBody.refund_amount, 30000);
      });
    });
  });
});

Deno.test("paid → grace period 초과 + cutoff 내 → 환불 성공", TEST_OPTS, async () => {
  const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

  const { fetchMock } = createFetchMock([
    authRoute,
    appRoute({ status: "paid", paid_at: ineligiblePaidAt, payment_amount: 30000 }),
    eventRoute(farFutureEvent), // 10일 후 → cutoff 합격
    policyRoute(),
    portoneTokenRoute,
    portoneCancelRoute,
    dbUpdateRoute,
  ]);

  await withEnv(ENV, async () => {
    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = authenticatedJsonRequest("http://localhost", { event_id: "event-123" });
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 200);
        assertEquals(payload.success, true);
        assertEquals(payload.type, "refunded");
      });
    });
  });
});

Deno.test("paid → grace period 초과 + cutoff 초과 → 400 (refund_not_eligible)", TEST_OPTS, async () => {
  const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

  const { fetchMock } = createFetchMock([
    authRoute,
    appRoute({ status: "paid", paid_at: ineligiblePaidAt, payment_amount: 30000 }),
    eventRoute(nearFutureEvent), // 3일 후 → cutoff 불합격
    policyRoute(),
  ]);

  await withEnv(ENV, async () => {
    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = authenticatedJsonRequest("http://localhost", { event_id: "event-123" });
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 400);
        assertEquals(payload.error, "refund_not_eligible");
      });
    });
  });
});

Deno.test("이미 환불됨 (refund_status != 'none') → 400 (already_refunded)", TEST_OPTS, async () => {
  const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

  const { fetchMock } = createFetchMock([
    authRoute,
    appRoute({ status: "paid", refund_status: "completed", payment_amount: 30000 }),
  ]);

  await withEnv(ENV, async () => {
    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = authenticatedJsonRequest("http://localhost", { event_id: "event-123" });
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 400);
        assertEquals(payload.error, "already_refunded");
      });
    });
  });
});

Deno.test("pending_review → 환불 정상 처리", TEST_OPTS, async () => {
  const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

  const { fetchMock } = createFetchMock([
    authRoute,
    appRoute({ status: "pending_review", paid_at: eligiblePaidAt, payment_amount: 30000 }),
    eventRoute(nearFutureEvent),
    policyRoute(),
    portoneTokenRoute,
    portoneCancelRoute,
    dbUpdateRoute,
  ]);

  await withEnv(ENV, async () => {
    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = authenticatedJsonRequest("http://localhost", { event_id: "event-123" });
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 200);
        assertEquals(payload.type, "refunded");
      });
    });
  });
});

Deno.test("approved → 환불 정상 처리", TEST_OPTS, async () => {
  const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

  const { fetchMock } = createFetchMock([
    authRoute,
    appRoute({ status: "approved", paid_at: eligiblePaidAt, payment_amount: 30000 }),
    eventRoute(nearFutureEvent),
    policyRoute(),
    portoneTokenRoute,
    portoneCancelRoute,
    dbUpdateRoute,
  ]);

  await withEnv(ENV, async () => {
    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = authenticatedJsonRequest("http://localhost", { event_id: "event-123" });
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 200);
        assertEquals(payload.type, "refunded");
      });
    });
  });
});

Deno.test("reason 포함 → 정상 처리", TEST_OPTS, async () => {
  const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

  const { fetchMock, calls } = createFetchMock([
    authRoute,
    appRoute({ status: "paid", paid_at: eligiblePaidAt, payment_amount: 30000 }),
    eventRoute(nearFutureEvent),
    policyRoute(),
    portoneTokenRoute,
    portoneCancelRoute,
    dbUpdateRoute,
  ]);

  await withEnv(ENV, async () => {
    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = authenticatedJsonRequest("http://localhost", {
          event_id: "event-123",
          reason: "일정 변경",
        });
        const response = await handler(request);

        assertEquals(response.status, 200);

        // Verify reason was passed to PortOne
        const cancelCall = calls.find((c) => c.url.includes("/payments/cancel"));
        const cancelBody = JSON.parse(cancelCall!.body!);
        assertEquals(cancelBody.reason, "일정 변경");
      });
    });
  });
});

// ===== Auth & Edge cases =====

Deno.test("존재하지 않는 event_id → 404", TEST_OPTS, async () => {
  const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

  const { fetchMock } = createFetchMock([
    authRoute,
    appNotFoundRoute,
  ]);

  await withEnv(ENV, async () => {
    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = authenticatedJsonRequest("http://localhost", { event_id: "nonexistent" });
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 404);
        assertEquals(payload.error, "해당 이벤트에 신청 내역이 없습니다");
      });
    });
  });
});

Deno.test("인증 없이 → 401", TEST_OPTS, async () => {
  const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

  const { fetchMock } = createFetchMock([
    {
      matcher: (req: Request) => req.url.includes("/auth/v1/user"),
      handler: () => jsonResponse({ error: "invalid token" }, { status: 401 }),
    },
  ]);

  await withEnv(ENV, async () => {
    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = authenticatedJsonRequest("http://localhost", { event_id: "event-123" });
        const response = await handler(request);

        assertEquals(response.status, 401);
      });
    });
  });
});

Deno.test("rejected 상태 → 400", TEST_OPTS, async () => {
  const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

  const { fetchMock } = createFetchMock([
    authRoute,
    appRoute({ status: "rejected" }),
  ]);

  await withEnv(ENV, async () => {
    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = authenticatedJsonRequest("http://localhost", { event_id: "event-123" });
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 400);
        assertEquals(payload.error, "이미 취소/거절된 신청입니다");
      });
    });
  });
});

Deno.test("신청 없는 event_id → 404", TEST_OPTS, async () => {
  const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

  const { fetchMock } = createFetchMock([
    authRoute,
    appNotFoundRoute,
  ]);

  await withEnv(ENV, async () => {
    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = authenticatedJsonRequest("http://localhost", { event_id: "event-no-app" });
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 404);
        assertEquals(payload.error, "해당 이벤트에 신청 내역이 없습니다");
      });
    });
  });
});

Deno.test("missing event_id → 400", TEST_OPTS, async () => {
  const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
  const { fetchMock } = createFetchMock([authRoute]);

  await withEnv(ENV, async () => {
    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = authenticatedJsonRequest("http://localhost", { reason: "test" });
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 400);
        assertEquals(payload.error, "Missing required field: event_id");
      });
    });
  });
});

Deno.test("malformed JSON → 400", TEST_OPTS, async () => {
  const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
  const { fetchMock } = createFetchMock([authRoute]);

  await withEnv(ENV, async () => {
    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = textRequest("http://localhost", "{invalid-json", {
          headers: { Authorization: "Bearer test-token" },
        });
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 400);
        assertEquals(payload.error, "Invalid JSON body");
      });
    });
  });
});

Deno.test("token failure → 502", TEST_OPTS, async () => {
  const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

  const { fetchMock } = createFetchMock([
    authRoute,
    appRoute({ status: "paid", paid_at: eligiblePaidAt, payment_amount: 30000 }),
    eventRoute(nearFutureEvent),
    policyRoute(),
    {
      matcher: "https://api.iamport.kr/users/getToken",
      handler: () => jsonResponse({ code: 1, message: "bad key" }),
    },
  ]);

  await withEnv(ENV, async () => {
    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = authenticatedJsonRequest("http://localhost", { event_id: "event-123" });
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 502);
        assertEquals(payload.error, "Payment provider error");
      });
    });
  });
});

Deno.test("DB error is non-fatal for refund → 200", TEST_OPTS, async () => {
  const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

  const { fetchMock } = createFetchMock([
    authRoute,
    appRoute({ status: "paid", paid_at: eligiblePaidAt, payment_amount: 30000 }),
    eventRoute(nearFutureEvent),
    policyRoute(),
    portoneTokenRoute,
    portoneCancelRoute,
    {
      matcher: (req: Request) =>
        req.url.includes("/rest/v1/event_applications") && req.method === "PATCH",
      handler: () => jsonResponse({ error: { message: "DB error" } }, { status: 500 }),
    },
  ]);

  await withEnv(ENV, async () => {
    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = authenticatedJsonRequest("http://localhost", { event_id: "event-123" });
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 200);
        assertEquals(payload.success, true);
        assertEquals(payload.type, "refunded");
      });
    });
  });
});
