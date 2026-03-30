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
  SUPABASE_URL: "https://supabase.test",
  SUPABASE_SERVICE_ROLE_KEY: "service-key",
};

// --- Route helpers ---

function userVerificationRoute(data: Record<string, unknown> | null) {
  return {
    matcher: (req: Request) =>
      req.url.includes("/rest/v1/user_verifications") && req.method === "GET",
    handler: () => jsonResponse(data),
  };
}

function existingSubmissionRoute(submission: Record<string, unknown> | null) {
  return {
    matcher: (req: Request) =>
      req.url.includes("/rest/v1/verification_submissions") && req.method === "GET",
    handler: () => jsonResponse(submission),
  };
}

const dbInsertSubmissionRoute = {
  matcher: (req: Request) =>
    req.url.includes("/rest/v1/verification_submissions") && req.method === "POST",
  handler: () => jsonResponse({ id: "sub-new" }),
};

const dbUpdateSubmissionRoute = {
  matcher: (req: Request) =>
    req.url.includes("/rest/v1/verification_submissions") && req.method === "PATCH",
  handler: () => jsonResponse({}),
};

// ===== submit action =====

Deno.test("submit — 첫 제출 → submission 생성, snapshot_data 배열 1개 항목", TEST_OPTS, async () => {
  const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

  const { fetchMock, calls } = createFetchMock([
    authRoute,
    userVerificationRoute({ data: { university: "서울대" } }),
    existingSubmissionRoute(null),
    dbInsertSubmissionRoute,
  ]);

  await withEnv(ENV, async () => {
    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = authenticatedJsonRequest("http://localhost", {
          action: "submit",
          partner_id: "partner-1",
          verification_id: "ver-1",
        });
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 200);
        assertEquals(payload.success, true);
        assertEquals(payload.submission_id, "sub-new");

        const insertCall = calls.find(
          (c) => c.url.includes("/rest/v1/verification_submissions") && c.method === "POST",
        );
        assertEquals(!!insertCall, true);
        const body = JSON.parse(insertCall!.body!);
        assertEquals(body.user_id, "user-123");
        assertEquals(body.partner_id, "partner-1");
        assertEquals(body.verification_id, "ver-1");
        assertEquals(body.status, "pending");
        assertEquals(Array.isArray(body.snapshot_data), true);
        assertEquals(body.snapshot_data.length, 1);
        assertEquals(body.snapshot_data[0].data.university, "서울대");
        assertEquals(body.snapshot_data[0].comments.length, 0);
      });
    });
  });
});

Deno.test("submit — 재제출 → snapshot_data 배열에 append, status = 'pending'", TEST_OPTS, async () => {
  const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

  const existingSnapshot = [
    {
      submitted_at: "2026-03-15",
      data: { university: "서울대" },
      result: "rejected",
      reviewed_by: "staff-1",
      reviewed_at: "2026-03-16",
      comments: [{ author: "staff-1", at: "2026-03-16", text: "재학증명서 흐림" }],
    },
  ];

  const { fetchMock, calls } = createFetchMock([
    authRoute,
    userVerificationRoute({ data: { university: "서울대" } }),
    existingSubmissionRoute({ id: "sub-existing", snapshot_data: existingSnapshot }),
    dbUpdateSubmissionRoute,
  ]);

  await withEnv(ENV, async () => {
    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = authenticatedJsonRequest("http://localhost", {
          action: "submit",
          partner_id: "partner-1",
          verification_id: "ver-1",
        });
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 200);
        assertEquals(payload.success, true);
        assertEquals(payload.submission_id, "sub-existing");

        const updateCall = calls.find(
          (c) => c.url.includes("/rest/v1/verification_submissions") && c.method === "PATCH",
        );
        assertEquals(!!updateCall, true);
        const body = JSON.parse(updateCall!.body!);
        assertEquals(body.status, "pending");
        assertEquals(body.snapshot_data.length, 2);
        assertEquals(body.snapshot_data[0].result, "rejected");
        assertEquals(body.snapshot_data[1].data.university, "서울대");
        assertEquals(body.snapshot_data[1].result, null);
      });
    });
  });
});

Deno.test("submit — user_verifications에 데이터 없이 제출 → 400", TEST_OPTS, async () => {
  const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

  const { fetchMock } = createFetchMock([
    authRoute,
    userVerificationRoute(null),
  ]);

  await withEnv(ENV, async () => {
    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = authenticatedJsonRequest("http://localhost", {
          action: "submit",
          partner_id: "partner-1",
          verification_id: "ver-1",
        });
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 400);
        assertEquals(payload.error, "No verification data found. Save your data first.");
      });
    });
  });
});

Deno.test("submit — partner_id 누락 → 400", TEST_OPTS, async () => {
  const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

  const { fetchMock } = createFetchMock([authRoute]);

  await withEnv(ENV, async () => {
    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = authenticatedJsonRequest("http://localhost", {
          action: "submit",
          verification_id: "ver-1",
        });
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 400);
        assertEquals(payload.error, "Missing required field: partner_id");
      });
    });
  });
});

Deno.test("submit — verification_id 누락 → 400", TEST_OPTS, async () => {
  const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

  const { fetchMock } = createFetchMock([authRoute]);

  await withEnv(ENV, async () => {
    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = authenticatedJsonRequest("http://localhost", {
          action: "submit",
          partner_id: "partner-1",
        });
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 400);
        assertEquals(payload.error, "Missing required field: verification_id");
      });
    });
  });
});

Deno.test("submit — 인증 없이 → 401", TEST_OPTS, async () => {
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
        const request = authenticatedJsonRequest("http://localhost", {
          action: "submit",
          partner_id: "partner-1",
          verification_id: "ver-1",
        });
        const response = await handler(request);

        assertEquals(response.status, 401);
      });
    });
  });
});

// ===== comment action =====

Deno.test("comment — 코멘트 추가 → 마지막 항목 comments 배열에 append", TEST_OPTS, async () => {
  const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

  const existingSubmission = {
    id: "sub-1",
    user_id: "user-123",
    snapshot_data: [
      {
        submitted_at: "2026-03-15",
        data: { university: "서울대" },
        result: "rejected",
        reviewed_by: "staff-1",
        reviewed_at: "2026-03-16",
        comments: [{ author: "staff-1", at: "2026-03-16", text: "서류 흐림" }],
      },
    ],
  };

  const submissionSelectRoute = {
    matcher: (req: Request) =>
      req.url.includes("/rest/v1/verification_submissions") && req.method === "GET",
    handler: () => jsonResponse(existingSubmission),
  };

  const { fetchMock, calls } = createFetchMock([
    authRoute,
    submissionSelectRoute,
    dbUpdateSubmissionRoute,
  ]);

  await withEnv(ENV, async () => {
    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = authenticatedJsonRequest("http://localhost", {
          action: "comment",
          submission_id: "sub-1",
          text: "다시 올리겠습니다",
        });
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 200);
        assertEquals(payload.success, true);

        const updateCall = calls.find(
          (c) => c.url.includes("/rest/v1/verification_submissions") && c.method === "PATCH",
        );
        assertEquals(!!updateCall, true);
        const body = JSON.parse(updateCall!.body!);
        const lastEntry = body.snapshot_data[0];
        assertEquals(lastEntry.comments.length, 2);
        assertEquals(lastEntry.comments[1].author, "user-123");
        assertEquals(lastEntry.comments[1].text, "다시 올리겠습니다");
      });
    });
  });
});

Deno.test("comment — 다른 유저 submission에 코멘트 → 403", TEST_OPTS, async () => {
  const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

  const otherUserSubmission = {
    id: "sub-1",
    user_id: "other-user-456",
    snapshot_data: [{ submitted_at: "2026-03-15", data: {}, comments: [] }],
  };

  const { fetchMock } = createFetchMock([
    authRoute,
    {
      matcher: (req: Request) =>
        req.url.includes("/rest/v1/verification_submissions") && req.method === "GET",
      handler: () => jsonResponse(otherUserSubmission),
    },
  ]);

  await withEnv(ENV, async () => {
    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = authenticatedJsonRequest("http://localhost", {
          action: "comment",
          submission_id: "sub-1",
          text: "테스트 코멘트",
        });
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 403);
        assertEquals(payload.error, "Forbidden: not your submission");
      });
    });
  });
});

Deno.test("comment — 존재하지 않는 submission → 404", TEST_OPTS, async () => {
  const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

  const { fetchMock } = createFetchMock([
    authRoute,
    {
      matcher: (req: Request) =>
        req.url.includes("/rest/v1/verification_submissions") && req.method === "GET",
      handler: () => jsonResponse(null),
    },
  ]);

  await withEnv(ENV, async () => {
    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = authenticatedJsonRequest("http://localhost", {
          action: "comment",
          submission_id: "non-existent",
          text: "테스트",
        });
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 404);
        assertEquals(payload.error, "Submission not found");
      });
    });
  });
});

Deno.test("comment — submission_id 누락 → 400", TEST_OPTS, async () => {
  const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

  const { fetchMock } = createFetchMock([authRoute]);

  await withEnv(ENV, async () => {
    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = authenticatedJsonRequest("http://localhost", {
          action: "comment",
          text: "테스트",
        });
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 400);
        assertEquals(payload.error, "Missing required field: submission_id");
      });
    });
  });
});

Deno.test("comment — text 누락 → 400", TEST_OPTS, async () => {
  const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

  const { fetchMock } = createFetchMock([authRoute]);

  await withEnv(ENV, async () => {
    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = authenticatedJsonRequest("http://localhost", {
          action: "comment",
          submission_id: "sub-1",
        });
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 400);
        assertEquals(payload.error, "Missing required field: text");
      });
    });
  });
});

// ===== Common edge cases =====

Deno.test("action 누락 → 400", TEST_OPTS, async () => {
  const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

  const { fetchMock } = createFetchMock([authRoute]);

  await withEnv(ENV, async () => {
    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = authenticatedJsonRequest("http://localhost", {
          partner_id: "partner-1",
        });
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 400);
        assertEquals(payload.error, "Missing required field: action");
      });
    });
  });
});

Deno.test("잘못된 action → 400", TEST_OPTS, async () => {
  const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

  const { fetchMock } = createFetchMock([authRoute]);

  await withEnv(ENV, async () => {
    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = authenticatedJsonRequest("http://localhost", {
          action: "invalid",
        });
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 400);
        assertEquals(payload.error, "Unknown action: invalid");
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
});
