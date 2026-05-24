// partner-approve-application — Approve event applications (single + bulk)
// Issue #517: 파트너 대시보드 리디자인 — 신청 승인 API

import { errorResponse, successResponse } from "../_shared/response_utils.ts";
import { parseAction } from "../_shared/request_utils.ts";
import {
  type EFContext,
  minglitEdgeFunction,
} from "../_shared/edge_function.ts";
import { approveApplication } from "./approve_application_service.ts";
import { parsePartnerApproveInput } from "./input.ts";

export const handler = async (
  req: Request,
  ctx: EFContext,
): Promise<Response> => {
  if (req.method !== "POST") return errorResponse("Method not allowed", 405);
  if (ctx.auth.type !== "user") {
    return errorResponse("Unexpected auth type", 500);
  }

  const parsed = await parseAction(req);
  if (parsed instanceof Response) return parsed;

  const input = parsePartnerApproveInput(parsed.action, parsed.body);
  if (input instanceof Response) return input;

  const result = await approveApplication({
    supabase: ctx.supabase,
    input,
    userId: ctx.auth.userId,
  });

  if (result instanceof Response) return result;

  if (!result.ok) {
    return errorResponse(result.message, result.status, result.details);
  }

  if (result.type === "approve") {
    return successResponse({
      approved: result.approved,
      application_id: result.applicationId,
    });
  }

  return successResponse({
    approved: result.approved,
    event_id: result.eventId,
    skipped_due_to_capacity: result.skippedDueToCapacity,
    remaining_slots_before_approval: result.remainingSlotsBeforeApproval,
  });
};

minglitEdgeFunction(handler);
