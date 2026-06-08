import type { SupabaseClient } from "@supabase/supabase-js";

export type ApplicationStatus = "pending" | "pending_review" | "approved" | "rejected" | "cancelled" | "paid" | "payment_failed" | "payment_pending";
export type RefundStatus = "none" | "requested" | "completed" | "failed";
export type ApplicationTab = "pending" | "approved" | "rejected";
export type ApplicationMode = "applications" | "roster";

export type PartnerApplicationEvent = {
  id: string;
  title: string;
  startsAt: string;
  maxParticipants: number;
  applications: PartnerApplication[];
};

export type PartnerApplication = {
  id: string;
  eventId: string;
  userId: string;
  userName: string;
  ticketName: string;
  amount: number;
  status: ApplicationStatus;
  refundStatus: RefundStatus;
  rejectionReason: string | null;
  createdAt: string;
  paidAt: string | null;
};

export type ApplicationReviewResult = {
  approved: string[];
  rejected: string[];
  skippedDueToCapacity: string[];
  skippedAlreadyProcessed: string[];
  remainingSlotsAfter: number;
};

export type SettlementRow = {
  id: string;
  partnerId: string;
  transferId: string | null;
  amount: number;
  currency: string;
  settlementDate: string;
};

export type BankAccount = {
  bankCode: string | null;
  bankName: string;
  accountNumber: string;
  accountHolder: string;
  verificationStatus: string | null;
};

export type BankAccountInput = {
  partnerId: string;
  bankCode: string;
  accountHolder: string;
  accountNumber: string;
};

type FunctionError = { message?: string };

type ApplicationEventRow = {
  id: string;
  title: string | null;
  start_time: string;
  max_participants: number | null;
  event_applications: Array<{
    id: string;
    event_id: string;
    user_id: string;
    status: string;
    payment_amount: number | null;
    refund_status: string | null;
    rejection_reason: string | null;
    created_at: string;
    paid_at?: string | null;
    user_profiles?: { name?: string | null; username?: string | null } | null;
    tickets?: { name?: string | null; price?: number | null } | null;
  }> | null;
};

type SettlementFunctionRow = {
  id?: string;
  partnerId?: string;
  transferId?: string;
  amount?: number;
  currency?: string;
  settlementDate?: string;
};

type BankAccountRow = {
  bank_code: string | null;
  bank_name: string | null;
  account_number: string | null;
  account_holder: string | null;
  bank_verification_status: string | null;
};

const APPLICATION_EVENTS_SELECT = [
  "id",
  "title",
  "start_time",
  "max_participants",
  "parties!inner(partner_id)",
  "event_applications(id,event_id,user_id,status,payment_amount,refund_status,rejection_reason,created_at,paid_at,user_profiles(name,username),tickets(name,price))",
].join(",");

export async function fetchPartnerApplicationEvents(
  supabase: SupabaseClient,
  partnerId: string,
): Promise<PartnerApplicationEvent[]> {
  const { data, error } = await supabase
    .from("events")
    .select(APPLICATION_EVENTS_SELECT)
    .eq("parties.partner_id", partnerId)
    .order("start_time", { ascending: false })
    .returns<ApplicationEventRow[]>();

  if (error) throw error;

  return (data ?? []).map(normalizeApplicationEventRow);
}

export function normalizeApplicationEventRow(row: ApplicationEventRow): PartnerApplicationEvent {
  return {
    id: row.id,
    title: row.title ?? "이벤트",
    startsAt: row.start_time,
    maxParticipants: row.max_participants ?? 0,
    applications: (row.event_applications ?? [])
      .map((application) => ({
        id: application.id,
        eventId: application.event_id,
        userId: application.user_id,
        userName: application.user_profiles?.name ?? application.user_profiles?.username ?? "참가자",
        ticketName: application.tickets?.name ?? "티켓",
        amount: application.payment_amount ?? application.tickets?.price ?? 0,
        status: normalizeApplicationStatus(application.status),
        refundStatus: normalizeRefundStatus(application.refund_status),
        rejectionReason: application.rejection_reason,
        createdAt: application.created_at,
        paidAt: application.paid_at ?? null,
      }))
      .sort((a, b) => new Date(a.createdAt).getTime() - new Date(b.createdAt).getTime()),
  };
}

export function applicationTabForStatus(status: ApplicationStatus): ApplicationTab {
  if (status === "approved" || status === "paid") return "approved";
  if (status === "rejected" || status === "cancelled") return "rejected";
  return "pending";
}

export function filterApplications(applications: PartnerApplication[], tab: ApplicationTab): PartnerApplication[] {
  return applications.filter((application) => applicationTabForStatus(application.status) === tab);
}

export function isReviewableApplicationStatus(status: ApplicationStatus): boolean {
  return status === "pending" || status === "pending_review";
}

export function normalizeApplicationTabParam(value: string | null): ApplicationTab {
  const normalized = value?.trim().toLowerCase();
  if (normalized === "approved" || normalized === "확정") return "approved";
  if (normalized === "rejected" || normalized === "거절") return "rejected";
  return "pending";
}

export function applicationTabQueryValue(tab: ApplicationTab): string {
  if (tab === "approved") return "확정";
  if (tab === "rejected") return "거절";
  return "대기";
}

export function normalizeApplicationModeParam(value: string | null): ApplicationMode {
  const normalized = value?.trim().toLowerCase();
  if (normalized === "roster" || normalized === "명단" || normalized === "참가자명단" || normalized === "참가자 명단") {
    return "roster";
  }
  return "applications";
}

export function applicationModeQueryValue(mode: ApplicationMode): string {
  return mode === "roster" ? "명단" : "신청";
}

export async function reviewPartnerApplications(
  supabase: SupabaseClient,
  eventId: string,
  approvals: string[],
  rejections: Array<{ applicationId: string; reason: string }>,
): Promise<ApplicationReviewResult> {
  const { data, error } = await supabase.functions.invoke("partner-review-applications", {
    body: {
      event_id: eventId,
      approvals,
      rejections: rejections.map((item) => ({
        application_id: item.applicationId,
        reason: item.reason,
      })),
    },
  });

  if (error) throw new Error(error.message);

  const body = data as {
    approved?: string[];
    rejected?: string[];
    skipped_due_to_capacity?: string[];
    skipped_already_processed?: string[];
    remaining_slots_after?: number;
    error?: FunctionError;
  } | null;

  if (body?.error) throw new Error(body.error.message ?? "신청 처리를 완료하지 못했습니다.");

  return {
    approved: body?.approved ?? [],
    rejected: body?.rejected ?? [],
    skippedDueToCapacity: body?.skipped_due_to_capacity ?? [],
    skippedAlreadyProcessed: body?.skipped_already_processed ?? [],
    remainingSlotsAfter: body?.remaining_slots_after ?? 0,
  };
}

export function applicationReviewResultMessage(
  action: "approve" | "reject",
  result: ApplicationReviewResult,
): string {
  if (result.skippedDueToCapacity.length > 0) {
    return "정원이 가득 차 승인되지 않은 신청이 있습니다. 목록을 다시 확인해 주세요.";
  }
  if (result.skippedAlreadyProcessed.length > 0) {
    return "이미 처리된 신청이라 변경되지 않았습니다. 목록을 다시 확인해 주세요.";
  }
  if (action === "approve" && result.approved.length > 0) {
    return "신청을 승인했습니다.";
  }
  if (action === "reject" && result.rejected.length > 0) {
    return "신청을 거절했습니다. 결제/환불 상태는 목록에서 다시 확인해 주세요.";
  }
  return "처리된 신청이 없습니다. 목록을 다시 확인해 주세요.";
}

export async function fetchSettlementRows(supabase: SupabaseClient, partnerId: string): Promise<SettlementRow[]> {
  const { data, error } = await supabase.functions.invoke("settlement-query", {
    body: { type: "settlements", partner_id: partnerId },
  });

  if (error) throw new Error(error.message);

  const body = data as { settlements?: SettlementFunctionRow[]; error?: FunctionError } | null;
  if (body?.error) throw new Error(body.error.message ?? "정산 내역을 불러오지 못했습니다.");

  return (body?.settlements ?? []).map(normalizeSettlementRow);
}

export function normalizeSettlementRow(row: SettlementFunctionRow): SettlementRow {
  return {
    id: row.id ?? "settlement",
    partnerId: row.partnerId ?? "",
    transferId: row.transferId ?? null,
    amount: row.amount ?? 0,
    currency: row.currency ?? "KRW",
    settlementDate: row.settlementDate ?? "",
  };
}

export async function fetchBankAccount(supabase: SupabaseClient, partnerId: string): Promise<BankAccount | null> {
  const { data, error } = await supabase
    .from("partner_settlements")
    .select("bank_code,bank_name,account_number,account_holder,bank_verification_status")
    .eq("partner_id", partnerId)
    .maybeSingle<BankAccountRow>();

  if (error) throw error;
  if (!data) return null;

  return normalizeBankAccount(data);
}

export function normalizeBankAccount(row: BankAccountRow): BankAccount {
  return {
    bankCode: row.bank_code,
    bankName: row.bank_name ?? "은행 미등록",
    accountNumber: maskAccountNumber(row.account_number ?? ""),
    accountHolder: row.account_holder ?? "예금주 미등록",
    verificationStatus: row.bank_verification_status,
  };
}

export function bankStatusLabel(status: string | null): string {
  if (status === "verified" || status === "manual_review_approved") return "검증 완료";
  if (status === "manual_review_pending") return "검토 대기";
  if (status === "failed") return "검증 실패";
  return "검토 필요";
}

export async function upsertBankAccount(supabase: SupabaseClient, input: BankAccountInput): Promise<void> {
  const errors = validateBankAccountInput(input);
  if (errors.length > 0) throw new Error(errors[0]);

  const { data, error } = await supabase.functions.invoke("partner-manage-settlement", {
    body: {
      action: "upsert_bank_account",
      partner_id: input.partnerId,
      bank_code: input.bankCode,
      account_holder: input.accountHolder,
      account_number: input.accountNumber,
    },
  });

  if (error) throw new Error(error.message);
  if ((data as { error?: FunctionError } | null)?.error) {
    throw new Error((data as { error: FunctionError }).error.message ?? "계좌를 저장하지 못했습니다.");
  }
}

export function validateBankAccountInput(input: BankAccountInput): string[] {
  const errors: string[] = [];
  if (!input.bankCode.trim()) errors.push("은행을 선택해 주세요.");
  if (!input.accountHolder.trim()) errors.push("예금주를 입력해 주세요.");
  if (!/^[0-9]{10,16}$/.test(input.accountNumber.replace(/[-\s]/g, ""))) {
    errors.push("계좌번호는 숫자 10~16자리로 입력해 주세요.");
  }
  return errors;
}

export function maskAccountNumber(value: string): string {
  const digits = value.replace(/\D/g, "");
  if (digits.length <= 4) return digits ? `****${digits}` : "계좌 미등록";
  return `${digits.slice(0, 3)}-${"*".repeat(Math.max(4, digits.length - 7))}-${digits.slice(-4)}`;
}

function normalizeApplicationStatus(value: string): ApplicationStatus {
  const allowed: ApplicationStatus[] = ["pending", "pending_review", "approved", "rejected", "cancelled", "paid", "payment_failed", "payment_pending"];
  return allowed.includes(value as ApplicationStatus) ? (value as ApplicationStatus) : "pending";
}

function normalizeRefundStatus(value: string | null): RefundStatus {
  const allowed: RefundStatus[] = ["none", "requested", "completed", "failed"];
  return allowed.includes(value as RefundStatus) ? (value as RefundStatus) : "none";
}
