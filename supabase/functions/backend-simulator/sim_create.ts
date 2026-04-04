import { createClient, type SupabaseClient } from "@supabase/supabase-js";
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
          log({ level: "warn", phase: "create", step: "get_partner_email", message: `No email for partner ${partner.id}, EF path skipped` });
        }
      } catch (authErr) {
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

// Fix #705: Process a single event's applications (extracted for parallel execution)
async function applyForEvent(
  supabase: SupabaseClient,
  eventId: string,
  // deno-lint-ignore no-explicit-any
  users: any[],
  config: SimConfig,
  log: (entry: Omit<SimLogEntry, "timestamp">) => void,
  supabaseUrl?: string,
  anonKey?: string,
  simUserPassword?: string,
): Promise<{ applicationIds: string[]; paidApplicationIds: string[]; pendingReviewApplicationIds: string[] }> {
  const applicationIds: string[] = [];
  const paidApplicationIds: string[] = [];
  const pendingReviewApplicationIds: string[] = [];

  const { data: entryGroups } = await supabase
    .from("entry_groups")
    .select("id, gender, birth_year_min, birth_year_max")
    .eq("event_id", eventId);
  if (!entryGroups || entryGroups.length === 0) {
    return { applicationIds, paidApplicationIds, pendingReviewApplicationIds };
  }

  const { data: ticketsRaw } = await supabase
    .from("tickets")
    .select("id, price, status")
    .eq("event_id", eventId);
  const tickets = (ticketsRaw ?? []).filter((t: { status: string }) => t.status === "on_sale");
  if (tickets.length === 0) {
    return { applicationIds, paidApplicationIds, pendingReviewApplicationIds };
  }
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
    const mockPaymentId = `e2e_pay_${crypto.randomUUID().slice(0, 8)}`;

    // Attempt to use apply_event RPC with user-scoped client when auth credentials are available
    if (supabaseUrl && anonKey && simUserPassword && user.username) {
      const userEmail = `${user.username}@test.com`;
      try {
        const userToken = await getSimUserToken(supabaseUrl, anonKey, userEmail, simUserPassword);
        const userClient = createClient(supabaseUrl, anonKey, {
          auth: { persistSession: false },
          global: { headers: { Authorization: `Bearer ${userToken}` } },
        });

        // apply_event RPC: pass verification_data=null for happy path (→ 'paid'), non-null for pending_review
        const rpcParams = {
          p_event_id: eventId,
          p_ticket_id: ticket.id,
          p_user_id: user.id,
          p_payment_id: isHappyPath ? mockPaymentId : null,
          p_payment_amount: isHappyPath ? ticket.price : null,
          p_verification_data: isHappyPath ? null : { source: "e2e_sim" },
        };

        const { data: appId, error: rpcErr } = await userClient.rpc("apply_event", rpcParams);
        if (rpcErr) {
          log({ level: "warn", phase: "apply", step: "rpc_apply_event", message: `RPC failed for user ${userEmail} event ${eventId}: ${rpcErr.message}` });
          continue;
        }

        const newAppId = appId as string;
        applicationIds.push(newAppId);
        appliedUserIds.add(user.id);
        appsCreated++;

        if (isHappyPath) {
          paidApplicationIds.push(newAppId);
        } else {
          pendingReviewApplicationIds.push(newAppId);
        }
        continue;
      } catch (authErr) {
        // Fall through to service_role direct insert if auth fails (e.g. user not seeded)
        log({ level: "warn", phase: "apply", step: "auth_fallback", message: `Auth failed for ${user.username}, using direct insert: ${String(authErr)}` });
      }
    }

    // Fallback: service_role direct insert (used when auth credentials not available or auth fails)
    const appId = crypto.randomUUID();
    const { error: appErr } = await supabase.from("event_applications").insert({
      id: appId,
      event_id: eventId,
      ticket_id: ticket.id,
      user_id: user.id,
      status: isHappyPath ? "paid" : "pending_review",
      payment_amount: isHappyPath ? ticket.price : null,
      payment_id: isHappyPath ? mockPaymentId : null,
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
      const { error: participantErr } = await supabase.from("event_participants").insert({
        id: crypto.randomUUID(),
        event_id: eventId,
        ticket_id: ticket.id,
        user_id: user.id,
        application_id: appId,
        status: "ticket_issued",
        birth_year: birthYear,
      });
      if (participantErr) {
        log({ level: "warn", phase: "create", step: "create_participant", message: `Failed to create participant: ${participantErr.message}` });
      }
    } else {
      pendingReviewApplicationIds.push(appId);
    }
  }

  if (appsCreated > 0) {
    log({ level: "info", phase: "apply", step: "event_applied", message: `Event ${eventId}: ${appsCreated} applications` });
  }

  return { applicationIds, paidApplicationIds, pendingReviewApplicationIds };
}

// Fix #705: Concurrency limit for parallel event processing to avoid overwhelming DB
const EVENT_CONCURRENCY = 5;

export async function simDiscoverAndApply(
  supabase: SupabaseClient,
  config: SimConfig,
  log: (entry: Omit<SimLogEntry, "timestamp">) => void,
  newEventIds: string[],
  supabaseUrl?: string,
  anonKey?: string,
): Promise<{ applicationIds: string[]; paidApplicationIds: string[]; pendingReviewApplicationIds: string[] }> {
  const applicationIds: string[] = [];
  const paidApplicationIds: string[] = [];
  const pendingReviewApplicationIds: string[] = [];

  const simUserPassword = Deno.env.get("SIM_USER_PASSWORD");
  if (supabaseUrl && anonKey && !simUserPassword) {
    log({ level: "warn", phase: "apply", step: "sim_user_password", message: "SIM_USER_PASSWORD not set; EF apply path disabled, using direct DB only" });
  }

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

  // Fix #705: Pre-warm auth token cache to eliminate sequential auth latency in the apply loop
  if (supabaseUrl && anonKey && simUserPassword) {
    await prewarmAuthTokens(users as { username: string }[], supabaseUrl, anonKey, simUserPassword, log);
  }

  // Fix #705: Process events in parallel batches instead of sequentially
  for (let i = 0; i < allEventIds.length; i += EVENT_CONCURRENCY) {
    const batch = allEventIds.slice(i, i + EVENT_CONCURRENCY);
    const results = await Promise.allSettled(
      batch.map((eventId) =>
        applyForEvent(supabase, eventId, users, config, log, supabaseUrl, anonKey, simUserPassword)
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
