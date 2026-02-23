CREATE OR REPLACE FUNCTION public.trigger_produce_event_events()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions, pgmq, temp
AS $$
BEGIN
  IF TG_OP = 'UPDATE' THEN
    IF NEW.status = 'cancelled' AND (OLD.status IS DISTINCT FROM 'cancelled') THEN
      PERFORM public.produce_event(
        'event_cancelled'::public.event_type_name,
        'events',
        NEW.id,
        row_to_json(NEW)::jsonb
      );
    ELSIF (
      NEW.title IS DISTINCT FROM OLD.title OR
      NEW.start_time IS DISTINCT FROM OLD.start_time OR
      NEW.location_id IS DISTINCT FROM OLD.location_id
    ) THEN
      PERFORM public.produce_event(
        'event_updated'::public.event_type_name,
        'events',
        NEW.id,
        row_to_json(NEW)::jsonb
      );
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_produce_event_events ON public.events;

CREATE TRIGGER on_produce_event_events
  AFTER UPDATE ON public.events
  FOR EACH ROW EXECUTE FUNCTION public.trigger_produce_event_events();
