import { assertEquals } from "@std/assert";
import {
  authenticatedJsonRequest,
  captureServeHandler,
  createFetchMock,
  jsonResponse,
  readJson,
  withEnv,
  withMockedFetch,
  withNoIntervals,
} from "../_test_utils/mock_http.ts";

const BASE_ENV = {
  SUPABASE_URL: "http://localhost:54321",
  SUPABASE_SERVICE_ROLE_KEY: "test-service-key",
  ENVIRONMENT: "dev",
  MINGLIT_EF_TEST_FN_NAME: "event-checkin",
};

const BASE_URL = "http://localhost";

// ──────────────────────────────────────────────
// Fix #1491: Test helpers for Ed25519 signature generation
// ──────────────────────────────────────────────

async function generateTestKeys() {
  const keyPair = await crypto.subtle.generateKey(
    { name: "Ed25519" },
    true,
    ["sign", "verify"],
  ) as CryptoKeyPair;
  const publicKeyJwk = await crypto.subtle.exportKey("jwk", keyPair.publicKey);
  return { privateKey: keyPair.privateKey, publicKeyJwk };
}

function base64UrlEncode(bytes: Uint8Array): string {
  let binary = "";
  for (let i = 0; i < bytes.byteLength; i++) {
    binary += String.fromCharCode(bytes[i]);
  }
  return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=/g, "");
}

async function signToken(
  privateKey: CryptoKey,
  ticketId: string,
  eventId: string,
  userId: string,
  expiresAt: string,
): Promise<string> {
  const payload = `${ticketId}|${eventId}|${userId}|${expiresAt}`;
  const message = new TextEncoder().encode(payload);
  const sigBytes = await crypto.subtle.sign("Ed25519", privateKey, message);
  return base64UrlEncode(new Uint8Array(sigBytes));
}

// ──────────────────────────────────────────────
// Shared participant mock factory
// ──────────────────────────────────────────────

function participantMock(overrides = {}) {
  return {
    id: "part-1",
    event_id: "evt-1",
    user_id: "user-1",
    ticket_id: "ticket-1",
    status: "ticket_issued",
    ...overrides,
  };
}

// ──────────────────────────────────────────────
// Tests
// ──────────────────────────────────────────────

Deno.test({
  name: "event-checkin - returns 200 and checks in participant with valid QR signature",
  fn: async () => {
    const { privateKey, publicKeyJwk } = await generateTestKeys();
    const expiresAt = new Date(Date.now() + 60 * 60 * 1000).toISOString();
    const signature = await signToken(privateKey, "ticket-1", "evt-1", "user-1", expiresAt);

    const ENV = {
      ...BASE_ENV,
      TICKET_SIGNING_PUBLIC_KEY_JWK: JSON.stringify(publicKeyJwk),
    };

    const { fetchMock } = createFetchMock([
      {
        matcher: "/auth/v1/user",
        handler: () => jsonResponse({ id: "user-1", email: "test@test.com" }),
      },
      {
        matcher: (req: Request) => req.url.includes("/rest/v1/event_participants") && req.method === "GET",
        handler: () => jsonResponse(participantMock()),
      },
      {
        matcher: (req: Request) => req.url.includes("/rest/v1/events") && !req.url.includes("event_participants") && req.method === "GET",
        handler: () => jsonResponse({ id: "evt-1", status: "active" }),
      },
      {
        matcher: (req: Request) => req.url.includes("/rest/v1/event_participants") && req.method === "PATCH",
        handler: () => new Response(null, { status: 204, headers: { "content-range": "0-0/1" } }),
      },
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        await withNoIntervals(async () => {
          const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
          const response = await handler(
            authenticatedJsonRequest(BASE_URL, {
              event_id: "evt-1",
              participant_id: "part-1",
              signature,
              expires_at: expiresAt,
            }),
          );
          assertEquals(response.status, 200);
          const body = await readJson(response);
          assertEquals(body.success, true);
          assertEquals(body.status, "checked_in");
          assertEquals(body.participant_id, "part-1");
        });
      });
    });
  },
});

Deno.test({
  name: "event-checkin - returns 400 when missing event_id/participant_id",
  fn: async () => {
    const { fetchMock } = createFetchMock([
      {
        matcher: "/auth/v1/user",
        handler: () => jsonResponse({ id: "user-1", email: "test@test.com" }),
      },
    ]);

    await withEnv(BASE_ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        await withNoIntervals(async () => {
          const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
          const response = await handler(
            authenticatedJsonRequest(BASE_URL, { event_id: "evt-1" }),
          );
          assertEquals(response.status, 400);
          const body = await readJson(response);
          assertEquals(body.error, "Missing required parameters: event_id, participant_id");
        });
      });
    });
  },
});

Deno.test({
  name: "event-checkin - returns 400 when missing signature/expires_at",
  fn: async () => {
    const { fetchMock } = createFetchMock([
      {
        matcher: "/auth/v1/user",
        handler: () => jsonResponse({ id: "user-1", email: "test@test.com" }),
      },
    ]);

    await withEnv(BASE_ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        await withNoIntervals(async () => {
          const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
          const response = await handler(
            authenticatedJsonRequest(BASE_URL, {
              event_id: "evt-1",
              participant_id: "part-1",
            }),
          );
          assertEquals(response.status, 400);
          const body = await readJson(response);
          assertEquals(body.error, "Missing required parameters: signature, expires_at");
        });
      });
    });
  },
});

Deno.test({
  name: "event-checkin - returns 400 when QR token is expired",
  fn: async () => {
    const { fetchMock } = createFetchMock([
      {
        matcher: "/auth/v1/user",
        handler: () => jsonResponse({ id: "user-1", email: "test@test.com" }),
      },
    ]);

    const expiredAt = new Date(Date.now() - 1000).toISOString(); // 1초 전 만료

    await withEnv(BASE_ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        await withNoIntervals(async () => {
          const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
          const response = await handler(
            authenticatedJsonRequest(BASE_URL, {
              event_id: "evt-1",
              participant_id: "part-1",
              signature: "any-sig",
              expires_at: expiredAt,
            }),
          );
          assertEquals(response.status, 400);
          const body = await readJson(response);
          assertEquals(body.error, "QR token expired");
        });
      });
    });
  },
});

Deno.test({
  name: "event-checkin - returns 404 when participant not found",
  fn: async () => {
    const futureExpiry = new Date(Date.now() + 3600000).toISOString();

    const { fetchMock } = createFetchMock([
      {
        matcher: "/auth/v1/user",
        handler: () => jsonResponse({ id: "user-1", email: "test@test.com" }),
      },
      {
        matcher: "/rest/v1/event_participants",
        handler: () => jsonResponse(null),
      },
    ]);

    await withEnv(BASE_ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        await withNoIntervals(async () => {
          const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
          const response = await handler(
            authenticatedJsonRequest(BASE_URL, {
              event_id: "evt-1",
              participant_id: "nonexistent",
              signature: "dummy-sig",
              expires_at: futureExpiry,
            }),
          );
          assertEquals(response.status, 404);
          const body = await readJson(response);
          assertEquals(body.error, "Participant not found");
        });
      });
    });
  },
});

Deno.test({
  name: "event-checkin - returns 403 when caller is not the participant",
  fn: async () => {
    const futureExpiry = new Date(Date.now() + 3600000).toISOString();

    const { fetchMock } = createFetchMock([
      {
        matcher: "/auth/v1/user",
        handler: () => jsonResponse({ id: "other-user", email: "other@test.com" }),
      },
      {
        matcher: "/rest/v1/event_participants",
        handler: () => jsonResponse(participantMock()),
      },
    ]);

    await withEnv(BASE_ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        await withNoIntervals(async () => {
          const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
          const response = await handler(
            authenticatedJsonRequest(BASE_URL, {
              event_id: "evt-1",
              participant_id: "part-1",
              signature: "dummy-sig",
              expires_at: futureExpiry,
            }),
          );
          assertEquals(response.status, 403);
          const body = await readJson(response);
          assertEquals(body.error, "Forbidden: caller is not the participant's user");
        });
      });
    });
  },
});

Deno.test({
  name: "event-checkin - returns 403 when QR signature is invalid",
  fn: async () => {
    const { publicKeyJwk } = await generateTestKeys();
    const expiresAt = new Date(Date.now() + 3600000).toISOString();

    const ENV = {
      ...BASE_ENV,
      TICKET_SIGNING_PUBLIC_KEY_JWK: JSON.stringify(publicKeyJwk),
    };

    const { fetchMock } = createFetchMock([
      {
        matcher: "/auth/v1/user",
        handler: () => jsonResponse({ id: "user-1", email: "test@test.com" }),
      },
      {
        matcher: (req: Request) => req.url.includes("/rest/v1/event_participants") && req.method === "GET",
        handler: () => jsonResponse(participantMock()),
      },
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        await withNoIntervals(async () => {
          const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
          const response = await handler(
            authenticatedJsonRequest(BASE_URL, {
              event_id: "evt-1",
              participant_id: "part-1",
              signature: "aW52YWxpZC1zaWduYXR1cmU", // invalid base64url
              expires_at: expiresAt,
            }),
          );
          assertEquals(response.status, 403);
          const body = await readJson(response);
          assertEquals(body.error, "Invalid QR signature");
        });
      });
    });
  },
});

Deno.test({
  name: "event-checkin - returns 409 when already checked in",
  fn: async () => {
    const { privateKey, publicKeyJwk } = await generateTestKeys();
    const expiresAt = new Date(Date.now() + 3600000).toISOString();
    const signature = await signToken(privateKey, "ticket-1", "evt-1", "user-1", expiresAt);

    const ENV = {
      ...BASE_ENV,
      TICKET_SIGNING_PUBLIC_KEY_JWK: JSON.stringify(publicKeyJwk),
    };

    const { fetchMock } = createFetchMock([
      {
        matcher: "/auth/v1/user",
        handler: () => jsonResponse({ id: "user-1", email: "test@test.com" }),
      },
      {
        matcher: (req: Request) => req.url.includes("/rest/v1/event_participants") && req.method === "GET",
        handler: () => jsonResponse(participantMock({ status: "checked_in" })),
      },
      {
        matcher: (req: Request) => req.url.includes("/rest/v1/events") && !req.url.includes("event_participants") && req.method === "GET",
        handler: () => jsonResponse({ id: "evt-1", status: "active" }),
      },
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        await withNoIntervals(async () => {
          const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
          const response = await handler(
            authenticatedJsonRequest(BASE_URL, {
              event_id: "evt-1",
              participant_id: "part-1",
              signature,
              expires_at: expiresAt,
            }),
          );
          assertEquals(response.status, 409);
          const body = await readJson(response);
          assertEquals(body.error, "Participant already checked in");
        });
      });
    });
  },
});

Deno.test({
  name: "event-checkin - returns 400 when status is not ticket_issued",
  fn: async () => {
    const { privateKey, publicKeyJwk } = await generateTestKeys();
    const expiresAt = new Date(Date.now() + 3600000).toISOString();
    const signature = await signToken(privateKey, "ticket-1", "evt-1", "user-1", expiresAt);

    const ENV = {
      ...BASE_ENV,
      TICKET_SIGNING_PUBLIC_KEY_JWK: JSON.stringify(publicKeyJwk),
    };

    const { fetchMock } = createFetchMock([
      {
        matcher: "/auth/v1/user",
        handler: () => jsonResponse({ id: "user-1", email: "test@test.com" }),
      },
      {
        matcher: (req: Request) => req.url.includes("/rest/v1/event_participants") && req.method === "GET",
        handler: () => jsonResponse(participantMock({ status: "cancelled" })),
      },
      {
        matcher: (req: Request) => req.url.includes("/rest/v1/events") && !req.url.includes("event_participants") && req.method === "GET",
        handler: () => jsonResponse({ id: "evt-1", status: "active" }),
      },
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        await withNoIntervals(async () => {
          const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
          const response = await handler(
            authenticatedJsonRequest(BASE_URL, {
              event_id: "evt-1",
              participant_id: "part-1",
              signature,
              expires_at: expiresAt,
            }),
          );
          assertEquals(response.status, 400);
          const body = await readJson(response);
          assertEquals(body.error, "Cannot check in participant with status 'cancelled'");
        });
      });
    });
  },
});

Deno.test({
  name: "event-checkin - returns 401 without auth token",
  fn: async () => {
    const { fetchMock } = createFetchMock([]);

    await withEnv(BASE_ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        await withNoIntervals(async () => {
          const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
          const request = new Request(BASE_URL, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ event_id: "evt-1", participant_id: "part-1" }),
          });

          const response = await handler(request);
          assertEquals(response.status, 401);
        });
      });
    });
  },
});

Deno.test({
  name: "event-checkin - OPTIONS returns CORS response",
  fn: async () => {
    const { fetchMock } = createFetchMock([]);

    await withEnv(BASE_ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        await withNoIntervals(async () => {
          const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
          const response = await handler(new Request(BASE_URL, { method: "OPTIONS" }));
          assertEquals(response.status, 200);
          assertEquals(response.headers.get("Access-Control-Allow-Origin"), "*");
          assertEquals(response.headers.get("Access-Control-Allow-Methods"), "GET, POST, OPTIONS");
          assertEquals(response.headers.has("Access-Control-Allow-Headers"), true);
        });
      });
    });
  },
});
