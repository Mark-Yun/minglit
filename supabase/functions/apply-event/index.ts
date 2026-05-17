// Fix #2185 (Batch 5): migrate to minglitEdgeFunction wrapper — auth via manifest (user caller)
import {
  errorResponse,
  successResponse,
} from "../_shared/response_utils.ts";
import { minglitEdgeFunction, type EFContext } from "../_shared/edge_function.ts";
import { parseJsonBody } from "../_shared/request_utils.ts";
import {
  isEventFull,
  isTicketSoldOut,
} from "../_shared/domains/event/availability.ts";

type VerifItem = { verification_id: string; data: Record<string, unknown> };

/** Parses the client-sent verification_data into a flat list of VerifItem.
 *  Accepts new array format { partner_id, verifications: [...] }
 *  and legacy single format { partner_id, verification_id, data }.
 */
function parseVerifications(
  verification_data: Record<string, unknown> | undefined,
): { partnerId: string | undefined; items: VerifItem[] } {
  if (!verification_data) return { partnerId: undefined, items: [] };

  const partnerId = verification_data["partner_id"] as string | undefined;

  if (Array.isArray(verification_data["verifications"])) {
    // Fix #2107: runtime-validate each entry instead of casting — items with
    // non-string verification_id or non-object data are silently dropped.
    const raw = verification_data["verifications"] as unknown[];
    return {
      partnerId,
      items: raw.flatMap((v) => {
        if (
          v &&
          typeof v === "object" &&
          typeof (v as { verification_id?: unknown }).verification_id === "string"
        ) {
          const item = v as { verification_id: string; data?: unknown };
          const data =
            item.data &&
            typeof item.data === "object" &&
            !Array.isArray(item.data)
              ? (item.data as Record<string, unknown>)
              : {};
          return [{ verification_id: item.verification_id, data }];
        }
        return [];
      }),
    };
  }

  // Legacy single-item format
  const verificationId = verification_data["verification_id"] as
    | string
    | undefined;
  const data = (verification_data["data"] ?? {}) as Record<string, unknown>;
  if (verificationId) {
    return { partnerId, items: [{ verification_id: verificationId, data }] };
  }

  return { partnerId, items: [] };
}

type SupabaseClient = EFContext["supabase"];

/** Upserts all verifications and inserts submission records.
 *  Returns an error Response on first failure, null on success.
 */
async function upsertVerifications(
  supabase: SupabaseClient,
  userId: string,
  applicationId: string,
  partnerId: string | undefined,
  items: VerifItem[],
): Promise<Response | null> {
  // Fix #2107: reject up-front if items were sent without a partnerId — silent
  // skip would make the caller treat the request as success with no rows saved.
  if (items.length > 0 && !partnerId) {
    console.error("upsertVerifications: items provided without partnerId");
    return errorResponse("Invalid verification payload: missing partner_id", 400);
  }
  for (const item of items) {
    if (!item.verification_id || !partnerId) continue;

    const { error: uvError } = await supabase
      .from("user_verifications")
      .upsert(
        {
          user_id: userId,
          verification_id: item.verification_id,
          data: item.data,
        },
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
        verification_id: item.verification_id,
        application_id: applicationId,
        status: "pending",
        snapshot_data: item.data,
      });
    if (vsError) {
      console.error(
        "Failed to insert verification_submissions:",
        vsError.message,
      );
      return errorResponse("Failed to process verification data", 500);
    }
  }
  return null;
}

export const handler = async (req: Request, ctx: EFContext): Promise<Response> => {
  if (ctx.auth.type !== "user") return errorResponse("Unexpected auth type", 500);
  const userId = ctx.auth.userId;
  const { supabase } = ctx;

  try {
    const body = await parseJsonBody(req);
    if (body instanceof Response) return body;

    const { event_id, ticket_id, verification_data } = body as {
      event_id?: string;
      ticket_id?: string;
      verification_data?: Record<string, unknown>;
    };

    const { partnerId: verifPartnerId, items: verifItems } =
      parseVerifications(verification_data);

    if (!event_id || !ticket_id) {
      return errorResponse(
        "Missing required parameters: event_id, ticket_id",
        400,
      );
    }

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
    // NOTE: user-create-order 는 scheduled OR active 허용 (Fix #998). 이 EF 는 scheduled only —
    // 정합성 이슈 → `_shared/domains/event/BLUEDOC.md` 의 "알려진 정합성 이슈" 참조.
    if (event.status !== "scheduled") {
      return errorResponse("Event is not accepting applications", 409, {
        status: event.status,
      });
    }

    // 3. capacity guard
    if (isEventFull(event.current_participants, event.max_participants)) {
      return errorResponse("Event is at full capacity", 409, {
        current: event.current_participants,
        max: event.max_participants,
      });
    }

    // 4. 티켓 정보 조회
    const { data: ticket, error: ticketError } = await supabase
      .from("tickets")
      .select(
        "id, price, quantity, sold_count, status, required_verification_ids, event_id",
      )
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
      return errorResponse("Ticket is not available", 409, {
        ticket_status: ticket.status,
      });
    }

    // 티켓 capacity guard
    if (isTicketSoldOut(ticket.sold_count, ticket.quantity)) {
      return errorResponse("Ticket is sold out", 409);
    }

    // 5. 중복 신청 확인 — cancelled/payment_failed 상태는 재신청 허용
    const { data: existingApp } = await supabase
      .from("event_applications")
      .select("id, status")
      .eq("event_id", event_id)
      .eq("user_id", userId)
      .maybeSingle();

    if (
      existingApp && existingApp.status !== "cancelled" &&
      existingApp.status !== "payment_failed"
    ) {
      return errorResponse("Already applied to this event", 409);
    }

    // 6. eligibility 체크 — 티켓에 required_verification_ids가 있는 경우 확인
    const requiredVerificationIds: string[] =
      ticket.required_verification_ids ?? [];
    if (requiredVerificationIds.length > 0) {
      const { data: verifications } = await supabase
        .from("user_verifications")
        .select("verification_id")
        .eq("user_id", userId)
        .in("verification_id", requiredVerificationIds);

      const verifiedIds = new Set(
        (verifications ?? []).map((v: { verification_id: string }) =>
          v.verification_id
        ),
      );
      const missingIds = requiredVerificationIds.filter((id) =>
        !verifiedIds.has(id)
      );

      if (missingIds.length > 0) {
        return errorResponse("Eligibility requirements not met", 403, {
          missing_verification_ids: missingIds,
        });
      }
    }

    // 7. 가격 기반 분기
    const price: number = ticket.price ?? 0;

    if (price > 0) {
      // 유료: payment_pending 상태로 신청 레코드 생성 후 주문 정보 반환
      // Fix #1492: 유료 경로 성별 균형 검증 누락 — 무료 경로와 동일하게 check_party_balance 추가
      const { data: balanceResult, error: balanceError } = await supabase.rpc(
        "check_party_balance",
        {
          p_event_id: event_id,
          p_ticket_id: ticket_id,
        },
      );
      if (balanceError) {
        console.error(
          "check_party_balance error on paid application:",
          balanceError.message,
        );
        return errorResponse("Failed to check balance", 500);
      }
      const balance = balanceResult as {
        allowed: boolean;
        reason: string | null;
      } | null;
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
          console.error(
            "Failed to update paid application for re-application:",
            updateError.message,
          );
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
          console.error(
            "Failed to create paid application:",
            insertError.message,
          );
          // unique constraint violation (23505) → race condition으로 중복 신청 발생
          if (insertError.code === "23505") {
            return errorResponse("Already applied to this event", 409);
          }
          return errorResponse("Failed to create application", 500);
        }
      }

      // Fix #1342 Bug2: 유료 경로에서 verification_data 처리 — RPC 미사용으로 인해 직접 삽입
      if (verifItems.length > 0) {
        const verifError = await upsertVerifications(
          supabase,
          userId,
          applicationId,
          verifPartnerId,
          verifItems,
        );
        if (verifError) return verifError;
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
        const { data: balanceResult, error: balanceError } = await supabase.rpc(
          "check_party_balance",
          {
            p_event_id: event_id,
            p_ticket_id: ticket_id,
          },
        );
        if (balanceError) {
          console.error(
            "check_party_balance error on free re-application:",
            balanceError.message,
          );
          return errorResponse("Failed to check balance", 500);
        }
        const balance = balanceResult as {
          allowed: boolean;
          reason: string | null;
        } | null;
        if (!balance?.allowed) {
          return errorResponse(balance?.reason ?? "성비 균형 제한", 409);
        }

        // Fix #1660: free re-applications use 'approved' (not 'paid') — payment_id is null for free events
        const newStatus = verifItems.length > 0 ? "pending_review" : "approved";
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
          console.error(
            "Failed to update free application for re-application:",
            updateError.message,
          );
          return errorResponse("Failed to apply to event", 500);
        }

        // Fix #1342 Bug2: 무료 재신청 경로에서 verification_data 처리
        if (verifItems.length > 0) {
          const verifError = await upsertVerifications(
            supabase,
            userId,
            existingApp.id,
            verifPartnerId,
            verifItems,
          );
          if (verifError) return verifError;
        }

        return successResponse({
          type: "free",
          application_id: existingApp.id,
        });
      }

      // 신규 무료 신청: apply_event RPC 호출 — DB 레벨 balance 체크 + 신청 완료
      // RPC handles one verification entry (first item). Additional verifications
      // are upserted separately after the RPC creates the application record.
      const rpcVerifData =
        verifItems.length > 0
          ? {
              partner_id: verifPartnerId,
              verification_id: verifItems[0].verification_id,
              data: verifItems[0].data,
            }
          : null;

      const { data: applicationId, error: rpcError } = await supabase.rpc(
        "apply_event",
        {
          p_event_id: event_id,
          p_ticket_id: ticket_id,
          p_user_id: userId,
          p_payment_id: null,
          p_payment_amount: 0,
          p_verification_data: rpcVerifData,
        },
      );

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

      // Process extra verifications (index 1+) that the RPC did not handle
      if (verifItems.length > 1) {
        const verifError = await upsertVerifications(
          supabase,
          userId,
          applicationId as string,
          verifPartnerId,
          verifItems.slice(1),
        );
        if (verifError) return verifError;
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
};

minglitEdgeFunction(handler);
