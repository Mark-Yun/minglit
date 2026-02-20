-- 14. Party Balance System
-- Gender/group ratio balancing for event ticket purchases
set search_path to public, extensions;

-- 1. Add balance_config to parties table
alter table public.parties 
  add column balance_config jsonb default null;

comment on column public.parties.balance_config is 
  'Balance configuration: {"enabled": true, "tolerance": 2, "target_groups": ["male", "female"]}';

-- 2. Balance check function
-- Returns whether a ticket purchase is allowed given current balance state
create or replace function public.check_party_balance(
  p_event_id uuid,
  p_ticket_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_party_id uuid;
  v_balance_config jsonb;
  v_target_gender public.gender;
  v_ticket_gender public.gender;
  v_tolerance int;
  v_group_counts jsonb := '{}'::jsonb;
  v_target_groups jsonb;
  v_male_count int := 0;
  v_female_count int := 0;
  v_diff int;
begin
  -- 1. Get party and its balance config
  select p.id, p.balance_config
  into v_party_id, v_balance_config
  from public.events e
  join public.parties p on p.id = e.party_id
  where e.id = p_event_id;

  -- If no balance config or not enabled, always allow
  if v_balance_config is null or (v_balance_config->>'enabled')::boolean is not true then
    return jsonb_build_object('allowed', true, 'reason', null);
  end if;

  v_tolerance := coalesce((v_balance_config->>'tolerance')::int, 2);

  -- 2. Get the gender of the entry group targeted by this ticket
  select eg.gender
  into v_ticket_gender
  from public.tickets t
  join public.entry_groups eg on eg.id = any(t.target_entry_group_ids)
  where t.id = p_ticket_id
  limit 1;

  -- If ticket has no gender-specific entry group, allow
  if v_ticket_gender is null then
    return jsonb_build_object('allowed', true, 'reason', null);
  end if;

  -- 3. Count current participants per gender for this event
  select 
    coalesce(sum(case when eg.gender = 'male' then 1 else 0 end), 0),
    coalesce(sum(case when eg.gender = 'female' then 1 else 0 end), 0)
  into v_male_count, v_female_count
  from public.event_participants ep
  join public.tickets t on t.id = ep.ticket_id
  join public.entry_groups eg on eg.id = any(t.target_entry_group_ids)
  where ep.event_id = p_event_id;

  -- 4. Check if adding one more of this gender would exceed tolerance
  if v_ticket_gender = 'male' then
    v_diff := (v_male_count + 1) - v_female_count;
  else
    v_diff := (v_female_count + 1) - v_male_count;
  end if;

  if v_diff > v_tolerance then
    return jsonb_build_object(
      'allowed', false, 
      'reason', '성비 조절 중',
      'gender', v_ticket_gender::text,
      'male_count', v_male_count,
      'female_count', v_female_count,
      'tolerance', v_tolerance
    );
  end if;

  return jsonb_build_object(
    'allowed', true, 
    'reason', null,
    'male_count', v_male_count,
    'female_count', v_female_count
  );
end;
$$;

-- 3. RPC to get balance status for all tickets in an event (for UI)
create or replace function public.get_event_ticket_balance_status(
  p_event_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_result jsonb := '[]'::jsonb;
  v_ticket record;
  v_check_result jsonb;
begin
  for v_ticket in
    select id, name from public.tickets where event_id = p_event_id
  loop
    v_check_result := public.check_party_balance(p_event_id, v_ticket.id);
    v_result := v_result || jsonb_build_array(
      jsonb_build_object(
        'ticket_id', v_ticket.id,
        'ticket_name', v_ticket.name,
        'allowed', v_check_result->>'allowed',
        'reason', v_check_result->>'reason'
      )
    );
  end loop;

  return v_result;
end;
$$;

-- 4. Integrate balance check into apply_event
create or replace function public.apply_event(
  p_event_id uuid,
  p_ticket_id uuid,
  p_user_id uuid,
  p_payment_id text,
  p_payment_amount int,
  p_verification_data jsonb default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_app_id uuid;
  v_status text := 'pending_review';
  v_balance_result jsonb;
begin
  -- Balance check (before any insertion)
  v_balance_result := public.check_party_balance(p_event_id, p_ticket_id);
  if (v_balance_result->>'allowed')::boolean is not true then
    raise exception '성비 균형 제한: %', v_balance_result->>'reason'
      using errcode = 'P0001';
  end if;

  if (p_verification_data is null) then
    v_status := 'paid';
  end if;

  insert into public.event_applications (
    event_id, ticket_id, user_id, 
    payment_id, payment_amount, status
  )
  values (
    p_event_id, p_ticket_id, p_user_id,
    p_payment_id, p_payment_amount, v_status
  )
  returning id into v_app_id;

  if (p_verification_data is not null) then
    insert into public.user_verifications (user_id, verification_id, data)
    values (
      p_user_id, 
      (p_verification_data->>'verification_id')::uuid, 
      p_verification_data->'data'
    )
    on conflict (user_id, verification_id) 
    do update set data = excluded.data, updated_at = now();

    insert into public.verification_submissions (
      partner_id, user_id, verification_id, application_id,
      status, snapshot_data
    )
    values (
      (p_verification_data->>'partner_id')::uuid,
      p_user_id,
      (p_verification_data->>'verification_id')::uuid,
      v_app_id,
      'pending',
      p_verification_data->'data'
    );
  end if;

  return v_app_id;
end;
$$;
