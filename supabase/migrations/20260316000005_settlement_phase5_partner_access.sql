-- Settlement Phase 5: Partner Access
-- REQ-8.01: GRANT SELECT on settlement tables for authenticated role
-- REQ-8.02: settlement_histories INSERT → PGMQ notification (READY/COMPLETED/FAILED)
-- REQ-8.18: request_retry_payout() RPC for FAILED payout retry

-- ============================================================
-- 1. GRANT SELECT on 5 settlement tables for authenticated role
-- ============================================================
grant select on public.settlement_items to authenticated;
grant select on public.payouts to authenticated;
grant select on public.adjustment_items to authenticated;
grant select on public.settlement_histories to authenticated;
grant select on public.payout_transfers to authenticated;

-- ============================================================
-- 2. Add settlement event types to event_type_name enum
-- ============================================================
alter type public.event_type_name add value if not exists 'settlement_ready';
alter type public.event_type_name add value if not exists 'settlement_completed';
alter type public.event_type_name add value if not exists 'settlement_failed';

-- ============================================================
-- 3. settlement_histories INSERT trigger → produce_event()
--    Fires only for READY, COMPLETED, FAILED transitions
-- ============================================================
create or replace function public.trigger_settlement_notification()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_event_type public.event_type_name;
begin
  v_event_type := case NEW.to_status
    when 'READY'     then 'settlement_ready'::public.event_type_name
    when 'COMPLETED' then 'settlement_completed'::public.event_type_name
    when 'FAILED'    then 'settlement_failed'::public.event_type_name
    else null
  end;

  if v_event_type is not null then
    perform public.produce_event(
      v_event_type,
      'settlement_histories',
      NEW.settlement_item_id,
      jsonb_build_object(
        'settlement_item_id', NEW.settlement_item_id,
        'event_type',  NEW.event_type,
        'from_status', NEW.from_status,
        'to_status',   NEW.to_status,
        'details',     coalesce(NEW.details, '{}')
      )
    );
  end if;

  return NEW;
end;
$$;

drop trigger if exists on_settlement_notification on public.settlement_histories;
create trigger on_settlement_notification
  after insert on public.settlement_histories
  for each row execute function public.trigger_settlement_notification();

-- ============================================================
-- 4. request_retry_payout(p_payout_id uuid, p_partner_id uuid) → jsonb
--    FAILED payout → CREATED + linked settlement_items FAILED→READY
--    REQ-8.18~21: 멱등성, 파트너 권한 확인
-- ============================================================
create or replace function public.request_retry_payout(
  p_payout_id  uuid,
  p_partner_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_payout       record;
  v_item         record;
  v_new_idem_key text;
begin
  select * into v_payout
  from public.payouts
  where id = p_payout_id
    and partner_id = p_partner_id;

  if not found then
    raise exception 'payout not found or unauthorized: %', p_payout_id;
  end if;

  if v_payout.status != 'FAILED' then
    raise exception 'only FAILED payouts can be retried, current status: %', v_payout.status;
  end if;

  v_new_idem_key := 'retry:' || p_payout_id::text || ':' || extract(epoch from now())::bigint::text;

  update public.payouts
  set
    status = 'CREATED',
    payout_request_idempotency_key = v_new_idem_key,
    updated_at = now()
  where id = p_payout_id;

  for v_item in
    select si.id, si.version
    from public.settlement_items si
    where si.payout_id = p_payout_id
      and si.status = 'FAILED'
      and si.retryable = true
  loop
    begin
      perform public.transition_settlement_status(
        v_item.id,
        v_item.version,
        'READY',
        'PARTNER',
        p_partner_id::text,
        'retry_requested',
        null::text, null::text, null::text, null::text,
        jsonb_build_object('retry_payout_id', p_payout_id),
        v_new_idem_key || ':' || v_item.id::text
      );
    exception when others then
      raise warning 'transition failed for item %: %', v_item.id, sqlerrm;
    end;
  end loop;

  return jsonb_build_object(
    'success', true,
    'payout_id', p_payout_id,
    'new_idempotency_key', v_new_idem_key
  );
end;
$$;

revoke execute on function public.request_retry_payout(uuid, uuid) from public;
grant execute on function public.request_retry_payout(uuid, uuid) to authenticated;
