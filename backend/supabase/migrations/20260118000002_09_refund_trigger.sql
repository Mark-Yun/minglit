-- 09. REFUND TRIGGER & STATUS SYNC

-- 1. Add rejection_reason to event_applications
alter table public.event_applications
add column rejection_reason text;

-- 2. Enhance Verification Status Sync (Handle Rejection)
create or replace function public.handle_verification_approval()
returns trigger 
set search_path = public
as $$
begin
  if (new.status = 'approved' and old.status != 'approved') then
    -- 1. Create Partner Verified User
    insert into public.partner_verified_users (partner_id, user_id, verification_id, submission_id, verified_at)
    values (new.partner_id, new.user_id, new.verification_id, new.id, now())
    on conflict (partner_id, user_id, verification_id) 
    do update set submission_id = new.id, verified_at = now(), valid_until = null; 

    -- 2. Auto-approve linked Event Application
    if (new.application_id is not null) then
      update public.event_applications
      set status = 'approved', updated_at = now()
      where id = new.application_id
      and status in ('pending', 'pending_review');
    end if;

  elsif (new.status = 'rejected' and old.status != 'rejected') then
    -- Handle Rejection: Sync to Application
    if (new.application_id is not null) then
      update public.event_applications
      set 
        status = 'rejected',
        rejection_reason = new.admin_comment,
        updated_at = now()
      where id = new.application_id;
    end if;

  elsif (new.status != 'approved' and old.status = 'approved') then
    -- Revoke verification if status changes back
    delete from public.partner_verified_users
    where submission_id = new.id;
  end if;
  return new;
end;
$$ language plpgsql security definer;

-- 3. Trigger Function to call Cancel Payment Edge Function
create or replace function public.handle_application_rejection()
returns trigger
language plpgsql
security definer
set search_path = public, extensions, net
as $$
declare
  v_payment_id text;
  v_reason text;
  v_project_url text := 'https://pbbfiqjectdyyyucorpa.supabase.co'; -- TODO: Make dynamic
  v_service_key text;
begin
  -- Trigger only on status change to 'rejected'
  if new.status = 'rejected' and (old.status is distinct from 'rejected') then
    v_payment_id := new.payment_id;
    v_reason := new.rejection_reason;

    if v_payment_id is not null then
      -- Get Secrets from Vault
      select decrypted_secret into v_service_key 
      from vault.decrypted_secrets 
      where name = 'service_role_key' limit 1;

      -- Call Edge Function via pg_net
      perform net.http_post(
        url := v_project_url || '/functions/v1/cancel-payment',
        headers := jsonb_build_object(
          'Content-Type', 'application/json',
          'Authorization', 'Bearer ' || v_service_key
        ),
        body := jsonb_build_object(
          'payment_id', v_payment_id,
          'reason', v_reason
        )
      );

      -- Update refund_status to 'requested'
      -- We do this here to indicate the process started.
      -- If payment_id was null, we skip.
      new.refund_status := 'requested';
    end if;
  end if;
  return new;
end;
$$;

-- 4. Create Trigger on event_applications
create trigger on_application_rejected
  before update on public.event_applications
  for each row
  execute function public.handle_application_rejection();
