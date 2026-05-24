import {
  isEventFull,
  isEventOpenForApplication,
  isEventStarted,
  isTicketSoldOut,
} from "../event/availability.ts";
import { blocksReapplication } from "../payment/application_status.ts";

export type CreateOrderErrorCode =
  | "EVENT_CLOSED"
  | "EVENT_NOT_SCHEDULED"
  | "TICKET_SOLD_OUT"
  | "EVENT_FULL"
  | "IDENTITY_REQUIRED"
  | "GENDER_MISMATCH"
  | "AGE_MISMATCH"
  | "VERIFICATION_REQUIRED"
  | "BALANCE_LIMIT"
  | "ALREADY_APPLIED";

export type CreateOrderPolicyResult =
  | { ok: true }
  | { ok: false; status: number; message: string; code?: CreateOrderErrorCode };

export interface CreateOrderEventSnapshot {
  status: string;
  start_time: string | Date;
  max_participants: number;
  current_participants: number;
}

export interface CreateOrderTicketSnapshot {
  event_id: string;
  price: number;
  quantity: number;
  sold_count: number;
}

export interface CreateOrderUserProfileSnapshot {
  is_verified: boolean;
  gender?: string | null;
  birth_date?: string | null;
}

export interface CreateOrderEntryGroupSnapshot {
  gender?: string | null;
  birth_year_min?: number | null;
  birth_year_max?: number | null;
  required_verification_ids?: string[] | null;
}

export interface CreateOrderExistingApplicationSnapshot {
  status: string;
}

export interface CreateOrderVerificationData {
  verification_id: string;
  data: Record<string, unknown>;
}

export interface CreateOrderPaymentPlan {
  amount: number;
  requiresPayment: boolean;
  initialStatus: "pending" | "paid";
}

export function evaluateEventAvailability(
  event: CreateOrderEventSnapshot,
  now: Date,
): CreateOrderPolicyResult {
  const windowResult = evaluateEventApplicationWindow(event, now);
  if (!windowResult.ok) return windowResult;
  return evaluateEventCapacity(event);
}

export function evaluateEventApplicationWindow(
  event: Pick<CreateOrderEventSnapshot, "status" | "start_time">,
  now: Date,
): CreateOrderPolicyResult {
  if (!isEventOpenForApplication(event.status)) {
    return reject("이벤트가 마감되었습니다.", "EVENT_CLOSED");
  }
  if (isEventStarted(event.start_time, now)) {
    return reject("이벤트가 마감되었습니다.", "EVENT_NOT_SCHEDULED");
  }
  return { ok: true };
}

export function evaluateEventCapacity(
  event: Pick<
    CreateOrderEventSnapshot,
    "current_participants" | "max_participants"
  >,
): CreateOrderPolicyResult {
  if (isEventFull(event.current_participants, event.max_participants)) {
    return reject("정원이 초과되었습니다.", "EVENT_FULL");
  }
  return { ok: true };
}

export function evaluateTicketAvailability(
  ticket: CreateOrderTicketSnapshot,
  eventId: string,
): CreateOrderPolicyResult {
  if (ticket.event_id !== eventId) {
    return { ok: false, status: 404, message: "티켓을 찾을 수 없습니다." };
  }
  if (isTicketSoldOut(ticket.sold_count, ticket.quantity)) {
    return reject("티켓이 매진되었습니다.", "TICKET_SOLD_OUT");
  }
  return { ok: true };
}

export function evaluateIdentity(
  profile: CreateOrderUserProfileSnapshot,
): CreateOrderPolicyResult {
  if (!profile.is_verified) {
    return reject("본인인증이 필요합니다.", "IDENTITY_REQUIRED");
  }
  return { ok: true };
}

export function evaluateEntryGroupEligibility(args: {
  profile: CreateOrderUserProfileSnapshot;
  entryGroups: CreateOrderEntryGroupSnapshot[];
  verificationData?: CreateOrderVerificationData;
}): CreateOrderPolicyResult {
  const { profile, entryGroups, verificationData } = args;
  if (entryGroups.length === 0) return { ok: true };

  const primaryGroup = entryGroups[0];
  if (
    primaryGroup.gender && profile.gender &&
    primaryGroup.gender !== profile.gender
  ) {
    return reject("성별 조건이 맞지 않습니다.", "GENDER_MISMATCH");
  }

  if (profile.birth_date) {
    const birthYear = new Date(profile.birth_date).getFullYear();
    if (
      primaryGroup.birth_year_min && birthYear < primaryGroup.birth_year_min
    ) {
      return reject("나이 조건이 맞지 않습니다.", "AGE_MISMATCH");
    }
    if (
      primaryGroup.birth_year_max && birthYear > primaryGroup.birth_year_max
    ) {
      return reject("나이 조건이 맞지 않습니다.", "AGE_MISMATCH");
    }
  }

  const requiredIds = entryGroups.flatMap((g) =>
    g.required_verification_ids ?? []
  );
  if (requiredIds.length > 0 && !verificationData) {
    return reject("자격 인증 정보가 필요합니다.", "VERIFICATION_REQUIRED");
  }

  return { ok: true };
}

export function evaluatePartyBalance(
  balanceResult: { allowed?: boolean } | null,
): CreateOrderPolicyResult {
  if (balanceResult?.allowed === false) {
    return reject("성비 균형 제한입니다.", "BALANCE_LIMIT");
  }
  return { ok: true };
}

export function evaluateReapplication(
  existingApp: CreateOrderExistingApplicationSnapshot | null,
): CreateOrderPolicyResult {
  if (existingApp && blocksReapplication(existingApp.status)) {
    return reject("이미 신청한 이벤트입니다.", "ALREADY_APPLIED");
  }
  return { ok: true };
}

export function decideCreateOrderPaymentPlan(
  ticket: Pick<CreateOrderTicketSnapshot, "price">,
): CreateOrderPaymentPlan {
  const amount = ticket.price;
  const requiresPayment = amount > 0;
  return {
    amount,
    requiresPayment,
    initialStatus: requiresPayment ? "pending" : "paid",
  };
}

function reject(
  message: string,
  code: CreateOrderErrorCode,
): CreateOrderPolicyResult {
  return { ok: false, status: 400, message, code };
}
