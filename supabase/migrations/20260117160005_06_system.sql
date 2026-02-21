-- 06. SYSTEM: Pipeline, Queues, Cron, Logs
set search_path to public, extensions;

-- 1. PGMQ Queues (drop first to handle incomplete state during db reset)
DO $$ BEGIN PERFORM pgmq.drop_queue('q_global_events'); EXCEPTION WHEN OTHERS THEN NULL; END $$;
DO $$ BEGIN PERFORM pgmq.drop_queue('q_notifications'); EXCEPTION WHEN OTHERS THEN NULL; END $$;
DO $$ BEGIN PERFORM pgmq.drop_queue('q_vectors'); EXCEPTION WHEN OTHERS THEN NULL; END $$;

select pgmq.create('q_global_events');
select pgmq.create('q_notifications');
select pgmq.create('q_vectors');

-- 2. Robustness Tables
create table public.processed_events (
  id uuid primary key,
  processed_at timestamptz not null default now()
);

create table public.dead_letter_queue (
  id uuid default gen_random_uuid() primary key,
  msg_id bigint not null,
  queue_name text not null,
  payload jsonb not null,
  error_reason text,
  failed_at timestamptz not null default now()
);

alter table public.processed_events enable row level security;
alter table public.dead_letter_queue enable row level security;

create index processed_events_at_idx on public.processed_events(processed_at);
create index dlq_queue_name_idx on public.dead_letter_queue(queue_name);

-- 3. Debug Logs
create table public.debug_logs (
  id uuid default gen_random_uuid() primary key,
  message text,
  payload jsonb,
  created_at timestamptz default now()
);
grant all on public.debug_logs to service_role;
grant all on public.debug_logs to postgres;
grant all on public.debug_logs to anon;
grant all on public.debug_logs to authenticated;

-- 4. PGMQ Wrappers
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
  return query select * from pgmq.delete_batch(queue_name, msg_ids::int8[]);
end;
$$ language plpgsql security definer;

create or replace function public.pgmq_delete(queue_name text, msg_id bigint)
returns boolean 
set search_path = public, extensions, pgmq, temp
as $$
begin
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

-- 5. Event Routes
create table public.event_routes (
  id uuid default gen_random_uuid() primary key,
  event_type public.event_type_name not null, 
  target_queue public.event_queue_name not null,
  is_active boolean default true,
  created_at timestamptz default now()
);
alter table public.event_routes enable row level security;

-- 6. Dispatcher Logic
create or replace function public.fan_out_event(p_event_type text, p_payload jsonb)
returns void 
set search_path = public, extensions, pgmq, temp
as $$
declare
  route record;
begin
  for route in 
    select target_queue 
    from public.event_routes 
    where event_type::text = p_event_type 
    and is_active = true
  loop
    perform pgmq.send(route.target_queue::text, p_payload);
  end loop;
end;
$$ language plpgsql security definer;

-- 7. Event Producer (v2 Standard Payload)
create or replace function public.produce_event()
returns trigger 
set search_path = public, extensions, pgmq, temp
as $$
declare
  event_type text;
  trace_id uuid := gen_random_uuid();
  actor_id uuid := auth.uid();
begin
  if (TG_NARGS > 0) then
    event_type := TG_ARGV[0];
  else
    event_type := 'unknown_' || TG_TABLE_NAME || '_' || lower(TG_OP);
  end if;

  perform public.fan_out_event(
    event_type,
    jsonb_build_object(
      'id', trace_id,
      'type', event_type,
      'meta', jsonb_build_object(
        'occurred_at', extract(epoch from now())::bigint,
        'source', TG_TABLE_NAME,
        'attempt', 1
      ),
      'actor', jsonb_build_object(
        'id', actor_id,
        'role', case 
          when actor_id is null then 'system'
          else 'user'
        end
      ),
      'payload', row_to_json(NEW)
    )
  );
  return NEW;
end;
$$ language plpgsql security definer;

-- 8. Triggers (Applied to Tables from previous migrations)
create trigger on_party_created_event
  after insert on public.parties
  for each row execute procedure public.produce_event('party_created');

create trigger on_user_action_event
  after insert on public.user_actions
  for each row execute procedure public.produce_event('user_interaction');

-- 9. CRON Jobs
-- Note: 'service_role_key' must be stored in vault.secrets
select cron.schedule(
  'process-global-events',
  '* * * * *', -- Every minute
  $$
    select net.http_post(
      url:='https://pbbfiqjectdyyyucorpa.supabase.co/functions/v1/global-event-worker',
      headers:=(
        jsonb_build_object(
          'Content-Type', 'application/json',
          'Authorization', 'Bearer ' || (select decrypted_secret from vault.decrypted_secrets where name = 'service_role_key' limit 1)
        )
      ),
      body:='{"batch_size": 10}'::jsonb
    ) as request_id;
  $$
);