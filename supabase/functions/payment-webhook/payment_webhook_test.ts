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
};

const DEV_ENV = { ...ENV, ENVIRONMENT: "dev" };

// Real Portone webhook IP (used in non-dev tests to pass IP gate)
const PORTONE_IP = "52.78.100.19";

Deno.test("payment-webhook - happy path updates status", async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
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

Deno.test("payment-webhook - unauthorized IP returns 403", async () => {
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
        assertEquals(response.status, 403);
        assertEquals(await response.text(), "Unauthorized IP");
      });
    });
  });
});

// Fix #1892 H1: 127.0.0.1은 production에서 차단되어야 함
Deno.test("payment-webhook - localhost IP blocked in production", async () => {
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
        assertEquals(response.status, 403);
        assertEquals(await response.text(), "Unauthorized IP");
      });
    });
  });
});

// Fix #1892 H1: ENVIRONMENT=dev에서는 127.0.0.1 허용
Deno.test("payment-webhook - localhost IP allowed in dev env", async () => {
  await withEnv(DEV_ENV, async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      {
        matcher: "https://api.iamport.kr/users/getToken",
        handler: () => jsonResponse({ code: 0, response: { access_token: "token" } }),
      },
      {
        matcher: "https://api.iamport.kr/payments/imp_dev",
        handler: () => jsonResponse({ code: 0, response: { merchant_uid: "order-dev", status: "paid" } }),
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
          { imp_uid: "imp_dev", merchant_uid: "order-dev", status: "paid" },
          { headers: { "x-forwarded-for": "127.0.0.1" } },
        );
        const response = await handler(request);
        assertEquals(response.status, 200);
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
        // rightmost(evil.example.com)가 선택되므로 403
        assertEquals(response.status, 403);
        assertEquals(await response.text(), "Unauthorized IP");
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
