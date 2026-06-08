"use client";

import Link from "next/link";
import { Loader2, RotateCcw, Search, User } from "lucide-react";
import { useEffect, useMemo, useState } from "react";
import { cancelUserOrder, canRequestAutomaticRefund, fetchUserPurchases, statusCopy, type UserPurchase } from "@/lib/user-orders";
import { getSupabaseBrowserClient } from "@/lib/supabase";

type PurchaseState =
  | { status: "loading" }
  | { status: "config-error" }
  | { status: "anonymous" }
  | { status: "error"; message: string }
  | { status: "ready"; purchases: UserPurchase[] };

export function WebUserPurchases({ selectedId }: { selectedId?: string }) {
  const [state, setState] = useState<PurchaseState>({ status: "loading" });
  const [activeId, setActiveId] = useState(selectedId ?? "");
  const [actionMessage, setActionMessage] = useState<string | null>(null);
  const [pendingCancel, setPendingCancel] = useState(false);

  async function load() {
    const supabase = getSupabaseBrowserClient();
    if (!supabase) {
      setState({ status: "config-error" });
      return;
    }

    const { data, error } = await supabase.auth.getSession();
    if (error || !data.session?.user) {
      setState({ status: "anonymous" });
      return;
    }

    try {
      const purchases = await fetchUserPurchases(supabase);
      setState({ status: "ready", purchases });
      setActiveId((current) => current || selectedId || purchases[0]?.id || "");
    } catch (purchaseError) {
      setState({
        status: "error",
        message: purchaseError instanceof Error ? purchaseError.message : "구매 내역을 불러오지 못했습니다.",
      });
    }
  }

  useEffect(() => {
    void Promise.resolve().then(load);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  async function cancelOrder(purchase: UserPurchase) {
    const supabase = getSupabaseBrowserClient();
    if (!supabase || pendingCancel) return;

    setPendingCancel(true);
    setActionMessage(null);
    try {
      const message = await cancelUserOrder(supabase, purchase.eventId, "web_user_purchase_cancel");
      setActionMessage(message);
      await load();
    } catch (error) {
      setActionMessage(error instanceof Error ? error.message : "환불 요청을 처리하지 못했습니다.");
    } finally {
      setPendingCancel(false);
    }
  }

  if (state.status !== "ready") {
    return <PurchasesGate state={state} />;
  }

  const selected = state.purchases.find((purchase) => purchase.id === activeId) ?? state.purchases[0] ?? null;

  return (
    <div className="web-user-shell">
      <PurchasesHeader />
      <main className="wup-main">
        <h1 className="wup-title">구매 내역</h1>
        {state.purchases.length === 0 || !selected ? (
          <div className="wup-empty">
            <Search aria-hidden="true" />
            <h2>구매 내역이 없습니다</h2>
            <p>이벤트 신청과 결제를 완료하면 이곳에서 승인 상태와 환불 가능 여부를 확인할 수 있습니다.</p>
            <Link href="/">이벤트 둘러보기</Link>
          </div>
        ) : (
          <div className="wup-grid">
            <section className="wup-list" aria-label="구매 목록">
              {state.purchases.map((purchase) => (
                <PurchaseListItem
                  key={purchase.id}
                  purchase={purchase}
                  selected={purchase.id === selected.id}
                  onSelect={() => setActiveId(purchase.id)}
                />
              ))}
            </section>
            <PurchaseDetail purchase={selected} actionMessage={actionMessage} pendingCancel={pendingCancel} onCancel={() => cancelOrder(selected)} />
          </div>
        )}
      </main>
    </div>
  );
}

function PurchasesGate({ state }: { state: Exclude<PurchaseState, { status: "ready" }> }) {
  const title = state.status === "anonymous" ? "로그인이 필요해요" : state.status === "config-error" ? "설정이 필요해요" : state.status === "error" ? "구매 내역을 불러오지 못했어요" : "구매 내역을 불러오는 중";
  const description =
    state.status === "anonymous"
      ? "개인 결제 정보는 로그인 후 확인할 수 있습니다."
      : state.status === "config-error"
        ? "Supabase 공개 환경변수가 없어 로그인 상태를 확인할 수 없습니다."
        : state.status === "error"
          ? state.message
          : "잠시만 기다려 주세요.";

  return (
    <div className="web-user-shell">
      <PurchasesHeader />
      <main className="wup-gate">
        {state.status === "loading" ? <Loader2 className="spin" aria-hidden="true" /> : <User aria-hidden="true" />}
        <h1>{title}</h1>
        <p>{description}</p>
        {state.status === "anonymous" ? <Link href={`/login?next=${encodeURIComponent("/my/purchases")}`}>로그인하기</Link> : <Link href="/">홈으로 돌아가기</Link>}
      </main>
    </div>
  );
}

function PurchasesHeader() {
  return (
    <header className="wup-header">
      <div className="wup-header__inner">
        <Link className="minglit-logo" href="/" aria-label="Minglit 홈">
          <span className="minglit-logo__mark">M</span>
          <span className="minglit-logo__text">Minglit</span>
        </Link>
        <Link className="wup-search" href="/"><Search aria-hidden="true" />이벤트, 지역, 키워드 검색</Link>
        <div className="wup-header__spacer" />
        <Link className="wup-avatar" href="/my/purchases" aria-label="구매 내역"><User aria-hidden="true" /></Link>
      </div>
    </header>
  );
}

function PurchaseListItem({ purchase, selected, onSelect }: { purchase: UserPurchase; selected: boolean; onSelect: () => void }) {
  const status = statusCopy(purchase.status, purchase.refundStatus);

  return (
    <button className={`wup-item${selected ? " wup-item--selected" : ""}`} type="button" onClick={onSelect}>
      <span className="wup-item__top">
        <span className="wup-item__date">{formatShortDate(purchase.createdAt)}</span>
        <StatusChip label={status.label} tone={status.tone} />
      </span>
      <span className="wup-item__name">{purchase.eventTitle}</span>
      <span className="wup-item__bottom">
        <span className="wup-item__meta">{purchase.ticketName}</span>
        <span className="wup-item__amount">{formatPrice(purchase.amount)}</span>
      </span>
    </button>
  );
}

function PurchaseDetail({ purchase, actionMessage, pendingCancel, onCancel }: { purchase: UserPurchase; actionMessage: string | null; pendingCancel: boolean; onCancel: () => void }) {
  const status = statusCopy(purchase.status, purchase.refundStatus);
  const refundable = useMemo(() => canRequestAutomaticRefund(purchase), [purchase]);

  return (
    <section className="wup-detail" aria-label={`${purchase.eventTitle} 상세`}>
      <div className="wup-hero">
        <div className="wup-hero__thumb">
          {purchase.eventImageUrl ? (
            // eslint-disable-next-line @next/next/no-img-element
            <img src={purchase.eventImageUrl} alt="" />
          ) : (
            "Minglit"
          )}
        </div>
        <div className="wup-hero__text">
          <Link className="wup-hero__title" href={`/events/${purchase.eventId}`}>{purchase.eventTitle}</Link>
          <div className="wup-hero__meta">{formatDateRange(purchase.startsAt, purchase.endsAt)}</div>
          <div className="wup-hero__sub">{purchase.locationName} · {purchase.partnerName}</div>
        </div>
        <StatusChip label={status.label} tone={status.tone} />
      </div>
      <div className="wup-divider" />
      <section>
        <h2 className="wup-sec__title">신청 상태</h2>
        <div className="wup-tl">
          <TimelineStep label="신청" done />
          <TimelineStep label="결제" done={["paid", "approved", "pending", "pending_review"].includes(purchase.status)} current={purchase.status === "payment_pending"} fail={purchase.status === "payment_failed"} />
          <TimelineStep label="승인" done={purchase.status === "approved"} current={["paid", "pending", "pending_review"].includes(purchase.status)} fail={purchase.status === "rejected"} />
          <TimelineStep label="입장" done={false} />
        </div>
        <p className="wup-tl-note">이벤트 당일 예약자 이름으로 입장합니다. QR/입장권 화면은 웹 MVP 범위에서 제외됩니다.</p>
      </section>
      <div className="wup-divider" />
      <section>
        <h2 className="wup-sec__title">결제 내역</h2>
        <dl className="wup-kv">
          <div><dt>티켓</dt><dd>{purchase.ticketName}</dd></div>
          <div><dt>금액</dt><dd>{formatPrice(purchase.amount)}</dd></div>
          <div><dt>결제 ID</dt><dd>{purchase.paymentId ?? "승인 대기"}</dd></div>
          <div><dt>장소</dt><dd>{purchase.locationAddress}</dd></div>
        </dl>
      </section>
      <section className="wup-refund">
        <h2>환불 정책</h2>
        <p>결제 후 3시간 이내 또는 이벤트 시작 7일 전까지 100% 자동 환불됩니다. 파트너 귀책 취소와 승인 거절은 전액 자동 환불 대상입니다.</p>
        {refundable ? (
          <button className="wup-btn wup-btn--refund" type="button" disabled={pendingCancel} onClick={onCancel}>
            {pendingCancel ? <Loader2 className="spin" aria-hidden="true" /> : <RotateCcw aria-hidden="true" />}
            환불 요청
          </button>
        ) : (
          <div className="wup-refund-pending">
            자동 환불 가능 기간이 아니거나 이미 환불 상태가 변경됐습니다. 파트너 환불 요청 Track 2는 backend EF가 추가되면 연결됩니다.
          </div>
        )}
        {actionMessage ? <div className="wup-action-message" role="status">{actionMessage}</div> : null}
      </section>
    </section>
  );
}

function TimelineStep({ label, done = false, current = false, fail = false }: { label: string; done?: boolean; current?: boolean; fail?: boolean }) {
  const stateClass = fail ? "wup-tl__step--fail" : done ? "wup-tl__step--done" : current ? "wup-tl__step--now" : "wup-tl__step--off";

  return (
    <div className={`wup-tl__step ${stateClass}`}>
      <div className="wup-tl__label">{label}</div>
    </div>
  );
}

function StatusChip({ label, tone }: { label: string; tone: string }) {
  return <span className={`wup-chip wup-chip--${tone}`}>{label}</span>;
}

function formatPrice(price: number): string {
  return price === 0 ? "무료" : `${price.toLocaleString("ko-KR")}원`;
}

function formatShortDate(value: string): string {
  return new Intl.DateTimeFormat("ko-KR", { month: "long", day: "numeric", timeZone: "Asia/Seoul" }).format(new Date(value));
}

function formatDateRange(start: string, end: string): string {
  const startDate = new Date(start);
  const endDate = new Date(end);
  const day = new Intl.DateTimeFormat("ko-KR", { month: "long", day: "numeric", weekday: "short", timeZone: "Asia/Seoul" }).format(startDate);
  const time = new Intl.DateTimeFormat("ko-KR", { hour: "numeric", minute: "2-digit", timeZone: "Asia/Seoul" });

  return `${day} ${time.format(startDate)} - ${time.format(endDate)}`;
}
