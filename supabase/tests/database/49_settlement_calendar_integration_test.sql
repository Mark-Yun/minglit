BEGIN;
SELECT no_plan();

SELECT tests.authenticate_as_service_role();

-- ============================================================
-- 1. assemble_payouts function exists
-- ============================================================
SELECT has_function('public', 'assemble_payouts', 'assemble_payouts function exists');

-- ============================================================
-- 2. assemble_payouts references calculate_scheduled_at
-- ============================================================
SELECT ok(
  (SELECT pg_get_functiondef(oid) FROM pg_proc
   WHERE proname = 'assemble_payouts' AND pronamespace = 'public'::regnamespace::oid)
  LIKE '%calculate_scheduled_at%',
  'assemble_payouts references calculate_scheduled_at'
);

-- ============================================================
-- 3. calculate_scheduled_at returns 15:00 KST for today
-- ============================================================
SELECT is(
  (SELECT extract(hour from (public.calculate_scheduled_at(now()::date) at time zone 'Asia/Seoul'))::int),
  15,
  'calculate_scheduled_at returns 15:00 KST for today'
);

SELECT * FROM finish();
ROLLBACK;
