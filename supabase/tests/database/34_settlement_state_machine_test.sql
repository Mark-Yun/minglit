BEGIN;
SELECT no_plan();

SELECT tests.authenticate_as_service_role();

CREATE TEMP TABLE transition_results (
  item_id uuid,
  result  boolean,
  err_msg text
);

-- ============================================================
-- 1. Function existence
-- ============================================================
SELECT has_function('public', 'calculate_settlement_amounts',
  'calculate_settlement_amounts function exists');

SELECT has_function('public', 'calculate_settlement_checksum',
  'calculate_settlement_checksum function exists');

SELECT has_function('public', 'transition_settlement_status',
  'transition_settlement_status function exists');

-- ============================================================
-- 2. calculate_settlement_amounts — floor() correctness
-- ============================================================
SELECT results_eq(
  $$SELECT out_platform_fee_amount, out_pg_fee_amount, out_vat_amount, out_net_amount
    FROM calculate_settlement_amounts(100000, 5.00, 3.50, 10.00)$$,
  $$VALUES (5000::bigint, 3500::bigint, 850::bigint, 90650::bigint)$$,
  'basic fee calculation: platform=5000, pg=3500, vat=850, net=90650'
);

SELECT results_eq(
  $$SELECT out_platform_fee_amount, out_pg_fee_amount, out_vat_amount, out_net_amount
    FROM calculate_settlement_amounts(142857, 5.00, 3.50, 10.00)$$,
  $$VALUES (7142::bigint, 4999::bigint, 1214::bigint, 129502::bigint)$$,
  'floor() applied: 142857*5%=7142.85 floors to 7142'
);

SELECT results_eq(
  $$SELECT out_platform_fee_amount, out_pg_fee_amount, out_vat_amount, out_net_amount
    FROM calculate_settlement_amounts(0, 5.00, 3.50, 10.00)$$,
  $$VALUES (0::bigint, 0::bigint, 0::bigint, 0::bigint)$$,
  'zero gross amount produces all-zero fees'
);

SELECT results_eq(
  $$SELECT out_platform_fee_amount, out_pg_fee_amount, out_vat_amount, out_net_amount
    FROM calculate_settlement_amounts(1000000, 5.00, 3.50, 10.00)$$,
  $$VALUES (50000::bigint, 35000::bigint, 8500::bigint, 906500::bigint)$$,
  'large amount (1M) calculation correct'
);

-- ============================================================
-- 3. calculate_settlement_checksum — format and consistency
-- ============================================================
SELECT results_eq(
  $$SELECT length(calculate_settlement_checksum(
    'aaaaaaaa-0000-0000-0000-000000000001'::uuid,
    '2026-01-01'::date, '2026-01-31'::date,
    'KRW', 100000, 5.00, 3.50, 10.00, 5000, 3500, 850, 90650
  ))$$,
  $$VALUES (64)$$,
  'checksum returns 64-char hex string (SHA-256)'
);

SELECT results_eq(
  $$SELECT
    calculate_settlement_checksum(
      'aaaaaaaa-0000-0000-0000-000000000001'::uuid,
      '2026-01-01'::date, '2026-01-31'::date,
      'KRW', 100000, 5.00, 3.50, 10.00, 5000, 3500, 850, 90650
    ) = calculate_settlement_checksum(
      'aaaaaaaa-0000-0000-0000-000000000001'::uuid,
      '2026-01-01'::date, '2026-01-31'::date,
      'KRW', 100000, 5.00, 3.50, 10.00, 5000, 3500, 850, 90650
    )$$,
  $$VALUES (true)$$,
  'same inputs produce identical checksum (deterministic)'
);

SELECT results_eq(
  $$SELECT
    calculate_settlement_checksum(
      'aaaaaaaa-0000-0000-0000-000000000001'::uuid,
      '2026-01-01'::date, '2026-01-31'::date,
      'KRW', 100000, 5.00, 3.50, 10.00, 5000, 3500, 850, 90650
    ) <> calculate_settlement_checksum(
      'aaaaaaaa-0000-0000-0000-000000000002'::uuid,
      '2026-01-01'::date, '2026-01-31'::date,
      'KRW', 100000, 5.00, 3.50, 10.00, 5000, 3500, 850, 90650
    )$$,
  $$VALUES (true)$$,
  'different partner_id produces different checksum'
);

-- ============================================================
-- 4. transition_settlement_status — state machine correctness
-- ============================================================
DO $$
DECLARE
  v_partner_id uuid;
  v_item_id    uuid;
  v_cs         char(64);
BEGIN
  INSERT INTO public.partners (name) VALUES ('Test Partner Phase2') RETURNING id INTO v_partner_id;

  v_cs := repeat('a', 64);

  INSERT INTO public.settlement_items (
    partner_id, settlement_period_start, settlement_period_end,
    currency, source_type, source_id, status,
    gross_amount, platform_fee_rate, platform_fee_amount,
    pg_fee_rate, pg_fee_amount, vat_rate, vat_amount, net_amount, calc_checksum
  ) VALUES (
    v_partner_id, '2026-01-01', '2026-01-31',
    'KRW', 'TEST', 'phase2-test-001', 'PENDING',
    100000, 5.00, 5000, 3.50, 3500, 10.00, 850, 90650, v_cs
  ) RETURNING id INTO v_item_id;

  INSERT INTO transition_results (item_id, result, err_msg)
  VALUES (v_item_id, null, 'item_created');

  UPDATE transition_results SET item_id = v_item_id WHERE err_msg = 'item_created';
END;
$$;

SELECT results_eq(
  $$SELECT transition_settlement_status(
    (SELECT item_id FROM transition_results LIMIT 1),
    1, 'READY', 'SYSTEM', 'cron', 'calc_succeeded'
  )$$,
  $$VALUES (true)$$,
  'PENDING → READY transition succeeds'
);

SELECT results_eq(
  $$SELECT status, version FROM settlement_items
    WHERE id = (SELECT item_id FROM transition_results LIMIT 1)$$,
  $$VALUES ('READY'::text, 2)$$,
  'after PENDING→READY: status=READY, version=2'
);

SELECT results_eq(
  $$SELECT count(*)::int FROM settlement_histories
    WHERE settlement_item_id = (SELECT item_id FROM transition_results LIMIT 1)$$,
  $$VALUES (1)$$,
  'settlement_histories auto-populated on transition'
);

SELECT results_eq(
  $$SELECT from_status, to_status, actor_type FROM settlement_histories
    WHERE settlement_item_id = (SELECT item_id FROM transition_results LIMIT 1)$$,
  $$VALUES ('PENDING'::text, 'READY'::text, 'SYSTEM'::text)$$,
  'history record contains correct from/to status and actor'
);

SELECT results_eq(
  $$SELECT transition_settlement_status(
    (SELECT item_id FROM transition_results LIMIT 1),
    2, 'HOLD', 'ADMIN', 'admin1', 'hold_applied',
    'MANUAL_REVIEW', 'Requires manual review', null, null
  )$$,
  $$VALUES (true)$$,
  'READY → HOLD transition succeeds with reason_code'
);

SELECT results_eq(
  $$SELECT transition_settlement_status(
    (SELECT item_id FROM transition_results LIMIT 1),
    3, 'READY', 'ADMIN', 'admin1', 'hold_released'
  )$$,
  $$VALUES (true)$$,
  'HOLD → READY transition succeeds'
);

SELECT results_eq(
  $$SELECT transition_settlement_status(
    (SELECT item_id FROM transition_results LIMIT 1),
    4, 'CANCELED', 'ADMIN', 'admin1', 'canceled'
  )$$,
  $$VALUES (true)$$,
  'READY → CANCELED transition succeeds'
);

SELECT throws_ok(
  $$SELECT transition_settlement_status(
    (SELECT item_id FROM transition_results LIMIT 1),
    5, 'READY', 'ADMIN', 'admin1', 'hold_released'
  )$$,
  'P0001',
  null,
  'CANCELED is terminal: transition_settlement_status raises exception'
);

-- ============================================================
-- 5. Invalid transitions — deny by default
-- ============================================================
DO $$
DECLARE
  v_partner_id uuid;
  v_item2_id   uuid;
BEGIN
  SELECT id INTO v_partner_id FROM public.partners WHERE name = 'Test Partner Phase2';

  INSERT INTO public.settlement_items (
    partner_id, settlement_period_start, settlement_period_end,
    currency, source_type, source_id, status,
    gross_amount, platform_fee_rate, platform_fee_amount,
    pg_fee_rate, pg_fee_amount, vat_rate, vat_amount, net_amount, calc_checksum
  ) VALUES (
    v_partner_id, '2026-02-01', '2026-02-28',
    'KRW', 'TEST', 'phase2-test-002', 'PENDING',
    50000, 5.00, 2500, 3.50, 1750, 10.00, 425, 45325, repeat('b', 64)
  ) RETURNING id INTO v_item2_id;

  INSERT INTO transition_results (item_id, err_msg) VALUES (v_item2_id, 'item2');
END;
$$;

SELECT throws_ok(
  $$SELECT transition_settlement_status(
    (SELECT item_id FROM transition_results WHERE err_msg='item2'),
    1, 'COMPLETED', 'SYSTEM', 'job', 'payout_succeeded'
  )$$,
  'P0001',
  null,
  'PENDING→COMPLETED is invalid: raises exception'
);

-- PENDING→FAILED is invalid (matrix check fires first)
-- Test failure_reason_code guard via PROCESSING item:
DO $$
DECLARE
  v_partner_id uuid;
  v_processing_id uuid;
BEGIN
  SELECT id INTO v_partner_id FROM public.partners WHERE name = 'Test Partner Phase2';
  INSERT INTO public.settlement_items (
    partner_id, settlement_period_start, settlement_period_end,
    currency, source_type, source_id, status,
    gross_amount, platform_fee_rate, platform_fee_amount,
    pg_fee_rate, pg_fee_amount, vat_rate, vat_amount, net_amount,
    calc_checksum, processing_started_at
  ) VALUES (
    v_partner_id, '2026-05-01', '2026-05-31',
    'KRW', 'TEST', 'phase2-processing-001', 'PROCESSING',
    60000, 5.00, 3000, 3.50, 2100, 10.00, 510, 54390,
    repeat('e', 64), now()
  ) RETURNING id INTO v_processing_id;
  INSERT INTO transition_results (item_id, err_msg) VALUES (v_processing_id, 'processing_item');
END;
$$;

SELECT throws_ok(
  $$SELECT transition_settlement_status(
    (SELECT item_id FROM transition_results WHERE err_msg='processing_item'),
    1, 'FAILED', 'SYSTEM', 'job', 'payout_failed'
  )$$,
  'failure_reason_code is required when transitioning to FAILED'
);

SELECT throws_ok(
  $$SELECT transition_settlement_status(
    (SELECT item_id FROM transition_results WHERE err_msg='item2'),
    1, 'HOLD', 'ADMIN', 'admin1', 'hold_applied'
  )$$,
  'hold_reason_code is required when transitioning to HOLD'
);

SELECT throws_ok(
  $$SELECT transition_settlement_status(
    (SELECT item_id FROM transition_results WHERE err_msg='item2'),
    999, 'READY', 'SYSTEM', 'cron', 'calc_succeeded'
  )$$,
  'P0001',
  null,
  'CAS failure: wrong version raises exception'
);

SELECT throws_ok(
  $$SELECT transition_settlement_status(
    '00000000-dead-beef-dead-000000000000'::uuid,
    1, 'READY', 'SYSTEM', 'cron', 'calc_succeeded'
  )$$,
  'P0001',
  null,
  'non-existent item raises exception'
);

-- ============================================================
-- 6. Negative net_amount is allowed (CHECK removed)
-- ============================================================
DO $$
DECLARE
  v_partner_id uuid;
BEGIN
  SELECT id INTO v_partner_id FROM public.partners WHERE name = 'Test Partner Phase2';

  INSERT INTO public.settlement_items (
    partner_id, settlement_period_start, settlement_period_end,
    currency, source_type, source_id, status,
    gross_amount, platform_fee_rate, platform_fee_amount,
    pg_fee_rate, pg_fee_amount, vat_rate, vat_amount, net_amount, calc_checksum
  ) VALUES (
    v_partner_id, '2026-03-01', '2026-03-31',
    'KRW', 'TEST', 'phase2-test-neg', 'PENDING',
    1000, 5.00, 50, 3.50, 35, 10.00, 8, -9000, repeat('c', 64)
  );
END;
$$;

SELECT results_eq(
  $$SELECT net_amount FROM settlement_items WHERE source_id = 'phase2-test-neg'$$,
  $$VALUES (-9000::bigint)$$,
  'negative net_amount is allowed (CHECK constraint removed)'
);

SELECT * FROM finish();
ROLLBACK;
