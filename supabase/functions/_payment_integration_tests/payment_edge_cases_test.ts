// Integration tests for payment edge cases (Issue #1289)
// Test 4: Free event application bypasses PG and gets approved directly
// Test 5: Duplicate payment attempt is handled idempotently
// Test 6: Amount mismatch triggers automatic cancellation (tamper detection)
import { assertEquals } from "@std/assert";
import {
  authenticatedJsonRequest,
  captureServeHandler,
  createFetchMock,
  jsonResponse,
  readJson,
  withNoIntervals,
  withEnv,
  withMockedFetch,
} from "../_test_utils/mock_http.ts";
import { authRoute } from "../_test_utils/fixtures.ts";

// Statsig uses node:timers setInterval internally, which withNoIntervals cannot patch.

const ENV_CREATE_ORDER = {
  SUPABASE_URL: "https://supabase.test",
  SUPABASE_SERVICE_ROLE_KEY: "service-key",
};

const ENV_VERIFY = {
  PORTONE_API_KEY: "test-key",
  PORTONE_API_SECRET: "test-secret",
  SUPABASE_URL: "https://supabase.test",
  SUPABASE_SERVICE_ROLE_KEY: "service-key",
};

// --- Shared fixtures ---

const MOCK_FREE_EVENT = {
  id: "event-free",
  party_id: "party-1",
  status: "scheduled",
  start_time: new Date(Date.now() + 86400000).toISOString(),
  max_participants: 20,
  current_participants: 5,
};

const MOCK_FREE_TICKET = {
  id: "ticket-free",
  event_id: "event-free",
  name: "무료 입장권",
  price: 0,
  quantity: 20,
  sold_count: 5,
  target_entry_group_ids: [],
};

const MOCK_USER_PROFILE = {
  id: "user-123",
  is_verified: true,
  gender: "male",
  birth_date: "1995-06-15",
};

// ---
// Test 4: Free event application (payment_amount: 0) bypasses PG
//
// user-create-order sets initialStatus = "paid" when ticket.price === 0
// and requires_payment = false in the response.
// The apply_event RPC is called and status is updated to "paid" immediately.
// No payment_id from PG — the PENDING_ prefix id is used internally.
// Verification: requires_payment is false and status would be "paid" (not "pending").
// ---
Deno.test(
  "payment-integration - Test 4: free event bypasses PG, approved directly",
  async () => {
    await withEnv(ENV_CREATE_ORDER, async () => {
      const handler = await captureServeHandler(
        new URL("../user-create-order/index.ts", import.meta.url),
      );

      const { fetchMock } = createFetchMock([
        authRoute,
        {
          // events lookup
          matcher: (req) =>
            req.url.includes("/rest/v1/events") && req.method === "GET",
          handler: () => jsonResponse(MOCK_FREE_EVENT),
        },
        {
          // tickets lookup
          matcher: (req) =>
            req.url.includes("/rest/v1/tickets") && req.method === "GET",
          handler: () => jsonResponse(MOCK_FREE_TICKET),
        },
        {
          // user_profiles lookup
          matcher: (req) =>
            req.url.includes("/rest/v1/user_profiles") && req.method === "GET",
          handler: () => jsonResponse(MOCK_USER_PROFILE),
        },
        {
          // check_party_balance RPC — allowed
          matcher: (req) =>
            req.url.includes("/rest/v1/rpc/check_party_balance"),
          handler: () => jsonResponse({ allowed: true }),
        },
        {
          // existing application check — none
          matcher: (req) =>
            req.url.includes("/rest/v1/event_applications") &&
            req.method === "GET",
          handler: () => jsonResponse(null, { status: 406 }),
        },
        {
          // apply_event RPC
          matcher: (req) =>
            req.url.includes("/rest/v1/rpc/apply_event"),
          handler: () => jsonResponse("app-free-001"),
        },
        {
          // status update PATCH
          matcher: (req) =>
            req.url.includes("/rest/v1/event_applications") &&
            req.method === "PATCH",
          handler: () => jsonResponse({}),
        },
      ]);

      await withMockedFetch(fetchMock, async () => {
        await withNoIntervals(async () => {
          const request = authenticatedJsonRequest("http://localhost", {
            event_id: "event-free",
            ticket_id: "ticket-free",
          });
          const response = await handler(request);
          const payload = await readJson(response);

          assertEquals(response.status, 200);
          assertEquals(payload.success, true);
          // Free event: no PG payment required
          assertEquals(payload.requires_payment, false);
          // Amount is 0 for free event
          assertEquals(payload.amount, 0);
          // Application was created
          assertEquals(payload.application_id, "app-free-001");
        });
      });
    });
  },
);

// ---
// Test 5: Duplicate payment attempt is idempotent
//
// payment-verify checks order.status before calling Iamport.
// If status is already "approved", it returns success immediately
// without re-calling Iamport or re-updating the DB.
// ---
Deno.test(
  "payment-integration - Test 5: duplicate payment verify is idempotent",
  async () => {
    await withEnv(ENV_VERIFY, async () => {
      const handler = await captureServeHandler(
        new URL("../payment-verify/index.ts", import.meta.url),
      );

      const { fetchMock, calls } = createFetchMock([
        authRoute,
        {
          // DB lookup returns already-approved application
          matcher: (req) =>
            req.url.includes("/rest/v1/event_applications") &&
            req.method === "GET",
          handler: () =>
            jsonResponse({
              payment_amount: 15000,
              status: "approved",
              payment_id: "imp_xxx",
              user_id: "user-123",
            }),
        },
      ]);

      await withMockedFetch(fetchMock, async () => {
        await withNoIntervals(async () => {
          const request = authenticatedJsonRequest("http://localhost", {
            imp_uid: "imp_xxx",
            merchant_uid: "order-already-approved",
          });
          const response = await handler(request);
          const payload = await readJson(response);

          // Idempotent: returns success without error
          assertEquals(response.status, 200);
          assertEquals(payload.success, true);
          assertEquals(payload.message, "Already processed");

          // Iamport API must NOT be called — no double-charge risk
          const iamportCalls = calls.filter((c) =>
            c.url.includes("api.iamport.kr")
          );
          assertEquals(
            iamportCalls.length,
            0,
            "Iamport should not be called for already-approved order",
          );
        });
      });
    });
  },
);

// ---
// Test 6: Amount mismatch triggers automatic cancellation (tamper detection)
//
// DB has payment_amount: 15000 but Iamport returns amount: 20000.
// payment-verify must:
//   1. Detect the mismatch
//   2. Call Iamport cancel endpoint automatically
//   3. Return 400 "Amount mismatch" — status remains NOT "approved"
// ---
Deno.test(
  "payment-integration - Test 6: amount mismatch triggers auto-cancel",
  async () => {
    await withEnv(ENV_VERIFY, async () => {
      const handler = await captureServeHandler(
        new URL("../payment-verify/index.ts", import.meta.url),
      );

      const { fetchMock, calls } = createFetchMock([
        authRoute,
        {
          // DB: expected amount 15000, status pending
          matcher: (req) =>
            req.url.includes("/rest/v1/event_applications") &&
            req.method === "GET",
          handler: () =>
            jsonResponse({
              payment_amount: 15000,
              status: "pending",
              user_id: "user-123",
            }),
        },
        {
          // Iamport token
          matcher: "https://api.iamport.kr/users/getToken",
          handler: () =>
            jsonResponse({ code: 0, response: { access_token: "token" } }),
        },
        {
          // Iamport payment query: returns tampered amount 20000
          matcher: "https://api.iamport.kr/payments/imp_tampered",
          handler: () =>
            jsonResponse({
              code: 0,
              response: {
                status: "paid",
                amount: 20000, // tampered — DB has 15000
                merchant_uid: "order-tampered",
              },
            }),
        },
        {
          // Iamport cancel — called automatically on mismatch
          // getToken is called again inside cancelPayment
          matcher: "https://api.iamport.kr/payments/cancel",
          handler: () =>
            jsonResponse({
              code: 0,
              response: { imp_uid: "imp_tampered", status: "cancelled" },
            }),
        },
      ]);

      await withMockedFetch(fetchMock, async () => {
        await withNoIntervals(async () => {
          const request = authenticatedJsonRequest("http://localhost", {
            imp_uid: "imp_tampered",
            merchant_uid: "order-tampered",
          });
          const response = await handler(request);
          const payload = await readJson(response);

          // Mismatch detected: returns 400
          assertEquals(response.status, 400);
          assertEquals(payload.error, "Amount mismatch");

          // Amounts reported in error response details
          assertEquals(payload.details.expected, 15000);
          assertEquals(payload.details.actual, 20000);

          // Cancel was actually called
          const cancelCall = calls.find((c) =>
            c.url.includes("api.iamport.kr/payments/cancel")
          );
          assertEquals(
            cancelCall !== undefined,
            true,
            "Iamport cancel must be called on amount mismatch",
          );

          // DB PATCH (approve) must NOT have been called — status stays non-approved
          const dbPatch = calls.find(
            (c) =>
              c.url.includes("/rest/v1/event_applications") &&
              c.method === "PATCH",
          );
          assertEquals(
            dbPatch,
            undefined,
            "DB must not be updated to approved on mismatch",
          );
        });
      });
    });
  },
);
