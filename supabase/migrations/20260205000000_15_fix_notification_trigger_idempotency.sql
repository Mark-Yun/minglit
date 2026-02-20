-- 15. Fix notification payload idempotency (add payload.id)
set search_path to public, extensions;

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
    new.start_time is distinct from old.start_time or
    new.location_id is distinct from old.location_id or
    new.status is distinct from old.status
  ) then

    -- 2. Loop through applicants (approved or pending)
    for applicant in
      select user_id
      from public.event_applications
      where event_id = new.id
      and status in ('approved', 'pending')
    loop

      -- 3. Construct Payload (include id for worker idempotency)
      payload := jsonb_build_object(
        'id', gen_random_uuid()::text,
        'type', 'event_update',
        'user_id', applicant.user_id,
        'title', '[이벤트 업데이트] ' || coalesce(new.title, '이벤트'),
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
      perform pgmq.send(
        queue_name := 'q_notifications',
        msg := payload
      );

    end loop;

  end if;

  return new;
end;
$$ language plpgsql;

drop trigger if exists on_event_update_notify on public.events;

create trigger on_event_update_notify
  after update on public.events
  for each row
  execute procedure public.notify_event_update();
