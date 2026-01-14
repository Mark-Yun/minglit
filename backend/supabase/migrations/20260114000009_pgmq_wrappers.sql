-- Public wrappers for PGMQ functions to be used via Supabase RPC
create or replace function public.pgmq_read(queue_name text, vt int, "limit" int)
returns setof jsonb as $$
begin
  return query select row_to_json(msg) from pgmq.read(queue_name, vt, "limit") as msg;
end;
$$ language plpgsql security definer;

create or replace function public.pgmq_delete_batch(queue_name text, msg_ids bigint[])
returns setof bigint as $$
begin
  return query select pgmq.delete_batch(queue_name, msg_ids);
end;
$$ language plpgsql security definer;

create or replace function public.pgmq_delete(queue_name text, msg_id bigint)
returns boolean as $$
begin
  return pgmq.delete(queue_name, msg_id);
end;
$$ language plpgsql security definer;

-- Wrapper for pop
create or replace function public.pgmq_pop(queue_name text)
returns setof jsonb as $$
begin
  return query select row_to_json(msg) from pgmq.pop(queue_name) as msg;
end;
$$ language plpgsql security definer;
