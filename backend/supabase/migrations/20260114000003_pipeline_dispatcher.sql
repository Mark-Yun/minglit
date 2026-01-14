-- 2. Dispatcher Logic (Internal Helper)
-- This function handles the routing logic based on event_routes table.
create or replace function public.fan_out_event(p_event_type text, p_payload jsonb)
returns void as $$
declare
  route record;
begin
  for route in 
    select target_queue 
    from public.event_routes 
    where event_type = p_event_type 
    and is_active = true
  loop
    -- Fan-out to target queues defined in event_routes
    perform pgmq.send(route.target_queue, p_payload);
  end loop;
end;
$$ language plpgsql security definer;

-- 3. Generic Event Producer Trigger Function
-- This function can be reused for any table. It takes 'event_type' as a trigger argument.
create or replace function public.produce_event()
returns trigger as $$
declare
  event_type text;
begin
  -- Get event type from trigger arguments (e.g., 'party_created')
  if (TG_NARGS > 0) then
    event_type := TG_ARGV[0];
  else
    event_type := 'unknown_' || TG_TABLE_NAME || '_' || lower(TG_OP);
  end if;

  perform public.fan_out_event(
    event_type,
    jsonb_build_object(
      'event_type', event_type,
      'table', TG_TABLE_NAME,
      'operation', TG_OP,
      'record', row_to_json(NEW),
      'ts', now()
    )
  );
  return NEW;
end;
$$ language plpgsql security definer;

-- 4. Attach Triggers

-- Party Created Event
create trigger on_party_created_event
  after insert on public.parties
  for each row execute procedure public.produce_event('party_created');

-- User Interaction Event
create trigger on_user_action_event
  after insert on public.user_actions
  for each row execute procedure public.produce_event('user_interaction');
