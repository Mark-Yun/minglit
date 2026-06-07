"use client";

import Link from "next/link";
import { useRouter, useSearchParams } from "next/navigation";
import { Banknote, Check, ClipboardList, Loader2, Printer, ShieldAlert, XCircle } from "lucide-react";
import { useEffect, useState } from "react";

import { PartnerConsoleShell } from "@/components/partner-console";
import {
  canEditPartnerSettlements,
  canManagePartnerApplications,
  canViewPartnerSettlements,
  resolvePartnerDashboardGate,
  type ManagedPartner,
} from "@/lib/partner-dashboard";
import {
  fetchBankAccount,
  fetchPartnerApplicationEvents,
  fetchSettlementRows,
  filterApplications,
  isReviewableApplicationStatus,
  applicationModeQueryValue,
  applicationReviewResultMessage,
  applicationTabQueryValue,
  normalizeApplicationModeParam,
  normalizeApplicationTabParam,
  reviewPartnerApplications,
  upsertBankAccount,
  validateBankAccountInput,
  type ApplicationMode,
  type ApplicationTab,
  type BankAccount,
  bankStatusLabel,
  type PartnerApplication,
  type PartnerApplicationEvent,
  type SettlementRow,
} from "@/lib/partner-operations";
import { getSupabaseBrowserClient } from "@/lib/supabase";

type GateState =
  | { status: "loading" }
  | { status: "config-error" }
  | { status: "error"; message: string }
  | { status: "no-access"; email: string }
  | { status: "ready"; partner: ManagedPartner; email: string };

type ApplicationsState =
  | { status: "loading" }
  | { status: "error"; message: string }
  | { status: "ready"; events: PartnerApplicationEvent[] };

type SettlementsState =
  | { status: "loading" }
  | { status: "error"; message: string }
  | { status: "ready"; settlements: SettlementRow[]; bankAccount: BankAccount | null };

const tabs: Array<{ key: ApplicationTab; label: string }> = [
  { key: "pending", label: "대기" },
  { key: "approved", label: "확정" },
  { key: "rejected", label: "거절" },
];

const banks = [
  { code: "kb", name: "KB국민은행" },
  { code: "shinhan", name: "신한은행" },
  { code: "hana", name: "하나은행" },
  { code: "woori", name: "우리은행" },
  { code: "ibk", name: "IBK기업은행" },
  { code: "nh", name: "NH농협은행" },
  { code: "kakao", name: "카카오뱅크" },
  { code: "toss", name: "토스뱅크" },
  { code: "kbank", name: "케이뱅크" },
];

export function PartnerApplicationsPage() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const [gate, setGate] = useState<GateState>({ status: "loading" });
  const [state, setState] = useState<ApplicationsState>({ status: "loading" });
  const [selectedApplicationId, setSelectedApplicationId] = useState<string>("");
  const [rejecting, setRejecting] = useState<PartnerApplication | null>(null);
  const [message, setMessage] = useState<string>("");
  const [submittingId, setSubmittingId] = useState<string | null>(null);
  const events = state.status === "ready" ? state.events : [];
  const tab = normalizeApplicationTabParam(searchParams.get("tab"));
  const mode = normalizeApplicationModeParam(searchParams.get("mode"));
  const selectedEvent = events.find((event) => event.id === searchParams.get("event")) ?? events[0] ?? null;
  const visible = selectedEvent ? filterApplications(selectedEvent.applications, tab) : [];
  const roster = selectedEvent
    ? [...filterApplications(selectedEvent.applications, "approved")].sort((left, right) => left.userName.localeCompare(right.userName, "ko-KR"))
    : [];
  const selectedApplication = visible.find((application) => application.id === selectedApplicationId) ?? visible[0] ?? null;
  const counts = {
    pending: selectedEvent ? filterApplications(selectedEvent.applications, "pending").length : 0,
    approved: selectedEvent ? filterApplications(selectedEvent.applications, "approved").length : 0,
    rejected: selectedEvent ? filterApplications(selectedEvent.applications, "rejected").length : 0,
  };

  useEffect(() => {
    let cancelled = false;

    async function load() {
      const supabase = getSupabaseBrowserClient();
      if (!supabase) {
        setGate({ status: "config-error" });
        return;
      }

      const resolved = await resolvePartnerDashboardGate(supabase, "/dashboard/applications");
      if (cancelled) return;
      if (resolved.status === "anonymous") {
        router.replace(resolved.loginRedirect);
        return;
      }
      setGate(resolved);
      if (resolved.status !== "ready") return;
      if (!canManagePartnerApplications(resolved.partner)) {
        setState({ status: "error", message: "신청 관리 권한이 없습니다. 파트너 소유자에게 권한을 요청해 주세요." });
        return;
      }

      try {
        const events = await fetchPartnerApplicationEvents(supabase, resolved.partner.id);
        if (cancelled) return;
        setState({ status: "ready", events });
      } catch (error) {
        if (!cancelled) setState({ status: "error", message: error instanceof Error ? error.message : "신청 데이터를 불러오지 못했습니다." });
      }
    }

    void load();
    return () => {
      cancelled = true;
    };
  }, [router]);

  useEffect(() => {
    if (gate.status !== "ready" || state.status !== "ready") return;
    if (!selectedEvent) return;

    const params = new URLSearchParams(searchParams.toString());
    params.set("event", selectedEvent.id);
    params.set("tab", applicationTabQueryValue(tab));
    params.set("mode", applicationModeQueryValue(mode));
    const nextQuery = params.toString();
    const currentQuery = searchParams.toString();
    if (nextQuery !== currentQuery) {
      router.replace(`/dashboard/applications?${nextQuery}`, { scroll: false });
    }
  }, [gate.status, mode, router, searchParams, selectedEvent, state.status, tab]);

  async function submitReview(application: PartnerApplication, action: "approve" | "reject", reason = "") {
    const supabase = getSupabaseBrowserClient();
    if (!supabase) return;

    setSubmittingId(application.id);
    setMessage("");

    try {
      const result = await reviewPartnerApplications(
        supabase,
        application.eventId,
        action === "approve" ? [application.id] : [],
        action === "reject" ? [{ applicationId: application.id, reason }] : [],
      );
      setMessage(applicationReviewResultMessage(action, result));
      if (gate.status === "ready") {
        const events = await fetchPartnerApplicationEvents(supabase, gate.partner.id);
        setState({ status: "ready", events });
      }
      setRejecting(null);
    } catch (error) {
      setMessage(error instanceof Error ? error.message : "신청 처리를 완료하지 못했습니다.");
    } finally {
      setSubmittingId(null);
    }
  }

  if (gate.status !== "ready") {
    return <OperationsFrame gate={gate} mobileTitle="신청" />;
  }

  function replaceApplicationQuery(next: { eventId?: string; tab?: ApplicationTab; mode?: ApplicationMode }) {
    const eventId = next.eventId ?? selectedEvent?.id;
    if (!eventId) return;

    const params = new URLSearchParams(searchParams.toString());
    params.set("event", eventId);
    params.set("tab", applicationTabQueryValue(next.tab ?? tab));
    params.set("mode", applicationModeQueryValue(next.mode ?? mode));
    router.replace(`/dashboard/applications?${params.toString()}`, { scroll: false });
  }

  return (
    <PartnerConsoleShell accountLabel={gate.partner.name} accountSub={gate.email} mobileTitle="신청">
      <section className="wpo-page">
        <PageHeader title="신청 관리" subtitle="대기 신청을 검토하고 확정 참가자 명단을 확인합니다." />

        {state.status === "loading" ? <LoadingPanel label="신청을 불러오고 있습니다." /> : null}
        {state.status === "error" ? <ErrorPanel message={state.message} /> : null}

        {state.status === "ready" ? (
          <>
            <div className="wpa-toolbar">
              <label className="wpo-field">
                <span>이벤트</span>
                <select value={selectedEvent?.id ?? ""} onChange={(event) => replaceApplicationQuery({ eventId: event.target.value })}>
                  {events.map((event) => (
                    <option key={event.id} value={event.id}>{event.title}</option>
                  ))}
                </select>
              </label>
              <div className="wpo-segment" role="tablist" aria-label="신청 화면 모드">
                <button type="button" className={mode === "applications" ? "is-active" : ""} onClick={() => replaceApplicationQuery({ mode: "applications" })}>
                  신청 관리
                </button>
                <button type="button" className={mode === "roster" ? "is-active" : ""} onClick={() => replaceApplicationQuery({ mode: "roster" })}>
                  참가자 명단
                </button>
              </div>
              <div className="wpo-segment" role="tablist" aria-label="신청 상태">
                {tabs.map((item) => (
                  <button key={item.key} type="button" className={tab === item.key ? "is-active" : ""} onClick={() => replaceApplicationQuery({ tab: item.key })}>
                    {item.label} {counts[item.key]}
                  </button>
                ))}
              </div>
            </div>

            {message ? <div className="wpo-toast" role="status">{message}</div> : null}

            {mode === "roster" ? (
              <RosterPanel event={selectedEvent} applications={roster} />
            ) : (
              <div className="wpa-grid">
                <section className="wpo-panel">
                  <h2>신청 목록</h2>
                  {visible.length === 0 ? (
                    <EmptyPanel icon={<ClipboardList aria-hidden="true" />} title="표시할 신청이 없습니다" description="이벤트 또는 상태 탭을 바꾸면 다른 신청을 볼 수 있습니다." />
                  ) : (
                    <div className="wpa-list">
                      {visible.map((application) => (
                        <button
                          key={application.id}
                          type="button"
                          className={`wpa-application${selectedApplication?.id === application.id ? " is-active" : ""}`}
                          onClick={() => setSelectedApplicationId(application.id)}
                        >
                          <span>
                            <strong>{application.userName}</strong>
                            <small>{application.ticketName} · {formatCurrency(application.amount)}</small>
                          </span>
                          <StatusChip label={applicationStatusLabel(application.status)} />
                        </button>
                      ))}
                    </div>
                  )}
                </section>

                <ApplicationDetail
                  application={selectedApplication}
                  submittingId={submittingId}
                  onApprove={(application) => submitReview(application, "approve")}
                  onReject={(application) => setRejecting(application)}
                />
              </div>
            )}
          </>
        ) : null}
      </section>

      {rejecting ? (
        <RejectDialog
          application={rejecting}
          submitting={submittingId === rejecting.id}
          onCancel={() => setRejecting(null)}
          onSubmit={(reason) => submitReview(rejecting, "reject", reason)}
        />
      ) : null}
    </PartnerConsoleShell>
  );
}

function RosterPanel({ event, applications }: { event: PartnerApplicationEvent | null; applications: PartnerApplication[] }) {
  return (
    <section className="wpo-panel wpa-roster">
      <div className="wpa-roster__header">
        <div>
          <h2>참가자 명단</h2>
          <p>{event ? `${event.title} · 확정 ${applications.length}명` : "선택된 이벤트가 없습니다."}</p>
        </div>
        <button type="button" className="wpo-secondary" onClick={() => window.print()} disabled={!event || applications.length === 0}>
          <Printer aria-hidden="true" />
          명단 인쇄
        </button>
      </div>
      {applications.length === 0 ? (
        <EmptyPanel icon={<ClipboardList aria-hidden="true" />} title="확정 참가자가 없습니다" description="승인 완료된 신청이 생기면 명단에 표시됩니다." />
      ) : (
        <div className="wpa-roster__table-wrap">
          <table className="wpa-roster__table">
            <thead>
              <tr>
                <th>입장</th>
                <th>이름</th>
                <th>티켓</th>
                <th>결제 금액</th>
                <th>상태</th>
              </tr>
            </thead>
            <tbody>
              {applications.map((application) => (
                <tr key={application.id}>
                  <td><span className="wpa-roster__check" aria-hidden="true" /></td>
                  <td>{application.userName}</td>
                  <td>{application.ticketName}</td>
                  <td>{formatCurrency(application.amount)}</td>
                  <td>{applicationStatusLabel(application.status)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </section>
  );
}

export function PartnerSettlementsPage() {
  const router = useRouter();
  const [gate, setGate] = useState<GateState>({ status: "loading" });
  const [state, setState] = useState<SettlementsState>({ status: "loading" });
  const [message, setMessage] = useState("");
  const [submitting, setSubmitting] = useState(false);
  const [form, setForm] = useState({ bankCode: "kb", accountHolder: "", accountNumber: "" });

  useEffect(() => {
    let cancelled = false;

    async function load() {
      const supabase = getSupabaseBrowserClient();
      if (!supabase) {
        setGate({ status: "config-error" });
        return;
      }

      const resolved = await resolvePartnerDashboardGate(supabase, "/dashboard/settlements");
      if (cancelled) return;
      if (resolved.status === "anonymous") {
        router.replace(resolved.loginRedirect);
        return;
      }
      setGate(resolved);
      if (resolved.status !== "ready") return;
      if (!canViewPartnerSettlements(resolved.partner)) {
        setState({ status: "error", message: "정산 조회 권한이 없습니다. 파트너 소유자에게 권한을 요청해 주세요." });
        return;
      }

      try {
        const [settlements, bankAccount] = await Promise.all([
          fetchSettlementRows(supabase, resolved.partner.id),
          fetchBankAccount(supabase, resolved.partner.id),
        ]);
        if (!cancelled) setState({ status: "ready", settlements, bankAccount });
      } catch (error) {
        if (!cancelled) setState({ status: "error", message: error instanceof Error ? error.message : "정산 데이터를 불러오지 못했습니다." });
      }
    }

    void load();
    return () => {
      cancelled = true;
    };
  }, [router]);

  async function submitBankAccount(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (gate.status !== "ready") return;
    if (!canEditPartnerSettlements(gate.partner)) {
      setMessage("정산 계좌 수정 권한이 없습니다. 파트너 소유자에게 권한을 요청해 주세요.");
      return;
    }
    const supabase = getSupabaseBrowserClient();
    if (!supabase) return;

    const input = {
      partnerId: gate.partner.id,
      bankCode: form.bankCode,
      accountHolder: form.accountHolder,
      accountNumber: form.accountNumber,
    };
    const errors = validateBankAccountInput(input);
    if (errors.length > 0) {
      setMessage(errors[0]);
      return;
    }

    setSubmitting(true);
    setMessage("");
    try {
      await upsertBankAccount(supabase, input);
      const bankAccount = await fetchBankAccount(supabase, gate.partner.id);
      const settlements = state.status === "ready" ? state.settlements : [];
      setState({ status: "ready", settlements, bankAccount });
      setMessage("계좌 검토 요청이 접수됐습니다.");
    } catch (error) {
      setMessage(error instanceof Error ? error.message : "계좌를 저장하지 못했습니다.");
    } finally {
      setSubmitting(false);
    }
  }

  if (gate.status !== "ready") {
    return <OperationsFrame gate={gate} mobileTitle="정산" />;
  }

  const settlements = state.status === "ready" ? state.settlements : [];
  const total = settlements.reduce((sum, row) => sum + row.amount, 0);
  const canEditSettlementAccount = canEditPartnerSettlements(gate.partner);

  return (
    <PartnerConsoleShell accountLabel={gate.partner.name} accountSub={gate.email} mobileTitle="정산">
      <section className="wpo-page">
        <PageHeader title="정산 관리" subtitle="정산 예정 내역과 지급 계좌 검토 상태를 확인합니다." />

        {state.status === "loading" ? <LoadingPanel label="정산을 불러오고 있습니다." /> : null}
        {state.status === "error" ? <ErrorPanel message={state.message} /> : null}

        {state.status === "ready" ? (
          <>
            <div className="wps-summary">
              <SummaryCard label="정산 건수" value={`${settlements.length}건`} />
              <SummaryCard label="정산 합계" value={formatCurrency(total)} />
              <SummaryCard label="계좌 상태" value={state.bankAccount ? bankStatusLabel(state.bankAccount.verificationStatus) : "미등록"} />
            </div>

            <section className="wpo-panel">
              <h2>정산 내역</h2>
              {settlements.length === 0 ? (
                <EmptyPanel icon={<Banknote aria-hidden="true" />} title="정산 내역이 없습니다" description="이벤트 완료 후 정산 데이터가 생성되면 이곳에 표시됩니다." />
              ) : (
                <div className="wps-table">
                  {settlements.map((settlement) => (
                    <article key={settlement.id} className="wps-row">
                      <div>
                        <strong>{settlement.id}</strong>
                        <span>{settlement.settlementDate || "일정 미정"} · {settlement.transferId ?? "transfer 미연결"}</span>
                      </div>
                      <b>{formatCurrency(settlement.amount, settlement.currency)}</b>
                    </article>
                  ))}
                </div>
              )}
            </section>

            <section className="wpo-panel wps-account">
              <h2>정산 계좌</h2>
              {state.bankAccount ? (
                <div className="wps-account__current">
                  <span>{state.bankAccount.bankName}</span>
                  <strong>{state.bankAccount.accountNumber}</strong>
                  <small>{state.bankAccount.accountHolder} · {bankStatusLabel(state.bankAccount.verificationStatus)}</small>
                </div>
              ) : (
                <p className="wpo-muted">
                  {canEditSettlementAccount ? "등록된 계좌가 없습니다. 정산금을 받을 계좌를 등록해 주세요." : "등록된 계좌가 없습니다."}
                </p>
              )}

              {canEditSettlementAccount ? (
                <form className="wps-bank-form" onSubmit={submitBankAccount}>
                  <label className="wpo-field">
                    <span>은행</span>
                    <select value={form.bankCode} onChange={(event) => setForm({ ...form, bankCode: event.target.value })}>
                      {banks.map((bank) => <option key={bank.code} value={bank.code}>{bank.name}</option>)}
                    </select>
                  </label>
                  <label className="wpo-field">
                    <span>예금주</span>
                    <input value={form.accountHolder} onChange={(event) => setForm({ ...form, accountHolder: event.target.value })} />
                  </label>
                  <label className="wpo-field">
                    <span>계좌번호</span>
                    <input inputMode="numeric" value={form.accountNumber} onChange={(event) => setForm({ ...form, accountNumber: event.target.value })} />
                  </label>
                  <button className="wpo-primary" type="submit" disabled={submitting}>
                    {submitting ? <Loader2 aria-hidden="true" /> : <Check aria-hidden="true" />}
                    계좌 검토 요청
                  </button>
                </form>
              ) : null}
              {message ? <div className="wpo-toast" role="status">{message}</div> : null}
            </section>
          </>
        ) : null}
      </section>
    </PartnerConsoleShell>
  );
}

function OperationsFrame({ gate, mobileTitle }: { gate: GateState; mobileTitle: string }) {
  return (
    <PartnerConsoleShell accountLabel="확인 중" accountSub="Minglit Partner" mobileTitle={mobileTitle}>
      {gate.status === "loading" ? (
        <LoadingPanel label="권한을 확인하고 있습니다." />
      ) : gate.status === "no-access" ? (
        <EmptyPanel icon={<ShieldAlert aria-hidden="true" />} title="파트너 권한이 없어요" description={`${gate.email} 계정에 연결된 파트너 권한을 찾지 못했습니다.`} />
      ) : (
        <ErrorPanel message={gate.status === "config-error" ? "Supabase 공개 환경변수가 설정되지 않았습니다." : gate.status === "error" ? gate.message : "다시 시도해 주세요."} />
      )}
    </PartnerConsoleShell>
  );
}

function PageHeader({ title, subtitle }: { title: string; subtitle: string }) {
  return (
    <header className="wpo-header">
      <h1>{title}</h1>
      <p>{subtitle}</p>
    </header>
  );
}

function ApplicationDetail({
  application,
  submittingId,
  onApprove,
  onReject,
}: {
  application: PartnerApplication | null;
  submittingId: string | null;
  onApprove: (application: PartnerApplication) => void;
  onReject: (application: PartnerApplication) => void;
}) {
  if (!application) {
    return (
      <section className="wpo-panel">
        <EmptyPanel icon={<ClipboardList aria-hidden="true" />} title="신청을 선택해 주세요" description="목록에서 신청자를 선택하면 상세 정보와 처리 액션이 표시됩니다." />
      </section>
    );
  }

  const isPending = isReviewableApplicationStatus(application.status);
  const isSubmitting = submittingId === application.id;

  return (
    <section className="wpo-panel wpa-detail">
      <h2>신청 상세</h2>
      <dl>
        <div><dt>신청자</dt><dd>{application.userName}</dd></div>
        <div><dt>티켓</dt><dd>{application.ticketName}</dd></div>
        <div><dt>결제금액</dt><dd>{formatCurrency(application.amount)}</dd></div>
        <div><dt>환불 상태</dt><dd>{refundStatusLabel(application.refundStatus)}</dd></div>
        <div><dt>신청 시각</dt><dd>{formatDate(application.createdAt)}</dd></div>
      </dl>
      {application.rejectionReason ? <p className="wpa-reason">거절 사유: {application.rejectionReason}</p> : null}
      {isPending ? (
        <div className="wpa-actions">
          <button className="wpo-primary" type="button" disabled={isSubmitting} onClick={() => onApprove(application)}>
            {isSubmitting ? <Loader2 aria-hidden="true" /> : <Check aria-hidden="true" />}
            승인
          </button>
          <button className="wpo-danger" type="button" disabled={isSubmitting} onClick={() => onReject(application)}>
            <XCircle aria-hidden="true" />
            거절
          </button>
        </div>
      ) : null}
    </section>
  );
}

function RejectDialog({
  application,
  submitting,
  onCancel,
  onSubmit,
}: {
  application: PartnerApplication;
  submitting: boolean;
  onCancel: () => void;
  onSubmit: (reason: string) => void;
}) {
  const [reason, setReason] = useState("");
  return (
    <div className="wpo-dialog" role="dialog" aria-modal="true" aria-labelledby="reject-title">
      <div className="wpo-dialog__panel">
        <h2 id="reject-title">{application.userName} 신청을 거절할까요?</h2>
        <p>거절 후 결제/환불 처리는 서버 결과를 다시 조회해 확인합니다.</p>
        <textarea value={reason} onChange={(event) => setReason(event.target.value)} placeholder="거절 사유" />
        <div className="wpo-dialog__actions">
          <button type="button" onClick={onCancel}>취소</button>
          <button type="button" disabled={submitting || !reason.trim()} onClick={() => onSubmit(reason.trim())}>거절 확정</button>
        </div>
      </div>
    </div>
  );
}

function SummaryCard({ label, value }: { label: string; value: string }) {
  return (
    <article className="wps-summary-card">
      <span>{label}</span>
      <strong>{value}</strong>
    </article>
  );
}

function LoadingPanel({ label }: { label: string }) {
  return <section className="wpo-panel wpo-loading"><Loader2 aria-hidden="true" />{label}</section>;
}

function ErrorPanel({ message }: { message: string }) {
  return <section className="wpo-panel wpo-error"><ShieldAlert aria-hidden="true" />{message}</section>;
}

function EmptyPanel({ icon, title, description }: { icon: React.ReactNode; title: string; description: string }) {
  return (
    <div className="wpo-empty">
      <div>{icon}</div>
      <h2>{title}</h2>
      <p>{description}</p>
      <Link href="/dashboard">홈으로 돌아가기</Link>
    </div>
  );
}

function StatusChip({ label }: { label: string }) {
  return <span className="wpo-chip">{label}</span>;
}

function applicationStatusLabel(status: string): string {
  if (status === "approved" || status === "paid") return "확정";
  if (status === "rejected") return "거절";
  if (status === "cancelled") return "취소";
  if (status === "payment_failed") return "결제 실패";
  if (status === "payment_pending") return "결제 대기";
  return "대기";
}

function refundStatusLabel(status: string): string {
  if (status === "completed") return "환불 완료";
  if (status === "requested") return "환불 요청";
  if (status === "failed") return "환불 실패";
  return "해당 없음";
}

function formatCurrency(amount: number, currency = "KRW"): string {
  if (currency !== "KRW") return `${amount.toLocaleString("ko-KR")} ${currency}`;
  return `${amount.toLocaleString("ko-KR")}원`;
}

function formatDate(value: string): string {
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return "일정 미정";
  return new Intl.DateTimeFormat("ko-KR", { dateStyle: "medium", timeStyle: "short", timeZone: "Asia/Seoul" }).format(date);
}
