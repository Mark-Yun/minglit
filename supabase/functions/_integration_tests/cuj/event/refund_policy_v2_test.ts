// cuj/event/refund_policy_v2_test.ts — 환불 정책 이원화 CUJ integration tests
//
// 대상 EF: user-cancel-order
// spec.md: docs/features/event/refund-policy-v2/spec.md
//
// PORTONE_API_URL env 를 dev-mock-portone 으로 redirect 해야 PortOne 호출이 성공한다.
// 예: PORTONE_API_URL=http://127.0.0.1:54321/functions/v1/dev-mock-portone
//
// Skipped CUJs (frontend-only 또는 EF 미존재):
//   1-2 — 다이얼로그에서 "돌아가기" : 상태 변경 없는 UI 전용 액션. EF 호출 없음.
//   1-3 — 환불 완료 후 라벨 표시 : DB row 읽기 + 프론트엔드 라벨 렌더링. EF 호출 없음.
//   2-2 — 결제 전 환불 정책 안내 시트 : 정적 UI. EF 호출 없음.
//   2-3 — 환불 정책 섹션 인라인 표시 : 시간 계산 + 프론트엔드 렌더링. EF 없음.
//   3-1 — 자동 환불 불가 → 파트너 요청 바텀시트 : UI 단독. EF 호출 없음.
//   3-3 — 환불 요청 결과 상태 라벨 : 프론트엔드 라벨. EF 호출 없음.
//   3-4 — 72시간 미응답 에스컬레이션 : cron 기반. user-cancel-order 와 무관한 별도 워커 필요.
//         TODO: scenario 'user-with-pending-refund-request' + escalation cron EF 추가 시 구현
//   4-1 — 파트너 환불 요청 알림 카드 : 프론트엔드 알림 탭. EF 호출 없음.
//   4-2 — 파트너 환불 요청 상세 + 승인 : TODO — EF 'partner-approve-refund' 미존재
//         partner-approve-application 는 신청 심사용. 환불 승인 전용 EF 필요.
//   4-3 — 파트너 환불 요청 거절 : TODO — 'partner-reject-refund' EF 미존재
//   5-1 — 파트너 귀책 일괄 자동 환불 : partner-manage-event (update_status: cancelled) 트리거 기반.
//         TODO: scenario 'partner-cancels-event-with-paid-participants' 추가 후 구현
//
// Covered CUJs: 1-1, 2-1, 3-2, 5-2 (4 / 15 CUJ)
// Skip:         1-2, 1-3, 2-2, 2-3, 3-1, 3-3, 3-4, 4-1, 4-2, 4-3, 5-1 (11 / 15 CUJ)

import { assert, assertEquals, assertMatch } from "jsr:@std/assert@1";
import { suite } from "../../_framework/suite.ts";
import { cujTest } from "../../_framework/cuj_test.ts";
import type { Ctx } from "../../_framework/suite.ts";

const ctx = suite("event/refund-policy-v2");

// ─── Helpers ──────────────────────────────────────────────────────────────────

/** 테스트용 user 를 auth.users + user_profiles 에 생성하고 userId 반환 */
async function seedUser(
  db: Ctx["db"],
  email: string,
  username: string,
): Promise<string> {
  const password = Deno.env.get("SIM_USER_PASSWORD") ?? "password1234!";
  const { data: existing } = await db.auth.admin.listUsers();
  let userId = existing?.users.find((u) => u.email === email)?.id;
  if (!userId) {
    const { data, error } = await db.auth.admin.createUser({
      email,
      password,
      email_confirm: true,
      user_metadata: { username },
    });
    if (error) throw new Error(`seedUser createUser(${email}): ${error.message}`);
    userId = data.user!.id;
  }
  const { error: profileErr } = await db
    .from("user_profiles")
    .upsert({ id: userId, username }, { onConflict: "id" });
  if (profileErr) throw new Error(`seedUser profile(${username}): ${profileErr.message}`);
  return userId;
}

/** 최소 partner + party + event 를 INSERT 하고 eventId 반환.
 *  tickets 테이블에 티켓도 삽입. 반환: { partnerId, partyId, eventId, ticketId }
 */
async function seedPartnerEvent(
  db: Ctx["db"],
  opts: {
    startTime: Date;   // 이벤트 시작 시각
    paymentAmount: number;
  },
): Promise<{ partnerId: string; partyId: string; eventId: string; ticketId: string }> {
  // 1. Partner
  const { data: partner, error: partnerErr } = await db
    .from("partners")
    .insert({ name: "Test Partner Co." })
    .select("id")
    .single();
  if (partnerErr || !partner) throw new Error(`seedPartnerEvent partner: ${partnerErr?.message}`);
  const partnerId = partner.id as string;

  // 2. Party
  const { data: party, error: partyErr } = await db
    .from("parties")
    .insert({ partner_id: partnerId, name: "Test Party" })
    .select("id")
    .single();
  if (partyErr || !party) throw new Error(`seedPartnerEvent party: ${partyErr?.message}`);
  const partyId = party.id as string;

  // 3. Event
  const endTime = new Date(opts.startTime.getTime() + 2 * 60 * 60 * 1000); // +2h
  const { data: event, error: eventErr } = await db
    .from("events")
    .insert({
      party_id: partyId,
      start_time: opts.startTime.toISOString(),
      end_time: endTime.toISOString(),
      title: "Test Event",
    })
    .select("id")
    .single();
  if (eventErr || !event) throw new Error(`seedPartnerEvent event: ${eventErr?.message}`);
  const eventId = event.id as string;

  // 4. Ticket template + ticket
  const { data: tmpl, error: tmplErr } = await db
    .from("ticket_templates")
    .insert({ party_id: partyId, name: "General", price: opts.paymentAmount })
    .select("id")
    .single();
  if (tmplErr || !tmpl) throw new Error(`seedPartnerEvent ticket_template: ${tmplErr?.message}`);

  const { data: ticket, error: ticketErr } = await db
    .from("tickets")
    .insert({
      event_id: eventId,
      template_id: (tmpl as { id: string }).id,
      name: "General",
      price: opts.paymentAmount,
      quantity: 10,
    })
    .select("id")
    .single();
  if (ticketErr || !ticket) throw new Error(`seedPartnerEvent ticket: ${ticketErr?.message}`);

  return { partnerId, partyId, eventId, ticketId: (ticket as { id: string }).id };
}

/** paid event_applications row 를 INSERT (RLS 우회).
 *  payment_id 는 dev-mock-portone 이 인식하는 임의 값으로 설정.
 */
async function seedPaidApplication(
  db: Ctx["db"],
  opts: {
    userId: string;
    eventId: string;
    ticketId: string;
    paymentAmount: number;
    paidAt: Date;
  },
): Promise<string> {
  const paymentId = `imp_test_${Date.now()}_${Math.floor(Math.random() * 1000)}`;
  const { data: app, error } = await db
    .from("event_applications")
    .insert({
      event_id: opts.eventId,
      ticket_id: opts.ticketId,
      user_id: opts.userId,
      status: "paid",
      payment_id: paymentId,
      payment_amount: opts.paymentAmount,
      refund_status: "none",
      paid_at: opts.paidAt.toISOString(),
    })
    .select("id")
    .single();
  if (error || !app) throw new Error(`seedPaidApplication: ${error?.message}`);
  return (app as { id: string }).id;
}

/** refund policy 를 DB 에 upsert (grace_period_hours, cutoff_days 커스텀) */
async function seedRefundPolicy(
  db: Ctx["db"],
  gracePeriodHours: number,
  cutoffDays: number,
): Promise<void> {
  const { error } = await db
    .from("policies")
    .upsert(
      {
        key: "refund",
        value: { grace_period_hours: gracePeriodHours, cutoff_days: cutoffDays },
        version: 99,
        effective_date: new Date(Date.now() - 1000).toISOString(), // 방금 전 effective
        description: "integration-test override",
      },
      { onConflict: "key,effective_date" },
    );
  if (error) throw new Error(`seedRefundPolicy: ${error.message}`);
}

// ─── CUJ 1-1: grace period(3시간) 내 자동 환불 ────────────────────────────────

cujTest(
  ctx,
  "1-1 grace period 내 paid 신청 → user-cancel-order 자동 환불 성공",
  "fresh",
  async (ctx) => {
    // Seed: user + event (시작 30일 후) + paid application (지금 막 결제)
    const userId = await seedUser(ctx.db, "refund_user_11@example.test", "refund_user_11");
    const now = new Date();
    const startFuture = new Date(now.getTime() + 30 * 24 * 60 * 60 * 1000); // 30일 후

    const { eventId, ticketId } = await seedPartnerEvent(ctx.db, {
      startTime: startFuture,
      paymentAmount: 15000,
    });

    // gracePeriodHours=3, cutoffDays=7 — 표준 정책
    await seedRefundPolicy(ctx.db, 3, 7);

    // 2분 전 결제 (grace period 안)
    const paidAt = new Date(now.getTime() - 2 * 60 * 1000);
    const appId = await seedPaidApplication(ctx.db, {
      userId,
      eventId,
      ticketId,
      paymentAmount: 15000,
      paidAt,
    });

    // EF 호출
    const user = await ctx.actAs.user(userId);
    const res = await user.invoke("user-cancel-order", { event_id: eventId });

    // Assert: EF 200 + type=refunded
    assertEquals(
      res.status,
      200,
      `expected 200 but got ${res.status}: ${JSON.stringify(res.data)}`,
    );
    const data = res.data as { success?: boolean; type?: string };
    assertEquals(data.success, true, "success must be true");
    assertEquals(data.type, "refunded", "type must be 'refunded'");

    // Assert: DB row 검증 — status=cancelled, refund_status=completed
    const { data: app } = await ctx.db
      .from("event_applications")
      .select("status, refund_status, refunded_at, cancellation_reason")
      .eq("id", appId)
      .single();
    const row = app as {
      status: string;
      refund_status: string;
      refunded_at: string | null;
      cancellation_reason: string | null;
    };
    assertEquals(row.status, "cancelled", "application status must be cancelled");
    assertEquals(row.refund_status, "completed", "refund_status must be completed");
    assert(row.refunded_at !== null, "refunded_at must be set");
    assertEquals(row.cancellation_reason, "user_requested", "cancellation_reason must be user_requested");
  },
);

// ─── CUJ 2-1: cutoff(7일) 전 자동 환불 ───────────────────────────────────────

cujTest(
  ctx,
  "2-1 cutoff 전 (grace 초과 + cutoff 내) paid 신청 → user-cancel-order 자동 환불 성공",
  "fresh",
  async (ctx) => {
    // 시나리오: grace period 경과(4시간 전 결제) + 이벤트는 10일 후 (cutoff 7일 내)
    const userId = await seedUser(ctx.db, "refund_user_21@example.test", "refund_user_21");
    const now = new Date();
    const startFuture = new Date(now.getTime() + 10 * 24 * 60 * 60 * 1000); // 10일 후

    const { eventId, ticketId } = await seedPartnerEvent(ctx.db, {
      startTime: startFuture,
      paymentAmount: 30000,
    });
    await seedRefundPolicy(ctx.db, 3, 7);

    // 4시간 전 결제 — grace period(3h) 초과, but cutoff(7일) 안
    const paidAt = new Date(now.getTime() - 4 * 60 * 60 * 1000);
    const appId = await seedPaidApplication(ctx.db, {
      userId,
      eventId,
      ticketId,
      paymentAmount: 30000,
      paidAt,
    });

    const user = await ctx.actAs.user(userId);
    const res = await user.invoke("user-cancel-order", { event_id: eventId });

    assertEquals(
      res.status,
      200,
      `expected 200 but got ${res.status}: ${JSON.stringify(res.data)}`,
    );
    const data = res.data as { success?: boolean; type?: string };
    assertEquals(data.success, true);
    assertEquals(data.type, "refunded");

    // DB 검증
    const { data: app } = await ctx.db
      .from("event_applications")
      .select("status, refund_status, refunded_at")
      .eq("id", appId)
      .single();
    const row = app as { status: string; refund_status: string; refunded_at: string | null };
    assertEquals(row.status, "cancelled");
    assertEquals(row.refund_status, "completed");
    assert(row.refunded_at !== null, "refunded_at must be set");
  },
);

// ─── CUJ 2-1 edge: grace+cutoff 모두 초과 → 자동 환불 거부 ───────────────────

cujTest(
  ctx,
  "2-1-edge grace+cutoff 모두 초과 → user-cancel-order 400 refund_not_eligible",
  "fresh",
  async (ctx) => {
    // 이벤트 시작 5일 전 + 결제 후 4시간 경과 → 자동 환불 불가 (cutoff 7일 초과)
    const userId = await seedUser(ctx.db, "refund_user_21e@example.test", "refund_user_21e");
    const now = new Date();
    const startFuture = new Date(now.getTime() + 5 * 24 * 60 * 60 * 1000); // 5일 후

    const { eventId, ticketId } = await seedPartnerEvent(ctx.db, {
      startTime: startFuture,
      paymentAmount: 30000,
    });
    await seedRefundPolicy(ctx.db, 3, 7);

    // 4시간 전 결제 — grace(3h) 초과, cutoff(5일 < 7일) 초과
    const paidAt = new Date(now.getTime() - 4 * 60 * 60 * 1000);
    await seedPaidApplication(ctx.db, {
      userId,
      eventId,
      ticketId,
      paymentAmount: 30000,
      paidAt,
    });

    const user = await ctx.actAs.user(userId);
    const res = await user.invoke("user-cancel-order", { event_id: eventId });

    assertEquals(
      res.status,
      400,
      `expected 400 but got ${res.status}: ${JSON.stringify(res.data)}`,
    );
    const data = res.data as Record<string, unknown>;
    // EF는 "refund_not_eligible" 메시지를 반환
    const strData = JSON.stringify(data);
    assertMatch(strData, /refund_not_eligible|Refund window has expired/i);
  },
);

// ─── CUJ 3-2: 파트너에게 환불 요청 전송 ────────────────────────────────────────
//
// TODO: EF 'user-request-refund' 또는 동등한 EF 가 존재하지 않음.
// user-cancel-order 는 자동 환불 가능 경로만 처리; 자동 환불 불가 시
// "refund_not_eligible" 을 반환하고 파트너 환불 요청 저장 로직이 없다.
//
// 이 CUJ 가 EF 수준에서 검증 가능하려면:
//   1. user-cancel-order 에 partner-refund-request 저장 분기 추가, 또는
//   2. 전용 EF (예: user-request-refund) 신규 생성 필요.
//
// 현재는 refund_not_eligible 응답 + DB 미변경을 중간 검증으로 대체한다.

cujTest(
  ctx,
  "3-2 자동 환불 불가 상태에서 user-cancel-order 호출 → 400 + refund_not_eligible (환불 요청 EF 미구현 중간 검증)",
  "fresh",
  async (ctx) => {
    // grace+cutoff 모두 초과한 상황 (이벤트 3일 후, 결제 5시간 전)
    const userId = await seedUser(ctx.db, "refund_user_32@example.test", "refund_user_32");
    const now = new Date();
    const startFuture = new Date(now.getTime() + 3 * 24 * 60 * 60 * 1000); // 3일 후

    const { eventId, ticketId } = await seedPartnerEvent(ctx.db, {
      startTime: startFuture,
      paymentAmount: 20000,
    });
    await seedRefundPolicy(ctx.db, 3, 7);

    const paidAt = new Date(now.getTime() - 5 * 60 * 60 * 1000); // 5시간 전
    const appId = await seedPaidApplication(ctx.db, {
      userId,
      eventId,
      ticketId,
      paymentAmount: 20000,
      paidAt,
    });

    const user = await ctx.actAs.user(userId);
    const res = await user.invoke("user-cancel-order", { event_id: eventId });

    // EF 는 파트너 환불 요청 저장 로직이 없으므로 400 반환
    assertEquals(
      res.status,
      400,
      `expected 400 (no partner-refund EF) but got ${res.status}: ${JSON.stringify(res.data)}`,
    );

    // DB 미변경 확인 — status, refund_status 는 원래대로
    const { data: app } = await ctx.db
      .from("event_applications")
      .select("status, refund_status")
      .eq("id", appId)
      .single();
    const row = app as { status: string; refund_status: string };
    assertEquals(row.status, "paid", "status must remain paid (no partner refund EF)");
    assertEquals(row.refund_status, "none", "refund_status must remain none");
  },
);

// ─── CUJ 3-2-duplicate: 동일 신청 중복 환불 요청 거부 ────────────────────────
//
// spec edge case: "동일 신청에 대한 중복 요청은 거부" (FR-6)
// user-cancel-order 는 refund_status !== 'none' 시 이미 "already_refunded" 로 거부한다.
// 이 테스트는 해당 guard 를 검증한다.

cujTest(
  ctx,
  "3-2-dup 이미 completed 환불 신청에 재취소 시도 → 400 already_refunded",
  "fresh",
  async (ctx) => {
    const userId = await seedUser(ctx.db, "refund_user_32d@example.test", "refund_user_32d");
    const now = new Date();
    const startFuture = new Date(now.getTime() + 30 * 24 * 60 * 60 * 1000);

    const { eventId, ticketId } = await seedPartnerEvent(ctx.db, {
      startTime: startFuture,
      paymentAmount: 15000,
    });
    await seedRefundPolicy(ctx.db, 3, 7);

    // refund_status = 'completed' 로 직접 삽입 (이미 환불 처리됨)
    await ctx.db.from("event_applications").insert({
      event_id: eventId,
      ticket_id: ticketId,
      user_id: userId,
      status: "cancelled",
      payment_id: `imp_already_refunded_${Date.now()}`,
      payment_amount: 15000,
      refund_status: "completed",
      refund_amount: 15000,
      paid_at: new Date(now.getTime() - 60 * 1000).toISOString(),
    });

    const user = await ctx.actAs.user(userId);
    const res = await user.invoke("user-cancel-order", { event_id: eventId });

    // 이미 취소됨 → 400
    assertEquals(
      res.status,
      400,
      `expected 400 but got ${res.status}: ${JSON.stringify(res.data)}`,
    );
    const strData = JSON.stringify(res.data);
    assertMatch(strData, /already_refunded|already_cancelled|already|취소/i);
  },
);

// ─── CUJ 5-2: 무료 이벤트 취소 ──────────────────────────────────────────────

cujTest(
  ctx,
  "5-2 무료 이벤트(payment_amount=0) 취소 → PortOne 호출 없이 상태만 cancelled",
  "fresh",
  async (ctx) => {
    const userId = await seedUser(ctx.db, "refund_user_52@example.test", "refund_user_52");
    const now = new Date();
    const startFuture = new Date(now.getTime() + 10 * 24 * 60 * 60 * 1000);

    // 무료 이벤트: paymentAmount=0
    const { eventId, ticketId } = await seedPartnerEvent(ctx.db, {
      startTime: startFuture,
      paymentAmount: 0,
    });

    // paid application with amount=0 (무료이지만 status=paid 로 처리된 케이스)
    await ctx.db.from("event_applications").insert({
      event_id: eventId,
      ticket_id: ticketId,
      user_id: userId,
      status: "paid",
      payment_id: null, // 무료 — payment_id 없음
      payment_amount: 0,
      refund_status: "none",
      paid_at: new Date(now.getTime() - 60 * 1000).toISOString(),
    });

    const user = await ctx.actAs.user(userId);
    const res = await user.invoke("user-cancel-order", { event_id: eventId });

    // 무료 이벤트는 PortOne 호출 없이 200 + type=cancelled 반환
    assertEquals(
      res.status,
      200,
      `expected 200 but got ${res.status}: ${JSON.stringify(res.data)}`,
    );
    const data = res.data as { success?: boolean; type?: string };
    assertEquals(data.success, true);
    assertEquals(data.type, "cancelled", "free event cancel type must be 'cancelled' (not 'refunded')");

    // DB 검증 — status=cancelled, refund_status 는 변경 안 됨
    const { data: app } = await ctx.db
      .from("event_applications")
      .select("status, refund_status")
      .eq("event_id", eventId)
      .eq("user_id", userId)
      .single();
    const row = app as { status: string; refund_status: string };
    assertEquals(row.status, "cancelled", "application status must be cancelled");
    // 무료 취소는 refund_status 를 건드리지 않는다
    assertEquals(row.refund_status, "none", "free cancel should not change refund_status");
  },
);

// ─── CUJ 5-2 guard: 이벤트 시작 후 취소 → 거부 ─────────────────────────────

cujTest(
  ctx,
  "5-2-guard 이벤트 시작 후 무료 취소 시도 → 400 (event already started)",
  "fresh",
  async (ctx) => {
    const userId = await seedUser(ctx.db, "refund_user_52g@example.test", "refund_user_52g");
    const now = new Date();

    // 이미 시작된 이벤트 (1시간 전 시작, 2시간 후 종료)
    const startPast = new Date(now.getTime() - 1 * 60 * 60 * 1000);
    const { eventId, ticketId } = await seedPartnerEvent(ctx.db, {
      startTime: startPast,
      paymentAmount: 0,
    });

    await ctx.db.from("event_applications").insert({
      event_id: eventId,
      ticket_id: ticketId,
      user_id: userId,
      status: "paid",
      payment_id: null,
      payment_amount: 0,
      refund_status: "none",
      paid_at: new Date(now.getTime() - 2 * 60 * 60 * 1000).toISOString(),
    });

    const user = await ctx.actAs.user(userId);
    const res = await user.invoke("user-cancel-order", { event_id: eventId });

    // 이벤트 시작 후 취소 불가 → 400
    assertEquals(
      res.status,
      400,
      `expected 400 (event started) but got ${res.status}: ${JSON.stringify(res.data)}`,
    );
  },
);
