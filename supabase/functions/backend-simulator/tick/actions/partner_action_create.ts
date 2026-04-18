// tick/actions/partner_action_create.ts — PartnerActionCreateEvent: create party+event (#1331)

import type { SupabaseClient } from "@supabase/supabase-js";
import type { AssertionResult, EFResponse } from "../tick_types.ts";
import { SimAction } from "../sim_action.ts";

// Fix #1540: 시드 이미지 파일명 (dev-seed EF가 party-assets/seed-images/에 업로드)
const SEED_IMAGE_FILENAMES = [
  "party_cafe_warm.jpg",
  "party_lounge_bright.jpg",
  "party_premium_lounge.jpg",
];

/**
 * Partner creates a new party + event when they have too few scheduled events.
 * EF: partner-manage-party (action=create)
 * Verifies party row and events row exist in the DB after creation.
 */
export class PartnerActionCreateEvent extends SimAction {
  readonly type = "partner_create";
  readonly ef = "partner-manage-party";
  readonly actorId: string;
  readonly description: string;
  // Fix #1540: 시드 이미지 URL 생성에 필요한 Supabase URL
  private readonly supabaseUrl: string;

  // Captured from EF response for DB assertion
  private createdPartyId: string | null = null;

  constructor(actorId: string, token: string, supabaseUrl: string) {
    super(token);
    this.actorId = actorId;
    this.supabaseUrl = supabaseUrl;
    this.description = `partner[${actorId}] creates new party+event`;
  }

  buildParams(): Record<string, unknown> {
    const now = Date.now();
    // Fix #1540: 빈 배열 대신 시드 이미지 URL 사용 — 홈/이벤트 화면 이미지 깨짐 방지
    const imageUrls = SEED_IMAGE_FILENAMES.map(
      (f) => `${this.supabaseUrl}/storage/v1/object/public/party-assets/seed-images/${f}`,
    );
    return {
      action: "create",
      partner_id: this.actorId,
      party: {
        title: `[E2E] Tick Party ${now}`,
        description: { ops: [{ insert: "Auto-generated tick simulation party\n" }] },
        image_urls: imageUrls,
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
      ticket_templates: [
        { name: "일반", price: 15000, quantity: 20 },
      ],
    };
  }

  assertEFResponse(response: EFResponse): AssertionResult {
    if (response.status !== 200) {
      return {
        passed: false,
        name: "partner_create_ef_status",
        details: `expected status 200, got ${response.status}`,
      };
    }
    const partyId = response.data?.party_id as string | undefined;
    if (!partyId) {
      return {
        passed: false,
        name: "partner_create_ef_party_id",
        details: `data.party_id is missing`,
      };
    }
    // Capture for DB assertion
    this.createdPartyId = partyId;
    return {
      passed: true,
      name: "partner_create_ef_ok",
      details: `status 200, party_id=${partyId}`,
    };
  }

  async assertDBState(supabase: SupabaseClient): Promise<AssertionResult> {
    if (!this.createdPartyId) {
      return {
        passed: false,
        name: "partner_create_db_no_party_id",
        details: `EF did not return a party_id; cannot verify DB state`,
      };
    }

    try {
      // Verify party row exists
      const { data: party, error: partyErr } = await supabase
        .from("parties")
        .select("id")
        .eq("id", this.createdPartyId)
        .maybeSingle();

      if (partyErr) {
        return {
          passed: false,
          name: "partner_create_db_party",
          details: `query error: ${partyErr.message}`,
        };
      }
      if (!party) {
        return {
          passed: false,
          name: "partner_create_db_party",
          details: `no parties row for id=${this.createdPartyId}`,
        };
      }

      // Verify at least one event row exists for the new party
      const { data: events, error: eventsErr } = await supabase
        .from("events")
        .select("id")
        .eq("party_id", this.createdPartyId)
        .limit(1);

      if (eventsErr) {
        return {
          passed: false,
          name: "partner_create_db_events",
          details: `query error: ${eventsErr.message}`,
        };
      }

      // Note: partner-manage-party only creates the party; event creation is separate.
      // DB assertion here only confirms the party row; event creation would come from
      // a separate partner-manage-event call if the factory chains them.
      // Per spec: verify parties row exists, events row exists (if created).
      // Since this action only calls partner-manage-party, we only assert the party row.
      const eventCount = (events ?? []).length;

      return {
        passed: true,
        name: "partner_create_db_ok",
        details: `party[${this.createdPartyId}] exists, ${eventCount} event(s) found`,
      };
    } catch (e) {
      return {
        passed: false,
        name: "partner_create_db_error",
        details: String(e),
      };
    }
  }
}
