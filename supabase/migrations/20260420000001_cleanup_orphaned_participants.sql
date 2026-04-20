-- Fix #1613: Clean up orphaned event_participants rows for cancelled applications
--
-- INV-03 invariant fires when event_participants rows exist for applications
-- with status='cancelled'. The trigger (20260417000002) prevents new violations,
-- but pre-existing orphaned rows must be removed manually.
--
-- This one-time cleanup deletes rows in event_participants that are linked to
-- a cancelled event_applications row via (event_id, user_id).

DELETE FROM public.event_participants ep
WHERE EXISTS (
  SELECT 1
  FROM public.event_applications a
  WHERE a.event_id = ep.event_id
    AND a.user_id = ep.user_id
    AND a.status = 'cancelled'
);
