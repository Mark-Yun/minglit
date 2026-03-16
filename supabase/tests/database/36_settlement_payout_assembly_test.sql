BEGIN;
SELECT no_plan();

SELECT tests.authenticate_as_service_role();

CREATE TEMP TABLE payout_test_state (key text, val text);

-- ============================================================
-- 1. assemble_payouts() 기본 동작: READY items → payouts 생성, payout_id 연결
-- ============================================================
DO $$
DECLARE
  v_partner_id uuid;
  v_cs         char(64);
BEGIN
  INSERT INTO public.partners (name) VALUES ('Payout Assembly Test Partner') RETURNING id INTO v_partner_id;

  -- Insert partner_settlements (bank account info)
  INSERT INTO public.partner_settlements (
    partner_id, biz_type, biz_name, biz_number, representative_name,
    bank_name, account_number, account_holder
  ) VALUES (
    v_partner_id, 'individual', 'Test Biz', '123-45-67890', 'Test Rep',
    'Kakao Bank', '3333-01-1234567', 'Test Rep'
  );

  v_cs := repeat('a', 64);

  -- Insert 3 READY items for this partner
  INSERT INTO public.settlement_items (
    partner_id, settlement_period_start, settlement_period_end,
    currency, source_type, source_id, status,
    gross_amount, platform_fee_rate, platform_fee_amount,
    pg_fee_rate, pg_fee_amount, vat_rate, vat_amount, net_amount, calc_checksum
  ) VALUES
    (v_partner_id, '2026-01-01', '2026-01-31', 'KRW', 'TEST', 'payout-test-001', 'READY',
     100000, 5.00, 5000, 3.50, 3500, 10.00, 850, 90650, v_cs),
    (v_partner_id, '2026-01-01', '2026-01-31', 'KRW', 'TEST', 'payout-test-002', 'READY',
     200000, 5.00, 10000, 3.50, 7000, 10.00, 1700, 181300, v_cs),
    (v_partner_id, '2026-01-01', '2026-01-31', 'KRW', 'TEST', 'payout-test-003', 'READY',
     50000, 5.00, 2500, 3.50, 1750, 10.00, 425, 45325, v_cs);

  INSERT INTO payout_test_state (key, val) VALUES ('partner_id_1', v_partner_id::text);
END;
$$;

-- Run assemble_payouts
SELECT lives_ok(
  $$SELECT assemble_payouts()$$,
  'assemble_payouts() executes without error'
);

-- Verify payout was created
SELECT results_eq(
  $$SELECT count(*)::int FROM payouts
    WHERE partner_id = (SELECT val FROM payout_test_state WHERE key='partner_id_1')::uuid$$,
  $$VALUES (1)$$,
  'assemble_payouts() creates 1 payout for partner with 3 READY items'
);

-- Verify all items are linked to payout
SELECT results_eq(
  $$SELECT count(*)::int FROM settlement_items
    WHERE partner_id = (SELECT val FROM payout_test_state WHERE key='partner_id_1')::uuid
      AND payout_id IS NOT NULL$$,
  $$VALUES (3)$$,
  'all 3 READY items are linked to payout via payout_id'
);

-- ============================================================
-- 2. total_*_amount 합계 일치: total_net_amount = SUM(net_amount of linked items)
-- ============================================================
SELECT results_eq(
  $$SELECT total_net_amount FROM payouts
    WHERE partner_id = (SELECT val FROM payout_test_state WHERE key='partner_id_1')::uuid$$,
  $$VALUES ((90650 + 181300 + 45325)::bigint)$$,
  'total_net_amount = SUM(net_amount) of linked items (317275)'
);

SELECT results_eq(
  $$SELECT total_gross_amount FROM payouts
    WHERE partner_id = (SELECT val FROM payout_test_state WHERE key='partner_id_1')::uuid$$,
  $$VALUES ((100000 + 200000 + 50000)::bigint)$$,
  'total_gross_amount = SUM(gross_amount) of linked items (350000)'
);

SELECT results_eq(
  $$SELECT total_platform_fee_amount FROM payouts
    WHERE partner_id = (SELECT val FROM payout_test_state WHERE key='partner_id_1')::uuid$$,
  $$VALUES ((5000 + 10000 + 2500)::bigint)$$,
  'total_platform_fee_amount = SUM(platform_fee_amount) of linked items (17500)'
);

-- ============================================================
-- 3. item_count 일치: item_count = COUNT(linked items)
-- ============================================================
SELECT results_eq(
  $$SELECT item_count FROM payouts
    WHERE partner_id = (SELECT val FROM payout_test_state WHERE key='partner_id_1')::uuid$$,
  $$VALUES (3)$$,
  'item_count = 3 (matches number of linked settlement_items)'
);

-- ============================================================
-- 4. 다른 partner_id → 별도 payout: 2개 파트너 → 2개 payout
-- ============================================================
DO $$
DECLARE
  v_partner2_id uuid;
  v_cs          char(64);
BEGIN
  INSERT INTO public.partners (name) VALUES ('Payout Assembly Test Partner 2') RETURNING id INTO v_partner2_id;

  INSERT INTO public.partner_settlements (
    partner_id, biz_type, biz_name, biz_number, representative_name,
    bank_name, account_number, account_holder
  ) VALUES (
    v_partner2_id, 'individual', 'Test Biz 2', '987-65-43210', 'Test Rep 2',
    'Shinhan Bank', '110-123-456789', 'Test Rep 2'
  );

  v_cs := repeat('b', 64);

  INSERT INTO public.settlement_items (
    partner_id, settlement_period_start, settlement_period_end,
    currency, source_type, source_id, status,
    gross_amount, platform_fee_rate, platform_fee_amount,
    pg_fee_rate, pg_fee_amount, vat_rate, vat_amount, net_amount, calc_checksum
  ) VALUES (
    v_partner2_id, '2026-01-01', '2026-01-31', 'KRW', 'TEST', 'payout-test-p2-001', 'READY',
    80000, 5.00, 4000, 3.50, 2800, 10.00, 680, 72520, v_cs
  );

  INSERT INTO payout_test_state (key, val) VALUES ('partner_id_2', v_partner2_id::text);
END;
$$;

SELECT lives_ok(
  $$SELECT assemble_payouts()$$,
  'assemble_payouts() runs again for second partner'
);

SELECT results_eq(
  $$SELECT count(*)::int FROM payouts
    WHERE partner_id IN (
      (SELECT val FROM payout_test_state WHERE key='partner_id_1')::uuid,
      (SELECT val FROM payout_test_state WHERE key='partner_id_2')::uuid
    )$$,
  $$VALUES (2)$$,
  '2 different partners → 2 separate payouts created'
);

-- ============================================================
-- 5. 이미 payout_id 있는 items → skip: 기존 payout_id 있으면 재처리 안 함
-- ============================================================
SELECT lives_ok(
  $$SELECT assemble_payouts()$$,
  'assemble_payouts() runs again (idempotency check)'
);

SELECT results_eq(
  $$SELECT count(*)::int FROM payouts
    WHERE partner_id = (SELECT val FROM payout_test_state WHERE key='partner_id_1')::uuid$$,
  $$VALUES (1)$$,
  'items already linked to payout are skipped — no duplicate payout created'
);

-- ============================================================
-- 6. bank_account_snapshot 포함: bank_name, account_holder, account_number, account_last4
-- ============================================================
SELECT results_eq(
  $$SELECT
    (bank_account_snapshot->>'bank_name')::text,
    (bank_account_snapshot->>'account_holder')::text,
    (bank_account_snapshot->>'account_number')::text,
    (bank_account_snapshot->>'account_last4')::text
  FROM payouts
  WHERE partner_id = (SELECT val FROM payout_test_state WHERE key='partner_id_1')::uuid$$,
  $$VALUES ('Kakao Bank', 'Test Rep', '3333-01-1234567', '4567')$$,
  'bank_account_snapshot contains bank_name, account_holder, account_number, account_last4'
);

-- ============================================================
-- 7. payout_request_idempotency_key 형식: 'prod:payout:{partner_id}:{currency}:{yyyyMMdd}-001'
-- ============================================================
SELECT results_eq(
  $$SELECT payout_request_idempotency_key ~
    ('^prod:payout:' ||
     (SELECT val FROM payout_test_state WHERE key='partner_id_1') ||
     ':[A-Z]+:\d{8}-001$')
  FROM payouts
  WHERE partner_id = (SELECT val FROM payout_test_state WHERE key='partner_id_1')::uuid$$,
  $$VALUES (true)$$,
  'payout_request_idempotency_key matches format prod:payout:{partner_id}:{currency}:{yyyyMMdd}-001'
);

SELECT * FROM finish();
ROLLBACK;
