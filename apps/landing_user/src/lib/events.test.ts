import assert from "node:assert/strict";
import test from "node:test";

import {
  getPublicEvent,
  getPublicEvents,
  isEventEligibleForProfile,
  type EntryGroupEligibility,
  type PublicEvent,
  type Ticket,
} from "./events";

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

  assert.equal(captured.urls.length, 2);
  const [eventPublicUrl, inheritedPublicUrl] = captured.urls;
  assertEventSelect(eventPublicUrl);
  assertEventSelect(inheritedPublicUrl);
  assert.equal(eventPublicUrl.searchParams.get("visibility"), "eq.public");
  assert.equal(eventPublicUrl.searchParams.get("parties.visibility"), null);
  assert.equal(inheritedPublicUrl.searchParams.get("visibility"), "is.null");
  assert.equal(inheritedPublicUrl.searchParams.get("parties.visibility"), "eq.public");
  assert.equal(eventPublicUrl.searchParams.get("parties.status"), "eq.active");
  assert.equal(inheritedPublicUrl.searchParams.get("parties.status"), "eq.active");
  assert.equal(eventPublicUrl.searchParams.get("start_time")?.startsWith("gte."), true);
  assert.equal(inheritedPublicUrl.searchParams.get("start_time")?.startsWith("gte."), true);
});

test("public event detail keeps the same visibility gate with the id filter", async () => {
  const captured = await captureSupabaseRequest([]);

  await getPublicEvent("event-1");

  assert.equal(captured.urls.length, 2);
  for (const url of captured.urls) {
    assert.equal(url.searchParams.get("id"), "eq.event-1");
    assert.equal(url.searchParams.get("limit"), "1");
    assert.equal(url.searchParams.get("parties.status"), "eq.active");
  }
  assert.equal(captured.urls[0].searchParams.get("visibility"), "eq.public");
  assert.equal(captured.urls[0].searchParams.get("parties.visibility"), null);
  assert.equal(captured.urls[1].searchParams.get("visibility"), "is.null");
  assert.equal(captured.urls[1].searchParams.get("parties.visibility"), "eq.public");
});

test("public event list preserves public event overrides on private parties", async () => {
  await captureSupabaseRequest((url) => {
    if (url.searchParams.get("visibility") === "eq.public") {
      return [eventRow("public-override", "public", "private")];
    }
    return [eventRow("public-inherited", null, "public")];
  });

  const events = await getPublicEvents();

  assert.deepEqual(
    events.map((event) => event.id),
    ["public-override", "public-inherited"],
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

test("public event list defensively excludes inactive party rows", async () => {
  await captureSupabaseRequest([
    eventRow("active-party", "public", "public", "active"),
    eventRow("draft-party", "public", "public", "draft"),
    eventRow("closed-party", "public", "public", "closed"),
  ]);

  const events = await getPublicEvents();

  assert.deepEqual(
    events.map((event) => event.id),
    ["active-party"],
  );
});

test("public event list keeps a normal empty Supabase result empty", async () => {
  await captureSupabaseRequest([]);

  const events = await getPublicEvents();

  assert.deepEqual(events, []);
});

test("public event detail does not expose demo events after a normal empty Supabase result", async () => {
  await captureSupabaseRequest([]);

  const event = await getPublicEvent("demo-gangnam-social");

  assert.equal(event, null);
});

test("public event list uses demo fallback when local Supabase env is absent", async () => {
  delete process.env.NEXT_PUBLIC_SUPABASE_URL;
  delete process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY;

  const events = await getPublicEvents();

  assert.equal(events.length, 3);
  assert.equal(events[0]?.id, "demo-gangnam-social");
});

test("public event list stays empty when configured Supabase fetch fails", async () => {
  process.env.NEXT_PUBLIC_SUPABASE_URL = "https://example.supabase.co";
  process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY = "public-key";
  globalThis.fetch = async () => {
    throw new Error("network unavailable");
  };

  const events = await getPublicEvents();

  assert.deepEqual(events, []);
});

test("public event list stays empty when configured Supabase responds with an error", async () => {
  process.env.NEXT_PUBLIC_SUPABASE_URL = "https://example.supabase.co";
  process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY = "public-key";
  globalThis.fetch = async () => new Response("unauthorized", { status: 401 });

  const events = await getPublicEvents();

  assert.deepEqual(events, []);
});

test("event eligibility filter requires a known profile gender", () => {
  assert.equal(isEventEligibleForProfile(publicEvent(), { gender: null, birthDate: "1995-01-01" }), false);
});

test("event eligibility filter follows orderable ticket target groups", () => {
  const event = publicEvent({
    tickets: [
      ticket({
        id: "male-ticket",
        status: "sold_out",
        soldCount: 10,
        quantity: 10,
        targetEntryGroupIds: ["male-group"],
      }),
      ticket({
        id: "female-ticket",
        targetEntryGroupIds: ["female-group"],
      }),
    ],
    entryGroups: [
      group({ id: "male-group", gender: "male" }),
      group({ id: "female-group", gender: "female" }),
    ],
  });

  assert.equal(isEventEligibleForProfile(event, { gender: "male", birthDate: "1995-01-01" }), false);
  assert.equal(isEventEligibleForProfile(event, { gender: "female", birthDate: "1995-01-01" }), true);
});

test("event eligibility filter applies birth-year and required verification checks", () => {
  const event = publicEvent({
    tickets: [ticket({ targetEntryGroupIds: ["group-1"] })],
    entryGroups: [
      group({
        id: "group-1",
        gender: "male",
        birthYearMin: 1990,
        birthYearMax: 2000,
        requiredVerificationIds: ["student-id"],
      }),
    ],
  });

  assert.equal(isEventEligibleForProfile(event, { gender: "male", birthDate: "1988-01-01" }), false);
  assert.equal(isEventEligibleForProfile(event, { gender: "male", birthDate: "1995-01-01" }), false);
  assert.equal(
    isEventEligibleForProfile(event, {
      gender: "male",
      birthDate: "1995-01-01",
      verificationData: { "student-id": "verified" },
    }),
    true,
  );
});

type RowResolver = unknown[] | ((url: URL) => unknown[]);

async function captureSupabaseRequest(rows: RowResolver) {
  const captured: { urls: URL[]; readonly url: URL } = {
    urls: [],
    get url() {
      const url = this.urls[0];
      assert.ok(url);
      return url;
    },
  };

  process.env.NEXT_PUBLIC_SUPABASE_URL = "https://example.supabase.co";
  process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY = "public-key";
  globalThis.fetch = async (input) => {
    const url = new URL(input.toString());
    captured.urls.push(url);
    return Response.json(typeof rows === "function" ? rows(url) : rows);
  };

  return captured;
}

function assertEventSelect(url: URL) {
  assert.equal(url.pathname, "/rest/v1/events");
  assert.match(url.searchParams.get("select") ?? "", /visibility/);
  assert.match(url.searchParams.get("select") ?? "", /parties!inner/);
  assert.match(url.searchParams.get("select") ?? "", /target_entry_group_ids/);
  assert.match(url.searchParams.get("select") ?? "", /birth_year_min/);
  assert.match(url.searchParams.get("select") ?? "", /required_verification_ids/);
  assert.equal(url.searchParams.get("select")?.includes("parties!inner(title,description,image_urls,visibility,status,"), true);
}

function eventRow(id: string, eventVisibility: string | null, partyVisibility: string, partyStatus = "active") {
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
      status: partyStatus,
      partners: { name: "Partner", introduction: "Intro" },
      locations: { name: "Seoul", address: "Seoul", region_1: "Seoul", region_2: "Gangnam" },
    },
    locations: null,
    tickets: [],
  };
}

function publicEvent(overrides: Partial<PublicEvent> = {}): PublicEvent {
  return {
    id: "event-1",
    title: "이벤트",
    description: "설명",
    imageUrl: null,
    images: [],
    startsAt: "2026-07-01T10:00:00.000Z",
    endsAt: "2026-07-01T12:00:00.000Z",
    status: "scheduled",
    maxParticipants: 20,
    currentParticipants: 0,
    partnerName: "파트너",
    partnerIntro: "소개",
    locationName: "서울",
    locationAddress: "서울",
    tags: ["소셜"],
    tickets: [ticket()],
    entryGroups: [],
    ...overrides,
  };
}

function ticket(overrides: Partial<Ticket> = {}): Ticket {
  return {
    id: "ticket-1",
    name: "일반",
    description: null,
    price: 0,
    quantity: 10,
    soldCount: 0,
    status: "on_sale",
    targetEntryGroupIds: [],
    ...overrides,
  };
}

function group(overrides: Partial<EntryGroupEligibility> = {}): EntryGroupEligibility {
  return {
    id: "group-1",
    gender: null,
    birthYearMin: null,
    birthYearMax: null,
    requiredVerificationIds: [],
    ...overrides,
  };
}
