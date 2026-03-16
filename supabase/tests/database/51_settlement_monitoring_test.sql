BEGIN;
SELECT no_plan();

SELECT tests.authenticate_as_service_role();

-- ============================================================
-- 1. Views exist
-- ============================================================
SELECT has_view('public', 'settlement_metrics', 'settlement_metrics view exists');

-- ============================================================
-- 2. Tables exist
-- ============================================================
SELECT has_table('public', 'settlement_alarm_results', 'settlement_alarm_results table exists');

-- ============================================================
-- 3. Functions exist
-- ============================================================
SELECT has_function('public', 'check_settlement_alarms', 'check_settlement_alarms function exists');

-- ============================================================
-- 4. settlement_metrics view returns one row
-- ============================================================
SELECT is(
  (SELECT count(*) FROM public.settlement_metrics),
  1::bigint,
  'settlement_metrics returns exactly one row'
);

-- ============================================================
-- 5. check_settlement_alarms runs without error
-- ============================================================
DO $$
BEGIN
  PERFORM public.check_settlement_alarms();
END$$;
SELECT ok(true, 'check_settlement_alarms() executes without error');

-- ============================================================
-- 6. 30-min dedup: second HIGH_FAILURE_RATE alarm within window not inserted
-- ============================================================
INSERT INTO public.settlement_alarm_results (alarm_type, severity, message, metric_value, threshold, fired_at)
VALUES ('HIGH_FAILURE_RATE', 'CRITICAL', 'test alarm', 6.5, 5, now());

DO $$
BEGIN
  PERFORM public.check_settlement_alarms();
END$$;

SELECT is(
  (SELECT count(*) FROM public.settlement_alarm_results WHERE alarm_type = 'HIGH_FAILURE_RATE' AND fired_at > now() - interval '1 minute'),
  1::bigint,
  '30-min dedup: second alarm within window not inserted'
);

SELECT * FROM finish();
ROLLBACK;
