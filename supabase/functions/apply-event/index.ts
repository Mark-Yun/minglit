import { createServiceClient } from "../_shared/supabase_client.ts";
import { successResponse, errorResponse, corsResponse } from "../_shared/response_utils.ts";
import { requireAuth } from "../_shared/auth_utils.ts";
import { initSentry, withHandler } from "../_shared/logger.ts";

initSentry();

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
      verification_data?: Record<string, unknown>;
    };

    if (!event_id || !ticket_id) {
      return errorResponse("Missing required parameters: event_id, ticket_id", 400);
    }

    const supabase = createServiceClient();

    // 1. 이벤트 + 티켓 정보 조회
    const { data: event, error: eventError } = await supabase
      .from("events")
      .select("id, status, current_participants, max_participants")
      .eq("id", event_id)
      .single();

    if (eventError || !event) {
      return errorResponse("Event not found", 404);
    }

    // 2. 이벤트 상태 확인 — scheduled 상태여야 신청 가능
    if (event.status !== "scheduled") {
      return errorResponse("Event is not accepting applications", 409, { status: event.status });
    }

    // 3. capacity guard — current_participants >= max_participants
    if (event.current_participants >= event.max_participants) {
      return errorResponse("Event is at full capacity", 409, {
        current: event.current_participants,
        max: event.max_participants,
      });
    }

    // 4. 티켓 정보 조회
    const { data: ticket, error: ticketError } = await supabase
      .from("tickets")
      .select("id, price, quantity, sold_count, status, required_verification_ids, event_id")
      .eq("id", ticket_id)
      .single();

    if (ticketError || !ticket) {
      return errorResponse("Ticket not found", 404);
    }

    // 티켓이 해당 이벤트 소속인지 확인
    if (ticket.event_id !== event_id) {
      return errorResponse("Ticket does not belong to this event", 400);
    }

    // 티켓 판매 상태 확인
    if (ticket.status !== "on_sale") {
      return errorResponse("Ticket is not available", 409, { ticket_status: ticket.status });
    }

    // 티켓 capacity guard — sold_count >= quantity
    if (ticket.sold_count >= ticket.quantity) {
      return errorResponse("Ticket is sold out", 409);
    }

    // 5. 중복 신청 확인 — cancelled/payment_failed 상태는 재신청 허용
    const { data: existingApp } = await supabase
      .from("event_applications")
      .select("id, status")
      .eq("event_id", event_id)
      .eq("user_id", userId)
      .maybeSingle();

    if (existingApp && existingApp.status !== "cancelled" && existingApp.status !== "payment_failed") {
      return errorResponse("Already applied to this event", 409);
    }

    // 6. eligibility 체크 — 티켓에 required_verification_ids가 있는 경우 확인
    const requiredVerificationIds: string[] = ticket.required_verification_ids ?? [];
    if (requiredVerificationIds.length > 0) {
      const { data: verifications } = await supabase
        .from("user_verifications")
        .select("verification_id")
        .eq("user_id", userId)
        .in("verification_id", requiredVerificationIds);

      const verifiedIds = new Set((verifications ?? []).map((v: { verification_id: string }) => v.verification_id));
      const missingIds = requiredVerificationIds.filter((id) => !verifiedIds.has(id));

      if (missingIds.length > 0) {
        return errorResponse("Eligibility requirements not met", 403, { missing_verification_ids: missingIds });
      }
    }

    // 7. 가격 기반 분기
    const price: number = ticket.price ?? 0;

    if (price > 0) {
      // 유료: payment_pending 상태로 신청 레코드 생성 후 주문 정보 반환
      // UUID를 미리 생성하여 INSERT 후 ID를 별도 조회 없이 사용
      const applicationId = crypto.randomUUID();

      const { error: insertError } = await supabase
        .from("event_applications")
        .insert({
          id: applicationId,
          event_id,
          ticket_id,
          user_id: userId,
          status: "payment_pending",
          payment_amount: price,
        });

      if (insertError) {
        console.error("Failed to create paid application:", insertError.message);
        // unique constraint violation (23505) → race condition으로 중복 신청 발생
        if (insertError.code === "23505") {
          return errorResponse("Already applied to this event", 409);
        }
        return errorResponse("Failed to create application", 500);
      }

      return successResponse({
        type: "paid",
        application_id: applicationId,
        order_id: applicationId,
        payment_amount: price,
      });
    } else {
      // 무료: apply_event RPC 호출 — DB 레벨 balance 체크 + 신청 완료
      const { data: applicationId, error: rpcError } = await supabase.rpc("apply_event", {
        p_event_id: event_id,
        p_ticket_id: ticket_id,
        p_user_id: userId,
        p_payment_id: null,
        p_payment_amount: 0,
        p_verification_data: verification_data ?? null,
      });

      if (rpcError) {
        console.error("apply_event RPC error:", rpcError.message);
        // errcode P0001 → 성비 균형 제한
        if (rpcError.code === "P0001") {
          return errorResponse(rpcError.message, 409);
        }
        // unique constraint violation (23505) → 중복 신청 (race condition 방어)
        if (rpcError.code === "23505") {
          return errorResponse("Already applied to this event", 409);
        }
        return errorResponse("Failed to apply to event", 500);
      }

      return successResponse({
        type: "free",
        application_id: applicationId,
      });
    }
  } catch (e) {
    const message = e instanceof Error ? e.message : String(e);
    console.error("Error in apply-event:", message);
    return errorResponse(message, 500);
  }
}));
