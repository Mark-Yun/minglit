-- Fix #1515: Remove event_participants when application is cancelled
--
-- INV-03 invariant: "Cancelled applications with orphaned participant records" was
-- already tracked by the invariant monitor (db_invariant_monitor.sql), but there
-- was no trigger to enforce cleanup.
--
-- When an event_application's status transitions to 'cancelled', the corresponding
-- event_participants row must be removed to maintain DB consistency.
-- The symmetric trigger (issue_ticket_on_approval) inserts the row on approval.

set search_path to public, extensions;

-- ────────────────────────────────────────────────────────
-- Trigger function: delete event_participants on cancel
-- ────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.remove_participant_on_cancel()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  DELETE FROM public.event_participants
  WHERE event_id = NEW.event_id
    AND user_id = NEW.user_id;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_application_cancel ON public.event_applications;

-- WHEN clause filters at the trigger level so remove_participant_on_cancel()
-- is never invoked unless the row is actually transitioning to 'cancelled'.
-- This avoids a function call on every event_applications UPDATE.
CREATE TRIGGER on_application_cancel
  AFTER UPDATE ON public.event_applications
  FOR EACH ROW
  WHEN (NEW.status = 'cancelled' AND OLD.status IS DISTINCT FROM 'cancelled')
  EXECUTE FUNCTION public.remove_participant_on_cancel();
