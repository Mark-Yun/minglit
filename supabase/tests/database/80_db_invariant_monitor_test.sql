-- 80_db_invariant_monitor_test.sql — pgTAP tests for check_db_invariants() (#1427)

BEGIN;
SELECT plan(10);

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

SELECT * FROM finish();
ROLLBACK;
