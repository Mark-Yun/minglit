BEGIN;
SELECT no_plan();

SELECT tests.authenticate_as_service_role();

CREATE TEMP TABLE retry_test_state (key text, val text);

-- ============================================================
-- Setup: create test partner
-- ============================================================
DO $$
DECLARE
  v_partner_id uuid;
BEGIN
  INSERT INTO public.partners (name) VALUES ('Retry Test Partner') RETURNING id INTO v_partner_id;
  INSERT INTO retry_test_state (key, val) VALUES ('partner_id', v_partner_id::text);
END;
$$;

-- ============================================================
-- 1. eligible FAILED → READY: retryable=true, retry_count<8, next_retry_at<=now()
-- ============================================================
DO $$
DECLARE
  v_partner_id uuid;
  v_item_id    uuid;
BEGIN
  SELECT val::uuid INTO v_partner_id FROM retry_test_state WHERE key = 'partner_id';

  INSERT INTO public.settlement_items (
    partner_id, settlement_period_start, settlement_period_end,
    currency, source_type, source_id, status,
    gross_amount, platform_fee_rate, platform_fee_amount,
    pg_fee_rate, pg_fee_amount, vat_rate, vat_amount, net_amount,
    calc_checksum, retryable, retry_count, next_retry_at,
    failure_reason_code
  ) VALUES (
    v_partner_id, '2026-01-01', '2026-01-31',
    'KRW', 'TEST', 'retry-eligible-001', 'FAILED',
    100000, 5.00, 5000, 3.50, 3500, 10.00, 850, 90650,
    repeat('a', 64), true, 2, now() - interval '1 minute',
    'TRANSFER_FAILED'
  ) RETURNING id INTO v_item_id;

  INSERT INTO retry_test_state (key, val) VALUES ('eligible_item_id', v_item_id::text);
END;
$$;

SELECT lives_ok(
  $$SELECT retry_failed_settlements()$$,
  'retry_failed_settlements() executes without error'
);

SELECT results_eq(
  $$SELECT status FROM settlement_items WHERE source_id = 'retry-eligible-001'$$,
  $$VALUES ('READY'::text)$$,
  'eligible FAILED item (retryable=true, retry_count<8, next_retry_at<=now()) transitions to READY'
);

SELECT results_eq(
  $$SELECT count(*)::int FROM settlement_histories
    WHERE settlement_item_id = (SELECT val FROM retry_test_state WHERE key='eligible_item_id')::uuid
      AND to_status = 'READY'
      AND event_type = 'retry_scheduled'$$,
  $$VALUES (1)$$,
  'retry transition recorded in settlement_histories with event_type=retry_scheduled'
);

-- ============================================================
-- 2. retryable=false → skip: FAILED + retryable=false → 상태 변경 없음
-- ============================================================
DO $$
DECLARE
  v_partner_id uuid;
BEGIN
  SELECT val::uuid INTO v_partner_id FROM retry_test_state WHERE key = 'partner_id';

  INSERT INTO public.settlement_items (
    partner_id, settlement_period_start, settlement_period_end,
    currency, source_type, source_id, status,
    gross_amount, platform_fee_rate, platform_fee_amount,
    pg_fee_rate, pg_fee_amount, vat_rate, vat_amount, net_amount,
    calc_checksum, retryable, retry_count, next_retry_at,
    failure_reason_code
  ) VALUES (
    v_partner_id, '2026-02-01', '2026-02-28',
    'KRW', 'TEST', 'retry-not-retryable-001', 'FAILED',
    50000, 5.00, 2500, 3.50, 1750, 10.00, 425, 45325,
    repeat('b', 64), false, 1, now() - interval '1 minute',
    'INVALID_ACCOUNT'
  );
END;
$$;

SELECT lives_ok(
  $$SELECT retry_failed_settlements()$$,
  'retry_failed_settlements() runs without error (retryable=false item present)'
);

SELECT results_eq(
  $$SELECT status FROM settlement_items WHERE source_id = 'retry-not-retryable-001'$$,
  $$VALUES ('FAILED'::text)$$,
  'retryable=false item stays FAILED — not retried'
);

-- ============================================================
-- 3. retry_count >= 8 → skip: retry_count=8 → 상태 변경 없음
-- ============================================================
DO $$
DECLARE
  v_partner_id uuid;
BEGIN
  SELECT val::uuid INTO v_partner_id FROM retry_test_state WHERE key = 'partner_id';

  INSERT INTO public.settlement_items (
    partner_id, settlement_period_start, settlement_period_end,
    currency, source_type, source_id, status,
    gross_amount, platform_fee_rate, platform_fee_amount,
    pg_fee_rate, pg_fee_amount, vat_rate, vat_amount, net_amount,
    calc_checksum, retryable, retry_count, next_retry_at,
    failure_reason_code
  ) VALUES (
    v_partner_id, '2026-03-01', '2026-03-31',
    'KRW', 'TEST', 'retry-max-count-001', 'FAILED',
    30000, 5.00, 1500, 3.50, 1050, 10.00, 255, 27195,
    repeat('c', 64), true, 8, now() - interval '1 minute',
    'TRANSFER_FAILED'
  );
END;
$$;

SELECT lives_ok(
  $$SELECT retry_failed_settlements()$$,
  'retry_failed_settlements() runs without error (retry_count=8 item present)'
);

SELECT results_eq(
  $$SELECT status FROM settlement_items WHERE source_id = 'retry-max-count-001'$$,
  $$VALUES ('FAILED'::text)$$,
  'retry_count=8 item stays FAILED — max retry count reached'
);

-- ============================================================
-- 4. next_retry_at > now() → skip: 아직 재시도 시간 안 됨 → 상태 변경 없음
-- ============================================================
DO $$
DECLARE
  v_partner_id uuid;
BEGIN
  SELECT val::uuid INTO v_partner_id FROM retry_test_state WHERE key = 'partner_id';

  INSERT INTO public.settlement_items (
    partner_id, settlement_period_start, settlement_period_end,
    currency, source_type, source_id, status,
    gross_amount, platform_fee_rate, platform_fee_amount,
    pg_fee_rate, pg_fee_amount, vat_rate, vat_amount, net_amount,
    calc_checksum, retryable, retry_count, next_retry_at,
    failure_reason_code
  ) VALUES (
    v_partner_id, '2026-04-01', '2026-04-30',
    'KRW', 'TEST', 'retry-future-001', 'FAILED',
    20000, 5.00, 1000, 3.50, 700, 10.00, 170, 18130,
    repeat('d', 64), true, 3, now() + interval '1 hour',
    'TRANSFER_FAILED'
  );
END;
$$;

SELECT lives_ok(
  $$SELECT retry_failed_settlements()$$,
  'retry_failed_settlements() runs without error (future next_retry_at item present)'
);

SELECT results_eq(
  $$SELECT status FROM settlement_items WHERE source_id = 'retry-future-001'$$,
  $$VALUES ('FAILED'::text)$$,
  'next_retry_at > now() item stays FAILED — not yet time to retry'
);

-- ============================================================
-- 5. calculate_next_retry_at(0) 범위: 48~72초 (60s ±20%)
-- ============================================================
SELECT results_eq(
  $$SELECT (
    extract(epoch from (calculate_next_retry_at(0) - now())) >= 48 AND
    extract(epoch from (calculate_next_retry_at(0) - now())) <= 72
  )$$,
  $$VALUES (true)$$,
  'calculate_next_retry_at(0) returns timestamp 48~72s from now (60s ±20%)'
);

-- ============================================================
-- 6. calculate_next_retry_at(7) 범위: 6144~9216초 (7680s ±20%, 2^7*60=7680)
-- ============================================================
SELECT results_eq(
  $$SELECT (
    extract(epoch from (calculate_next_retry_at(7) - now())) >= 6144 AND
    extract(epoch from (calculate_next_retry_at(7) - now())) <= 9216
  )$$,
  $$VALUES (true)$$,
  'calculate_next_retry_at(7) returns timestamp 6144~9216s from now (7680s ±20%)'
);

-- ============================================================
-- 7. calculate_next_retry_at(10) 범위: 17280~25920초 (21600s ±20%, capped at 6h)
-- ============================================================
SELECT results_eq(
  $$SELECT (
    extract(epoch from (calculate_next_retry_at(10) - now())) >= 17280 AND
    extract(epoch from (calculate_next_retry_at(10) - now())) <= 25920
  )$$,
  $$VALUES (true)$$,
  'calculate_next_retry_at(10) returns timestamp 17280~25920s from now (21600s ±20%, 6h cap)'
);

SELECT * FROM finish();
ROLLBACK;
