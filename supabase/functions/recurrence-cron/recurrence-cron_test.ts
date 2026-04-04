import { assertEquals } from "@std/assert";
import { FakeTime } from "@std/testing/time";
import {
  captureServeHandler,
  createFetchMock,
  jsonResponse,
  readJson,
  withEnv,
  withMockedFetch,
  withNoIntervals,
  type FetchRoute,
} from "../_test_utils/mock_http.ts";

const TEST_OPTS = { sanitizeOps: false, sanitizeResources: false };

const ENV = {
  SUPABASE_URL: "https://supabase.test",
  SUPABASE_SERVICE_ROLE_KEY: "test-service-key",
};

const TODAY = "2026-04-05";
const RULE_ID = "aaaaaaaa-0000-0000-0000-000000000001";
const PARTY_ID = "bbbbbbbb-0000-0000-0000-000000000001";
const EVENT_ID = "cccccccc-0000-0000-0000-000000000001";

function serviceRoleRequest(url = "http://localhost"): Request {
  return new Request(url, {
    method: "POST",
    headers: {
      "Authorization": "Bearer test-service-key",
      "Content-Type": "application/json",
    },
    body: JSON.stringify({}),
  });
}

function makeRule(overrides: Record<string, unknown> = {}): Record<string, unknown> {
  return {
    id: RULE_ID,
    party_id: PARTY_ID,
    pattern: "weekly",
    days_of_week: [1, 5], // Monday and Friday
    month_day: null,
    start_time: "18:00:00",
    end_time: "23:00:00",
    end_date: null,
    status: "active",
    last_generated_date: null,
    created_at: "2026-01-01T00:00:00Z",
    ...overrides,
  };
}

/** Route: GET recurrence_rules returns the given rules array */
function rulesRoute(rules: unknown[]): FetchRoute {
  return {
    matcher: (req: Request) =>
      req.url.includes("/rest/v1/recurrence_rules") && req.method === "GET",
    handler: () => jsonResponse(rules),
  };
}

/** Route: POST events → returns inserted event */
function eventsInsertRoute(eventId = EVENT_ID): FetchRoute {
  return {
    matcher: (req: Request) =>
      req.url.includes("/rest/v1/events") && req.method === "POST",
    handler: () => jsonResponse({ id: eventId }),
  };
}

/** Route: POST events → returns null (simulate duplicate / ON CONFLICT DO NOTHING) */
function eventsInsertDuplicateRoute(): FetchRoute {
  return {
    matcher: (req: Request) =>
      req.url.includes("/rest/v1/events") && req.method === "POST",
    handler: () => jsonResponse(null),
  };
}

/** Route: POST events → returns 23505 conflict error */
function eventsInsert23505Route(): FetchRoute {
  return {
    matcher: (req: Request) =>
      req.url.includes("/rest/v1/events") && req.method === "POST",
    handler: () =>
      jsonResponse(
        { code: "23505", message: "duplicate key value violates unique constraint" },
        { status: 409 },
      ),
  };
}

/** Route: GET entry_group_templates returns empty array */
const entryGroupTemplatesEmpty: FetchRoute = {
  matcher: (req: Request) =>
    req.url.includes("/rest/v1/entry_group_templates") && req.method === "GET",
  handler: () => jsonResponse([]),
};

/** Route: GET ticket_templates returns empty array */
const ticketTemplatesEmpty: FetchRoute = {
  matcher: (req: Request) =>
    req.url.includes("/rest/v1/ticket_templates") && req.method === "GET",
  handler: () => jsonResponse([]),
};

/** Route: PATCH recurrence_rules → success */
const rulesUpdateRoute: FetchRoute = {
  matcher: (req: Request) =>
    req.url.includes("/rest/v1/recurrence_rules") && req.method === "PATCH",
  handler: () => jsonResponse({}),
};

// ─── Auth tests ───────────────────────────────────────────────────────────────

Deno.test("recurrence-cron - missing auth returns 401", TEST_OPTS, async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );
    await withNoIntervals(async () => {
      const req = new Request("http://localhost", { method: "POST" });
      const res = await handler(req);
      assertEquals(res.status, 401);
    });
  });
});

Deno.test("recurrence-cron - wrong service role key returns 401", TEST_OPTS, async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );
    await withNoIntervals(async () => {
      const req = new Request("http://localhost", {
        method: "POST",
        headers: { Authorization: "Bearer wrong-key" },
      });
      const res = await handler(req);
      assertEquals(res.status, 401);
    });
  });
});

Deno.test("recurrence-cron - OPTIONS preflight returns 200", TEST_OPTS, async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );
    await withNoIntervals(async () => {
      const req = new Request("http://localhost", { method: "OPTIONS" });
      const res = await handler(req);
      assertEquals(res.status, 200);
    });
  });
});

// ─── Happy path: weekly rule generates correct events ──────────────────────────

Deno.test(
  "recurrence-cron - weekly rule with 2 days generates ~8-9 events over 30 days",
  TEST_OPTS,
  async () => {
    await withEnv(ENV, async () => {
      const handler = await captureServeHandler(
        new URL("./index.ts", import.meta.url),
      );

      let eventInsertCount = 0;
      const { fetchMock } = createFetchMock([
        rulesRoute([makeRule()]), // weekly Mon+Fri, no last_generated_date
        entryGroupTemplatesEmpty,
        ticketTemplatesEmpty,
        {
          matcher: (req: Request) =>
            req.url.includes("/rest/v1/events") && req.method === "POST",
          handler: () => {
            eventInsertCount += 1;
            return jsonResponse({ id: `event-${eventInsertCount}` });
          },
        },
        rulesUpdateRoute,
      ]);

      await withMockedFetch(fetchMock, async () => {
        await withNoIntervals(async () => {
          const res = await handler(serviceRoleRequest());
          const payload = await readJson(res);

          assertEquals(res.status, 200);
          assertEquals(payload.processed, 1);
          // 30-day window with Mon+Fri: expect 8 or 9 events
          const totalEvents = payload.total_events as number;
          assertEquals(totalEvents >= 8 && totalEvents <= 9, true);
        });
      });
    });
  },
);

// ─── Paused rules are skipped ──────────────────────────────────────────────────

Deno.test(
  "recurrence-cron - paused rule is not returned by query and generates 0 events",
  TEST_OPTS,
  async () => {
    await withEnv(ENV, async () => {
      const handler = await captureServeHandler(
        new URL("./index.ts", import.meta.url),
      );

      // The DB query filters by status='active', so paused rules return empty array
      const { fetchMock } = createFetchMock([
        rulesRoute([]), // No active rules (paused/cancelled filtered out by DB)
      ]);

      await withMockedFetch(fetchMock, async () => {
        await withNoIntervals(async () => {
          const res = await handler(serviceRoleRequest());
          const payload = await readJson(res);

          assertEquals(res.status, 200);
          assertEquals(payload.processed, 0);
          assertEquals(payload.total_events, 0);
        });
      });
    });
  },
);

// ─── Cancelled rules are skipped ──────────────────────────────────────────────

Deno.test(
  "recurrence-cron - cancelled rule generates 0 events",
  TEST_OPTS,
  async () => {
    await withEnv(ENV, async () => {
      const handler = await captureServeHandler(
        new URL("./index.ts", import.meta.url),
      );

      // The DB query filters by status='active', so cancelled rules not returned
      const { fetchMock } = createFetchMock([
        rulesRoute([]),
      ]);

      await withMockedFetch(fetchMock, async () => {
        await withNoIntervals(async () => {
          const res = await handler(serviceRoleRequest());
          const payload = await readJson(res);

          assertEquals(res.status, 200);
          assertEquals(payload.processed, 0);
          assertEquals(payload.total_events, 0);
        });
      });
    });
  },
);

// ─── end_date in the past → 0 events ─────────────────────────────────────────

Deno.test(
  "recurrence-cron - rule with end_date in the past generates 0 events",
  TEST_OPTS,
  async () => {
    await withEnv(ENV, async () => {
      const handler = await captureServeHandler(
        new URL("./index.ts", import.meta.url),
      );

      const rule = makeRule({ end_date: "2026-01-01" }); // far in the past

      const { fetchMock } = createFetchMock([
        rulesRoute([rule]),
        entryGroupTemplatesEmpty,
        ticketTemplatesEmpty,
        rulesUpdateRoute,
      ]);

      await withMockedFetch(fetchMock, async () => {
        await withNoIntervals(async () => {
          const res = await handler(serviceRoleRequest());
          const payload = await readJson(res);

          assertEquals(res.status, 200);
          assertEquals(payload.processed, 1);
          assertEquals(payload.total_events, 0);
        });
      });
    });
  },
);

// ─── end_date in 10 days → events only up to end_date ─────────────────────────

Deno.test(
  "recurrence-cron - rule with end_date in 10 days limits event generation",
  TEST_OPTS,
  async () => {
    await withEnv(ENV, async () => {
      const handler = await captureServeHandler(
        new URL("./index.ts", import.meta.url),
      );

      // end_date = today + 10 days (computed dynamically so the test is date-independent)
      const todayUtc = new Date().toISOString().split("T")[0];
      const endDateMs = new Date(`${todayUtc}T00:00:00Z`).getTime() + 10 * 24 * 60 * 60 * 1000;
      const endDateStr = new Date(endDateMs).toISOString().split("T")[0];
      const rule = makeRule({
        end_date: endDateStr,
        days_of_week: [0, 1, 2, 3, 4, 5, 6], // every day
      });

      let eventInsertCount = 0;
      const { fetchMock } = createFetchMock([
        rulesRoute([rule]),
        entryGroupTemplatesEmpty,
        ticketTemplatesEmpty,
        {
          matcher: (req: Request) =>
            req.url.includes("/rest/v1/events") && req.method === "POST",
          handler: () => {
            eventInsertCount += 1;
            return jsonResponse({ id: `event-${eventInsertCount}` });
          },
        },
        rulesUpdateRoute,
      ]);

      await withMockedFetch(fetchMock, async () => {
        await withNoIntervals(async () => {
          const res = await handler(serviceRoleRequest());
          const payload = await readJson(res);

          assertEquals(res.status, 200);
          assertEquals(payload.processed, 1);
          // From today to today+10 inclusive = 11 days, all days of week → exactly 11 events
          assertEquals(payload.total_events, 11);
        });
      });
    });
  },
);

// ─── Monthly pattern: generates only on month_day ─────────────────────────────

Deno.test(
  "recurrence-cron - monthly rule generates events only on month_day",
  TEST_OPTS,
  async () => {
    // Freeze clock at 2026-04-05: window = [2026-04-05, 2026-05-05]
    // month_day=15 → only 2026-04-15 qualifies → exactly 1 event
    const fakeTime = new FakeTime("2026-04-05T00:00:00Z");
    try {
      await withEnv(ENV, async () => {
        const handler = await captureServeHandler(
          new URL("./index.ts", import.meta.url),
        );

        const rule = makeRule({
          pattern: "monthly",
          days_of_week: [],
          month_day: 15,
        });

        let eventInsertCount = 0;
        const { fetchMock } = createFetchMock([
          rulesRoute([rule]),
          entryGroupTemplatesEmpty,
          ticketTemplatesEmpty,
          {
            matcher: (req: Request) =>
              req.url.includes("/rest/v1/events") && req.method === "POST",
            handler: () => {
              eventInsertCount += 1;
              return jsonResponse({ id: `event-${eventInsertCount}` });
            },
          },
          rulesUpdateRoute,
        ]);

        await withMockedFetch(fetchMock, async () => {
          await withNoIntervals(async () => {
            const res = await handler(serviceRoleRequest());
            const payload = await readJson(res);

            assertEquals(res.status, 200);
            assertEquals(payload.processed, 1);
            // Frozen at 2026-04-05 → window [Apr 5, May 5] → month_day=15 → Apr 15 → 1 event
            assertEquals(payload.total_events, 1);
          });
        });
      });
    } finally {
      fakeTime.restore();
    }
  },
);

// ─── Duplicate events are counted as skipped ──────────────────────────────────

Deno.test(
  "recurrence-cron - duplicate events (23505) are counted as skipped, not errors",
  TEST_OPTS,
  async () => {
    // Freeze clock: window [2026-04-05, 2026-05-05], month_day=15 → exactly 1 candidate date
    const fakeTime = new FakeTime("2026-04-05T00:00:00Z");
    try {
      await withEnv(ENV, async () => {
        const handler = await captureServeHandler(
          new URL("./index.ts", import.meta.url),
        );

        const rule = makeRule({
          pattern: "monthly",
          days_of_week: [],
          month_day: 15,
        });

        const { fetchMock } = createFetchMock([
          rulesRoute([rule]),
          entryGroupTemplatesEmpty,
          ticketTemplatesEmpty,
          eventsInsert23505Route(), // simulate already-existing duplicate
          rulesUpdateRoute,
        ]);

        await withMockedFetch(fetchMock, async () => {
          await withNoIntervals(async () => {
            const res = await handler(serviceRoleRequest());
            const payload = await readJson(res);

            assertEquals(res.status, 200);
            assertEquals(payload.processed, 1);
            assertEquals(payload.total_events, 0);
            assertEquals(payload.total_skipped, 1);
            assertEquals(payload.total_errors, 0);
          });
        });
      });
    } finally {
      fakeTime.restore();
    }
  },
);

// ─── entry_group_templates + ticket_templates are copied ──────────────────────

Deno.test(
  "recurrence-cron - entry_group_templates and ticket_templates are copied for each event",
  TEST_OPTS,
  async () => {
    // Freeze clock: window [2026-04-05, 2026-05-05], month_day=15 → exactly 1 event
    const fakeTime = new FakeTime("2026-04-05T00:00:00Z");
    try {
    await withEnv(ENV, async () => {
      const handler = await captureServeHandler(
        new URL("./index.ts", import.meta.url),
      );

      // Single event: monthly on day 15
      const rule = makeRule({
        pattern: "monthly",
        days_of_week: [],
        month_day: 15,
      });

      const templateGroupId = "tpl-group-001";
      const newGroupId = "new-group-001";

      let ticketInsertBody: unknown = null;

      const { fetchMock } = createFetchMock([
        rulesRoute([rule]),
        // entry_group_templates
        {
          matcher: (req: Request) =>
            req.url.includes("/rest/v1/entry_group_templates") && req.method === "GET",
          handler: () =>
            jsonResponse([{
              id: templateGroupId,
              party_id: PARTY_ID,
              label: "일반",
              gender: null,
              birth_year_min: null,
              birth_year_max: null,
              required_verification_ids: [],
            }]),
        },
        // ticket_templates referencing the template group
        {
          matcher: (req: Request) =>
            req.url.includes("/rest/v1/ticket_templates") && req.method === "GET",
          handler: () =>
            jsonResponse([{
              id: "tpl-ticket-001",
              party_id: PARTY_ID,
              name: "일반 입장권",
              price: 20000,
              quantity: 100,
              target_entry_group_ids: [templateGroupId],
            }]),
        },
        // events insert
        eventsInsertRoute(),
        // entry_groups insert → return new group with mapped id
        {
          matcher: (req: Request) =>
            req.url.includes("/rest/v1/entry_groups") && req.method === "POST",
          handler: () => jsonResponse([{ id: newGroupId, label: "일반" }]),
        },
        // tickets insert — capture body
        {
          matcher: (req: Request) =>
            req.url.includes("/rest/v1/tickets") && req.method === "POST",
          handler: async (req: Request) => {
            ticketInsertBody = await req.json();
            return jsonResponse([{}]);
          },
        },
        rulesUpdateRoute,
      ]);

      await withMockedFetch(fetchMock, async () => {
        await withNoIntervals(async () => {
          const res = await handler(serviceRoleRequest());
          const payload = await readJson(res);

          assertEquals(res.status, 200);
          assertEquals(payload.total_events, 1);

          // Ticket target_entry_group_ids should reference new group id, not template id
          const ticketRows = ticketInsertBody as Array<{ target_entry_group_ids: string[] }>;
          assertEquals(ticketRows[0].target_entry_group_ids[0], newGroupId);
        });
      });
    });
    } finally {
      fakeTime.restore();
    }
  },
);

// ─── No active rules → processed=0 ───────────────────────────────────────────

Deno.test(
  "recurrence-cron - no active rules returns processed=0",
  TEST_OPTS,
  async () => {
    await withEnv(ENV, async () => {
      const handler = await captureServeHandler(
        new URL("./index.ts", import.meta.url),
      );

      const { fetchMock } = createFetchMock([
        rulesRoute([]),
      ]);

      await withMockedFetch(fetchMock, async () => {
        await withNoIntervals(async () => {
          const res = await handler(serviceRoleRequest());
          const payload = await readJson(res);

          assertEquals(res.status, 200);
          assertEquals(payload.processed, 0);
          assertEquals(payload.total_events, 0);
        });
      });
    });
  },
);
