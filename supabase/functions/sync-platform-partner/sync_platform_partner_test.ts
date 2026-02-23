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
  PORTONE_V2_API_KEY: "test-v2-key",
  SUPABASE_URL: "https://supabase.test",
  SUPABASE_SERVICE_ROLE_KEY: "service-key",
};

Deno.test("sync-platform-partner - new partner creates PortOne partner and saves ID", async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

    const { fetchMock, calls } = createFetchMock([
      {
        matcher: (req) => req.url.includes("/rest/v1/partners") && req.method === "GET",
        handler: () => jsonResponse({ id: "partner-uuid", name: "Test Partner", portone_partner_id: null }),
      },
      {
        matcher: "https://api.portone.io/platform/partners",
        handler: () => jsonResponse({ id: "partner-uuid", name: "Test Partner" }),
      },
      {
        matcher: (req) => req.url.includes("/rest/v1/partners") && req.method === "PATCH",
        handler: () => jsonResponse({}),
      },
    ]);

    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = jsonRequest("http://localhost", { partner_id: "partner-uuid" });
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 200);
        assertEquals(payload.success, true);
        assertEquals(payload.portone_partner_id, "partner-uuid");

        const dbPatch = calls.find((c) => c.url.includes("/rest/v1/partners") && c.method === "PATCH");
        const patchBody = JSON.parse(dbPatch!.body!);
        assertEquals(patchBody.portone_partner_id, "partner-uuid");
      });
    });
  });
});

Deno.test("sync-platform-partner - already synced partner is skipped", async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

    const { fetchMock, calls } = createFetchMock([
      {
        matcher: (req) => req.url.includes("/rest/v1/partners") && req.method === "GET",
        handler: () => jsonResponse({ id: "partner-uuid", name: "Test Partner", portone_partner_id: "existing-portone-id" }),
      },
    ]);

    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = jsonRequest("http://localhost", { partner_id: "partner-uuid" });
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 200);
        assertEquals(payload.success, true);
        assertEquals(payload.skipped, true);
        assertEquals(payload.portone_partner_id, "existing-portone-id");

        const portoneCall = calls.find((c) => c.url.includes("api.portone.io/platform/partners"));
        assertEquals(portoneCall, undefined);
      });
    });
  });
});

Deno.test("sync-platform-partner - partner not found returns 404", async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

    const { fetchMock } = createFetchMock([
      {
        matcher: (req) => req.url.includes("/rest/v1/partners") && req.method === "GET",
        handler: () => jsonResponse({ error: { message: "not found" } }, { status: 406 }),
      },
    ]);

    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = jsonRequest("http://localhost", { partner_id: "nonexistent" });
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 404);
        assertEquals(payload.error, "Partner not found");
      });
    });
  });
});

Deno.test("sync-platform-partner - PortOne API error returns 502", async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

    const { fetchMock } = createFetchMock([
      {
        matcher: (req) => req.url.includes("/rest/v1/partners") && req.method === "GET",
        handler: () => jsonResponse({ id: "partner-uuid", name: "Test Partner", portone_partner_id: null }),
      },
      {
        matcher: "https://api.portone.io/platform/partners",
        handler: () => jsonResponse({ message: "unauthorized" }, { status: 401 }),
      },
    ]);

    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = jsonRequest("http://localhost", { partner_id: "partner-uuid" });
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 502);
        assertEquals(payload.error, "Failed to create PortOne partner");
      });
    });
  });
});

Deno.test("sync-platform-partner - missing partner_id returns 400", async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([]);

    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = jsonRequest("http://localhost", {});
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 400);
        assertEquals(payload.error, "Missing partner_id");
      });
    });
  });
});
