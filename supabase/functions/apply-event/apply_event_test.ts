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
  SUPABASE_URL: "https://supabase.test",
  SUPABASE_SERVICE_ROLE_KEY: "service-key",
};

// ──────────────────────────────────────────────
// Fixtures
// ──────────────────────────────────────────────

const FREE_EVENT = {
  id: "event-free-1",
  status: "scheduled",
  current_participants: 0,
  max_participants: 10,
};

const PAID_EVENT = {
  id: "event-paid-1",
  status: "scheduled",
  current_participants: 0,
  max_participants: 10,
};

const FREE_TICKET = {
  id: "ticket-free-1",
  price: 0,
  quantity: 10,
  sold_count: 0,
  status: "on_sale",
  required_verification_ids: [],
  event_id: "event-free-1",
};

const PAID_TICKET = {
  id: "ticket-paid-1",
  price: 5000,
  quantity: 10,
  sold_count: 0,
  status: "on_sale",
  required_verification_ids: [],
  event_id: "event-paid-1",
};

// Helper: Auth GET returns user-123
function authRoute() {
  return {
    matcher: (req: Request) =>
      req.url.includes("/auth/v1/user") && req.method === "GET",
    handler: () => jsonResponse({ id: "user-123", email: "test@example.com" }),
  };
}

// ──────────────────────────────────────────────
// Tests
// ──────────────────────────────────────────────

Deno.test("apply-event - 무료 이벤트 신청 성공", async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

    const { fetchMock } = createFetchMock([
      authRoute(),
      {
        matcher: (req) => req.url.includes("/rest/v1/events") && req.method === "GET",
        handler: () => jsonResponse(FREE_EVENT),
      },
      {
        matcher: (req) => req.url.includes("/rest/v1/tickets") && req.method === "GET",
        handler: () => jsonResponse(FREE_TICKET),
      },
      {
        // 중복 신청 확인 — 없음
        matcher: (req) =>
          req.url.includes("/rest/v1/event_applications") && req.method === "GET",
        handler: () => jsonResponse(null),
      },
      {
        // apply_event RPC
        matcher: (req) =>
          req.url.includes("/rest/v1/rpc/apply_event") && req.method === "POST",
        handler: () => jsonResponse("application-free-uuid-1"),
      },
    ]);

    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = jsonRequest(
          "http://localhost",
          { event_id: "event-free-1", ticket_id: "ticket-free-1" },
          { headers: { Authorization: "Bearer test-token" } },
        );
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 200);
        assertEquals(payload.type, "free");
        assertEquals(typeof payload.application_id, "string");
      });
    });
  });
});

Deno.test("apply-event - 유료 이벤트 신청 성공 (주문 생성 확인)", async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

    const { fetchMock } = createFetchMock([
      authRoute(),
      {
        matcher: (req) => req.url.includes("/rest/v1/events") && req.method === "GET",
        handler: () => jsonResponse(PAID_EVENT),
      },
      {
        matcher: (req) => req.url.includes("/rest/v1/tickets") && req.method === "GET",
        handler: () => jsonResponse(PAID_TICKET),
      },
      {
        // 중복 신청 확인 — 없음
        matcher: (req) =>
          req.url.includes("/rest/v1/event_applications") && req.method === "GET",
        handler: () => jsonResponse(null),
      },
      {
        // 유료: payment_pending 레코드 INSERT — id는 EF에서 미리 생성하므로 빈 배열 반환
        matcher: (req) =>
          req.url.includes("/rest/v1/event_applications") && req.method === "POST",
        handler: () => jsonResponse([]),
      },
    ]);

    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = jsonRequest(
          "http://localhost",
          { event_id: "event-paid-1", ticket_id: "ticket-paid-1" },
          { headers: { Authorization: "Bearer test-token" } },
        );
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 200);
        assertEquals(payload.type, "paid");
        assertEquals(typeof payload.application_id, "string");
        assertEquals(typeof payload.order_id, "string");
        assertEquals(payload.payment_amount, 5000);
      });
    });
  });
});

Deno.test("apply-event - capacity 초과 시 409 반환", async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

    const { fetchMock } = createFetchMock([
      authRoute(),
      {
        matcher: (req) => req.url.includes("/rest/v1/events") && req.method === "GET",
        handler: () =>
          jsonResponse({
            ...FREE_EVENT,
            current_participants: 10,
            max_participants: 10,
          }),
      },
    ]);

    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = jsonRequest(
          "http://localhost",
          { event_id: "event-free-1", ticket_id: "ticket-free-1" },
          { headers: { Authorization: "Bearer test-token" } },
        );
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 409);
        assertEquals(payload.error, "Event is at full capacity");
      });
    });
  });
});

Deno.test("apply-event - eligibility 미충족 시 403 반환", async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

    const { fetchMock } = createFetchMock([
      authRoute(),
      {
        matcher: (req) => req.url.includes("/rest/v1/events") && req.method === "GET",
        handler: () => jsonResponse(FREE_EVENT),
      },
      {
        matcher: (req) => req.url.includes("/rest/v1/tickets") && req.method === "GET",
        handler: () =>
          jsonResponse({
            ...FREE_TICKET,
            required_verification_ids: ["verification-uuid-1"],
          }),
      },
      {
        // 중복 신청 확인 — 없음
        matcher: (req) =>
          req.url.includes("/rest/v1/event_applications") && req.method === "GET",
        handler: () => jsonResponse(null),
      },
      {
        // user_verifications — 인증 없음
        matcher: (req) =>
          req.url.includes("/rest/v1/user_verifications") && req.method === "GET",
        handler: () => jsonResponse([]),
      },
    ]);

    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = jsonRequest(
          "http://localhost",
          { event_id: "event-free-1", ticket_id: "ticket-free-1" },
          { headers: { Authorization: "Bearer test-token" } },
        );
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 403);
        assertEquals(payload.error, "Eligibility requirements not met");
      });
    });
  });
});

Deno.test("apply-event - 중복 신청 시 409 반환", async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

    const { fetchMock } = createFetchMock([
      authRoute(),
      {
        matcher: (req) => req.url.includes("/rest/v1/events") && req.method === "GET",
        handler: () => jsonResponse(FREE_EVENT),
      },
      {
        matcher: (req) => req.url.includes("/rest/v1/tickets") && req.method === "GET",
        handler: () => jsonResponse(FREE_TICKET),
      },
      {
        // 중복 신청 확인 — 이미 존재
        matcher: (req) =>
          req.url.includes("/rest/v1/event_applications") && req.method === "GET",
        handler: () => jsonResponse({ id: "existing-application-id" }),
      },
    ]);

    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = jsonRequest(
          "http://localhost",
          { event_id: "event-free-1", ticket_id: "ticket-free-1" },
          { headers: { Authorization: "Bearer test-token" } },
        );
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 409);
        assertEquals(payload.error, "Already applied to this event");
      });
    });
  });
});

Deno.test("apply-event - 이벤트 상태 invalid 시 409 반환", async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

    const { fetchMock } = createFetchMock([
      authRoute(),
      {
        matcher: (req) => req.url.includes("/rest/v1/events") && req.method === "GET",
        handler: () => jsonResponse({ ...FREE_EVENT, status: "cancelled" }),
      },
    ]);

    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = jsonRequest(
          "http://localhost",
          { event_id: "event-free-1", ticket_id: "ticket-free-1" },
          { headers: { Authorization: "Bearer test-token" } },
        );
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 409);
        assertEquals(payload.error, "Event is not accepting applications");
      });
    });
  });
});

Deno.test("apply-event - 인증 헤더 없을 때 401 반환", async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

    const { fetchMock } = createFetchMock([]);

    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = jsonRequest("http://localhost", {
          event_id: "event-free-1",
          ticket_id: "ticket-free-1",
        });
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 401);
        assertEquals(typeof payload.error, "string");
      });
    });
  });
});

Deno.test("apply-event - 필수 파라미터 누락 시 400 반환", async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

    const { fetchMock } = createFetchMock([authRoute()]);

    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = jsonRequest(
          "http://localhost",
          { event_id: "event-free-1" },
          { headers: { Authorization: "Bearer test-token" } },
        );
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 400);
        assertEquals(payload.error, "Missing required parameters: event_id, ticket_id");
      });
    });
  });
});
