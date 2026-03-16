BEGIN;
SELECT no_plan();

SELECT tests.authenticate_as_service_role();

-- ============================================================
-- 1. Table existence
-- ============================================================
SELECT has_table('public', 'business_calendar', 'business_calendar table exists');

-- ============================================================
-- 2. Function existence
-- ============================================================
SELECT has_function('public', 'calculate_scheduled_at', 'calculate_scheduled_at function exists');

-- ============================================================
-- 3. Non-business days count (2026)
-- ============================================================
SELECT ok(
  (SELECT count(*) FROM public.business_calendar WHERE NOT is_business_day AND date BETWEEN '2026-01-01' AND '2026-12-31') >= 115,
  '2026 non-business days: >= 115'
);

-- ============================================================
-- 4. 2026-03-23 is a business day (Monday)
-- ============================================================
SELECT ok(
  (SELECT is_business_day FROM public.business_calendar WHERE date = '2026-03-23'),
  '2026-03-23 Monday is a business day'
);

-- ============================================================
-- 5. 2026-03-21 is NOT a business day (Saturday)
-- ============================================================
SELECT ok(
  NOT (SELECT is_business_day FROM public.business_calendar WHERE date = '2026-03-21'),
  '2026-03-21 Saturday is not a business day'
);

-- ============================================================
-- 6. 2026-01-29 is NOT a business day (설날)
-- ============================================================
SELECT ok(
  NOT (SELECT is_business_day FROM public.business_calendar WHERE date = '2026-01-29'),
  '2026-01-29 설날 is not a business day'
);

-- ============================================================
-- 7. calculate_scheduled_at returns result at 15:00 KST
-- ============================================================
SELECT ok(
  (SELECT extract(hour from (public.calculate_scheduled_at('2026-03-20'::date) at time zone 'Asia/Seoul'))) = 15,
  'calculate_scheduled_at returns result at 15:00 KST'
);

-- ============================================================
-- 8. calculate_scheduled_at for Friday 2026-03-20 → at least Mar 24 (Tue) or later
-- ============================================================
SELECT ok(
  (SELECT (public.calculate_scheduled_at('2026-03-20'::date) at time zone 'Asia/Seoul')::date) >= '2026-03-24'::date,
  'calculate_scheduled_at for 2026-03-20 >= 2026-03-24'
);

-- ============================================================
-- 9. calculate_scheduled_at does not raise with seeded calendar
-- ============================================================
DO $$
BEGIN
  -- This just verifies the function doesn't raise an exception
  PERFORM public.calculate_scheduled_at('2026-03-20'::date);
END$$;
SELECT ok(true, 'calculate_scheduled_at does not raise with seeded calendar');

SELECT * FROM finish();
ROLLBACK;
