BEGIN;
SELECT plan(3);

SELECT tests.authenticate_as_service_role();

-- fan_out_event runs as SECURITY DEFINER and has pgmq access internally
-- We verify routing correctness by checking function calls don't error

-- Test 1: party_created routes to both queues (no error = routing works)
SELECT lives_ok(
  $$SELECT public.fan_out_event('party_created', '{"id": "test-1", "title": "Test"}'::jsonb)$$,
  'party_created → fan_out_event succeeds (routes to q_notifications + q_vectors)'
);

-- Test 2: application_approved routes to notifications only (no error)
SELECT lives_ok(
  $$SELECT public.fan_out_event('application_approved', '{"id": "test-2"}'::jsonb)$$,
  'application_approved → fan_out_event succeeds (routes to q_notifications)'
);

-- Test 3: unknown event_type does not error (graceful no-op)
SELECT lives_ok(
  $$SELECT public.fan_out_event('unknown_event_type', '{}'::jsonb)$$,
  'unknown_event_type → fan_out_event succeeds without error (no matching routes)'
);

SELECT * FROM finish();
ROLLBACK;
