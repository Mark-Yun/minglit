import { assertEquals } from "@std/assert";
import {
  captureServeHandler,
  createFetchMock,
  jsonRequest,
  jsonResponse,
  textRequest,
  withNoIntervals,
  withEnv,
  withMockedFetch,
} from "../_test_utils/mock_http.ts";

const ENV = {
  PORTONE_API_KEY: "test-key",
  PORTONE_API_SECRET: "test-secret",
  SUPABASE_URL: "https://supabase.test",
  SUPABASE_SERVICE_ROLE_KEY: "service-key",
  ENVIRONMENT: "dev",
  MINGLIT_EF_TEST_FN_NAME: "payment-webhook",
};

// Real Portone webhook IP (used to pass IP allowlist gate in auth-manifest)
const PORTONE_IP = "52.78.100.19";

Deno.test("payment-webhook - happy path updates status", async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      // Fix #1949: idempotency SELECT (not found → null) and INSERT (success)
      {
        matcher: (req) => req.url.includes("/rest/v1/webhook_imp_uid_log") && req.method === "GET",
        handler: () => new Response("null", { status: 200, headers: { "Content-Type": "application/json" } }),
      },
      {
        matcher: (req) => req.url.includes("/rest/v1/webhook_imp_uid_log") && req.method === "POST",
        handler: () => jsonResponse({}),
      },
      {
        matcher: "https://api.iamport.kr/users/getToken",
        handler: () => jsonResponse({ code: 0, response: { access_token: "token" } }),
      },
      {
        matcher: "https://api.iamport.kr/payments/imp_abc",
        handler: () => jsonResponse({ code: 0, response: { merchant_uid: "order-123", status: "paid" } }),
      },
      {
        matcher: (req) => req.url.includes("/rest/v1/event_applications") && req.method === "PATCH",
        handler: () => jsonResponse({}),
      },
    ]);

    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = jsonRequest(
          "http://localhost",
          { imp_uid: "imp_abc", merchant_uid: "order-123", status: "paid" },
          { headers: { "x-real-ip": PORTONE_IP } },
        );
        const response = await handler(request);
        assertEquals(response.status, 200);
        assertEquals(await response.text(), "OK");
      });
    });
  });
});

Deno.test("payment-webhook - unauthorized IP returns 401", async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([]);

    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = jsonRequest(
          "http://localhost",
          { imp_uid: "imp_abc", merchant_uid: "order-123", status: "paid" },
          { headers: { "x-forwarded-for": "10.0.0.1" } },
        );
        const response = await handler(request);
        // Fix #2185 (Batch 8): IP check now via wrapper manifest; returns 401 JSON (not 403 text)
        assertEquals(response.status, 401);
        const body = await response.json();
        assertEquals(body.error, "Unauthorized");
      });
    });
  });
});

// Fix #2185 (Batch 8): 127.0.0.1 is not in manifest ips — always blocked (manifest-enforced, not env-specific)
Deno.test("payment-webhook - localhost IP always blocked (not in manifest allowlist)", async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([]);

    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = jsonRequest(
          "http://localhost",
          { imp_uid: "imp_abc", merchant_uid: "order-123", status: "paid" },
          { headers: { "x-forwarded-for": "127.0.0.1" } },
        );
        const response = await handler(request);
        // IP allowlist declared in auth-manifest.json (3 Portone IPs, no 127.0.0.1)
        assertEquals(response.status, 401);
        const body = await response.json();
        assertEquals(body.error, "Unauthorized");
      });
    });
  });
});

// Fix #1892 H2: XFF leftmost 스푸핑 차단 — 가장 오른쪽 값을 신뢰
Deno.test("payment-webhook - spoofed XFF first hop blocked", async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([]);

    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        // 공격자가 whitelist IP를 XFF 앞에 넣고 자신의 IP를 뒤에 붙임
        const request = jsonRequest(
          "http://localhost",
          { imp_uid: "imp_abc", merchant_uid: "order-123", status: "paid" },
          { headers: { "x-forwarded-for": `${PORTONE_IP}, evil.example.com` } },
        );
        const response = await handler(request);
        // rightmost(evil.example.com)가 선택되므로 401 (Fix #2185: wrapper returns JSON 401)
        assertEquals(response.status, 401);
        const body = await response.json();
        assertEquals(body.error, "Unauthorized");
      });
    });
  });
});

// Fix #1892 H2: cf-connecting-ip — x-real-ip 부재 시 Cloudflare 설정 헤더로 인증
Deno.test("payment-webhook - cf-connecting-ip accepted when x-real-ip absent", async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      {
        matcher: (req) => req.url.includes("/rest/v1/webhook_imp_uid_log") && req.method === "GET",
        handler: () => new Response("null", { status: 200, headers: { "Content-Type": "application/json" } }),
      },
      {
        matcher: (req) => req.url.includes("/rest/v1/webhook_imp_uid_log") && req.method === "POST",
        handler: () => jsonResponse({}),
      },
      {
        matcher: "https://api.iamport.kr/users/getToken",
        handler: () => jsonResponse({ code: 0, response: { access_token: "token" } }),
      },
      {
        matcher: "https://api.iamport.kr/payments/imp_cfip",
        handler: () => jsonResponse({ code: 0, response: { merchant_uid: "order-cfip", status: "paid" } }),
      },
      {
        matcher: (req) => req.url.includes("/rest/v1/event_applications") && req.method === "PATCH",
        handler: () => jsonResponse({}),
      },
    ]);

    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        // x-real-ip 없이 cf-connecting-ip만 있는 경우 — Cloudflare 인프라에서 발생
        const request = jsonRequest(
          "http://localhost",
          { imp_uid: "imp_cfip", merchant_uid: "order-cfip", status: "paid" },
          { headers: { "cf-connecting-ip": PORTONE_IP } },
        );
        const response = await handler(request);
        assertEquals(response.status, 200);
      });
    });
  });
});

// Fix #1892 H2: x-real-ip가 XFF보다 우선 적용됨
Deno.test("payment-webhook - x-real-ip takes precedence over XFF", async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      {
        matcher: (req) => req.url.includes("/rest/v1/webhook_imp_uid_log") && req.method === "GET",
        handler: () => new Response("null", { status: 200, headers: { "Content-Type": "application/json" } }),
      },
      {
        matcher: (req) => req.url.includes("/rest/v1/webhook_imp_uid_log") && req.method === "POST",
        handler: () => jsonResponse({}),
      },
      {
        matcher: "https://api.iamport.kr/users/getToken",
        handler: () => jsonResponse({ code: 0, response: { access_token: "token" } }),
      },
      {
        matcher: "https://api.iamport.kr/payments/imp_realip",
        handler: () => jsonResponse({ code: 0, response: { merchant_uid: "order-realip", status: "paid" } }),
      },
      {
        matcher: (req) => req.url.includes("/rest/v1/event_applications") && req.method === "PATCH",
        handler: () => jsonResponse({}),
      },
    ]);

    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        // x-real-ip에 실제 Portone IP, XFF에 나쁜 IP — x-real-ip 우선
        const request = jsonRequest(
          "http://localhost",
          { imp_uid: "imp_realip", merchant_uid: "order-realip", status: "paid" },
          { headers: { "x-real-ip": PORTONE_IP, "x-forwarded-for": "evil.example.com" } },
        );
        const response = await handler(request);
        assertEquals(response.status, 200);
      });
    });
  });
});

Deno.test("payment-webhook - missing params returns 400", async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([]);

    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = jsonRequest(
          "http://localhost",
          { status: "paid" },
          { headers: { "x-real-ip": PORTONE_IP } },
        );
        const response = await handler(request);
        assertEquals(response.status, 400);
        assertEquals(await response.text(), "Missing parameters");
      });
    });
  });
});

Deno.test("payment-webhook - merchant UID mismatch returns 400", async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      {
        matcher: (req) => req.url.includes("/rest/v1/webhook_imp_uid_log") && req.method === "GET",
        handler: () => new Response("null", { status: 200, headers: { "Content-Type": "application/json" } }),
      },
      {
        matcher: "https://api.iamport.kr/users/getToken",
        handler: () => jsonResponse({ code: 0, response: { access_token: "token" } }),
      },
      {
        matcher: "https://api.iamport.kr/payments/imp_abc",
        handler: () => jsonResponse({ code: 0, response: { merchant_uid: "other", status: "paid" } }),
      },
    ]);

    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = jsonRequest(
          "http://localhost",
          { imp_uid: "imp_abc", merchant_uid: "order-123" },
          { headers: { "x-real-ip": PORTONE_IP } },
        );
        const response = await handler(request);
        assertEquals(response.status, 400);
        assertEquals(await response.text(), "Merchant UID mismatch");
      });
    });
  });
});

Deno.test("payment-webhook - iamport error returns 500", async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      {
        matcher: (req) => req.url.includes("/rest/v1/webhook_imp_uid_log") && req.method === "GET",
        handler: () => new Response("null", { status: 200, headers: { "Content-Type": "application/json" } }),
      },
      {
        matcher: "https://api.iamport.kr/users/getToken",
        handler: () => new Response("error", { status: 500 }),
      },
    ]);

    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = jsonRequest(
          "http://localhost",
          { imp_uid: "imp_abc", merchant_uid: "order-123" },
          { headers: { "x-real-ip": PORTONE_IP } },
        );
        const response = await handler(request);
        assertEquals(response.status, 500);
        assertEquals(typeof (await response.text()), "string");
      });
    });
  });
});

Deno.test("payment-webhook - malformed JSON returns 400", async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([]);

    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = textRequest("http://localhost", "{bad-json", {
          headers: { "x-real-ip": PORTONE_IP },
        });
        const response = await handler(request);
        assertEquals(response.status, 400);
        assertEquals(typeof (await response.text()), "string");
      });
    });
  });
});

Deno.test("payment-webhook - cancelled status sets refund_status completed", async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock, calls } = createFetchMock([
      {
        matcher: (req) => req.url.includes("/rest/v1/webhook_imp_uid_log") && req.method === "GET",
        handler: () => new Response("null", { status: 200, headers: { "Content-Type": "application/json" } }),
      },
      {
        matcher: (req) => req.url.includes("/rest/v1/webhook_imp_uid_log") && req.method === "POST",
        handler: () => jsonResponse({}),
      },
      {
        matcher: "https://api.iamport.kr/users/getToken",
        handler: () => jsonResponse({ code: 0, response: { access_token: "token" } }),
      },
      {
        matcher: "https://api.iamport.kr/payments/imp_cancel",
        handler: () => jsonResponse({ code: 0, response: { merchant_uid: "order-456", status: "cancelled" } }),
      },
      {
        matcher: (req) => req.url.includes("/rest/v1/event_applications") && req.method === "PATCH",
        handler: () => jsonResponse({}),
      },
    ]);

    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = jsonRequest(
          "http://localhost",
          { imp_uid: "imp_cancel", merchant_uid: "order-456", status: "cancelled" },
          { headers: { "x-real-ip": PORTONE_IP } },
        );
        const response = await handler(request);
        assertEquals(response.status, 200);

        const dbCall = calls.find((c) => c.url.includes("/rest/v1/event_applications") && c.method === "PATCH");
        const dbBody = JSON.parse(dbCall!.body!);
        assertEquals(dbBody.status, "cancelled");
        assertEquals(dbBody.refund_status, "completed");
      });
    });
  });
});

Deno.test("payment-webhook - paid status does not set refund_status", async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock, calls } = createFetchMock([
      {
        matcher: (req) => req.url.includes("/rest/v1/webhook_imp_uid_log") && req.method === "GET",
        handler: () => new Response("null", { status: 200, headers: { "Content-Type": "application/json" } }),
      },
      {
        matcher: (req) => req.url.includes("/rest/v1/webhook_imp_uid_log") && req.method === "POST",
        handler: () => jsonResponse({}),
      },
      {
        matcher: "https://api.iamport.kr/users/getToken",
        handler: () => jsonResponse({ code: 0, response: { access_token: "token" } }),
      },
      {
        matcher: "https://api.iamport.kr/payments/imp_paid",
        handler: () => jsonResponse({ code: 0, response: { merchant_uid: "order-789", status: "paid" } }),
      },
      {
        matcher: (req) => req.url.includes("/rest/v1/event_applications") && req.method === "PATCH",
        handler: () => jsonResponse({}),
      },
    ]);

    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = jsonRequest(
          "http://localhost",
          { imp_uid: "imp_paid", merchant_uid: "order-789", status: "paid" },
          { headers: { "x-real-ip": PORTONE_IP } },
        );
        const response = await handler(request);
        assertEquals(response.status, 200);

        const dbCall = calls.find((c) => c.url.includes("/rest/v1/event_applications") && c.method === "PATCH");
        const dbBody = JSON.parse(dbCall!.body!);
        assertEquals(dbBody.status, "approved");
        assertEquals(dbBody.refund_status, undefined);
      });
    });
  });
});

// Fix #1949: replayed webhook with same imp_uid must be rejected without side-effects
Deno.test("payment-webhook - duplicate imp_uid returns 200 without DB update or PortOne call", async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock, calls } = createFetchMock([
      {
        // Idempotency SELECT returns existing record — already processed
        matcher: (req) => req.url.includes("/rest/v1/webhook_imp_uid_log") && req.method === "GET",
        handler: () => jsonResponse({ imp_uid: "imp_dup", merchant_uid: "order-dup" }),
      },
    ]);

    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = jsonRequest(
          "http://localhost",
          { imp_uid: "imp_dup", merchant_uid: "order-dup", status: "paid" },
          { headers: { "x-real-ip": PORTONE_IP } },
        );
        const response = await handler(request);
        assertEquals(response.status, 200);
        assertEquals(await response.text(), "OK");

        // No PortOne API call should have been made
        const portoneCall = calls.find((c) => c.url.includes("api.iamport.kr"));
        assertEquals(portoneCall, undefined);

        // No DB update should have been made
        const dbPatch = calls.find((c) => c.url.includes("/rest/v1/event_applications") && c.method === "PATCH");
        assertEquals(dbPatch, undefined);
      });
    });
  });
});
