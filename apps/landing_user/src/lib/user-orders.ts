import type { SupabaseClient } from "@supabase/supabase-js";
import type { PublicEvent, Ticket } from "./events";

export type CheckoutOrderResult = {
  applicationId: string;
  amount: number;
  requiresPayment: boolean;
  ticketName: string;
};
export type CheckoutGateInput = {
  authStatus: "loading" | "config-error" | "anonymous" | "profile-error" | "ready";
  isVerified: boolean;
  agreed: boolean;
  ticketPrice: number;
  isCreating: boolean;
};
export type CheckoutGate = { canSubmit: boolean; helper: string };

export type PurchaseStatus = "pending" | "pending_review" | "approved" | "rejected" | "cancelled" | "paid" | "payment_failed" | "payment_pending";
export type RefundStatus = "none" | "requested" | "completed" | "failed";

export type UserPurchase = {
  id: string;
  eventId: string;
  ticketId: string;
  eventTitle: string;
  eventImageUrl: string | null;
  startsAt: string;
  endsAt: string;
  locationName: string;
  locationAddress: string;
  partnerName: string;
  ticketName: string;
  amount: number;
  status: PurchaseStatus;
  refundStatus: RefundStatus;
  rejectionReason: string | null;
  paymentId: string | null;
  createdAt: string;
  paidAt: string | null;
  refundedAt: string | null;
};

type FunctionError = { message?: string };

type PurchaseRow = {
  id: string;
  event_id: string;
  ticket_id: string;
  status: string;
  payment_id: string | null;
  payment_amount: number | null;
  refund_status: string | null;
  rejection_reason: string | null;
  created_at: string;
  paid_at?: string | null;
  refunded_at?: string | null;
  events: {
    id: string;
    title?: string | null;
    start_time: string;
    end_time: string;
    image_urls?: string[] | null;
    locations?: { name?: string | null; address?: string | null; region_1?: string | null; region_2?: string | null } | null;
    parties?: {
      title?: string | null;
      image_urls?: string[] | null;
      partners?: { name?: string | null } | null;
    } | null;
  } | null;
  tickets: { id: string; name: string; price?: number | null } | null;
};

const PURCHASE_SELECT = [
  "id",
  "event_id",
  "ticket_id",
  "status",
  "payment_id",
  "payment_amount",
  "refund_status",
  "rejection_reason",
  "created_at",
  "paid_at",
  "refunded_at",
  "events(id,title,start_time,end_time,image_urls,locations(name,address,region_1,region_2),parties(title,image_urls,partners(name)))",
  "tickets(id,name,price)",
].join(",");

export function findCheckoutTicket(event: PublicEvent, ticketId: string | null): Ticket | null {
  if (!ticketId) return null;

  return event.tickets.find((ticket) => ticket.id === ticketId && isTicketOrderable(ticket)) ?? null;
}

export function isTicketOrderable(ticket: Ticket): boolean {
  return ticket.status === "on_sale" && (ticket.quantity <= 0 || ticket.soldCount < ticket.quantity);
}

export function checkoutGate(input: CheckoutGateInput): CheckoutGate {
  if (input.authStatus === "loading") return { canSubmit: false, helper: "로그인 상태를 확인하고 있습니다." };
  if (input.authStatus === "anonymous") return { canSubmit: false, helper: "로그인 후 같은 주문으로 돌아옵니다." };
  if (input.authStatus === "config-error") return { canSubmit: false, helper: "Supabase 공개 환경변수가 없어 신청을 시작할 수 없습니다." };
  if (input.authStatus === "profile-error") return { canSubmit: false, helper: "프로필 인증 상태를 확인하지 못했습니다. 잠시 후 다시 시도해 주세요." };
  if (!input.isVerified) return { canSubmit: false, helper: "본인인증 후 결제할 수 있어요." };
  if (input.ticketPrice > 0) return { canSubmit: false, helper: "유료 결제창은 아직 연결되지 않아 출시 전입니다." };
  if (!input.agreed) return { canSubmit: false, helper: "필수 약관과 환불 정책에 동의해 주세요." };
  if (input.isCreating) return { canSubmit: false, helper: "신청을 생성하고 있습니다." };

  return { canSubmit: true, helper: "무료 티켓 신청 후에도 파트너 승인 전까지는 승인 대기 상태입니다." };
}

export async function fetchUserVerified(supabase: SupabaseClient, userId: string): Promise<boolean> {
  const { data, error } = await supabase
    .from("user_profiles")
    .select("is_verified")
    .eq("id", userId)
    .single<{ is_verified: boolean | null }>();

  if (error) throw error;

  return data?.is_verified === true;
}

export async function createCheckoutOrder(
  supabase: SupabaseClient,
  eventId: string,
  ticketId: string,
): Promise<CheckoutOrderResult> {
  const { data, error } = await supabase.functions.invoke("user-create-order", {
    body: { event_id: eventId, ticket_id: ticketId },
  });

  if (error) throw new Error(error.message);

  const body = data as {
    application_id?: string;
    amount?: number;
    requires_payment?: boolean;
    ticket_name?: string;
    error?: FunctionError;
  } | null;

  if (!body?.application_id) {
    throw new Error(body?.error?.message ?? "주문을 생성하지 못했습니다.");
  }

  return {
    applicationId: body.application_id,
    amount: body.amount ?? 0,
    requiresPayment: body.requires_payment ?? false,
    ticketName: body.ticket_name ?? "티켓",
  };
}

export async function verifyCheckoutPayment(
  supabase: SupabaseClient,
  impUid: string,
  merchantUid: string,
): Promise<void> {
  const { data, error } = await supabase.functions.invoke("payment-verify", {
    body: { imp_uid: impUid, merchant_uid: merchantUid },
  });

  if (error) throw new Error(error.message);
  if ((data as { error?: FunctionError } | null)?.error) {
    throw new Error((data as { error: FunctionError }).error.message ?? "결제를 검증하지 못했습니다.");
  }
}

export async function fetchUserPurchases(supabase: SupabaseClient): Promise<UserPurchase[]> {
  const { data, error } = await supabase
    .from("event_applications")
    .select(PURCHASE_SELECT)
    .order("created_at", { ascending: false })
    .limit(50)
    .returns<PurchaseRow[]>();

  if (error) throw error;

  return (data ?? []).map(mapPurchaseRow);
}

export async function cancelUserOrder(supabase: SupabaseClient, eventId: string, reason: string): Promise<string> {
  const { data, error } = await supabase.functions.invoke("user-cancel-order", {
    body: { event_id: eventId, reason },
  });

  if (error) throw new Error(error.message);

  const body = data as { type?: string; data?: { refund_amount?: number }; error?: FunctionError } | null;
  if (body?.error) throw new Error(body.error.message ?? "환불 요청을 처리하지 못했습니다.");
  if (body?.type === "refunded") return `${(body.data?.refund_amount ?? 0).toLocaleString("ko-KR")}원 환불이 접수됐습니다.`;
  if (body?.type === "cancelled") return "신청 취소가 접수됐습니다.";

  return "요청이 접수됐습니다.";
}

export function mapPurchaseRow(row: PurchaseRow): UserPurchase {
  const event = row.events;
  const location = event?.locations;
  const ticket = row.tickets;
  const eventTitle = event?.title ?? event?.parties?.title ?? "이벤트";

  return {
    id: row.id,
    eventId: row.event_id,
    ticketId: row.ticket_id,
    eventTitle,
    eventImageUrl: event?.image_urls?.[0] ?? event?.parties?.image_urls?.[0] ?? null,
    startsAt: event?.start_time ?? row.created_at,
    endsAt: event?.end_time ?? row.created_at,
    locationName: location?.name ?? ([location?.region_1, location?.region_2].filter(Boolean).join(" ") || "장소 미정"),
    locationAddress: location?.address ?? "상세 장소는 신청 후 안내됩니다.",
    partnerName: event?.parties?.partners?.name ?? "Minglit Partner",
    ticketName: ticket?.name ?? "티켓",
    amount: row.payment_amount ?? ticket?.price ?? 0,
    status: normalizePurchaseStatus(row.status),
    refundStatus: normalizeRefundStatus(row.refund_status),
    rejectionReason: row.rejection_reason,
    paymentId: row.payment_id,
    createdAt: row.created_at,
    paidAt: row.paid_at ?? null,
    refundedAt: row.refunded_at ?? null,
  };
}

export function statusCopy(status: PurchaseStatus, refundStatus: RefundStatus): { label: string; tone: string } {
  if (refundStatus === "completed") return { label: "환불 완료", tone: "neutral" };
  if (refundStatus === "requested") return { label: "환불 요청됨", tone: "warning" };
  if (refundStatus === "failed") return { label: "환불 실패", tone: "error" };

  switch (status) {
    case "approved":
      return { label: "확정", tone: "success" };
    case "paid":
    case "pending_review":
    case "pending":
      return { label: "승인 대기", tone: "info" };
    case "rejected":
      return { label: "거절됨", tone: "error" };
    case "cancelled":
      return { label: "취소됨", tone: "neutral" };
    case "payment_pending":
      return { label: "결제 대기", tone: "warning" };
    case "payment_failed":
      return { label: "결제 실패", tone: "error" };
  }
}

export function canRequestAutomaticRefund(purchase: UserPurchase, now = new Date()): boolean {
  if (!["paid", "pending", "pending_review", "approved"].includes(purchase.status)) return false;
  if (purchase.refundStatus !== "none") return false;

  const paidAt = purchase.paidAt ? new Date(purchase.paidAt) : new Date(purchase.createdAt);
  const startsAt = new Date(purchase.startsAt);
  const graceMs = 3 * 60 * 60 * 1000;
  const cutoffMs = 7 * 24 * 60 * 60 * 1000;

  return now.getTime() - paidAt.getTime() <= graceMs || startsAt.getTime() - now.getTime() >= cutoffMs;
}

function normalizePurchaseStatus(value: string): PurchaseStatus {
  const allowed: PurchaseStatus[] = ["pending", "pending_review", "approved", "rejected", "cancelled", "paid", "payment_failed", "payment_pending"];
  return allowed.includes(value as PurchaseStatus) ? (value as PurchaseStatus) : "pending";
}

function normalizeRefundStatus(value: string | null): RefundStatus {
  const allowed: RefundStatus[] = ["none", "requested", "completed", "failed"];
  return allowed.includes(value as RefundStatus) ? (value as RefundStatus) : "none";
}
