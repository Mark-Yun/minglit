BEGIN;
SELECT no_plan();

SELECT tests.authenticate_as_service_role();

-- ============================================================
-- Setup: ensure kill switch starts OFF
-- ============================================================
SELECT toggle_settlement_kill_switch(false, 'test-setup');

-- ============================================================
-- 1. Kill switch starts as OFF
-- ============================================================
SELECT is(
  (SELECT (value->>'enabled')::boolean FROM public.system_settings WHERE key = 'settlement_kill_switch'),
  false,
  'kill switch starts as OFF'
);

-- ============================================================
-- 2. Toggle kill switch ON
-- ============================================================
SELECT toggle_settlement_kill_switch(true, 'test');

SELECT is(
  (SELECT (value->>'enabled')::boolean FROM public.system_settings WHERE key = 'settlement_kill_switch'),
  true,
  'kill switch is ON after toggle'
);

-- ============================================================
-- 3. PROCESSING transition blocked when kill switch is ON
-- ============================================================
DO $$
DECLARE
  v_raised boolean := false;
  v_item_id uuid := gen_random_uuid();
BEGIN
  BEGIN
    PERFORM public.transition_settlement_status(
      v_item_id, 0, 'PROCESSING', 'SYSTEM', 'test', 'test_event'
    );
  EXCEPTION WHEN OTHERS THEN
    v_raised := true;
  END;
  ASSERT v_raised, 'transition to PROCESSING with kill switch ON should raise';
END$$;
SELECT ok(true, 'kill switch ON: PROCESSING transition raises exception');

-- ============================================================
-- 4. Toggle kill switch OFF
-- ============================================================
SELECT toggle_settlement_kill_switch(false, 'test');

SELECT is(
  (SELECT (value->>'enabled')::boolean FROM public.system_settings WHERE key = 'settlement_kill_switch'),
  false,
  'kill switch toggled back to OFF'
);

-- ============================================================
-- 5. force_fail_processing_on_kill_switch function exists
-- ============================================================
SELECT has_function('public', 'force_fail_processing_on_kill_switch', 'force_fail_processing_on_kill_switch function exists');

-- ============================================================
-- 6. toggle_settlement_kill_switch function exists
-- ============================================================
SELECT has_function('public', 'toggle_settlement_kill_switch', 'toggle_settlement_kill_switch function exists');

SELECT * FROM finish();
ROLLBACK;
