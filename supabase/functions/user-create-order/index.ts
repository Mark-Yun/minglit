import { createClient } from "@supabase/supabase-js";
import { successResponse, errorResponse, corsResponse } from "../_shared/response_utils.ts";
import { requireAuth } from "../_shared/auth_utils.ts";
import { initSentry, withHandler, withSpan, log } from "../_shared/logger.ts";
import { initStatsig, logStatsigEvent } from "../_shared/statsig_utils.ts";

const FN = "user-create-order";

initSentry();
initStatsig();

Deno.serve(withHandler(async (req) => {
  if (req.method === "OPTIONS") return corsResponse();

  const auth = await requireAuth(req);
  if (auth instanceof Response) return auth;
  const userId = auth;

  try {
    let reqBody: Record<string, unknown>;
    try {
      reqBody = await req.json();
    } catch {
      return errorResponse("Invalid JSON body", 400);
    }

    const { event_id, ticket_id, verification_data } = reqBody as {
      event_id?: string;
      ticket_id?: string;
      verification_data?: { verification_id: string; data: Record<string, unknown> };
    };

    // 1. Input validation
    if (!event_id) return errorResponse("Missing required field: event_id", 400);
    if (!ticket_id) return errorResponse("Missing required field: ticket_id", 400);

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
    );

    // 2. Fetch event
    const { data: event, error: eventError } = await withSpan(
      "db.query.events", "db.query",
      () => supabase
        .from("events")
        .select("id, party_id, status, start_time, max_participants, current_participants")
        .eq("id", event_id)
        .single(),
    );

    if (eventError || !event) {
      return errorResponse("이벤트를 찾을 수 없습니다.", 404);
    }

    if (event.status !== "scheduled") {
      return errorResponse("이벤트가 마감되었습니다.", 400, { code: "EVENT_NOT_SCHEDULED" });
    }

    if (new Date(event.start_time) <= new Date()) {
      return errorResponse("이벤트가 마감되었습니다.", 400, { code: "EVENT_NOT_SCHEDULED" });
    }

    // 3. Fetch ticket and verify it belongs to the event
    const { data: ticket, error: ticketError } = await withSpan(
      "db.query.tickets", "db.query",
      () => supabase
        .from("tickets")
        .select("id, event_id, name, price, quantity, sold_count, target_entry_group_ids")
        .eq("id", ticket_id)
        .single(),
    );

    if (ticketError || !ticket) {
      return errorResponse("티켓을 찾을 수 없습니다.", 404);
    }

    if (ticket.event_id !== event_id) {
      return errorResponse("티켓을 찾을 수 없습니다.", 404);
    }

    // 4. Check ticket availability
    if (ticket.sold_count >= ticket.quantity) {
      return errorResponse("티켓이 매진되었습니다.", 400, { code: "TICKET_SOLD_OUT" });
    }

    // 5. Check event capacity
    if (event.current_participants >= event.max_participants) {
      return errorResponse("정원이 초과되었습니다.", 400, { code: "EVENT_FULL" });
    }

    // 6. Fetch user profile
    const { data: userProfile, error: profileError } = await withSpan(
      "db.query.user_profiles", "db.query",
      () => supabase
        .from("user_profiles")
        .select("id, is_verified, gender, birth_date")
        .eq("id", userId)
        .single(),
    );

    if (profileError || !userProfile) {
      return errorResponse("사용자 프로필을 찾을 수 없습니다.", 404);
    }

    // 7. Check identity verification
    if (!userProfile.is_verified) {
      return errorResponse("본인인증이 필요합니다.", 400, { code: "IDENTITY_REQUIRED" });
    }

    // 8. Check entry group eligibility (gender/age)
    const targetGroupIds: string[] = ticket.target_entry_group_ids ?? [];
    if (targetGroupIds.length > 0) {
      const { data: entryGroups } = await withSpan(
        "db.query.entry_groups", "db.query",
        () => supabase
          .from("entry_groups")
          .select("id, gender, birth_year_min, birth_year_max, required_verification_ids")
          .eq("event_id", event_id)
          .in("id", targetGroupIds),
      );

      if (entryGroups && entryGroups.length > 0) {
        const group = entryGroups[0];

        // Gender check
        if (group.gender && userProfile.gender && group.gender !== userProfile.gender) {
          return errorResponse("성별 조건이 맞지 않습니다.", 400, { code: "GENDER_MISMATCH" });
        }

        // Age check
        if (userProfile.birth_date) {
          const birthYear = new Date(userProfile.birth_date).getFullYear();
          if (group.birth_year_min && birthYear < group.birth_year_min) {
            return errorResponse("나이 조건이 맞지 않습니다.", 400, { code: "AGE_MISMATCH" });
          }
          if (group.birth_year_max && birthYear > group.birth_year_max) {
            return errorResponse("나이 조건이 맞지 않습니다.", 400, { code: "AGE_MISMATCH" });
          }
        }

        // Required verification check
        const requiredIds: string[] = entryGroups
          .flatMap((g: { required_verification_ids?: string[] }) => g.required_verification_ids ?? []);
        if (requiredIds.length > 0 && !verification_data) {
          return errorResponse("자격 인증 정보가 필요합니다.", 400, { code: "VERIFICATION_REQUIRED" });
        }
      }
    }

    // 9. Check party balance (gender balance)
    const { data: balanceResult, error: balanceError } = await withSpan(
      "db.rpc.check_party_balance", "db.rpc",
      () => supabase.rpc("check_party_balance", {
        p_event_id: event_id,
        p_ticket_id: ticket_id,
      }),
    );

    if (balanceError) {
      log({ function: FN, level: "error", message: "check_party_balance error", metadata: { detail: balanceError } });
    }

    if (balanceResult && balanceResult.allowed === false) {
      return errorResponse("성비 균형 제한입니다.", 400, { code: "BALANCE_LIMIT" });
    }

    // 10. Check duplicate application
    const { data: existingApp } = await withSpan(
      "db.query.existing_application", "db.query",
      () => supabase
        .from("event_applications")
        .select("id, status")
        .eq("event_id", event_id)
        .eq("user_id", userId)
        .single(),
    );

    if (existingApp && existingApp.status !== "cancelled" && existingApp.status !== "payment_failed") {
      return errorResponse("이미 신청한 이벤트입니다.", 400, { code: "ALREADY_APPLIED" });
    }

    // 11. Determine status based on price
    const amount = ticket.price;
    const requiresPayment = amount > 0;
    const pendingPaymentId = `PENDING_${Date.now()}`;
    const initialStatus = requiresPayment ? "pending" : "paid";

    // 12. Create or update application via apply_event RPC
    const { data: appId, error: applyError } = await withSpan(
      "db.rpc.apply_event", "db.rpc",
      () => supabase.rpc("apply_event", {
        p_event_id: event_id,
        p_ticket_id: ticket_id,
        p_user_id: userId,
        p_payment_id: pendingPaymentId,
        p_payment_amount: amount,
        p_verification_data: verification_data ?? null,
      }),
    );

    if (applyError) {
      log({ function: FN, level: "error", message: "apply_event error", metadata: { detail: applyError } });
      return errorResponse("주문 생성 중 오류가 발생했습니다.", 500);
    }

    // If existing cancelled/failed app was reused, update it
    if (existingApp) {
      await withSpan(
        "db.update.event_applications", "db.update",
        () => supabase
          .from("event_applications")
          .update({
            status: initialStatus,
            payment_id: pendingPaymentId,
            ticket_id: ticket_id,
            payment_amount: amount,
            updated_at: new Date().toISOString(),
          })
          .eq("id", appId),
      );
    } else {
      // Set status to pending (for paid) or paid (for free)
      await withSpan(
        "db.update.event_applications.status", "db.update",
        () => supabase
          .from("event_applications")
          .update({
            status: initialStatus,
            payment_id: pendingPaymentId,
            payment_amount: amount,
            updated_at: new Date().toISOString(),
          })
          .eq("id", appId),
      );
    }

    logStatsigEvent(userId, "order_created", amount, {
      event_id,
      ticket_id,
      requires_payment: String(requiresPayment),
    }).catch(() => {});

    return successResponse({
      success: true,
      application_id: appId,
      amount,
      requires_payment: requiresPayment,
      ticket_name: ticket.name,
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    log({ function: FN, level: "error", message: "Error in user-create-order", metadata: { detail: message } });
    return errorResponse("주문 생성 중 오류가 발생했습니다.", 500);
  }
}));
