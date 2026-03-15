-- Settlement Phase 1: Data Migration + Compatibility Views
-- Copies existing settlements data into settlement_items (parallel coexistence).
-- Recreates partner_revenue_stats and partner_monthly_revenue views to use settlement_items.
-- Old settlements table and its data are preserved (NOT deleted).

-- ============================================================
-- Data Migration: settlements → settlement_items
-- ============================================================
-- Column mapping:
--   source_type = 'EVENT', source_id = event_id::text
--   status: lowercase→UPPERCASE mapping
--   amounts: INTEGER→BIGINT cast
--   rates: hardcoded (3.5%, 5%, 10%) — Phase 2 adds configurable rates
--   calc_checksum: SHA-256 of canonical string per SRS REQ-7.03
--   settlement_period_start/end: from events.end_time or fallback to event_date

insert into public.settlement_items (
  id,
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
  retryable,
  retry_count,
  calc_checksum,
  version,
  event_completed_at,
  created_at,
  updated_at
)
select
  gen_random_uuid()                          as id,
  s.partner_id,
  coalesce(e.end_time::date, s.event_date::date) as settlement_period_start,
  coalesce(e.end_time::date, s.event_date::date) as settlement_period_end,
  'KRW'                                      as currency,
  'EVENT'                                    as source_type,
  s.event_id::text                           as source_id,
  case s.status
    when 'pending'   then 'PENDING'
    when 'ready'     then 'READY'
    when 'requested' then 'PROCESSING'
    when 'completed' then 'COMPLETED'
    else 'PENDING'
  end                                        as status,
  s.total_sales::bigint                      as gross_amount,
  5.00::decimal(5,2)                         as platform_fee_rate,
  s.platform_fee::bigint                     as platform_fee_amount,
  3.50::decimal(5,2)                         as pg_fee_rate,
  s.pg_fee::bigint                           as pg_fee_amount,
  10.00::decimal(5,2)                        as vat_rate,
  s.vat::bigint                              as vat_amount,
  s.net_amount::bigint                       as net_amount,
  false                                      as retryable,
  0                                          as retry_count,
  encode(
    digest(
      s.partner_id::text || '|' ||
      coalesce(e.end_time::date, s.event_date::date)::text || '|' ||
      coalesce(e.end_time::date, s.event_date::date)::text || '|' ||
      'KRW' || '|' ||
      s.total_sales::text || '|' ||
      '5.00' || '|' ||
      '3.50' || '|' ||
      '10.00' || '|' ||
      s.platform_fee::text || '|' ||
      s.pg_fee::text || '|' ||
      s.vat::text || '|' ||
      s.net_amount::text || '|' ||
      'v1',
      'sha256'
    ),
    'hex'
  )                                          as calc_checksum,
  1                                          as version,
  e.end_time                                 as event_completed_at,
  s.created_at,
  s.updated_at
from public.settlements s
left join public.events e on e.id = s.event_id;

-- ============================================================
-- Verify migration row count (assertion in migration)
-- ============================================================
do $$
declare
  v_settlements_count int;
  v_items_count int;
begin
  select count(*) into v_settlements_count from public.settlements;
  select count(*) into v_items_count from public.settlement_items where source_type = 'EVENT';

  if v_settlements_count <> v_items_count then
    raise exception 'Data migration row count mismatch: settlements=%, settlement_items=%',
      v_settlements_count, v_items_count;
  end if;
end;
$$;

-- ============================================================
-- Compatibility Views: recreate to read from settlement_items
-- Maps settlement_items columns → legacy column names
-- ============================================================

drop view if exists public.partner_revenue_stats;
create view public.partner_revenue_stats as
select
  partner_id,
  coalesce(sum(gross_amount), 0)::bigint as total_sales,
  0::bigint                               as total_refunds,
  coalesce(sum(net_amount), 0)::bigint   as net_amount
from public.settlement_items
group by partner_id;

drop view if exists public.partner_monthly_revenue;
create view public.partner_monthly_revenue as
select
  partner_id,
  date_trunc('month', settlement_period_start)::date as month,
  coalesce(sum(gross_amount), 0)::bigint              as total_sales,
  0::bigint                                            as total_refunds,
  coalesce(sum(net_amount), 0)::bigint                as net_amount
from public.settlement_items
group by partner_id, date_trunc('month', settlement_period_start)
order by month;
