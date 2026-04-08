BEGIN;
SELECT no_plan();

-- ============================================================
-- Issue #1190: tag_usage_monthly RLS auth.role() 검증
-- Finding #7: current_setting('role', true) → auth.role() 통일
-- ============================================================

-- 테스트 데이터 세팅
SELECT tests.create_supabase_user('monthly_user_a', 'monthly_a@test.com');

SELECT tests.authenticate_as_service_role();

WITH t AS (
  INSERT INTO public.tags (name, is_featured, usage_count)
  VALUES ('monthly_rls_test_tag', false, 0)
  RETURNING id
)
SELECT set_config('tests.monthly_tag_id', id::text, true) FROM t;

-- ============================================================
-- authenticated 유저는 tag_usage_monthly에 직접 쓰기 불가
-- ============================================================

SELECT tests.authenticate_as('monthly_user_a');

SAVEPOINT before_auth_tum_insert;
SELECT throws_ok(
  format(
    $$
      INSERT INTO public.tag_usage_monthly (tag_id, month, monthly_count)
      VALUES ('%s', '2024-01-01', 100)
    $$,
    current_setting('tests.monthly_tag_id')
  ),
  NULL,
  NULL,
  'Fix #1190: authenticated user cannot INSERT tag_usage_monthly (auth.role() guard)'
);
ROLLBACK TO SAVEPOINT before_auth_tum_insert;

-- ============================================================
-- service_role은 tag_usage_monthly에 쓰기 가능
-- ============================================================

SELECT tests.authenticate_as_service_role();

SELECT lives_ok(
  format(
    $$
      INSERT INTO public.tag_usage_monthly (tag_id, month, monthly_count)
      VALUES ('%s', '2024-01-01', 100)
      ON CONFLICT (tag_id, month) DO NOTHING
    $$,
    current_setting('tests.monthly_tag_id')
  ),
  'Fix #1190: service_role can INSERT tag_usage_monthly (auth.role() guard)'
);

-- ============================================================
-- authenticated 유저는 tag_usage_monthly 읽기 가능
-- ============================================================

SELECT tests.authenticate_as('monthly_user_a');

SELECT lives_ok(
  $$SELECT count(*) FROM public.tag_usage_monthly$$,
  'Fix #1190: authenticated user can SELECT tag_usage_monthly (read policy)'
);

SELECT * FROM finish();
ROLLBACK;
