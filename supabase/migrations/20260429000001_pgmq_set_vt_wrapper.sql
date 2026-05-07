-- Fix #2040: Add public.pgmq_set_vt wrapper so notification-worker can reschedule
-- marketing messages during KST night hours (§50 ⑤ guard).

create or replace function public.pgmq_set_vt(queue_name text, msg_id bigint, vt_offset int)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions, pgmq, pg_temp
as $$
begin
  return to_jsonb(pgmq.set_vt(queue_name, msg_id::int8, vt_offset));
end;
$$;

revoke all on function public.pgmq_set_vt(text, bigint, int) from public, anon, authenticated;
grant execute on function public.pgmq_set_vt(text, bigint, int) to service_role;
