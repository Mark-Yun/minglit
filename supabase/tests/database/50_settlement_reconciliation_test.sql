BEGIN;
SELECT no_plan();

SELECT tests.authenticate_as_service_role();

-- ============================================================
-- 1. Tables exist
-- ============================================================
SELECT has_table('public', 'reconciliation_runs', 'reconciliation_runs table exists');
SELECT has_table('public', 'reconciliation_results', 'reconciliation_results table exists');

-- ============================================================
-- 2. Functions exist
-- ============================================================
SELECT has_function('public', 'classify_reconciliation_mismatch', 'classify_reconciliation_mismatch function exists');
SELECT has_function('public', 'process_reconciliation_kill_switch', 'process_reconciliation_kill_switch function exists');

-- ============================================================
-- 3. reconciliation_runs: partial unique (RUNNING only) prevents concurrent runs
-- Allows retries (FAILED→new RUNNING on same date/type)
-- ============================================================
INSERT INTO public.reconciliation_runs (run_date, run_type, status)
VALUES ('2026-03-14', 'DAILY', 'RUNNING');

DO $$
DECLARE v_raised boolean := false;
BEGIN
  BEGIN
    INSERT INTO public.reconciliation_runs (run_date, run_type, status)
    VALUES ('2026-03-14', 'DAILY', 'RUNNING');
  EXCEPTION WHEN unique_violation THEN
    v_raised := true;
  END;
  ASSERT v_raised, 'concurrent RUNNING runs for same date/type should raise unique_violation';
END$$;
SELECT ok(true, 'reconciliation_runs: concurrent RUNNING blocked, retries allowed');

UPDATE public.reconciliation_runs SET status = 'FAILED' WHERE run_date = '2026-03-14' AND run_type = 'DAILY';

DO $$
DECLARE v_raised boolean := false;
BEGIN
  BEGIN
    INSERT INTO public.reconciliation_runs (run_date, run_type, status)
    VALUES ('2026-03-14', 'DAILY', 'RUNNING');
  EXCEPTION WHEN OTHERS THEN
    v_raised := true;
  END;
  ASSERT NOT v_raised, 'retry after FAILED should succeed (partial unique index allows it)';
END$$;
SELECT ok(true, 'reconciliation_runs: retry after FAILED allowed');

-- ============================================================
-- 4. classify_reconciliation_mismatch: MISSING_IN_LEDGER
-- ============================================================
SELECT results_eq(
  $$SELECT mismatch_type::text, severity::text
    FROM public.classify_reconciliation_mismatch(null::bigint, 100000::bigint, null, null, null, null)$$,
  $$VALUES ('MISSING_IN_LEDGER', 'CRITICAL')$$,
  'null ledger + portone amount → MISSING_IN_LEDGER CRITICAL'
);

-- ============================================================
-- 5. classify_reconciliation_mismatch: MISSING_IN_PORTONE
-- ============================================================
SELECT results_eq(
  $$SELECT mismatch_type::text, severity::text
    FROM public.classify_reconciliation_mismatch(100000::bigint, null::bigint, null, null, null, null)$$,
  $$VALUES ('MISSING_IN_PORTONE', 'CRITICAL')$$,
  'ledger + null portone → MISSING_IN_PORTONE CRITICAL'
);

-- ============================================================
-- 6. classify_reconciliation_mismatch: AMOUNT_MISMATCH
-- ============================================================
SELECT results_eq(
  $$SELECT mismatch_type::text, severity::text
    FROM public.classify_reconciliation_mismatch(100000::bigint, 99000::bigint, null, null, null, null)$$,
  $$VALUES ('AMOUNT_MISMATCH', 'CRITICAL')$$,
  'amount diff > 1 → AMOUNT_MISMATCH CRITICAL'
);

-- ============================================================
-- 7. classify_reconciliation_mismatch: MATCHED (exact)
-- ============================================================
SELECT results_eq(
  $$SELECT mismatch_type::text, severity::text
    FROM public.classify_reconciliation_mismatch(100000::bigint, 100000::bigint, null, null, null, null)$$,
  $$VALUES ('MATCHED', 'INFO')$$,
  'exact amounts → MATCHED INFO'
);

-- ============================================================
-- 8. classify_reconciliation_mismatch: DATE_SHIFT
-- ============================================================
SELECT results_eq(
  $$SELECT mismatch_type::text, severity::text
    FROM public.classify_reconciliation_mismatch(100000::bigint, 100000::bigint, '2026-03-14'::date, '2026-03-15'::date, null, null)$$,
  $$VALUES ('DATE_SHIFT', 'WARNING')$$,
  'same amount, different dates → DATE_SHIFT WARNING'
);

-- ============================================================
-- 9. classify_reconciliation_mismatch: STATUS_MISMATCH
-- ============================================================
SELECT results_eq(
  $$SELECT mismatch_type::text, severity::text
    FROM public.classify_reconciliation_mismatch(100000::bigint, 100000::bigint, '2026-03-14'::date, '2026-03-14'::date, 'COMPLETED', 'PENDING')$$,
  $$VALUES ('STATUS_MISMATCH', 'WARNING')$$,
  'same amount+date, different status → STATUS_MISMATCH WARNING'
);

-- ============================================================
-- 10. process_reconciliation_kill_switch: CRITICAL >= 3 → activates kill switch
-- ============================================================
DO $$
DECLARE
  v_run_id uuid;
BEGIN
  PERFORM public.toggle_settlement_kill_switch(false, 'test');

  INSERT INTO public.reconciliation_runs (run_date, run_type, status, critical_count)
  VALUES ('2026-03-13', 'DAILY', 'RUNNING', 0)
  RETURNING id INTO v_run_id;

  INSERT INTO public.reconciliation_results (run_id, mismatch_type, severity)
  VALUES
    (v_run_id, 'MISSING_IN_LEDGER', 'CRITICAL'),
    (v_run_id, 'MISSING_IN_LEDGER', 'CRITICAL'),
    (v_run_id, 'MISSING_IN_PORTONE', 'CRITICAL');

  PERFORM public.process_reconciliation_kill_switch(v_run_id);
END$$;

SELECT is(
  (SELECT (value->>'enabled')::boolean FROM public.system_settings WHERE key = 'settlement_kill_switch'),
  true,
  'process_reconciliation_kill_switch: CRITICAL >= 3 activates kill switch'
);

SELECT toggle_settlement_kill_switch(false, 'test-cleanup');

SELECT * FROM finish();
ROLLBACK;
