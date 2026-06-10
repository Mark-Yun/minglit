export type Ticket = {
  id: string;
  name: string;
  description: string | null;
  price: number;
  quantity: number;
  soldCount: number;
  status: string;
  targetEntryGroupIds?: string[];
};

export type EntryGender = "male" | "female";

export type EntryGroupEligibility = {
  id: string;
  gender: EntryGender | null;
  birthYearMin: number | null;
  birthYearMax: number | null;
  requiredVerificationIds: string[];
};

export type EligibilityProfile = {
  gender: EntryGender | null;
  birthDate?: string | null;
  verificationData?: Record<string, unknown> | null;
};

export type PublicEvent = {
  id: string;
  title: string;
  description: string;
  imageUrl: string | null;
  // Full ordered image list for the detail hero carousel. Falls back to
  // [imageUrl] when only a single image is available; empty when none.
  images: string[];
  startsAt: string;
  endsAt: string;
  status: string;
  maxParticipants: number;
  currentParticipants: number;
  partnerName: string;
  partnerIntro: string;
  locationName: string;
  locationAddress: string;
  tags: string[];
  tickets: Ticket[];
  // Kept for backward-compatible callers; the home eligibility filter uses
  // ticket target groups via `entryGroups` below.
  entryGroupGenders?: EntryGender[];
  entryGroups?: EntryGroupEligibility[];
};

type PostgrestEvent = {
  id: string;
  title?: string | null;
  description?: unknown;
  image_urls?: string[] | null;
  visibility?: string | null;
  start_time: string;
  end_time: string;
  status: string;
  max_participants?: number | null;
  current_participants?: number | null;
  parties?: {
    title?: string | null;
    description?: unknown;
    image_urls?: string[] | null;
    visibility?: string | null;
    status?: string | null;
    partners?: { name?: string | null; introduction?: string | null } | null;
    locations?: {
      name?: string | null;
      address?: string | null;
      region_1?: string | null;
      region_2?: string | null;
    } | null;
  } | null;
  locations?: {
    name?: string | null;
    address?: string | null;
    region_1?: string | null;
    region_2?: string | null;
  } | null;
  tickets?: Array<{
    id: string;
    name: string;
    description?: string | null;
    price?: number | null;
    quantity?: number | null;
    sold_count?: number | null;
    status?: string | null;
    target_entry_group_ids?: string[] | null;
  }> | null;
  entry_groups?: Array<{
    id: string;
    gender?: string | null;
    birth_year_min?: number | null;
    birth_year_max?: number | null;
    required_verification_ids?: string[] | null;
  }> | null;
};

type FetchEventsResult = {
  rows: PostgrestEvent[];
  shouldUseDemoFallback: boolean;
};

type VisibilityMode = "event-public" | "inherited-public";

const EVENT_SELECT = [
  "id",
  "title",
  "description",
  "image_urls",
  "visibility",
  "start_time",
  "end_time",
  "status",
  "max_participants",
  "current_participants",
  "parties!inner(title,description,image_urls,visibility,status,partners(name,introduction),locations(name,address,region_1,region_2))",
  "locations(name,address,region_1,region_2)",
  "tickets(id,name,description,price,quantity,sold_count,status,target_entry_group_ids)",
  "entry_groups(id,gender,birth_year_min,birth_year_max,required_verification_ids)",
].join(",");

const DEMO_EVENTS: PublicEvent[] = [
  {
    id: "demo-gangnam-social",
    title: "강남 와인 소셜 나이트",
    description:
      "퇴근 후 가볍게 와인과 대화를 즐기는 소셜 모임입니다. 처음 오는 사람도 편하게 합류할 수 있도록 호스트가 테이블을 안내합니다.",
    imageUrl: "https://picsum.photos/seed/minglit-web-wine/1200/600",
    images: [
      "https://picsum.photos/seed/minglit-web-wine/1200/600",
      "https://picsum.photos/seed/minglit-web-wine-2/1200/600",
      "https://picsum.photos/seed/minglit-web-wine-3/1200/600",
    ],
    startsAt: "2026-07-04T10:30:00+09:00",
    endsAt: "2026-07-04T13:00:00+09:00",
    status: "scheduled",
    maxParticipants: 20,
    currentParticipants: 12,
    partnerName: "밍글 스튜디오",
    partnerIntro: "검증된 소셜 이벤트를 운영하는 밍글릿 파트너",
    locationName: "서울 강남",
    locationAddress: "서울 강남구 테헤란로",
    tags: ["와인", "네트워킹", "강남"],
    tickets: [
      {
        id: "demo-ticket-standard",
        name: "일반 참가권",
        description: "웰컴 드링크 1잔 포함",
        price: 39000,
        quantity: 20,
        soldCount: 12,
        status: "on_sale",
        targetEntryGroupIds: [],
      },
    ],
  },
  {
    id: "demo-art-class",
    title: "성수 아트 클래스 밋업",
    description:
      "작은 드로잉 워크숍과 전시 토크가 이어지는 주말 클래스입니다. 재료는 현장에서 제공합니다.",
    imageUrl: "https://picsum.photos/seed/minglit-web-art/1200/600",
    images: ["https://picsum.photos/seed/minglit-web-art/1200/600"],
    startsAt: "2026-07-11T15:00:00+09:00",
    endsAt: "2026-07-11T18:00:00+09:00",
    status: "active",
    maxParticipants: 16,
    currentParticipants: 15,
    partnerName: "성수 커뮤니티 라운지",
    partnerIntro: "취향 기반 클래스와 밋업을 여는 공간",
    locationName: "서울 성수",
    locationAddress: "서울 성동구 연무장길",
    tags: ["아트", "클래스", "성수"],
    tickets: [
      {
        id: "demo-ticket-art",
        name: "클래스 참가권",
        description: "재료비 포함",
        price: 45000,
        quantity: 16,
        soldCount: 15,
        status: "on_sale",
        targetEntryGroupIds: [],
      },
    ],
  },
  {
    id: "demo-running",
    title: "한강 러닝 크루 첫 모임",
    description:
      "가벼운 5km 러닝 후 근처 카페에서 대화를 나누는 입문자 환영 모임입니다.",
    imageUrl: "https://picsum.photos/seed/minglit-web-run/1200/600",
    images: ["https://picsum.photos/seed/minglit-web-run/1200/600"],
    startsAt: "2026-07-18T08:00:00+09:00",
    endsAt: "2026-07-18T10:30:00+09:00",
    status: "scheduled",
    maxParticipants: 24,
    currentParticipants: 24,
    partnerName: "한강 액티브 클럽",
    partnerIntro: "건강한 취미 모임을 만드는 파트너",
    locationName: "서울 여의도",
    locationAddress: "서울 영등포구 여의동로",
    tags: ["스포츠", "러닝", "한강"],
    tickets: [
      {
        id: "demo-ticket-running",
        name: "참가권",
        description: "러닝 리더 동행",
        price: 0,
        quantity: 24,
        soldCount: 24,
        status: "sold_out",
        targetEntryGroupIds: [],
      },
    ],
  },
];

export async function getPublicEvents(): Promise<PublicEvent[]> {
  const result = await fetchEventsFromSupabase();
  const events = result.rows
    .filter(isPubliclyVisible)
    .map(mapEvent)
    .filter((event) => event.status !== "cancelled");

  if (events.length > 0) return events;

  return result.shouldUseDemoFallback ? DEMO_EVENTS : [];
}

export async function getPublicEvent(id: string): Promise<PublicEvent | null> {
  const result = await fetchEventsFromSupabase(id);
  const row = result.rows.find(isPubliclyVisible);
  const event = row ? mapEvent(row) : null;

  if (event && event.status !== "cancelled") return event;

  return result.shouldUseDemoFallback ? (DEMO_EVENTS.find((demo) => demo.id === id) ?? null) : null;
}

async function fetchEventsFromSupabase(id?: string): Promise<FetchEventsResult> {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const key = process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY;

  if (!url || !key) return { rows: [], shouldUseDemoFallback: true };

  try {
    const fetchOptions: RequestInit & { next: { revalidate: number } } = {
      headers: {
        apikey: key,
        Authorization: `Bearer ${key}`,
      },
      next: { revalidate: 60 },
    };
    const nowIso = new Date().toISOString();
    const results = await Promise.all([
      fetchEventRows(buildEventsEndpoint(url, id, nowIso, "event-public"), fetchOptions),
      fetchEventRows(buildEventsEndpoint(url, id, nowIso, "inherited-public"), fetchOptions),
    ]);

    if (results.some((rows) => rows === null)) {
      return { rows: [], shouldUseDemoFallback: false };
    }

    return { rows: mergeEventRows(results.flat() as PostgrestEvent[], id ? 1 : 24), shouldUseDemoFallback: false };
  } catch {
    return { rows: [], shouldUseDemoFallback: false };
  }
}

function buildEventsEndpoint(baseUrl: string, id: string | undefined, nowIso: string, visibilityMode: VisibilityMode) {
  const endpoint = new URL("/rest/v1/events", baseUrl);
  endpoint.searchParams.set("select", EVENT_SELECT);
  endpoint.searchParams.set("status", "in.(scheduled,active,ongoing,completed)");
  endpoint.searchParams.set("parties.status", "eq.active");
  endpoint.searchParams.set("order", "start_time.asc");
  endpoint.searchParams.set("limit", id ? "1" : "24");

  if (visibilityMode === "event-public") {
    endpoint.searchParams.set("visibility", "eq.public");
  } else {
    endpoint.searchParams.set("visibility", "is.null");
    endpoint.searchParams.set("parties.visibility", "eq.public");
  }

  if (id) {
    endpoint.searchParams.set("id", `eq.${id}`);
  } else {
    endpoint.searchParams.set("start_time", `gte.${nowIso}`);
  }

  return endpoint;
}

async function fetchEventRows(endpoint: URL, fetchOptions: RequestInit & { next: { revalidate: number } }) {
  const response = await fetch(endpoint, fetchOptions);
  if (!response.ok) return null;
  return (await response.json()) as PostgrestEvent[];
}

function mergeEventRows(rows: PostgrestEvent[], limit: number): PostgrestEvent[] {
  const byId = new Map<string, PostgrestEvent>();
  for (const row of rows) {
    if (!byId.has(row.id)) byId.set(row.id, row);
  }

  return [...byId.values()]
    .sort((a, b) => new Date(a.start_time).getTime() - new Date(b.start_time).getTime())
    .slice(0, limit);
}

function isPubliclyVisible(row: PostgrestEvent): boolean {
  return (row.visibility ?? row.parties?.visibility) === "public" && row.parties?.status === "active";
}

function mapEvent(row: PostgrestEvent): PublicEvent {
  const party = row.parties;
  const location = row.locations ?? party?.locations;
  const tickets = (row.tickets ?? []).map((ticket) => ({
    id: ticket.id,
    name: ticket.name,
    description: ticket.description ?? null,
    price: ticket.price ?? 0,
    quantity: ticket.quantity ?? 0,
    soldCount: ticket.sold_count ?? 0,
    status: ticket.status ?? "on_sale",
    targetEntryGroupIds: normalizeStringArray(ticket.target_entry_group_ids),
  }));
  const rawImages = (row.image_urls?.length ? row.image_urls : party?.image_urls) ?? [];
  const imageUrl = rawImages[0] ?? null;
  const images = rawImages.length > 0 ? rawImages : imageUrl ? [imageUrl] : [];
  const title = row.title ?? party?.title ?? "이벤트";

  return {
    entryGroupGenders: mapEntryGroupGenders(row.entry_groups),
    id: row.id,
    title,
    description: readableDescription(row.description ?? party?.description),
    imageUrl,
    images,
    startsAt: row.start_time,
    endsAt: row.end_time,
    status: row.status,
    maxParticipants: row.max_participants ?? 0,
    currentParticipants: row.current_participants ?? 0,
    partnerName: party?.partners?.name ?? "Minglit Partner",
    partnerIntro: party?.partners?.introduction ?? "검증된 이벤트를 운영하는 밍글릿 파트너",
    locationName: location?.name ?? [location?.region_1, location?.region_2].filter(Boolean).join(" ") ?? "장소 미정",
    locationAddress: location?.address ?? "상세 장소는 신청 후 안내됩니다.",
    tags: buildTags(title, location?.region_2 ?? location?.region_1),
    tickets,
    entryGroups: mapEntryGroups(row.entry_groups),
  };
}

export function isEventEligibleForProfile(
  event: PublicEvent,
  profile: EligibilityProfile,
): boolean {
  if (!profile.gender) return false;
  if (!isEventOpenForApplication(event.status)) return false;
  if (event.maxParticipants > 0 && event.currentParticipants >= event.maxParticipants) return false;

  const entryGroups = event.entryGroups ?? [];
  return event.tickets.some((ticket) => isTicketEligibleForProfile(ticket, entryGroups, profile));
}

function isTicketEligibleForProfile(
  ticket: Ticket,
  entryGroups: EntryGroupEligibility[],
  profile: EligibilityProfile,
): boolean {
  if (!isTicketOrderable(ticket)) return false;

  const targetGroupIds = ticket.targetEntryGroupIds ?? [];
  if (targetGroupIds.length === 0) return true;

  const groupsById = new Map(entryGroups.map((group) => [group.id, group]));
  const targetGroups = targetGroupIds
    .map((id) => groupsById.get(id))
    .filter((group): group is EntryGroupEligibility => group !== undefined);

  return evaluateEntryGroupEligibility(targetGroups, profile);
}

function evaluateEntryGroupEligibility(
  entryGroups: EntryGroupEligibility[],
  profile: EligibilityProfile,
): boolean {
  if (entryGroups.length === 0) return true;

  const primaryGroup = entryGroups[0];
  if (primaryGroup.gender && primaryGroup.gender !== profile.gender) return false;

  const birthYear = parseBirthYear(profile.birthDate);
  if (birthYear !== null) {
    if (primaryGroup.birthYearMin !== null && birthYear < primaryGroup.birthYearMin) return false;
    if (primaryGroup.birthYearMax !== null && birthYear > primaryGroup.birthYearMax) return false;
  }

  const requiredIds = entryGroups.flatMap((group) => group.requiredVerificationIds);
  if (requiredIds.length > 0 && !profile.verificationData) return false;

  return true;
}

function isEventOpenForApplication(status: string): boolean {
  return status === "scheduled" || status === "active";
}

function isTicketOrderable(ticket: Ticket): boolean {
  return ticket.status === "on_sale" && (ticket.quantity <= 0 || ticket.soldCount < ticket.quantity);
}

function parseBirthYear(value: string | null | undefined): number | null {
  if (!value) return null;
  const year = new Date(value).getFullYear();
  return Number.isFinite(year) ? year : null;
}

function mapEntryGroupGenders(groups: PostgrestEvent["entry_groups"]): EntryGender[] {
  if (!groups || groups.length === 0) return [];

  const genders = new Set<EntryGender>();
  for (const group of groups) {
    // A null-gender group is unrestricted → the whole event is open to all.
    if (group.gender == null) return [];
    if (group.gender === "male" || group.gender === "female") genders.add(group.gender);
  }

  return Array.from(genders);
}

function mapEntryGroups(groups: PostgrestEvent["entry_groups"]): EntryGroupEligibility[] {
  if (!groups || groups.length === 0) return [];

  return groups.map((group) => ({
    id: group.id,
    gender: group.gender === "male" || group.gender === "female" ? group.gender : null,
    birthYearMin: group.birth_year_min ?? null,
    birthYearMax: group.birth_year_max ?? null,
    requiredVerificationIds: normalizeStringArray(group.required_verification_ids),
  }));
}

function normalizeStringArray(value: unknown): string[] {
  return Array.isArray(value) ? value.filter((item): item is string => typeof item === "string") : [];
}

function readableDescription(value: unknown): string {
  if (typeof value === "string" && value.trim()) return value;
  if (value && typeof value === "object") {
    const record = value as Record<string, unknown>;
    const candidates = [record.text, record.body, record.summary, record.content];
    const found = candidates.find((candidate) => typeof candidate === "string" && candidate.trim());
    if (typeof found === "string") return found;
  }

  return "이벤트 소개가 준비 중입니다. 상세한 진행 방식과 안내는 파트너가 순차적으로 업데이트합니다.";
}

function buildTags(title: string, region?: string | null): string[] {
  const tags = new Set<string>();

  if (region) tags.add(region);
  if (/클래스|아트|문화/.test(title)) tags.add("클래스");
  if (/러닝|스포츠|운동/.test(title)) tags.add("스포츠");
  if (/와인|소셜|네트워킹|모임/.test(title)) tags.add("소셜");
  if (tags.size === 0) tags.add("이벤트");

  return Array.from(tags).slice(0, 3);
}
