import { assertEquals } from "@std/assert";
import {
  authenticatedJsonRequest,
  captureServeHandler,
  createFetchMock,
  jsonResponse,
  readJson,
  withEnv,
  withMockedFetch,
  type FetchRoute,
} from "../_test_utils/mock_http.ts";

const TEST_VOTER_ID = "voter-001";
const TEST_CANDIDATE_ID = "candidate-001";
const TEST_EVENT_ID = "event-001";
const TEST_TICKET_VOTER = "ticket-voter";
const TEST_TICKET_CANDIDATE = "ticket-candidate";
const GROUP_MALE = "group-male";
const GROUP_FEMALE = "group-female";

const ENV = {
  SUPABASE_URL: "http://localhost:54321",
  SUPABASE_SERVICE_ROLE_KEY: "test-service-key",
};

function authRoute(): FetchRoute {
  return {
    matcher: "/auth/v1/user",
    handler: () => jsonResponse({ id: TEST_VOTER_ID, email: "voter@test.com" }),
  };
}

// Event with vote period active
function eventRoute(overrides?: {
  vote_start_at?: string | null;
  vote_end_at?: string | null;
  status?: string;
}): FetchRoute {
  return {
    matcher: (req) => req.url.includes("/rest/v1/events") && req.url.includes("select="),
    handler: () =>
      jsonResponse({
        id: TEST_EVENT_ID,
        status: overrides?.status ?? "ongoing",
        vote_start_at: overrides?.vote_start_at !== undefined
          ? overrides.vote_start_at
          : "2026-01-01T00:00:00Z",
        vote_end_at: overrides?.vote_end_at !== undefined
          ? overrides.vote_end_at
          : "2099-12-31T23:59:59Z",
      }),
  };
}

// Voter participant lookup
function voterParticipantRoute(overrides?: { status?: string }): FetchRoute {
  return {
    matcher: (req) =>
      req.url.includes("event_participants") &&
      req.url.includes(TEST_VOTER_ID) &&
      !req.url.includes(TEST_CANDIDATE_ID),
    handler: () =>
      jsonResponse({
        status: overrides?.status ?? "checked_in",
        ticket_id: TEST_TICKET_VOTER,
      }),
  };
}

// Candidate participant lookup
function candidateParticipantRoute(overrides?: { status?: string }): FetchRoute {
  return {
    matcher: (req) =>
      req.url.includes("event_participants") &&
      req.url.includes(TEST_CANDIDATE_ID),
    handler: () =>
      jsonResponse({
        status: overrides?.status ?? "checked_in",
        ticket_id: TEST_TICKET_CANDIDATE,
      }),
  };
}

// Voter ticket
function voterTicketRoute(groupIds: string[] = [GROUP_MALE]): FetchRoute {
  return {
    matcher: (req) =>
      req.url.includes("/rest/v1/tickets") && req.url.includes(TEST_TICKET_VOTER),
    handler: () => jsonResponse({ target_entry_group_ids: groupIds }),
  };
}

// Candidate ticket
function candidateTicketRoute(groupIds: string[] = [GROUP_FEMALE]): FetchRoute {
  return {
    matcher: (req) =>
      req.url.includes("/rest/v1/tickets") && req.url.includes(TEST_TICKET_CANDIDATE),
    handler: () => jsonResponse({ target_entry_group_ids: groupIds }),
  };
}

// Match rules
function matchRulesRoute(rules: Array<{ vote_count: number }> = [{ vote_count: 3 }]): FetchRoute {
  return {
    matcher: (req) => req.url.includes("match_rules"),
    handler: () => jsonResponse(rules),
  };
}

// Current vote count (Supabase count: "exact", head: true → HEAD request)
function voteCountRoute(count = 0): FetchRoute {
  return {
    matcher: (req) =>
      req.url.includes("match_votes") &&
      req.url.includes("select=") &&
      (req.method === "GET" || req.method === "HEAD"),
    handler: () =>
      new Response(null, {
        status: 200,
        headers: {
          "Content-Type": "application/json",
          "content-range": `0-${Math.max(0, count - 1)}/${count}`,
        },
      }),
  };
}

// Insert vote
function insertVoteRoute(success = true): FetchRoute {
  return {
    matcher: (req) =>
      req.url.includes("match_votes") && req.method === "POST",
    handler: () =>
      success
        ? jsonResponse({ event_id: TEST_EVENT_ID })
        : jsonResponse(
            { message: "duplicate key", code: "23505" },
            { status: 409 },
          ),
  };
}

// All routes for happy path
function happyPathRoutes(): FetchRoute[] {
  return [
    authRoute(),
    eventRoute(),
    voterParticipantRoute(),
    candidateParticipantRoute(),
    voterTicketRoute(),
    candidateTicketRoute(),
    matchRulesRoute(),
    voteCountRoute(0),
    insertVoteRoute(),
  ];
}

// ─── CORS preflight ───
Deno.test({
  name: "handles OPTIONS preflight request",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          new Request("http://localhost", { method: "OPTIONS" }),
        );
        assertEquals(res.status, 200);
      });
    });
  },
});

// ─── 401: no auth ───
Deno.test({
  name: "returns 401 without authorization",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      {
        matcher: "/auth/v1/user",
        handler: () => jsonResponse({ error: "invalid" }, { status: 401 }),
      },
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const req = new Request("http://localhost", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ event_id: TEST_EVENT_ID, candidate_id: TEST_CANDIDATE_ID }),
        });
        const res = await handler(req);
        assertEquals(res.status, 401);
      });
    });
  },
});

// ─── 400: missing event_id ───
Deno.test({
  name: "returns 400 for missing event_id",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([authRoute()]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest("http://localhost", { candidate_id: TEST_CANDIDATE_ID }),
        );
        assertEquals(res.status, 400);
        const body = await readJson(res);
        assertEquals(body.error, "Missing event_id");
      });
    });
  },
});

// ─── 400: missing candidate_id ───
Deno.test({
  name: "returns 400 for missing candidate_id",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([authRoute()]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest("http://localhost", { event_id: TEST_EVENT_ID }),
        );
        assertEquals(res.status, 400);
        const body = await readJson(res);
        assertEquals(body.error, "Missing candidate_id");
      });
    });
  },
});

// ─── 400: self vote ───
Deno.test({
  name: "returns 400 for self-vote",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([authRoute()]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest("http://localhost", {
            event_id: TEST_EVENT_ID,
            candidate_id: TEST_VOTER_ID, // self
          }),
        );
        assertEquals(res.status, 400);
        const body = await readJson(res);
        assertEquals(body.error, "자기 자신에게 투표할 수 없습니다");
      });
    });
  },
});

// ─── 404: event not found ───
Deno.test({
  name: "returns 404 for non-existent event",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute(),
      {
        matcher: (req) => req.url.includes("/rest/v1/events"),
        handler: () => jsonResponse(null),
      },
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest("http://localhost", {
            event_id: "nonexistent",
            candidate_id: TEST_CANDIDATE_ID,
          }),
        );
        assertEquals(res.status, 404);
        const body = await readJson(res);
        assertEquals(body.error, "Event not found");
      });
    });
  },
});

// ─── 400: vote_start_at is null (voting not enabled) ───
Deno.test({
  name: "returns 400 when vote_start_at is null",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute(),
      eventRoute({ vote_start_at: null }),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest("http://localhost", {
            event_id: TEST_EVENT_ID,
            candidate_id: TEST_CANDIDATE_ID,
          }),
        );
        assertEquals(res.status, 400);
        const body = await readJson(res);
        assertEquals(body.error, "투표 기능이 활성화되지 않았습니다");
      });
    });
  },
});

// ─── 400: vote not yet started ───
Deno.test({
  name: "returns 400 when vote has not started yet",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute(),
      eventRoute({ vote_start_at: "2099-12-31T00:00:00Z" }),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest("http://localhost", {
            event_id: TEST_EVENT_ID,
            candidate_id: TEST_CANDIDATE_ID,
          }),
        );
        assertEquals(res.status, 400);
        const body = await readJson(res);
        assertEquals(body.error, "투표가 아직 시작되지 않았습니다");
      });
    });
  },
});

// ─── 400: vote deadline passed ───
Deno.test({
  name: "returns 400 when vote deadline has passed",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute(),
      eventRoute({
        vote_start_at: "2020-01-01T00:00:00Z",
        vote_end_at: "2020-12-31T23:59:59Z",
      }),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest("http://localhost", {
            event_id: TEST_EVENT_ID,
            candidate_id: TEST_CANDIDATE_ID,
          }),
        );
        assertEquals(res.status, 400);
        const body = await readJson(res);
        assertEquals(body.error, "투표가 마감되었습니다");
      });
    });
  },
});

// ─── 400: voter not participant ───
Deno.test({
  name: "returns 400 when voter is not a participant",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute(),
      eventRoute(),
      {
        matcher: (req) =>
          req.url.includes("event_participants") && req.url.includes(TEST_VOTER_ID),
        handler: () => jsonResponse(null),
      },
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest("http://localhost", {
            event_id: TEST_EVENT_ID,
            candidate_id: TEST_CANDIDATE_ID,
          }),
        );
        assertEquals(res.status, 400);
        const body = await readJson(res);
        assertEquals(body.error, "이벤트 참가자가 아닙니다");
      });
    });
  },
});

// ─── 400: voter not checked_in (ticket_issued) ───
Deno.test({
  name: "returns 400 when voter status is ticket_issued",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute(),
      eventRoute(),
      voterParticipantRoute({ status: "ticket_issued" }),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest("http://localhost", {
            event_id: TEST_EVENT_ID,
            candidate_id: TEST_CANDIDATE_ID,
          }),
        );
        assertEquals(res.status, 400);
        const body = await readJson(res);
        assertEquals(body.error, "체크인 후 투표 가능합니다");
      });
    });
  },
});

// ─── 400: voter is no_show ───
Deno.test({
  name: "returns 400 when voter status is no_show",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute(),
      eventRoute(),
      voterParticipantRoute({ status: "no_show" }),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest("http://localhost", {
            event_id: TEST_EVENT_ID,
            candidate_id: TEST_CANDIDATE_ID,
          }),
        );
        assertEquals(res.status, 400);
        const body = await readJson(res);
        assertEquals(body.error, "체크인 후 투표 가능합니다");
      });
    });
  },
});

// ─── 400: candidate not checked_in ───
Deno.test({
  name: "returns 400 when candidate is not checked_in",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute(),
      eventRoute(),
      voterParticipantRoute(),
      candidateParticipantRoute({ status: "ticket_issued" }),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest("http://localhost", {
            event_id: TEST_EVENT_ID,
            candidate_id: TEST_CANDIDATE_ID,
          }),
        );
        assertEquals(res.status, 400);
        const body = await readJson(res);
        assertEquals(body.error, "후보자가 체크인하지 않았습니다");
      });
    });
  },
});

// ─── 400: match_rules에 없는 그룹간 투표 ───
Deno.test({
  name: "returns 400 when groups are not in match_rules",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute(),
      eventRoute(),
      voterParticipantRoute(),
      candidateParticipantRoute(),
      voterTicketRoute(),
      candidateTicketRoute(),
      matchRulesRoute([]), // no matching rules
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest("http://localhost", {
            event_id: TEST_EVENT_ID,
            candidate_id: TEST_CANDIDATE_ID,
          }),
        );
        assertEquals(res.status, 400);
        const body = await readJson(res);
        assertEquals(body.error, "매칭 대상이 아닙니다");
      });
    });
  },
});

// ─── 400: vote count exceeded ───
Deno.test({
  name: "returns 400 when vote count is exceeded",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute(),
      eventRoute(),
      voterParticipantRoute(),
      candidateParticipantRoute(),
      voterTicketRoute(),
      candidateTicketRoute(),
      matchRulesRoute([{ vote_count: 2 }]),
      voteCountRoute(2), // already used all votes
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest("http://localhost", {
            event_id: TEST_EVENT_ID,
            candidate_id: TEST_CANDIDATE_ID,
          }),
        );
        assertEquals(res.status, 400);
        const body = await readJson(res);
        assertEquals(body.error, "투표 수를 초과했습니다");
      });
    });
  },
});

// ─── 200: happy path — successful vote ───
Deno.test({
  name: "returns 200 for successful vote",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock(happyPathRoutes());

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest("http://localhost", {
            event_id: TEST_EVENT_ID,
            candidate_id: TEST_CANDIDATE_ID,
          }),
        );
        assertEquals(res.status, 200);
        const body = await readJson(res);
        assertEquals(body.success, true);
      });
    });
  },
});

// ─── 400: duplicate vote (DB PK violation) ───
Deno.test({
  name: "returns 400 for duplicate vote",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const routes = happyPathRoutes().filter(
      (r) => typeof r.matcher !== "function" || !("" + r.matcher).includes("POST"),
    );
    // Replace insert route with duplicate error
    const routesWithDupError = [
      ...routes.slice(0, -1), // remove last (insertVoteRoute)
      {
        matcher: (req: Request) =>
          req.url.includes("match_votes") && req.method === "POST",
        handler: () =>
          jsonResponse(
            { message: "duplicate key value violates unique constraint", code: "23505" },
            { status: 409 },
          ),
      } as FetchRoute,
    ];
    const { fetchMock } = createFetchMock(routesWithDupError);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest("http://localhost", {
            event_id: TEST_EVENT_ID,
            candidate_id: TEST_CANDIDATE_ID,
          }),
        );
        assertEquals(res.status, 400);
        const body = await readJson(res);
        assertEquals(body.error, "이미 투표한 후보입니다");
      });
    });
  },
});
