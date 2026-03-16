-- Settlement Phase 4: Reconciliation Schema
-- REQ-4.4.01~10: 대사 테이블, 불일치 분류, kill switch 자동 활성화

-- ============================================================
-- 1. reconciliation_runs — 대사 실행 기록
-- ============================================================
create table if not exists public.reconciliation_runs (
  id                  uuid        primary key default gen_random_uuid(),
  run_date            date        not null,
  run_type            text        not null check (run_type in ('DAILY', 'PAYOUT_TRIGGERED')),
  status              text        not null default 'RUNNING'
                                  check (status in ('RUNNING', 'COMPLETED', 'FAILED')),
  source_hash         text,
  total_count         int         not null default 0,
  matched_count       int         not null default 0,
  mismatched_count    int         not null default 0,
  critical_count      int         not null default 0,
  error_message       text,
  started_at          timestamptz not null default now(),
  completed_at        timestamptz
);

create unique index if not exists idx_reconciliation_runs_date_type_running
  on public.reconciliation_runs (run_date, run_type)
  where status = 'RUNNING';

-- ============================================================
-- 2. reconciliation_results — 개별 매칭/불일치 결과
-- ============================================================
create type public.recon_mismatch_type as enum (
  'MATCHED',
  'MISSING_IN_PORTONE',
  'MISSING_IN_LEDGER',
  'AMOUNT_MISMATCH',
  'DUPLICATE',
  'DATE_SHIFT',
  'STATUS_MISMATCH'
);

create type public.recon_severity as enum (
  'INFO',
  'WARNING',
  'CRITICAL'
);

create table if not exists public.reconciliation_results (
  id                      uuid                        primary key default gen_random_uuid(),
  run_id                  uuid                        not null references public.reconciliation_runs(id) on delete cascade,
  settlement_item_id      uuid                        references public.settlement_items(id),
  portone_settlement_id   text,
  mismatch_type           public.recon_mismatch_type  not null,
  severity                public.recon_severity       not null default 'INFO',
  details                 jsonb                       not null default '{}',
  created_at              timestamptz                 not null default now()
);

create unique index if not exists idx_reconciliation_results_run_item
  on public.reconciliation_results (run_id, settlement_item_id)
  where settlement_item_id is not null;

create index if not exists idx_reconciliation_results_run_id
  on public.reconciliation_results (run_id);

create index if not exists idx_reconciliation_results_mismatch_type
  on public.reconciliation_results (mismatch_type, severity);

-- ============================================================
-- 3. classify_reconciliation_mismatch()
--    Determines mismatch type and severity given two amounts
--    (or null for missing entries)
-- ============================================================
create or replace function public.classify_reconciliation_mismatch(
  p_ledger_amount       bigint,
  p_portone_amount      bigint,
  p_ledger_date         date,
  p_portone_date        date,
  p_ledger_status       text,
  p_portone_status      text
)
returns table(mismatch_type public.recon_mismatch_type, severity public.recon_severity)
language plpgsql
security definer
set search_path = public
as $$
begin
  if p_ledger_amount is null and p_portone_amount is not null then
    return query select 'MISSING_IN_LEDGER'::public.recon_mismatch_type, 'CRITICAL'::public.recon_severity;
    return;
  end if;

  if p_portone_amount is null and p_ledger_amount is not null then
    return query select 'MISSING_IN_PORTONE'::public.recon_mismatch_type, 'CRITICAL'::public.recon_severity;
    return;
  end if;

  if p_ledger_amount is not null and p_portone_amount is not null then
    if abs(p_ledger_amount - p_portone_amount) > 1 then
      return query select 'AMOUNT_MISMATCH'::public.recon_mismatch_type, 'CRITICAL'::public.recon_severity;
      return;
    end if;

    if p_ledger_date is not null and p_portone_date is not null
       and p_ledger_date != p_portone_date then
      return query select 'DATE_SHIFT'::public.recon_mismatch_type, 'WARNING'::public.recon_severity;
      return;
    end if;

    if p_ledger_status is not null and p_portone_status is not null
       and p_ledger_status != p_portone_status then
      return query select 'STATUS_MISMATCH'::public.recon_mismatch_type, 'WARNING'::public.recon_severity;
      return;
    end if;
  end if;

  return query select 'MATCHED'::public.recon_mismatch_type, 'INFO'::public.recon_severity;
end;
$$;

-- ============================================================
-- 4. process_reconciliation_kill_switch()
--    Activates kill switch if CRITICAL mismatches >= threshold
--    REQ-4.4.08: auto kill switch on critical mismatches
-- ============================================================
create or replace function public.process_reconciliation_kill_switch(
  p_run_id uuid
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_critical_count int;
  v_threshold      int;
  v_activated      boolean := false;
begin
  select count(*) into v_critical_count
  from public.reconciliation_results
  where run_id = p_run_id
    and severity = 'CRITICAL';

  select (value->>'value')::int into v_threshold
  from public.system_settings
  where key = 'reconciliation_kill_switch_threshold';

  v_threshold := coalesce(v_threshold, 3);

  if v_critical_count >= v_threshold then
    perform public.toggle_settlement_kill_switch(true, 'reconciliation_auto');
    v_activated := true;
  end if;

  return v_activated;
end;
$$;

alter table public.reconciliation_runs enable row level security;
create policy "reconciliation_runs_service_role_only"
  on public.reconciliation_runs
  using (auth.role() = 'service_role');

alter table public.reconciliation_results enable row level security;
create policy "reconciliation_results_service_role_only"
  on public.reconciliation_results
  using (auth.role() = 'service_role');

create index if not exists idx_reconciliation_results_settlement_item_id
  on public.reconciliation_results (settlement_item_id)
  where settlement_item_id is not null;

revoke execute on function public.classify_reconciliation_mismatch(bigint, bigint, date, date, text, text) from public;
revoke execute on function public.process_reconciliation_kill_switch(uuid) from public;
grant execute on function public.classify_reconciliation_mismatch(bigint, bigint, date, date, text, text) to service_role;
grant execute on function public.process_reconciliation_kill_switch(uuid) to service_role;
