-- Settlement Phase 3: Payout Pipeline
-- Builds payout assembly, retry logic, and cron wiring on top of Phase 1+2.
-- Prerequisites: Phase 1 (schema) + Phase 2 (state machine) must be applied.

-- ============================================================
-- 0. Add portone_transfer_id column to settlement_items
--    Stores PortOne transfer ID after createOrderTransfer() succeeds
-- ============================================================
alter table public.settlement_items
  add column if not exists portone_transfer_id text;

-- ============================================================
-- 1. calculate_next_retry_at() — 지수 백오프 + jitter ±20%
--    REQ-3.2.19: 2^n * 60s, max 6h, jitter ±20%
--    VOLATILE because random() is used (not IMMUTABLE)
-- ============================================================
create or replace function public.calculate_next_retry_at(p_retry_count int)
returns timestamptz
language plpgsql
volatile
security definer
set search_path = public
as $$
declare
  v_base_seconds  double precision;
  v_max_seconds   double precision := 21600.0; -- 6 hours in seconds
  v_capped        double precision;
  v_jitter_factor double precision;
begin
  v_base_seconds  := power(2.0, p_retry_count) * 60.0;
  v_capped        := least(v_base_seconds, v_max_seconds);
  v_jitter_factor := 1.0 + (random() * 0.4 - 0.2); -- ±20%
  return now() + make_interval(secs => v_capped * v_jitter_factor);
end;
$$;

-- ============================================================
-- 2. assemble_payouts() — READY items → payouts 생성
--    REQ-4.6.01: D+2 기본 지급 일정
--    Groups READY settlement_items by partner_id, creates payout records,
--    links items via payout_id.
-- ============================================================
create or replace function public.assemble_payouts()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_partner       record;
  v_payout_id     uuid;
  v_bank_snapshot jsonb;
  v_idem_key      text;
  v_seq           int;
  v_today         text;
begin
  v_today := to_char(now() at time zone 'Asia/Seoul', 'YYYYMMDD');

  -- Process each partner that has READY items without a payout_id
  for v_partner in
    select
      si.partner_id,
      si.currency,
      count(*)                          as item_count,
      sum(si.gross_amount)              as total_gross,
      sum(si.platform_fee_amount)       as total_platform_fee,
      sum(si.pg_fee_amount)             as total_pg_fee,
      sum(si.vat_amount)                as total_vat,
      sum(si.net_amount)                as total_net,
      min(si.settlement_period_start)   as period_start,
      max(si.settlement_period_end)     as period_end
    from public.settlement_items si
    where si.status = 'READY'
      and si.payout_id is null
    group by si.partner_id, si.currency
  loop
    -- Get bank account snapshot from partner_settlements (most recent)
    select jsonb_build_object(
      'bank_code',            ps.bank_code,
      'account_holder_name',  ps.account_holder_name,
      'account_number',       ps.account_number,
      'account_last4',        right(ps.account_number, 4)
    )
    into v_bank_snapshot
    from public.partner_settlements ps
    where ps.partner_id = v_partner.partner_id
    order by ps.created_at desc
    limit 1;

    if v_bank_snapshot is null then
      v_bank_snapshot := '{}'::jsonb;
    end if;

    -- Generate idempotency key with sequential suffix (REQ-5.3.27)
    select coalesce(
      max(
        (regexp_match(payout_request_idempotency_key, '-(\d+)$'))[1]::int
      ), 0
    ) + 1
    into v_seq
    from public.payouts
    where partner_id = v_partner.partner_id
      and payout_request_idempotency_key like
          'prod:payout:' || v_partner.partner_id || ':' || v_today || '-%';

    v_idem_key := 'prod:payout:' || v_partner.partner_id
                  || ':' || v_today
                  || '-' || lpad(v_seq::text, 3, '0');

    -- Insert payout record
    insert into public.payouts (
      partner_id,
      payout_period_start,
      payout_period_end,
      currency,
      status,
      scheduled_at,
      item_count,
      total_gross_amount,
      total_platform_fee_amount,
      total_pg_fee_amount,
      total_vat_amount,
      total_net_amount,
      bank_account_snapshot,
      payout_request_idempotency_key
    ) values (
      v_partner.partner_id,
      v_partner.period_start,
      v_partner.period_end,
      v_partner.currency,
      'CREATED',
      now() + interval '2 days',
      v_partner.item_count,
      v_partner.total_gross,
      v_partner.total_platform_fee,
      v_partner.total_pg_fee,
      v_partner.total_vat,
      v_partner.total_net,
      v_bank_snapshot,
      v_idem_key
    )
    returning id into v_payout_id;

    -- Link settlement_items to this payout
    update public.settlement_items
    set payout_id = v_payout_id
    where status = 'READY'
      and payout_id is null
      and partner_id = v_partner.partner_id
      and currency = v_partner.currency;

  end loop;
end;
$$;

-- ============================================================
-- 3. retry_failed_settlements() — FAILED → READY 재시도
--    REQ-3.2.19: 지수 백오프 기반 재시도
--    Eligible: retryable=true, retry_count<8, next_retry_at<=now()
-- ============================================================
create or replace function public.retry_failed_settlements()
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
    from public.settlement_items
    where status = 'FAILED'
      and retryable = true
      and retry_count < 8
      and next_retry_at <= now()
  loop
    perform public.transition_settlement_status(
      v_item.id,
      v_item.version,
      'READY',
      'SYSTEM',
      'retry_scheduler',
      'retry_scheduled',
      null::text, null::text, null::text, null::text,
      '{"source": "retry_failed_settlements"}'::jsonb,
      null::text
    );
  end loop;
end;
$$;

-- ============================================================
-- 4. Cron jobs — 신규 4개 추가
-- ============================================================

-- 4a. settlement-register-transfers: 매 15분 (EF 호출 via pg_net)
select cron.schedule(
  'settlement-register-transfers',
  '*/15 * * * *',
  $$
    select net.http_post(
      url:='https://cnuahgrfzcqkmdyhunuk.supabase.co/functions/v1/settlement-register-transfers',
      headers:=(
        jsonb_build_object(
          'Content-Type', 'application/json',
          'Authorization', 'Bearer ' || (select decrypted_secret from vault.decrypted_secrets where name = 'service_role_key' limit 1)
        )
      ),
      body:='{}'::jsonb
    ) as request_id;
  $$
);

-- 4b. settlement-payout-sync: 매일 11:00, 14:00, 17:00 KST (UTC 02:00, 05:00, 08:00)
select cron.schedule(
  'settlement-payout-sync',
  '0 2,5,8 * * *',
  $$
    select net.http_post(
      url:='https://cnuahgrfzcqkmdyhunuk.supabase.co/functions/v1/payout-sync',
      headers:=(
        jsonb_build_object(
          'Content-Type', 'application/json',
          'Authorization', 'Bearer ' || (select decrypted_secret from vault.decrypted_secrets where name = 'service_role_key' limit 1)
        )
      ),
      body:='{}'::jsonb
    ) as request_id;
  $$
);

-- 4c. settlement-payout-assembly: 매일 10:00 KST (UTC 01:00)
select cron.schedule(
  'settlement-payout-assembly',
  '0 1 * * *',
  $$select public.assemble_payouts();$$
);

-- 4d. settlement-retry-failed: 매 30분
select cron.schedule(
  'settlement-retry-failed',
  '*/30 * * * *',
  $$select public.retry_failed_settlements();$$
);
