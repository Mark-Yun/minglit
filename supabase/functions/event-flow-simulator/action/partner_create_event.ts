// action/partner_create_event.ts — PartnerActionCreateEvent (EF: partner-manage-party)
//
// Fix #1540: 시드 이미지 URL 사용 — 홈/이벤트 화면 이미지 깨짐 방지.

import type { ActionDef } from "./_registry.ts";
import { registerAction } from "./_registry.ts";

const SEED_IMAGE_FILENAMES = [
  "party_cafe_warm.jpg",
  "party_lounge_bright.jpg",
  "party_premium_lounge.jpg",
];

const MIN_SCHEDULED_EVENTS = 2;

export const partnerCreateEventAction: ActionDef = {
  type: "partner_create_event",
  role: "partner",
  ef: "partner-manage-party",

  canExecute(state) {
    const myEvents = (state.myEvents as Array<{ status: string }>) ?? [];
    const myParties = (state.myParties as Array<unknown>) ?? [];
    // 파티 없거나 scheduled event 가 임계치 미만 → 신규 생성
    if (myParties.length === 0) return true;
    const scheduledCount = myEvents.filter((e) => e.status === "scheduled").length;
    return scheduledCount < MIN_SCHEDULED_EVENTS;
  },

  buildPayload(_state, _rng) {
    const now = Date.now();
    // supabaseUrl 은 transport 단계에서 주입 (각 액션이 EF 호출 시 URL 알아야 함)
    // 본 payload 는 placeholder — 실제 image_urls 빌드는 transport 가 수행
    return {
      action: "create",
      _imageFilenames: SEED_IMAGE_FILENAMES,
      party: {
        title: `[E2E] Tick Party ${now}`,
        description: { ops: [{ insert: "Auto-generated tick simulation party\n" }] },
        required_verification_ids: [],
        min_confirmed_count: 4,
        max_participants: 20,
        status: "active",
        metadata: { show_participant_list: true, visibility: "public" },
      },
      location: {
        name: "[E2E] 틱 시뮬레이션 장소",
        address: "서울시 강남구",
        region_1: "서울",
        region_2: "강남구",
      },
      entry_group_templates: [
        { label: "남성", gender: "male", birth_year_min: 1990, birth_year_max: 2005 },
        { label: "여성", gender: "female", birth_year_min: 1990, birth_year_max: 2005 },
      ],
      ticket_templates: [{ name: "일반", price: 15000, quantity: 20 }],
    };
  },
};

registerAction(partnerCreateEventAction);
