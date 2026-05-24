export const APPROVABLE_APPLICATION_STATUSES = [
  "pending",
  "pending_review",
] as const;

export interface ApprovalFailure {
  ok: false;
  status: number;
  message: string;
  details?: unknown;
}

export type SingleApprovalPolicyResult =
  | { ok: true; approved: 1 }
  | ApprovalFailure;

export type BulkApprovalPolicyResult =
  | {
    ok: true;
    approved: number;
    skippedDueToCapacity: number;
    remainingSlotsBeforeApproval: number;
  }
  | ApprovalFailure;

export function isApplicationApprovableForPartnerApproval(
  status: string,
): boolean {
  return APPROVABLE_APPLICATION_STATUSES.includes(
    status as typeof APPROVABLE_APPLICATION_STATUSES[number],
  );
}

export function mapSingleApprovalRpcResult(
  rawResult: unknown,
): SingleApprovalPolicyResult {
  const result = firstResult(rawResult);
  const resultStatus = typeof result.result_status === "string"
    ? result.result_status
    : undefined;

  if (resultStatus === "approved") {
    return { ok: true, approved: 1 };
  }
  if (resultStatus === "event_full") {
    return fail(409, "정원이 초과되었습니다.", { code: "EVENT_FULL" });
  }
  if (resultStatus === "already_processed") {
    return fail(409, "Application already processed");
  }
  if (resultStatus === "not_found") {
    return fail(404, "Application not found");
  }

  return fail(500, "Event capacity data is invalid", {
    code: "INVALID_EVENT_CAPACITY",
  });
}

export function mapBulkApprovalRpcResult(
  rawResult: unknown,
): BulkApprovalPolicyResult {
  const result = firstResult(rawResult);
  const resultStatus = typeof result.result_status === "string"
    ? result.result_status
    : undefined;

  if (resultStatus === "invalid_capacity") {
    return fail(500, "Event capacity data is invalid", {
      code: "INVALID_EVENT_CAPACITY",
    });
  }
  if (resultStatus === "not_found") {
    return fail(404, "Event not found");
  }

  return {
    ok: true,
    approved: numberOrZero(result.approved_count),
    skippedDueToCapacity: numberOrZero(result.skipped_due_to_capacity),
    remainingSlotsBeforeApproval: numberOrZero(
      result.remaining_slots_before_approval,
    ),
  };
}

function firstResult(rawResult: unknown): Record<string, unknown> {
  const value = Array.isArray(rawResult) ? rawResult[0] : rawResult;
  return typeof value === "object" && value !== null
    ? value as Record<string, unknown>
    : {};
}

function numberOrZero(value: unknown): number {
  return typeof value === "number" ? value : 0;
}

function fail(
  status: number,
  message: string,
  details?: unknown,
): ApprovalFailure {
  if (details === undefined) return { ok: false, status, message };
  return { ok: false, status, message, details };
}
