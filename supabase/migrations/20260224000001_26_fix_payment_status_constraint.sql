-- 26. Add payment_failed and payment_pending to event_applications status check + pgmq_send wrapper
set search_path to public, extensions;

-- 1. Fix event_applications status constraint
alter table public.event_applications drop constraint if exists event_applications_status_check;
alter table public.event_applications add constraint event_applications_status_check
  check (status in ('pending', 'pending_review', 'approved', 'rejected', 'cancelled', 'paid', 'payment_failed', 'payment_pending'));

-- 2. Add pgmq_send public RPC wrapper
create or replace function public.pgmq_send(queue_name text, message jsonb)
returns bigint
language plpgsql
security definer
set search_path = public, extensions, pgmq, temp
as $$
begin
  return pgmq.send(queue_name, message);
end;
$$;