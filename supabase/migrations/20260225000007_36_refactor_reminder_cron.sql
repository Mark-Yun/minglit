-- 36. Refactor send_event_reminders(): pgmq.send('q_notifications') → produce_event('event_reminder')
set search_path to public, extensions, pgmq, temp;

-- Refactor reminder function to use produce_event instead of direct pgmq.send
create or replace function public.send_event_reminders()
returns void
language plpgsql
security definer
set search_path = public, extensions, pgmq, temp
as $$
declare
  participant record;
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
    perform public.produce_event(
      'event_reminder'::public.event_type_name,
      'event_participants',
      participant.participant_id,
      jsonb_build_object(
        'user_id', participant.user_id,
        'event_id', participant.event_id,
        'event_title', participant.event_title
      )
    );

    -- Mark as sent to prevent duplicates
    update public.event_participants
    set reminder_sent_at = now()
    where id = participant.participant_id;
  end loop;
end;
$$;
