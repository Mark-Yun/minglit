import type { SupabaseClient, User } from "@supabase/supabase-js";

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

export const dashboardSnapshot = {
  todos: [
    {
      key: "applications",
      label: "승인 대기 신청",
      value: 4,
      description: "오늘 검토하면 게스트 응답 시간이 줄어요.",
      href: "/dashboard/applications",
      alert: true,
    },
    {
      key: "events",
      label: "임박 이벤트",
      value: 2,
      description: "이번 주 운영 일정과 정원을 확인하세요.",
      href: "/dashboard/events",
      alert: false,
    },
    {
      key: "settlements",
      label: "정산 확인",
      value: 1,
      description: "검토 가능한 정산 내역이 있어요.",
      href: "/dashboard/settlements",
      alert: false,
    },
  ],
  events: [
    {
      title: "성수 와인 밍글링",
      dateLabel: "오늘 19:30",
      location: "성수 라운지",
      capacityLabel: "18 / 24명",
      capacity: 75,
      pending: 4,
      dday: "오늘",
    },
    {
      title: "주말 브런치 네트워킹",
      dateLabel: "D-3 · 11:00",
      location: "한남 프라이빗룸",
      capacityLabel: "10 / 18명",
      capacity: 56,
      pending: 0,
      dday: "D-3",
    },
  ],
};
