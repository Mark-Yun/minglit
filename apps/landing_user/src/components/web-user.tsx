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
import { usePathname, useRouter, useSearchParams } from "next/navigation";
import { Suspense, useCallback, useMemo, useState } from "react";
import type { EntryGender, PublicEvent, Ticket } from "@/lib/events";
import { useAuthState } from "@/lib/use-auth-state";

export function WebUserHome({ events }: { events: PublicEvent[] }) {
  return (
    <div className="web-user-shell">
      <GlobalHeader />
      <main className="wuh-main">
        {/* Fallback renders the unfiltered grid so the first paint matches the
            server render (no skeleton) while useSearchParams hydrates. */}
        <Suspense fallback={<EventGrid events={events} />}>
          <HomeContent events={events} />
        </Suspense>
      </main>
    </div>
  );
}

function HomeContent({ events }: { events: PublicEvent[] }) {
  const auth = useAuthState();
  const searchParams = useSearchParams();
  const router = useRouter();
  const pathname = usePathname();

  // Checkbox only exists for signed-in + verified users with a known gender.
  const canFilter = auth.status === "ready" && auth.isVerified;
  const checked = canFilter && searchParams.get("eligible") === "1";

  const visibleEvents = useMemo(() => {
    if (!checked || !auth.gender) return events;
    return events.filter((event) => isEligibleFor(event, auth.gender as EntryGender));
  }, [events, checked, auth.gender]);

  const setEligible = useCallback(
    (next: boolean) => {
      const params = new URLSearchParams(searchParams.toString());
      if (next) params.set("eligible", "1");
      else params.delete("eligible");
      const qs = params.toString();
      router.replace(qs ? `${pathname}?${qs}` : pathname, { scroll: false });
    },
    [searchParams, router, pathname],
  );

  return (
    <>
      {canFilter ? (
        <div className="wuh-filterbar">
          <label className="wuh-eligibility">
            <input
              type="checkbox"
              className="wuh-eligibility__box"
              checked={checked}
              onChange={(event) => setEligible(event.target.checked)}
            />
            참가 가능한 이벤트만
          </label>
        </div>
      ) : null}
      {checked && visibleEvents.length === 0 ? (
        <div className="web-empty">
          <Search aria-hidden="true" />
          <h1>참가 가능한 이벤트가 없어요</h1>
          <p>자격 조건에 맞는 이벤트가 아직 없어요. 체크를 해제하면 전체 이벤트를 볼 수 있어요.</p>
          <button type="button" className="web-empty__btn" onClick={() => setEligible(false)}>
            전체 이벤트 보기
          </button>
        </div>
      ) : (
        <EventGrid events={visibleEvents} />
      )}
    </>
  );
}

function EventGrid({ events }: { events: PublicEvent[] }) {
  if (events.length === 0) {
    return <EmptyState title="표시할 이벤트가 없어요" description="새로운 이벤트가 열리면 이곳에 먼저 보여드릴게요." />;
  }

  return (
    <section className="wuh-grid" aria-label="이벤트 목록">
      {events.map((event) => (
        <EventCard key={event.id} event={event} />
      ))}
    </section>
  );
}

function isEligibleFor(event: PublicEvent, gender: EntryGender): boolean {
  const genders = event.entryGroupGenders ?? [];
  // Empty = no gender restriction (open). Otherwise the user's gender must match.
  return genders.length === 0 || genders.includes(gender);
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
        <Link href="/" aria-label="Minglit 홈">
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img className="wuh-logo" src="/logos/minglit_logo_background_transparent.svg" alt="minglit" />
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
        <h2 className="wuh-card__title">{event.title}</h2>
        <p className="wuh-card__meta">
          <MapPin aria-hidden="true" />
          <span className="txt">{event.locationName} · {formatCardWhen(event.startsAt)}</span>
          <span className="price">{formatPrice(minTicketPrice)}</span>
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
  const images = event.images.length > 0 ? event.images : event.imageUrl ? [event.imageUrl] : [];
  const [activeIndex, setActiveIndex] = useState(0);
  const hasCarousel = images.length > 1;
  const active = Math.min(activeIndex, images.length - 1);

  return (
    <EventImage
      className="wed-hero"
      event={event}
      closed={closed}
      imageUrl={hasCarousel ? images[active] : undefined}
      dots={
        hasCarousel ? (
          <div className="wed-hero__dots" role="tablist" aria-label="이벤트 이미지">
            {images.map((image, index) => (
              <button
                key={image}
                type="button"
                role="tab"
                aria-selected={index === active}
                aria-label={`이미지 ${index + 1}`}
                className={`wed-hero__dot${index === active ? " wed-hero__dot--active" : ""}`}
                onClick={() => setActiveIndex(index)}
              />
            ))}
          </div>
        ) : null
      }
    />
  );
}

function EventImage({
  className,
  event,
  closed,
  imageUrl,
  dots,
}: {
  className: string;
  event: PublicEvent;
  closed: boolean;
  imageUrl?: string | null;
  dots?: React.ReactNode;
}) {
  const src = imageUrl !== undefined ? imageUrl : event.imageUrl;

  return (
    <div className={`${className}${closed ? ` ${className}--ended` : ""}`}>
      {src ? (
        // eslint-disable-next-line @next/next/no-img-element
        <img src={src} alt="" />
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
      {dots}
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
  const auth = useAuthState();
  const availableTickets = event.tickets.filter((ticket) => !isTicketClosed(ticket));
  const [selectedTicketId, setSelectedTicketId] = useState(availableTickets[0]?.id ?? event.tickets[0]?.id ?? "");
  const selectedTicket = event.tickets.find((ticket) => ticket.id === selectedTicketId) ?? availableTickets[0] ?? event.tickets[0];
  const closed = isEventClosed(event) || availableTickets.length === 0;
  const progress = event.maxParticipants > 0 ? Math.min(100, Math.round((event.currentParticipants / event.maxParticipants) * 100)) : 0;
  const cta = ticketCta(event, auth.status, closed, selectedTicket);

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
      {cta.banner ? (
        <div className="wed-login-banner" role="note">{cta.banner}</div>
      ) : null}
      <Link className={`wed-cta${cta.disabled ? " wed-cta--disabled" : ""}`} href={cta.href}>
        <TicketIcon aria-hidden="true" />
        {cta.label}
      </Link>
      <div className={`wed-cta-note${cta.noteWarn ? " wed-cta-note--warn" : ""}`}>{cta.note}</div>
    </aside>
  );
}

type TicketCta = { label: string; href: string; note: string; noteWarn: boolean; disabled: boolean; banner: string | null };

function ticketCta(
  event: PublicEvent,
  authStatus: "loading" | "anonymous" | "ready",
  closed: boolean,
  selectedTicket: Ticket | undefined,
): TicketCta {
  if (closed) {
    return { label: "마감된 이벤트", href: "#", note: "이미 마감되어 신청할 수 없어요", noteWarn: true, disabled: true, banner: null };
  }

  if (authStatus === "loading") {
    return { label: "로그인 상태 확인 중", href: "#", note: "로그인 상태를 확인하고 있어요", noteWarn: false, disabled: true, banner: null };
  }

  if (authStatus === "anonymous") {
    return {
      label: "로그인하고 신청하기",
      href: `/login?next=${encodeURIComponent(`/events/${event.id}`)}`,
      note: "신청에는 로그인이 필요해요 — 보던 화면으로 돌아와요",
      noteWarn: false,
      disabled: false,
      banner: "로그인 후 신청할 수 있어요",
    };
  }

  return {
    label: "신청하고 결제하기",
    href: selectedTicket ? `/events/${event.id}/checkout?ticket=${selectedTicket.id}` : "#",
    note: "티켓을 확인한 뒤 결제 보호 화면으로 이동합니다.",
    noteWarn: false,
    disabled: !selectedTicket,
    banner: null,
  };
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

function formatCardWhen(value: string): string {
  const time = new Intl.DateTimeFormat("ko-KR", {
    hour: "numeric",
    minute: "2-digit",
    timeZone: "Asia/Seoul",
  }).format(new Date(value));

  return `${formatShortDate(value)} ${time}`;
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
