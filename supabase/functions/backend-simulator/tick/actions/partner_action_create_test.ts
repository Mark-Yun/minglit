// tick/actions/partner_action_create_test.ts — PartnerActionCreateEvent unit tests (#1331)

import { assertEquals } from "@std/assert";
import type { SupabaseClient } from "@supabase/supabase-js";
import { createMockSupabaseClient } from "../../../_test_utils/mock_supabase_client.ts";
import { PartnerActionCreateEvent } from "./partner_action_create.ts";
import type { EFResponse } from "../tick_types.ts";

const TOKEN = "test-token";
const PARTNER_ID = "partner-1";
const SUPABASE_URL = "https://test.supabase.co";

function newAction() {
  return new PartnerActionCreateEvent(PARTNER_ID, TOKEN, SUPABASE_URL);
}

Deno.test({
  name: "PartnerActionCreateEvent - identity fields wired correctly",
  fn: () => {
    const action = newAction();
    assertEquals(action.type, "partner_create");
    assertEquals(action.ef, "partner-manage-party");
    assertEquals(action.actorId, PARTNER_ID);
    assertEquals(action.token, TOKEN);
    assertEquals(action.description.includes(PARTNER_ID), true);
  },
});

Deno.test({
  name: "PartnerActionCreateEvent.buildParams - top-level structure (action=create, partner_id, nested objects)",
  fn: () => {
    const params = newAction().buildParams();
    assertEquals(params.action, "create");
    assertEquals(params.partner_id, PARTNER_ID);
    const party = params.party as Record<string, unknown>;
    assertEquals(typeof party.title, "string");
    assertEquals((party.title as string).startsWith("[E2E] Tick Party "), true);
    assertEquals(party.status, "active");
    assertEquals(party.min_confirmed_count, 4);
    assertEquals(party.max_participants, 20);
    const location = params.location as Record<string, unknown>;
    assertEquals(typeof location.name, "string");
    assertEquals((location.name as string).startsWith("[E2E] "), true);
    assertEquals(Array.isArray(params.entry_group_templates), true);
    assertEquals((params.entry_group_templates as unknown[]).length, 2);
    assertEquals(Array.isArray(params.ticket_templates), true);
    assertEquals((params.ticket_templates as unknown[]).length, 1);
  },
});

Deno.test({
  // Fix #1540: image_urls must be seed URLs, not empty — guards against home/event image blank regression
  name: "PartnerActionCreateEvent.buildParams - image_urls reference seed images on the configured Supabase URL",
  fn: () => {
    const params = newAction().buildParams();
    const party = params.party as Record<string, unknown>;
    const imageUrls = party.image_urls as string[];
    assertEquals(Array.isArray(imageUrls), true);
    assertEquals(imageUrls.length > 0, true, "image_urls must not be empty (Fix #1540)");
    for (const url of imageUrls) {
      assertEquals(url.startsWith(SUPABASE_URL), true, `url must start with configured Supabase URL: ${url}`);
      assertEquals(url.includes("/storage/v1/object/public/party-assets/seed-images/"), true);
    }
  },
});

Deno.test({
  name: "PartnerActionCreateEvent.assertEFResponse - passes on 200 with party_id and captures it",
  fn: () => {
    const action = newAction();
    const result = action.assertEFResponse({ status: 200, data: { party_id: "party-new-1" } });
    assertEquals(result.passed, true);
    assertEquals(result.details.includes("party-new-1"), true);
  },
});

Deno.test({
  name: "PartnerActionCreateEvent.assertEFResponse - fails on non-200 status",
  fn: () => {
    for (const status of [400, 401, 403, 500]) {
      const result = newAction().assertEFResponse({ status, data: { party_id: "party-1" } });
      assertEquals(result.passed, false, `status=${status} must fail`);
      assertEquals(result.details.includes(String(status)), true);
    }
  },
});

Deno.test({
  name: "PartnerActionCreateEvent.assertEFResponse - fails when party_id missing on 200",
  fn: () => {
    const result = newAction().assertEFResponse({ status: 200, data: {} });
    assertEquals(result.passed, false);
    assertEquals(result.name, "partner_create_ef_party_id");
  },
});

Deno.test({
  // Stateful contract: assertDBState depends on createdPartyId captured in assertEFResponse.
  // Calling DB assert without prior EF assert must fail explicitly (don't silently return success).
  name: "PartnerActionCreateEvent.assertDBState - fails when called before assertEFResponse captures party_id",
  fn: async () => {
    const mock = createMockSupabaseClient({});
    const action = newAction(); // EF assertion not yet called
    const result = await action.assertDBState(mock as unknown as SupabaseClient);
    assertEquals(result.passed, false);
    assertEquals(result.name, "partner_create_db_no_party_id");
  },
});

function buildDBMock(opts: {
  party?: { id: string } | null;
  partyError?: { message: string } | null;
  events?: Array<{ id: string }>;
  eventsError?: { message: string } | null;
}) {
  return createMockSupabaseClient({
    tables: {
      parties: {
        select: () => ({ data: opts.party ?? null, error: opts.partyError ?? null }),
      },
      events: {
        select: () => ({ data: opts.events ?? [], error: opts.eventsError ?? null }),
      },
    },
  });
}

Deno.test({
  name: "PartnerActionCreateEvent.assertDBState - passes when party row exists (with events)",
  fn: async () => {
    const action = newAction();
    action.assertEFResponse({ status: 200, data: { party_id: "party-new-1" } });

    const mock = buildDBMock({
      party: { id: "party-new-1" },
      events: [{ id: "event-new-1" }],
    });
    const result = await action.assertDBState(mock as unknown as SupabaseClient);
    assertEquals(result.passed, true);
    assertEquals(result.details.includes("party-new-1"), true);
    assertEquals(result.details.includes("1 event"), true);
  },
});

Deno.test({
  // SUT comment notes: events row not strictly required (partner-manage-party only creates party).
  // Guards against accidental tightening that would reject the documented behavior.
  name: "PartnerActionCreateEvent.assertDBState - passes when party exists even with 0 events",
  fn: async () => {
    const action = newAction();
    action.assertEFResponse({ status: 200, data: { party_id: "party-new-2" } });

    const mock = buildDBMock({
      party: { id: "party-new-2" },
      events: [], // explicit empty
    });
    const result = await action.assertDBState(mock as unknown as SupabaseClient);
    assertEquals(result.passed, true);
    assertEquals(result.details.includes("0 event"), true);
  },
});

Deno.test({
  name: "PartnerActionCreateEvent.assertDBState - fails when party row missing",
  fn: async () => {
    const action = newAction();
    action.assertEFResponse({ status: 200, data: { party_id: "party-ghost" } });

    const mock = buildDBMock({ party: null });
    const result = await action.assertDBState(mock as unknown as SupabaseClient);
    assertEquals(result.passed, false);
    assertEquals(result.name, "partner_create_db_party");
  },
});

Deno.test({
  name: "PartnerActionCreateEvent.assertDBState - fails on parties query error",
  fn: async () => {
    const action = newAction();
    action.assertEFResponse({ status: 200, data: { party_id: "party-x" } });

    const mock = buildDBMock({ partyError: { message: "rls denied" } });
    const result = await action.assertDBState(mock as unknown as SupabaseClient);
    assertEquals(result.passed, false);
    assertEquals(result.name, "partner_create_db_party");
    assertEquals(result.details.includes("rls denied"), true);
  },
});

Deno.test({
  name: "PartnerActionCreateEvent.assertDBState - fails on events query error",
  fn: async () => {
    const action = newAction();
    action.assertEFResponse({ status: 200, data: { party_id: "party-y" } });

    const mock = buildDBMock({
      party: { id: "party-y" },
      eventsError: { message: "events query timeout" },
    });
    const result = await action.assertDBState(mock as unknown as SupabaseClient);
    assertEquals(result.passed, false);
    assertEquals(result.name, "partner_create_db_events");
    assertEquals(result.details.includes("events query timeout"), true);
  },
});
