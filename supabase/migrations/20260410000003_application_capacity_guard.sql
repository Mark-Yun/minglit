-- Issue #1219
-- Atomic approval helpers for event capacity guards across Edge Functions and DB triggers.

-- Fix #1219: serialize single-application approval under an event row lock so current_participants cannot overshoot max_participants.
CREATE OR REPLACE FUNCTION public.approve_event_application_with_capacity_guard(
  p_application_id uuid
)
RETURNS TABLE (
  result_status text,
  approved integer,
  event_id uuid
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_event_id uuid;
  v_current_participants integer;
  v_max_participants integer;
BEGIN
  SELECT ea.event_id, e.current_participants, e.max_participants
  INTO v_event_id, v_current_participants, v_max_participants
  FROM public.event_applications ea
  JOIN public.events e ON e.id = ea.event_id
  WHERE ea.id = p_application_id
  FOR UPDATE OF e;

  IF NOT FOUND THEN
    RETURN QUERY SELECT 'not_found', 0, NULL::uuid;
    RETURN;
  END IF;

  IF v_current_participants IS NULL OR v_max_participants IS NULL THEN
    RETURN QUERY SELECT 'invalid_capacity', 0, v_event_id;
    RETURN;
  END IF;

  IF v_current_participants >= v_max_participants THEN
    RETURN QUERY SELECT 'event_full', 0, v_event_id;
    RETURN;
  END IF;

  UPDATE public.event_applications
  SET status = 'approved',
      updated_at = now()
  WHERE id = p_application_id
    AND status IN ('pending', 'pending_review');

  IF FOUND THEN
    RETURN QUERY SELECT 'approved', 1, v_event_id;
    RETURN;
  END IF;

  RETURN QUERY SELECT 'already_processed', 0, v_event_id;
END;
$$;

-- Fix #1219: bulk approval must lock the event row, approve oldest pending rows first, and stop at remaining capacity.
CREATE OR REPLACE FUNCTION public.bulk_approve_event_applications_with_capacity_guard(
  p_event_id uuid
)
RETURNS TABLE (
  result_status text,
  approved_count integer,
  skipped_due_to_capacity integer,
  remaining_slots_before_approval integer
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_current_participants integer;
  v_max_participants integer;
  v_remaining_slots integer;
  v_pending_count integer;
  v_approved_count integer;
BEGIN
  SELECT e.current_participants, e.max_participants
  INTO v_current_participants, v_max_participants
  FROM public.events e
  WHERE e.id = p_event_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RETURN QUERY SELECT 'not_found', 0, 0, 0;
    RETURN;
  END IF;

  IF v_current_participants IS NULL OR v_max_participants IS NULL THEN
    RETURN QUERY SELECT 'invalid_capacity', 0, 0, 0;
    RETURN;
  END IF;

  v_remaining_slots := GREATEST(v_max_participants - v_current_participants, 0);

  SELECT count(*)::integer
  INTO v_pending_count
  FROM public.event_applications
  WHERE event_id = p_event_id
    AND status IN ('pending', 'pending_review');

  IF v_pending_count = 0 THEN
    RETURN QUERY SELECT 'no_pending', 0, 0, v_remaining_slots;
    RETURN;
  END IF;

  IF v_remaining_slots = 0 THEN
    RETURN QUERY SELECT 'event_full', 0, v_pending_count, 0;
    RETURN;
  END IF;

  WITH candidate_applications AS (
    SELECT ea.id
    FROM public.event_applications ea
    WHERE ea.event_id = p_event_id
      AND ea.status IN ('pending', 'pending_review')
    ORDER BY ea.created_at ASC
    LIMIT v_remaining_slots
  ),
  updated_applications AS (
    UPDATE public.event_applications ea
    SET status = 'approved',
        updated_at = now()
    WHERE ea.id IN (SELECT id FROM candidate_applications)
      AND ea.status IN ('pending', 'pending_review')
    RETURNING ea.id
  )
  SELECT count(*)::integer
  INTO v_approved_count
  FROM updated_applications;

  RETURN QUERY
  SELECT
    'approved',
    v_approved_count,
    GREATEST(v_pending_count - v_approved_count, 0),
    v_remaining_slots;
END;
$$;

-- Fix #1219: verification approval must reuse the same capacity-safe helper instead of updating applications directly.
CREATE OR REPLACE FUNCTION public.handle_verification_approval()
RETURNS trigger
SET search_path = public
AS $$
BEGIN
  IF (new.status = 'approved' AND old.status IS DISTINCT FROM 'approved') THEN
    INSERT INTO public.partner_verified_users (partner_id, user_id, verification_id, submission_id, verified_at)
    VALUES (new.partner_id, new.user_id, new.verification_id, new.id, now())
    ON CONFLICT (partner_id, user_id, verification_id)
    DO UPDATE SET submission_id = new.id, verified_at = now(), valid_until = null;

    IF (new.application_id IS NOT NULL) THEN
      PERFORM public.approve_event_application_with_capacity_guard(new.application_id);
    END IF;
  END IF;

  IF (new.status = 'rejected' AND old.status IS DISTINCT FROM 'rejected') THEN
    IF (new.application_id IS NOT NULL) THEN
      UPDATE public.event_applications
      SET
        status = 'rejected',
        updated_at = now()
      WHERE id = new.application_id;
    END IF;
  END IF;

  IF (old.status = 'approved' AND new.status IS DISTINCT FROM 'approved') THEN
    DELETE FROM public.partner_verified_users
    WHERE submission_id = new.id;
  END IF;

  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

REVOKE EXECUTE ON FUNCTION public.approve_event_application_with_capacity_guard(uuid) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.approve_event_application_with_capacity_guard(uuid) TO service_role;

REVOKE EXECUTE ON FUNCTION public.bulk_approve_event_applications_with_capacity_guard(uuid) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.bulk_approve_event_applications_with_capacity_guard(uuid) TO service_role;
