-- Settlement Phase 1: DB Schema Foundation
-- Adds 5 new settlement tables alongside existing `settlements` table (parallel coexistence).
-- DOES NOT drop or modify the existing `settlements` table, triggers, or cron jobs.
-- Business logic (state machine, CAS, audit triggers) comes in Phase 2.

-- ============================================================
-- 1. settlement_items (정산 원장 — core ledger)
-- Created first WITHOUT payout FK (payouts table doesn't exist yet).
-- FK to payouts added via ALTER TABLE after payouts is created.
-- ============================================================

create table if not exists public.settlement_items (
  id uuid primary key default gen_random_uuid(),

  partner_id uuid not null
    references public.partners(id) on delete restrict,  -- RESTRICT not CASCADE: protect financial data
  settlement_period_start date not null,
  settlement_period_end   date not null,

  currency char(3) not null default 'KRW',

  source_type text not null,
  source_id   text not null,

  status text not null check (status in
    ('PENDING','HOLD','CANCELED','READY','PROCESSING','COMPLETED','FAILED')
  ),

  gross_amount        bigint not null check (gross_amount >= 0),
  platform_fee_rate   decimal(5,2) not null check (platform_fee_rate >= 0 and platform_fee_rate <= 100),
  platform_fee_amount bigint not null check (platform_fee_amount >= 0),

  pg_fee_rate         decimal(5,2) not null check (pg_fee_rate >= 0 and pg_fee_rate <= 100),
  pg_fee_amount       bigint not null check (pg_fee_amount >= 0),

  vat_rate            decimal(5,2) not null check (vat_rate >= 0 and vat_rate <= 100),
  vat_amount          bigint not null check (vat_amount >= 0),

  net_amount          bigint not null check (net_amount >= 0),

  hold_reason_code    text,
  hold_reason_detail  text,
  failure_reason_code text,
  failure_message     text,

  retryable boolean not null default false,
  retry_count int not null default 0 check (retry_count >= 0),
  next_retry_at timestamptz,

  processing_started_at timestamptz,
  processing_ended_at   timestamptz,

  payout_id uuid,  -- FK added below after payouts table is created

  calc_checksum char(64) not null,
  version int not null default 1 check (version >= 1),

  event_completed_at timestamptz,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint uq_settlement_items_source unique (partner_id, source_type, source_id),
  constraint ck_settlement_items_period check (settlement_period_start <= settlement_period_end),
  constraint ck_settlement_items_hold_reason check (
    (status <> 'HOLD') or (hold_reason_code is not null)
  )
);

create index if not exists idx_settlement_items_partner_period
  on public.settlement_items(partner_id, settlement_period_start, settlement_period_end);

create index if not exists idx_settlement_items_status
  on public.settlement_items(status);

create index if not exists idx_settlement_items_payout
  on public.settlement_items(payout_id);

create index if not exists idx_settlement_items_source
  on public.settlement_items(source_type, source_id);

-- moddatetime trigger (matching codebase pattern from settlements table)
create trigger handle_updated_at before update on public.settlement_items
  for each row execute procedure moddatetime(updated_at);

-- ============================================================
-- 2. payouts (파트너별 지급 묶음)
-- ============================================================

create table if not exists public.payouts (
  id uuid primary key default gen_random_uuid(),
  partner_id uuid not null
    references public.partners(id) on delete restrict,

  payout_period_start date not null,
  payout_period_end   date not null,
  currency char(3) not null default 'KRW',

  status text not null check (status in ('CREATED','READY','PROCESSING','COMPLETED','FAILED','CANCELED')),

  scheduled_at timestamptz not null,
  processing_started_at timestamptz,
  processing_ended_at   timestamptz,

  item_count int not null default 0 check (item_count >= 0),

  total_gross_amount        bigint not null check (total_gross_amount >= 0),
  total_platform_fee_amount bigint not null check (total_platform_fee_amount >= 0),
  total_pg_fee_amount       bigint not null check (total_pg_fee_amount >= 0),
  total_vat_amount          bigint not null check (total_vat_amount >= 0),
  total_net_amount          bigint not null check (total_net_amount >= 0),

  bank_account_snapshot jsonb not null default '{}'::jsonb,

  payout_request_idempotency_key text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint ck_payouts_period check (payout_period_start <= payout_period_end)
);

create unique index if not exists uq_payouts_partner_period
  on public.payouts(partner_id, payout_period_start, payout_period_end);

create index if not exists idx_payouts_status_scheduled
  on public.payouts(status, scheduled_at);

-- REQ-5.3.05: idempotency key uniqueness per partner
create unique index if not exists uq_payouts_partner_idempotency
  on public.payouts(partner_id, payout_request_idempotency_key)
  where payout_request_idempotency_key is not null;

-- moddatetime trigger
create trigger handle_updated_at before update on public.payouts
  for each row execute procedure moddatetime(updated_at);

-- ============================================================
-- 3. Add payout FK to settlement_items (now that payouts exists)
-- ============================================================

alter table public.settlement_items
  add constraint fk_settlement_items_payout
    foreign key (payout_id) references public.payouts(id);

-- ============================================================
-- 4. settlement_histories (감사 로그 — append-only)
-- NO moddatetime trigger (append-only: no updates allowed)
-- ============================================================

create table if not exists public.settlement_histories (
  id uuid primary key default gen_random_uuid(),
  settlement_item_id uuid not null,

  event_at timestamptz not null default now(),
  event_type text not null,
  actor_type text not null check (actor_type in ('SYSTEM','JOB','ADMIN','PARTNER')),
  actor_id text not null,

  from_status text not null,
  to_status   text not null,

  idempotency_key text,
  details jsonb not null default '{}'::jsonb,

  constraint fk_settlement_histories_item
    foreign key (settlement_item_id) references public.settlement_items(id)
);

create index if not exists idx_settlement_histories_item_eventat
  on public.settlement_histories(settlement_item_id, event_at);

create index if not exists idx_settlement_histories_event_type
  on public.settlement_histories(event_type);

-- REQ-5.2.06: prevent duplicate idempotency keys per item+event_type
create unique index if not exists uq_settlement_histories_idempotency
  on public.settlement_histories(settlement_item_id, event_type, idempotency_key)
  where idempotency_key is not null;

-- REQ-5.2.07: audit query index on actor
create index if not exists idx_settlement_histories_actor
  on public.settlement_histories(actor_type, actor_id);

-- ============================================================
-- 5. payout_transfers (송금 시도 + 멱등성 키)
-- ============================================================

create table if not exists public.payout_transfers (
  id uuid primary key default gen_random_uuid(),
  payout_id uuid not null,

  provider text not null,
  idempotency_key text not null,

  attempt_no int not null check (attempt_no >= 1),
  status text not null check (status in ('CREATED','REQUESTED','SUCCEEDED','FAILED')),

  amount bigint not null check (amount >= 0),
  currency char(3) not null default 'KRW',

  provider_transfer_id text,
  requested_at timestamptz,
  responded_at timestamptz,

  response_code text,
  response_message text,

  error_class text,
  retryable boolean not null default false,
  next_retry_at timestamptz,

  request_payload  jsonb not null default '{}'::jsonb,
  response_payload jsonb not null default '{}'::jsonb,

  created_at timestamptz not null default now(),

  constraint fk_payout_transfers_payout
    foreign key (payout_id) references public.payouts(id),
  constraint uq_payout_transfers_idem unique (provider, idempotency_key)
);

create index if not exists idx_payout_transfers_payout
  on public.payout_transfers(payout_id);

create index if not exists idx_payout_transfers_status_retry
  on public.payout_transfers(status, next_retry_at);

-- ============================================================
-- 6. adjustment_items (사후 차감/조정 — 원장 불변 원칙)
-- ============================================================

create table if not exists public.adjustment_items (
  id uuid primary key default gen_random_uuid(),
  partner_id uuid not null
    references public.partners(id) on delete restrict,

  adjustment_type text not null check (adjustment_type in
    ('REFUND','CHARGEBACK','MANUAL_DEDUCT','MANUAL_ADD','FEE_CORRECTION','TAX_CORRECTION')
  ),

  amount_signed bigint not null check (amount_signed <> 0),
  currency char(3) not null default 'KRW',

  reason_code text not null,
  reason_detail text,

  related_settlement_item_id uuid,
  related_payout_id uuid,
  source_type text,
  source_id text,

  evidence_url text,
  status text not null check (status in ('CREATED','APPLIED','CANCELED')),

  created_by_actor_type text not null check (created_by_actor_type in ('SYSTEM','ADMIN')),
  created_by_actor_id text not null,

  created_at timestamptz not null default now(),

  constraint fk_adjustment_related_item
    foreign key (related_settlement_item_id) references public.settlement_items(id),
  constraint fk_adjustment_related_payout
    foreign key (related_payout_id) references public.payouts(id)
);

create index if not exists idx_adjustment_partner_created
  on public.adjustment_items(partner_id, created_at);

create index if not exists idx_adjustment_related
  on public.adjustment_items(related_settlement_item_id, related_payout_id);

-- REQ-5.3.25: prevent duplicate adjustments for same source
create unique index if not exists uq_adjustment_source
  on public.adjustment_items(partner_id, adjustment_type, source_type, source_id)
  where source_type is not null and source_id is not null;

-- ============================================================
-- 7. RLS (Row Level Security)
-- Pattern: is_super_admin() OR has_partner_permission(partner_id, 'SETTLEMENT_VIEW')
-- ============================================================

-- settlement_items
alter table public.settlement_items enable row level security;

create policy "Partner can read own settlement_items"
  on public.settlement_items for select
  using (
    public.is_super_admin()
    or public.has_partner_permission(partner_id, 'SETTLEMENT_VIEW')
  );

-- payouts
alter table public.payouts enable row level security;

create policy "Partner can read own payouts"
  on public.payouts for select
  using (
    public.is_super_admin()
    or public.has_partner_permission(partner_id, 'SETTLEMENT_VIEW')
  );

-- adjustment_items
alter table public.adjustment_items enable row level security;

create policy "Partner can read own adjustment_items"
  on public.adjustment_items for select
  using (
    public.is_super_admin()
    or public.has_partner_permission(partner_id, 'SETTLEMENT_VIEW')
  );

-- settlement_histories: SELECT via settlement_item subquery, INSERT for service role only
-- No UPDATE/DELETE policies: append-only enforced at DB level
alter table public.settlement_histories enable row level security;

create policy "Partner can read related settlement_histories"
  on public.settlement_histories for select
  using (
    public.is_super_admin()
    or exists (
      select 1 from public.settlement_items si
      where si.id = settlement_item_id
        and public.has_partner_permission(si.partner_id, 'SETTLEMENT_VIEW')
    )
  );

-- payout_transfers: SELECT via payout subquery
alter table public.payout_transfers enable row level security;

create policy "Partner can read related payout_transfers"
  on public.payout_transfers for select
  using (
    public.is_super_admin()
    or exists (
      select 1 from public.payouts p
      where p.id = payout_id
        and public.has_partner_permission(p.partner_id, 'SETTLEMENT_VIEW')
    )
  );
