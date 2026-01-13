create or replace function public.trigger_enqueue_user_action()
returns trigger as $$
begin
  -- Enqueue action data to PGMQ for background processing
  perform pgmq.send(
    queue_name := 'recommendation_updates',
    msg := jsonb_build_object(
      'user_id', NEW.user_id,
      'party_id', NEW.party_id,
      'action_type', NEW.action_type,
      'created_at', NEW.created_at
    )
  );
  return NEW;
end;
$$ language plpgsql security definer;

-- Trigger on User Actions
create trigger on_user_action_enqueued
  after insert on public.user_actions
  for each row execute procedure public.trigger_enqueue_user_action();
