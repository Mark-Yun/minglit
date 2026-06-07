"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import {
  AlertTriangle,
  CalendarPlus,
  ChevronDown,
  Loader2,
  Pencil,
  Plus,
  RotateCcw,
  Save,
  Trash2,
} from "lucide-react";
import { useEffect, useMemo, useState } from "react";

import {
  ConsoleEmptyState,
  DashboardSkeleton,
  PartnerConsoleShell,
} from "@/components/partner-console";
import {
  resolvePartnerDashboardGate,
  type ManagedPartner,
} from "@/lib/partner-dashboard";
import {
  buildEventCreatePayload,
  buildEventUpdatePayload,
  buildPartyCreatePayload,
  buildPartyUpdatePayload,
  buildRecurrencePayload,
  buildTicketTemplatePayload,
  defaultEventFormValues,
  defaultPartyFormValues,
  eventStatusLabel,
  eventToFormValues,
  fetchPartnerParties,
  formatEventDateRange,
  partyToFormValues,
  splitEvents,
  validateEventForm,
  validatePartyForm,
  type EventFormValues,
  type PartnerEvent,
  type PartnerParty,
  type PartyFormValues,
} from "@/lib/partner-events";
import { getSupabaseBrowserClient } from "@/lib/supabase";

type PartnerEventsState =
  | { status: "loading" }
  | { status: "config-error" }
  | { status: "error"; message: string }
  | { status: "no-access"; email: string }
  | { status: "ready"; partner: ManagedPartner; email: string; parties: PartnerParty[] };

type EventRouteMode =
  | { type: "create"; initialPartyId?: string }
  | { type: "edit"; eventId: string };

type PartyRouteMode =
  | { type: "create" }
  | { type: "edit"; partyId: string };

export function PartnerEventsHubPage() {
  const [state, setState] = useState<PartnerEventsState>({ status: "loading" });

  async function load(options: { showLoading?: boolean } = {}) {
    if (options.showLoading) setState({ status: "loading" });
    const supabase = getSupabaseBrowserClient();
    if (!supabase) {
      setState({ status: "config-error" });
      return;
    }

    const gate = await resolvePartnerDashboardGate(supabase, "/dashboard/events");
    if (gate.status === "anonymous") {
      window.location.href = gate.loginRedirect;
      return;
    }
    if (gate.status !== "ready") {
      setState(gate);
      return;
    }

    try {
      const parties = await fetchPartnerParties(supabase, gate.partner.id);
      setState({ status: "ready", partner: gate.partner, email: gate.email, parties });
    } catch (error) {
      setState({
        status: "error",
        message: error instanceof Error ? error.message : "파티·이벤트 목록을 불러오지 못했어요.",
      });
    }
  }

  useEffect(() => {
    let cancelled = false;
    async function initialLoad() {
      const loaded = await loadPartnerEventsState("/dashboard/events");
      if (!cancelled) setState(loaded);
    }
    void initialLoad();
    return () => {
      cancelled = true;
    };
  }, []);

  return (
    <PartnerEventsFrame state={state} mobileTitle="파티·이벤트">
      {state.status === "ready" ? (
        <EventsHubContent parties={state.parties} onReload={() => void load({ showLoading: true })} />
      ) : (
        <FrameFallback state={state} />
      )}
    </PartnerEventsFrame>
  );
}

export function PartnerPartyFormPage({ mode }: { mode: PartyRouteMode }) {
  const router = useRouter();
  const [state, setState] = useState<PartnerEventsState>({ status: "loading" });
  const [values, setValues] = useState<PartyFormValues>(defaultPartyFormValues);
  const [submitting, setSubmitting] = useState(false);
  const [formError, setFormError] = useState<string | null>(null);

  const currentParty = state.status === "ready" && mode.type === "edit"
    ? state.parties.find((party) => party.id === mode.partyId) ?? null
    : null;

  useEffect(() => {
    async function load() {
      const loaded = await loadPartnerEventsState("/dashboard/events");
      setState(loaded);
      if (loaded.status === "ready" && mode.type === "edit") {
        const party = loaded.parties.find((item) => item.id === mode.partyId);
        if (party) setValues(partyToFormValues(party));
      }
    }
    void load();
  }, [mode]);

  async function submit() {
    if (state.status !== "ready") return;
    const errors = validatePartyForm(values);
    if (errors.length > 0) {
      setFormError(errors.join(" "));
      return;
    }

    const supabase = getSupabaseBrowserClient();
    if (!supabase) return;
    setSubmitting(true);
    setFormError(null);

    try {
      if (mode.type === "create") {
        const { data, error } = await supabase.functions.invoke("partner-manage-party", {
          body: buildPartyCreatePayload(state.partner, values),
        });
        if (error) throw error;
        const partyId = typeof data === "object" && data && "party_id" in data ? String(data.party_id) : null;
        if (partyId) {
          const recurrencePayload = buildRecurrencePayload({ ...emptyParty(partyId), recurrenceRule: null }, values);
          if (recurrencePayload) {
            const { error: recurrenceError } = await supabase.functions.invoke("recurrence-rules", {
              body: recurrencePayload,
            });
            if (recurrenceError) throw recurrenceError;
          }
        }
      } else if (currentParty) {
        const { error } = await supabase.functions.invoke("partner-manage-party", {
          body: buildPartyUpdatePayload(currentParty, values),
        });
        if (error) throw error;
        const { error: ticketError } = await supabase.functions.invoke("partner-manage-party", {
          body: buildTicketTemplatePayload(currentParty, values),
        });
        if (ticketError) throw ticketError;
        const recurrencePayload = buildRecurrencePayload(currentParty, values);
        if (recurrencePayload) {
          const { error: recurrenceError } = await supabase.functions.invoke("recurrence-rules", {
            body: recurrencePayload,
          });
          if (recurrenceError) throw recurrenceError;
        }
      }
      router.push("/dashboard/events");
    } catch (error) {
      setFormError(error instanceof Error ? error.message : "파티 저장에 실패했어요.");
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <PartnerEventsFrame state={state} mobileTitle={mode.type === "create" ? "새 파티" : "파티 수정"}>
      {state.status !== "ready" ? (
        <FrameFallback state={state} />
      ) : mode.type === "edit" && !currentParty ? (
        <ConsoleEmptyState
          icon={<AlertTriangle aria-hidden="true" />}
          title="파티를 찾지 못했어요"
          description="목록으로 돌아가 다시 선택해 주세요."
          ctaHref="/dashboard/events"
          ctaLabel="목록으로"
        />
      ) : (
        <PartyFormContent
          mode={mode.type}
          values={values}
          error={formError}
          submitting={submitting}
          onChange={setValues}
          onSubmit={submit}
        />
      )}
    </PartnerEventsFrame>
  );
}

export function PartnerEventFormPage({ mode }: { mode: EventRouteMode }) {
  const router = useRouter();
  const [state, setState] = useState<PartnerEventsState>({ status: "loading" });
  const [values, setValues] = useState<EventFormValues>({
    ...defaultEventFormValues,
    partyId: mode.type === "create" ? mode.initialPartyId ?? "" : "",
  });
  const [submitting, setSubmitting] = useState(false);
  const [formError, setFormError] = useState<string | null>(null);
  const [showCancel, setShowCancel] = useState(false);
  const [cancelReason, setCancelReason] = useState("");

  const selectedParty = state.status === "ready"
    ? state.parties.find((party) => party.id === values.partyId) ?? null
    : null;
  const currentEvent = state.status === "ready" && mode.type === "edit"
    ? state.parties.flatMap((party) => party.events).find((event) => event.id === mode.eventId) ?? null
    : null;

  useEffect(() => {
    async function load() {
      const loaded = await loadPartnerEventsState("/dashboard/events");
      setState(loaded);
      if (loaded.status === "ready") {
        if (mode.type === "edit") {
          const event = loaded.parties.flatMap((party) => party.events).find((item) => item.id === mode.eventId);
          if (event) setValues(eventToFormValues(event));
        } else if (!mode.initialPartyId && loaded.parties[0]) {
          setValues((current) => ({ ...current, partyId: loaded.parties[0].id }));
        }
      }
    }
    void load();
  }, [mode]);

  async function submit() {
    if (state.status !== "ready") return;
    const errors = validateEventForm(values);
    if (mode.type === "create" && selectedParty && selectedParty.ticketTemplates.length === 0) {
      errors.push("선택한 파티에 티켓 템플릿이 없어 회차를 만들 수 없습니다.");
    }
    if (errors.length > 0) {
      setFormError(errors.join(" "));
      return;
    }

    const supabase = getSupabaseBrowserClient();
    if (!supabase) return;
    setSubmitting(true);
    setFormError(null);

    try {
      if (mode.type === "create" && selectedParty) {
        const { error } = await supabase.functions.invoke("partner-manage-event", {
          body: buildEventCreatePayload(selectedParty, values),
        });
        if (error) throw error;
      } else if (mode.type === "edit") {
        const { error } = await supabase.functions.invoke("partner-manage-event", {
          body: buildEventUpdatePayload(mode.eventId, values),
        });
        if (error) throw error;
      }
      router.push("/dashboard/events");
    } catch (error) {
      setFormError(error instanceof Error ? error.message : "회차 저장에 실패했어요.");
    } finally {
      setSubmitting(false);
    }
  }

  async function cancelEvent() {
    if (mode.type !== "edit") return;
    const supabase = getSupabaseBrowserClient();
    if (!supabase) return;
    setSubmitting(true);
    setFormError(null);
    try {
      const { error } = await supabase.functions.invoke("partner-manage-event", {
        body: { action: "update_status", event_id: mode.eventId, status: "cancelled", reason: cancelReason },
      });
      if (error) throw error;
      router.push("/dashboard/events");
    } catch (error) {
      setFormError(error instanceof Error ? error.message : "회차 취소에 실패했어요.");
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <PartnerEventsFrame state={state} mobileTitle={mode.type === "create" ? "새 회차" : "회차 수정"}>
      {state.status !== "ready" ? (
        <FrameFallback state={state} />
      ) : mode.type === "edit" && !currentEvent ? (
        <ConsoleEmptyState
          icon={<AlertTriangle aria-hidden="true" />}
          title="회차를 찾지 못했어요"
          description="목록으로 돌아가 다시 선택해 주세요."
          ctaHref="/dashboard/events"
          ctaLabel="목록으로"
        />
      ) : (
        <>
          <EventFormContent
            mode={mode.type}
            parties={state.parties}
            currentEvent={currentEvent}
            values={values}
            error={formError}
            submitting={submitting}
            onChange={setValues}
            onSubmit={submit}
            onCancelOpen={() => setShowCancel(true)}
          />
          {showCancel && currentEvent ? (
            <CancelEventDialog
              event={currentEvent}
              reason={cancelReason}
              submitting={submitting}
              onReason={setCancelReason}
              onClose={() => setShowCancel(false)}
              onConfirm={cancelEvent}
            />
          ) : null}
        </>
      )}
    </PartnerEventsFrame>
  );
}

function EventsHubContent({ parties, onReload }: { parties: PartnerParty[]; onReload: () => void }) {
  const [expandedPartyIds, setExpandedPartyIds] = useState<Set<string>>(new Set());

  const summary = useMemo(() => {
    const events = parties.flatMap((party) => party.events);
    const active = events.filter((event) => splitEvents([event]).active.length > 0).length;
    const pending = events.reduce((sum, event) => sum + event.pending_count, 0);
    return { parties: parties.length, active, pending };
  }, [parties]);

  if (parties.length === 0) {
    return (
      <ConsoleEmptyState
        icon={<CalendarPlus aria-hidden="true" />}
        title="아직 만든 파티가 없어요"
        description="첫 파티 템플릿을 만들면 반복 회차와 티켓 구성을 여기에서 관리할 수 있습니다."
        ctaHref="/parties/new"
        ctaLabel="새 파티 만들기"
      />
    );
  }

  return (
    <>
      <header className="wpe-page-header">
        <div>
          <h1>파티·이벤트</h1>
          <p>파티 {summary.parties}개 · 활성 회차 {summary.active}건 · 대기 신청 {summary.pending}건</p>
        </div>
        <div className="wpe-header-actions">
          <button className="wpe-icon-btn" type="button" aria-label="새로고침" onClick={onReload}>
            <RotateCcw aria-hidden="true" />
          </button>
          <Link className="wpe-btn wpe-btn--primary" href="/parties/new">
            <Plus aria-hidden="true" />
            새 파티 만들기
          </Link>
        </div>
      </header>

      <section className="wpe-party-list" aria-label="파티와 회차 목록">
        {parties.map((party, index) => {
          const isExpanded = expandedPartyIds.size === 0 ? index === 0 : expandedPartyIds.has(party.id);
          return (
            <PartyGroupCard
              key={party.id}
              party={party}
              isExpanded={isExpanded}
              onToggle={() => {
                setExpandedPartyIds((current) => {
                  const next = new Set(current);
                  if (next.has(party.id)) next.delete(party.id);
                  else next.add(party.id);
                  return next;
                });
              }}
            />
          );
        })}
      </section>
    </>
  );
}

function PartyGroupCard({
  party,
  isExpanded,
  onToggle,
}: {
  party: PartnerParty;
  isExpanded: boolean;
  onToggle: () => void;
}) {
  const { active, past } = splitEvents(party.events);
  const nextEvent = active[0];
  const recurrenceLabel = "반복 규칙 연결 대기";
  const canCreateEvent = party.status === "active" && party.ticketTemplates.length > 0;

  return (
    <article className="wpe-party-card">
      <button className="wpe-party-card__head" type="button" onClick={onToggle} aria-expanded={isExpanded}>
        <div className="wpe-party-card__titleblock">
          <div className="wpe-party-card__titleline">
            <h2>{party.title}</h2>
            {party.status === "draft" ? <span className="wpe-chip wpe-chip--warning">임시저장</span> : null}
            {party.status === "closed" ? <span className="wpe-chip wpe-chip--muted">닫힘</span> : null}
            <span className="wpe-chip">{recurrenceLabel}</span>
          </div>
          <p>
            {party.location?.name ?? "장소 미정"} · 정원 {party.max_participants}명 · 티켓 {party.ticketTemplates.length}종
          </p>
        </div>
        <ChevronDown className={isExpanded ? "wpe-chevron wpe-chevron--open" : "wpe-chevron"} aria-hidden="true" />
      </button>

      <div className="wpe-party-card__actions">
        <Link className="wpe-btn wpe-btn--outline" href={`/parties/${party.id}/edit`}>
          <Pencil aria-hidden="true" />
          파티 수정
        </Link>
        <Link
          className={`wpe-btn wpe-btn--outline${canCreateEvent ? "" : " wpe-btn--disabled"}`}
          href={canCreateEvent ? `/events/new?party=${party.id}` : `/parties/${party.id}/edit`}
          aria-disabled={!canCreateEvent}
        >
          <CalendarPlus aria-hidden="true" />
          회차 추가
        </Link>
      </div>

      {!isExpanded ? (
        <p className="wpe-party-card__next">
          다음 회차 — {nextEvent ? `${formatEventDateRange(nextEvent)} · ${eventStatusLabel(nextEvent)}` : "예정된 회차 없음"}
        </p>
      ) : (
        <EventRows active={active} past={past} partyTitle={party.title} />
      )}
    </article>
  );
}

function EventRows({ active, past, partyTitle }: { active: PartnerEvent[]; past: PartnerEvent[]; partyTitle: string }) {
  const rows = [...active, ...past];
  if (rows.length === 0) {
    return <div className="wpe-inline-empty">{partyTitle}에 연결된 회차가 아직 없습니다.</div>;
  }

  return (
    <div className="wpe-event-table" role="table" aria-label={`${partyTitle} 회차`}>
      <div className="wpe-event-table__head" role="row">
        <span>일시</span>
        <span>상태</span>
        <span>정원</span>
        <span>신청</span>
        <span>관리</span>
      </div>
      {rows.map((event) => {
        const status = eventStatusLabel(event);
        const isEditable = event.status === "scheduled" && status !== "진행";
        return (
          <div className="wpe-event-row" role="row" key={event.id}>
            <span className="wpe-event-row__date">{formatEventDateRange(event)}</span>
            <span className={`wpe-status wpe-status--${statusClass(status)}`}>{status}</span>
            <span>
              {event.current_participants} / {event.max_participants}명
            </span>
            <span>{event.pending_count} 대기 · {event.paid_count} 확정</span>
            <span className="wpe-event-row__actions">
              {isEditable ? (
                <>
                  <Link href={`/events/${event.id}/edit`}>수정</Link>
                  <Link className="wpe-link-danger" href={`/events/${event.id}/edit?cancel=1`}>취소</Link>
                </>
              ) : (
                "—"
              )}
            </span>
          </div>
        );
      })}
    </div>
  );
}

function PartyFormContent({
  mode,
  values,
  error,
  submitting,
  onChange,
  onSubmit,
}: {
  mode: "create" | "edit";
  values: PartyFormValues;
  error: string | null;
  submitting: boolean;
  onChange: (values: PartyFormValues) => void;
  onSubmit: () => void;
}) {
  return (
    <form
      className="wpe-form"
      onSubmit={(event) => {
        event.preventDefault();
        void onSubmit();
      }}
    >
      <FormHeader
        backHref="/dashboard/events"
        title={mode === "create" ? "새 파티 만들기" : "파티 수정"}
        description="기본 정보, 장소, 정원, 티켓 템플릿을 한 번에 관리합니다."
      />
      {error ? <FormError message={error} /> : null}
      <section className="wpe-form-section">
        <h2>기본 정보</h2>
        <label className="wpe-field">
          <span>파티 이름</span>
          <input value={values.title} onChange={(event) => onChange({ ...values, title: event.target.value })} />
        </label>
        <label className="wpe-field">
          <span>소개</span>
          <textarea value={values.description} onChange={(event) => onChange({ ...values, description: event.target.value })} rows={4} />
        </label>
        <label className="wpe-field">
          <span>상태</span>
          <select value={values.status} onChange={(event) => onChange({ ...values, status: event.target.value as PartyFormValues["status"] })}>
            <option value="active">게시</option>
            <option value="draft">임시저장</option>
            <option value="closed">닫힘</option>
          </select>
        </label>
      </section>
      <section className="wpe-form-section">
        <h2>장소와 정원</h2>
        <div className="wpe-field-grid">
          <label className="wpe-field">
            <span>장소 이름</span>
            <input value={values.locationName} onChange={(event) => onChange({ ...values, locationName: event.target.value })} />
          </label>
          <label className="wpe-field">
            <span>주소</span>
            <input value={values.locationAddress} onChange={(event) => onChange({ ...values, locationAddress: event.target.value })} />
          </label>
          <NumberField label="정원" value={values.maxParticipants} onChange={(value) => onChange({ ...values, maxParticipants: value })} />
          <NumberField label="최소 확정 인원" value={values.minConfirmedCount} onChange={(value) => onChange({ ...values, minConfirmedCount: value })} />
        </div>
      </section>
      <section className="wpe-form-section">
        <h2>티켓 템플릿</h2>
        <div className="wpe-field-grid">
          <label className="wpe-field">
            <span>티켓 이름</span>
            <input value={values.ticketName} onChange={(event) => onChange({ ...values, ticketName: event.target.value })} />
          </label>
          <NumberField label="가격" value={values.ticketPrice} onChange={(value) => onChange({ ...values, ticketPrice: value })} />
          <NumberField label="수량" value={values.ticketQuantity} onChange={(value) => onChange({ ...values, ticketQuantity: value })} />
        </div>
      </section>
      <section className="wpe-form-section">
        <h2>반복 규칙</h2>
        <label className="wpe-field">
          <span>반복 패턴</span>
          <select
            value={values.recurrencePattern}
            onChange={(event) => onChange({ ...values, recurrencePattern: event.target.value as PartyFormValues["recurrencePattern"] })}
          >
            <option value="none">반복 없음</option>
            <option value="weekly">매주</option>
            <option value="biweekly">격주</option>
            <option value="monthly">매월</option>
          </select>
        </label>
        {values.recurrencePattern !== "none" ? (
          <div className="wpe-field-grid">
            {values.recurrencePattern === "monthly" ? (
              <NumberField
                label="매월 날짜"
                value={values.recurrenceMonthDay}
                onChange={(value) => onChange({ ...values, recurrenceMonthDay: value })}
              />
            ) : (
              <label className="wpe-field">
                <span>요일</span>
                <select
                  value={values.recurrenceDayOfWeek}
                  onChange={(event) => onChange({ ...values, recurrenceDayOfWeek: Number(event.target.value) })}
                >
                  <option value={0}>일요일</option>
                  <option value={1}>월요일</option>
                  <option value={2}>화요일</option>
                  <option value={3}>수요일</option>
                  <option value={4}>목요일</option>
                  <option value={5}>금요일</option>
                  <option value={6}>토요일</option>
                </select>
              </label>
            )}
            <label className="wpe-field">
              <span>시작 시간</span>
              <input
                type="time"
                value={values.recurrenceStartTime}
                onChange={(event) => onChange({ ...values, recurrenceStartTime: event.target.value })}
              />
            </label>
            <label className="wpe-field">
              <span>종료 시간</span>
              <input
                type="time"
                value={values.recurrenceEndTime}
                onChange={(event) => onChange({ ...values, recurrenceEndTime: event.target.value })}
              />
            </label>
          </div>
        ) : null}
      </section>
      <FormActions label={mode === "create" ? "파티 만들기" : "변경 저장"} submitting={submitting} />
    </form>
  );
}

function EventFormContent({
  mode,
  parties,
  currentEvent,
  values,
  error,
  submitting,
  onChange,
  onSubmit,
  onCancelOpen,
}: {
  mode: "create" | "edit";
  parties: PartnerParty[];
  currentEvent: PartnerEvent | null;
  values: EventFormValues;
  error: string | null;
  submitting: boolean;
  onChange: (values: EventFormValues) => void;
  onSubmit: () => void;
  onCancelOpen: () => void;
}) {
  const selectedParty = parties.find((party) => party.id === values.partyId) ?? null;
  return (
    <form
      className="wpe-form"
      onSubmit={(event) => {
        event.preventDefault();
        void onSubmit();
      }}
    >
      <FormHeader
        backHref="/dashboard/events"
        title={mode === "create" ? "새 회차 만들기" : "이벤트 수정"}
        description={mode === "create" ? "파티 템플릿을 선택하면 장소와 티켓 구성을 상속합니다." : "일시나 장소 변경 시 확정 참가자 안내가 필요합니다."}
      />
      {error ? <FormError message={error} /> : null}
      <section className="wpe-form-section">
        <h2>회차 정보</h2>
        <label className="wpe-field">
          <span>파티</span>
          <select
            value={values.partyId}
            disabled={mode === "edit"}
            onChange={(event) => onChange({ ...values, partyId: event.target.value })}
          >
            {parties.map((party) => (
              <option key={party.id} value={party.id}>{party.title}</option>
            ))}
          </select>
        </label>
        {selectedParty?.ticketTemplates.length === 0 ? (
          <FormError message="이 파티에는 티켓 템플릿이 없습니다. 파티 수정에서 티켓을 먼저 추가해 주세요." />
        ) : null}
        <label className="wpe-field">
          <span>회차 제목</span>
          <input value={values.title} onChange={(event) => onChange({ ...values, title: event.target.value })} />
        </label>
        <div className="wpe-field-grid">
          <label className="wpe-field">
            <span>시작 일시</span>
            <input type="datetime-local" value={values.startLocal} onChange={(event) => onChange({ ...values, startLocal: event.target.value })} />
          </label>
          <label className="wpe-field">
            <span>종료 일시</span>
            <input type="datetime-local" value={values.endLocal} onChange={(event) => onChange({ ...values, endLocal: event.target.value })} />
          </label>
          <NumberField label="정원" value={values.maxParticipants} onChange={(value) => onChange({ ...values, maxParticipants: value })} />
          <NumberField label="최소 확정 인원" value={values.minConfirmedCount} onChange={(value) => onChange({ ...values, minConfirmedCount: value })} />
        </div>
        {mode === "edit" ? (
          <label className="wpe-field">
            <span>변경 사유</span>
            <input value={values.reason} onChange={(event) => onChange({ ...values, reason: event.target.value })} placeholder="일시 변경 안내에 사용할 사유" />
          </label>
        ) : null}
      </section>
      {selectedParty ? (
        <section className="wpe-form-section">
          <h2>상속되는 티켓</h2>
          <div className="wpe-ticket-summary">
            {selectedParty.ticketTemplates.map((template) => (
              <span key={template.id}>{template.name} · {template.price.toLocaleString("ko-KR")}원 · {template.quantity}장</span>
            ))}
          </div>
        </section>
      ) : null}
      <FormActions label={mode === "create" ? "회차 만들기" : "저장"} submitting={submitting} />
      {mode === "edit" && currentEvent?.status === "scheduled" ? (
        <section className="wpe-danger-zone">
          <div>
            <h2>이벤트 취소</h2>
            <p>취소하면 결제 건은 환불 플로우로 넘어가고 신청자에게 취소 상태가 노출됩니다.</p>
          </div>
          <button className="wpe-btn wpe-btn--danger-outline" type="button" onClick={onCancelOpen}>
            <Trash2 aria-hidden="true" />
            이벤트 취소
          </button>
        </section>
      ) : null}
    </form>
  );
}

function CancelEventDialog({
  event,
  reason,
  submitting,
  onReason,
  onClose,
  onConfirm,
}: {
  event: PartnerEvent;
  reason: string;
  submitting: boolean;
  onReason: (reason: string) => void;
  onClose: () => void;
  onConfirm: () => void;
}) {
  return (
    <div className="wpe-modal" role="dialog" aria-modal="true" aria-label="이벤트 취소 확인">
      <div className="wpe-modal__scrim" onClick={onClose} />
      <div className="wpe-modal__panel">
        <h2>이 회차를 취소할까요?</h2>
        <p>{formatEventDateRange(event)}</p>
        <div className="wpe-modal__notice">취소는 되돌릴 수 없습니다. 유료 참가자는 환불 처리 대상이 됩니다.</div>
        <label className="wpe-field">
          <span>취소 사유</span>
          <select value={reason} onChange={(event) => onReason(event.target.value)}>
            <option value="">선택 안 함</option>
            <option value="인원 미달">인원 미달</option>
            <option value="장소 문제">장소 문제</option>
            <option value="기타">기타</option>
          </select>
        </label>
        <div className="wpe-modal__actions">
          <button className="wpe-btn wpe-btn--ghost" type="button" onClick={onClose}>돌아가기</button>
          <button className="wpe-btn wpe-btn--danger" type="button" disabled={submitting} onClick={onConfirm}>
            {submitting ? <Loader2 aria-hidden="true" /> : <Trash2 aria-hidden="true" />}
            회차 취소하기
          </button>
        </div>
      </div>
    </div>
  );
}

function PartnerEventsFrame({
  state,
  mobileTitle,
  children,
}: {
  state: PartnerEventsState;
  mobileTitle: string;
  children: React.ReactNode;
}) {
  const accountLabel = state.status === "ready" ? state.partner.name : "확인 중";
  const accountSub = state.status === "ready" ? state.email : "Minglit Partner";
  return (
    <PartnerConsoleShell accountLabel={accountLabel} accountSub={accountSub} mobileTitle={mobileTitle}>
      {children}
    </PartnerConsoleShell>
  );
}

function FrameFallback({ state }: { state: PartnerEventsState }) {
  if (state.status === "loading") return <DashboardSkeleton />;
  if (state.status === "no-access") {
    return (
      <ConsoleEmptyState
        icon={<AlertTriangle aria-hidden="true" />}
        title="파트너 권한이 없어요"
        description={`${state.email} 계정에 연결된 파트너 권한이 없습니다.`}
        ctaHref="/login"
        ctaLabel="다른 계정으로 로그인"
      />
    );
  }
  return (
    <ConsoleEmptyState
      icon={<AlertTriangle aria-hidden="true" />}
      title="화면을 열 수 없어요"
      description={state.status === "config-error" ? "Supabase 공개 환경변수가 설정되지 않았습니다." : state.status === "error" ? state.message : "다시 시도해 주세요."}
      ctaHref="/dashboard"
      ctaLabel="홈으로"
    />
  );
}

async function loadPartnerEventsState(next: string): Promise<PartnerEventsState> {
  const supabase = getSupabaseBrowserClient();
  if (!supabase) return { status: "config-error" };
  const gate = await resolvePartnerDashboardGate(supabase, next);
  if (gate.status === "anonymous") {
    window.location.href = gate.loginRedirect;
    return { status: "loading" };
  }
  if (gate.status !== "ready") return gate;
  try {
    const parties = await fetchPartnerParties(supabase, gate.partner.id);
    return { status: "ready", partner: gate.partner, email: gate.email, parties };
  } catch (error) {
    return {
      status: "error",
      message: error instanceof Error ? error.message : "파티·이벤트 데이터를 불러오지 못했어요.",
    };
  }
}

function FormHeader({ backHref, title, description }: { backHref: string; title: string; description: string }) {
  return (
    <header className="wpe-form-header">
      <Link href={backHref}>← 목록으로</Link>
      <h1>{title}</h1>
      <p>{description}</p>
    </header>
  );
}

function FormError({ message }: { message: string }) {
  return (
    <div className="wpe-form-error" role="alert">
      <AlertTriangle aria-hidden="true" />
      {message}
    </div>
  );
}

function FormActions({ label, submitting }: { label: string; submitting: boolean }) {
  return (
    <div className="wpe-form-actions">
      <button className="wpe-btn wpe-btn--primary" type="submit" disabled={submitting}>
        {submitting ? <Loader2 aria-hidden="true" /> : <Save aria-hidden="true" />}
        {submitting ? "저장 중..." : label}
      </button>
    </div>
  );
}

function NumberField({ label, value, onChange }: { label: string; value: number; onChange: (value: number) => void }) {
  return (
    <label className="wpe-field">
      <span>{label}</span>
      <input type="number" value={value} min={0} max={999} onChange={(event) => onChange(Number(event.target.value))} />
    </label>
  );
}

function emptyParty(id: string): PartnerParty {
  return {
    id,
    title: "",
    status: "active",
    min_confirmed_count: 0,
    max_participants: 0,
    descriptionText: "",
    location: null,
    ticketTemplates: [],
    recurrenceRule: null,
    events: [],
  };
}

function statusClass(status: string): string {
  if (status === "취소") return "cancelled";
  if (status === "종료") return "completed";
  if (status === "진행") return "active";
  return "scheduled";
}
