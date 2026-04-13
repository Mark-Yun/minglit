-- 80_db_invariant_monitor_test.sql — pgTAP tests for check_db_invariants() (#1427)

BEGIN;
SELECT plan(12);

-- ─────────────────────────────────────────────────────────────────────────────
-- Schema checks
-- ─────────────────────────────────────────────────────────────────────────────

SELECT has_function(
  'public', 'check_db_invariants', ARRAY[]::text[],
  'check_db_invariants() function exists'
);

-- ─────────────────────────────────────────────────────────────────────────────
-- Return value shape
-- ─────────────────────────────────────────────────────────────────────────────

SELECT ok(
  (SELECT (check_db_invariants())::json->>'passed' IS NOT NULL),
  'check_db_invariants() returns JSON with "passed" key'
);

SELECT ok(
  (SELECT (check_db_invariants())::json->>'violations' IS NOT NULL),
  'check_db_invariants() returns JSON with "violations" key'
);

SELECT ok(
  (SELECT (check_db_invariants())::json->>'checked_at' IS NOT NULL),
  'check_db_invariants() returns JSON with "checked_at" key'
);

SELECT ok(
  (SELECT json_typeof((check_db_invariants())::json->'violations') = 'array'),
  'violations is a JSON array'
);

SELECT ok(
  (SELECT json_typeof((check_db_invariants())::json->'passed') = 'boolean'),
  'passed is a JSON boolean'
);

-- ─────────────────────────────────────────────────────────────────────────────
-- INV-05: no paid applications with NULL payment_id in clean DB
-- ─────────────────────────────────────────────────────────────────────────────

SELECT results_eq(
  $$SELECT count(*)::int FROM event_applications WHERE status = 'paid' AND payment_id IS NULL$$,
  $$SELECT 0::int$$,
  'INV-05: no paid applications with NULL payment_id in clean DB'
);

-- ─────────────────────────────────────────────────────────────────────────────
-- INV-07: no self-votes in clean DB
-- ─────────────────────────────────────────────────────────────────────────────

SELECT results_eq(
  $$SELECT count(*)::int FROM match_votes WHERE voter_id = candidate_id$$,
  $$SELECT 0::int$$,
  'INV-07: no self-votes in clean DB'
);

-- ─────────────────────────────────────────────────────────────────────────────
-- pg_cron job existence
-- ─────────────────────────────────────────────────────────────────────────────

SELECT results_eq(
  $$SELECT count(*)::int FROM cron.job WHERE jobname = 'db-invariant-monitor'$$,
  $$SELECT 1::int$$,
  'pg_cron job db-invariant-monitor is scheduled'
);

SELECT results_eq(
  $$SELECT schedule FROM cron.job WHERE jobname = 'db-invariant-monitor'$$,
  $$VALUES ('0 * * * *')$$,
  'pg_cron job runs hourly'
);

-- ─────────────────────────────────────────────────────────────────────────────
-- INV-06: no current_participants counter drift in clean DB
-- ─────────────────────────────────────────────────────────────────────────────

SELECT ok(
  (SELECT count(*) = 0 FROM (
    SELECT e.id
    FROM events e
    LEFT JOIN event_participants p ON e.id = p.event_id
    GROUP BY e.id, e.current_participants
    HAVING e.current_participants != count(p.id)
  ) sub),
  'INV-06: no current_participants counter drift in clean DB'
);

-- ─────────────────────────────────────────────────────────────────────────────
-- INV-04 regression: completed event WITH settlement_items(source_type='EVENT')
-- must NOT trigger INV-04 violation.
-- Pins the fix: INV-04 check uses source_type = 'EVENT' (uppercase), not 'event'.
-- ─────────────────────────────────────────────────────────────────────────────

DO $$
DECLARE
  v_partner_id uuid := gen_random_uuid();
  v_party_id   uuid := gen_random_uuid();
  v_event_id   uuid := gen_random_uuid();
  v_checksum   char(64);
BEGIN
  -- Minimal partner
  INSERT INTO public.partners (id, name)
  VALUES (v_partner_id, 'Test Partner INV04');

  -- Minimal party owned by the partner
  INSERT INTO public.parties (id, partner_id, title, status)
  VALUES (v_party_id, v_partner_id, 'Test Party INV04', 'active');

  -- Completed event
  INSERT INTO public.events (id, party_id, title, start_time, end_time, status)
  VALUES (v_event_id, v_party_id, 'Test Event INV04',
          now() - interval '2 hours', now() - interval '1 hour',
          'completed');

  -- Compute a valid checksum for the settlement_items row
  v_checksum := public.calculate_settlement_checksum(
    v_partner_id,
    (now() - interval '1 hour')::date,
    (now() - interval '1 hour')::date,
    'KRW',
    0::bigint,   -- gross_amount
    5.00::decimal(5,2),
    3.50::decimal(5,2),
    10.00::decimal(5,2),
    0::bigint,   -- platform_fee_amount
    0::bigint,   -- pg_fee_amount
    0::bigint,   -- vat_amount
    0::bigint    -- net_amount
  );

  -- Settlement item with source_type = 'EVENT' (uppercase — the regression fix)
  INSERT INTO public.settlement_items (
    partner_id,
    settlement_period_start,
    settlement_period_end,
    currency,
    source_type,
    source_id,
    status,
    gross_amount,
    platform_fee_rate,
    platform_fee_amount,
    pg_fee_rate,
    pg_fee_amount,
    vat_rate,
    vat_amount,
    net_amount,
    calc_checksum
  ) VALUES (
    v_partner_id,
    (now() - interval '1 hour')::date,
    (now() - interval '1 hour')::date,
    'KRW',
    'EVENT',
    v_event_id::text,
    'PENDING',
    0, 5.00, 0, 3.50, 0, 10.00, 0, 0,
    v_checksum
  );
END;
$$;

SELECT ok(
  NOT EXISTS (
    SELECT 1
    FROM json_array_elements(
      (check_db_invariants())::json->'violations'
    ) v
    WHERE v->>'id' = 'INV-04'
  ),
  'INV-04: completed event with settlement_items(source_type=''EVENT'') does not trigger INV-04'
);

SELECT * FROM finish();
ROLLBACK;
