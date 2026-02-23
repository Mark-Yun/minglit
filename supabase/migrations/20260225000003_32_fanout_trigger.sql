-- Migration 32: Fan-out trigger on pgmq.q_q_global_events
-- When a message is inserted into q_global_events, automatically fan-out
-- to target queues based on event_routes table

CREATE OR REPLACE FUNCTION public.fanout_global_event()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions, pgmq, temp
AS $$
DECLARE
  v_event_type text;
BEGIN
  v_event_type := NEW.message->>'event_type';
  IF v_event_type IS NOT NULL THEN
    PERFORM public.fan_out_event(v_event_type, NEW.message);
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_global_event_fanout ON pgmq.q_q_global_events;

CREATE TRIGGER on_global_event_fanout
  AFTER INSERT ON pgmq.q_q_global_events
  FOR EACH ROW EXECUTE FUNCTION public.fanout_global_event();
