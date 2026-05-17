// action/new_actions_test.ts — 신규 7 액션 smoke 테스트 (identity + canExecute 분기)
//
// apply.ts 의 apply_test.ts 가 자세한 패턴 모범. 본 파일은 7 액션의 식별자/기본
// 분기만 검증해서 PR 회귀 가드 역할. 추후 액션별 *_test.ts 분리 가능 (#TBD issue).

import { assertEquals } from "@std/assert";
import { refundAction } from "./refund.ts";
import { checkinAction } from "./checkin.ts";
import { discoverAction } from "./discover.ts";
import { voteAction } from "./vote.ts";
import { blockAction } from "./block.ts";
import { partnerApproveAction } from "./partner_approve.ts";
import { partnerRejectAction } from "./partner_reject.ts";
import { partnerCreateEventAction } from "./partner_create_event.ts";
import { createPRNG } from "../core/types.ts";

const rng = createPRNG(1);

// ============================================================
// Identity 가드 — type / role / ef wiring
// ============================================================

Deno.test({
  name: "action identity wiring — user actions",
  fn: () => {
    assertEquals(refundAction.type, "user_refund");
    assertEquals(refundAction.role, "user");
    assertEquals(refundAction.ef, "user-cancel-order");

    assertEquals(checkinAction.type, "user_checkin");
    assertEquals(checkinAction.role, "user");
    assertEquals(checkinAction.ef, "event-checkin");

    assertEquals(discoverAction.type, "user_discover");
    assertEquals(discoverAction.role, "user");
    assertEquals(discoverAction.ef, "user-event-feed");

    assertEquals(voteAction.type, "user_vote");
    assertEquals(voteAction.role, "user");
    assertEquals(voteAction.ef, "user-cast-vote");

    assertEquals(blockAction.type, "user_block");
    assertEquals(blockAction.role, "user");
    // block 은 direct DB write — ef undefined 의도적
    assertEquals(blockAction.ef, undefined);
  },
});

Deno.test({
  name: "action identity wiring — partner actions",
  fn: () => {
    assertEquals(partnerApproveAction.type, "partner_approve");
    assertEquals(partnerApproveAction.role, "partner");
    assertEquals(partnerApproveAction.ef, "partner-approve-application");

    assertEquals(partnerRejectAction.type, "partner_reject");
    assertEquals(partnerRejectAction.role, "partner");
    assertEquals(partnerRejectAction.ef, "partner-reject-application");

    assertEquals(partnerCreateEventAction.type, "partner_create_event");
    assertEquals(partnerCreateEventAction.role, "partner");
    assertEquals(partnerCreateEventAction.ef, "partner-manage-party");
  },
});

// ============================================================
// canExecute 핵심 분기
// ============================================================

Deno.test({
  name: "refundAction.canExecute - false when no approved/paid application",
  fn: () => {
    assertEquals(refundAction.canExecute({ myApplications: [], visibleEvents: [] }), false);
  },
});

Deno.test({
  name: "refundAction.canExecute - false when event starts within 7-day cutoff",
  fn: () => {
    const tomorrow = new Date(Date.now() + 1 * 86400_000).toISOString();
    const state = {
      myApplications: [{ id: "a1", event_id: "e1", status: "approved" }],
      visibleEvents: [{ id: "e1", status: "scheduled", start_time: tomorrow }],
    };
    assertEquals(refundAction.canExecute(state), false);
  },
});

Deno.test({
  name: "refundAction.canExecute - true when application approved + event ≥7 days away",
  fn: () => {
    const future = new Date(Date.now() + 10 * 86400_000).toISOString();
    const state = {
      myApplications: [{ id: "a1", event_id: "e1", status: "approved" }],
      visibleEvents: [{ id: "e1", status: "scheduled", start_time: future }],
    };
    assertEquals(refundAction.canExecute(state), true);
  },
});

Deno.test({
  name: "checkinAction.canExecute - true when ticket_issued participant in active event",
  fn: () => {
    const state = {
      myParticipations: [{ id: "p1", event_id: "e1", status: "ticket_issued" }],
      visibleEvents: [{ id: "e1", status: "active" }],
    };
    assertEquals(checkinAction.canExecute(state), true);
  },
});

Deno.test({
  name: "checkinAction.canExecute - false when event not active",
  fn: () => {
    const state = {
      myParticipations: [{ id: "p1", event_id: "e1", status: "ticket_issued" }],
      visibleEvents: [{ id: "e1", status: "scheduled" }],
    };
    assertEquals(checkinAction.canExecute(state), false);
  },
});

Deno.test({
  name: "discoverAction.canExecute - always true (read-only, rate-driven sampling)",
  fn: () => {
    assertEquals(discoverAction.canExecute({}), true);
  },
});

Deno.test({
  name: "voteAction.canExecute - true when checked_in in ongoing event",
  fn: () => {
    const state = {
      myParticipations: [{ event_id: "e1", status: "checked_in" }],
      visibleEvents: [{ id: "e1", status: "ongoing" }],
    };
    assertEquals(voteAction.canExecute(state), true);
  },
});

Deno.test({
  name: "blockAction.canExecute - true when applied event partner not yet blocked",
  fn: () => {
    const state = {
      myApplications: [{ event_id: "e1", status: "approved" }],
      visibleEvents: [{ id: "e1", party_id: "party1" }],
      myBlocks: [],
    };
    assertEquals(blockAction.canExecute(state), true);
  },
});

Deno.test({
  name: "blockAction.canExecute - false when already blocked all applied partners",
  fn: () => {
    const state = {
      myApplications: [{ event_id: "e1", status: "approved" }],
      visibleEvents: [{ id: "e1", party_id: "party1" }],
      myBlocks: [{ target_id: "party1", target_type: "partner" }],
    };
    assertEquals(blockAction.canExecute(state), false);
  },
});

Deno.test({
  name: "partnerApproveAction.canExecute - true when pending applications exist",
  fn: () => {
    assertEquals(partnerApproveAction.canExecute({ pendingApplications: [{ id: "a1" }] }), true);
    assertEquals(partnerApproveAction.canExecute({ pendingApplications: [] }), false);
  },
});

Deno.test({
  name: "partnerRejectAction.canExecute - true when pending applications exist",
  fn: () => {
    assertEquals(partnerRejectAction.canExecute({ pendingApplications: [{ id: "a1" }] }), true);
    assertEquals(partnerRejectAction.canExecute({ pendingApplications: [] }), false);
  },
});

Deno.test({
  name: "partnerCreateEventAction.canExecute - true when no parties yet",
  fn: () => {
    assertEquals(
      partnerCreateEventAction.canExecute({ myParties: [], myEvents: [] }),
      true,
    );
  },
});

Deno.test({
  name: "partnerCreateEventAction.canExecute - true when scheduled events below min(2)",
  fn: () => {
    const state = {
      myParties: [{ id: "p1" }],
      myEvents: [{ status: "scheduled" }],  // 1 < 2
    };
    assertEquals(partnerCreateEventAction.canExecute(state), true);
  },
});

Deno.test({
  name: "partnerCreateEventAction.canExecute - false when scheduled events ≥ min(2)",
  fn: () => {
    const state = {
      myParties: [{ id: "p1" }],
      myEvents: [{ status: "scheduled" }, { status: "scheduled" }],
    };
    assertEquals(partnerCreateEventAction.canExecute(state), false);
  },
});

// ============================================================
// buildPayload smoke — happy path 1건씩
// ============================================================

Deno.test({
  name: "buildPayload smoke — refund / checkin / vote / block / partner_approve / partner_reject / partner_create",
  fn: () => {
    const future = new Date(Date.now() + 10 * 86400_000).toISOString();

    const refundPayload = refundAction.buildPayload({
      myApplications: [{ id: "a1", event_id: "e1", status: "paid" }],
      visibleEvents: [{ id: "e1", status: "scheduled", start_time: future }],
    }, rng);
    assertEquals(refundPayload, { event_id: "e1" });

    const checkinPayload = checkinAction.buildPayload({
      myParticipations: [{ id: "p1", event_id: "e1", status: "ticket_issued" }],
      visibleEvents: [{ id: "e1", status: "active" }],
    }, rng);
    assertEquals(checkinPayload, { event_id: "e1", participant_id: "p1" });

    const votePayload = voteAction.buildPayload({
      myParticipations: [{ event_id: "e1", status: "checked_in" }],
      visibleEvents: [{ id: "e1", status: "ongoing" }],
    }, rng);
    assertEquals(votePayload.event_id, "e1");

    const blockPayload = blockAction.buildPayload({
      myApplications: [{ event_id: "e1", status: "approved" }],
      visibleEvents: [{ id: "e1", party_id: "party1" }],
      myBlocks: [],
    }, rng);
    assertEquals(blockPayload, { party_id: "party1" });

    const approvePayload = partnerApproveAction.buildPayload({
      pendingApplications: [{ id: "a1" }],
    }, rng);
    assertEquals(approvePayload, { application_id: "a1" });

    const rejectPayload = partnerRejectAction.buildPayload({
      pendingApplications: [{ id: "a1" }],
    }, rng);
    assertEquals(rejectPayload, { application_id: "a1" });

    const createPayload = partnerCreateEventAction.buildPayload({}, rng);
    assertEquals(createPayload.action, "create");
    assertEquals(Array.isArray((createPayload.party as Record<string, unknown>).description), false);
  },
});
