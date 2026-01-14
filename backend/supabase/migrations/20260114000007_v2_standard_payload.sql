-- Upgrade produce_event to v2 standardized payload
create or replace function public.produce_event()
returns trigger as $$
declare
  event_type text;
  trace_id uuid := gen_random_uuid();
  actor_id uuid := auth.uid();
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
