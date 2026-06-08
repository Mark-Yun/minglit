import type { EFContext } from "../_shared/edge_function.ts";
import { log, withSpan } from "../_shared/logger.ts";
import {
  parseRefundPolicy,
  verifyRefundEligibility,
} from "../_shared/domains/payment/refund_policy.ts";
import type { UserRequestRefundInput } from "./input.ts";

const FN = "user-request-refund";
const RESPONSE_DEADLINE_HOURS = 72;

export type UserRequestRefundResult =
  | {
    ok: true;
    request: {
      id: string;
      application_id: string;
      status: "pending";
      requested_at: string;
      response_deadline_at: string;
    };
  }
  | {
    ok: false;
    status: number;
    message: string;
    details?: unknown;
  };

interface ApplicationSnapshot {
  id: string;
  event_id: string;
  user_id: string;
  status: string;
  payment_id: string | null;
  payment_amount: number | null;
  paid_at: string | null;
  refund_status: string | null;
}

export async function requestPartnerRefund(args: {
  supabase: EFContext["supabase"];
  userId: string;
  input: UserRequestRefundInput;
  now?: Date;
}): Promise<UserRequestRefundResult> {
  const { supabase, userId, input } = args;
  const now = args.now ?? new Date();

  const { data: application, error: appError } = await withSpan(
    "db.query.event_applications",
    "db.query",
    () =>
      supabase
        .from("event_applications")
        .select(
          "id, event_id, user_id, status, payment_id, payment_amount, paid_at, refund_status",
        )
        .eq("id", input.application_id)
        .single(),
  );

  if (appError || !application) {
    return fail(404, "Order not found");
  }

  const app = application as ApplicationSnapshot;
  if (app.user_id !== userId) {
    return fail(403, "Forbidden");
  }

  if (!["paid", "approved"].includes(app.status)) {
    return fail(400, "refund_request_not_allowed", {
      reason: "invalid_status",
    });
  }
  if (
    app.payment_amount === null || app.payment_amount <= 0 || !app.payment_id
  ) {
    return fail(400, "refund_request_not_allowed", {
      reason: "not_paid_order",
    });
  }
  if (app.refund_status !== "none") {
    return fail(409, "refund_request_exists");
  }

  const [eventResult, policyResult, existingResult] = await Promise.all([
    withSpan("db.query.events", "db.query", () =>
      supabase
        .from("events")
        .select("id, party_id, start_time")
        .eq("id", app.event_id)
        .single()),
    withSpan(
      "db.rpc.get_current_policy",
      "db.rpc",
      () => supabase.rpc("get_current_policy", { p_key: "refund" }),
    ),
    withSpan("db.query.refund_requests.existing", "db.query", () =>
      supabase
        .from("refund_requests")
        .select("id, status")
        .eq("application_id", app.id)
        .maybeSingle()),
  ]);

  if (existingResult.data) {
    return fail(409, "refund_request_exists");
  }

  if (eventResult.error || !eventResult.data) {
    log({
      function: FN,
      level: "error",
      message: "Failed to fetch event",
      metadata: { detail: eventResult.error },
    });
    return fail(500, "Failed to verify refund eligibility");
  }
  if (policyResult.error || !policyResult.data) {
    log({
      function: FN,
      level: "error",
      message: "Failed to fetch policy",
      metadata: { detail: policyResult.error },
    });
    return fail(500, "Failed to verify refund eligibility");
  }

  const event = eventResult.data as { party_id: string; start_time: string };
  const policy = parseRefundPolicy(policyResult.data);
  const eligibility = verifyRefundEligibility({
    paidAt: app.paid_at,
    eventStartTime: event.start_time,
    now,
    ...policy,
  });
  if (eligibility.eligible) {
    return fail(409, "automatic_refund_available");
  }

  const { data: party, error: partyError } = await withSpan(
    "db.query.parties",
    "db.query",
    () =>
      supabase
        .from("parties")
        .select("partner_id")
        .eq("id", event.party_id)
        .single(),
  );
  if (partyError || !party) {
    log({
      function: FN,
      level: "error",
      message: "Failed to fetch party",
      metadata: { detail: partyError },
    });
    return fail(500, "Failed to create refund request");
  }

  const requestedAt = now.toISOString();
  const responseDeadlineAt = new Date(
    now.getTime() + RESPONSE_DEADLINE_HOURS * 60 * 60 * 1000,
  ).toISOString();

  const { data: requestData, error: requestError } = await withSpan(
    "db.rpc.create_partner_refund_request",
    "db.rpc",
    () =>
      supabase.rpc("create_partner_refund_request", {
        p_application_id: app.id,
        p_user_id: userId,
        p_event_id: app.event_id,
        p_partner_id: (party as { partner_id: string }).partner_id,
        p_reason_code: input.reason_code,
        p_reason_text: input.reason_text ?? null,
        p_requested_at: requestedAt,
        p_response_deadline_at: responseDeadlineAt,
      }),
  );

  const request = Array.isArray(requestData) ? requestData[0] : requestData;
  if (requestError || !request) {
    const code = isUniqueViolation(requestError) ? 409 : 500;
    return fail(
      code,
      code === 409
        ? "refund_request_exists"
        : "Failed to create refund request",
      requestError,
    );
  }

  const row = request as {
    id: string;
    application_id: string;
    status: "pending";
    requested_at: string;
    response_deadline_at: string;
  };
  return { ok: true, request: row };
}

function isUniqueViolation(error: unknown): boolean {
  return typeof error === "object" && error !== null &&
    "code" in error && (error as { code?: string }).code === "23505";
}

function fail(
  status: number,
  message: string,
  details?: unknown,
): Extract<UserRequestRefundResult, { ok: false }> {
  return details === undefined
    ? { ok: false, status, message }
    : { ok: false, status, message, details };
}
