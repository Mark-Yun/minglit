-- Settlement Phase 2: State Machine & Ledger Logic
-- Builds business logic on top of Phase 1 tables.
-- Full cutover: trigger writes to settlement_items (not settlements).
-- Old settlements table preserved as read-only archive (no DROP).

-- ============================================================
-- 0. Prerequisites
-- ============================================================
create extension if not exists pgcrypto;

-- ============================================================
-- Task 3: Remove net_amount >= 0 CHECK constraint
-- Allows negative net_amount (e.g., when refunds exceed gross)
-- ============================================================
alter table public.settlement_items
  drop constraint if exists settlement_items_net_amount_check;

-- ============================================================
-- Task 1a: calculate_settlement_amounts()
-- REQ-7.01: floor-based fee calculation (not round)
-- ============================================================
create or replace function public.calculate_settlement_amounts(
  p_gross              bigint,
  p_platform_fee_rate  decimal(5,2),
  p_pg_fee_rate        decimal(5,2),
  p_vat_rate           decimal(5,2),
  out out_platform_fee_amount bigint,
  out out_pg_fee_amount       bigint,
  out out_vat_amount          bigint,
  out out_net_amount          bigint
)
returns record
language plpgsql
immutable
security definer
set search_path = public
as $$
begin
  out_platform_fee_amount := floor(p_gross * p_platform_fee_rate / 100)::bigint;
  out_pg_fee_amount       := floor(p_gross * p_pg_fee_rate / 100)::bigint;
  out_vat_amount          := floor((out_platform_fee_amount + out_pg_fee_amount) * p_vat_rate / 100)::bigint;
  out_net_amount          := p_gross - out_platform_fee_amount - out_pg_fee_amount - out_vat_amount;
end;
$$;

-- ============================================================
-- Task 1b: calculate_settlement_checksum()
-- REQ-7.03: SHA-256 of canonical string
-- Format: "{partner_id}|{period_start}|{period_end}|{currency}|{gross}|
--          {platform_fee_rate}|{pg_fee_rate}|{vat_rate}|
--          {platform_fee_amount}|{pg_fee_amount}|{vat_amount}|{net_amount}|v1"
-- ============================================================
create or replace function public.calculate_settlement_checksum(
  p_partner_id            uuid,
  p_period_start          date,
  p_period_end            date,
  p_currency              char(3),
  p_gross                 bigint,
  p_platform_fee_rate     decimal(5,2),
  p_pg_fee_rate           decimal(5,2),
  p_vat_rate              decimal(5,2),
  p_platform_fee_amount   bigint,
  p_pg_fee_amount         bigint,
  p_vat_amount            bigint,
  p_net_amount            bigint
)
returns char(64)
language plpgsql
immutable
security definer
set search_path = public
as $$
declare
  v_canonical text;
begin
  v_canonical :=
    p_partner_id::text || '|' ||
    p_period_start::text || '|' ||
    p_period_end::text || '|' ||
    p_currency || '|' ||
    p_gross::text || '|' ||
    p_platform_fee_rate::text || '|' ||
    p_pg_fee_rate::text || '|' ||
    p_vat_rate::text || '|' ||
    p_platform_fee_amount::text || '|' ||
    p_pg_fee_amount::text || '|' ||
    p_vat_amount::text || '|' ||
    p_net_amount::text || '|' ||
    'v1';
  return encode(extensions.digest(v_canonical, 'sha256'), 'hex');
end;
$$;

-- ============================================================
-- Task 2: transition_settlement_status()
-- REQ-3.2.15: CAS-based state transition with audit logging
-- Allowed transitions (13):
--   PENDING  → READY, HOLD, CANCELED
--   HOLD     → READY, CANCELED
--   READY    → PROCESSING, HOLD, CANCELED
--   PROCESSING → COMPLETED, FAILED
--   FAILED   → READY, HOLD, CANCELED
-- COMPLETED and CANCELED are terminal — no transitions allowed
-- ============================================================
create or replace function public.transition_settlement_status(
  p_item_id              uuid,
  p_expected_version     int,
  p_new_status           text,
  p_actor_type           text,
  p_actor_id             text,
  p_event_type           text,
  p_hold_reason_code     text    default null,
  p_hold_reason_detail   text    default null,
  p_failure_reason_code  text    default null,
  p_failure_message      text    default null,
  p_details              jsonb   default '{}',
  p_idempotency_key      text    default null
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_current_status  text;
  v_current_version int;
  v_rows_updated    int;
  v_allowed_targets text[];
begin
  -- Lock and read current state
  select status, version
  into   v_current_status, v_current_version
  from   public.settlement_items
  where  id = p_item_id
  for    update;

  if not found then
    raise exception 'settlement_item not found: %', p_item_id;
  end if;

  -- Reject any transition from terminal states (REQ-3.2.16)
  if v_current_status in ('COMPLETED', 'CANCELED') then
    raise exception
      'Cannot transition from terminal state % to % for item %',
      v_current_status, p_new_status, p_item_id;
  end if;

  -- Validate transition against allowed matrix
  v_allowed_targets := case v_current_status
    when 'PENDING'    then array['READY','HOLD','CANCELED']
    when 'HOLD'       then array['READY','CANCELED']
    when 'READY'      then array['PROCESSING','HOLD','CANCELED']
    when 'PROCESSING' then array['COMPLETED','FAILED']
    when 'FAILED'     then array['READY','HOLD','CANCELED']
    else array[]::text[]
  end;

  if not (p_new_status = any(v_allowed_targets)) then
    raise exception
      'Invalid transition: % → % is not allowed for item %',
      v_current_status, p_new_status, p_item_id;
  end if;

  -- Guard: HOLD requires hold_reason_code (REQ-3.2.23)
  if p_new_status = 'HOLD' and p_hold_reason_code is null then
    raise exception 'hold_reason_code is required when transitioning to HOLD';
  end if;

  -- Guard: FAILED requires failure_reason_code (REQ-3.2.18)
  if p_new_status = 'FAILED' and p_failure_reason_code is null then
    raise exception 'failure_reason_code is required when transitioning to FAILED';
  end if;

  -- CAS update (REQ-3.2.15)
  update public.settlement_items
  set
    status               = p_new_status,
    version              = version + 1,
    hold_reason_code     = case when p_new_status = 'HOLD'   then p_hold_reason_code    else hold_reason_code end,
    hold_reason_detail   = case when p_new_status = 'HOLD'   then p_hold_reason_detail  else hold_reason_detail end,
    failure_reason_code  = case when p_new_status = 'FAILED' then p_failure_reason_code else failure_reason_code end,
    failure_message      = case when p_new_status = 'FAILED' then p_failure_message     else failure_message end,
    processing_started_at = case when p_new_status = 'PROCESSING' then now() else processing_started_at end,
    processing_ended_at   = case when p_new_status in ('COMPLETED','FAILED') then now() else processing_ended_at end,
    updated_at           = now()
  where id      = p_item_id
    and version = p_expected_version
    and status  = v_current_status;

  get diagnostics v_rows_updated = row_count;

  if v_rows_updated = 0 then
    raise exception
      'CAS failure: version mismatch or concurrent modification for item %. Expected version: %',
      p_item_id, p_expected_version;
  end if;

  -- Append-only audit log (REQ-3.2.10)
  insert into public.settlement_histories (
    settlement_item_id,
    event_type,
    actor_type,
    actor_id,
    from_status,
    to_status,
    details,
    idempotency_key
  ) values (
    p_item_id,
    p_event_type,
    p_actor_type,
    p_actor_id,
    v_current_status,
    p_new_status,
    coalesce(p_details, '{}'),
    p_idempotency_key
  );

  return true;
end;
$$;

-- ============================================================
-- Task 4: Modify create_settlement_on_event_completion()
-- Full cutover: writes to settlement_items (not settlements)
-- Uses calculate_settlement_amounts() (floor) and checksum
-- ============================================================
create or replace function public.create_settlement_on_event_completion()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_partner_id            uuid;
  v_event_date            date;
  v_total_sales           bigint := 0;
  v_platform_fee_rate     decimal(5,2) := 5.00;
  v_pg_fee_rate           decimal(5,2) := 3.50;
  v_vat_rate              decimal(5,2) := 10.00;
  v_platform_fee_amount   bigint;
  v_pg_fee_amount         bigint;
  v_vat_amount            bigint;
  v_net_amount            bigint;
  v_checksum              char(64);
  v_amounts               record;
begin
  if (new.status = 'completed' and old.status is distinct from 'completed') then

    -- Get partner_id from parties
    select p.partner_id
    into   v_partner_id
    from   public.parties p
    where  p.id = new.party_id;

    -- Settlement period = event end date
    v_event_date := coalesce(new.end_time, now())::date;

    -- Aggregate total sales from event_applications (gross, before refunds)
    select coalesce(
      sum(case when ea.status in ('paid', 'approved') then ea.payment_amount else 0 end),
      0
    )
    into v_total_sales
    from public.event_applications ea
    where ea.event_id = new.id;

    -- Calculate amounts using floor() (REQ-4.1.3, REQ-7.01)
    select * into v_amounts
    from public.calculate_settlement_amounts(
      v_total_sales::bigint,
      v_platform_fee_rate,
      v_pg_fee_rate,
      v_vat_rate
    );

    v_platform_fee_amount := v_amounts.out_platform_fee_amount;
    v_pg_fee_amount       := v_amounts.out_pg_fee_amount;
    v_vat_amount          := v_amounts.out_vat_amount;
    v_net_amount          := v_amounts.out_net_amount;

    -- Calculate SHA-256 checksum (REQ-7.03)
    v_checksum := public.calculate_settlement_checksum(
      v_partner_id,
      v_event_date,
      v_event_date,
      'KRW',
      v_total_sales::bigint,
      v_platform_fee_rate,
      v_pg_fee_rate,
      v_vat_rate,
      v_platform_fee_amount,
      v_pg_fee_amount,
      v_vat_amount,
      v_net_amount
    );

    -- Full cutover: insert into settlement_items (not settlements)
    insert into public.settlement_items (
      partner_id,
      settlement_period_start,
      settlement_period_end,
      currency,
      source_type,
      source_id,
      status,
      gross_amount,
      platform_fee_rate,
      platform_fee_amount,
      pg_fee_rate,
      pg_fee_amount,
      vat_rate,
      vat_amount,
      net_amount,
      calc_checksum,
      event_completed_at
    )
    values (
      v_partner_id,
      v_event_date,
      v_event_date,
      'KRW',
      'EVENT',
      new.id::text,
      'PENDING',
      v_total_sales::bigint,
      v_platform_fee_rate,
      v_platform_fee_amount,
      v_pg_fee_rate,
      v_pg_fee_amount,
      v_vat_rate,
      v_vat_amount,
      v_net_amount,
      v_checksum,
      new.end_time
    )
    on conflict on constraint uq_settlement_items_source do update
    set
      gross_amount          = excluded.gross_amount,
      platform_fee_rate     = excluded.platform_fee_rate,
      platform_fee_amount   = excluded.platform_fee_amount,
      pg_fee_rate           = excluded.pg_fee_rate,
      pg_fee_amount         = excluded.pg_fee_amount,
      vat_rate              = excluded.vat_rate,
      vat_amount            = excluded.vat_amount,
      net_amount            = excluded.net_amount,
      calc_checksum         = excluded.calc_checksum,
      event_completed_at    = excluded.event_completed_at,
      updated_at            = now();

  end if;
  return new;
end;
$$;

-- ============================================================
-- Task 5a: Replace update_settlement_ready_status()
-- 14-day hold (was 7-day), uses transition_settlement_status()
-- Includes checksum re-validation before READY transition
-- ============================================================
create or replace function public.update_settlement_ready_status()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_item          record;
  v_expected_cs   char(64);
begin
  for v_item in
    select id, version, partner_id, settlement_period_start, settlement_period_end,
           currency, gross_amount, platform_fee_rate, pg_fee_rate, vat_rate,
           platform_fee_amount, pg_fee_amount, vat_amount, net_amount, calc_checksum
    from   public.settlement_items
    where  status = 'PENDING'
    and    event_completed_at <= now() - interval '14 days'
  loop
    -- Re-validate checksum before transitioning to READY (REQ-7.03)
    v_expected_cs := public.calculate_settlement_checksum(
      v_item.partner_id,
      v_item.settlement_period_start,
      v_item.settlement_period_end,
      v_item.currency,
      v_item.gross_amount,
      v_item.platform_fee_rate,
      v_item.pg_fee_rate,
      v_item.vat_rate,
      v_item.platform_fee_amount,
      v_item.pg_fee_amount,
      v_item.vat_amount,
      v_item.net_amount
    );

    if v_item.calc_checksum = v_expected_cs then
      -- Checksum valid → transition to READY
      perform public.transition_settlement_status(
        v_item.id,
        v_item.version,
        'READY',
        'SYSTEM',
        'settlement_cron_job',
        'calc_succeeded',
        null::text, null::text, null::text, null::text,
        '{"source": "update_settlement_ready_status"}'::jsonb,
        null::text
      );
    else
      -- Checksum mismatch → HOLD for manual review (PENDING→FAILED not in allowed matrix)
      perform public.transition_settlement_status(
        v_item.id,
        v_item.version,
        'HOLD',
        'SYSTEM',
        'settlement_cron_job',
        'hold_applied',
        'CHECKSUM_MISMATCH'::text,
        'Checksum validation failed during ready transition'::text,
        null::text, null::text,
        ('{"expected": "' || v_expected_cs || '", "actual": "' || v_item.calc_checksum || '"}')::jsonb,
        null::text
      );
    end if;

  end loop;
end;
$$;

-- Update cron: same name replaces existing job, 14-day logic applied
select cron.schedule(
  'settlement-status-transition',
  '0 3 * * *',
  $$select public.update_settlement_ready_status();$$
);

-- ============================================================
-- Task 6: Stuck processing check (REQ-3.2.13)
-- PROCESSING > 2h → auto FAILED
-- No-op until Phase 3 creates PROCESSING items
-- ============================================================
create or replace function public.check_stuck_processing_settlements()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_item record;
begin
  for v_item in
    select id, version
    from   public.settlement_items
    where  status = 'PROCESSING'
    and    processing_started_at < now() - interval '2 hours'
  loop
    perform public.transition_settlement_status(
      v_item.id,
      v_item.version,
      'FAILED',
      'SYSTEM',
      'stuck_check_job',
      'payout_failed',
      null::text, null::text,
      'TIMEOUT_STUCK_PROCESSING',
      'Processing exceeded 2 hour limit',
      '{"source": "check_stuck_processing_settlements"}'::jsonb,
      null::text
    );
  end loop;
end;
$$;

-- Cron: every 30 minutes
select cron.schedule(
  'settlement-stuck-processing-check',
  '*/30 * * * *',
  $$select public.check_stuck_processing_settlements();$$
);
