import assert from "node:assert/strict";
import test from "node:test";

import { getPublicEvent, getPublicEvents } from "./events";

const originalFetch = globalThis.fetch;
const originalEnv = {
  NEXT_PUBLIC_SUPABASE_URL: process.env.NEXT_PUBLIC_SUPABASE_URL,
  NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY: process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY,
};

test.afterEach(() => {
  globalThis.fetch = originalFetch;
  process.env.NEXT_PUBLIC_SUPABASE_URL = originalEnv.NEXT_PUBLIC_SUPABASE_URL;
  process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY = originalEnv.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY;
});

test("public event list requests the server-side visibility gate", async () => {
  const captured = await captureSupabaseRequest([]);

  await getPublicEvents();

  assert.equal(captured.url.pathname, "/rest/v1/events");
  assert.match(captured.url.searchParams.get("select") ?? "", /visibility/);
  assert.match(captured.url.searchParams.get("select") ?? "", /parties!inner/);
  assert.equal(
    captured.url.searchParams.get("or"),
    "(visibility.eq.public,and(visibility.is.null,parties.visibility.eq.public))",
  );
  assert.equal(captured.url.searchParams.get("start_time")?.startsWith("gte."), true);
});

test("public event detail keeps the same visibility gate with the id filter", async () => {
  const captured = await captureSupabaseRequest([]);

  await getPublicEvent("event-1");

  assert.equal(captured.url.searchParams.get("id"), "eq.event-1");
  assert.equal(captured.url.searchParams.get("limit"), "1");
  assert.equal(
    captured.url.searchParams.get("or"),
    "(visibility.eq.public,and(visibility.is.null,parties.visibility.eq.public))",
  );
});

test("public event list defensively excludes private inherited and private override rows", async () => {
  await captureSupabaseRequest([
    eventRow("public-inherited", null, "public"),
    eventRow("private-inherited", null, "private"),
    eventRow("private-override", "private", "public"),
    eventRow("public-override", "public", "private"),
  ]);

  const events = await getPublicEvents();

  assert.deepEqual(
    events.map((event) => event.id),
    ["public-inherited", "public-override"],
  );
});

async function captureSupabaseRequest(rows: unknown[]) {
  const captured: { url: URL | null } = { url: null };

  process.env.NEXT_PUBLIC_SUPABASE_URL = "https://example.supabase.co";
  process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY = "public-key";
  globalThis.fetch = async (input) => {
    captured.url = new URL(input.toString());
    return Response.json(rows);
  };

  return captured as { url: URL };
}

function eventRow(id: string, eventVisibility: string | null, partyVisibility: string) {
  return {
    id,
    title: id,
    description: "description",
    image_urls: [],
    visibility: eventVisibility,
    start_time: "2026-07-01T10:00:00+09:00",
    end_time: "2026-07-01T12:00:00+09:00",
    status: "scheduled",
    max_participants: 20,
    current_participants: 0,
    parties: {
      title: `${id} party`,
      description: "party description",
      image_urls: [],
      visibility: partyVisibility,
      partners: { name: "Partner", introduction: "Intro" },
      locations: { name: "Seoul", address: "Seoul", region_1: "Seoul", region_2: "Gangnam" },
    },
    locations: null,
    tickets: [],
  };
}
