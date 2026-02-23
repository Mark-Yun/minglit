CREATE OR REPLACE FUNCTION public.trigger_produce_event_application()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions, pgmq, temp
AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    PERFORM public.produce_event(
      'new_application'::public.event_type_name,
      'event_applications',
      NEW.id,
      row_to_json(NEW)::jsonb
    );
  ELSIF TG_OP = 'UPDATE' THEN
    IF NEW.status = 'approved' AND (OLD.status IS DISTINCT FROM 'approved') THEN
      PERFORM public.produce_event(
        'application_approved'::public.event_type_name,
        'event_applications',
        NEW.id,
        row_to_json(NEW)::jsonb
      );
    ELSIF NEW.status = 'rejected' AND (OLD.status IS DISTINCT FROM 'rejected') THEN
      PERFORM public.produce_event(
        'application_rejected'::public.event_type_name,
        'event_applications',
        NEW.id,
        row_to_json(NEW)::jsonb
      );
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_produce_event_application ON public.event_applications;

CREATE TRIGGER on_produce_event_application
  AFTER INSERT OR UPDATE ON public.event_applications
  FOR EACH ROW EXECUTE FUNCTION public.trigger_produce_event_application();
