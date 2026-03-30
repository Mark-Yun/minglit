BEGIN;
SELECT no_plan();

SELECT tests.authenticate_as_service_role();

CREATE TEMP TABLE trigger_results (key text, val text);

-- ============================================================
-- 1. Trigger cutover: event completion → settlement_items
-- ============================================================
DO $$
DECLARE
  v_partner_id uuid;
  v_party_id   uuid;
  v_event_id   uuid;
  v_ticket_id  uuid;
  v_user_id    uuid;
BEGIN
  v_user_id := tests.create_supabase_user('trigger_test_user');
  INSERT INTO public.partners (name) VALUES ('Trigger Test Partner') RETURNING id INTO v_partner_id;

  INSERT INTO public.parties (partner_id, title, min_confirmed_count, max_participants)
  VALUES (v_partner_id, 'Trigger Test Party', 0, 10)
  RETURNING id INTO v_party_id;

  INSERT INTO public.events (party_id, start_time, end_time, min_confirmed_count, max_participants)
  VALUES (v_party_id,
    now() - interval '2 days',
    now() - interval '1 day',
    0, 10)
  RETURNING id INTO v_event_id;

  INSERT INTO public.tickets (event_id, name, quantity, price)
  VALUES (v_event_id, 'Trigger Test Ticket', 10, 50000)
  RETURNING id INTO v_ticket_id;

  INSERT INTO public.event_applications (
    event_id, ticket_id, user_id, status, payment_id, payment_amount
  ) VALUES (
    v_event_id, v_ticket_id, v_user_id, 'paid', 'pay_trigger_001', 50000
  );

  INSERT INTO trigger_results (key, val) VALUES
    ('event_id', v_event_id::text),
    ('partner_id', v_partner_id::text);

  UPDATE public.events SET status = 'completed' WHERE id = v_event_id;
END;
$$;

SELECT results_eq(
  $$SELECT count(*)::int FROM settlement_items
    WHERE source_id = (SELECT val FROM trigger_results WHERE key='event_id')
      AND source_type = 'EVENT'$$,
  $$VALUES (1)$$,
  'event completion creates 1 settlement_items record'
);

SELECT results_eq(
  $$SELECT status FROM settlement_items
    WHERE source_id = (SELECT val FROM trigger_results WHERE key='event_id')$$,
  $$VALUES ('PENDING'::text)$$,
  'new settlement_item starts in PENDING status'
);

SELECT results_eq(
  $$SELECT gross_amount FROM settlement_items
    WHERE source_id = (SELECT val FROM trigger_results WHERE key='event_id')$$,
  $$VALUES (50000::bigint)$$,
  'gross_amount = total paid sales (50000)'
);

SELECT results_eq(
  $$SELECT platform_fee_amount FROM settlement_items
    WHERE source_id = (SELECT val FROM trigger_results WHERE key='event_id')$$,
  $$VALUES (2500::bigint)$$,
  'platform_fee = floor(50000 * 5%) = 2500'
);

SELECT results_eq(
  $$SELECT count(*)::int FROM settlements
    WHERE event_id = (SELECT val FROM trigger_results WHERE key='event_id')::uuid$$,
  $$VALUES (0)$$,
  'old settlements table NOT written (full cutover)'
);

SELECT results_eq(
  $$SELECT length(calc_checksum) FROM settlement_items
    WHERE source_id = (SELECT val FROM trigger_results WHERE key='event_id')$$,
  $$VALUES (64)$$,
  'calc_checksum is a valid 64-char SHA-256 hex'
);

-- ============================================================
-- 2. Cron: 14-day hold transition PENDING → READY
-- ============================================================
DO $$
DECLARE
  v_partner_id uuid;
  v_item_id    uuid;
  v_cs         char(64);
  v_amounts    record;
BEGIN
  SELECT id INTO v_partner_id FROM public.partners WHERE name = 'Trigger Test Partner';

  SELECT * INTO v_amounts FROM calculate_settlement_amounts(80000, 5.00, 3.50, 10.00);

  v_cs := calculate_settlement_checksum(
    v_partner_id,
    '2026-01-01'::date, '2026-01-31'::date,
    'KRW', 80000, 5.00, 3.50, 10.00,
    v_amounts.out_platform_fee_amount,
    v_amounts.out_pg_fee_amount,
    v_amounts.out_vat_amount,
    v_amounts.out_net_amount
  );

  INSERT INTO public.settlement_items (
    partner_id, settlement_period_start, settlement_period_end,
    currency, source_type, source_id, status,
    gross_amount, platform_fee_rate, platform_fee_amount,
    pg_fee_rate, pg_fee_amount, vat_rate, vat_amount, net_amount,
    calc_checksum, event_completed_at
  ) VALUES (
    v_partner_id, '2026-01-01', '2026-01-31',
    'KRW', 'TEST', 'cron-test-14d', 'PENDING',
    80000, 5.00, v_amounts.out_platform_fee_amount,
    3.50, v_amounts.out_pg_fee_amount, 10.00, v_amounts.out_vat_amount, v_amounts.out_net_amount,
    v_cs,
    now() - interval '15 days'
  ) RETURNING id INTO v_item_id;

  INSERT INTO trigger_results (key, val) VALUES ('cron_item_id', v_item_id::text);
END;
$$;

SELECT is(
  (SELECT status FROM settlement_items WHERE source_id = 'cron-test-14d'),
  'PENDING',
  'before cron: status is PENDING'
);

SELECT lives_ok(
  $$SELECT update_settlement_ready_status()$$,
  'update_settlement_ready_status() executes without error'
);

SELECT results_eq(
  $$SELECT status FROM settlement_items WHERE source_id = 'cron-test-14d'$$,
  $$VALUES ('READY'::text)$$,
  '15-day old item transitions to READY after cron'
);

SELECT results_eq(
  $$SELECT count(*)::int FROM settlement_histories
    WHERE settlement_item_id = (SELECT val FROM trigger_results WHERE key='cron_item_id')::uuid
    AND event_type = 'calc_succeeded'$$,
  $$VALUES (1)$$,
  'cron transition recorded in settlement_histories'
);

-- ============================================================
-- 3. Cron: 13-day item does NOT transition
-- ============================================================
DO $$
DECLARE
  v_partner_id uuid;
  v_amounts    record;
  v_cs         char(64);
BEGIN
  SELECT id INTO v_partner_id FROM public.partners WHERE name = 'Trigger Test Partner';
  SELECT * INTO v_amounts FROM calculate_settlement_amounts(30000, 5.00, 3.50, 10.00);

  v_cs := calculate_settlement_checksum(
    v_partner_id, '2026-02-01'::date, '2026-02-28'::date,
    'KRW', 30000, 5.00, 3.50, 10.00,
    v_amounts.out_platform_fee_amount,
    v_amounts.out_pg_fee_amount,
    v_amounts.out_vat_amount,
    v_amounts.out_net_amount
  );

  INSERT INTO public.settlement_items (
    partner_id, settlement_period_start, settlement_period_end,
    currency, source_type, source_id, status,
    gross_amount, platform_fee_rate, platform_fee_amount,
    pg_fee_rate, pg_fee_amount, vat_rate, vat_amount, net_amount,
    calc_checksum, event_completed_at
  ) VALUES (
    v_partner_id, '2026-02-01', '2026-02-28',
    'KRW', 'TEST', 'cron-test-13d', 'PENDING',
    30000, 5.00, v_amounts.out_platform_fee_amount,
    3.50, v_amounts.out_pg_fee_amount, 10.00, v_amounts.out_vat_amount, v_amounts.out_net_amount,
    v_cs,
    now() - interval '13 days'
  );
END;
$$;

SELECT lives_ok(
  $$SELECT update_settlement_ready_status()$$,
  'cron runs without error'
);

SELECT results_eq(
  $$SELECT status FROM settlement_items WHERE source_id = 'cron-test-13d'$$,
  $$VALUES ('PENDING'::text)$$,
  '13-day old item stays PENDING (14-day threshold not met)'
);

-- ============================================================
-- 4. Cron: checksum mismatch → FAILED
-- ============================================================
DO $$
DECLARE
  v_partner_id uuid;
  v_amounts    record;
BEGIN
  SELECT id INTO v_partner_id FROM public.partners WHERE name = 'Trigger Test Partner';
  SELECT * INTO v_amounts FROM calculate_settlement_amounts(20000, 5.00, 3.50, 10.00);

  INSERT INTO public.settlement_items (
    partner_id, settlement_period_start, settlement_period_end,
    currency, source_type, source_id, status,
    gross_amount, platform_fee_rate, platform_fee_amount,
    pg_fee_rate, pg_fee_amount, vat_rate, vat_amount, net_amount,
    calc_checksum, event_completed_at
  ) VALUES (
    v_partner_id, '2026-03-01', '2026-03-31',
    'KRW', 'TEST', 'cron-test-tampered', 'PENDING',
    20000, 5.00, v_amounts.out_platform_fee_amount,
    3.50, v_amounts.out_pg_fee_amount, 10.00, v_amounts.out_vat_amount, v_amounts.out_net_amount,
    repeat('f', 64),
    now() - interval '20 days'
  );
END;
$$;

SELECT lives_ok(
  $$SELECT update_settlement_ready_status()$$,
  'cron handles checksum mismatch gracefully'
);

SELECT results_eq(
  $$SELECT status FROM settlement_items WHERE source_id = 'cron-test-tampered'$$,
  $$VALUES ('HOLD'::text)$$,
  'tampered checksum results in HOLD status for manual review'
);

SELECT results_eq(
  $$SELECT hold_reason_code FROM settlement_items WHERE source_id = 'cron-test-tampered'$$,
  $$VALUES ('CHECKSUM_MISMATCH'::text)$$,
  'hold_reason_code = CHECKSUM_MISMATCH for tampered item'
);

-- ============================================================
-- 5. Stuck processing check: PROCESSING > 2h → FAILED
-- ============================================================
DO $$
DECLARE
  v_partner_id uuid;
  v_item_id    uuid;
BEGIN
  SELECT id INTO v_partner_id FROM public.partners WHERE name = 'Trigger Test Partner';

  INSERT INTO public.settlement_items (
    partner_id, settlement_period_start, settlement_period_end,
    currency, source_type, source_id, status,
    gross_amount, platform_fee_rate, platform_fee_amount,
    pg_fee_rate, pg_fee_amount, vat_rate, vat_amount, net_amount,
    calc_checksum, processing_started_at
  ) VALUES (
    v_partner_id, '2026-04-01', '2026-04-30',
    'KRW', 'TEST', 'stuck-processing-001', 'PROCESSING',
    10000, 5.00, 500, 3.50, 350, 10.00, 85, 9065,
    repeat('d', 64),
    now() - interval '3 hours'
  ) RETURNING id INTO v_item_id;

  INSERT INTO trigger_results (key, val) VALUES ('stuck_item_id', v_item_id::text);
END;
$$;

SELECT lives_ok(
  $$SELECT check_stuck_processing_settlements()$$,
  'check_stuck_processing_settlements() runs without error'
);

SELECT results_eq(
  $$SELECT status FROM settlement_items WHERE source_id = 'stuck-processing-001'$$,
  $$VALUES ('FAILED'::text)$$,
  'PROCESSING item older than 2h transitions to FAILED'
);

SELECT results_eq(
  $$SELECT failure_reason_code FROM settlement_items WHERE source_id = 'stuck-processing-001'$$,
  $$VALUES ('TIMEOUT_STUCK_PROCESSING'::text)$$,
  'failure_reason_code = TIMEOUT_STUCK_PROCESSING'
);

SELECT * FROM finish();
ROLLBACK;
