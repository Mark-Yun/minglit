BEGIN;
SELECT no_plan();

SELECT tests.authenticate_as_service_role();

-- ============================================================
-- 1. Table existence
-- ============================================================
SELECT has_table('public', 'system_settings', 'system_settings table exists');

-- ============================================================
-- 2. Function existence
-- ============================================================
SELECT has_function('public', 'toggle_settlement_kill_switch', 'toggle_settlement_kill_switch function exists');
SELECT has_function('public', 'force_fail_processing_on_kill_switch', 'force_fail_processing_on_kill_switch function exists');

-- ============================================================
-- 3. Kill switch default = false
-- ============================================================
SELECT is(
  (SELECT (value->>'enabled')::boolean FROM public.system_settings WHERE key = 'settlement_kill_switch'),
  false,
  'kill switch default is false'
);

-- ============================================================
-- 4. reconciliation threshold = 3
-- ============================================================
SELECT is(
  (SELECT (value->>'value')::int FROM public.system_settings WHERE key = 'reconciliation_kill_switch_threshold'),
  3,
  'reconciliation kill switch threshold default is 3'
);

-- ============================================================
-- 5. Toggle ON sets enabled=true
-- ============================================================
SELECT toggle_settlement_kill_switch(true, 'test-admin');
SELECT is(
  (SELECT (value->>'enabled')::boolean FROM public.system_settings WHERE key = 'settlement_kill_switch'),
  true,
  'toggle ON sets kill switch to true'
);

-- ============================================================
-- 6. Toggle OFF sets enabled=false
-- ============================================================
SELECT toggle_settlement_kill_switch(false, 'test-admin');
SELECT is(
  (SELECT (value->>'enabled')::boolean FROM public.system_settings WHERE key = 'settlement_kill_switch'),
  false,
  'toggle OFF sets kill switch to false'
);

SELECT * FROM finish();
ROLLBACK;
