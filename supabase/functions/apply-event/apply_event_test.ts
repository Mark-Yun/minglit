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
        // Fix #1492: 유료 경로 check_party_balance — 허용
        matcher: (req) => req.url.includes("/rest/v1/rpc/check_party_balance"),
        handler: () => jsonResponse({ allowed: true, reason: null }),
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

// ──────────────────────────────────────────────
// Bug #1342 Bug1: 취소 후 재신청 — unique constraint 충돌 없이 성공
// ──────────────────────────────────────────────

Deno.test("apply-event - 취소 후 유료 재신청 성공 (UPDATE 경로)", async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

    let patchCalled = false;

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
        // 중복 신청 확인 — cancelled 상태로 존재
        matcher: (req) =>
          req.url.includes("/rest/v1/event_applications") && req.method === "GET",
        handler: () => jsonResponse({ id: "existing-cancelled-app-id", status: "cancelled" }),
      },
      {
        // Fix #1492: 유료 경로 check_party_balance — 허용
        matcher: (req) => req.url.includes("/rest/v1/rpc/check_party_balance"),
        handler: () => jsonResponse({ allowed: true, reason: null }),
      },
      {
        // 재신청: PATCH (UPDATE)
        matcher: (req) => {
          if (req.url.includes("/rest/v1/event_applications") && req.method === "PATCH") {
            patchCalled = true;
            return true;
          }
          return false;
        },
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
        // 재신청이므로 기존 ID 재사용
        assertEquals(payload.application_id, "existing-cancelled-app-id");
        assertEquals(payload.payment_amount, 5000);
        assertEquals(patchCalled, true, "PATCH(UPDATE)가 호출되어야 함 — INSERT 금지");
      });
    });
  });
});

Deno.test("apply-event - payment_failed 후 유료 재신청 성공 (UPDATE 경로)", async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

    let patchCalled = false;

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
        // 중복 신청 확인 — payment_failed 상태로 존재
        matcher: (req) =>
          req.url.includes("/rest/v1/event_applications") && req.method === "GET",
        handler: () => jsonResponse({ id: "existing-failed-app-id", status: "payment_failed" }),
      },
      {
        // Fix #1492: 유료 경로 check_party_balance — 허용
        matcher: (req) => req.url.includes("/rest/v1/rpc/check_party_balance"),
        handler: () => jsonResponse({ allowed: true, reason: null }),
      },
      {
        matcher: (req) => {
          if (req.url.includes("/rest/v1/event_applications") && req.method === "PATCH") {
            patchCalled = true;
            return true;
          }
          return false;
        },
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
        assertEquals(payload.application_id, "existing-failed-app-id");
        assertEquals(patchCalled, true, "PATCH(UPDATE)가 호출되어야 함 — INSERT 금지");
      });
    });
  });
});

// Fix #1342 Bug1: apply_event RPC 미호출 검증 (unique constraint 충돌 방지)
// Fix #1345: check_party_balance 호출 검증 추가
Deno.test("apply-event - 취소 후 무료 재신청 성공 (UPDATE 경로, apply_event RPC 미호출)", async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

    let patchCalled = false;
    let applyEventRpcCalled = false;
    let checkBalanceRpcCalled = false;
    // Fix #1660: capture PATCH body to assert status='approved'
    let patchBody: Record<string, unknown> = {};

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
        // 중복 신청 확인 — cancelled 상태로 존재
        matcher: (req) =>
          req.url.includes("/rest/v1/event_applications") && req.method === "GET",
        handler: () => jsonResponse({ id: "existing-cancelled-free-id", status: "cancelled" }),
      },
      {
        // Fix #1345: check_party_balance RPC — 허용 반환
        matcher: (req) => {
          if (req.url.includes("/rest/v1/rpc/check_party_balance")) {
            checkBalanceRpcCalled = true;
            return true;
          }
          return false;
        },
        handler: () => jsonResponse({ allowed: true, reason: null }),
      },
      {
        matcher: (req) => {
          if (req.url.includes("/rest/v1/event_applications") && req.method === "PATCH") {
            patchCalled = true;
            // Fix #1660: capture body to assert status='approved' (not 'paid')
            req.json().then((body: Record<string, unknown>) => {
              patchBody = body;
            });
            return true;
          }
          return false;
        },
        handler: () => jsonResponse([]),
      },
      {
        matcher: (req) => {
          if (req.url.includes("/rest/v1/rpc/apply_event")) {
            applyEventRpcCalled = true;
            return true;
          }
          return false;
        },
        handler: () => jsonResponse("should-not-be-called"),
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
        assertEquals(payload.application_id, "existing-cancelled-free-id");
        assertEquals(checkBalanceRpcCalled, true, "check_party_balance RPC가 호출되어야 함 — Fix #1345");
        assertEquals(patchCalled, true, "PATCH(UPDATE)가 호출되어야 함 — INSERT 금지");
        assertEquals(applyEventRpcCalled, false, "apply_event RPC는 호출되면 안 됨 — plain INSERT로 충돌 발생");
        // Fix #1660: free re-application must use 'approved' status, not 'paid'
        assertEquals(patchBody?.status, "approved", "Fix #1660: 무료 재신청 PATCH status='approved' (not 'paid')");
      });
    });
  });
});

// Fix #1345: check_party_balance 거부 시 409 반환 — UPDATE 미호출 검증
Deno.test("apply-event - 취소 후 무료 재신청 — check_party_balance 거부 시 409 반환", async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

    let patchCalled = false;

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
        // 중복 신청 확인 — cancelled 상태로 존재
        matcher: (req) =>
          req.url.includes("/rest/v1/event_applications") && req.method === "GET",
        handler: () => jsonResponse({ id: "existing-cancelled-free-id", status: "cancelled" }),
      },
      {
        // check_party_balance — 성비 불균형으로 거부
        matcher: (req) => req.url.includes("/rest/v1/rpc/check_party_balance"),
        handler: () => jsonResponse({ allowed: false, reason: "남성 참가자 수가 초과되었습니다" }),
      },
      {
        matcher: (req) => {
          if (req.url.includes("/rest/v1/event_applications") && req.method === "PATCH") {
            patchCalled = true;
            return true;
          }
          return false;
        },
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

        assertEquals(response.status, 409);
        assertEquals(payload.error, "남성 참가자 수가 초과되었습니다");
        assertEquals(patchCalled, false, "balance 거부 시 UPDATE가 호출되면 안 됨");
      });
    });
  });
});

// ──────────────────────────────────────────────
// Bug #1342 Bug2: 유료 경로에서 verification_data 저장 확인
// ──────────────────────────────────────────────

Deno.test("apply-event - 유료 신규 신청 시 verification_data 저장 확인", async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

    let uvUpsertCalled = false;
    let vsInsertCalled = false;

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
        // Fix #1492: 유료 경로 check_party_balance — 허용
        matcher: (req) => req.url.includes("/rest/v1/rpc/check_party_balance"),
        handler: () => jsonResponse({ allowed: true, reason: null }),
      },
      {
        // 유료: payment_pending 레코드 INSERT
        matcher: (req) =>
          req.url.includes("/rest/v1/event_applications") && req.method === "POST",
        handler: () => jsonResponse([]),
      },
      {
        // user_verifications UPSERT
        matcher: (req) => {
          if (req.url.includes("/rest/v1/user_verifications") && req.method === "POST") {
            uvUpsertCalled = true;
            return true;
          }
          return false;
        },
        handler: () => jsonResponse([]),
      },
      {
        // verification_submissions INSERT
        matcher: (req) => {
          if (req.url.includes("/rest/v1/verification_submissions") && req.method === "POST") {
            vsInsertCalled = true;
            return true;
          }
          return false;
        },
        handler: () => jsonResponse([]),
      },
    ]);

    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = jsonRequest(
          "http://localhost",
          {
            event_id: "event-paid-1",
            ticket_id: "ticket-paid-1",
            verification_data: {
              verification_id: "verif-uuid-1",
              partner_id: "partner-uuid-1",
              data: { name: "홍길동", birth: "1990-01-01" },
            },
          },
          { headers: { Authorization: "Bearer test-token" } },
        );
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 200);
        assertEquals(payload.type, "paid");
        assertEquals(uvUpsertCalled, true, "user_verifications UPSERT가 호출되어야 함");
        assertEquals(vsInsertCalled, true, "verification_submissions INSERT가 호출되어야 함");
      });
    });
  });
});

Deno.test("apply-event - 유료 재신청 시 verification_data 저장 확인", async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

    let uvUpsertCalled = false;
    let vsInsertCalled = false;

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
        // 중복 신청 확인 — cancelled 상태로 존재
        matcher: (req) =>
          req.url.includes("/rest/v1/event_applications") && req.method === "GET",
        handler: () => jsonResponse({ id: "existing-cancelled-paid-id", status: "cancelled" }),
      },
      {
        // Fix #1492: 유료 경로 check_party_balance — 허용
        matcher: (req) => req.url.includes("/rest/v1/rpc/check_party_balance"),
        handler: () => jsonResponse({ allowed: true, reason: null }),
      },
      {
        // 재신청: PATCH (UPDATE)
        matcher: (req) =>
          req.url.includes("/rest/v1/event_applications") && req.method === "PATCH",
        handler: () => jsonResponse([]),
      },
      {
        // user_verifications UPSERT
        matcher: (req) => {
          if (req.url.includes("/rest/v1/user_verifications") && req.method === "POST") {
            uvUpsertCalled = true;
            return true;
          }
          return false;
        },
        handler: () => jsonResponse([]),
      },
      {
        // verification_submissions INSERT
        matcher: (req) => {
          if (req.url.includes("/rest/v1/verification_submissions") && req.method === "POST") {
            vsInsertCalled = true;
            return true;
          }
          return false;
        },
        handler: () => jsonResponse([]),
      },
    ]);

    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = jsonRequest(
          "http://localhost",
          {
            event_id: "event-paid-1",
            ticket_id: "ticket-paid-1",
            verification_data: {
              verification_id: "verif-uuid-1",
              partner_id: "partner-uuid-1",
              data: { name: "홍길동", birth: "1990-01-01" },
            },
          },
          { headers: { Authorization: "Bearer test-token" } },
        );
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 200);
        assertEquals(payload.type, "paid");
        assertEquals(payload.application_id, "existing-cancelled-paid-id");
        assertEquals(uvUpsertCalled, true, "user_verifications UPSERT가 호출되어야 함");
        assertEquals(vsInsertCalled, true, "verification_submissions INSERT가 호출되어야 함");
      });
    });
  });
});

// Fix #1492: 유료 경로 check_party_balance 거부 시 409 반환 — INSERT 미호출 검증
Deno.test("apply-event - 유료 신청 — check_party_balance 거부 시 409 반환", async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

    let insertCalled = false;

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
        // check_party_balance — 성비 불균형으로 거부
        matcher: (req) => req.url.includes("/rest/v1/rpc/check_party_balance"),
        handler: () => jsonResponse({ allowed: false, reason: "여성 참가자 수가 초과되었습니다" }),
      },
      {
        matcher: (req) => {
          if (req.url.includes("/rest/v1/event_applications") && req.method === "POST") {
            insertCalled = true;
            return true;
          }
          return false;
        },
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

        assertEquals(response.status, 409);
        assertEquals(payload.error, "여성 참가자 수가 초과되었습니다");
        assertEquals(insertCalled, false, "balance 거부 시 INSERT가 호출되면 안 됨");
      });
    });
  });
});
