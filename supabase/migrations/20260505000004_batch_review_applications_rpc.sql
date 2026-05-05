-- Issue #2101: batch review RPC — unified approve + reject in single transaction with capacity guard.

CREATE TYPE public.rejection_item AS (
  application_id uuid,
  reason         text
);

CREATE FUNCTION public.batch_review_event_applications(
  p_event_id   uuid,
  p_approvals  uuid[],
  p_rejections public.rejection_item[]
)
RETURNS TABLE (
  approved                uuid[],
  rejected                uuid[],
  skipped_due_to_capacity uuid[],
  skipped_already_processed uuid[],
  remaining_slots_after   integer
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_current_participants integer;
  v_max_participants     integer;
  v_remaining_slots      integer;
  v_approved             uuid[] := '{}';
  v_rejected             uuid[] := '{}';
  v_skipped_capacity     uuid[] := '{}';
  v_skipped_processed    uuid[] := '{}';
  v_app_id               uuid;
  v_rej                  public.rejection_item;
  v_app_status           text;
  v_updated_count        integer;
BEGIN
  -- Lock event row for the duration of this transaction.
  SELECT e.current_participants, e.max_participants
  INTO v_current_participants, v_max_participants
  FROM public.events e
  WHERE e.id = p_event_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'event not found: %', p_event_id;
  END IF;

  v_remaining_slots := GREATEST(COALESCE(v_max_participants, 0) - COALESCE(v_current_participants, 0), 0);

  -- Process approvals: oldest first within the given ids, up to remaining capacity.
  IF p_approvals IS NOT NULL AND array_length(p_approvals, 1) > 0 THEN
    FOR v_app_id IN
      SELECT ea.id
      FROM public.event_applications ea
      WHERE ea.id = ANY(p_approvals)
        AND ea.event_id = p_event_id
      ORDER BY ea.created_at ASC
    LOOP
      -- Check current status
      SELECT ea.status INTO v_app_status
      FROM public.event_applications ea
      WHERE ea.id = v_app_id;

      IF v_app_status IS NULL OR v_app_status NOT IN ('pending', 'pending_review') THEN
        v_skipped_processed := v_skipped_processed || v_app_id;
        CONTINUE;
      END IF;

      IF v_remaining_slots <= 0 THEN
        v_skipped_capacity := v_skipped_capacity || v_app_id;
        CONTINUE;
      END IF;

      UPDATE public.event_applications
      SET status = 'approved', updated_at = now()
      WHERE id = v_app_id AND status IN ('pending', 'pending_review');

      GET DIAGNOSTICS v_updated_count = ROW_COUNT;
      IF v_updated_count > 0 THEN
        v_approved := v_approved || v_app_id;
        v_remaining_slots := v_remaining_slots - 1;
      ELSE
        v_skipped_processed := v_skipped_processed || v_app_id;
      END IF;
    END LOOP;
  END IF;

  -- Process rejections: no capacity constraint.
  IF p_rejections IS NOT NULL AND array_length(p_rejections, 1) > 0 THEN
    FOREACH v_rej IN ARRAY p_rejections LOOP
      SELECT ea.status INTO v_app_status
      FROM public.event_applications ea
      WHERE ea.id = v_rej.application_id AND ea.event_id = p_event_id;

      IF v_app_status IS NULL OR v_app_status NOT IN ('pending', 'pending_review') THEN
        v_skipped_processed := v_skipped_processed || v_rej.application_id;
        CONTINUE;
      END IF;

      UPDATE public.event_applications
      SET status = 'rejected',
          rejection_reason = v_rej.reason,
          updated_at = now()
      WHERE id = v_rej.application_id
        AND event_id = p_event_id
        AND status IN ('pending', 'pending_review');

      GET DIAGNOSTICS v_updated_count = ROW_COUNT;
      IF v_updated_count > 0 THEN
        v_rejected := v_rejected || v_rej.application_id;
      ELSE
        v_skipped_processed := v_skipped_processed || v_rej.application_id;
      END IF;
    END LOOP;
  END IF;

  RETURN QUERY SELECT v_approved, v_rejected, v_skipped_capacity, v_skipped_processed, v_remaining_slots;
END;
$$;

REVOKE ALL ON FUNCTION public.batch_review_event_applications(uuid, uuid[], public.rejection_item[]) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.batch_review_event_applications(uuid, uuid[], public.rejection_item[]) TO service_role;
