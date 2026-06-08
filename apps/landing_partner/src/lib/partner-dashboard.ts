import type { SupabaseClient, User } from "@supabase/supabase-js";

import { fetchPartnerParties, type PartnerParty } from "./partner-events";
import { fetchSettlementRows } from "./partner-operations";

export type ManagedPartner = {
  id: string;
  name: string;
  introduction: string | null;
  contact_email: string | null;
  role: string;
  permissions: string[];
};

export type PartnerDashboardGate =
  | { status: "anonymous"; loginRedirect: string }
  | { status: "error"; message: string }
  | { status: "no-access"; email: string }
  | { status: "ready"; partner: ManagedPartner; email: string };

export type PartnerLoginGate =
  | { status: "anonymous" }
  | { status: "error"; message: string }
  | { status: "no-access"; email: string }
  | { status: "ready"; redirectTo: string };

export type PartnerDashboardSection = {
  key: "events" | "applications" | "settlements";
  href: string;
  label: string;
  title: string;
  description: string;
};

export const partnerInquiryHref = "mailto:contact@minglit.com";

const ownerRoles = new Set(["owner"]);
const applicationManagePermissions = new Set(["PARTY_MANAGE"]);
const settlementViewPermissions = new Set(["SETTLEMENT_VIEW", "settlement.read"]);
const settlementEditPermissions = new Set(["SETTLEMENT_EDIT", "settlement.write"]);

type PartnerPermissionRow = {
  partner_id: string;
  role: string;
  permissions: string[] | null;
};

type PartnerRow = {
  id: string;
  name: string;
  introduction: string | null;
  contact_email: string | null;
  is_active: boolean | null;
};

export async function fetchCurrentPartner(
  supabase: SupabaseClient,
  user: User,
): Promise<ManagedPartner | null> {
  const { data: permissionRows, error: permissionsError } = await supabase
    .from("partner_member_permissions")
    .select("partner_id, role, permissions")
    .eq("user_id", user.id)
    .limit(1)
    .returns<PartnerPermissionRow[]>();

  if (permissionsError) throw permissionsError;

  const permission = permissionRows?.[0];
  if (!permission) return null;

  const { data: partner, error: partnerError } = await supabase
    .from("partners")
    .select("id, name, introduction, contact_email, is_active")
    .eq("id", permission.partner_id)
    .eq("is_active", true)
    .single<PartnerRow>();

  if (partnerError) throw partnerError;
  if (!partner) return null;

  return {
    id: partner.id,
    name: partner.name,
    introduction: partner.introduction,
    contact_email: partner.contact_email,
    role: permission.role,
    permissions: permission.permissions ?? [],
  };
}

export async function resolvePartnerDashboardGate(
  supabase: SupabaseClient,
  next = "/dashboard",
): Promise<PartnerDashboardGate> {
  const { data, error } = await supabase.auth.getSession();

  if (error) return { status: "error", message: error.message };

  const user = data.session?.user;
  if (!user) {
    return { status: "anonymous", loginRedirect: `/login?next=${encodeURIComponent(next)}` };
  }

  try {
    const partner = await fetchCurrentPartner(supabase, user);
    if (!partner) return { status: "no-access", email: user.email ?? "로그인된 계정" };

    return { status: "ready", partner, email: user.email ?? partner.name };
  } catch (partnerError) {
    return {
      status: "error",
      message: partnerError instanceof Error ? partnerError.message : "대시보드 데이터를 불러오지 못했어요.",
    };
  }
}

export async function resolvePartnerLoginGate(
  supabase: SupabaseClient,
  next = "/dashboard",
): Promise<PartnerLoginGate> {
  const { data, error } = await supabase.auth.getSession();

  if (error) return { status: "error", message: error.message };

  const user = data.session?.user;
  if (!user) return { status: "anonymous" };

  try {
    const partner = await fetchCurrentPartner(supabase, user);
    if (partner) return { status: "ready", redirectTo: next };

    return { status: "no-access", email: user.email ?? "로그인된 계정" };
  } catch (partnerError) {
    return {
      status: "error",
      message: partnerError instanceof Error ? partnerError.message : "파트너 권한을 확인하지 못했어요.",
    };
  }
}

export const dashboardSections: PartnerDashboardSection[] = [
  {
    key: "events",
    href: "/dashboard/events",
    label: "파티·이벤트",
    title: "이벤트 관리",
    description: "이벤트 목록과 상세 운영 도구는 곧 연결됩니다.",
  },
  {
    key: "applications",
    href: "/dashboard/applications",
    label: "신청",
    title: "신청 관리",
    description: "참가 신청 검토와 승인 도구는 곧 연결됩니다.",
  },
  {
    key: "settlements",
    href: "/dashboard/settlements",
    label: "정산",
    title: "정산 관리",
    description: "정산 내역 확인과 지급 관리 도구는 곧 연결됩니다.",
  },
];

export function getPartnerDashboardSection(section: string): PartnerDashboardSection | null {
  return dashboardSections.find((item) => item.key === section) ?? null;
}

export function canViewPartnerSettlements(partner: Pick<ManagedPartner, "role" | "permissions">): boolean {
  if (ownerRoles.has(partner.role)) return true;
  return partner.permissions.some((permission) => settlementViewPermissions.has(permission));
}

export function canEditPartnerSettlements(partner: Pick<ManagedPartner, "role" | "permissions">): boolean {
  if (ownerRoles.has(partner.role)) return true;
  return partner.permissions.some((permission) => settlementEditPermissions.has(permission));
}

export function canManagePartnerApplications(partner: Pick<ManagedPartner, "role" | "permissions">): boolean {
  if (ownerRoles.has(partner.role)) return true;
  return partner.permissions.some((permission) => applicationManagePermissions.has(permission));
}

export type PartnerDashboardTodo = {
  key: "applications" | "events" | "settlements";
  label: string;
  value: number;
  description: string;
  href: string;
  alert: boolean;
};

export type PartnerDashboardEvent = {
  title: string;
  dateLabel: string;
  location: string;
  capacityLabel: string;
  capacity: number;
  pending: number;
  dday: string;
};

export type PartnerDashboardData = {
  todos: PartnerDashboardTodo[];
  events: PartnerDashboardEvent[];
};

const UPCOMING_EVENT_LIMIT = 6;

/** 페칭 실패/빈 상태 폴백 — 컴포넌트 초기값으로도 사용. */
export const emptyPartnerDashboard: PartnerDashboardData = {
  todos: [
    { key: "applications", label: "승인 대기 신청", value: 0, description: "검토할 신청이 없어요.", href: dashboardSections[1].href, alert: false },
    { key: "events", label: "임박 이벤트", value: 0, description: "예정된 이벤트가 없어요.", href: dashboardSections[0].href, alert: false },
    { key: "settlements", label: "정산 확인", value: 0, description: "확인할 정산 내역이 없어요.", href: dashboardSections[2].href, alert: false },
  ],
  events: [],
};

/**
 * 파트너 홈 스냅샷 실데이터 페칭.
 * (a) 대기 신청 수 — 파티/회차의 pending 신청 합계
 * (b) 오늘/임박 이벤트 — scheduled & 시작 시각이 현재 이후인 회차
 * (c) 정산 상태 — settlement-query EF (fetchSettlementRows) 건수
 * 각 소스는 독립적으로 실패해도 빈 값으로 폴백한다.
 */
export async function fetchPartnerDashboard(
  supabase: SupabaseClient,
  partnerId: string,
  now: Date = new Date(),
): Promise<PartnerDashboardData> {
  const [parties, settlementCount] = await Promise.all([
    fetchPartnerParties(supabase, partnerId).catch(() => [] as PartnerParty[]),
    fetchSettlementRows(supabase, partnerId)
      .then((rows) => rows.length)
      .catch(() => 0),
  ]);

  const allEvents = parties.flatMap((party) =>
    party.events.map((event) => ({ event, party })),
  );

  const upcoming = allEvents
    .filter(({ event }) => event.status === "scheduled" && new Date(event.start_time) >= now)
    .sort((a, b) => new Date(a.event.start_time).getTime() - new Date(b.event.start_time).getTime());

  const pendingTotal = allEvents.reduce((sum, { event }) => sum + event.pending_count, 0);

  const events: PartnerDashboardEvent[] = upcoming.slice(0, UPCOMING_EVENT_LIMIT).map(({ event, party }) => {
    const max = event.max_participants || party.max_participants || 0;
    const current = event.current_participants;
    return {
      title: event.title ?? party.title,
      dateLabel: formatDashboardEventDate(event.start_time, now),
      location: event.location?.name ?? party.location?.name ?? "장소 미정",
      capacityLabel: `${current} / ${max}명`,
      capacity: max > 0 ? Math.min(100, Math.round((current / max) * 100)) : 0,
      pending: event.pending_count,
      dday: ddayLabel(event.start_time, now),
    };
  });

  return {
    todos: [
      {
        key: "applications",
        label: "승인 대기 신청",
        value: pendingTotal,
        description: pendingTotal > 0 ? "오늘 검토하면 게스트 응답 시간이 줄어요." : "검토할 신청이 없어요.",
        href: dashboardSections[1].href,
        alert: pendingTotal > 0,
      },
      {
        key: "events",
        label: "임박 이벤트",
        value: upcoming.length,
        description: upcoming.length > 0 ? "이번 주 운영 일정과 정원을 확인하세요." : "예정된 이벤트가 없어요.",
        href: dashboardSections[0].href,
        alert: false,
      },
      {
        key: "settlements",
        label: "정산 확인",
        value: settlementCount,
        description: settlementCount > 0 ? "검토 가능한 정산 내역이 있어요." : "확인할 정산 내역이 없어요.",
        href: dashboardSections[2].href,
        alert: false,
      },
    ],
    events,
  };
}

function ddayLabel(startTime: string, now: Date): string {
  const start = new Date(startTime);
  const startDay = new Date(start.getFullYear(), start.getMonth(), start.getDate());
  const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const diffDays = Math.round((startDay.getTime() - today.getTime()) / 86_400_000);
  if (diffDays <= 0) return "오늘";
  return `D-${diffDays}`;
}

function formatDashboardEventDate(startTime: string, now: Date): string {
  const start = new Date(startTime);
  const time = new Intl.DateTimeFormat("ko-KR", { hour: "2-digit", minute: "2-digit" }).format(start);
  const dday = ddayLabel(startTime, now);
  return dday === "오늘" ? `오늘 ${time}` : `${dday} · ${time}`;
}
