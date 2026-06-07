import assert from "node:assert/strict";
import test from "node:test";

import type { SupabaseClient, User } from "@supabase/supabase-js";

import {
  buildEventCreatePayload,
  buildEventUpdatePayload,
  buildPartyCreatePayload,
  buildRecurrencePayload,
  buildTicketTemplatePayload,
  defaultPartyFormValues,
  eventStatusLabel,
  eventToFormValues,
  normalizePartyRow,
  splitEvents,
  validateEventForm,
  validatePartyForm,
  type PartnerParty,
} from "./partner-events";
import {
  dashboardSections,
  fetchCurrentPartner,
  getPartnerDashboardSection,
  partnerInquiryHref,
  resolvePartnerDashboardGate,
  resolvePartnerLoginGate,
  type ManagedPartner,
} from "./partner-dashboard";

const testUser = { id: "user-1", email: "owner@example.com" } as User;

test("dashboard guard redirects anonymous users to login with next dashboard", async () => {
  const gate = await resolvePartnerDashboardGate(createSupabase({ sessionUser: null }));

  assert.deepEqual(gate, {
    status: "anonymous",
    loginRedirect: "/login?next=%2Fdashboard",
  });
});

test("partner lookup returns null when no partner member permission exists", async () => {
  const partner = await fetchCurrentPartner(
    createSupabase({
      sessionUser: testUser,
      permissionRows: [],
    }),
    testUser,
  );

  assert.equal(partner, null);
});

test("dashboard guard shows no-access when the signed-in user has no partner permission", async () => {
  const gate = await resolvePartnerDashboardGate(
    createSupabase({
      sessionUser: testUser,
      permissionRows: [],
    }),
  );

  assert.deepEqual(gate, {
    status: "no-access",
    email: "owner@example.com",
  });
});

test("dashboard guard returns the managed partner for authorized users", async () => {
  const gate = await resolvePartnerDashboardGate(createAuthorizedSupabase());

  assert.equal(gate.status, "ready");
  assert.deepEqual(gate, {
    status: "ready",
    partner: expectedPartner,
    email: "owner@example.com",
  });
});

test("login guard redirects authorized users to the sanitized next path", async () => {
  const gate = await resolvePartnerLoginGate(createAuthorizedSupabase(), "/dashboard/events");

  assert.deepEqual(gate, {
    status: "ready",
    redirectTo: "/dashboard/events",
  });
});

test("dashboard section links used by the shell resolve to known placeholder routes", () => {
  assert.deepEqual(
    dashboardSections.map((section) => section.href),
    ["/dashboard/events", "/dashboard/applications", "/dashboard/settlements"],
  );

  for (const section of dashboardSections) {
    assert.equal(getPartnerDashboardSection(section.key), section);
  }

  assert.equal(getPartnerDashboardSection("missing"), null);
});

test("partner inquiry link leaves the dashboard redirect route", () => {
  assert.equal(partnerInquiryHref, "mailto:contact@minglit.com");
  assert.equal(partnerInquiryHref.startsWith("/"), false);
});

test("party form validation rejects missing core fields and impossible capacity", () => {
  const errors = validatePartyForm({
    ...defaultPartyFormValues,
    title: "",
    locationName: "",
    locationAddress: "",
    maxParticipants: 0,
    minConfirmedCount: 3,
    ticketName: "",
    ticketPrice: -1,
    ticketQuantity: 0,
  });

  assert.ok(errors.includes("파티 이름을 입력해 주세요."));
  assert.ok(errors.includes("장소 이름을 입력해 주세요."));
  assert.ok(errors.includes("티켓 이름을 입력해 주세요."));
  assert.ok(errors.some((error) => error.includes("정원")));
});

test("party create payload uses partner-manage-party EF contract", () => {
  const payload = buildPartyCreatePayload(expectedPartner, {
    ...defaultPartyFormValues,
    title: "성수 와인 밍글링",
    description: "초보도 편한 와인 모임",
    locationName: "성수 라운지",
    locationAddress: "서울 성동구",
    maxParticipants: 24,
    minConfirmedCount: 6,
    ticketName: "일반",
    ticketPrice: 39000,
    ticketQuantity: 24,
  });

  assert.equal(payload.action, "create");
  assert.equal(payload.partner_id, "partner-1");
  assert.deepEqual(payload.party.description, { plain_text: "초보도 편한 와인 모임" });
  assert.deepEqual(payload.location, { name: "성수 라운지", address: "서울 성동구" });
  assert.deepEqual(payload.ticket_templates[0], { name: "일반", price: 39000, quantity: 24 });
});

test("ticket template payload updates existing template before creating a new one", () => {
  const party = createParty({ ticketTemplates: [{ id: "template-1", name: "일반", description: null, price: 1000, quantity: 10 }] });
  const payload = buildTicketTemplatePayload(party, {
    ...defaultPartyFormValues,
    title: party.title,
    locationName: "라운지",
    locationAddress: "서울",
    maxParticipants: 10,
    minConfirmedCount: 2,
    ticketName: "얼리버드",
    ticketPrice: 2000,
    ticketQuantity: 8,
  });

  assert.equal(payload.action, "update_ticket_template");
  assert.equal(payload.ticket_template_id, "template-1");
});

test("recurrence payload creates, updates, or pauses recurrence-rules EF contracts", () => {
  const party = createParty();
  const createPayload = buildRecurrencePayload(party, {
    ...defaultPartyFormValues,
    recurrencePattern: "weekly",
    recurrenceDayOfWeek: 5,
    recurrenceStartTime: "19:00",
    recurrenceEndTime: "21:00",
  });

  assert.deepEqual(createPayload, {
    action: "create",
    party_id: "party-1",
    pattern: "weekly",
    days_of_week: [5],
    month_day: null,
    start_time: "19:00",
    end_time: "21:00",
    end_date: null,
  });

  const partyWithRule = createParty({
    recurrenceRule: {
      id: "rule-1",
      pattern: "weekly",
      days_of_week: [5],
      month_day: null,
      start_time: "19:00",
      end_time: "21:00",
      end_date: null,
      status: "active",
    },
  });
  const pausePayload = buildRecurrencePayload(partyWithRule, {
    ...defaultPartyFormValues,
    recurrencePattern: "none",
  });

  assert.deepEqual(pausePayload, { action: "pause", rule_id: "rule-1" });
});

test("event form validation requires party, title, and increasing date range", () => {
  const errors = validateEventForm({
    partyId: "",
    title: "",
    startLocal: "2026-06-08T20:00",
    endLocal: "2026-06-08T19:00",
    maxParticipants: 12,
    minConfirmedCount: 3,
    reason: "",
  });

  assert.ok(errors.includes("회차를 열 파티를 선택해 주세요."));
  assert.ok(errors.includes("회차 제목을 입력해 주세요."));
  assert.ok(errors.includes("종료 일시는 시작 일시보다 늦어야 합니다."));
});

test("event create payload copies ticket template references", () => {
  const party = createParty({
    location: { id: "location-1", name: "라운지", address: "서울", address_detail: null },
    ticketTemplates: [{ id: "template-1", name: "일반", description: null, price: 1000, quantity: 10 }],
  });
  const payload = buildEventCreatePayload(party, {
    partyId: party.id,
    title: "6월 회차",
    startLocal: "2026-06-08T20:00",
    endLocal: "2026-06-08T22:00",
    maxParticipants: 10,
    minConfirmedCount: 2,
    reason: "",
  });

  assert.equal(payload.action, "create");
  assert.equal(payload.party_id, party.id);
  assert.equal(payload.event.location_id, "location-1");
  assert.deepEqual(payload.tickets, [{ template_id: "template-1", quantity: 10 }]);
});

test("event update payload carries schedule change reason only when present", () => {
  const payload = buildEventUpdatePayload("event-1", {
    partyId: "party-1",
    title: "수정 회차",
    startLocal: "2026-06-08T20:00",
    endLocal: "2026-06-08T22:00",
    maxParticipants: 10,
    minConfirmedCount: 2,
    reason: "장소 사정",
  });

  assert.equal(payload.action, "update");
  assert.equal(payload.event_id, "event-1");
  assert.equal(payload.reason, "장소 사정");
});

test("event form values preserve existing minimum confirmed count", () => {
  const values = eventToFormValues({
    id: "event-1",
    party_id: "party-1",
    title: "기존 회차",
    start_time: "2026-06-08T11:00:00.000Z",
    end_time: "2026-06-08T13:00:00.000Z",
    status: "scheduled",
    max_participants: 20,
    min_confirmed_count: 7,
    current_participants: 3,
    pending_count: 0,
    paid_count: 0,
    location: null,
  });

  assert.equal(values.minConfirmedCount, 7);
});

test("normalized event rows include minimum confirmed count for edit forms", () => {
  const party = normalizePartyRow({
    id: "party-1",
    title: "성수 와인",
    description: { plain_text: "소개" },
    status: "active",
    min_confirmed_count: 2,
    max_participants: 12,
    location_id: "location-1",
    locations: { id: "location-1", name: "라운지", address: "서울", address_detail: null },
    ticket_templates: [],
    recurrence_rules: [],
    events: [
      {
        id: "event-1",
        party_id: "party-1",
        title: "회차",
        start_time: "2026-06-10T10:00:00.000Z",
        end_time: "2026-06-10T12:00:00.000Z",
        status: "scheduled",
        max_participants: 12,
        min_confirmed_count: 5,
        current_participants: 3,
        locations: null,
      },
    ],
  });

  assert.equal(party.events[0].min_confirmed_count, 5);
});

test("normalized event rows split active and past events for hub ordering", () => {
  const party = normalizePartyRow({
    id: "party-1",
    title: "성수 와인",
    description: { plain_text: "소개" },
    status: "active",
    min_confirmed_count: 2,
    max_participants: 12,
    location_id: "location-1",
    locations: { id: "location-1", name: "라운지", address: "서울", address_detail: null },
    ticket_templates: [],
    recurrence_rules: [],
    events: [
      {
        id: "future",
        party_id: "party-1",
        title: "미래",
        start_time: "2026-06-10T10:00:00.000Z",
        end_time: "2026-06-10T12:00:00.000Z",
        status: "scheduled",
        max_participants: 12,
        min_confirmed_count: 4,
        current_participants: 3,
        locations: null,
      },
      {
        id: "past",
        party_id: "party-1",
        title: "과거",
        start_time: "2026-06-01T10:00:00.000Z",
        end_time: "2026-06-01T12:00:00.000Z",
        status: "completed",
        max_participants: 12,
        min_confirmed_count: 4,
        current_participants: 8,
        locations: null,
      },
    ],
  });

  const { active, past } = splitEvents(party.events, new Date("2026-06-08T00:00:00.000Z"));
  assert.equal(active[0].id, "future");
  assert.equal(past[0].id, "past");
  assert.equal(eventStatusLabel(active[0], new Date("2026-06-08T00:00:00.000Z")), "모집 중");
});

const expectedPartner: ManagedPartner = {
  id: "partner-1",
  name: "Minglit Lounge",
  introduction: "Partner intro",
  contact_email: "partner@example.com",
  role: "owner",
  permissions: ["event.manage", "settlement.read"],
};

function createParty(overrides: Partial<PartnerParty> = {}): PartnerParty {
  return {
    id: "party-1",
    title: "성수 와인",
    status: "active",
    min_confirmed_count: 2,
    max_participants: 12,
    descriptionText: "",
    location: null,
    ticketTemplates: [],
    recurrenceRule: null,
    events: [],
    ...overrides,
  };
}

function createAuthorizedSupabase(): SupabaseClient {
  return createSupabase({
    sessionUser: testUser,
    permissionRows: [
      {
        partner_id: "partner-1",
        role: "owner",
        permissions: ["event.manage", "settlement.read"],
      },
    ],
    partnerRow: {
      id: "partner-1",
      name: "Minglit Lounge",
      introduction: "Partner intro",
      contact_email: "partner@example.com",
      is_active: true,
    },
  });
}

type PermissionRow = {
  partner_id: string;
  role: string;
  permissions: string[] | null;
};

type PartnerRow = {
  id: string;
  name: string;
  introduction: string | null;
  contact_email: string | null;
  is_active: boolean | null;
};

type FakeSupabaseOptions = {
  sessionUser: User | null;
  permissionRows?: PermissionRow[];
  partnerRow?: PartnerRow | null;
};

function createSupabase({
  sessionUser,
  permissionRows = [],
  partnerRow = null,
}: FakeSupabaseOptions): SupabaseClient {
  return {
    auth: {
      getSession: async () => ({
        data: { session: sessionUser ? { user: sessionUser } : null },
        error: null,
      }),
    },
    from(table: string) {
      if (table === "partner_member_permissions") {
        return permissionQuery(permissionRows);
      }

      if (table === "partners") {
        return partnerQuery(partnerRow);
      }

      throw new Error(`Unexpected table: ${table}`);
    },
  } as unknown as SupabaseClient;
}

function permissionQuery(rows: PermissionRow[]) {
  return {
    select() {
      return this;
    },
    eq() {
      return this;
    },
    limit() {
      return this;
    },
    returns: async () => ({ data: rows, error: null }),
  };
}

function partnerQuery(row: PartnerRow | null) {
  return {
    select() {
      return this;
    },
    eq() {
      return this;
    },
    single: async () => ({ data: row, error: null }),
  };
}
