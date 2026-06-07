import type { SupabaseClient } from "@supabase/supabase-js";

import type { ManagedPartner } from "./partner-dashboard";

export type PartyStatus = "draft" | "active" | "closed";
export type EventStatus = "scheduled" | "cancelled" | "completed";
export type RecurrencePattern = "none" | "weekly" | "biweekly" | "monthly";

export type PartnerLocation = {
  id: string;
  name: string;
  address: string;
  address_detail: string | null;
};

export type TicketTemplate = {
  id: string;
  name: string;
  description: string | null;
  price: number;
  quantity: number;
};

export type RecurrenceRule = {
  id: string;
  pattern: Exclude<RecurrencePattern, "none">;
  days_of_week: number[];
  month_day: number | null;
  start_time: string;
  end_time: string;
  end_date: string | null;
  status: "active" | "paused" | "cancelled";
};

export type PartnerEvent = {
  id: string;
  party_id: string;
  title: string | null;
  start_time: string;
  end_time: string;
  status: EventStatus;
  max_participants: number;
  min_confirmed_count: number;
  current_participants: number;
  pending_count: number;
  paid_count: number;
  location: PartnerLocation | null;
};

export type PartnerParty = {
  id: string;
  title: string;
  status: PartyStatus;
  min_confirmed_count: number;
  max_participants: number;
  descriptionText: string;
  location: PartnerLocation | null;
  ticketTemplates: TicketTemplate[];
  recurrenceRule: RecurrenceRule | null;
  events: PartnerEvent[];
};

export type PartyFormValues = {
  title: string;
  description: string;
  status: PartyStatus;
  locationName: string;
  locationAddress: string;
  maxParticipants: number;
  minConfirmedCount: number;
  ticketName: string;
  ticketPrice: number;
  ticketQuantity: number;
  recurrencePattern: RecurrencePattern;
  recurrenceDayOfWeek: number;
  recurrenceMonthDay: number;
  recurrenceStartTime: string;
  recurrenceEndTime: string;
};

export type EventFormValues = {
  partyId: string;
  title: string;
  startLocal: string;
  endLocal: string;
  maxParticipants: number;
  minConfirmedCount: number;
  reason: string;
};

type PartyRow = {
  id: string;
  title: string;
  description: unknown;
  status: PartyStatus;
  min_confirmed_count: number | null;
  max_participants: number | null;
  location_id: string | null;
  locations: PartnerLocation | PartnerLocation[] | null;
  ticket_templates: TicketTemplate[] | null;
  recurrence_rules: RecurrenceRule[] | null;
  events: Array<{
    id: string;
    party_id: string;
    title: string | null;
    start_time: string;
    end_time: string;
    status: EventStatus;
    max_participants: number | null;
    min_confirmed_count: number | null;
    current_participants: number | null;
    locations: PartnerLocation | PartnerLocation[] | null;
  }> | null;
};

type ApplicationRow = {
  event_id: string;
  status: string;
};

export const defaultPartyFormValues: PartyFormValues = {
  title: "",
  description: "",
  status: "active",
  locationName: "",
  locationAddress: "",
  maxParticipants: 20,
  minConfirmedCount: 4,
  ticketName: "일반 티켓",
  ticketPrice: 0,
  ticketQuantity: 20,
  recurrencePattern: "none",
  recurrenceDayOfWeek: 5,
  recurrenceMonthDay: 15,
  recurrenceStartTime: "19:00",
  recurrenceEndTime: "21:00",
};

export const defaultEventFormValues: EventFormValues = {
  partyId: "",
  title: "",
  startLocal: "",
  endLocal: "",
  maxParticipants: 20,
  minConfirmedCount: 4,
  reason: "",
};

export function shouldOpenCancelDialog(value: string | string[] | undefined): boolean {
  const firstValue = Array.isArray(value) ? value[0] : value;
  return firstValue === "1" || firstValue === "true" || firstValue === "yes";
}

export async function fetchPartnerParties(
  supabase: SupabaseClient,
  partnerId: string,
): Promise<PartnerParty[]> {
  const { data, error } = await supabase
    .from("parties")
    .select(
      "id,title,description,status,min_confirmed_count,max_participants,location_id,locations(id,name,address,address_detail),ticket_templates(id,name,description,price,quantity),recurrence_rules(id,pattern,days_of_week,month_day,start_time,end_time,end_date,status),events(id,party_id,title,start_time,end_time,status,max_participants,min_confirmed_count,current_participants,locations(id,name,address,address_detail))",
    )
    .eq("partner_id", partnerId)
    .order("updated_at", { ascending: false })
    .returns<PartyRow[]>();

  if (error) throw error;

  const parties = (data ?? []).map(normalizePartyRow);
  const eventIds = parties.flatMap((party) => party.events.map((event) => event.id));
  if (eventIds.length === 0) return parties;

  const { data: applications, error: applicationsError } = await supabase
    .from("event_applications")
    .select("event_id,status")
    .in("event_id", eventIds)
    .returns<ApplicationRow[]>();

  if (applicationsError) throw applicationsError;

  const counts = countApplicationsByEvent(applications ?? []);
  return parties.map((party) => ({
    ...party,
    events: party.events.map((event) => ({
      ...event,
      pending_count: counts.get(event.id)?.pending ?? 0,
      paid_count: counts.get(event.id)?.paid ?? 0,
    })),
  }));
}

export function normalizePartyRow(row: PartyRow): PartnerParty {
  const ticketTemplates = row.ticket_templates ?? [];
  const events = (row.events ?? [])
    .map((event) => ({
      id: event.id,
      party_id: event.party_id,
      title: event.title,
      start_time: event.start_time,
      end_time: event.end_time,
      status: event.status,
      max_participants: event.max_participants ?? row.max_participants ?? 0,
      min_confirmed_count: event.min_confirmed_count ?? row.min_confirmed_count ?? 0,
      current_participants: event.current_participants ?? 0,
      pending_count: 0,
      paid_count: 0,
      location: firstRelated(event.locations),
    }))
    .sort((a, b) => new Date(a.start_time).getTime() - new Date(b.start_time).getTime());

  return {
    id: row.id,
    title: row.title,
    status: row.status,
    min_confirmed_count: row.min_confirmed_count ?? 0,
    max_participants: row.max_participants ?? 0,
    descriptionText: descriptionToText(row.description),
    location: firstRelated(row.locations),
    ticketTemplates,
    recurrenceRule: (row.recurrence_rules ?? []).find((rule) => rule.status !== "cancelled") ?? null,
    events,
  };
}

export function validatePartyForm(values: PartyFormValues): string[] {
  const errors: string[] = [];
  if (!values.title.trim()) errors.push("파티 이름을 입력해 주세요.");
  if (!values.locationName.trim()) errors.push("장소 이름을 입력해 주세요.");
  if (!values.locationAddress.trim()) errors.push("장소 주소를 입력해 주세요.");
  if (!Number.isInteger(values.maxParticipants) || values.maxParticipants < 1 || values.maxParticipants > 999) {
    errors.push("정원은 1~999명 사이여야 합니다.");
  }
  if (values.minConfirmedCount < 0 || values.minConfirmedCount > values.maxParticipants) {
    errors.push("최소 확정 인원은 0 이상, 정원 이하로 입력해 주세요.");
  }
  if (!values.ticketName.trim()) errors.push("티켓 이름을 입력해 주세요.");
  if (values.ticketPrice < 0) errors.push("티켓 가격은 0원 이상이어야 합니다.");
  if (!Number.isInteger(values.ticketQuantity) || values.ticketQuantity < 1 || values.ticketQuantity > 999) {
    errors.push("티켓 수량은 1~999장 사이여야 합니다.");
  }
  if (values.recurrencePattern !== "none") {
    if (!/^\d{2}:\d{2}$/.test(values.recurrenceStartTime) || !/^\d{2}:\d{2}$/.test(values.recurrenceEndTime)) {
      errors.push("반복 시작/종료 시간은 HH:MM 형식이어야 합니다.");
    }
    if (values.recurrenceStartTime >= values.recurrenceEndTime) {
      errors.push("반복 종료 시간은 시작 시간보다 늦어야 합니다.");
    }
    if ((values.recurrencePattern === "weekly" || values.recurrencePattern === "biweekly") &&
      (values.recurrenceDayOfWeek < 0 || values.recurrenceDayOfWeek > 6)) {
      errors.push("반복 요일을 선택해 주세요.");
    }
    if (values.recurrencePattern === "monthly" &&
      (values.recurrenceMonthDay < 1 || values.recurrenceMonthDay > 31)) {
      errors.push("매월 반복 날짜는 1~31일 사이여야 합니다.");
    }
  }
  return errors;
}

export function validateEventForm(values: EventFormValues): string[] {
  const errors: string[] = [];
  if (!values.partyId) errors.push("회차를 열 파티를 선택해 주세요.");
  if (!values.title.trim()) errors.push("회차 제목을 입력해 주세요.");
  const start = new Date(values.startLocal);
  const end = new Date(values.endLocal);
  if (!values.startLocal || Number.isNaN(start.getTime())) errors.push("시작 일시를 입력해 주세요.");
  if (!values.endLocal || Number.isNaN(end.getTime())) errors.push("종료 일시를 입력해 주세요.");
  if (!Number.isNaN(start.getTime()) && !Number.isNaN(end.getTime()) && start >= end) {
    errors.push("종료 일시는 시작 일시보다 늦어야 합니다.");
  }
  if (!Number.isInteger(values.maxParticipants) || values.maxParticipants < 1 || values.maxParticipants > 999) {
    errors.push("정원은 1~999명 사이여야 합니다.");
  }
  if (values.minConfirmedCount < 0 || values.minConfirmedCount > values.maxParticipants) {
    errors.push("최소 확정 인원은 0 이상, 정원 이하로 입력해 주세요.");
  }
  return errors;
}

export function buildPartyCreatePayload(partner: ManagedPartner, values: PartyFormValues) {
  return {
    action: "create",
    partner_id: partner.id,
    party: {
      title: values.title.trim(),
      description: { plain_text: values.description.trim() },
      status: values.status,
      min_confirmed_count: values.minConfirmedCount,
      max_participants: values.maxParticipants,
    },
    location: {
      name: values.locationName.trim(),
      address: values.locationAddress.trim(),
    },
    ticket_templates: [
      {
        name: values.ticketName.trim(),
        price: values.ticketPrice,
        quantity: values.ticketQuantity,
      },
    ],
  };
}

export function buildPartyUpdatePayload(party: PartnerParty, values: PartyFormValues) {
  return {
    action: "update",
    party_id: party.id,
    party: {
      title: values.title.trim(),
      description: { plain_text: values.description.trim() },
      status: values.status,
      min_confirmed_count: values.minConfirmedCount,
      max_participants: values.maxParticipants,
    },
    location: {
      name: values.locationName.trim(),
      address: values.locationAddress.trim(),
    },
  };
}

export function buildTicketTemplatePayload(party: PartnerParty, values: PartyFormValues) {
  const ticketTemplate = {
    name: values.ticketName.trim(),
    price: values.ticketPrice,
    quantity: values.ticketQuantity,
  };
  const existing = party.ticketTemplates[0];

  if (!existing) {
    return {
      action: "create_ticket_template",
      ticket_template: {
        ...ticketTemplate,
        party_id: party.id,
      },
    };
  }

  return {
    action: "update_ticket_template",
    ticket_template_id: existing.id,
    ticket_template: ticketTemplate,
  };
}

export function buildRecurrencePayload(party: PartnerParty, values: PartyFormValues) {
  const existing = party.recurrenceRule;
  if (values.recurrencePattern === "none") {
    return existing ? { action: "pause", rule_id: existing.id } : null;
  }

  const body = {
    pattern: values.recurrencePattern,
    days_of_week: values.recurrencePattern === "monthly" ? [] : [values.recurrenceDayOfWeek],
    month_day: values.recurrencePattern === "monthly" ? values.recurrenceMonthDay : null,
    start_time: values.recurrenceStartTime,
    end_time: values.recurrenceEndTime,
    end_date: null,
  };

  if (existing) {
    return {
      action: "update",
      rule_id: existing.id,
      ...body,
    };
  }

  return {
    action: "create",
    party_id: party.id,
    ...body,
  };
}

export function buildEventCreatePayload(party: PartnerParty, values: EventFormValues) {
  return {
    action: "create",
    party_id: values.partyId,
    event: {
      title: values.title.trim(),
      start_time: new Date(values.startLocal).toISOString(),
      end_time: new Date(values.endLocal).toISOString(),
      max_participants: values.maxParticipants,
      min_confirmed_count: values.minConfirmedCount,
      location_id: party.location?.id,
    },
    tickets: party.ticketTemplates.map((template) => ({
      template_id: template.id,
      quantity: template.quantity,
    })),
  };
}

export function buildEventUpdatePayload(eventId: string, values: EventFormValues) {
  return {
    action: "update",
    event_id: eventId,
    event: {
      title: values.title.trim(),
      start_time: new Date(values.startLocal).toISOString(),
      end_time: new Date(values.endLocal).toISOString(),
      max_participants: values.maxParticipants,
      min_confirmed_count: values.minConfirmedCount,
    },
    reason: values.reason.trim() || undefined,
  };
}

export function partyToFormValues(party: PartnerParty): PartyFormValues {
  const template = party.ticketTemplates[0];
  return {
    title: party.title,
    description: party.descriptionText,
    status: party.status,
    locationName: party.location?.name ?? "",
    locationAddress: party.location?.address ?? "",
    maxParticipants: party.max_participants,
    minConfirmedCount: party.min_confirmed_count,
    ticketName: template?.name ?? defaultPartyFormValues.ticketName,
    ticketPrice: template?.price ?? defaultPartyFormValues.ticketPrice,
    ticketQuantity: template?.quantity ?? party.max_participants,
    recurrencePattern: party.recurrenceRule?.pattern ?? "none",
    recurrenceDayOfWeek: party.recurrenceRule?.days_of_week[0] ?? defaultPartyFormValues.recurrenceDayOfWeek,
    recurrenceMonthDay: party.recurrenceRule?.month_day ?? defaultPartyFormValues.recurrenceMonthDay,
    recurrenceStartTime: party.recurrenceRule?.start_time ?? defaultPartyFormValues.recurrenceStartTime,
    recurrenceEndTime: party.recurrenceRule?.end_time ?? defaultPartyFormValues.recurrenceEndTime,
  };
}

export function eventToFormValues(event: PartnerEvent): EventFormValues {
  return {
    partyId: event.party_id,
    title: event.title ?? "",
    startLocal: toDateTimeLocal(event.start_time),
    endLocal: toDateTimeLocal(event.end_time),
    maxParticipants: event.max_participants,
    minConfirmedCount: event.min_confirmed_count,
    reason: "",
  };
}

export function eventStatusLabel(event: PartnerEvent, now = new Date()): string {
  if (event.status === "cancelled") return "취소";
  if (event.status === "completed") return "종료";
  const start = new Date(event.start_time);
  const end = new Date(event.end_time);
  if (start <= now && now < end) return "진행";
  if (start > now) return "모집 중";
  return "종료";
}

export function splitEvents(events: PartnerEvent[], now = new Date()) {
  const active: PartnerEvent[] = [];
  const past: PartnerEvent[] = [];
  for (const event of events) {
    if (event.status === "cancelled" || event.status === "completed" || new Date(event.end_time) < now) {
      past.push(event);
    } else {
      active.push(event);
    }
  }
  active.sort((a, b) => new Date(a.start_time).getTime() - new Date(b.start_time).getTime());
  past.sort((a, b) => new Date(b.start_time).getTime() - new Date(a.start_time).getTime());
  return { active, past };
}

export function formatEventDateRange(event: Pick<PartnerEvent, "start_time" | "end_time">): string {
  const start = new Date(event.start_time);
  const end = new Date(event.end_time);
  const date = new Intl.DateTimeFormat("ko-KR", {
    month: "short",
    day: "numeric",
    weekday: "short",
    hour: "2-digit",
    minute: "2-digit",
  }).format(start);
  const endTime = new Intl.DateTimeFormat("ko-KR", {
    hour: "2-digit",
    minute: "2-digit",
  }).format(end);
  return `${date} - ${endTime}`;
}

export function toDateTimeLocal(value: string): string {
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return "";
  const offsetMs = date.getTimezoneOffset() * 60_000;
  return new Date(date.getTime() - offsetMs).toISOString().slice(0, 16);
}

function countApplicationsByEvent(rows: ApplicationRow[]) {
  const counts = new Map<string, { pending: number; paid: number }>();
  for (const row of rows) {
    const current = counts.get(row.event_id) ?? { pending: 0, paid: 0 };
    if (row.status === "pending" || row.status === "pending_review") current.pending += 1;
    if (row.status === "approved" || row.status === "paid") current.paid += 1;
    counts.set(row.event_id, current);
  }
  return counts;
}

function firstRelated<T>(value: T | T[] | null | undefined): T | null {
  if (Array.isArray(value)) return value[0] ?? null;
  return value ?? null;
}

function descriptionToText(description: unknown): string {
  if (!description) return "";
  if (typeof description === "string") return description;
  if (typeof description === "object" && "plain_text" in description) {
    const value = (description as { plain_text?: unknown }).plain_text;
    return typeof value === "string" ? value : "";
  }
  return "";
}
