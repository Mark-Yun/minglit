import type { EFContext } from "../_shared/edge_function.ts";
import { log, withSpan } from "../_shared/logger.ts";
import { logStatsigEvent } from "../_shared/statsig_utils.ts";
import {
  type CreateOrderEntryGroupSnapshot,
  type CreateOrderEventSnapshot,
  type CreateOrderExistingApplicationSnapshot,
  type CreateOrderPolicyResult,
  type CreateOrderTicketSnapshot,
  type CreateOrderUserProfileSnapshot,
  decideCreateOrderPaymentPlan,
  evaluateEntryGroupEligibility,
  evaluateEventApplicationWindow,
  evaluateEventCapacity,
  evaluateIdentity,
  evaluatePartyBalance,
  evaluateReapplication,
  evaluateTicketAvailability,
} from "../_shared/domains/order/create_order_policy.ts";
import type { CreateOrderInput } from "./input.ts";

const FN = "user-create-order";

export type CreateOrderServiceResult =
  | {
    ok: true;
    applicationId: string;
    amount: number;
    requiresPayment: boolean;
    ticketName: string;
    payment?: PortoneV2BrowserPayment;
  }
  | CreateOrderServiceFailure;

export interface PortoneV2BrowserPayment {
  provider: "portone_v2";
  store_id: string;
  channel_key: string;
  payment_id: string;
  order_name: string;
  total_amount: number;
  currency: "CURRENCY_KRW";
  pay_method: "CARD";
  redirect_url: string;
  force_redirect: boolean;
}

export interface CreateOrderServiceFailure {
  ok: false;
  status: number;
  message: string;
  code?: string;
}

export async function createApplicationOrder(args: {
  supabase: EFContext["supabase"];
  userId: string;
  input: CreateOrderInput;
  now?: Date;
}): Promise<CreateOrderServiceResult> {
  const { supabase, userId, input } = args;
  const now = args.now ?? new Date();

  const { data: event, error: eventError } = await withSpan(
    "db.query.events",
    "db.query",
    () =>
      supabase
        .from("events")
        .select(
          "id, party_id, title, status, start_time, max_participants, current_participants",
        )
        .eq("id", input.event_id)
        .single(),
  );

  if (eventError || !event) {
    return fail(404, "이벤트를 찾을 수 없습니다.");
  }

  const eventPolicy = evaluateEventApplicationWindow(
    event as CreateOrderEventSnapshot,
    now,
  );
  if (!eventPolicy.ok) return fromPolicy(eventPolicy);

  const { data: ticket, error: ticketError } = await withSpan(
    "db.query.tickets",
    "db.query",
    () =>
      supabase
        .from("tickets")
        .select(
          "id, event_id, name, price, quantity, sold_count, target_entry_group_ids",
        )
        .eq("id", input.ticket_id)
        .single(),
  );

  if (ticketError || !ticket) {
    return fail(404, "티켓을 찾을 수 없습니다.");
  }

  const ticketPolicy = evaluateTicketAvailability(
    ticket as CreateOrderTicketSnapshot,
    input.event_id,
  );
  if (!ticketPolicy.ok) return fromPolicy(ticketPolicy);

  const capacityPolicy = evaluateEventCapacity(
    event as CreateOrderEventSnapshot,
  );
  if (!capacityPolicy.ok) return fromPolicy(capacityPolicy);

  const { data: userProfile, error: profileError } = await withSpan(
    "db.query.user_profiles",
    "db.query",
    () =>
      supabase
        .from("user_profiles")
        .select("id, is_verified, gender, birth_date")
        .eq("id", userId)
        .single(),
  );

  if (profileError || !userProfile) {
    return fail(404, "사용자 프로필을 찾을 수 없습니다.");
  }

  const profile = userProfile as CreateOrderUserProfileSnapshot;
  const identityPolicy = evaluateIdentity(profile);
  if (!identityPolicy.ok) return fromPolicy(identityPolicy);

  const targetGroupIds: string[] = Array.isArray(ticket.target_entry_group_ids)
    ? ticket.target_entry_group_ids
    : [];
  if (targetGroupIds.length > 0) {
    const { data: entryGroups } = await withSpan(
      "db.query.entry_groups",
      "db.query",
      () =>
        supabase
          .from("entry_groups")
          .select(
            "id, gender, birth_year_min, birth_year_max, required_verification_ids",
          )
          .eq("event_id", input.event_id)
          .in("id", targetGroupIds),
    );

    const eligibilityPolicy = evaluateEntryGroupEligibility({
      profile,
      entryGroups: Array.isArray(entryGroups)
        ? entryGroups as CreateOrderEntryGroupSnapshot[]
        : [],
      verificationData: input.verification_data,
    });
    if (!eligibilityPolicy.ok) return fromPolicy(eligibilityPolicy);
  }

  const { data: balanceResult, error: balanceError } = await withSpan(
    "db.rpc.check_party_balance",
    "db.rpc",
    () =>
      supabase.rpc("check_party_balance", {
        p_event_id: input.event_id,
        p_ticket_id: input.ticket_id,
      }),
  );

  if (balanceError) {
    log({
      function: FN,
      level: "error",
      message: "check_party_balance error",
      metadata: { detail: balanceError },
    });
  }

  const balancePolicy = evaluatePartyBalance(
    isRecord(balanceResult) ? balanceResult as { allowed?: boolean } : null,
  );
  if (!balancePolicy.ok) return fromPolicy(balancePolicy);

  const { data: existingApp } = await withSpan(
    "db.query.existing_application",
    "db.query",
    () =>
      supabase
        .from("event_applications")
        .select("id, status")
        .eq("event_id", input.event_id)
        .eq("user_id", userId)
        .single(),
  );

  const existingApplication = isRecord(existingApp)
    ? existingApp as CreateOrderExistingApplicationSnapshot & { id?: string }
    : null;
  const reapplicationPolicy = evaluateReapplication(existingApplication);
  if (!reapplicationPolicy.ok) return fromPolicy(reapplicationPolicy);

  const paymentPlan = decideCreateOrderPaymentPlan(
    ticket as CreateOrderTicketSnapshot,
  );
  const pendingPaymentId = paymentPlan.requiresPayment
    ? createPortoneV2PaymentId()
    : `PENDING_${crypto.randomUUID()}`;

  const { data: appId, error: applyError } = await withSpan(
    "db.rpc.apply_event",
    "db.rpc",
    () =>
      supabase.rpc("apply_event", {
        p_event_id: input.event_id,
        p_ticket_id: input.ticket_id,
        p_user_id: userId,
        p_payment_id: pendingPaymentId,
        p_payment_amount: paymentPlan.amount,
        p_verification_data: input.verification_data ?? null,
      }),
  );

  if (applyError) {
    log({
      function: FN,
      level: "error",
      message: "apply_event error",
      metadata: { detail: applyError },
    });
    return fail(500, "주문 생성 중 오류가 발생했습니다.");
  }

  const applicationId = String(appId);
  const updatePayload: Record<string, unknown> = {
    status: paymentPlan.initialStatus,
    payment_id: pendingPaymentId,
    payment_amount: paymentPlan.amount,
    updated_at: now.toISOString(),
  };
  if (existingApplication) {
    updatePayload.ticket_id = input.ticket_id;
  }

  const { error: updateError } = await withSpan(
    existingApplication
      ? "db.update.event_applications"
      : "db.update.event_applications.status",
    "db.update",
    () =>
      supabase
        .from("event_applications")
        .update(updatePayload)
        .eq("id", applicationId),
  );

  if (updateError) {
    log({
      function: FN,
      level: "error",
      message: "event_applications update error",
      metadata: { detail: updateError },
    });
    return fail(500, "주문 생성 중 오류가 발생했습니다.");
  }

  logStatsigEvent(userId, "order_created", paymentPlan.amount, {
    event_id: input.event_id,
    ticket_id: input.ticket_id,
    requires_payment: String(paymentPlan.requiresPayment),
  }).catch(() => {});

  return {
    ok: true,
    applicationId,
    amount: paymentPlan.amount,
    requiresPayment: paymentPlan.requiresPayment,
    ticketName: String((ticket as { name?: unknown }).name ?? ""),
    ...(paymentPlan.requiresPayment
      ? {
        payment: buildPortonePayment({
          eventId: input.event_id,
          eventTitle: String((event as { title?: unknown }).title ?? "이벤트"),
          ticketName: String((ticket as { name?: unknown }).name ?? ""),
          paymentId: pendingPaymentId,
          amount: paymentPlan.amount,
        }),
      }
      : {}),
  };
}

function createPortoneV2PaymentId(): string {
  return `pay${crypto.randomUUID().replaceAll("-", "")}`;
}

function buildPortonePayment(args: {
  eventId: string;
  eventTitle: string;
  ticketName: string;
  paymentId: string;
  amount: number;
}): PortoneV2BrowserPayment {
  const storeId = Deno.env.get("PORTONE_V2_STORE_ID");
  const channelKey = Deno.env.get("PORTONE_V2_CHANNEL_KEY");
  const landingOrigin = Deno.env.get("LANDING_USER_ORIGIN") ??
    Deno.env.get("NEXT_PUBLIC_SITE_URL") ??
    "http://localhost:3000";

  if (!storeId || !channelKey) {
    throw new Error(
      "Missing required environment variables: PORTONE_V2_STORE_ID, PORTONE_V2_CHANNEL_KEY",
    );
  }

  return {
    provider: "portone_v2",
    store_id: storeId,
    channel_key: channelKey,
    payment_id: args.paymentId,
    order_name: `Minglit - ${args.eventTitle} / ${args.ticketName}`,
    total_amount: args.amount,
    currency: "CURRENCY_KRW",
    pay_method: "CARD",
    redirect_url: `${
      landingOrigin.replace(/\/$/, "")
    }/events/${args.eventId}/checkout/return`,
    force_redirect: false,
  };
}

function fromPolicy(result: Exclude<CreateOrderPolicyResult, { ok: true }>) {
  return fail(result.status, result.message, result.code);
}

function fail(
  status: number,
  message: string,
  code?: string,
): CreateOrderServiceFailure {
  return { ok: false, status, message, code };
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}
