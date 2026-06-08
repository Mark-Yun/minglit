import { assertEquals, assertRejects } from "@std/assert";
import {
  createFetchMock,
  jsonResponse,
  withEnv,
  withMockedFetch,
} from "../_test_utils/mock_http.ts";
import {
  fetchPartnerPortoneId,
  getPortoneClient,
  PortoneV2Client,
} from "./portone_client.ts";

const ENV = {
  PORTONE_V2_API_URL: "https://portone.test",
  PORTONE_V2_API_KEY: "test-key",
};

Deno.test("PortoneV2Client covers platform and payment helper requests", async () => {
  await withEnv(ENV, async () => {
    const client = new PortoneV2Client("test-key");
    const { fetchMock, calls } = createFetchMock([
      {
        matcher: "/payments/pay-1/cancel",
        handler: () => jsonResponse({ cancellationId: "cancel-1" }),
      },
      {
        matcher: "/platform/partners/partner-1",
        handler: () => jsonResponse({ id: "partner-1", name: "Partner" }),
      },
      {
        matcher: "/platform/transfers/order-cancel",
        handler: () => jsonResponse({ transfer: { id: "cancel-transfer-1" } }),
      },
      {
        matcher: "/platform/partner-settlements?",
        handler: () =>
          jsonResponse({
            settlements: [{ id: "settlement-1" }],
            page: { number: 1 },
          }),
      },
      {
        matcher: "/platform/payouts?",
        handler: () =>
          jsonResponse({ payouts: [{ id: "payout-1" }], page: { size: 10 } }),
      },
      {
        matcher: "/platform/partner-settlements/complete-payout",
        handler: () => jsonResponse({ bulkPayoutId: "bulk-1" }),
      },
      {
        matcher: "/platform/payouts/payout-1",
        handler: () => jsonResponse({ id: "payout-1", amount: 1000 }),
      },
      {
        matcher: "/platform/transfer-summaries",
        handler: () =>
          jsonResponse({
            transferSummaries: [{ id: "transfer-1" }],
            page: { number: 0 },
          }),
      },
    ]);

    await withMockedFetch(fetchMock, async () => {
      assertEquals(
        await client.cancelPayment("pay-1", "user requested"),
        { cancellationId: "cancel-1" },
      );
      assertEquals((await client.getPartner("partner-1")).id, "partner-1");
      const cancelTransfer = await client.createOrderCancelTransfer({
        partnerId: "partner-1",
        paymentId: "pay-1",
        cancellationId: "cancel-1",
      }) as { transfer?: { id?: string } };
      assertEquals(
        cancelTransfer.transfer?.id,
        "cancel-transfer-1",
      );
      assertEquals(
        (await client.getPartnerSettlements({
          partnerId: "partner-1",
          dateRange: { from: "2026-06-01", until: "2026-06-08" },
          page: { number: 1, size: 20 },
        })).settlements[0]?.id,
        "settlement-1",
      );
      assertEquals(
        (await client.getPayouts({
          partnerId: "partner-1",
          page: { number: 0, size: 10 },
        })).payouts[0]?.id,
        "payout-1",
      );
      assertEquals(
        (await client.requestPayout({
          bulkPayoutId: "bulk-1",
          partnerSettlementIds: ["settlement-1"],
        })).bulkPayoutId,
        "bulk-1",
      );
      assertEquals((await client.getPayoutDetail("payout-1")).id, "payout-1");
      assertEquals(
        (await client.getPartnerTransfers({
          partnerId: "partner-1",
          page: { number: 0, size: 10 },
        })).transferSummaries[0]?.id,
        "transfer-1",
      );
    });

    assertEquals(
      calls.some((call) =>
        call.url.includes("dateRange.from=2026-06-01") &&
        call.url.includes("page.size=20")
      ),
      true,
    );
    const transferCall = calls.find((call) =>
      call.url.includes("/platform/transfer-summaries")
    );
    assertEquals(transferCall?.method, "POST");
    assertEquals(
      transferCall?.body,
      '{"page":{"number":0,"size":10},"filter":{"partnerIds":["partner-1"]}}',
    );
  });
});

Deno.test("PortoneV2Client propagates PortOne API errors", async () => {
  await withEnv(ENV, async () => {
    const client = new PortoneV2Client("test-key");
    const { fetchMock } = createFetchMock([
      {
        matcher: "/payments/pay-1/cancel",
        handler: () =>
          jsonResponse({ message: "cannot cancel" }, { status: 409 }),
      },
    ]);

    await withMockedFetch(fetchMock, async () => {
      await assertRejects(
        () => client.cancelPayment("pay-1", "bad"),
        Error,
        "cannot cancel",
      );
    });
  });
});

Deno.test("getPortoneClient requires API key", async () => {
  await withEnv({ PORTONE_V2_API_KEY: undefined }, async () => {
    assertEquals(
      (() => {
        try {
          getPortoneClient();
          return "ok";
        } catch (error) {
          return error instanceof Error ? error.message : String(error);
        }
      })(),
      "Missing required environment variable: PORTONE_V2_API_KEY",
    );
  });
});

Deno.test("fetchPartnerPortoneId returns linked id and rejects missing links", async () => {
  const supabase = {
    from() {
      return {
        select() {
          return {
            eq(_key: string, partnerId: string) {
              return {
                single() {
                  if (partnerId === "partner-ok") {
                    return {
                      data: { portone_partner_id: "portone-partner-1" },
                      error: null,
                    };
                  }
                  if (partnerId === "partner-error") {
                    return {
                      data: null,
                      error: { message: "db down" },
                    };
                  }
                  return { data: {}, error: null };
                },
              };
            },
          };
        },
      };
    },
  };

  assertEquals(
    await fetchPartnerPortoneId(supabase, "partner-ok"),
    "portone-partner-1",
  );
  await assertRejects(
    () => fetchPartnerPortoneId(supabase, "partner-error"),
    Error,
    "Failed to fetch partner partner-error",
  );
  await assertRejects(
    () => fetchPartnerPortoneId(supabase, "partner-missing"),
    Error,
    "Partner partner-missing has no PortOne link",
  );
});
