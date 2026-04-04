import { assertEquals } from "@std/assert";
import {
  authenticatedJsonRequest,
  captureServeHandler,
  createFetchMock,
  jsonResponse,
  readJson,
  textRequest,
  withNoIntervals,
  withEnv,
  withMockedFetch,
} from "../_test_utils/mock_http.ts";
import { authRoute } from "../_test_utils/fixtures.ts";

// Statsig uses node:timers setInterval internally, which withNoIntervals cannot patch.
const TEST_OPTS = { sanitizeOps: false, sanitizeResources: false };

const ENV = {
  SUPABASE_URL: "https://supabase.test",
  SUPABASE_SERVICE_ROLE_KEY: "service-key",
};

const MOCK_EVENT = {
  id: "event-1",
  party_id: "party-1",
  status: "scheduled",
  start_time: new Date(Date.now() + 86400000).toISOString(), // tomorrow
  max_participants: 20,
  current_participants: 5,
};

const MOCK_TICKET = {
  id: "ticket-1",
  event_id: "event-1",
  name: "일반 티켓",
  price: 15000,
  quantity: 10,
  sold_count: 3,
  target_entry_group_ids: ["group-1"],
};

const MOCK_FREE_TICKET = {
  ...MOCK_TICKET,
  id: "ticket-free",
  price: 0,
};

const MOCK_USER_PROFILE = {
  id: "user-123",
  is_verified: true,
  gender: "male",
  birth_date: "1995-06-15",
};

const MOCK_ENTRY_GROUP = {
  id: "group-1",
  gender: "male",
  birth_year_min: 1990,
  birth_year_max: 2000,
  required_verification_ids: [],
};

const MOCK_BALANCE_OK = { allowed: true, reason: null };

function restRoute(
  table: string,
  method: string,
  response: unknown,
  status = 200,
) {
  return {
    matcher: (req: Request) =>
      req.url.includes(`/rest/v1/${table}`) && req.method === method,
    handler: () => jsonResponse(response, { status }),
  };
}

function rpcRoute(rpcName: string, response: unknown) {
  return {
    matcher: (req: Request) => req.url.includes(`/rest/v1/rpc/${rpcName}`),
    handler: () => jsonResponse(response),
  };
}

// ---------- Happy Path: Paid Event ----------

Deno.test({ name: "user-create-order - happy path: paid event creates order", ...TEST_OPTS, fn: async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute,
      restRoute("events", "GET", MOCK_EVENT),
      restRoute("tickets", "GET", MOCK_TICKET),
      restRoute("user_profiles", "GET", MOCK_USER_PROFILE),
      restRoute("entry_groups", "GET", [MOCK_ENTRY_GROUP]),
      rpcRoute("check_party_balance", MOCK_BALANCE_OK),
      restRoute("event_applications", "GET", null),
      rpcRoute("apply_event", "app-id-1"),
      restRoute("event_applications", "PATCH", {}),
    ]);

    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = authenticatedJsonRequest("http://localhost", {
          event_id: "event-1",
          ticket_id: "ticket-1",
        });
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 200);
        assertEquals(payload.success, true);
        assertEquals(payload.amount, 15000);
        assertEquals(payload.requires_payment, true);
        assertEquals(payload.ticket_name, "일반 티켓");
        assertEquals(typeof payload.application_id, "string");
      });
    });
  });
}});

// ---------- Happy Path: Free Event ----------

Deno.test({ name: "user-create-order - happy path: free event creates order with requires_payment=false", ...TEST_OPTS, fn: async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute,
      restRoute("events", "GET", MOCK_EVENT),
      restRoute("tickets", "GET", MOCK_FREE_TICKET),
      restRoute("user_profiles", "GET", MOCK_USER_PROFILE),
      restRoute("entry_groups", "GET", [MOCK_ENTRY_GROUP]),
      rpcRoute("check_party_balance", MOCK_BALANCE_OK),
      restRoute("event_applications", "GET", null),
      rpcRoute("apply_event", "app-id-2"),
      restRoute("event_applications", "PATCH", {}),
    ]);

    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = authenticatedJsonRequest("http://localhost", {
          event_id: "event-1",
          ticket_id: "ticket-free",
        });
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 200);
        assertEquals(payload.success, true);
        assertEquals(payload.amount, 0);
        assertEquals(payload.requires_payment, false);
      });
    });
  });
}});

// ---------- Auth Errors ----------

Deno.test({ name: "user-create-order - unauthenticated request returns 401", ...TEST_OPTS, fn: async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      {
        matcher: (req: Request) => req.url.includes("/auth/v1/user"),
        handler: () => jsonResponse({ error: "invalid" }, { status: 401 }),
      },
    ]);

    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = authenticatedJsonRequest("http://localhost", {
          event_id: "event-1",
          ticket_id: "ticket-1",
        });
        const response = await handler(request);

        assertEquals(response.status, 401);
      });
    });
  });
}});

// ---------- Input Validation ----------

Deno.test({ name: "user-create-order - missing event_id returns 400", ...TEST_OPTS, fn: async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([authRoute]);

    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = authenticatedJsonRequest("http://localhost", {
          ticket_id: "ticket-1",
        });
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 400);
        assertEquals(payload.error, "Missing required field: event_id");
      });
    });
  });
}});

Deno.test({ name: "user-create-order - missing ticket_id returns 400", ...TEST_OPTS, fn: async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([authRoute]);

    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = authenticatedJsonRequest("http://localhost", {
          event_id: "event-1",
        });
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 400);
        assertEquals(payload.error, "Missing required field: ticket_id");
      });
    });
  });
}});

Deno.test({ name: "user-create-order - malformed JSON returns 400", ...TEST_OPTS, fn: async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([authRoute]);

    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = textRequest("http://localhost", "{invalid", {
          headers: { Authorization: "Bearer test-token" },
        });
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 400);
        assertEquals(payload.error, "Invalid JSON body");
      });
    });
  });
}});

// ---------- Event Validation ----------

Deno.test({ name: "user-create-order - nonexistent event returns 404", ...TEST_OPTS, fn: async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute,
      {
        matcher: (req: Request) => req.url.includes("/rest/v1/events") && req.method === "GET",
        handler: () => jsonResponse({ message: "not found" }, { status: 406 }),
      },
    ]);

    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = authenticatedJsonRequest("http://localhost", {
          event_id: "nonexistent",
          ticket_id: "ticket-1",
        });
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 404);
        assertEquals(payload.error, "이벤트를 찾을 수 없습니다.");
      });
    });
  });
}});

Deno.test({ name: "user-create-order - cancelled event returns EVENT_CLOSED", ...TEST_OPTS, fn: async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute,
      restRoute("events", "GET", { ...MOCK_EVENT, status: "cancelled" }),
    ]);

    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = authenticatedJsonRequest("http://localhost", {
          event_id: "event-1",
          ticket_id: "ticket-1",
        });
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 400);
        // Fix #998: error code renamed from EVENT_NOT_SCHEDULED to EVENT_CLOSED
        // (active events are now allowed; only non-schedulable statuses are closed)
        assertEquals(payload.details.code, "EVENT_CLOSED");
      });
    });
  });
}});

Deno.test({ name: "user-create-order - past event returns EVENT_NOT_SCHEDULED", ...TEST_OPTS, fn: async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute,
      restRoute("events", "GET", {
        ...MOCK_EVENT,
        start_time: new Date(Date.now() - 86400000).toISOString(),
      }),
    ]);

    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = authenticatedJsonRequest("http://localhost", {
          event_id: "event-1",
          ticket_id: "ticket-1",
        });
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 400);
        assertEquals(payload.details.code, "EVENT_NOT_SCHEDULED");
      });
    });
  });
}});

// ---------- Ticket Validation ----------

Deno.test({ name: "user-create-order - ticket not belonging to event returns 404", ...TEST_OPTS, fn: async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute,
      restRoute("events", "GET", MOCK_EVENT),
      restRoute("tickets", "GET", { ...MOCK_TICKET, event_id: "other-event" }),
    ]);

    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = authenticatedJsonRequest("http://localhost", {
          event_id: "event-1",
          ticket_id: "ticket-1",
        });
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 404);
        assertEquals(payload.error, "티켓을 찾을 수 없습니다.");
      });
    });
  });
}});

Deno.test({ name: "user-create-order - sold out ticket returns TICKET_SOLD_OUT", ...TEST_OPTS, fn: async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute,
      restRoute("events", "GET", MOCK_EVENT),
      restRoute("tickets", "GET", { ...MOCK_TICKET, sold_count: 10 }),
    ]);

    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = authenticatedJsonRequest("http://localhost", {
          event_id: "event-1",
          ticket_id: "ticket-1",
        });
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 400);
        assertEquals(payload.details.code, "TICKET_SOLD_OUT");
      });
    });
  });
}});

// ---------- Capacity ----------

Deno.test({ name: "user-create-order - full event returns EVENT_FULL", ...TEST_OPTS, fn: async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute,
      restRoute("events", "GET", { ...MOCK_EVENT, current_participants: 20 }),
      restRoute("tickets", "GET", MOCK_TICKET),
    ]);

    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = authenticatedJsonRequest("http://localhost", {
          event_id: "event-1",
          ticket_id: "ticket-1",
        });
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 400);
        assertEquals(payload.details.code, "EVENT_FULL");
      });
    });
  });
}});

// ---------- Identity Verification ----------

Deno.test({ name: "user-create-order - unverified user returns IDENTITY_REQUIRED", ...TEST_OPTS, fn: async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute,
      restRoute("events", "GET", MOCK_EVENT),
      restRoute("tickets", "GET", MOCK_TICKET),
      restRoute("user_profiles", "GET", { ...MOCK_USER_PROFILE, is_verified: false }),
    ]);

    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = authenticatedJsonRequest("http://localhost", {
          event_id: "event-1",
          ticket_id: "ticket-1",
        });
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 400);
        assertEquals(payload.details.code, "IDENTITY_REQUIRED");
      });
    });
  });
}});

// ---------- Gender Mismatch ----------

Deno.test({ name: "user-create-order - gender mismatch returns GENDER_MISMATCH", ...TEST_OPTS, fn: async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute,
      restRoute("events", "GET", MOCK_EVENT),
      restRoute("tickets", "GET", MOCK_TICKET),
      restRoute("user_profiles", "GET", { ...MOCK_USER_PROFILE, gender: "female" }),
      restRoute("entry_groups", "GET", [MOCK_ENTRY_GROUP]),
    ]);

    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = authenticatedJsonRequest("http://localhost", {
          event_id: "event-1",
          ticket_id: "ticket-1",
        });
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 400);
        assertEquals(payload.details.code, "GENDER_MISMATCH");
      });
    });
  });
}});

// ---------- Age Mismatch ----------

Deno.test({ name: "user-create-order - age mismatch returns AGE_MISMATCH", ...TEST_OPTS, fn: async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute,
      restRoute("events", "GET", MOCK_EVENT),
      restRoute("tickets", "GET", MOCK_TICKET),
      restRoute("user_profiles", "GET", { ...MOCK_USER_PROFILE, birth_date: "1985-01-01" }),
      restRoute("entry_groups", "GET", [MOCK_ENTRY_GROUP]),
    ]);

    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = authenticatedJsonRequest("http://localhost", {
          event_id: "event-1",
          ticket_id: "ticket-1",
        });
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 400);
        assertEquals(payload.details.code, "AGE_MISMATCH");
      });
    });
  });
}});

// ---------- Balance Limit ----------

Deno.test({ name: "user-create-order - balance limit returns BALANCE_LIMIT", ...TEST_OPTS, fn: async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute,
      restRoute("events", "GET", MOCK_EVENT),
      restRoute("tickets", "GET", MOCK_TICKET),
      restRoute("user_profiles", "GET", MOCK_USER_PROFILE),
      restRoute("entry_groups", "GET", [MOCK_ENTRY_GROUP]),
      rpcRoute("check_party_balance", { allowed: false, reason: "성비 조절 중" }),
    ]);

    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = authenticatedJsonRequest("http://localhost", {
          event_id: "event-1",
          ticket_id: "ticket-1",
        });
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 400);
        assertEquals(payload.details.code, "BALANCE_LIMIT");
      });
    });
  });
}});

// ---------- Duplicate Application ----------

Deno.test({ name: "user-create-order - duplicate application returns ALREADY_APPLIED", ...TEST_OPTS, fn: async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute,
      restRoute("events", "GET", MOCK_EVENT),
      restRoute("tickets", "GET", MOCK_TICKET),
      restRoute("user_profiles", "GET", MOCK_USER_PROFILE),
      restRoute("entry_groups", "GET", [MOCK_ENTRY_GROUP]),
      rpcRoute("check_party_balance", MOCK_BALANCE_OK),
      restRoute("event_applications", "GET", { id: "existing-app", status: "approved" }),
    ]);

    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = authenticatedJsonRequest("http://localhost", {
          event_id: "event-1",
          ticket_id: "ticket-1",
        });
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 400);
        assertEquals(payload.details.code, "ALREADY_APPLIED");
      });
    });
  });
}});

// ---------- Verification Required ----------

Deno.test({ name: "user-create-order - missing verification data returns VERIFICATION_REQUIRED", ...TEST_OPTS, fn: async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute,
      restRoute("events", "GET", MOCK_EVENT),
      restRoute("tickets", "GET", MOCK_TICKET),
      restRoute("user_profiles", "GET", MOCK_USER_PROFILE),
      restRoute("entry_groups", "GET", [{
        ...MOCK_ENTRY_GROUP,
        required_verification_ids: ["ver-1"],
      }]),
    ]);

    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = authenticatedJsonRequest("http://localhost", {
          event_id: "event-1",
          ticket_id: "ticket-1",
          // no verification_data
        });
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 400);
        assertEquals(payload.details.code, "VERIFICATION_REQUIRED");
      });
    });
  });
}});
