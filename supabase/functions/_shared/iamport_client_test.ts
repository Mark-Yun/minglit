// _shared/iamport_client_test.ts — regression tests for e2e_pay_ mock routing (#1422)

import { assertEquals, assertRejects } from "@std/assert";
import { IamportClient } from "./iamport_client.ts";

// ─────────────────────────────────────────────────────────────────────────────
// Helpers: minimal fetch mock
// ─────────────────────────────────────────────────────────────────────────────

type MockFetchCall = { url: string; method: string; headers: Record<string, string> };

function mockFetch(
  handler: (url: string, init: RequestInit) => Response,
): { restore: () => void; calls: MockFetchCall[] } {
  const calls: MockFetchCall[] = [];
  const original = globalThis.fetch;
  globalThis.fetch = (input: RequestInfo | URL, init?: RequestInit): Promise<Response> => {
    const url = typeof input === "string" ? input : input instanceof URL ? input.href : input.url;
    calls.push({
      url,
      method: (init?.method ?? "GET").toUpperCase(),
      headers: Object.fromEntries(
        Object.entries((init?.headers as Record<string, string>) ?? {}),
      ),
    });
    return Promise.resolve(handler(url, init ?? {}));
  };
  return { restore: () => { globalThis.fetch = original; }, calls };
}

function tokenResponse(token = "mock-token"): Response {
  return new Response(
    JSON.stringify({ code: 0, response: { access_token: token } }),
    { status: 200, headers: { "Content-Type": "application/json" } },
  );
}

function paymentResponse(impUid: string, status = "paid", amount = 15000): Response {
  return new Response(
    JSON.stringify({ code: 0, response: { imp_uid: impUid, status, amount } }),
    { status: 200, headers: { "Content-Type": "application/json" } },
  );
}

function cancelResponse(impUid: string): Response {
  return new Response(
    JSON.stringify({ code: 0, response: { imp_uid: impUid, status: "cancelled", cancel_amount: 15000 } }),
    { status: 200, headers: { "Content-Type": "application/json" } },
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Tests
// ─────────────────────────────────────────────────────────────────────────────

Deno.test("IamportClient.getPayment — real imp_uid uses real PG base URL", async () => {
  Deno.env.set("PORTONE_V1_API_URL", "https://api.iamport.kr");
  Deno.env.set("SUPABASE_URL", "https://proj.supabase.co");

  const { restore, calls } = mockFetch((url) => {
    if (url.includes("/users/getToken")) return tokenResponse();
    if (url.includes("/payments/imp_123")) return paymentResponse("imp_123");
    return new Response("not found", { status: 404 });
  });

  try {
    const client = new IamportClient("key", "secret");
    await client.getPayment("imp_123");

    const tokenCall = calls.find((c) => c.url.includes("/users/getToken"));
    const paymentCall = calls.find((c) => c.url.includes("/payments/imp_123"));

    // Must use real PG URL, NOT mock-portone
    assertEquals(tokenCall?.url.startsWith("https://api.iamport.kr"), true);
    assertEquals(paymentCall?.url.startsWith("https://api.iamport.kr"), true);
    assertEquals(paymentCall?.url.includes("dev-mock-portone"), false);
  } finally {
    restore();
  }
});

Deno.test("IamportClient.getPayment — e2e_pay_ prefix routes to dev-mock-portone (#1422)", async () => {
  Deno.env.set("PORTONE_V1_API_URL", "https://api.iamport.kr");
  Deno.env.set("SUPABASE_URL", "https://proj.supabase.co");

  const { restore, calls } = mockFetch((url) => {
    if (url.includes("/users/getToken")) return tokenResponse("mock-token-for-testing");
    if (url.includes("/payments/e2e_pay_abc123")) return paymentResponse("e2e_pay_abc123");
    return new Response("not found", { status: 404 });
  });

  try {
    const client = new IamportClient("key", "secret");
    const payment = await client.getPayment("e2e_pay_abc123");

    const tokenCall = calls.find((c) => c.url.includes("/users/getToken"));
    const paymentCall = calls.find((c) => c.url.includes("/payments/e2e_pay_abc123"));

    // Must use mock-portone URL, NOT real PG
    assertEquals(tokenCall?.url.includes("dev-mock-portone"), true, "token call must hit mock-portone");
    assertEquals(paymentCall?.url.includes("dev-mock-portone"), true, "payment call must hit mock-portone");
    assertEquals(tokenCall?.url.startsWith("https://api.iamport.kr"), false);
    assertEquals((payment as { status: string }).status, "paid");
  } finally {
    restore();
  }
});

Deno.test("IamportClient.cancelPayment — real imp_uid uses real PG base URL", async () => {
  Deno.env.set("PORTONE_V1_API_URL", "https://api.iamport.kr");
  Deno.env.set("SUPABASE_URL", "https://proj.supabase.co");

  const { restore, calls } = mockFetch((url) => {
    if (url.includes("/users/getToken")) return tokenResponse();
    if (url.includes("/payments/cancel")) return cancelResponse("imp_456");
    return new Response("not found", { status: 404 });
  });

  try {
    const client = new IamportClient("key", "secret");
    await client.cancelPayment("imp_456", "test cancel");

    const cancelCall = calls.find((c) => c.url.includes("/payments/cancel"));
    assertEquals(cancelCall?.url.startsWith("https://api.iamport.kr"), true);
    assertEquals(cancelCall?.url.includes("dev-mock-portone"), false);
  } finally {
    restore();
  }
});

Deno.test("IamportClient.cancelPayment — e2e_pay_ prefix routes to dev-mock-portone (#1422)", async () => {
  Deno.env.set("PORTONE_V1_API_URL", "https://api.iamport.kr");
  Deno.env.set("SUPABASE_URL", "https://proj.supabase.co");

  const { restore, calls } = mockFetch((url) => {
    if (url.includes("/users/getToken")) return tokenResponse("mock-token-for-testing");
    if (url.includes("/payments/cancel")) return cancelResponse("e2e_pay_xyz");
    return new Response("not found", { status: 404 });
  });

  try {
    const client = new IamportClient("key", "secret");
    const result = await client.cancelPayment("e2e_pay_xyz", "simulator refund");

    const tokenCall = calls.find((c) => c.url.includes("/users/getToken"));
    const cancelCall = calls.find((c) => c.url.includes("/payments/cancel"));

    assertEquals(tokenCall?.url.includes("dev-mock-portone"), true, "token call must hit mock-portone");
    assertEquals(cancelCall?.url.includes("dev-mock-portone"), true, "cancel call must hit mock-portone");
    assertEquals((result as { status: string }).status, "cancelled");
  } finally {
    restore();
  }
});

Deno.test("IamportClient.getCertification — always uses real base URL (not mock)", async () => {
  Deno.env.set("PORTONE_V1_API_URL", "https://api.iamport.kr");
  Deno.env.set("SUPABASE_URL", "https://proj.supabase.co");

  const { restore, calls } = mockFetch((url) => {
    if (url.includes("/users/getToken")) return tokenResponse();
    if (url.includes("/certifications/cert_001")) {
      return new Response(
        JSON.stringify({ code: 0, response: { imp_uid: "cert_001", certified: true } }),
        { status: 200, headers: { "Content-Type": "application/json" } },
      );
    }
    return new Response("not found", { status: 404 });
  });

  try {
    const client = new IamportClient("key", "secret");
    await client.getCertification("cert_001");

    const certCall = calls.find((c) => c.url.includes("/certifications/cert_001"));
    assertEquals(certCall?.url.startsWith("https://api.iamport.kr"), true);
    assertEquals(certCall?.url.includes("dev-mock-portone"), false);
  } finally {
    restore();
  }
});
