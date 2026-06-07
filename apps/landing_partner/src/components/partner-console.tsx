"use client";

import Link from "next/link";
import { usePathname, useRouter, useSearchParams } from "next/navigation";
import {
  Banknote,
  CalendarDays,
  CheckCircle2,
  ClipboardList,
  Home,
  Loader2,
  LogOut,
  Menu,
  ShieldAlert,
  UserRound,
  X,
} from "lucide-react";
import { useEffect, useMemo, useState } from "react";
import {
  dashboardSections,
  dashboardSnapshot,
  partnerInquiryHref,
  resolvePartnerDashboardGate,
  resolvePartnerLoginGate,
  type ManagedPartner,
  type PartnerDashboardSection,
} from "@/lib/partner-dashboard";
import { getSupabaseBrowserClient } from "@/lib/supabase";

type LoginProvider = "google" | "apple" | "kakao";
type AuthState =
  | { status: "loading" }
  | { status: "anonymous" }
  | { status: "config-error" }
  | { status: "error"; message: string }
  | { status: "no-access"; email: string }
  | { status: "ready"; partner: ManagedPartner; email: string };

const oauthProviders: Array<{ id: LoginProvider; label: string; className: string; icon: string }> = [
  { id: "google", label: "Google로 계속하기", className: "btn-social--google", icon: "G" },
  { id: "apple", label: "Apple로 계속하기", className: "btn-social--apple", icon: "A" },
  { id: "kakao", label: "Kakao로 계속하기", className: "btn-social--kakao", icon: "K" },
];

export function PartnerLoginPage() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const [authState, setAuthState] = useState<AuthState>({ status: "loading" });
  const [pendingProvider, setPendingProvider] = useState<LoginProvider | null>(null);

  const next = sanitizeNext(searchParams.get("next"));
  const queryError = searchParams.get("error");

  useEffect(() => {
    let cancelled = false;

    async function loadSession() {
      const supabase = getSupabaseBrowserClient();
      if (!supabase) {
        setAuthState({ status: "config-error" });
        return;
      }

      const gate = await resolvePartnerLoginGate(supabase, next);
      if (cancelled) return;

      if (gate.status === "ready") {
        router.replace(gate.redirectTo);
        return;
      }

      if (gate.status === "anonymous") {
        setAuthState(queryError ? { status: "error", message: queryError } : { status: "anonymous" });
        return;
      }

      setAuthState(gate);
    }

    void loadSession();

    return () => {
      cancelled = true;
    };
  }, [next, queryError, router]);

  async function signIn(provider: LoginProvider) {
    const supabase = getSupabaseBrowserClient();
    if (!supabase) {
      setAuthState({ status: "config-error" });
      return;
    }

    setPendingProvider(provider);
    setAuthState({ status: "anonymous" });

    const redirectTo = `${window.location.origin}/auth/callback?next=${encodeURIComponent(next)}`;
    const { error } = await supabase.auth.signInWithOAuth({
      provider,
      options: { redirectTo },
    });

    if (error) {
      setPendingProvider(null);
      setAuthState({ status: "error", message: error.message });
    }
  }

  async function signOutToRetry() {
    const supabase = getSupabaseBrowserClient();
    await supabase?.auth.signOut();
    setPendingProvider(null);
    setAuthState({ status: "anonymous" });
  }

  const showAlert = authState.status === "error" || authState.status === "config-error";
  const alertText =
    authState.status === "config-error"
      ? "Supabase 공개 환경변수가 설정되지 않았어요."
      : authState.status === "error"
        ? authState.message
        : "";

  return (
    <main className="wpl-canvas">
      <section className="wpl-card" aria-label="파트너 로그인">
        <BrandBlock compact={authState.status === "no-access"} />

        {showAlert ? (
          <div className="wpl-alert" role="alert">
            <ShieldAlert aria-hidden="true" />
            <span>{alertText}</span>
          </div>
        ) : null}

        {authState.status === "loading" ? (
          <div className="wpl-loading">
            <Loader2 aria-hidden="true" />
            세션을 확인하고 있어요.
          </div>
        ) : authState.status === "no-access" ? (
          <NoAccessCard email={authState.email} onRetry={signOutToRetry} />
        ) : (
          <>
            <div className="wpl-buttons">
              {oauthProviders.map((provider) => {
                const isPending = pendingProvider === provider.id;
                const isDisabled = pendingProvider !== null || authState.status === "config-error";

                return (
                  <button
                    key={provider.id}
                    className={`btn-social ${provider.className}`}
                    type="button"
                    disabled={isDisabled}
                    onClick={() => signIn(provider.id)}
                  >
                    <span className="btn-social__icon" aria-hidden="true">
                      {isPending ? <Loader2 /> : provider.icon}
                    </span>
                    {isPending ? `${provider.label.split("로")[0]}로 이동하는 중...` : provider.label}
                  </button>
                );
              })}
            </div>

            <p className="wpl-inquiry">
              입점을 준비 중인가요? <a href={partnerInquiryHref}>입점 문의</a>
            </p>
          </>
        )}
      </section>
    </main>
  );
}

export function PartnerDashboardPage() {
  const router = useRouter();
  const [authState, setAuthState] = useState<AuthState>({ status: "loading" });

  useEffect(() => {
    let cancelled = false;

    async function loadDashboard() {
      const supabase = getSupabaseBrowserClient();
      if (!supabase) {
        setAuthState({ status: "config-error" });
        return;
      }

      const gate = await resolvePartnerDashboardGate(supabase);
      if (cancelled) return;

      if (gate.status === "anonymous") {
        router.replace(gate.loginRedirect);
        return;
      }

      setAuthState(gate);
    }

    void loadDashboard();

    return () => {
      cancelled = true;
    };
  }, [router]);

  if (authState.status === "ready") {
    return <DashboardShell partner={authState.partner} email={authState.email} />;
  }

  return (
    <PartnerConsoleShell accountLabel="확인 중" accountSub="Minglit Partner" mobileTitle="파트너 홈">
      {authState.status === "loading" ? (
        <DashboardSkeleton />
      ) : authState.status === "no-access" ? (
        <ConsoleEmptyState
          icon={<ShieldAlert aria-hidden="true" />}
          title="파트너 권한이 없어요"
          description={`${authState.email} 계정에 연결된 파트너 멤버 권한을 찾지 못했습니다.`}
          ctaHref="/login"
          ctaLabel="다른 계정으로 로그인"
        />
      ) : (
        <ConsoleEmptyState
          icon={<ShieldAlert aria-hidden="true" />}
          title="대시보드를 열 수 없어요"
          description={
            authState.status === "config-error"
              ? "Supabase 공개 환경변수가 설정되지 않았습니다."
              : authState.status === "error"
                ? authState.message
                : "다시 시도해 주세요."
          }
          ctaHref="/login"
          ctaLabel="로그인으로 돌아가기"
        />
      )}
    </PartnerConsoleShell>
  );
}

export function PartnerDashboardSectionPage({ section }: { section: PartnerDashboardSection }) {
  const router = useRouter();
  const [authState, setAuthState] = useState<AuthState>({ status: "loading" });

  useEffect(() => {
    let cancelled = false;

    async function loadSection() {
      const supabase = getSupabaseBrowserClient();
      if (!supabase) {
        setAuthState({ status: "config-error" });
        return;
      }

      const gate = await resolvePartnerDashboardGate(supabase, section.href);
      if (cancelled) return;

      if (gate.status === "anonymous") {
        router.replace(gate.loginRedirect);
        return;
      }

      setAuthState(gate);
    }

    void loadSection();

    return () => {
      cancelled = true;
    };
  }, [router, section.href]);

  if (authState.status === "ready") {
    return (
      <PartnerConsoleShell accountLabel={authState.partner.name} accountSub={authState.email} mobileTitle={section.label}>
        <ConsoleEmptyState
          icon={<ClipboardList aria-hidden="true" />}
          title={`${section.title} 준비 중입니다`}
          description={section.description}
          ctaHref="/dashboard"
          ctaLabel="홈으로 돌아가기"
        />
      </PartnerConsoleShell>
    );
  }

  return (
    <PartnerConsoleShell accountLabel="확인 중" accountSub="Minglit Partner" mobileTitle={section.label}>
      {authState.status === "loading" ? (
        <DashboardSkeleton />
      ) : authState.status === "no-access" ? (
        <ConsoleEmptyState
          icon={<ShieldAlert aria-hidden="true" />}
          title="파트너 권한이 없어요"
          description={`${authState.email} 계정에 연결된 파트너 멤버 권한을 찾지 못했습니다.`}
          ctaHref="/login"
          ctaLabel="다른 계정으로 로그인"
        />
      ) : (
        <ConsoleEmptyState
          icon={<ShieldAlert aria-hidden="true" />}
          title="대시보드를 열 수 없어요"
          description={
            authState.status === "config-error"
              ? "Supabase 공개 환경변수가 설정되지 않았습니다."
              : authState.status === "error"
                ? authState.message
                : "다시 시도해 주세요."
          }
          ctaHref="/login"
          ctaLabel="로그인으로 돌아가기"
        />
      )}
    </PartnerConsoleShell>
  );
}

function DashboardShell({ partner, email }: { partner: ManagedPartner; email: string }) {
  const greeting = useMemo(() => `${partner.name} 운영을 확인하세요`, [partner.name]);

  return (
    <PartnerConsoleShell accountLabel={partner.name} accountSub={email} mobileTitle="파트너 홈">
      <header className="wph-header">
        <h1 className="wph-header__greeting">{greeting}</h1>
        <p className="wph-header__sub">오늘 처리할 신청과 임박 이벤트를 한 화면에서 봅니다.</p>
      </header>

      <section className="wph-todo" aria-label="오늘 할 일">
        {dashboardSnapshot.todos.map((todo) => (
          <Link key={todo.key} className={`wph-todo-card${todo.alert ? " wph-todo-card--alert" : ""}`} href={todo.href}>
            <span className="wph-todo-card__label">
              {todo.alert ? <span className="wph-pulse-dot" aria-hidden="true" /> : <CheckCircle2 aria-hidden="true" />}
              {todo.label}
            </span>
            <strong className="wph-todo-card__num">{todo.value}</strong>
            <span className="wph-todo-card__sub">{todo.description}</span>
            <span className="wph-todo-card__link">바로 보기</span>
          </Link>
        ))}
      </section>

      <section className="wph-section" aria-label="오늘과 임박 이벤트">
        <div className="wph-section__title-row">
          <h2 className="wph-section__title">오늘·임박 이벤트</h2>
          <Link className="wph-section__more" href={dashboardSections[0].href}>
            전체 보기
          </Link>
        </div>

        <div className="wph-event-list">
          {dashboardSnapshot.events.map((event) => (
            <article key={event.title} className="wph-event-row">
              <span className={`wph-dday-chip ${event.dday === "오늘" ? "wph-dday-chip--today" : "wph-dday-chip--soon"}`}>
                {event.dday}
              </span>
              <div className="wph-event-row__text">
                <h3 className="wph-event-row__title">{event.title}</h3>
                <p className="wph-event-row__meta">
                  {event.dateLabel} · {event.location}
                </p>
              </div>
              <div className="wph-event-row__capacity" aria-label={`정원 ${event.capacityLabel}`}>
                <div className="wph-event-row__capacity-bar" aria-hidden="true">
                  <span style={{ width: `${event.capacity}%` }} />
                </div>
                <span className="wph-event-row__capacity-label">{event.capacityLabel}</span>
              </div>
              {event.pending > 0 ? <span className="wph-pending-badge">{event.pending} 대기</span> : null}
              <Link className="wph-row-action" href={dashboardSections[1].href}>
                관리
              </Link>
            </article>
          ))}
        </div>
      </section>
    </PartnerConsoleShell>
  );
}

function PartnerConsoleShell({
  accountLabel,
  accountSub,
  mobileTitle,
  children,
}: {
  accountLabel: string;
  accountSub: string;
  mobileTitle: string;
  children: React.ReactNode;
}) {
  const pathname = usePathname();
  const [isMobileNavOpen, setIsMobileNavOpen] = useState(false);
  const navItems = [
    { href: "/dashboard", label: "홈", icon: Home },
    { href: dashboardSections[0].href, label: dashboardSections[0].label, icon: CalendarDays },
    { href: dashboardSections[1].href, label: dashboardSections[1].label, icon: ClipboardList, badge: "4" },
    { href: dashboardSections[2].href, label: dashboardSections[2].label, icon: Banknote },
  ];
  const renderNavItems = (closeOnSelect = false) =>
    navItems.map((item) => {
      const Icon = item.icon;
      const isActive = item.href === "/dashboard" ? pathname === item.href : pathname.startsWith(item.href);

      return (
        <Link
          key={item.href}
          className={`wph-nav__item${isActive ? " wph-nav__item--active" : ""}`}
          href={item.href}
          aria-current={isActive ? "page" : undefined}
          onClick={closeOnSelect ? () => setIsMobileNavOpen(false) : undefined}
        >
          <Icon aria-hidden="true" />
          <span>{item.label}</span>
          {item.badge ? <span className="wph-nav__badge">{item.badge}</span> : null}
        </Link>
      );
    });

  return (
    <div className="wph-shell">
      <aside className="wph-sidebar" aria-label="파트너 콘솔 메뉴">
        <Link className="wph-sidebar__brand" href="/dashboard" aria-label="Minglit partner dashboard">
          <span className="minglit-mark">M</span>
          <span className="minglit-word">Minglit</span>
          <span className="wph-sidebar__brand-suffix">PARTNER</span>
        </Link>

        <nav className="wph-nav">
          {renderNavItems()}
        </nav>

        <div className="wph-sidebar__footer">
          <div className="wph-sidebar__avatar" aria-hidden="true">
            {accountLabel.slice(0, 1)}
          </div>
          <div className="wph-sidebar__account">
            <div className="wph-sidebar__account-name">{accountLabel}</div>
            <div className="wph-sidebar__account-sub">{accountSub}</div>
          </div>
        </div>
      </aside>

      <header className="wph-mobilebar">
        <Link className="wph-mobilebar__brand" href="/dashboard" aria-label="Minglit partner dashboard">
          <span className="minglit-mark">M</span>
          <span>{mobileTitle}</span>
        </Link>
        <button
          className="wph-mobilebar__menu"
          type="button"
          aria-label={isMobileNavOpen ? "메뉴 닫기" : "메뉴 열기"}
          aria-expanded={isMobileNavOpen}
          aria-controls="partner-mobile-nav"
          onClick={() => setIsMobileNavOpen((open) => !open)}
        >
          {isMobileNavOpen ? <X aria-hidden="true" /> : <Menu aria-hidden="true" />}
        </button>
      </header>

      <div
        className={`wph-mobile-drawer${isMobileNavOpen ? " wph-mobile-drawer--open" : ""}`}
        id="partner-mobile-nav"
        aria-hidden={!isMobileNavOpen}
      >
        <button
          className="wph-mobile-drawer__scrim"
          type="button"
          aria-label="메뉴 닫기"
          tabIndex={isMobileNavOpen ? 0 : -1}
          onClick={() => setIsMobileNavOpen(false)}
        />
        <div className="wph-mobile-drawer__panel" role="dialog" aria-modal="true" aria-label="파트너 콘솔 메뉴">
          <nav className="wph-nav">{renderNavItems(true)}</nav>
        </div>
      </div>

      <main className="wph-main">{children}</main>
    </div>
  );
}

function BrandBlock({ compact = false }: { compact?: boolean }) {
  return (
    <div className={`wpl-brand${compact ? " wpl-brand--compact" : ""}`}>
      <div className="wpl-brand__logo" aria-hidden="true">
        <span className="minglit-mark">M</span>
        <span className="minglit-word">Minglit</span>
      </div>
      <div className="wpl-brand__badge">PARTNER</div>
      {!compact ? <p className="wpl-brand__slogan">Verified Vibe, Spark Your Business</p> : null}
    </div>
  );
}

function NoAccessCard({ email, onRetry }: { email: string; onRetry: () => void }) {
  return (
    <div className="wpl-noaccess">
      <ShieldAlert className="wpl-noaccess__icon" aria-hidden="true" />
      <h1 className="wpl-noaccess__title">파트너 계정이 아니에요</h1>
      <p className="wpl-noaccess__sub">파트너 멤버 권한이 있는 계정으로 다시 로그인하거나 입점 문의를 남겨주세요.</p>
      <span className="wpl-account-chip">
        <UserRound aria-hidden="true" />
        {email}
      </span>
      <div className="wpl-noaccess__actions">
        <a className="wpl-btn wpl-btn--primary" href={partnerInquiryHref}>
          입점 문의하기
        </a>
        <button className="wpl-btn wpl-btn--outline" type="button" onClick={onRetry}>
          <LogOut aria-hidden="true" />
          다른 계정으로 로그인
        </button>
      </div>
    </div>
  );
}

function DashboardSkeleton() {
  return (
    <>
      <div className="wph-skeleton wph-skeleton--header" />
      <div className="wph-todo">
        <div className="wph-skeleton wph-skeleton--card" />
        <div className="wph-skeleton wph-skeleton--card" />
        <div className="wph-skeleton wph-skeleton--card" />
      </div>
      <div className="wph-skeleton wph-skeleton--row" />
      <div className="wph-skeleton wph-skeleton--row" />
    </>
  );
}

function ConsoleEmptyState({
  icon,
  title,
  description,
  ctaHref,
  ctaLabel,
}: {
  icon: React.ReactNode;
  title: string;
  description: string;
  ctaHref: string;
  ctaLabel: string;
}) {
  return (
    <section className="wph-empty">
      <div className="wph-empty__icon">{icon}</div>
      <h1>{title}</h1>
      <p>{description}</p>
      <Link href={ctaHref}>{ctaLabel}</Link>
    </section>
  );
}

function sanitizeNext(value: string | null): string {
  if (!value || !value.startsWith("/") || value.startsWith("//")) return "/dashboard";
  return value;
}
