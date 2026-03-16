-- Add single-settlement variant of update_settlement_ready_status
-- Allows targeted PENDING → READY transition for a specific settlement_id
-- Fixes: test isolation issue where bulk RPC would affect all eligible settlements

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
      PERFORM transition_settlement_status(
        p_settlement_id := rec.id,
        p_expected_status := 'PENDING',
        p_new_status := 'READY',
        p_version := rec.version
      );
    EXCEPTION WHEN OTHERS THEN
      RAISE WARNING 'update_single_settlement_ready_status: CAS failed for %, %', rec.id, SQLERRM;
    END;
  END LOOP;
END;
$$;

GRANT EXECUTE ON FUNCTION public.update_single_settlement_ready_status(uuid) TO service_role;
