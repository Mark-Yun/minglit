-- Settlement Phase 4: Kill Switch Guard in transition_settlement_status()
-- REQ-4.6.10: Kill switch blocks READY→PROCESSING when enabled
-- Adds guard check at the TOP of the function, before SELECT FOR UPDATE.

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
  -- Kill switch guard (REQ-4.6.10): block READY→PROCESSING when kill switch is active
  if p_new_status = 'PROCESSING' then
    if (select (value->>'enabled')::boolean
        from public.system_settings
        where key = 'settlement_kill_switch') then
      raise exception 'Kill switch is active. READY→PROCESSING transitions are blocked.';
    end if;
  end if;

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
