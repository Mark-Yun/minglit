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
  SENTRY_DSN: "",
};

const AUTH_HEADER = { Authorization: "Bearer valid-token" };

/** Creates a fetch mock with auth + RPC route */
function buildFetchMock(rpcResponse: Record<string, unknown>) {
  return createFetchMock([
    {
      // Supabase auth.getUser
      matcher: (req) => req.url.includes("/auth/v1/user"),
      handler: () => jsonResponse({ id: "user-123", email: "test@example.com" }),
    },
    {
      // RPC call
      matcher: (req) =>
        req.url.includes("/rest/v1/rpc/create_order_validated"),
      handler: () => jsonResponse(rpcResponse),
    },
  ]);
}

// ============================================================
// Happy path tests
// ============================================================

Deno.test("user-create-order - paid order returns success with requires_payment=true", async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = buildFetchMock({
      success: true,
      application_id: "app-uuid-1",
      amount: 15000,
      requires_payment: true,
      ticket_name: "남성 티켓",
    });

    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = jsonRequest(
          "http://localhost",
          { event_id: "event-1", ticket_id: "ticket-1" },
          { headers: AUTH_HEADER },
        );
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 200);
        assertEquals(payload.success, true);
        assertEquals(payload.application_id, "app-uuid-1");
        assertEquals(payload.amount, 15000);
        assertEquals(payload.requires_payment, true);
        assertEquals(payload.ticket_name, "남성 티켓");
      });
    });
  });
});

Deno.test("user-create-order - free order returns success with requires_payment=false", async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = buildFetchMock({
      success: true,
      application_id: "app-uuid-2",
      amount: 0,
      requires_payment: false,
      ticket_name: "무료 티켓",
    });

    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = jsonRequest(
          "http://localhost",
          { event_id: "event-2", ticket_id: "ticket-free" },
          { headers: AUTH_HEADER },
        );
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 200);
        assertEquals(payload.success, true);
        assertEquals(payload.requires_payment, false);
        assertEquals(payload.amount, 0);
      });
    });
  });
});

// V1: amount field in request body is ignored (server uses ticket.price)
Deno.test("user-create-order - V1: amount in body is ignored, server amount returned", async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = buildFetchMock({
      success: true,
      application_id: "app-uuid-3",
      amount: 15000, // server-determined amount
      requires_payment: true,
      ticket_name: "티켓",
    });

    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        // Client sends amount: 1 (tampered), but server ignores it
        const request = jsonRequest(
          "http://localhost",
          { event_id: "event-1", ticket_id: "ticket-1", amount: 1 },
          { headers: AUTH_HEADER },
        );
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 200);
        assertEquals(payload.amount, 15000); // server amount, not 1
      });
    });
  });
});

// ============================================================
// Auth errors
// ============================================================

Deno.test("user-create-order - no auth header returns 401", async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([]);

    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = jsonRequest("http://localhost", {
          event_id: "event-1",
          ticket_id: "ticket-1",
        });
        const response = await handler(request);
        assertEquals(response.status, 401);
      });
    });
  });
});

Deno.test("user-create-order - invalid token returns 401", async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      {
        matcher: (req) => req.url.includes("/auth/v1/user"),
        handler: () => jsonResponse({ error: "Unauthorized" }, { status: 401 }),
      },
    ]);

    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = jsonRequest(
          "http://localhost",
          { event_id: "event-1", ticket_id: "ticket-1" },
          { headers: { Authorization: "Bearer bad-token" } },
        );
        const response = await handler(request);
        assertEquals(response.status, 401);
      });
    });
  });
});

// ============================================================
// Validation errors
// ============================================================

Deno.test("user-create-order - missing event_id returns 400", async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      {
        matcher: (req) => req.url.includes("/auth/v1/user"),
        handler: () => jsonResponse({ id: "user-123" }),
      },
    ]);

    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = jsonRequest(
          "http://localhost",
          { ticket_id: "ticket-1" },
          { headers: AUTH_HEADER },
        );
        const response = await handler(request);
        assertEquals(response.status, 400);
      });
    });
  });
});

Deno.test("user-create-order - malformed JSON returns 400", async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      {
        matcher: (req) => req.url.includes("/auth/v1/user"),
        handler: () => jsonResponse({ id: "user-123" }),
      },
    ]);

    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = new Request("http://localhost", {
          method: "POST",
          headers: { ...AUTH_HEADER, "Content-Type": "application/json" },
          body: "{oops",
        });
        const response = await handler(request);
        const payload = await readJson(response);
        assertEquals(response.status, 400);
        assertEquals(payload.error, "Invalid JSON body");
      });
    });
  });
});

// ============================================================
// DB function error codes → HTTP status mapping
// ============================================================

Deno.test("user-create-order - V2: TICKET_NOT_FOUND returns 404", async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = buildFetchMock({ error: "TICKET_NOT_FOUND" });

    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = jsonRequest(
          "http://localhost",
          { event_id: "event-1", ticket_id: "bad-ticket" },
          { headers: AUTH_HEADER },
        );
        const response = await handler(request);
        const payload = await readJson(response);
        assertEquals(response.status, 404);
        assertEquals(payload.error, "TICKET_NOT_FOUND");
      });
    });
  });
});

Deno.test("user-create-order - V3: TICKET_SOLD_OUT returns 400", async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = buildFetchMock({ error: "TICKET_SOLD_OUT" });

    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = jsonRequest(
          "http://localhost",
          { event_id: "event-1", ticket_id: "sold-ticket" },
          { headers: AUTH_HEADER },
        );
        const response = await handler(request);
        const payload = await readJson(response);
        assertEquals(response.status, 400);
        assertEquals(payload.error, "TICKET_SOLD_OUT");
      });
    });
  });
});

Deno.test("user-create-order - V4: EVENT_NOT_ACTIVE returns 400", async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = buildFetchMock({ error: "EVENT_NOT_ACTIVE" });

    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = jsonRequest(
          "http://localhost",
          { event_id: "old-event", ticket_id: "ticket-1" },
          { headers: AUTH_HEADER },
        );
        const response = await handler(request);
        const payload = await readJson(response);
        assertEquals(response.status, 400);
        assertEquals(payload.error, "EVENT_NOT_ACTIVE");
      });
    });
  });
});

Deno.test("user-create-order - V4: EVENT_NOT_FOUND returns 404", async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = buildFetchMock({ error: "EVENT_NOT_FOUND" });

    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = jsonRequest(
          "http://localhost",
          { event_id: "nonexistent-event", ticket_id: "ticket-1" },
          { headers: AUTH_HEADER },
        );
        const response = await handler(request);
        const payload = await readJson(response);
        assertEquals(response.status, 404);
        assertEquals(payload.error, "EVENT_NOT_FOUND");
      });
    });
  });
});

Deno.test("user-create-order - V5: EVENT_FULL returns 400", async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = buildFetchMock({ error: "EVENT_FULL" });

    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = jsonRequest(
          "http://localhost",
          { event_id: "full-event", ticket_id: "ticket-1" },
          { headers: AUTH_HEADER },
        );
        const response = await handler(request);
        const payload = await readJson(response);
        assertEquals(response.status, 400);
        assertEquals(payload.error, "EVENT_FULL");
      });
    });
  });
});

Deno.test("user-create-order - V6: ELIGIBILITY_FAILED (gender) returns 400", async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = buildFetchMock({ error: "ELIGIBILITY_FAILED", reason: "gender_mismatch" });

    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = jsonRequest(
          "http://localhost",
          { event_id: "event-1", ticket_id: "male-ticket" },
          { headers: AUTH_HEADER },
        );
        const response = await handler(request);
        const payload = await readJson(response);
        assertEquals(response.status, 400);
        assertEquals(payload.error, "ELIGIBILITY_FAILED");
      });
    });
  });
});

Deno.test("user-create-order - V6: ELIGIBILITY_FAILED (age) returns 400", async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = buildFetchMock({ error: "ELIGIBILITY_FAILED", reason: "age_out_of_range" });

    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = jsonRequest(
          "http://localhost",
          { event_id: "event-1", ticket_id: "age-ticket" },
          { headers: AUTH_HEADER },
        );
        const response = await handler(request);
        const payload = await readJson(response);
        assertEquals(response.status, 400);
        assertEquals(payload.error, "ELIGIBILITY_FAILED");
      });
    });
  });
});

Deno.test("user-create-order - V8: VERIFICATION_REQUIRED returns 400", async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = buildFetchMock({ error: "VERIFICATION_REQUIRED" });

    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = jsonRequest(
          "http://localhost",
          { event_id: "event-1", ticket_id: "ticket-1" },
          { headers: AUTH_HEADER },
        );
        const response = await handler(request);
        const payload = await readJson(response);
        assertEquals(response.status, 400);
        assertEquals(payload.error, "VERIFICATION_REQUIRED");
      });
    });
  });
});

Deno.test("user-create-order - ALREADY_APPLIED returns 409", async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = buildFetchMock({ error: "ALREADY_APPLIED", application_id: "existing-app" });

    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = jsonRequest(
          "http://localhost",
          { event_id: "event-1", ticket_id: "ticket-1" },
          { headers: AUTH_HEADER },
        );
        const response = await handler(request);
        const payload = await readJson(response);
        assertEquals(response.status, 409);
        assertEquals(payload.error, "ALREADY_APPLIED");
      });
    });
  });
});

Deno.test("user-create-order - BALANCE_LIMIT returns 400", async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = buildFetchMock({ error: "BALANCE_LIMIT", reason: "성비 조절 중" });

    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = jsonRequest(
          "http://localhost",
          { event_id: "event-1", ticket_id: "ticket-1" },
          { headers: AUTH_HEADER },
        );
        const response = await handler(request);
        const payload = await readJson(response);
        assertEquals(response.status, 400);
        assertEquals(payload.error, "BALANCE_LIMIT");
      });
    });
  });
});

// ============================================================
// CORS
// ============================================================

Deno.test("user-create-order - OPTIONS returns CORS response", async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([]);

    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = new Request("http://localhost", { method: "OPTIONS" });
        const response = await handler(request);
        assertEquals(response.status, 200);
        assertEquals(response.headers.get("Access-Control-Allow-Origin"), "*");
      });
    });
  });
});

// ============================================================
// RPC error (500)
// ============================================================

Deno.test("user-create-order - RPC error returns 500", async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      {
        matcher: (req) => req.url.includes("/auth/v1/user"),
        handler: () => jsonResponse({ id: "user-123" }),
      },
      {
        matcher: (req) => req.url.includes("/rest/v1/rpc/create_order_validated"),
        handler: () => jsonResponse({ message: "DB error" }, { status: 500 }),
      },
    ]);

    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = jsonRequest(
          "http://localhost",
          { event_id: "event-1", ticket_id: "ticket-1" },
          { headers: AUTH_HEADER },
        );
        const response = await handler(request);
        assertEquals(response.status, 500);
      });
    });
  });
});
