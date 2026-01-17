-- Transactional RPC: Apply Event (One-Shot)
-- This function handles the "One-Shot" application flow where payment and verification submission happen atomically.

create or replace function public.apply_event(
  p_event_id uuid,
  p_ticket_id uuid,
  p_user_id uuid,
  p_payment_id text,
  p_payment_amount int,
  p_verification_data jsonb default null -- Optional: { "verification_id": "...", "data": {...}, "partner_id": "..." }
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_app_id uuid;
  v_status text := 'pending_review'; -- Default for verification needed
begin
  -- 1. Determine Status
  -- If no verification is needed (data is null), approve immediately (or set to paid)
  -- Note: If user is already verified (checked by client), client should NOT send verification_data.
  if (p_verification_data is null) then
    v_status := 'paid';
  end if;

  -- 2. Insert Application
  insert into public.event_applications (
    event_id, ticket_id, user_id, 
    payment_id, payment_amount, status
  )
  values (
    p_event_id, p_ticket_id, p_user_id,
    p_payment_id, p_payment_amount, v_status
  )
  returning id into v_app_id;

  -- 3. Handle Verification (if provided)
  if (p_verification_data is not null) then
    -- 3.1. Upsert User Verification (Save original data for reuse)
    insert into public.user_verifications (user_id, verification_id, data)
    values (
      p_user_id, 
      (p_verification_data->>'verification_id')::uuid, 
      p_verification_data->'data'
    )
    on conflict (user_id, verification_id) 
    do update set data = excluded.data, updated_at = now();

    -- 3.2. Create Submission (Snapshot linked to Application)
    insert into public.verification_submissions (
      partner_id, user_id, verification_id, application_id,
      status, snapshot_data
    )
    values (
      (p_verification_data->>'partner_id')::uuid,
      p_user_id,
      (p_verification_data->>'verification_id')::uuid,
      v_app_id, -- Link to the application created above
      'pending',
      p_verification_data->'data'
    );
  end if;

  return v_app_id;
end;
$$;
