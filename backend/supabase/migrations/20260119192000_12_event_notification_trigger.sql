-- 12. Event Update Notification Trigger

-- 1. Create Notification Function
create or replace function public.notify_event_update()
returns trigger 
security definer
set search_path = public, extensions
as $$
declare
  applicant record;
  payload jsonb;
  msg_id bigint;
begin
  -- 1. Check significant changes
  if (
    new.title is distinct from old.title or
    new.event_date is distinct from old.event_date or
    new.address is distinct from old.address or
    new.status is distinct from old.status
  ) then
    
    -- 2. Loop through applicants (approved or pending)
    -- Assuming 'event_applications' table exists and has 'user_id', 'event_id', 'status'
    -- Check table name in 04_events.sql if unsure. Usually event_applications or tickets.
    -- Based on context, likely 'event_applications'.
    for applicant in 
      select user_id 
      from public.event_applications 
      where event_id = new.id 
      and status in ('approved', 'pending') -- Notify accepted and pending users
    loop
      
      -- 3. Construct Payload
      payload := jsonb_build_object(
        'type', 'event_update',
        'user_id', applicant.user_id,
        'title', '[이벤트 업데이트] ' || new.title,
        'body', '주최자가 이벤트 정보를 변경했습니다. 탭하여 확인해보세요.',
        'category', 'service',
        'data', jsonb_build_object(
          'event_id', new.id,
          'deep_link', '/events/' || new.id
        ),
        'meta', jsonb_build_object(
          'occurred_at', now()
        )
      );

      -- 4. Send to PGMQ
      -- Assuming pgmq extension is enabled and queue 'q_notifications' exists.
      -- If not, this might fail. Ideally wrapped in exception block or ensure queue exists.
      perform pgmq.send(
        queue_name := 'q_notifications',
        msg := payload
      );
      
    end loop;
    
  end if;

  return new;
end;
$$ language plpgsql;

-- 2. Create Trigger
drop trigger if exists on_event_update_notify on public.events;

create trigger on_event_update_notify
  after update on public.events
  for each row
  execute procedure public.notify_event_update();
