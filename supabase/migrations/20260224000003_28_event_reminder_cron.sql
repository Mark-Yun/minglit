-- 28. Event reminder: reminder_sent_at column + cron function + schedule
set search_path to public, extensions;

-- 1. Add reminder tracking column
alter table public.event_participants add column if not exists reminder_sent_at timestamptz;

-- 2. Reminder function
create or replace function public.send_event_reminders()
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  participant record;
  payload jsonb;
begin
  for participant in
    select
      ep.id as participant_id,
      ep.user_id,
      e.id as event_id,
      coalesce(e.title, '이벤트') as event_title
    from public.event_participants ep
    join public.events e on e.id = ep.event_id
    where e.start_time between now() + interval '55 minutes' and now() + interval '65 minutes'
      and e.status = 'scheduled'
      and ep.status = 'ticket_issued'
      and ep.reminder_sent_at is null
  loop
    payload := jsonb_build_object(
      'id', gen_random_uuid()::text,
      'type', 'event_reminder',
      'user_id', participant.user_id,
      'title', '[리마인더] ' || participant.event_title,
      'body', '이벤트가 1시간 후 시작됩니다.',
      'category', 'service',
      'data', jsonb_build_object(
        'event_id', participant.event_id,
        'deep_link', '/events/' || participant.event_id
      ),
      'meta', jsonb_build_object('occurred_at', now())
    );

    perform pgmq.send(queue_name := 'q_notifications', msg := payload);

    -- Mark as sent to prevent duplicates
    update public.event_participants
    set reminder_sent_at = now()
    where id = participant.participant_id;
  end loop;
end;
$$;

-- 3. Register cron job (every minute)
select cron.schedule(
  'send-event-reminders',
  '* * * * *',
  $$select public.send_event_reminders();$$
);
