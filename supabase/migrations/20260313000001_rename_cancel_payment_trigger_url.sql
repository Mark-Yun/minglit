-- Rename cancel-payment → payment-cancel in handle_application_rejection trigger URL
-- Part of edge function rename: {domain}-{action} convention

create or replace function public.handle_application_rejection()
returns trigger
language plpgsql
security definer
set search_path = public, extensions, net
as $$
declare
  v_payment_id text;
  v_reason text;
  v_project_url text := 'https://cnuahgrfzcqkmdyhunuk.supabase.co';
  v_service_key text;
begin
  if new.status = 'rejected' and (old.status is distinct from 'rejected') then
    v_payment_id := new.payment_id;
    v_reason := new.rejection_reason;

    if v_payment_id is not null then
      select decrypted_secret into v_service_key 
      from vault.decrypted_secrets 
      where name = 'service_role_key' limit 1;

      perform net.http_post(
        url := v_project_url || '/functions/v1/payment-cancel',
        headers := jsonb_build_object(
          'Content-Type', 'application/json',
          'Authorization', 'Bearer ' || v_service_key
        ),
        body := jsonb_build_object(
          'payment_id', v_payment_id,
          'reason', v_reason
        )
      );

      new.refund_status := 'requested';
    end if;
  end if;
  return new;
end;
$$;
