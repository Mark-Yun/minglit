import type { SupabaseClient } from "@supabase/supabase-js";
import type { SimConfig, SimLogEntry } from "./sim_types.ts";

export interface SimCreatedData {
  partyIds: string[];
  eventIds: string[];
  applicationIds: string[];
  paidApplicationIds: string[];
  pendingReviewApplicationIds: string[];
}

const E2E_SCENARIOS = [
  { title: "[E2E] 대학생 밍글", birthYearMin: 2000, birthYearMax: 2005 },
  { title: "[E2E] 직장인 밍글", birthYearMin: 1990, birthYearMax: 2000 },
  { title: "[E2E] 소셜 파티", birthYearMin: 1995, birthYearMax: 2003 },
  { title: "[E2E] 주말 밍글", birthYearMin: 1985, birthYearMax: 2000 },
  { title: "[E2E] 네트워킹", birthYearMin: 1990, birthYearMax: 2005 },
];

const START_TIME_OFFSETS_MS = [
  30 * 24 * 60 * 60 * 1000,       // +30 days (100% refund zone)
  5 * 24 * 60 * 60 * 1000,        // +5 days (80% refund zone)
  2 * 24 * 60 * 60 * 1000,        // +2 days (50% refund zone)
  12 * 60 * 60 * 1000 + 10000,    // +12h + 10s (0% refund zone, but > 2h)
];

export async function simCreateParties(
  supabase: SupabaseClient,
  config: SimConfig,
  log: (entry: Omit<SimLogEntry, "timestamp">) => void,
): Promise<{ partyIds: string[]; eventIds: string[] }> {
  const partyIds: string[] = [];
  const eventIds: string[] = [];

  const { data: partners, error: pErr } = await supabase
    .from("partners")
    .select("id");
  if (pErr || !partners || partners.length === 0) {
    log({ level: "error", phase: "create", step: "get_partners", message: `No partners found: ${pErr?.message ?? "empty"}` });
    return { partyIds, eventIds };
  }

  for (let i = 0; i < config.party_count; i++) {
    const partner = partners[i % partners.length] as { id: string };
    const scenario = E2E_SCENARIOS[i % E2E_SCENARIOS.length];

    const { data: location } = await supabase
      .from("locations")
      .select("id")
      .eq("partner_id", partner.id)
      .maybeSingle();

    let locationId: string;
    if (location?.id) {
      locationId = location.id;
    } else {
      const newLocId = crypto.randomUUID();
      const { error: locErr } = await supabase.from("locations").insert({
        id: newLocId,
        partner_id: partner.id,
        name: "[E2E] 테스트 장소",
        address: "서울특별시 강남구 역삼동",
        region_1: "서울",
        region_2: "강남구",
      });
      if (locErr) {
        log({ level: "error", phase: "create", step: "create_location", message: `Failed: ${locErr.message}` });
        continue;
      }
      locationId = newLocId;
    }

    const partyId = crypto.randomUUID();
    const { error: partyErr } = await supabase.from("parties").insert({
      id: partyId,
      partner_id: partner.id,
      location_id: locationId,
      title: scenario.title,
      description: "[E2E] 시뮬레이션 테스트 파티입니다.",
      image_urls: [],
      required_verification_ids: [],
      min_confirmed_count: 4,
      max_participants: 20,
      status: "active",
      metadata: { show_participant_list: true, visibility: "public" },
    });
    if (partyErr) {
      log({ level: "error", phase: "create", step: "create_party", message: `Failed: ${partyErr.message}` });
      continue;
    }
    partyIds.push(partyId);

    for (let ei = 0; ei < config.events_per_party; ei++) {
      const now = new Date();
      const startTime = new Date(now.getTime() + START_TIME_OFFSETS_MS[ei % 4]);
      const endTime = new Date(startTime.getTime() + 3 * 60 * 60 * 1000);

      const eventId = crypto.randomUUID();
      const { error: evErr } = await supabase.from("events").insert({
        id: eventId,
        party_id: partyId,
        location_id: locationId,
        start_time: startTime.toISOString(),
        end_time: endTime.toISOString(),
        min_confirmed_count: 4,
        max_participants: 20,
        status: "scheduled",
        metadata: { show_participant_list: true, visibility: "public" },
      });
      if (evErr) {
        log({ level: "error", phase: "create", step: "create_event", message: `Failed: ${evErr.message}` });
        continue;
      }
      eventIds.push(eventId);

      const maleGroupId = crypto.randomUUID();
      const femaleGroupId = crypto.randomUUID();

      await supabase.from("entry_groups").insert({
        id: maleGroupId,
        event_id: eventId, label: "남성", gender: "male",
        birth_year_min: scenario.birthYearMin, birth_year_max: scenario.birthYearMax,
        required_verification_ids: [],
      });
      await supabase.from("entry_groups").insert({
        id: femaleGroupId,
        event_id: eventId, label: "여성", gender: "female",
        birth_year_min: scenario.birthYearMin, birth_year_max: scenario.birthYearMax,
        required_verification_ids: [],
      });

      await supabase.from("tickets").insert({
        id: crypto.randomUUID(),
        event_id: eventId,
        name: "[E2E] 일반 티켓",
        price: 20000,
        quantity: 10,
        target_entry_group_ids: [maleGroupId, femaleGroupId],
        status: "on_sale",
      });
    }

    log({ level: "info", phase: "create", step: "party_created", message: `Created: ${scenario.title}`, data: { partyId } });
  }

  log({ level: "info", phase: "create", step: "done", message: `Created ${partyIds.length} parties, ${eventIds.length} events` });
  return { partyIds, eventIds };
}

export async function simDiscoverAndApply(
  supabase: SupabaseClient,
  config: SimConfig,
  log: (entry: Omit<SimLogEntry, "timestamp">) => void,
  newEventIds: string[],
): Promise<{ applicationIds: string[]; paidApplicationIds: string[]; pendingReviewApplicationIds: string[] }> {
  const applicationIds: string[] = [];
  const paidApplicationIds: string[] = [];
  const pendingReviewApplicationIds: string[] = [];

  const { data: existingEventsRaw } = await supabase
    .from("events")
    .select("id, parties!inner(title)")
    .eq("status", "scheduled");

  const existingEventIds = (existingEventsRaw ?? [])
    // deno-lint-ignore no-explicit-any
    .filter((e: any) => {
      const p = e.parties;
      const title: string = Array.isArray(p) ? (p[0]?.title ?? "") : (p?.title ?? "");
      return !title.startsWith("[E2E]");
    })
    .slice(0, 20)
    // deno-lint-ignore no-explicit-any
    .map((e: any) => e.id as string);
  const allEventIds = [...newEventIds, ...existingEventIds];

  const { data: usersRaw } = await supabase
    .from("user_profiles")
    .select("id, gender, birth_date, username");
  const users = (usersRaw ?? [])
    .filter((u: { username: string }) => !u.username?.startsWith("partner_"))
    .slice(0, 60);
  if (users.length === 0) {
    log({ level: "warn", phase: "apply", step: "get_users", message: "No seed users found" });
    return { applicationIds, paidApplicationIds, pendingReviewApplicationIds };
  }

  for (const eventId of allEventIds) {
    const { data: entryGroups } = await supabase
      .from("entry_groups")
      .select("id, gender, birth_year_min, birth_year_max")
      .eq("event_id", eventId);
    if (!entryGroups || entryGroups.length === 0) continue;

    const { data: ticketsRaw } = await supabase
      .from("tickets")
      .select("id, price, status")
      .eq("event_id", eventId);
    const tickets = (ticketsRaw ?? []).filter((t: { status: string }) => t.status === "on_sale");
    if (tickets.length === 0) continue;
    const ticket = tickets[0] as { id: string; price: number };

    const { data: existingApps } = await supabase
      .from("event_applications")
      .select("user_id")
      .eq("event_id", eventId);
    const appliedUserIds = new Set((existingApps ?? []).map((a: { user_id: string }) => a.user_id));

    let appsCreated = 0;
    const shuffledUsers = [...users].sort(() => Math.random() - 0.5);

    for (const user of shuffledUsers) {
      if (appsCreated >= config.apps_per_event) break;
      if (appliedUserIds.has(user.id)) continue;

      const birthYear = user.birth_date ? new Date(user.birth_date).getFullYear() : 1995;
      const eligible = (entryGroups as { gender: string; birth_year_min: number; birth_year_max: number }[]).some(
        (g) => g.gender === user.gender && birthYear >= g.birth_year_min && birthYear <= g.birth_year_max
      );
      if (!eligible) continue;

      const isHappyPath = Math.random() >= config.error_rate;
      const status = isHappyPath ? "paid" : "pending_review";
      const appId = crypto.randomUUID();

      const { error: appErr } = await supabase.from("event_applications").insert({
        id: appId,
        event_id: eventId,
        ticket_id: ticket.id,
        user_id: user.id,
        status,
        payment_amount: isHappyPath ? ticket.price : null,
        payment_id: isHappyPath ? `e2e_pay_${crypto.randomUUID().slice(0, 8)}` : null,
        message: "[E2E] 시뮬레이션 신청",
      });
      if (appErr) {
        log({ level: "warn", phase: "apply", step: "create_application", message: `Failed: ${appErr.message}` });
        continue;
      }

      applicationIds.push(appId);
      appliedUserIds.add(user.id);
      appsCreated++;

      if (isHappyPath) {
        paidApplicationIds.push(appId);
        await supabase.from("event_participants").insert({
          id: crypto.randomUUID(),
          event_id: eventId,
          ticket_id: ticket.id,
          user_id: user.id,
          application_id: appId,
          status: "ticket_issued",
          birth_year: birthYear,
        });
      } else {
        pendingReviewApplicationIds.push(appId);
      }
    }

    if (appsCreated > 0) {
      log({ level: "info", phase: "apply", step: "event_applied", message: `Event ${eventId}: ${appsCreated} applications` });
    }
  }

  log({ level: "info", phase: "apply", step: "done",
    message: `Total: ${applicationIds.length} (${paidApplicationIds.length} paid, ${pendingReviewApplicationIds.length} pending_review)` });
  return { applicationIds, paidApplicationIds, pendingReviewApplicationIds };
}
