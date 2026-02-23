CREATE OR REPLACE FUNCTION public.trigger_produce_event_verification()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions, pgmq, temp
AS $$
BEGIN
  IF TG_OP = 'UPDATE' AND (OLD.status IS DISTINCT FROM NEW.status) THEN
    IF NEW.status IN ('approved', 'rejected', 'needs_correction') THEN
      PERFORM public.produce_event(
        'verification_result'::public.event_type_name,
        'verification_submissions',
        NEW.id,
        row_to_json(NEW)::jsonb
      );
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_produce_event_verification ON public.verification_submissions;

CREATE TRIGGER on_produce_event_verification
  AFTER UPDATE ON public.verification_submissions
  FOR EACH ROW EXECUTE FUNCTION public.trigger_produce_event_verification();
