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
      // Fix #1492: 유료 경로 성별 균형 검증 누락 — 무료 경로와 동일하게 check_party_balance 추가
      const { data: balanceResult, error: balanceError } = await supabase.rpc("check_party_balance", {
        p_event_id: event_id,
        p_ticket_id: ticket_id,
      });
      if (balanceError) {
        console.error("check_party_balance error on paid application:", balanceError.message);
        return errorResponse("Failed to check balance", 500);
      }
      const balance = balanceResult as { allowed: boolean; reason: string | null } | null;
      if (!balance?.allowed) {
        return errorResponse(balance?.reason ?? "성비 균형 제한", 409);
      }

      let applicationId: string;

      if (existingApp) {
        // Fix #1342 Bug1: 취소/결제실패 후 재신청 — unique constraint 충돌 방지를 위해 INSERT 대신 UPDATE
        applicationId = existingApp.id;
        const { error: updateError } = await supabase
          .from("event_applications")
          .update({
            ticket_id,
            status: "payment_pending",
            payment_amount: price,
            payment_id: null,
            rejection_reason: null,
          })
          .eq("id", existingApp.id);

        if (updateError) {
          console.error("Failed to update paid application for re-application:", updateError.message);
          return errorResponse("Failed to create application", 500);
        }
      } else {
        // UUID를 미리 생성하여 INSERT 후 ID를 별도 조회 없이 사용
        applicationId = crypto.randomUUID();

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
      }

      // Fix #1342 Bug2: 유료 경로에서 verification_data 처리 — RPC 미사용으로 인해 직접 삽입
      if (verification_data) {
        const verificationId = verification_data["verification_id"] as string | undefined;
        const partnerId = verification_data["partner_id"] as string | undefined;
        const data = verification_data["data"] ?? {};

        if (verificationId && partnerId) {
          const { error: uvError } = await supabase
            .from("user_verifications")
            .upsert(
              { user_id: userId, verification_id: verificationId, data },
              { onConflict: "user_id,verification_id" },
            );

          if (uvError) {
            console.error("Failed to upsert user_verifications:", uvError.message);
            return errorResponse("Failed to process verification data", 500);
          }

          const { error: vsError } = await supabase
            .from("verification_submissions")
            .insert({
              partner_id: partnerId,
              user_id: userId,
              verification_id: verificationId,
              application_id: applicationId,
              status: "pending",
              snapshot_data: data,
            });

          if (vsError) {
            console.error("Failed to insert verification_submissions:", vsError.message);
            return errorResponse("Failed to process verification data", 500);
          }
        }
      }

      return successResponse({
        type: "paid",
        application_id: applicationId,
        order_id: applicationId,
        payment_amount: price,
      });
    } else {
      // 무료 경로
      if (existingApp) {
        // Fix #1342 Bug1: 취소/결제실패 후 재신청 — apply_event RPC는 plain INSERT이므로 직접 UPDATE
        // Fix #1345: apply_event RPC 미사용으로 인해 check_party_balance 누락 — 명시적 호출
        const { data: balanceResult, error: balanceError } = await supabase.rpc("check_party_balance", {
          p_event_id: event_id,
          p_ticket_id: ticket_id,
        });
        if (balanceError) {
          console.error("check_party_balance error on free re-application:", balanceError.message);
          return errorResponse("Failed to check balance", 500);
        }
        const balance = balanceResult as { allowed: boolean; reason: string | null } | null;
        if (!balance?.allowed) {
          return errorResponse(balance?.reason ?? "성비 균형 제한", 409);
        }

        // Fix #1660: free re-applications use 'approved' (not 'paid') — payment_id is null for free events
        const newStatus = verification_data ? "pending_review" : "approved";
        const { error: updateError } = await supabase
          .from("event_applications")
          .update({
            ticket_id,
            status: newStatus,
            payment_id: null,
            payment_amount: 0,
            rejection_reason: null,
          })
          .eq("id", existingApp.id);

        if (updateError) {
          console.error("Failed to update free application for re-application:", updateError.message);
          return errorResponse("Failed to apply to event", 500);
        }

        // Fix #1342 Bug2: 무료 재신청 경로에서 verification_data 처리
        if (verification_data) {
          const verificationId = verification_data["verification_id"] as string | undefined;
          const partnerId = verification_data["partner_id"] as string | undefined;
          const data = verification_data["data"] ?? {};

          if (verificationId && partnerId) {
            const { error: uvError } = await supabase
              .from("user_verifications")
              .upsert(
                { user_id: userId, verification_id: verificationId, data },
                { onConflict: "user_id,verification_id" },
              );

            if (uvError) {
              console.error("Failed to upsert user_verifications:", uvError.message);
              return errorResponse("Failed to process verification data", 500);
            }

            const { error: vsError } = await supabase
              .from("verification_submissions")
              .insert({
                partner_id: partnerId,
                user_id: userId,
                verification_id: verificationId,
                application_id: existingApp.id,
                status: "pending",
                snapshot_data: data,
              });

            if (vsError) {
              console.error("Failed to insert verification_submissions:", vsError.message);
              return errorResponse("Failed to process verification data", 500);
            }
          }
        }

        return successResponse({
          type: "free",
          application_id: existingApp.id,
        });
      }

      // 신규 무료 신청: apply_event RPC 호출 — DB 레벨 balance 체크 + 신청 완료
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
