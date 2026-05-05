import { assertEquals } from "@std/assert";
import {
  authenticatedJsonRequest,
  captureServeHandler,
  createFetchMock,
  type FetchRoute,
  jsonResponse,
  readJson,
  withEnv,
  withMockedFetch,
} from "../_test_utils/mock_http.ts";

const ENV = {
  SUPABASE_URL: "http://localhost:54321",
  SUPABASE_SERVICE_ROLE_KEY: "test-service-key",
};

const TEST_EVENT_ID = "event-001";
const TEST_VOTER_ID = "user-001";
const TEST_CANDIDATE_IDS = ["user-002", "user-003"];
const TEST_VOTER_TICKET_ID = "ticket-001";
const TEST_CANDIDATE_TICKET_IDS = ["ticket-002", "ticket-003"];

function authRoute(): FetchRoute {
  return {
    matcher: "/auth/v1/user",
    handler: () => jsonResponse({ id: TEST_VOTER_ID, email: "user@test.com" }),
  };
}

function eventRoute(overrides?: {
  status?: string;
  vote_start_at?: string | null;
  vote_end_at?: string | null;
  end_time?: string | null;
}): FetchRoute {
  return {
    matcher: (req) =>
      req.url.includes("/rest/v1/events") && req.url.includes("select="),
    handler: () =>
      jsonResponse({
        id: TEST_EVENT_ID,
        status: overrides?.status ?? "ongoing",
        vote_start_at: overrides?.vote_start_at ?? "2020-01-01T00:00:00Z",
        vote_end_at: overrides?.vote_end_at ?? "2099-12-31T23:59:59Z",
        end_time: overrides?.end_time ?? null,
      }),
  };
}

function voterParticipantRoute(): FetchRoute {
  return {
    matcher: (req) =>
      req.url.includes("event_participants") &&
      req.url.includes(TEST_VOTER_ID) &&
      !req.url.includes("in."),
    handler: () =>
      jsonResponse({ status: "checked_in", ticket_id: TEST_VOTER_TICKET_ID }),
  };
}

function candidateParticipantsRoute(): FetchRoute {
  return {
    matcher: (req) =>
      req.url.includes("event_participants") &&
      req.url.includes("in.%28user-002%2Cuser-003%29"),
    handler: () =>
      jsonResponse([
        { user_id: "user-002", status: "checked_in", ticket_id: "ticket-002" },
        { user_id: "user-003", status: "checked_in", ticket_id: "ticket-003" },
      ]),
  };
}

function voterTicketRoute(): FetchRoute {
  return {
    matcher: (req) =>
      req.url.includes("/rest/v1/tickets") &&
      req.url.includes(TEST_VOTER_TICKET_ID),
    handler: () => jsonResponse({ target_entry_group_ids: ["group-m"] }),
  };
}

function candidateTicketsRoute(): FetchRoute {
  return {
    matcher: (req) =>
      req.url.includes("/rest/v1/tickets") &&
      req.url.includes("in.%28ticket-002%2Cticket-003%29"),
    handler: () =>
      jsonResponse([
        { id: "ticket-002", target_entry_group_ids: ["group-f"] },
        { id: "ticket-003", target_entry_group_ids: ["group-f"] },
      ]),
  };
}

function rulesRoute(): FetchRoute {
  return {
    matcher: (req) => req.url.includes("/rest/v1/match_rules"),
    handler: () =>
      jsonResponse([
        { target_group_id: "group-f", vote_count: 3 },
      ]),
  };
}

function commitRpcRoute(
  result?: { inserted_count: number; duplicate_count: number },
): FetchRoute {
  return {
    matcher: (req) => req.url.includes("/rest/v1/rpc/commit_match_likes"),
    handler: () =>
      jsonResponse([
        {
          inserted_count: result?.inserted_count ?? 2,
          duplicate_count: result?.duplicate_count ?? 0,
        },
      ]),
  };
}

function happyPathRoutes(): FetchRoute[] {
  return [
    authRoute(),
    eventRoute(),
    voterParticipantRoute(),
    candidateParticipantsRoute(),
    voterTicketRoute(),
    candidateTicketsRoute(),
    rulesRoute(),
    commitRpcRoute(),
  ];
}

Deno.test({
  name: "returns 400 when candidate_ids exceed max 3",
  fn: async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );
    const { fetchMock } = createFetchMock([authRoute()]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest("http://localhost", {
            event_id: TEST_EVENT_ID,
            candidate_ids: ["u1", "u2", "u3", "u4"],
          }),
        );
        assertEquals(res.status, 400);
        const body = await readJson(res);
        assertEquals(body.error, "좋아요는 최대 3명까지 보낼 수 있습니다");
      });
    });
  },
});

Deno.test({
  name:
    "returns structured phase mismatch when event is outside matching window",
  fn: async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );
    const { fetchMock } = createFetchMock([
      authRoute(),
      eventRoute({ status: "completed" }),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest("http://localhost", {
            event_id: TEST_EVENT_ID,
            candidate_ids: TEST_CANDIDATE_IDS,
          }),
        );
        assertEquals(res.status, 409);
        const body = await readJson(res);
        assertEquals(body.error, "매칭 선택 가능 시간이 아니에요");
        assertEquals(body.details.code, "phase_mismatch");
      });
    });
  },
});

Deno.test({
  name: "returns idempotent counts when duplicate likes are submitted again",
  fn: async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );
    const { fetchMock } = createFetchMock([
      authRoute(),
      eventRoute(),
      voterParticipantRoute(),
      candidateParticipantsRoute(),
      voterTicketRoute(),
      candidateTicketsRoute(),
      rulesRoute(),
      commitRpcRoute({ inserted_count: 0, duplicate_count: 2 }),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest("http://localhost", {
            event_id: TEST_EVENT_ID,
            candidate_ids: TEST_CANDIDATE_IDS,
          }),
        );
        assertEquals(res.status, 200);
        const body = await readJson(res);
        assertEquals(body.inserted_count, 0);
        assertEquals(body.duplicate_count, 2);
      });
    });
  },
});

Deno.test({
  name: "commits likes in one batch mutation",
  fn: async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );
    const { fetchMock, calls } = createFetchMock(happyPathRoutes());

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest("http://localhost", {
            event_id: TEST_EVENT_ID,
            candidate_ids: TEST_CANDIDATE_IDS,
          }),
        );
        assertEquals(res.status, 200);
      });
    });

    assertEquals(
      calls.filter((call) =>
        call.url.includes("/rest/v1/rpc/commit_match_likes")
      ).length,
      1,
    );
  },
});
