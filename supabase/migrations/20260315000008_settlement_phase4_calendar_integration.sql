-- ============================================================
-- Phase 4: Calendar Integration
-- Replace now() + interval '2 days' with calculate_scheduled_at()
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
      'bank_name',      ps.bank_name,
      'account_holder', ps.account_holder,
      'account_number', ps.account_number,
      'account_last4',  right(ps.account_number, 4)
    )
    into v_bank_snapshot
    from public.partner_settlements ps
    where ps.partner_id = v_partner.partner_id
    order by ps.updated_at desc nulls last
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
          'prod:payout:' || v_partner.partner_id || ':' || v_partner.currency || ':' || v_today || '-%';

    v_idem_key := 'prod:payout:' || v_partner.partner_id
                  || ':' || v_partner.currency
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
      calculate_scheduled_at((now() at time zone 'Asia/Seoul')::date),
      v_partner.item_count,
      v_partner.total_gross,
      v_partner.total_platform_fee,
      v_partner.total_pg_fee,
      v_partner.total_vat,
      v_partner.total_net,
      v_bank_snapshot,
      v_idem_key
    )
    on conflict (partner_id, payout_request_idempotency_key)
      where payout_request_idempotency_key is not null
      do nothing
    returning id into v_payout_id;

    if v_payout_id is null then
      select id into v_payout_id
      from public.payouts
      where partner_id = v_partner.partner_id
        and payout_request_idempotency_key = v_idem_key;
    end if;

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

revoke execute on function public.assemble_payouts() from public;
grant execute on function public.assemble_payouts() to service_role;
