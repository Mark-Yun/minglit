import { assertEquals } from "@std/assert";
import {
  captureServeHandler,
  createFetchMock,
  jsonRequest,
  jsonResponse,
  readJson,
  textRequest,
  withEnv,
  withMockedFetch,
} from "../_test_utils/mock_http.ts";

Deno.test("cancel-payment - happy path cancels payment", async () => {
  const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

  const { fetchMock } = createFetchMock([
    {
      matcher: "https://api.iamport.kr/users/getToken",
      handler: () => jsonResponse({ code: 0, response: { access_token: "token" } }),
    },
    {
      matcher: "https://api.iamport.kr/payments/cancel",
      handler: () => jsonResponse({ code: 0, response: { status: "cancelled" } }),
    },
  ]);

  await withEnv(
    {
      PORTONE_API_KEY: "test-key",
      PORTONE_API_SECRET: "test-secret",
    },
    async () => {
      await withMockedFetch(fetchMock, async () => {
        const request = jsonRequest("http://localhost", {
          payment_id: "imp_123",
          reason: "user requested",
        });

        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 200);
        assertEquals(payload.success, true);
      });
    },
  );
});

Deno.test("cancel-payment - missing payment_id returns 400", async () => {
  const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

  const { fetchMock } = createFetchMock([]);

  await withEnv(
    {
      PORTONE_API_KEY: "test-key",
      PORTONE_API_SECRET: "test-secret",
    },
    async () => {
      await withMockedFetch(fetchMock, async () => {
        const request = jsonRequest("http://localhost", { reason: "missing" });
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 400);
        assertEquals(payload.error, "Missing payment_id");
      });
    },
  );
});

Deno.test("cancel-payment - token failure returns 502", async () => {
  const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

  const { fetchMock } = createFetchMock([
    {
      matcher: "https://api.iamport.kr/users/getToken",
      handler: () => jsonResponse({ code: 1, message: "bad key" }),
    },
  ]);

  await withEnv(
    {
      PORTONE_API_KEY: "test-key",
      PORTONE_API_SECRET: "test-secret",
    },
    async () => {
      await withMockedFetch(fetchMock, async () => {
        const request = jsonRequest("http://localhost", { payment_id: "imp_123" });
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 502);
        assertEquals(payload.error, "Payment provider error");
      });
    },
  );
});

Deno.test("cancel-payment - malformed JSON returns 400", async () => {
  const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

  const { fetchMock } = createFetchMock([]);

  await withEnv(
    {
      PORTONE_API_KEY: "test-key",
      PORTONE_API_SECRET: "test-secret",
    },
    async () => {
      await withMockedFetch(fetchMock, async () => {
        const request = textRequest("http://localhost", "{invalid-json");
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 400);
        assertEquals(payload.error, "Invalid JSON body");
      });
    },
  );
});
