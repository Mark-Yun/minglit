import { createClient, SupabaseClient } from "@supabase/supabase-js";
import { createServiceClient } from "../_shared/supabase_client.ts";
import { errorResponse, successResponse } from "../_shared/response_utils.ts";

function isProduction(): boolean {
  const env = Deno.env.get("ENVIRONMENT");
  return env !== "local" && env !== "development";
}

interface UserPersona {
  email: string;
  password: string;
  metadata: {
    name: string;
    username: string;
    gender: string;
    birth_date: string;
    phone_number: string;
    is_verified: boolean;
  };
}

interface PartnerDef {
  name: string;
  introduction: string;
  biz_name: string;
  biz_number: string;
  contact_email: string;
  ownerEmail: string;
  location: typeof HOT_PLACES[number];
  localVerifications: {
    category: "career" | "academic" | "asset";
    internal_name: string;
    display_name: string;
    description: string;
    icon_key: string;
    form_schema: unknown[];
  }[];
}

const HOT_PLACES = [
  {
    name: "서울 강남",
    address: "서울특별시 강남구 역삼동",
    lat: 37.4979,
    lng: 127.0276,
    region_1: "서울",
    region_2: "강남구",
    region_3: "역삼동",
  },
  {
    name: "서울 홍대",
    address: "서울특별시 마포구 서교동",
    lat: 37.5575,
    lng: 126.9245,
    region_1: "서울",
    region_2: "마포구",
    region_3: "서교동",
  },
  {
    name: "서울 성수",
    address: "서울특별시 성동구 성수동",
    lat: 37.5445,
    lng: 127.0559,
    region_1: "서울",
    region_2: "성동구",
    region_3: "성수동",
  },
] as const;

const SCENARIOS: {
  title: string;
  summary: string;
  minConfirmed: number;
  maxParticipants: number;
  verificationCategory: "career" | "academic" | "asset" | null;
  entryGroups: {
    label: string;
    gender: "male" | "female";
    birthYearMin: number;
    birthYearMax: number;
  }[];
  tickets: { name: string; price: number; quantity: number }[];
  metadata: { show_participant_list: boolean; visibility: string };
}[] = [
  {
    title: "대학생 소셜 밍글",
    summary: "같은 또래 대학생들이 모여 자연스럽게 네트워킹하는 자리",
    minConfirmed: 4,
    maxParticipants: 10,
    verificationCategory: "academic",
    entryGroups: [
      { label: "남성", gender: "male", birthYearMin: 2001, birthYearMax: 2005 },
      {
        label: "여성",
        gender: "female",
        birthYearMin: 2001,
        birthYearMax: 2005,
      },
    ],
    tickets: [
      { name: "일반 티켓", price: 15000, quantity: 5 },
      { name: "얼리버드", price: 10000, quantity: 5 },
    ],
    metadata: { show_participant_list: true, visibility: "public" },
  },
  {
    title: "직장인 금요 밍글",
    summary: "퇴근 후 가볍게 즐기는 직장인 소셜 파티",
    minConfirmed: 6,
    maxParticipants: 16,
    verificationCategory: "career",
    entryGroups: [
      { label: "남성", gender: "male", birthYearMin: 1995, birthYearMax: 2002 },
      {
        label: "여성",
        gender: "female",
        birthYearMin: 1995,
        birthYearMax: 2002,
      },
    ],
    tickets: [
      { name: "스탠다드", price: 25000, quantity: 8 },
      { name: "프리미엄 (음료 포함)", price: 35000, quantity: 8 },
    ],
    metadata: { show_participant_list: true, visibility: "public" },
  },
  {
    title: "프리미엄 라운지 밍글",
    summary: "검증된 멤버들만 참여하는 프리미엄 소셜 모임",
    minConfirmed: 4,
    maxParticipants: 8,
    verificationCategory: "asset",
    entryGroups: [
      { label: "남성", gender: "male", birthYearMin: 1990, birthYearMax: 2000 },
      {
        label: "여성",
        gender: "female",
        birthYearMin: 1990,
        birthYearMax: 2000,
      },
    ],
    tickets: [
      { name: "VIP 티켓", price: 50000, quantity: 4 },
      { name: "VVIP 티켓 (디너 포함)", price: 80000, quantity: 4 },
    ],
    metadata: { show_participant_list: false, visibility: "private" },
  },
  {
    title: "동네친구 보드게임",
    summary: "보드게임으로 시작하는 가벼운 동네 모임",
    minConfirmed: 4,
    maxParticipants: 8,
    verificationCategory: null,
    entryGroups: [
      {
        label: "참가자",
        gender: "male",
        birthYearMin: 1995,
        birthYearMax: 2005,
      },
      {
        label: "참가자",
        gender: "female",
        birthYearMin: 1995,
        birthYearMax: 2005,
      },
    ],
    tickets: [
      { name: "참가비", price: 10000, quantity: 8 },
    ],
    metadata: { show_participant_list: true, visibility: "public" },
  },
  {
    title: "복합조건 네트워킹",
    summary: "다양한 배경의 사람들이 만나는 복합 네트워킹",
    minConfirmed: 6,
    maxParticipants: 12,
    verificationCategory: "career",
    entryGroups: [
      {
        label: "남성 (20대)",
        gender: "male",
        birthYearMin: 1999,
        birthYearMax: 2005,
      },
      {
        label: "여성 (20대)",
        gender: "female",
        birthYearMin: 1999,
        birthYearMax: 2005,
      },
      {
        label: "남성 (30대)",
        gender: "male",
        birthYearMin: 1990,
        birthYearMax: 1998,
      },
      {
        label: "여성 (30대)",
        gender: "female",
        birthYearMin: 1990,
        birthYearMax: 1998,
      },
    ],
    tickets: [
      { name: "20대 티켓", price: 20000, quantity: 6 },
      { name: "30대 티켓", price: 25000, quantity: 6 },
    ],
    metadata: { show_participant_list: true, visibility: "public" },
  },
  {
    title: "자유 오픈 밍글",
    summary: "누구나 참여 가능한 오픈 소셜 네트워킹",
    minConfirmed: 4,
    maxParticipants: 12,
    verificationCategory: null,
    entryGroups: [
      { label: "남성", gender: "male", birthYearMin: 1990, birthYearMax: 2005 },
      {
        label: "여성",
        gender: "female",
        birthYearMin: 1990,
        birthYearMax: 2005,
      },
    ],
    tickets: [{ name: "참가비", price: 12000, quantity: 12 }],
    metadata: { show_participant_list: true, visibility: "public" },
  },
  {
    title: "직장인 애프터눈 라운지",
    summary: "직장인 인증 필수 — 오후의 여유로운 네트워킹",
    minConfirmed: 4,
    maxParticipants: 10,
    verificationCategory: "career",
    entryGroups: [
      { label: "남성", gender: "male", birthYearMin: 1988, birthYearMax: 2000 },
      {
        label: "여성",
        gender: "female",
        birthYearMin: 1988,
        birthYearMax: 2000,
      },
    ],
    tickets: [{ name: "라운지 티켓", price: 20000, quantity: 10 }],
    metadata: { show_participant_list: true, visibility: "public" },
  },
  {
    title: "VIP 멤버십 파티",
    summary: "파트너 자체 인증 필수 — 엄선된 VIP 멤버십 파티",
    minConfirmed: 4,
    maxParticipants: 8,
    verificationCategory: "asset",
    entryGroups: [
      {
        label: "남성 VIP",
        gender: "male",
        birthYearMin: 1985,
        birthYearMax: 2000,
      },
      {
        label: "여성 VIP",
        gender: "female",
        birthYearMin: 1985,
        birthYearMax: 2000,
      },
    ],
    tickets: [{ name: "VIP 멤버십", price: 60000, quantity: 8 }],
    metadata: { show_participant_list: false, visibility: "private" },
  },
];

// Unified partner list: defined partners (with local verifications) + hot-place partners
const ALL_PARTNERS: PartnerDef[] = [
  {
    name: "밍글 스튜디오",
    introduction: "서울 강남에서 운영하는 프리미엄 소셜 라운지",
    biz_name: "(주)밍글스튜디오",
    biz_number: "123-45-67890",
    contact_email: "partner1@test.com",
    ownerEmail: "partner_owner_1@test.com",
    location: HOT_PLACES[0],
    localVerifications: [
      {
        category: "career",
        internal_name: "mingle_career",
        display_name: "직장인 인증",
        description: "재직증명서 또는 명함 제출",
        icon_key: "briefcase",
        form_schema: [{ type: "image", label: "재직증명서" }],
      },
      {
        category: "academic",
        internal_name: "mingle_academic",
        display_name: "대학생 인증",
        description: "학생증 또는 재학증명서 제출",
        icon_key: "school",
        form_schema: [{ type: "image", label: "학생증" }],
      },
    ],
  },
  {
    name: "파티룸 홍대",
    introduction:
      "홍대에서 가장 힙한 파티룸. 다양한 테마의 소셜 이벤트를 운영합니다.",
    biz_name: "파티룸홍대",
    biz_number: "987-65-43210",
    contact_email: "partner2@test.com",
    ownerEmail: "partner_owner_2@test.com",
    location: HOT_PLACES[1],
    localVerifications: [
      {
        category: "asset",
        internal_name: "hongdae_asset",
        display_name: "자산 인증",
        description: "프리미엄 파티 참가를 위한 자산 인증",
        icon_key: "diamond",
        form_schema: [{ type: "text", label: "자산 정보" }],
      },
    ],
  },
  {
    name: "서울 강남 소셜클럽",
    introduction: "서울 강남 지역 대표 소셜 클럽",
    biz_name: "서울 강남클럽",
    biz_number: "000-00-00000",
    contact_email: "partner_hotplace_0@test.com",
    ownerEmail: "partner_hotplace_0@test.com",
    location: HOT_PLACES[0],
    localVerifications: [],
  },
  {
    name: "서울 홍대 소셜클럽",
    introduction: "서울 홍대 지역 대표 소셜 클럽",
    biz_name: "서울 홍대클럽",
    biz_number: "000-00-00001",
    contact_email: "partner_hotplace_1@test.com",
    ownerEmail: "partner_hotplace_1@test.com",
    location: HOT_PLACES[1],
    localVerifications: [],
  },
  {
    name: "서울 성수 소셜클럽",
    introduction: "서울 성수 지역 대표 소셜 클럽",
    biz_name: "서울 성수클럽",
    biz_number: "000-00-00002",
    contact_email: "partner_hotplace_2@test.com",
    ownerEmail: "partner_hotplace_2@test.com",
    location: HOT_PLACES[2],
    localVerifications: [],
  },
];

function generateDescription(
  title: string,
  summary: string,
): { ops: object[] } {
  return {
    ops: [
      { insert: `${title}\n`, attributes: { bold: true } },
      { insert: "\n" },
      { insert: `${summary}\n` },
      { insert: "\n" },
      { insert: "📍 장소 안내\n", attributes: { bold: true } },
      {
        insert:
          "이벤트 장소는 신청 확정 후 안내드립니다. 대중교통 이용을 권장합니다.\n",
      },
      { insert: "\n" },
      { insert: "✅ 참가 조건\n", attributes: { bold: true } },
      {
        insert:
          "본인 인증 완료 후 신청 가능합니다. 미성년자는 참여가 제한됩니다.\n",
      },
      { insert: "\n" },
      { insert: "🎁 포함 내용\n", attributes: { bold: true } },
      { insert: "음료 1잔 제공, 네트워킹 프로그램 진행, 기념 사진 촬영.\n" },
      { insert: "\n" },
      { insert: "⚠️ 주의사항\n", attributes: { bold: true } },
      {
        insert:
          "노쇼 시 패널티가 부과될 수 있습니다. 취소는 이벤트 24시간 전까지 가능합니다.\n",
      },
    ],
  };
}

// Merged generatePersonas + generate30sPersonas: covers age 20-34 in a single loop.
// Phone prefix: 20-24 → 1000+age (preserves original), 25-34 → 2000+age (preserves original).
// Email pattern: user_{age}_{m|f}_{ok|no}@test.com — preserved for E2E test compat.
function generateAllPersonas(): UserPersona[] {
  // Fix #446: Date → Temporal API migration
  const currentYear = Temporal.Now.plainDateISO().year;
  const personas: UserPersona[] = [];
  const password = "password1234!";

  for (let age = 20; age <= 34; age++) {
    const birthYear = currentYear - age + 1;
    const birthDate = `${birthYear}-01-01`;
    const phonePrefix = age <= 24 ? 1000 + age : 2000 + age;

    const variants = [
      { gender: "male", verified: true, suffix: "인증O" },
      { gender: "male", verified: false, suffix: "인증X" },
      { gender: "female", verified: true, suffix: "인증O" },
      { gender: "female", verified: false, suffix: "인증X" },
    ];

    for (const v of variants) {
      const genderKr = v.gender === "male" ? "남" : "여";
      const genderShort = v.gender === "male" ? "m" : "f";
      const verifShort = v.verified ? "ok" : "no";

      const name = `${age}${genderKr}_${v.suffix}`;
      const username = `user_${age}_${genderShort}_${verifShort}`;
      const email = `${username}@test.com`;
      const last4 = `${v.verified ? "1" : "0"}${
        v.gender === "male" ? "1" : "2"
      }00`;
      const phoneNumber = `010-${phonePrefix}-${last4}`;

      personas.push({
        email,
        password,
        metadata: {
          name,
          username,
          gender: v.gender,
          birth_date: birthDate,
          phone_number: phoneNumber,
          is_verified: v.verified,
        },
      });
    }
  }

  return personas;
}

async function createAdminUser(
  supabase: SupabaseClient,
  persona: UserPersona,
): Promise<string> {
  const { data, error } = await supabase.auth.admin.createUser({
    email: persona.email,
    password: persona.password,
    email_confirm: true,
    app_metadata: { has_password: true },
    user_metadata: persona.metadata,
  });

  if (error) {
    if (
      error.message?.includes("already registered") ||
      (error as any).code === "email_exists"
    ) {
      // Fix #492: 기존 계정 재사용 시 비밀번호·metadata를 seed 값으로 보정 — uploadSeedImages의 signIn이 정상 동작하도록 보장
      const { data: users } = await supabase.auth.admin.listUsers({
        perPage: 1000,
      });
      const existing = users?.users?.find((u: any) =>
        u.email === persona.email
      );
      if (existing) {
        const { data: updatedUser, error: updateError } = await supabase.auth
          .admin.updateUserById(existing.id, {
            password: persona.password,
            app_metadata: { has_password: true },
            user_metadata: persona.metadata,
          });
        if (updateError) {
          throw new Error(
            `Failed to repair existing user ${persona.email} (${existing.id}): ${updateError.message}`,
          );
        }
        if (!updatedUser?.user?.id) {
          throw new Error(
            `Failed to repair existing user ${persona.email} (${existing.id}): missing updated user payload`,
          );
        }
        return existing.id;
      }
      throw new Error(
        `User ${persona.email} reported as existing but not found in listUsers`,
      );
    }
    throw error;
  }

  return data.user?.id ?? "";
}

async function createPartner(
  sb: SupabaseClient,
  ownerId: string,
  partnerDef: {
    name: string;
    introduction: string;
    biz_name: string;
    biz_number: string;
    contact_email: string;
  },
): Promise<string> {
  const { data, error } = await sb.from("partners").insert({
    name: partnerDef.name,
    introduction: partnerDef.introduction,
    biz_name: partnerDef.biz_name,
    biz_number: partnerDef.biz_number,
    contact_email: partnerDef.contact_email,
  }).select("id").single();

  if (error) {
    throw new Error(
      `Failed to create partner "${partnerDef.name}": ${error.message}`,
    );
  }

  const { error: permError } = await sb.from("partner_member_permissions")
    .insert({
      partner_id: data.id,
      user_id: ownerId,
      role: "owner",
    });
  if (permError) {
    throw new Error(`Failed to add owner permission: ${permError.message}`);
  }

  return data.id;
}

async function createLocation(
  sb: SupabaseClient,
  partnerId: string,
  loc: typeof HOT_PLACES[number],
): Promise<string> {
  const { data, error } = await sb.from("locations").insert({
    partner_id: partnerId,
    name: loc.name,
    address: loc.address,
    region_1: loc.region_1,
    region_2: loc.region_2,
    region_3: loc.region_3,
    geo_point: `POINT(${loc.lng} ${loc.lat})`,
  }).select("id").single();

  if (error) {
    throw new Error(
      `Failed to create location "${loc.name}": ${error.message}`,
    );
  }
  return data.id;
}

async function createVerification(
  sb: SupabaseClient,
  partnerId: string | null,
  verif: {
    category: string;
    internal_name: string;
    display_name: string;
    description: string;
    icon_key: string;
    form_schema: unknown[];
  },
): Promise<string> {
  const { data, error } = await sb.from("verifications").insert({
    partner_id: partnerId,
    category: verif.category,
    internal_name: verif.internal_name,
    display_name: verif.display_name,
    description: verif.description,
    icon_key: verif.icon_key,
    form_schema: verif.form_schema,
  }).select("id").single();

  if (error) {
    throw new Error(
      `Failed to create verification "${verif.internal_name}": ${error.message}`,
    );
  }
  return data.id;
}

async function createPartyWithEvents(
  sb: SupabaseClient,
  partnerId: string,
  locationId: string,
  scenario: typeof SCENARIOS[number],
  verificationIds: string[],
): Promise<{ partyId: string; eventIds: string[] }> {
  const { data: party, error: partyErr } = await sb.from("parties").insert({
    partner_id: partnerId,
    location_id: locationId,
    title: scenario.title,
    description: generateDescription(scenario.title, scenario.summary),
    image_urls: [],
    required_verification_ids: verificationIds,
    min_confirmed_count: scenario.minConfirmed,
    max_participants: scenario.maxParticipants,
    status: "active",
    metadata: scenario.metadata,
  }).select("id").single();

  if (partyErr) {
    throw new Error(
      `Failed to create party "${scenario.title}": ${partyErr.message}`,
    );
  }
  const partyId = party.id;

  const templateIds: string[] = [];
  for (const eg of scenario.entryGroups) {
    const { data: egt, error: egtErr } = await sb.from("entry_group_templates")
      .insert({
        party_id: partyId,
        label: eg.label,
        gender: eg.gender,
        birth_year_min: eg.birthYearMin,
        birth_year_max: eg.birthYearMax,
        required_verification_ids: verificationIds,
      }).select("id").single();
    if (egtErr) {
      throw new Error(
        `Failed to create entry_group_template: ${egtErr.message}`,
      );
    }
    templateIds.push(egt.id);
  }

  for (const ticket of scenario.tickets) {
    const { error: ttErr } = await sb.from("ticket_templates").insert({
      party_id: partyId,
      name: ticket.name,
      price: ticket.price,
      quantity: ticket.quantity,
      target_entry_group_ids: templateIds,
    });
    if (ttErr) {
      throw new Error(`Failed to create ticket_template: ${ttErr.message}`);
    }
  }

  // Fix #446: Date → Temporal API migration (Pattern D — date arithmetic)
  const eventIds: string[] = [];

  for (let i = 0; i < 2; i++) {
    const today = Temporal.Now.plainDateISO();
    const eventDate = today.add({ days: i === 0 ? 3 : 10 });
    const startInstant = eventDate
      .toZonedDateTime(Temporal.Now.timeZoneId())
      .with({ hour: 19, minute: 0, second: 0, millisecond: 0 })
      .toInstant();
    const endInstant = eventDate
      .toZonedDateTime(Temporal.Now.timeZoneId())
      .with({ hour: 22, minute: 0, second: 0, millisecond: 0 })
      .toInstant();

    const { data: event, error: eventErr } = await sb.from("events").insert({
      party_id: partyId,
      location_id: locationId,
      start_time: startInstant.toString(),
      end_time: endInstant.toString(),
      min_confirmed_count: scenario.minConfirmed,
      max_participants: scenario.maxParticipants,
      status: "scheduled",
      metadata: scenario.metadata,
    }).select("id").single();

    if (eventErr) {
      throw new Error(`Failed to create event: ${eventErr.message}`);
    }
    eventIds.push(event.id);

    const entryGroupIds: string[] = [];
    for (const eg of scenario.entryGroups) {
      const { data: entryGroup, error: egErr } = await sb.from("entry_groups")
        .insert({
          event_id: event.id,
          label: eg.label,
          gender: eg.gender,
          birth_year_min: eg.birthYearMin,
          birth_year_max: eg.birthYearMax,
          required_verification_ids: verificationIds,
        }).select("id").single();
      if (egErr) {
        throw new Error(`Failed to create entry_group: ${egErr.message}`);
      }
      entryGroupIds.push(entryGroup.id);
    }

    for (const ticket of scenario.tickets) {
      const { error: ticketErr } = await sb.from("tickets").insert({
        event_id: event.id,
        name: ticket.name,
        price: ticket.price,
        quantity: ticket.quantity,
        target_entry_group_ids: entryGroupIds,
        status: "on_sale",
      });
      if (ticketErr) {
        throw new Error(`Failed to create ticket: ${ticketErr.message}`);
      }
    }
  }

  return { partyId, eventIds };
}

async function ensureGlobalVerifications(
  sb: SupabaseClient,
): Promise<Record<string, string>> {
  const globals = [
    {
      category: "career",
      internal_name: "global_career",
      display_name: "직장인 인증",
      description: "재직증명서 기반 직장인 인증",
      icon_key: "briefcase",
      form_schema: [{ type: "image", label: "재직증명서" }],
    },
    {
      category: "academic",
      internal_name: "global_academic",
      display_name: "대학생 인증",
      description: "학생증 기반 대학생 인증",
      icon_key: "school",
      form_schema: [{ type: "image", label: "학생증" }],
    },
    {
      category: "asset",
      internal_name: "global_asset",
      display_name: "자산 인증",
      description: "자산 보유 인증",
      icon_key: "diamond",
      form_schema: [{ type: "text", label: "자산 정보" }],
    },
  ];

  const result: Record<string, string> = {};

  for (const g of globals) {
    const { data: existing } = await sb.from("verifications")
      .select("id")
      .is("partner_id", null)
      .eq("internal_name", g.internal_name)
      .maybeSingle();

    if (existing) {
      result[g.category] = existing.id;
    } else {
      const id = await createVerification(sb, null, g);
      result[g.category] = id;
    }
  }

  return result;
}

// ─── Domain Seeding Functions ───────────────────────────────────────

// Merged seedUsers + seed30sUsers: covers ages 20-34 via generateAllPersonas.
async function seedAllUsers(supabase: SupabaseClient): Promise<number> {
  const personas = generateAllPersonas();
  let createdUsers = 0;

  for (const persona of personas) {
    try {
      await createAdminUser(supabase, persona);
      createdUsers++;
    } catch (err) {
      console.error(`Failed to create ${persona.email}:`, err);
      throw err;
    }
  }

  return createdUsers;
}

async function uploadSeedImages(supabase: SupabaseClient): Promise<string[]> {
  const imageFiles = [
    "party_cafe_warm.jpg",
    "party_lounge_bright.jpg",
    "party_premium_lounge.jpg",
  ];
  const urls: string[] = [];

  // Check if images already exist in storage (uploaded externally or by a previous run)
  // Use listV2 (cursor-based pagination) over deprecated list() — see #445
  const { data: existing } = await supabase.storage.from("party-assets").listV2(
    { prefix: "seed-images/", limit: 10 },
  );
  const existingNames = new Set(
    (existing?.objects ?? []).map((f: { name: string }) =>
      f.name.replace("seed-images/", "")
    ),
  );

  // If all images already exist, just return their public URLs
  const allExist = imageFiles.every((f) => existingNames.has(f));
  if (allExist) {
    for (const filename of imageFiles) {
      const { data } = supabase.storage.from("party-assets").getPublicUrl(
        `seed-images/${filename}`,
      );
      urls.push(data.publicUrl);
    }
    return urls;
  }

  // Sign in as the first partner owner so storage trigger can set minglit_files.owner_id
  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
  const { data: authData, error: authError } = await supabase.auth
    .signInWithPassword({
      email: ALL_PARTNERS[0].ownerEmail,
      password: "password1234!",
    });
  if (authError || !authData.session) {
    console.error(
      "Failed to sign in as partner owner for image upload:",
      authError?.message,
    );
    return urls;
  }

  const authedClient = createClient(supabaseUrl, anonKey, {
    global: {
      headers: { Authorization: `Bearer ${authData.session.access_token}` },
    },
  });

  for (const filename of imageFiles) {
    try {
      const fileUrl = new URL(`./assets/${filename}`, import.meta.url);
      const bytes = await Deno.readFile(fileUrl);
      const path = `seed-images/${filename}`;

      const { error } = await authedClient.storage
        .from("party-assets")
        .upload(path, bytes, { contentType: "image/jpeg", upsert: true });

      if (error) {
        console.error(`Failed to upload ${filename}:`, error.message);
        continue;
      }

      const { data } = supabase.storage.from("party-assets").getPublicUrl(path);
      urls.push(data.publicUrl);
    } catch (err) {
      console.error(`Error uploading ${filename}:`, err);
    }
  }

  return urls;
}

async function updatePartyImages(
  supabase: SupabaseClient,
  imageUrls: string[],
): Promise<void> {
  if (imageUrls.length === 0) return;

  const { data: parties } = await supabase.from("parties").select("id").order(
    "created_at",
  );
  if (!parties) return;

  for (let i = 0; i < parties.length; i++) {
    const shuffled = [
      imageUrls[i % imageUrls.length],
      imageUrls[(i + 1) % imageUrls.length],
      imageUrls[(i + 2) % imageUrls.length],
    ];
    await supabase.from("parties").update({ image_urls: shuffled }).eq(
      "id",
      parties[i].id,
    );
  }
}

async function seedGlobalVerifications(
  supabase: SupabaseClient,
): Promise<Record<string, string>> {
  return await ensureGlobalVerifications(supabase);
}

// Merged seedDefinedPartners + seedHotPlacePartners into a single idempotent function.
// Uses ALL_PARTNERS which combines SEED_PARTNERS (with local verifications) and hot-place partners.
async function seedAllPartners(
  supabase: SupabaseClient,
  globalVerifs: Record<string, string>,
): Promise<{ createdPartners: number }> {
  let createdPartners = 0;

  for (let idx = 0; idx < ALL_PARTNERS.length; idx++) {
    const pDef = ALL_PARTNERS[idx];
    const ownerPersona: UserPersona = {
      email: pDef.ownerEmail,
      password: "password1234!",
      metadata: {
        name: `${pDef.name} 대표`,
        username: pDef.ownerEmail.replace("@test.com", ""),
        gender: "male",
        birth_date: idx < 2 ? "1990-01-01" : "1988-01-01",
        phone_number: idx < 2
          ? `010-0000-${String(idx).padStart(4, "0")}`
          : `010-0001-${String(idx - 2).padStart(4, "0")}`,
        is_verified: true,
      },
    };

    let ownerId: string;
    try {
      ownerId = await createAdminUser(supabase, ownerPersona);
    } catch (err) {
      console.error(`Failed to create partner owner ${pDef.ownerEmail}:`, err);
      continue;
    }

    // Idempotency: skip partner creation if already exists
    const { data: existingPartner } = await supabase
      .from("partners")
      .select("id")
      .eq("biz_number", pDef.biz_number)
      .maybeSingle();

    if (existingPartner) {
      createdPartners++;
      continue;
    }

    const partnerId = await createPartner(supabase, ownerId, pDef);
    createdPartners++;

    await createLocation(supabase, partnerId, pDef.location);

    for (const lv of pDef.localVerifications) {
      const vid = await createVerification(supabase, partnerId, lv);
      globalVerifs[`${partnerId}_${lv.category}`] = vid;
    }
  }

  return { createdPartners };
}

async function seedPartnerRoles(supabase: SupabaseClient): Promise<void> {
  // Assign first 2 seed users as manager/staff to the first seed partner
  // Fix #492: biz_number으로 시드 파트너를 정확히 조회 (order/limit 대신)
  const { data: firstPartner } = await supabase
    .from("partners")
    .select("id")
    .eq("biz_number", ALL_PARTNERS[0].biz_number)
    .maybeSingle();

  if (!firstPartner) return;

  // Fix #492: 정확한 seed username 집합으로 조회 (LIKE 패턴 대신)
  const seedUsernames = ["user_20_m_ok", "user_20_f_ok"];
  const { data: seedUsers } = await supabase
    .from("user_profiles")
    .select("id")
    .in("username", seedUsernames)
    .order("username")
    .limit(2);

  if (!seedUsers || seedUsers.length < 2) return;

  const roles = ["manager", "staff"] as const;
  for (let i = 0; i < Math.min(seedUsers.length, roles.length); i++) {
    // Fix #492: ignoreDuplicates 제거 — 재실행 시 role drift 방지를 위해 onConflict update 허용
    const { error } = await supabase.from("partner_member_permissions").upsert({
      partner_id: firstPartner.id,
      user_id: seedUsers[i].id,
      role: roles[i],
    }, { onConflict: "partner_id,user_id" });

    if (error) {
      console.error(`Failed to assign ${roles[i]} role:`, error.message);
    }
  }
}

// createFreshEvents: for ?mode=full only. Queries existing partners/locations from DB
// and creates new parties + events using SCENARIOS. Replaces seedDefinedPartners/seedHotPlacePartners
// event creation for local development.
async function createFreshEvents(
  supabase: SupabaseClient,
): Promise<{ createdParties: number; createdEvents: number }> {
  const { data: partners } = await supabase
    .from("partners")
    .select("id")
    .order("created_at");

  if (!partners || partners.length === 0) {
    return { createdParties: 0, createdEvents: 0 };
  }

  const { data: globalVerifRows } = await supabase
    .from("verifications")
    .select("id, category")
    .is("partner_id", null);

  const globalVerifs: Record<string, string> = {};
  for (const v of (globalVerifRows ?? [])) {
    globalVerifs[v.category] = v.id;
  }

  let createdParties = 0;
  let createdEvents = 0;

  for (let pi = 0; pi < partners.length; pi++) {
    const partnerId = partners[pi].id;

    const { data: location } = await supabase
      .from("locations")
      .select("id")
      .eq("partner_id", partnerId)
      .limit(1)
      .maybeSingle();

    if (!location) continue;

    const scenario = SCENARIOS[pi % SCENARIOS.length];
    const verifIds = scenario.verificationCategory
      ? [globalVerifs[scenario.verificationCategory]].filter(Boolean)
      : [];

    const { eventIds } = await createPartyWithEvents(
      supabase,
      partnerId,
      location.id,
      scenario,
      verifIds,
    );
    createdParties++;
    createdEvents += eventIds.length;
  }

  return { createdParties, createdEvents };
}

Deno.serve(async (req) => {
  // Handle CORS preflight before any auth/env checks
  if (req.method === "OPTIONS") {
    return new Response(null, {
      status: 204,
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers":
          "authorization, x-client-info, apikey, content-type",
        "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
      },
    });
  }

  if (isProduction()) {
    return errorResponse("Dev-only function. Blocked in production.", 403);
  }

  const url = new URL(req.url);
  const mode = url.searchParams.get("mode") ?? "static";

  if (mode !== "static" && mode !== "full") {
    return errorResponse(
      `Invalid mode: "${mode}". Use "static" or "full".`,
      400,
    );
  }

  try {
    const supabase = createServiceClient();

    // static mode: idempotent seed of users, verifications, partners, roles, images
    const createdUsers = await seedAllUsers(supabase);
    const globalVerifs = await seedGlobalVerifications(supabase);
    const { createdPartners } = await seedAllPartners(supabase, globalVerifs);
    await seedPartnerRoles(supabase);
    const imageUrls = await uploadSeedImages(supabase);

    // Purge pgmq queues to avoid queue bloat after seeding
    for (const queue of ["q_global_events", "q_notifications", "q_vectors"]) {
      try {
        await supabase.rpc("pgmq_purge", { queue_name: queue });
      } catch {
        // pgmq may not be available in all environments — ignore errors
      }
    }

    if (mode === "static") {
      return successResponse({
        mode,
        created_users: createdUsers,
        created_partners: createdPartners,
        uploaded_images: imageUrls.length,
      });
    }

    // full mode: static + createFreshEvents + updatePartyImages (local compat)
    const { createdParties, createdEvents } = await createFreshEvents(supabase);
    await updatePartyImages(supabase, imageUrls);

    return successResponse({
      mode,
      created_users: createdUsers,
      created_partners: createdPartners,
      uploaded_images: imageUrls.length,
      created_parties: createdParties,
      created_events: createdEvents,
    });
  } catch (err) {
    return errorResponse((err as Error).message, 500);
  }
});
