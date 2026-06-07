"use client";

import Link from "next/link";
import { AlertCircle, CalendarDays, Check, CreditCard, Loader2, MapPin, ShieldCheck, User } from "lucide-react";
import { useEffect, useMemo, useState } from "react";
import type { PublicEvent, Ticket } from "@/lib/events";
import { createCheckoutOrder, verifyCheckoutPayment } from "@/lib/user-orders";
import { getSupabaseBrowserClient } from "@/lib/supabase";

type AuthState = { status: "loading" } | { status: "config-error" } | { status: "anonymous" } | { status: "ready" };
type CheckoutState =
  | { status: "idle" }
  | { status: "creating" }
  | { status: "payment"; applicationId: string; merchantUid: string }
  | { status: "done" }
  | { status: "error"; message: string };

export function WebUserCheckout({ event, ticket }: { event: PublicEvent; ticket: Ticket }) {
  const [authState, setAuthState] = useState<AuthState>({ status: "loading" });
  const [agreed, setAgreed] = useState(false);
  const [checkout, setCheckout] = useState<CheckoutState>({ status: "idle" });
  const total = ticket.price;

  useEffect(() => {
    let cancelled = false;

    async function resolveAuth() {
      const supabase = getSupabaseBrowserClient();
      if (!supabase) {
        setAuthState({ status: "config-error" });
        return;
      }

      const { data, error } = await supabase.auth.getSession();
      if (cancelled) return;
      if (error || !data.session?.user) {
        setAuthState({ status: "anonymous" });
        return;
      }

      setAuthState({ status: "ready" });
    }

    void resolveAuth();

    return () => {
      cancelled = true;
    };
  }, []);

  const helper = useMemo(() => {
    if (authState.status === "loading") return "로그인 상태를 확인하고 있습니다.";
    if (authState.status === "anonymous") return "로그인 후 같은 주문으로 돌아옵니다.";
    if (authState.status === "config-error") return "Supabase 공개 환경변수가 없어 결제를 시작할 수 없습니다.";
    if (!agreed) return "필수 약관과 환불 정책에 동의해 주세요.";
    if (checkout.status === "creating") return "주문을 생성하고 있습니다.";
    if (checkout.status === "payment") return "Portone V2 결제창 완료 후 결제 식별자를 입력해 검증합니다.";
    return "결제 후에도 파트너 승인 전까지는 승인 대기 상태입니다.";
  }, [agreed, authState.status, checkout.status]);

  async function startPayment() {
    const supabase = getSupabaseBrowserClient();
    if (!supabase || authState.status !== "ready" || !agreed) return;

    setCheckout({ status: "creating" });

    try {
      const order = await createCheckoutOrder(supabase, event.id, ticket.id);
      if (!order.requiresPayment || order.amount === 0) {
        setCheckout({ status: "done" });
        return;
      }

      setCheckout({
        status: "payment",
        applicationId: order.applicationId,
        merchantUid: order.applicationId,
      });
    } catch (error) {
      setCheckout({ status: "error", message: error instanceof Error ? error.message : "주문 생성에 실패했습니다." });
    }
  }

  async function verifyPayment(formData: FormData) {
    const supabase = getSupabaseBrowserClient();
    const impUid = String(formData.get("imp_uid") ?? "").trim();
    const merchantUid = String(formData.get("merchant_uid") ?? "").trim();

    if (!supabase || !impUid || !merchantUid) {
      setCheckout({ status: "error", message: "결제 식별자를 입력해 주세요." });
      return;
    }

    try {
      await verifyCheckoutPayment(supabase, impUid, merchantUid);
      setCheckout({ status: "done" });
    } catch (error) {
      setCheckout({ status: "error", message: error instanceof Error ? error.message : "결제 검증에 실패했습니다." });
    }
  }

  if (checkout.status === "done") {
    return (
      <div className="web-user-shell">
        <CheckoutHeader />
        <main className="wuc-done">
          <div className="wuc-done__icon"><Check aria-hidden="true" /></div>
          <span className="wuc-chip wuc-chip--info">파트너 승인 대기</span>
          <h1>신청이 접수됐습니다</h1>
          <p>결제는 참여 확정이 아닙니다. 파트너가 승인하면 확정되고, 거절되면 전액 자동 환불됩니다.</p>
          <div className="wuc-done__actions">
            <Link className="wuc-btn wuc-btn--primary" href="/my/purchases">구매내역 보기</Link>
            <Link className="wuc-btn wuc-btn--secondary" href={`/events/${event.id}`}>이벤트로 돌아가기</Link>
          </div>
        </main>
      </div>
    );
  }

  return (
    <div className="web-user-shell">
      <CheckoutHeader />
      <main className="wuc-main">
        <section className="wuc-col" aria-labelledby="checkout-title">
          <h1 id="checkout-title" className="wuc-page-title">신청 · 결제</h1>
          <div className="wuc-banner">
            <AlertCircle aria-hidden="true" />
            <div>
              <div className="wuc-banner__title">결제는 참여 확정이 아닙니다</div>
              <p className="wuc-banner__sub">파트너 승인 후 최종 확정됩니다. 거절되면 결제 금액은 전액 자동 환불됩니다.</p>
            </div>
          </div>

          <section className="wuc-card">
            <h2 className="wuc-card__title">주문 정보</h2>
            <div className="wuc-event">
              <EventThumb event={event} />
              <div className="wuc-event__body">
                <div className="wuc-event__name">{event.title}</div>
                <div className="wuc-event__meta"><CalendarDays aria-hidden="true" />{formatDateRange(event.startsAt, event.endsAt)}</div>
                <div className="wuc-event__meta"><MapPin aria-hidden="true" />{event.locationName}</div>
              </div>
            </div>
            <div className="wuc-ticket-row">
              <div>
                <div className="wuc-ticket-row__name">{ticket.name}</div>
                <div className="wuc-ticket-row__qty">1매 · {ticket.description ?? "표준 티켓"}</div>
              </div>
              <Link className="wuc-link" href={`/events/${event.id}`}>변경</Link>
              <div className="wuc-ticket-row__price">{formatPrice(total)}</div>
            </div>
          </section>

          <section className="wuc-identity">
            <div className="wuc-identity__icon"><ShieldCheck aria-hidden="true" /></div>
            <div>
              <div className="wuc-identity__title">본인인증은 결제 단계에서 확인합니다</div>
              <p className="wuc-identity__sub">Portone V2 웹 인증이 연결되면 최초 1회 인증 후 결제를 이어갑니다.</p>
            </div>
          </section>

          <section className="wuc-card">
            <h2 className="wuc-card__title">약관 및 환불 정책</h2>
            <label className={`wuc-check wuc-check--all${agreed ? " wuc-check--checked" : ""}`}>
              <input type="checkbox" checked={agreed} onChange={(eventValue) => setAgreed(eventValue.currentTarget.checked)} />
              <span className="wuc-check__box" aria-hidden="true"><Check /></span>
              필수 약관과 환불 정책에 모두 동의합니다
              <span className="wuc-check__req">필수</span>
            </label>
            <div className="wuc-consent__divider" />
            <div className="wuc-refund-box">
              <span className="wuc-refund-box__head">자동 환불 (전액)</span>
              파트너 귀책 취소·승인 거절 시 전액 자동 환불됩니다.
              <span className="wuc-refund-box__head">직접 취소 (전액)</span>
              결제 후 3시간 이내 또는 이벤트 시작 7일 전까지 전액 환불됩니다.
              <span className="wuc-refund-box__head">그 외</span>
              자동 환불 불가 기간의 파트너 환불 요청은 backend follow-up이 필요합니다.
            </div>
          </section>
        </section>

        <aside className="wuc-summary" aria-label="주문 요약">
          <div className="wuc-summary__title">주문 요약</div>
          <div className="wuc-summary__line"><span>{ticket.name}</span><b>{formatPrice(total)}</b></div>
          <div className="wuc-summary__line"><span>수량</span><b>1매</b></div>
          <div className="wuc-summary__total"><span>총 결제금액</span><b>{formatPrice(total)}</b></div>
          {authState.status === "anonymous" ? (
            <Link className="wuc-pay" href={`/login?next=${encodeURIComponent(`/events/${event.id}/checkout?ticket=${ticket.id}`)}`}>
              <User aria-hidden="true" /> 로그인하고 계속
            </Link>
          ) : (
            <button
              className="wuc-pay"
              type="button"
              disabled={authState.status !== "ready" || !agreed || checkout.status === "creating"}
              onClick={startPayment}
            >
              {checkout.status === "creating" ? <Loader2 className="spin" aria-hidden="true" /> : <CreditCard aria-hidden="true" />}
              결제 진행
            </button>
          )}
          <p className="wuc-summary__helper">{helper}</p>
          {checkout.status === "payment" ? <PaymentReturnForm merchantUid={checkout.merchantUid} onVerify={verifyPayment} /> : null}
          {checkout.status === "error" ? <div className="wuc-snackbar" role="alert">{checkout.message}</div> : null}
        </aside>
      </main>
    </div>
  );
}

function CheckoutHeader() {
  return (
    <header className="wuc-header">
      <div className="wuc-header__inner">
        <Link className="minglit-logo" href="/" aria-label="Minglit 홈">
          <span className="minglit-logo__mark">M</span>
          <span className="minglit-logo__text">Minglit</span>
        </Link>
        <div className="wuc-header__spacer" />
        <Link className="wuc-avatar" href="/my/purchases" aria-label="구매 내역"><User aria-hidden="true" /></Link>
      </div>
    </header>
  );
}

function EventThumb({ event }: { event: PublicEvent }) {
  return (
    <div className="wuc-event__thumb">
      {event.imageUrl ? (
        // eslint-disable-next-line @next/next/no-img-element
        <img src={event.imageUrl} alt="" />
      ) : (
        <span>Minglit Event</span>
      )}
    </div>
  );
}

function PaymentReturnForm({ merchantUid, onVerify }: { merchantUid: string; onVerify: (formData: FormData) => void }) {
  return (
    <form className="wuc-paywin" action={onVerify}>
      <div className="wuc-paywin__sim">Portone V2 웹 결제창 연결 대기</div>
      <label>
        imp_uid
        <input name="imp_uid" placeholder="imp_xxx" />
      </label>
      <label>
        merchant_uid
        <input name="merchant_uid" defaultValue={merchantUid} />
      </label>
      <button type="submit">결제 검증</button>
    </form>
  );
}

function formatPrice(price: number): string {
  return price === 0 ? "무료" : `${price.toLocaleString("ko-KR")}원`;
}

function formatDateRange(start: string, end: string): string {
  const startDate = new Date(start);
  const endDate = new Date(end);
  const day = new Intl.DateTimeFormat("ko-KR", {
    month: "long",
    day: "numeric",
    weekday: "short",
    timeZone: "Asia/Seoul",
  }).format(startDate);
  const time = new Intl.DateTimeFormat("ko-KR", { hour: "numeric", minute: "2-digit", timeZone: "Asia/Seoul" });

  return `${day} ${time.format(startDate)} - ${time.format(endDate)}`;
}
