import { assertEquals } from "@std/assert";
import {
  createFetchMock,
  withEnv,
  withMockedFetch,
} from "../_test_utils/mock_http.ts";
import { createServiceClient } from "./supabase_client.ts";

const BASE_ENV = {
  SUPABASE_URL: "https://example.supabase.co",
};

Deno.test("createServiceClient: sb_secret admin client sends apikey without default bearer", async () => {
  await withEnv(
    {
      ...BASE_ENV,
      SUPABASE_SERVICE_ROLE_KEY: undefined,
      SUPABASE_SECRET_KEYS: JSON.stringify({
        default: "sb_secret_test_key",
      }),
    },
    async () => {
      let capturedHeaders = new Headers();
      const { fetchMock } = createFetchMock([
        {
          matcher: "/rest/v1/probe",
          handler: (req) => {
            capturedHeaders = req.headers;
            return new Response("[]", {
              status: 200,
              headers: { "Content-Type": "application/json" },
            });
          },
        },
      ]);

      await withMockedFetch(fetchMock, async () => {
        await createServiceClient().from("probe").select("*");
      });

      assertEquals(capturedHeaders.get("apikey"), "sb_secret_test_key");
      assertEquals(capturedHeaders.get("Authorization"), null);
    },
  );
});

Deno.test("createServiceClient: legacy service_role JWT keeps bearer", async () => {
  await withEnv(
    {
      ...BASE_ENV,
      SUPABASE_SERVICE_ROLE_KEY: "legacy-service-role-jwt",
      SUPABASE_SECRET_KEYS: undefined,
    },
    async () => {
      let capturedHeaders = new Headers();
      const { fetchMock } = createFetchMock([
        {
          matcher: "/rest/v1/probe",
          handler: (req) => {
            capturedHeaders = req.headers;
            return new Response("[]", {
              status: 200,
              headers: { "Content-Type": "application/json" },
            });
          },
        },
      ]);

      await withMockedFetch(fetchMock, async () => {
        await createServiceClient().from("probe").select("*");
      });

      assertEquals(capturedHeaders.get("apikey"), "legacy-service-role-jwt");
      assertEquals(
        capturedHeaders.get("Authorization"),
        "Bearer legacy-service-role-jwt",
      );
    },
  );
});

Deno.test("createServiceClient: sb_secret admin client preserves user JWT auth calls", async () => {
  await withEnv(
    {
      ...BASE_ENV,
      SUPABASE_SERVICE_ROLE_KEY: undefined,
      SUPABASE_SECRET_KEYS: JSON.stringify({
        default: "sb_secret_test_key",
      }),
    },
    async () => {
      let capturedHeaders = new Headers();
      const { fetchMock } = createFetchMock([
        {
          matcher: "/auth/v1/user",
          handler: (req) => {
            capturedHeaders = req.headers;
            return new Response(JSON.stringify({ user: { id: "user-1" } }), {
              status: 200,
              headers: { "Content-Type": "application/json" },
            });
          },
        },
      ]);

      await withMockedFetch(fetchMock, async () => {
        await createServiceClient().auth.getUser("user-jwt");
      });

      assertEquals(capturedHeaders.get("apikey"), "sb_secret_test_key");
      assertEquals(capturedHeaders.get("Authorization"), "Bearer user-jwt");
    },
  );
});
