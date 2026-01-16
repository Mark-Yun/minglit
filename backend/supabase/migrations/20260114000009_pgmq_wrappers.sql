-- Public wrappers for PGMQ functions to be used via Supabase RPC
-- v4: Final robustness with explicit casting and set returning handling
create or replace function public.pgmq_read(queue_name text, vt int, "limit" int)
returns setof jsonb 
set search_path = public, extensions, pgmq, temp
as $$
begin
  return query select to_jsonb(msg) from pgmq.read(queue_name, vt, "limit") as msg;
end;
$$ language plpgsql security definer;

create or replace function public.pgmq_delete_batch(queue_name text, msg_ids bigint[])
returns setof bigint 
set search_path = public, extensions, pgmq, temp
as $$
begin
  -- Explicitly cast msg_ids to int8[] which is what PGMQ expects
  return query select * from pgmq.delete_batch(queue_name, msg_ids::int8[]);
end;
$$ language plpgsql security definer;

create or replace function public.pgmq_delete(queue_name text, msg_id bigint)
returns boolean 
set search_path = public, extensions, pgmq, temp
as $$
begin
  -- Cast to int8 for exact match
  return pgmq.delete(queue_name, msg_id::int8);
end;
$$ language plpgsql security definer;

create or replace function public.pgmq_pop(queue_name text)
returns setof jsonb 
set search_path = public, extensions, pgmq, temp
as $$
begin
  return query select to_jsonb(msg) from pgmq.pop(queue_name) as msg;
end;
$$ language plpgsql security definer;