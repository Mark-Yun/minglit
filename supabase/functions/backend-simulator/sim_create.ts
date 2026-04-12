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
  supabaseUrl: string,
  anonKey: string,
): Promise<{ partyIds: string[]; eventIds: string[] }> {
  const partyIds: string[] = [];
  const eventIds: string[] = [];

  const simUserPassword = Deno.env.get("SIM_USER_PASSWORD");
  if (!simUserPassword) {
    throw new Error("SIM_USER_PASSWORD is required for EF path");
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

    // ── Step 1: Acquire partner JWT ───────────────────────────────────────────
    const partnerEmail = await getPartnerEmail(supabase, partner.id);
    if (!partnerEmail) {
      throw new Error(`No email for partner ${partner.id}`);
    }
    const partnerToken = await getSimPartnerToken(supabaseUrl, anonKey, partnerEmail, simUserPassword);

    // ── Step 2: Create party via EF ───────────────────────────────────────────
    const partyEfResult = await callEdgeFunction(supabaseUrl, "partner-manage-party", {
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

    const partyEfData = partyEfResult.data as { success?: boolean; party_id?: string } | null;
    if (partyEfResult.status !== 200 || !partyEfData?.success || !partyEfData?.party_id) {
      throw new Error(`EF partner-manage-party returned status=${partyEfResult.status}`);
    }
    const partyId = partyEfData.party_id;
    log({ level: "info", phase: "create", step: "ef_create_party", message: `EF created party: ${scenario.title}`, data: { partyId } });
    partyIds.push(partyId);

    // ── Step 3: Fetch ticket_templates created by the party EF ───────────────
    const { data: templates } = await supabase
      .from("ticket_templates")
      .select("id, name")
      .eq("party_id", partyId);
    const ticketTemplates = (templates ?? []) as { id: string; name: string }[];

    // ── Step 4: Create events via EF ──────────────────────────────────────────
    for (let ei = 0; ei < config.events_per_party; ei++) {
      const now = new Date();
      const startTime = new Date(now.getTime() + START_TIME_OFFSETS_MS[ei % 4]);
      const endTime = new Date(startTime.getTime() + 3 * 60 * 60 * 1000);

      const eventEfResult = await callEdgeFunction(supabaseUrl, "partner-manage-event", {
        action: "create",
        party_id: partyId,
        event: {
          start_time: startTime.toISOString(),
          end_time: endTime.toISOString(),
          max_participants: 20,
          min_confirmed_count: 4,
          title: `${scenario.title} #${ei + 1}`,
          metadata: { show_participant_list: true, visibility: "public" },
        },
        tickets: ticketTemplates.map((t) => ({
          template_id: t.id,
          quantity: 10,
        })),
      }, partnerToken);

      const eventEfData = eventEfResult.data as { success?: boolean; event_id?: string } | null;
      if (eventEfResult.status !== 200 || !eventEfData?.success || !eventEfData?.event_id) {
        throw new Error(`EF partner-manage-event returned status=${eventEfResult.status}`);
      }
      const eventId = eventEfData.event_id;
      log({ level: "info", phase: "create", step: "ef_create_event", message: `EF created event ${ei + 1} for party ${partyId}`, data: { eventId } });
      eventIds.push(eventId);
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
  supabaseUrl: string,
  anonKey: string,
): Promise<{ displayPartyIds: string[]; displayEventIds: string[] }> {
  const displayPartyIds: string[] = [];
  const displayEventIds: string[] = [];

  const simUserPassword = Deno.env.get("SIM_USER_PASSWORD");
  if (!simUserPassword) {
    throw new Error("SIM_USER_PASSWORD is required for EF path");
  }

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

    // Acquire partner JWT for EF calls
    const partnerEmail = await getPartnerEmail(supabase, partner.id);
    if (!partnerEmail) {
      throw new Error(`No email for partner ${partner.id}`);
    }
    const partnerToken = await getSimPartnerToken(supabaseUrl, anonKey, partnerEmail, simUserPassword);

    // Fix #964: [E2E] location 재사용 방지 — display 이벤트가 E2E 테스트용 location에 붙지 않도록 필터링
    const { data: location } = await supabase
      .from("locations")
      .select("id")
      .eq("partner_id", partner.id)
      .not("name", "ilike", "[E2E]%")
      .maybeSingle();

    const locationId_existing = location?.id as string | undefined;

    // Create display party via EF
    const partyEfResult = await callEdgeFunction(supabaseUrl, "partner-manage-party", {
      action: "create",
      partner_id: partner.id,
      party: {
        title: scenario.title,
        description: { ops: [{ insert: `${scenario.description}\n` }] },
        image_urls: [],
        required_verification_ids: [],
        min_confirmed_count: 4,
        max_participants: 30,
        status: "active",
        metadata: { show_participant_list: true, visibility: "public" },
      },
      ...(locationId_existing
        ? { location_id: locationId_existing }
        : {
            location: {
              name: "전시용 테스트 장소",
              address: "서울특별시 강남구 역삼동",
              region_1: "서울",
              region_2: "강남구",
            },
          }),
      entry_group_templates: [
        { label: "남성", gender: "male", birth_year_min: 1990, birth_year_max: 2005 },
        { label: "여성", gender: "female", birth_year_min: 1990, birth_year_max: 2005 },
      ],
      ticket_templates: [
        { name: "일반 티켓", price: 0, quantity: 30 },
      ],
    }, partnerToken);

    const partyEfData = partyEfResult.data as { success?: boolean; party_id?: string } | null;
    if (partyEfResult.status !== 200 || !partyEfData?.success || !partyEfData?.party_id) {
      throw new Error(`EF partner-manage-party returned status=${partyEfResult.status} for display party`);
    }
    const partyId = partyEfData.party_id;
    displayPartyIds.push(partyId);

    // Fetch ticket_templates created by the party EF
    const { data: templates } = await supabase
      .from("ticket_templates")
      .select("id, name")
      .eq("party_id", partyId);
    const ticketTemplates = (templates ?? []) as { id: string; name: string }[];

    // 파티당 이벤트 2개 (같은 시나리오, 시작 시간만 +3시간 차이)
    for (let ei = 0; ei < 2; ei++) {
      const now = new Date();
      const startTime = new Date(now.getTime() + scenario.offsetDays * 24 * 60 * 60 * 1000 + ei * 3 * 60 * 60 * 1000);
      const endTime = new Date(startTime.getTime() + 3 * 60 * 60 * 1000);

      const eventEfResult = await callEdgeFunction(supabaseUrl, "partner-manage-event", {
        action: "create",
        party_id: partyId,
        event: {
          title: `${scenario.title} #${ei + 1}`,
          start_time: startTime.toISOString(),
          end_time: endTime.toISOString(),
          max_participants: 30,
          min_confirmed_count: 4,
          metadata: { show_participant_list: true, visibility: "public" },
        },
        tickets: ticketTemplates.map((t) => ({
          template_id: t.id,
          quantity: 30,
        })),
      }, partnerToken);

      const eventEfData = eventEfResult.data as { success?: boolean; event_id?: string } | null;
      if (eventEfResult.status !== 200 || !eventEfData?.success || !eventEfData?.event_id) {
        throw new Error(`EF partner-manage-event returned status=${eventEfResult.status} for display event`);
      }
      displayEventIds.push(eventEfData.event_id);
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
// Note: #1283 에서 strict 파라미터 제거 및 EF-only 전환 예정 (simCreateParties/simCreateDisplayEvents와 일관성)
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
