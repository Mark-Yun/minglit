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
    // Simulator location fields — only set for regional personas (#1334)
    sim_region?: string;
    sim_lat?: number;
    sim_lng?: number;
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
  verificationCategories: ("career" | "academic" | "asset")[];
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
    verificationCategories: ["academic"],
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
    verificationCategories: ["career"],
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
    verificationCategories: ["asset"],
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
    verificationCategories: [],
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
    verificationCategories: ["career"],
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
    verificationCategories: [],
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
    verificationCategories: ["career"],
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
    verificationCategories: ["asset"],
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
  // Edge Case 1: 최소 정원 이벤트 (정원 2명) — 매칭/정산의 최소 케이스
  {
    title: "[E2E] 1:1 프리미엄 디너",
    summary: "소수 정예 1:1 매칭 디너",
    minConfirmed: 2,
    maxParticipants: 2,
    verificationCategories: ["asset"],
    entryGroups: [
      { label: "남성", gender: "male", birthYearMin: 1985, birthYearMax: 2000 },
      { label: "여성", gender: "female", birthYearMin: 1985, birthYearMax: 2000 },
    ],
    tickets: [{ name: "디너 티켓", price: 100000, quantity: 2 }],
    metadata: { show_participant_list: false, visibility: "private" },
  },
  // Edge Case 2: 대규모 이벤트 (정원 50명) — 대용량 처리 검증
  {
    title: "[E2E] 대규모 네트워킹 파티",
    summary: "50명 규모의 대형 소셜 네트워킹",
    minConfirmed: 10,
    maxParticipants: 50,
    verificationCategories: [],
    entryGroups: [
      { label: "남성", gender: "male", birthYearMin: 1990, birthYearMax: 2005 },
      { label: "여성", gender: "female", birthYearMin: 1990, birthYearMax: 2005 },
    ],
    tickets: [
      { name: "일반", price: 15000, quantity: 25 },
      { name: "VIP", price: 30000, quantity: 25 },
    ],
    metadata: { show_participant_list: true, visibility: "public" },
  },
  // Edge Case 3: 무료 이벤트 (price: 0) — 0원 결제/환불/정산 처리 검증
  {
    title: "[E2E] 무료 동네 산책 모임",
    summary: "참가비 없는 가벼운 동네 산책",
    minConfirmed: 4,
    maxParticipants: 12,
    verificationCategories: [],
    entryGroups: [
      { label: "남성", gender: "male", birthYearMin: 1990, birthYearMax: 2005 },
      { label: "여성", gender: "female", birthYearMin: 1990, birthYearMax: 2005 },
    ],
    tickets: [{ name: "무료 참가", price: 0, quantity: 12 }],
    metadata: { show_participant_list: true, visibility: "public" },
  },
  // Edge Case 4: 여성 전용 이벤트 (단일 entryGroup) — 단일 그룹 매칭 graceful skip 검증
  {
    title: "[E2E] 여성 전용 와인 클래스",
    summary: "여성만 참가 가능한 와인 테이스팅",
    minConfirmed: 4,
    maxParticipants: 8,
    verificationCategories: [],
    entryGroups: [
      { label: "여성", gender: "female", birthYearMin: 1990, birthYearMax: 2005 },
    ],
    tickets: [{ name: "와인 클래스", price: 35000, quantity: 8 }],
    metadata: { show_participant_list: true, visibility: "public" },
  },
  // Edge Case 5: 연령 제한 극단 (40대 전용) — seed 유저 연령 불일치, 빈 이벤트 graceful 처리
  {
    title: "[E2E] 40대 소셜 디너",
    summary: "40대만 참가 가능한 프리미엄 디너",
    minConfirmed: 4,
    maxParticipants: 8,
    verificationCategories: ["career"],
    entryGroups: [
      { label: "남성", gender: "male", birthYearMin: 1980, birthYearMax: 1989 },
      { label: "여성", gender: "female", birthYearMin: 1980, birthYearMax: 1989 },
    ],
    tickets: [{ name: "디너 티켓", price: 45000, quantity: 8 }],
    metadata: { show_participant_list: false, visibility: "private" },
  },
  // Edge Case 6: 복수 인증 요구 (career + asset 동시) — 다중 인증 승인 플로우 검증
  {
    title: "[E2E] 엘리트 멤버십 라운지",
    summary: "직장인 + 자산 인증 동시 필요",
    minConfirmed: 4,
    maxParticipants: 6,
    verificationCategories: ["career", "asset"],
    entryGroups: [
      { label: "남성", gender: "male", birthYearMin: 1988, birthYearMax: 1998 },
      { label: "여성", gender: "female", birthYearMin: 1988, birthYearMax: 1998 },
    ],
    tickets: [{ name: "멤버십", price: 80000, quantity: 6 }],
    metadata: { show_participant_list: false, visibility: "private" },
  },
  // Edge Case 7: 정원 = 신청 수 (capacity guard 검증, #1219)
  {
    title: "[E2E] 마감 임박 소규모 모임",
    summary: "정원과 신청 수가 동일한 소규모 이벤트",
    minConfirmed: 4,
    maxParticipants: 6,
    verificationCategories: [],
    entryGroups: [
      { label: "남성", gender: "male", birthYearMin: 1995, birthYearMax: 2005 },
      { label: "여성", gender: "female", birthYearMin: 1995, birthYearMax: 2005 },
    ],
    tickets: [{ name: "참가비", price: 20000, quantity: 6 }],
    metadata: { show_participant_list: true, visibility: "public" },
  },
  // Edge Case 8: 고가 티켓 (200,000원) — 환불/정산 금액 정확성 검증
  {
    title: "[E2E] 럭셔리 요트 파티",
    summary: "프리미엄 요트 위 네트워킹 파티",
    minConfirmed: 4,
    maxParticipants: 8,
    verificationCategories: ["asset"],
    entryGroups: [
      { label: "남성 VIP", gender: "male", birthYearMin: 1985, birthYearMax: 1998 },
      { label: "여성 VIP", gender: "female", birthYearMin: 1985, birthYearMax: 1998 },
    ],
    tickets: [{ name: "요트 파티", price: 200000, quantity: 8 }],
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

// Global verifications seeded via dev_seed_bulk_partners RPC.
// Extracted from ensureGlobalVerifications() — single source of truth.
const GLOBAL_VERIFICATIONS = [
  { category: "career", internal_name: "global_career", display_name: "직장인 인증", description: "재직증명서 기반 직장인 인증", icon_key: "briefcase", form_schema: [{ type: "image", label: "재직증명서" }] },
  { category: "academic", internal_name: "global_academic", display_name: "대학생 인증", description: "학생증 기반 대학생 인증", icon_key: "school", form_schema: [{ type: "image", label: "학생증" }] },
  { category: "asset", internal_name: "global_asset", display_name: "자산 인증", description: "자산 보유 인증", icon_key: "diamond", form_schema: [{ type: "text", label: "자산 정보" }] },
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

const SEED_PASSWORD = "password1234!";

// ─── Regional Persona Generation (#1334) ───────────────────────────────────

// 10 major regions with simulator GPS coordinates.
const REGIONS = [
  { name: "강남", lat: 37.4979, lng: 127.0276 },
  { name: "홍대", lat: 37.5575, lng: 126.9245 },
  { name: "성수", lat: 37.5445, lng: 127.0559 },
  { name: "이태원", lat: 37.5340, lng: 126.9948 },
  { name: "잠실", lat: 37.5133, lng: 127.1001 },
  { name: "판교", lat: 37.3948, lng: 127.1112 },
  { name: "부산_해운대", lat: 35.1631, lng: 129.1635 },
  { name: "부산_서면", lat: 35.1578, lng: 129.0596 },
  { name: "대구_동성로", lat: 35.8690, lng: 128.5941 },
  { name: "제주", lat: 33.4996, lng: 126.5312 },
] as const;

// 25 ages(18-42) × 2 genders × 10 regions = 500 regional personas.
// All regional users are is_verified: true for simulation.
// Phone scheme: 010-5{regionIdx:1}{age-18:2}-{gender:1}000
//   → 5000+regionIdx*100+(age-18), last4=1000(male)/2000(female)
//   Max prefix = 5000+9*100+24 = 5924 (4 digits, no overflow).
function generateRegionalPersonas(): UserPersona[] {
  const currentYear = Temporal.Now.plainDateISO().year;
  const personas: UserPersona[] = [];

  for (let age = 18; age <= 42; age++) {
    const birthYear = currentYear - age + 1;
    const birthDate = `${birthYear}-01-01`;

    for (const gender of ["male", "female"] as const) {
      const genderShort = gender === "male" ? "m" : "f";
      const last4 = gender === "male" ? "1000" : "2000";

      for (let ri = 0; ri < REGIONS.length; ri++) {
        const region = REGIONS[ri];
        const prefix = 5000 + ri * 100 + (age - 18);
        const username = `user_${age}_${genderShort}_${region.name}`;

        personas.push({
          email: `${username}@test.com`,
          password: SEED_PASSWORD,
          metadata: {
            name: `${age}${gender === "male" ? "남" : "여"}_${region.name}`,
            username,
            gender,
            birth_date: birthDate,
            phone_number: `010-${prefix}-${last4}`,
            is_verified: true,
            sim_region: region.name,
            sim_lat: region.lat,
            sim_lng: region.lng,
          },
        });
      }
    }
  }

  return personas;
}

// ─── Legacy Persona Generation ──────────────────────────────────────────────

// Merged generatePersonas + generate30sPersonas: covers age 20-34 in a single loop.
// Phone prefix: 20-24 → 1000+age (preserves original), 25-34 → 2000+age (preserves original).
// Email pattern: user_{age}_{m|f}_{ok|no}@test.com — preserved for E2E test compat.
function generateAllPersonas(): UserPersona[] {
  // Fix #446: Date → Temporal API migration
  const currentYear = Temporal.Now.plainDateISO().year;
  const personas: UserPersona[] = [];
  const password = SEED_PASSWORD;

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

  // Fix #1334: include 500 regional personas (25 ages × 2 genders × 10 regions)
  // after the 60 legacy personas. generateAllPersonas() = 60 + 500 = 560 total.
  personas.push(...generateRegionalPersonas());

  return personas;
}

// ─── Helper: Party/Event Creation (used by createFreshEvents) ───────────────

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
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
  if (!anonKey) {
    console.error("SUPABASE_ANON_KEY not set — skipping authed image upload");
    return urls;
  };
  const { data: authData, error: authError } = await supabase.auth
    .signInWithPassword({
      email: ALL_PARTNERS[0].ownerEmail,
      password: SEED_PASSWORD,
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

  // Fix #1272: seed 파트너의 파티만 대상 — 실사용 데이터 보호
  const seedBizNumbers = ALL_PARTNERS.map((p) => p.biz_number);
  const { data: seedPartners } = await supabase
    .from("partners")
    .select("id")
    .in("biz_number", seedBizNumbers);
  const seedPartnerIds = (seedPartners ?? []).map((p: { id: string }) => p.id);
  const { data: parties } = await supabase
    .from("parties")
    .select("id")
    .in("partner_id", seedPartnerIds)
    .order("created_at");
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
    const verifIds = scenario.verificationCategories
      .map((cat) => globalVerifs[cat])
      .filter(Boolean);

    // Fix #1272: 멱등성 — 이미 존재하는 파티는 skip
    const { data: existingParty } = await supabase
      .from("parties")
      .select("id")
      .eq("partner_id", partnerId)
      .eq("title", scenario.title)
      .maybeSingle();
    if (existingParty) continue;

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

    // Fix #1390: 560 admin.createUser() HTTP calls → 2 in-DB RPCs (~4초 total)

    // RPC 1: 유저 560명 + 파트너 오너 (1 RPC, ~3초)
    const allPersonas = generateAllPersonas();
    const partnerOwnerUsers = ALL_PARTNERS.map((p, idx) => ({
      email: p.ownerEmail,
      name: `${p.name} 대표`,
      username: p.ownerEmail.replace("@test.com", ""),
      gender: "male",
      birth_date: idx < 2 ? "1990-01-01" : "1988-01-01",
      phone_number: idx < 2
        ? `010-0000-${String(idx).padStart(4, "0")}`
        : `010-0001-${String(idx - 2).padStart(4, "0")}`,
      is_verified: true,
    }));
    const regularUsers = allPersonas.map((p) => ({
      email: p.email,
      name: p.metadata.name,
      username: p.metadata.username,
      gender: p.metadata.gender,
      birth_date: p.metadata.birth_date,
      phone_number: p.metadata.phone_number,
      is_verified: p.metadata.is_verified,
      sim_region: p.metadata.sim_region ?? null,
      sim_lat: p.metadata.sim_lat ?? null,
      sim_lng: p.metadata.sim_lng ?? null,
    }));
    const { data: userResult, error: userRpcError } = await supabase.rpc(
      "dev_seed_bulk_users",
      { p_users: [...regularUsers, ...partnerOwnerUsers], p_password: SEED_PASSWORD },
    );
    if (userRpcError) throw new Error(`dev_seed_bulk_users: ${userRpcError.message}`);

    // RPC 2: 파트너 + 위치 + 인증 + 역할 (1 RPC, ~1초)
    const partnersPayload = ALL_PARTNERS.map((p) => ({
      name: p.name,
      introduction: p.introduction,
      biz_name: p.biz_name,
      biz_number: p.biz_number,
      contact_email: p.contact_email,
      owner_email: p.ownerEmail,
      location: p.location,
      local_verifications: p.localVerifications,
    }));
    const { data: partnerResult, error: partnerRpcError } = await supabase.rpc(
      "dev_seed_bulk_partners",
      { p_partners: partnersPayload, p_global_verifications: GLOBAL_VERIFICATIONS },
    );
    if (partnerRpcError) throw new Error(`dev_seed_bulk_partners: ${partnerRpcError.message}`);

    const createdUsers = (userResult as { total: number })?.total ?? 0;
    const processedPartners = (partnerResult as { partners_processed: number })?.partners_processed ?? 0;

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
      // Fix #1210: static 모드에서도 기존 파티에 이미지 할당
      // mode=full 없이 재시드 시 party.image_urls가 []로 유지되는 버그 방지
      await updatePartyImages(supabase, imageUrls);
      return successResponse({
        mode,
        created_users: createdUsers,
        created_partners: processedPartners,
        uploaded_images: imageUrls.length,
      });
    }

    // full mode: static + createFreshEvents + updatePartyImages (local compat)
    const { createdParties, createdEvents } = await createFreshEvents(supabase);
    await updatePartyImages(supabase, imageUrls);

    return successResponse({
      mode,
      created_users: createdUsers,
      created_partners: processedPartners,
      uploaded_images: imageUrls.length,
      created_parties: createdParties,
      created_events: createdEvents,
    });
  } catch (err) {
    return errorResponse((err as Error).message, 500);
  }
});
