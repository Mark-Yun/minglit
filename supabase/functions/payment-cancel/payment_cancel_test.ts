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

function appRoute(overrides?: { paid_at?: string | null; refund_status?: string }) {
  return {
    matcher: (req: Request) =>
      req.url.includes("/rest/v1/event_applications") && req.method === "GET",
    handler: () =>
      jsonResponse({
        paid_at: overrides?.paid_at !== undefined ? overrides.paid_at : eligiblePaidAt,
        event_id: "event-123",
        refund_status: overrides?.refund_status ?? "none",
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
  handler: () => jsonResponse({ code: 0, response: { status: "cancelled", amount: 15000 } }),
};

const dbUpdateRoute = {
  matcher: (req: Request) =>
    req.url.includes("/rest/v1/event_applications") && req.method === "PATCH",
  handler: () => jsonResponse({}),
};

Deno.test("payment-cancel - eligible (within grace period) → 200", async () => {
  const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

  const { fetchMock, calls } = createFetchMock([
    authRoute,
    appRoute({ paid_at: eligiblePaidAt }), // 1시간 전 결제
    eventRoute(nearFutureEvent),             // 3일 후 이벤트 (cutoff 불합격)
    policyRoute(),
    portoneTokenRoute,
    portoneCancelRoute,
    dbUpdateRoute,
  ]);

  await withEnv(ENV, async () => {
    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = authenticatedJsonRequest("http://localhost", {
          payment_id: "imp_123",
          reason: "user requested",
        });

        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 200);
        assertEquals(payload.success, true);

        const dbCall = calls.find(
          (c) => c.url.includes("/rest/v1/event_applications") && c.method === "PATCH",
        );
        const dbBody = JSON.parse(dbCall!.body!);
        assertEquals(dbBody.refund_status, "completed");
      });
    });
  });
});

Deno.test("payment-cancel - ineligible (3h after payment, 3 days before event) → 400", async () => {
  const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

  const { fetchMock } = createFetchMock([
    authRoute,
    appRoute({ paid_at: ineligiblePaidAt }), // 3시간 전 결제 (grace 불합격)
    eventRoute(nearFutureEvent),              // 3일 후 이벤트 (cutoff 불합격)
    policyRoute(),
  ]);

  await withEnv(ENV, async () => {
    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = authenticatedJsonRequest("http://localhost", {
          payment_id: "imp_123",
        });

        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 400);
        assertEquals(payload.error, "refund_not_eligible");
      });
    });
  });
});

Deno.test("payment-cancel - already refunded → 400", async () => {
  const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

  const { fetchMock } = createFetchMock([
    authRoute,
    appRoute({ refund_status: "completed" }),
  ]);

  await withEnv(ENV, async () => {
    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = authenticatedJsonRequest("http://localhost", {
          payment_id: "imp_123",
        });

        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 400);
        assertEquals(payload.error, "already_refunded");
      });
    });
  });
});

Deno.test("payment-cancel - application not found → 404", async () => {
  const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

  const { fetchMock } = createFetchMock([
    authRoute,
    {
      matcher: (req: Request) =>
        req.url.includes("/rest/v1/event_applications") && req.method === "GET",
      handler: () => jsonResponse({ error: { message: "not found" } }, { status: 406 }),
    },
  ]);

  await withEnv(ENV, async () => {
    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = authenticatedJsonRequest("http://localhost", {
          payment_id: "imp_unknown",
        });

        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 404);
        assertEquals(payload.error, "Application not found");
      });
    });
  });
});

Deno.test("payment-cancel - paidAt null + within cutoff → eligible → 200", async () => {
  const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

  const { fetchMock } = createFetchMock([
    authRoute,
    appRoute({ paid_at: null }),     // paid_at 없음 → grace 불합격
    eventRoute(farFutureEvent),      // 10일 후 이벤트 → cutoff 합격
    policyRoute(),
    portoneTokenRoute,
    portoneCancelRoute,
    dbUpdateRoute,
  ]);

  await withEnv(ENV, async () => {
    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = authenticatedJsonRequest("http://localhost", {
          payment_id: "imp_123",
        });

        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 200);
        assertEquals(payload.success, true);
      });
    });
  });
});

Deno.test("payment-cancel - missing payment_id returns 400", async () => {
  const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
  const { fetchMock } = createFetchMock([authRoute]);

  await withEnv(ENV, async () => {
    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = authenticatedJsonRequest("http://localhost", { reason: "missing" });
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 400);
        assertEquals(payload.error, "Missing payment_id");
      });
    });
  });
});

Deno.test("payment-cancel - token failure returns 502", async () => {
  const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

  const { fetchMock } = createFetchMock([
    authRoute,
    appRoute(),
    eventRoute(),
    policyRoute(),
    {
      matcher: "https://api.iamport.kr/users/getToken",
      handler: () => jsonResponse({ code: 1, message: "bad key" }),
    },
  ]);

  await withEnv(ENV, async () => {
    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = authenticatedJsonRequest("http://localhost", { payment_id: "imp_123" });
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 502);
        assertEquals(payload.error, "Payment provider error");
      });
    });
  });
});

Deno.test("payment-cancel - malformed JSON returns 400", async () => {
  const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
  const { fetchMock } = createFetchMock([authRoute]);

  await withEnv(ENV, async () => {
    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = textRequest("http://localhost", "{invalid-json", { headers: { Authorization: "Bearer test-token" } });
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 400);
        assertEquals(payload.error, "Invalid JSON body");
      });
    });
  });
});

Deno.test("payment-cancel - partial refund passes amount and checksum to iamport", async () => {
  const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

  const { fetchMock, calls } = createFetchMock([
    authRoute,
    appRoute(),
    eventRoute(),
    policyRoute(),
    portoneTokenRoute,
    {
      matcher: "https://api.iamport.kr/payments/cancel",
      handler: () => jsonResponse({ code: 0, response: { status: "cancelled", amount: 5000 } }),
    },
    dbUpdateRoute,
  ]);

  await withEnv(ENV, async () => {
    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = authenticatedJsonRequest("http://localhost", {
          payment_id: "imp_123",
          reason: "partial refund",
          amount: 5000,
          checksum: 15000,
        });

        const response = await handler(request);
        assertEquals(response.status, 200);

        const cancelCall = calls.find((c) => c.url.includes("/payments/cancel"));
        const cancelBody = JSON.parse(cancelCall!.body!);
        assertEquals(cancelBody.amount, 5000);
        assertEquals(cancelBody.checksum, 15000);

        const dbCall = calls.find((c) => c.url.includes("/rest/v1/event_applications") && c.method === "PATCH");
        const dbBody = JSON.parse(dbCall!.body!);
        assertEquals(dbBody.refund_status, "completed");
        assertEquals(dbBody.refund_amount, 5000);
      });
    });
  });
});

Deno.test("payment-cancel - DB error is non-fatal, still returns 200", async () => {
  const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

  const { fetchMock } = createFetchMock([
    authRoute,
    appRoute(),
    eventRoute(),
    policyRoute(),
    portoneTokenRoute,
    {
      matcher: "https://api.iamport.kr/payments/cancel",
      handler: () => jsonResponse({ code: 0, response: { status: "cancelled" } }),
    },
    {
      matcher: (req: Request) =>
        req.url.includes("/rest/v1/event_applications") && req.method === "PATCH",
      handler: () => jsonResponse({ error: { message: "DB error" } }, { status: 500 }),
    },
  ]);

  await withEnv(ENV, async () => {
    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = authenticatedJsonRequest("http://localhost", { payment_id: "imp_123" });
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 200);
        assertEquals(payload.success, true);
      });
    });
  });
});
