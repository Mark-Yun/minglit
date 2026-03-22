-- Fix update_single_settlement_ready_status: use positional params for transition_settlement_status
-- The previous version (20260316000002) used named params that don't match the function signature.
-- transition_settlement_status signature: (p_item_id, p_expected_version, p_new_status, p_actor_type, p_actor_id, p_event_type, ...)

CREATE OR REPLACE FUNCTION public.update_single_settlement_ready_status(
  p_settlement_id uuid
)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
  rec RECORD;
BEGIN
  FOR rec IN
    SELECT *
    FROM settlement_items
    WHERE id = p_settlement_id
      AND status = 'PENDING'
      AND event_completed_at <= now() - interval '14 days'
    FOR UPDATE
  LOOP
    BEGIN
      PERFORM public.transition_settlement_status(
        rec.id,
        rec.version,
        'READY',
        'SYSTEM',
        'backend_simulator',
        'status_to_ready',
        null::text, null::text, null::text, null::text,
        '{"source": "update_single_settlement_ready_status"}'::jsonb,
        null::text
      );
    EXCEPTION WHEN OTHERS THEN
      RAISE WARNING 'update_single_settlement_ready_status: CAS failed for %, %', rec.id, SQLERRM;
    END;
  END LOOP;
END;
$$;

GRANT EXECUTE ON FUNCTION public.update_single_settlement_ready_status(uuid) TO service_role;
