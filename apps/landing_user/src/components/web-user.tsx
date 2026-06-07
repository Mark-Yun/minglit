"use client";

import Link from "next/link";
import {
  CalendarDays,
  ChevronRight,
  MapPin,
  Search,
  Share2,
  Ticket as TicketIcon,
  User,
  Users,
} from "lucide-react";
import { useMemo, useState } from "react";
import type { PublicEvent, Ticket } from "@/lib/events";

export function WebUserHome({ events }: { events: PublicEvent[] }) {
  return (
    <div className="web-user-shell">
      <GlobalHeader />
      <main className="wuh-main">
        <section className="wuh-filterbar" aria-label="이벤트 필터">
          <button className="wuh-eligibility" type="button" aria-pressed="false">
            <span className="wuh-eligibility__box" aria-hidden="true" />
            참가 가능한 이벤트만
          </button>
        </section>

        {events.length > 0 ? (
          <section className="wuh-grid" aria-label="이벤트 목록">
            {events.map((event) => (
              <EventCard key={event.id} event={event} />
            ))}
          </section>
        ) : (
          <EmptyState title="표시할 이벤트가 없어요" description="새로운 이벤트가 열리면 이곳에 먼저 보여드릴게요." />
        )}
      </main>
    </div>
  );
}

export function WebUserEventDetail({ event }: { event: PublicEvent }) {
  return (
    <div className="web-user-shell">
      <GlobalHeader />
      <main className="wed-main">
        <div className="wed-grid">
          <article className="wed-content">
            <EventHero event={event} />
            <div className="wed-title-row">
              <h1 className="wed-title">{event.title}</h1>
              <button className="wed-share" type="button">
                <Share2 aria-hidden="true" />
                공유
              </button>
            </div>

            <InfoTile icon={<CalendarDays aria-hidden="true" />} title={formatDateRange(event.startsAt, event.endsAt)} sub="KST 기준" />
            <InfoTile icon={<MapPin aria-hidden="true" />} title={event.locationName} sub={event.locationAddress} />

            <section className="wed-sec">
              <h2 className="wed-sec__h">이벤트 소개</h2>
              <p className="wed-desc">{event.description}</p>
            </section>

            <Link className="wed-partner" href="/" aria-label={`${event.partnerName} 파트너 정보`}>
              <div className="wed-partner__avatar" aria-hidden="true">
                <User />
              </div>
              <div className="wed-partner__body">
                <div className="wed-partner__name">{event.partnerName}</div>
                <div className="wed-partner__sub">{event.partnerIntro}</div>
              </div>
              <ChevronRight className="wed-partner__chevron" aria-hidden="true" />
            </Link>
          </article>

          <TicketPanel event={event} />
        </div>
      </main>
    </div>
  );
}

export function EmptyState({ title, description }: { title: string; description: string }) {
  return (
    <div className="web-empty">
      <Search aria-hidden="true" />
      <h1>{title}</h1>
      <p>{description}</p>
      <Link href="/">홈으로 돌아가기</Link>
    </div>
  );
}

function GlobalHeader() {
  return (
    <header className="wuh-header">
      <div className="wuh-header__inner">
        <Link className="minglit-logo" href="/" aria-label="Minglit 홈">
          <span className="minglit-logo__mark">M</span>
          <span className="minglit-logo__text">Minglit</span>
        </Link>
        <button className="wuh-search" type="button">
          <Search aria-hidden="true" />
          이벤트, 지역, 키워드 검색
        </button>
        <div className="wuh-header__spacer" />
        <Link className="wuh-login-btn" href="/login">
          로그인
        </Link>
      </div>
    </header>
  );
}

function EventCard({ event }: { event: PublicEvent }) {
  const isClosed = isEventClosed(event);
  const minTicketPrice = minPrice(event.tickets);

  return (
    <Link className="wuh-card" href={`/events/${event.id}`} aria-label={`${event.title} 상세 보기`}>
      <EventImage className="wuh-card__image" event={event} closed={isClosed} />
      <div className="wuh-card__body">
        <div className="wuh-card__date">{formatShortDate(event.startsAt)}</div>
        <h2 className="wuh-card__title">{event.title}</h2>
        <p className="wuh-card__meta">
          {event.locationName} · {formatPrice(minTicketPrice)}
        </p>
        <div className="wuh-card__foot">
          <span>{event.currentParticipants}/{event.maxParticipants} 신청</span>
          <span className={isClosed ? "wuh-card__closed" : "wuh-card__open"}>{isClosed ? "마감" : "신청 가능"}</span>
        </div>
      </div>
    </Link>
  );
}

function EventHero({ event }: { event: PublicEvent }) {
  const closed = isEventClosed(event);

  return <EventImage className="wed-hero" event={event} closed={closed} />;
}

function EventImage({ className, event, closed }: { className: string; event: PublicEvent; closed: boolean }) {
  return (
    <div className={`${className}${closed ? ` ${className}--ended` : ""}`}>
      {event.imageUrl ? (
        // eslint-disable-next-line @next/next/no-img-element
        <img src={event.imageUrl} alt="" />
      ) : (
        <div className="event-image__ph">Minglit Event</div>
      )}
      <div className="wuh-card__grad" />
      <div className="wuh-ovl wuh-ovl--partner">
        <User aria-hidden="true" />
        <span>{event.partnerName}</span>
      </div>
      <div className="wuh-ovl wuh-ovl--pp">
        <Users aria-hidden="true" />
        <span>{event.currentParticipants}/{event.maxParticipants}</span>
      </div>
      <div className="wuh-card__tags">
        {event.tags.map((tag) => (
          <span key={tag}>{tag}</span>
        ))}
      </div>
      {closed ? (
        <div className="wuh-card__scrim">
          <b>{event.status === "completed" ? "종료" : "마감"}</b>
        </div>
      ) : null}
    </div>
  );
}

function InfoTile({ icon, title, sub }: { icon: React.ReactNode; title: string; sub: string }) {
  return (
    <div className="wed-tile">
      <div className="wed-tile__icon">{icon}</div>
      <div>
        <div className="wed-tile__title">{title}</div>
        <div className="wed-tile__sub">{sub}</div>
      </div>
    </div>
  );
}

function TicketPanel({ event }: { event: PublicEvent }) {
  const availableTickets = event.tickets.filter((ticket) => !isTicketClosed(ticket));
  const [selectedTicketId, setSelectedTicketId] = useState(availableTickets[0]?.id ?? event.tickets[0]?.id ?? "");
  const selectedTicket = event.tickets.find((ticket) => ticket.id === selectedTicketId) ?? availableTickets[0] ?? event.tickets[0];
  const closed = isEventClosed(event) || availableTickets.length === 0;
  const progress = event.maxParticipants > 0 ? Math.min(100, Math.round((event.currentParticipants / event.maxParticipants) * 100)) : 0;
  const ctaLabel = closed ? "마감된 이벤트" : "로그인하고 신청하기";
  const helper = closed ? "이미 마감되어 신청할 수 없어요" : "비로그인 열람은 가능하고, 신청 시 로그인으로 이동합니다.";

  const sortedTickets = useMemo(
    () => [...event.tickets].sort((a, b) => a.price - b.price),
    [event.tickets],
  );

  return (
    <aside className="wed-panel" aria-label="티켓 선택">
      <div className="wed-panel__title">티켓 선택</div>
      <div className="wed-status">
        <div className="wed-status__caption">신청 현황</div>
        <div className="wed-status__row">
          <span>{event.currentParticipants}/{event.maxParticipants}</span>
          <span>{closed ? "마감" : "모집중"}</span>
        </div>
        <div className="wed-status__bar" aria-hidden="true">
          <span style={{ width: `${progress}%` }} />
        </div>
      </div>

      <div className="wed-ticket-list" role="radiogroup" aria-label="티켓 옵션">
        {sortedTickets.length > 0 ? (
          sortedTickets.map((ticket, index) => {
            const ticketClosed = isTicketClosed(ticket) || isEventClosed(event);
            const selected = ticket.id === selectedTicket?.id && !ticketClosed;

            return (
              <button
                key={ticket.id}
                className={`wed-ticket${selected ? " wed-ticket--selected" : ""}${ticketClosed ? " wed-ticket--locked" : ""}`}
                type="button"
                role="radio"
                aria-checked={selected}
                disabled={ticketClosed}
                onClick={() => setSelectedTicketId(ticket.id)}
              >
                <span className="wed-ticket__top">
                  <span className="wed-ticket__name">{ticket.name}</span>
                  {index === 0 && !ticketClosed ? <span className="wed-ticket__badge">추천</span> : null}
                </span>
                <span className="wed-ticket__desc">{ticket.description ?? "표준 티켓"}</span>
                <span className="wed-ticket__price">{formatPrice(ticket.price)}</span>
                {ticketClosed ? <span className="wed-ticket__reason">매진되었거나 선택할 수 없어요</span> : null}
              </button>
            );
          })
        ) : (
          <div className="wed-ticket wed-ticket--locked">
            <span className="wed-ticket__name">티켓 준비 중</span>
            <span className="wed-ticket__desc">판매 정보가 공개되면 선택할 수 있어요</span>
          </div>
        )}
      </div>

      <div className="wed-refund">
        결제 후 <b>3시간 이내</b> 또는 이벤트 시작 <b>7일 전</b>까지 100% 자동 환불 · <span>자세히 보기</span>
      </div>

      <div className="wed-total">
        <span>합계</span>
        <b>{closed || !selectedTicket ? "-" : formatPrice(selectedTicket.price)}</b>
      </div>
      <Link className={`wed-cta${closed ? " wed-cta--disabled" : ""}`} href={closed ? "#" : `/login?next=/events/${event.id}`}>
        <TicketIcon aria-hidden="true" />
        {ctaLabel}
      </Link>
      <div className={`wed-cta-note${closed ? " wed-cta-note--warn" : ""}`}>{helper}</div>
    </aside>
  );
}

function isEventClosed(event: PublicEvent): boolean {
  if (event.status === "completed" || event.status === "cancelled") return true;
  if (event.maxParticipants > 0 && event.currentParticipants >= event.maxParticipants) return true;

  return event.tickets.length > 0 && event.tickets.every(isTicketClosed);
}

function isTicketClosed(ticket: Ticket): boolean {
  return ticket.status !== "on_sale" || (ticket.quantity > 0 && ticket.soldCount >= ticket.quantity);
}

function minPrice(tickets: Ticket[]): number {
  if (tickets.length === 0) return 0;
  return Math.min(...tickets.map((ticket) => ticket.price));
}

function formatPrice(price: number): string {
  return price === 0 ? "무료" : `${price.toLocaleString("ko-KR")}원`;
}

function formatShortDate(value: string): string {
  return new Intl.DateTimeFormat("ko-KR", {
    month: "long",
    day: "numeric",
    weekday: "short",
    timeZone: "Asia/Seoul",
  }).format(new Date(value));
}

function formatDateRange(start: string, end: string): string {
  const startDate = new Date(start);
  const endDate = new Date(end);
  const day = new Intl.DateTimeFormat("ko-KR", {
    year: "numeric",
    month: "long",
    day: "numeric",
    weekday: "long",
    timeZone: "Asia/Seoul",
  }).format(startDate);
  const time = new Intl.DateTimeFormat("ko-KR", {
    hour: "numeric",
    minute: "2-digit",
    timeZone: "Asia/Seoul",
  });

  return `${day} ${time.format(startDate)} - ${time.format(endDate)}`;
}
