-- Settlement Phase 4: Monitoring Views & Alarm Function
-- settlement_metrics view + settlement_alarm_results + check_settlement_alarms()

-- ============================================================
-- 1. settlement_metrics — operational view
-- ============================================================
create or replace view public.settlement_metrics as
with
  status_counts as (
    select
      status,
      count(*) as cnt
    from public.settlement_items
    group by status
  ),
  processing_times as (
    select
      avg(extract(epoch from (processing_ended_at - processing_started_at))) as avg_processing_seconds
    from public.settlement_items
    where status in ('COMPLETED', 'FAILED')
      and processing_ended_at is not null
      and processing_started_at is not null
      and processing_started_at > now() - interval '24 hours'
  ),
  last_24h as (
    select
      count(*) filter (where status = 'COMPLETED') as completed_24h,
      count(*) filter (where status = 'FAILED')    as failed_24h,
      count(*) as total_24h
    from public.settlement_items
    where updated_at > now() - interval '24 hours'
  ),
  dlq_depth as (
    select count(*) as cnt
    from public.settlement_items
    where status = 'HOLD'
      and hold_reason_code like 'SYSTEM%'
  ),
  last_recon as (
    select
      max(completed_at)   as last_run_at,
      max(critical_count) as last_critical_count
    from public.reconciliation_runs
    where status = 'COMPLETED'
      and completed_at > now() - interval '48 hours'
  ),
  last_payout as (
    select max(updated_at) as last_success_at
    from public.payouts
    where status = 'COMPLETED'
  )
select
  coalesce((select cnt from status_counts where status = 'PENDING'),    0) as pending_count,
  coalesce((select cnt from status_counts where status = 'READY'),      0) as ready_count,
  coalesce((select cnt from status_counts where status = 'PROCESSING'), 0) as processing_count,
  coalesce((select cnt from status_counts where status = 'COMPLETED'),  0) as completed_count,
  coalesce((select cnt from status_counts where status = 'FAILED'),     0) as failed_count,
  coalesce((select cnt from status_counts where status = 'HOLD'),       0) as hold_count,
  coalesce((select cnt from status_counts where status = 'CANCELED'),   0) as canceled_count,
  (select avg_processing_seconds from processing_times)                    as avg_processing_seconds_24h,
  (select completed_24h from last_24h)                                     as completed_last_24h,
  (select failed_24h    from last_24h)                                     as failed_last_24h,
  (select total_24h     from last_24h)                                     as total_last_24h,
  case
    when (select total_24h from last_24h) > 0
    then round(
      (select failed_24h from last_24h)::numeric /
      (select total_24h  from last_24h)::numeric * 100, 2
    )
    else 0
  end as failure_rate_pct_24h,
  (select cnt      from dlq_depth)                                         as dlq_depth,
  (select last_run_at       from last_recon)                               as last_reconciliation_at,
  (select last_critical_count from last_recon)                             as last_reconciliation_critical,
  (select last_success_at  from last_payout)                               as last_successful_payout_at;

-- ============================================================
-- 2. settlement_alarm_results — alarm audit trail
-- ============================================================
create table if not exists public.settlement_alarm_results (
  id          uuid        primary key default gen_random_uuid(),
  alarm_type  text        not null,
  severity    text        not null check (severity in ('INFO', 'WARNING', 'CRITICAL')),
  message     text        not null,
  metric_value numeric,
  threshold   numeric,
  fired_at    timestamptz not null default now()
);

create index if not exists idx_alarm_results_fired_at
  on public.settlement_alarm_results (fired_at desc);

create index if not exists idx_alarm_results_alarm_type
  on public.settlement_alarm_results (alarm_type, fired_at desc);

-- ============================================================
-- 3. check_settlement_alarms() — threshold-based alarm firing
--    30-minute dedup: no duplicate alarms within 30 minutes
-- ============================================================
create or replace function public.check_settlement_alarms()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_metrics    record;
  v_dedup_mins constant int := 30;
begin
  select * into v_metrics from public.settlement_metrics;

  -- Failure rate alarms
  if v_metrics.failure_rate_pct_24h > 5 then
    if not exists (
      select 1 from public.settlement_alarm_results
      where alarm_type = 'HIGH_FAILURE_RATE'
        and fired_at > now() - (v_dedup_mins || ' minutes')::interval
    ) then
      insert into public.settlement_alarm_results
        (alarm_type, severity, message, metric_value, threshold)
      values (
        'HIGH_FAILURE_RATE', 'CRITICAL',
        'Settlement failure rate exceeds 5%: ' || v_metrics.failure_rate_pct_24h || '%',
        v_metrics.failure_rate_pct_24h, 5
      );
    end if;
  elsif v_metrics.failure_rate_pct_24h > 1 then
    if not exists (
      select 1 from public.settlement_alarm_results
      where alarm_type = 'ELEVATED_FAILURE_RATE'
        and fired_at > now() - (v_dedup_mins || ' minutes')::interval
    ) then
      insert into public.settlement_alarm_results
        (alarm_type, severity, message, metric_value, threshold)
      values (
        'ELEVATED_FAILURE_RATE', 'WARNING',
        'Settlement failure rate exceeds 1%: ' || v_metrics.failure_rate_pct_24h || '%',
        v_metrics.failure_rate_pct_24h, 1
      );
    end if;
  end if;

  -- DLQ depth alarm
  if v_metrics.dlq_depth > 10 then
    if not exists (
      select 1 from public.settlement_alarm_results
      where alarm_type = 'HIGH_DLQ_DEPTH'
        and fired_at > now() - (v_dedup_mins || ' minutes')::interval
    ) then
      insert into public.settlement_alarm_results
        (alarm_type, severity, message, metric_value, threshold)
      values (
        'HIGH_DLQ_DEPTH', 'WARNING',
        'DLQ depth exceeds threshold: ' || v_metrics.dlq_depth || ' items in HOLD',
        v_metrics.dlq_depth, 10
      );
    end if;
  end if;

  -- SLA delay alarm (REQ-4.6.05: SLA = scheduled_at + 30 min)
  if exists (
    select 1
    from public.payouts
    where status not in ('COMPLETED', 'CANCELED')
      and scheduled_at < now() - interval '30 minutes'
  ) then
    if not exists (
      select 1 from public.settlement_alarm_results
      where alarm_type = 'PAYOUT_SLA_BREACH'
        and fired_at > now() - (v_dedup_mins || ' minutes')::interval
    ) then
      insert into public.settlement_alarm_results
        (alarm_type, severity, message, metric_value, threshold)
      values (
        'PAYOUT_SLA_BREACH', 'WARNING',
        'One or more payouts have exceeded SLA (scheduled_at + 30 minutes)',
        null, null
      );
    end if;
  end if;
end;
$$;
