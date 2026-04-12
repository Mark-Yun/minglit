import type { SupabaseClient } from "@supabase/supabase-js";
import type { SimConfig, SimLogEntry } from "./sim_types.ts";
import { callEdgeFunction, getPartnerEmail, getSimPartnerToken, getSimUserToken } from "./sim_auth.ts";

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
  supabaseUrl?: string,
  anonKey?: string,
  strict?: boolean,
): Promise<{ partyIds: string[]; eventIds: string[] }> {
  const partyIds: string[] = [];
  const eventIds: string[] = [];

  const simUserPassword = Deno.env.get("SIM_USER_PASSWORD");
  if (supabaseUrl && anonKey && !simUserPassword) {
    const errMsg = "SIM_USER_PASSWORD is required for EF path";
    if (strict) throw new Error(errMsg);
    log({ level: "warn", phase: "create", step: "sim_user_password", message: `${errMsg}, falling back to direct DB` });
  }

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

    const locationId_existing = location?.id as string | undefined;

    // ── Step 1: Acquire partner JWT (needed for EF path) ──────────────────────
    let partnerToken: string | null = null;
    if (supabaseUrl && anonKey && simUserPassword) {
      try {
        const partnerEmail = await getPartnerEmail(supabase, partner.id);
        if (partnerEmail) {
          partnerToken = await getSimPartnerToken(supabaseUrl, anonKey, partnerEmail, simUserPassword);
        } else {
          const errMsg = `No email for partner ${partner.id}, EF path skipped`;
          if (strict) throw new Error(errMsg);
          log({ level: "warn", phase: "create", step: "get_partner_email", message: errMsg });
        }
      } catch (authErr) {
        if (strict) throw authErr;
        log({ level: "warn", phase: "create", step: "get_partner_token", message: `Failed to get partner token: ${String(authErr)}` });
      }
    }

    // ── Step 2: Create party ──────────────────────────────────────────────────
    let partyId: string | null = null;
    let partyCreatedViaEf = false;
    // Tracked from the direct DB fallback path; used in the event direct DB fallback
    // to avoid a redundant per-event parties query.
    let directDbLocationId: string | null = null;

    if (supabaseUrl && anonKey && partnerToken) {
      try {
        const efResult = await callEdgeFunction(supabaseUrl, "partner-manage-party", {
          action: "create",
          partner_id: partner.id,
          party: {
            title: scenario.title,
            description: { ops: [{ insert: "[E2E] 시뮬레이션 테스트 파티입니다.\n" }] },
            image_urls: [],
            required_verification_ids: [],
            min_confirmed_count: 4,
            max_participants: 20,
            status: "active",
            metadata: { show_participant_list: true, visibility: "public" },
          },
          ...(locationId_existing
            ? { location_id: locationId_existing }
            : {
                location: {
                  name: "[E2E] 테스트 장소",
                  address: "서울특별시 강남구 역삼동",
                  region_1: "서울",
                  region_2: "강남구",
                },
              }),
          entry_group_templates: [
            { label: "남성", gender: "male", birth_year_min: scenario.birthYearMin, birth_year_max: scenario.birthYearMax },
            { label: "여성", gender: "female", birth_year_min: scenario.birthYearMin, birth_year_max: scenario.birthYearMax },
          ],
          ticket_templates: [
            { name: "일반", price: 20000, quantity: 10 },
          ],
        }, partnerToken);

        const efData = efResult.data as { success?: boolean; party_id?: string } | null;
        if (efResult.status === 200 && efData?.success && efData?.party_id) {
          partyId = efData.party_id;
          partyCreatedViaEf = true;
          log({ level: "info", phase: "create", step: "ef_create_party", message: `EF created party: ${scenario.title}`, data: { partyId } });
        } else {
          const errMsg = `EF partner-manage-party returned status=${efResult.status}`;
          if (strict) throw new Error(errMsg);
          log({ level: "warn", phase: "create", step: "ef_create_party", message: `${errMsg}, falling back to direct DB` });
        }
      } catch (efErr) {
        if (strict) throw efErr;
        log({ level: "warn", phase: "create", step: "ef_create_party", message: `EF partner-manage-party threw: ${String(efErr)}, falling back to direct DB` });
      }
    }

    // Fallback: direct DB insert (when EF not available or EF failed in non-strict mode)
    if (!partyId) {
      // Ensure location exists for direct DB path
      let locationId: string;
      if (locationId_existing) {
        locationId = locationId_existing;
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

      const directPartyId = crypto.randomUUID();
      const { error: partyErr } = await supabase.from("parties").insert({
        id: directPartyId,
        partner_id: partner.id,
        location_id: locationId,
        title: scenario.title,
        description: { ops: [{ insert: "[E2E] 시뮬레이션 테스트 파티입니다.\n" }] },
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
      partyId = directPartyId;
      directDbLocationId = locationId;

      // For direct DB path: create entry groups and ticket templates on the party level
      // (events will also get entry_groups + tickets created inline below)
    }

    // At this point partyId is always set: EF success sets it, fallback continues on error
    partyIds.push(partyId!);

    // ── Step 3: Create events ─────────────────────────────────────────────────

    // Fetch ticket_templates created by the EF (needed for event EF payload).
    // Only relevant when the party was created via EF — direct DB parties have no ticket_templates.
    let ticketTemplates: { id: string; name: string }[] = [];
    if (partyCreatedViaEf && supabaseUrl && anonKey && partnerToken) {
      const { data: templates } = await supabase
        .from("ticket_templates")
        .select("id, name")
        .eq("party_id", partyId!);
      ticketTemplates = (templates ?? []) as { id: string; name: string }[];
    }

    for (let ei = 0; ei < config.events_per_party; ei++) {
      const now = new Date();
      const startTime = new Date(now.getTime() + START_TIME_OFFSETS_MS[ei % 4]);
      const endTime = new Date(startTime.getTime() + 3 * 60 * 60 * 1000);

      let eventId: string | null = null;

      // Only attempt the event EF when the party was created via EF (which guarantees
      // ticket_templates exist). A direct-DB party has no ticket_templates, so the
      // event EF would produce a ticket-less event — skip it and use direct DB instead.
      if (partyCreatedViaEf && supabaseUrl && anonKey && partnerToken) {
        try {
          const efResult = await callEdgeFunction(supabaseUrl, "partner-manage-event", {
            action: "create",
            party_id: partyId,
            event: {
              start_time: startTime.toISOString(),
              end_time: endTime.toISOString(),
              max_participants: 20,
              title: `${scenario.title} #${ei + 1}`,
            },
            tickets: ticketTemplates.map((t) => ({
              template_id: t.id,
              quantity: 10,
            })),
          }, partnerToken);

          const efData = efResult.data as { success?: boolean; event_id?: string } | null;
          if (efResult.status === 200 && efData?.success && efData?.event_id) {
            eventId = efData.event_id;
            log({ level: "info", phase: "create", step: "ef_create_event", message: `EF created event ${ei + 1} for party ${partyId}`, data: { eventId } });
          } else {
            const errMsg = `EF partner-manage-event returned status=${efResult.status}`;
            if (strict) throw new Error(errMsg);
            log({ level: "warn", phase: "create", step: "ef_create_event", message: `${errMsg}, falling back to direct DB` });
          }
        } catch (efErr) {
          if (strict) throw efErr;
          log({ level: "warn", phase: "create", step: "ef_create_event", message: `EF partner-manage-event threw: ${String(efErr)}, falling back to direct DB` });
        }
      }

      // Fallback: direct DB insert for event + entry_groups + tickets.
      // locationId is known from the party creation step — no per-event DB query needed.
      if (!eventId) {
        let resolvedLocationId: string | null = directDbLocationId ?? locationId_existing ?? null;
        if (partyCreatedViaEf && !resolvedLocationId) {
          const { data: partyRow, error: partyLookupErr } = await supabase
            .from("parties")
            .select("location_id")
            .eq("id", partyId!)
            .maybeSingle();

          if (partyLookupErr || !partyRow?.location_id) {
            log({
              level: "error",
              phase: "create",
              step: "resolve_location_id",
              message: `Failed to resolve location_id for party ${partyId}: ${partyLookupErr?.message ?? "empty"}`,
            });
            continue;
          }
          resolvedLocationId = partyRow.location_id as string;
        }
        if (!resolvedLocationId) {
          log({ level: "error", phase: "create", step: "resolve_location_id", message: `No location_id for party ${partyId}` });
          continue;
        }

        const directEventId = crypto.randomUUID();
        const { error: evErr } = await supabase.from("events").insert({
          id: directEventId,
          party_id: partyId,
          location_id: resolvedLocationId,
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
        eventId = directEventId;

        const maleGroupId = crypto.randomUUID();
        const femaleGroupId = crypto.randomUUID();

        const { error: maleGroupErr } = await supabase.from("entry_groups").insert({
          id: maleGroupId,
          event_id: eventId, label: "남성", gender: "male",
          birth_year_min: scenario.birthYearMin, birth_year_max: scenario.birthYearMax,
          required_verification_ids: [],
        });
        if (maleGroupErr) {
          log({ level: "warn", phase: "create", step: "create_entry_group", message: `Failed to create male entry_group: ${maleGroupErr.message}` });
        }

        const { error: femaleGroupErr } = await supabase.from("entry_groups").insert({
          id: femaleGroupId,
          event_id: eventId, label: "여성", gender: "female",
          birth_year_min: scenario.birthYearMin, birth_year_max: scenario.birthYearMax,
          required_verification_ids: [],
        });
        if (femaleGroupErr) {
          log({ level: "warn", phase: "create", step: "create_entry_group", message: `Failed to create female entry_group: ${femaleGroupErr.message}` });
        }

        const { error: ticketErr } = await supabase.from("tickets").insert({
          id: crypto.randomUUID(),
          event_id: eventId,
          name: "[E2E] 일반 티켓",
          price: 20000,
          quantity: 10,
          target_entry_group_ids: [maleGroupId, femaleGroupId],
          status: "on_sale",
        });
        if (ticketErr) {
          log({ level: "warn", phase: "create", step: "create_ticket", message: `Failed to create ticket: ${ticketErr.message}` });
        }
      }

      // At this point eventId is always set: EF success sets it, fallback continues on error
      eventIds.push(eventId!);
    }

    log({ level: "info", phase: "create", step: "party_created", message: `Created: ${scenario.title}`, data: { partyId } });
  }

  log({ level: "info", phase: "create", step: "done", message: `Created ${partyIds.length} parties, ${eventIds.length} events` });
  return { partyIds, eventIds };
}

// Fix #964: 피드 전시용 이벤트 — E2E 테스트와 분리된 일반 유저 피드용 이벤트 데이터 제공
const DISPLAY_SCENARIOS = [
  { title: "강남 직장인 애프터워크 밍글", description: "강남에서 만나는 직장인들의 애프터워크 소셜 파티입니다.", offsetDays: 3 },
  { title: "홍대 대학생 주말 밍글", description: "홍대 앞에서 펼쳐지는 대학생 주말 소셜 밍글입니다.", offsetDays: 7 },
  { title: "성수 네트워킹 파티", description: "성수동 힙스터들의 소셜 네트워킹 파티입니다.", offsetDays: 14 },
  { title: "이태원 소셜 밍글", description: "이태원에서 새로운 사람들과 만나는 소셜 밍글입니다.", offsetDays: 21 },
  { title: "압구정 프라이데이 밍글", description: "압구정에서 즐기는 금요일 저녁 소셜 파티입니다.", offsetDays: 30 },
];

export async function simCreateDisplayEvents(
  supabase: SupabaseClient,
  log: (entry: Omit<SimLogEntry, "timestamp">) => void,
): Promise<{ displayPartyIds: string[]; displayEventIds: string[] }> {
  const displayPartyIds: string[] = [];
  const displayEventIds: string[] = [];

  // Fix #964: Dedup — skip creation if display parties already exist to prevent infinite accumulation
  const { data: existing } = await supabase
    .from("parties")
    .select("id")
    .in("title", DISPLAY_SCENARIOS.map((s) => s.title))
    .eq("status", "active");

  if (existing && existing.length >= DISPLAY_SCENARIOS.length) {
    log({ level: "info", phase: "create", step: "display_skip", message: "Display parties already exist, skipping" });
    return { displayPartyIds, displayEventIds };
  }

  const { data: partners, error: pErr } = await supabase
    .from("partners")
    .select("id");
  if (pErr || !partners || partners.length === 0) {
    log({ level: "error", phase: "create", step: "display_get_partners", message: `No partners found: ${pErr?.message ?? "empty"}` });
    return { displayPartyIds, displayEventIds };
  }

  for (let i = 0; i < DISPLAY_SCENARIOS.length; i++) {
    const partner = partners[i % partners.length] as { id: string };
    const scenario = DISPLAY_SCENARIOS[i];

    // Fix #964: [E2E] location 재사용 방지 — display 이벤트가 E2E 테스트용 location에 붙지 않도록 필터링
    const { data: location } = await supabase
      .from("locations")
      .select("id")
      .eq("partner_id", partner.id)
      .not("name", "ilike", "[E2E]%")
      .maybeSingle();

    let locationId: string;
    if (location?.id) {
      locationId = location.id;
    } else {
      const newLocId = crypto.randomUUID();
      const { error: locErr } = await supabase.from("locations").insert({
        id: newLocId,
        partner_id: partner.id,
        name: "전시용 테스트 장소",
        address: "서울특별시 강남구 역삼동",
        region_1: "서울",
        region_2: "강남구",
      });
      if (locErr) {
        log({ level: "error", phase: "create", step: "display_create_location", message: `Failed: ${locErr.message}` });
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
      description: { ops: [{ insert: `${scenario.description}\n` }] },
      image_urls: [],
      required_verification_ids: [],
      min_confirmed_count: 4,
      max_participants: 20,
      status: "active",
      metadata: { show_participant_list: true, visibility: "public" },
    });
    if (partyErr) {
      log({ level: "error", phase: "create", step: "display_create_party", message: `Failed: ${partyErr.message}` });
      continue;
    }
    displayPartyIds.push(partyId);

    // 파티당 이벤트 2개 (같은 시나리오, 시작 시간만 +3시간 차이)
    for (let ei = 0; ei < 2; ei++) {
      const now = new Date();
      const startTime = new Date(now.getTime() + scenario.offsetDays * 24 * 60 * 60 * 1000 + ei * 3 * 60 * 60 * 1000);
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
        log({ level: "error", phase: "create", step: "display_create_event", message: `Failed: ${evErr.message}` });
        continue;
      }
      displayEventIds.push(eventId);

      const maleGroupId = crypto.randomUUID();
      const femaleGroupId = crypto.randomUUID();

      const { error: maleGroupErr } = await supabase.from("entry_groups").insert({
        id: maleGroupId,
        event_id: eventId, label: "남성", gender: "male",
        birth_year_min: 1990, birth_year_max: 2005,
        required_verification_ids: [],
      });
      if (maleGroupErr) {
        log({ level: "warn", phase: "create", step: "display_create_entry_group", message: `Failed to create male entry_group: ${maleGroupErr.message}` });
      }

      const { error: femaleGroupErr } = await supabase.from("entry_groups").insert({
        id: femaleGroupId,
        event_id: eventId, label: "여성", gender: "female",
        birth_year_min: 1990, birth_year_max: 2005,
        required_verification_ids: [],
      });
      if (femaleGroupErr) {
        log({ level: "warn", phase: "create", step: "display_create_entry_group", message: `Failed to create female entry_group: ${femaleGroupErr.message}` });
      }

      const { error: ticketErr } = await supabase.from("tickets").insert({
        id: crypto.randomUUID(),
        event_id: eventId,
        name: "일반 티켓",
        price: 20000,
        quantity: 10,
        target_entry_group_ids: [maleGroupId, femaleGroupId],
        status: "on_sale",
      });
      if (ticketErr) {
        log({ level: "warn", phase: "create", step: "display_create_ticket", message: `Failed to create ticket: ${ticketErr.message}` });
      }
    }

    log({ level: "info", phase: "create", step: "display_party_created", message: `Created display party: ${scenario.title}`, data: { partyId } });
  }

  log({ level: "info", phase: "create", step: "display_done", message: `Created ${displayPartyIds.length} display parties, ${displayEventIds.length} display events` });
  return { displayPartyIds, displayEventIds };
}

// Fix #705: Pre-warm auth tokens in parallel to avoid sequential latency per-application
async function prewarmAuthTokens(
  users: { username: string }[],
  supabaseUrl: string,
  anonKey: string,
  simUserPassword: string,
  log: (entry: Omit<SimLogEntry, "timestamp">) => void,
): Promise<void> {
  const BATCH_SIZE = 10;
  const uniqueUsernames = [...new Set(users.map((u) => u.username).filter(Boolean))];
  let warmed = 0;
  let failed = 0;

  for (let i = 0; i < uniqueUsernames.length; i += BATCH_SIZE) {
    const batch = uniqueUsernames.slice(i, i + BATCH_SIZE);
    const results = await Promise.allSettled(
      batch.map((username) =>
        getSimUserToken(supabaseUrl, anonKey, `${username}@test.com`, simUserPassword)
      ),
    );
    for (const r of results) {
      if (r.status === "fulfilled") warmed++;
      else failed++;
    }
  }

  log({
    level: "info",
    phase: "apply",
    step: "prewarm_auth",
    message: `Auth tokens pre-warmed: ${warmed} ok, ${failed} failed (${uniqueUsernames.length} total)`,
  });
}

// Fix #1323: User-centric apply loop — each user discovers events via their own feed,
// then applies up to config.max_apps_per_user times. This ensures per-user RLS is respected
// and eliminates the need for direct DB queries for entry_groups, tickets, or existing apps.
async function applyForUser(
  username: string,
  config: SimConfig,
  log: (entry: Omit<SimLogEntry, "timestamp">) => void,
  newEventIds: string[],
  supabaseUrl: string,
  anonKey: string,
  simUserPassword: string,
): Promise<{ applicationIds: string[]; paidApplicationIds: string[]; pendingReviewApplicationIds: string[] }> {
  const applicationIds: string[] = [];
  const paidApplicationIds: string[] = [];
  const pendingReviewApplicationIds: string[] = [];

  const userEmail = `${username}@test.com`;
  let userToken: string;
  try {
    userToken = await getSimUserToken(supabaseUrl, anonKey, userEmail, simUserPassword);
  } catch (authErr) {
    log({ level: "error", phase: "apply", step: "auth_token", message: `Auth failed for ${username}, skipping: ${String(authErr)}` });
    return { applicationIds, paidApplicationIds, pendingReviewApplicationIds };
  }

  // Each user fetches their own feed — RLS ensures they only see events they can apply to
  let feedEvents: { id: string; title?: string; party?: { title?: string }; tickets?: { id: string; price: number }[] }[] = [];
  try {
    const feedResult = await callEdgeFunction(supabaseUrl, "user-event-feed", { sort_by: "closing_soon", limit: 20 }, userToken);
    if (feedResult.status === 200) {
      const feedData = feedResult.data as { events?: { id: string; title?: string; party?: { title?: string }; tickets?: { id: string; price: number }[] }[] } | null;
      feedEvents = feedData?.events ?? [];
    } else {
      log({ level: "warn", phase: "apply", step: "user_feed", message: `user-event-feed returned status=${feedResult.status} for ${username}` });
    }
  } catch (efErr) {
    log({ level: "warn", phase: "apply", step: "user_feed", message: `user-event-feed threw for ${username}: ${String(efErr)}` });
  }

  // Build the list of events to attempt: feed events (non-E2E) + newEventIds
  // newEventIds are E2E-created; log if they appear in the feed
  const e2eEventIdSet = new Set(newEventIds);
  const feedE2eCount = feedEvents.filter((e) => {
    const partyTitle: string = e.party?.title ?? "";
    return partyTitle.startsWith("[E2E]") || e2eEventIdSet.has(e.id);
  }).length;
  if (feedE2eCount > 0) {
    log({ level: "info", phase: "apply", step: "user_feed", message: `${username}: ${feedE2eCount} E2E event(s) appeared in user feed` });
  }

  // Non-E2E feed events (already visible to this user via their feed)
  const nonE2eFeedEvents = feedEvents.filter((e) => {
    const partyTitle: string = e.party?.title ?? "";
    return !partyTitle.startsWith("[E2E]");
  });

  // E2E events are appended as minimal objects (ticket from newEventIds won't have feed data)
  const e2eEventObjects = newEventIds.map((id) => ({ id, party: { title: "[E2E]" }, tickets: undefined }));

  const candidateEvents = [...nonE2eFeedEvents, ...e2eEventObjects];

  let appsCreated = 0;
  for (const event of candidateEvents) {
    if (appsCreated >= config.max_apps_per_user) break;

    // Skip [E2E] events in this user-centric loop — they are E2E-created and
    // ineligibility/RLS will be enforced by the EF itself; we only skip them
    // here to avoid unneeded EF calls that are expected to fail for regular users.
    const partyTitle: string = (event as { party?: { title?: string } }).party?.title ?? "";
    if (partyTitle.startsWith("[E2E]")) continue;

    // Use ticket from feed response if available
    const ticket = event.tickets?.[0];
    if (!ticket) {
      log({ level: "warn", phase: "apply", step: "ef_apply_event", message: `No ticket in feed for event ${event.id}, skipping` });
      continue;
    }

    // apply-event EF: server enforces eligibility, capacity, duplicate checks
    const efResult = await callEdgeFunction(supabaseUrl, "apply-event", {
      event_id: event.id,
      ticket_id: ticket.id,
    }, userToken);

    if (efResult.status !== 200) {
      log({ level: "warn", phase: "apply", step: "ef_apply_event", message: `apply-event EF returned status=${efResult.status} for user ${username} event ${event.id}` });
      continue;
    }

    const efData = efResult.data as { type: "free" | "paid"; application_id: string } | null;
    if (!efData?.application_id) {
      log({ level: "warn", phase: "apply", step: "ef_apply_event", message: `apply-event EF returned no application_id for user ${username} event ${event.id}` });
      continue;
    }

    applicationIds.push(efData.application_id);
    appsCreated++;

    if (efData.type === "free") {
      pendingReviewApplicationIds.push(efData.application_id);
    } else {
      paidApplicationIds.push(efData.application_id);
    }
  }

  if (appsCreated > 0) {
    log({ level: "info", phase: "apply", step: "user_applied", message: `User ${username}: ${appsCreated} applications` });
  }

  return { applicationIds, paidApplicationIds, pendingReviewApplicationIds };
}

// Fix #1323: User-centric discover-and-apply loop
export async function simDiscoverAndApply(
  supabase: SupabaseClient,
  config: SimConfig,
  log: (entry: Omit<SimLogEntry, "timestamp">) => void,
  newEventIds: string[],
  supabaseUrl?: string,
  anonKey?: string,
  strict?: boolean,
): Promise<{ applicationIds: string[]; paidApplicationIds: string[]; pendingReviewApplicationIds: string[] }> {
  const applicationIds: string[] = [];
  const paidApplicationIds: string[] = [];
  const pendingReviewApplicationIds: string[] = [];

  const simUserPassword = Deno.env.get("SIM_USER_PASSWORD");
  if (!simUserPassword) {
    const errMsg = "SIM_USER_PASSWORD not set; cannot acquire user token for user-event-feed EF";
    if (strict) throw new Error(errMsg);
    log({ level: "warn", phase: "apply", step: "sim_user_password", message: errMsg });
  }

  if (!supabaseUrl || !anonKey || !simUserPassword) {
    const errMsg = "supabaseUrl, anonKey, or SIM_USER_PASSWORD not available — cannot call user-event-feed EF";
    if (strict) throw new Error(errMsg);
    log({ level: "error", phase: "apply", step: "event_feed", message: errMsg });
    return { applicationIds, paidApplicationIds, pendingReviewApplicationIds };
  }

  const { data: usersRaw } = await supabase
    .from("user_profiles")
    .select("id, gender, birth_date, username");
  const users = (usersRaw ?? [])
    .filter((u: { username: string }) => !u.username?.startsWith("partner_"))
    .slice(0, 60) as { id: string; username: string }[];

  if (users.length === 0) {
    log({ level: "warn", phase: "apply", step: "get_users", message: "No seed users found" });
    return { applicationIds, paidApplicationIds, pendingReviewApplicationIds };
  }

  // Fix #705: Pre-warm auth token cache to eliminate sequential auth latency in the apply loop
  await prewarmAuthTokens(users, supabaseUrl, anonKey, simUserPassword, log);

  // Fix #1323: Process users in parallel batches (user-centric loop)
  const batchSize = config.user_batch_size;
  for (let i = 0; i < users.length; i += batchSize) {
    const batch = users.slice(i, i + batchSize);
    const results = await Promise.allSettled(
      batch.map((user) =>
        applyForUser(user.username, config, log, newEventIds, supabaseUrl!, anonKey!, simUserPassword!)
      ),
    );

    for (const result of results) {
      if (result.status === "fulfilled") {
        applicationIds.push(...result.value.applicationIds);
        paidApplicationIds.push(...result.value.paidApplicationIds);
        pendingReviewApplicationIds.push(...result.value.pendingReviewApplicationIds);
      }
    }
  }

  log({ level: "info", phase: "apply", step: "done",
    message: `Total: ${applicationIds.length} (${paidApplicationIds.length} paid, ${pendingReviewApplicationIds.length} pending_review)` });
  return { applicationIds, paidApplicationIds, pendingReviewApplicationIds };
}
