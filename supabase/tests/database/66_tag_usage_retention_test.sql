BEGIN;
SELECT no_plan();

-- ============================================================
-- Issue #1180: tag_usage_daily 보유/압축 정책 테스트
-- ============================================================

-- 테스트용 태그 생성 (service_role)
SELECT tests.authenticate_as_service_role();

-- 1. tag_usage_monthly 테이블 존재 확인
SELECT has_table('public', 'tag_usage_monthly', 'tag_usage_monthly table exists');

-- 2. compress_old_tag_usage_daily 함수 존재 확인
SELECT has_function('public', 'compress_old_tag_usage_daily', 'compress function exists');

-- 3. 함수 권한 테스트: anon 호출 불가
SELECT results_eq(
  $$SELECT has_function_privilege('anon', 'public.compress_old_tag_usage_daily()', 'EXECUTE')::text$$,
  $$VALUES ('false')$$,
  'anon cannot execute compress_old_tag_usage_daily'
);

-- 4. 함수 권한 테스트: authenticated 호출 불가
SELECT results_eq(
  $$SELECT has_function_privilege('authenticated', 'public.compress_old_tag_usage_daily()', 'EXECUTE')::text$$,
  $$VALUES ('false')$$,
  'authenticated cannot execute compress_old_tag_usage_daily'
);

-- 5. 압축 함수 동작 테스트
-- 5-a. 테스트 태그 생성
WITH t AS (
  INSERT INTO tags (name, usage_count) VALUES ('retention_test_tag', 10)
  RETURNING id
)
SELECT set_config('tests.ret_tag_id', id::text, true) FROM t;

-- 5-b. 2년 초과 데이터 삽입 (예: 800일 전 ~ 750일 전, 여러 날짜)
DO $$
BEGIN
  FOR i IN 750..760 LOOP
    INSERT INTO tag_usage_daily (tag_id, date, daily_count)
    VALUES (
      current_setting('tests.ret_tag_id')::uuid,
      CURRENT_DATE - (i || ' days')::interval,
      i - 749  -- 1, 2, 3, ..., 11
    );
  END LOOP;
END $$;

-- 5-c. 2년 이내 데이터 삽입 (최근 30일)
INSERT INTO tag_usage_daily (tag_id, date, daily_count)
VALUES (
  current_setting('tests.ret_tag_id')::uuid,
  CURRENT_DATE - interval '30 days',
  100
);

-- 5-d. 압축 함수 실행
SELECT compress_old_tag_usage_daily();

-- 5-e. 검증: 2년 초과 일별 데이터가 삭제됨
SELECT is(
  (SELECT count(*)::integer FROM tag_usage_daily
   WHERE tag_id = current_setting('tests.ret_tag_id')::uuid
     AND date < CURRENT_DATE - interval '2 years'),
  0,
  'old daily data deleted after compression'
);

-- 5-f. 검증: 2년 이내 일별 데이터는 유지됨
SELECT is(
  (SELECT count(*)::integer FROM tag_usage_daily
   WHERE tag_id = current_setting('tests.ret_tag_id')::uuid
     AND date >= CURRENT_DATE - interval '2 years'),
  1,
  'recent daily data preserved after compression'
);

-- 5-g. 검증: 월별 집계가 올바르게 생성됨
SELECT cmp_ok(
  (SELECT count(*)::integer FROM tag_usage_monthly
   WHERE tag_id = current_setting('tests.ret_tag_id')::uuid),
  '>', 0,
  'monthly aggregates created after compression'
);

-- 5-h. 검증: 월별 집계 합계가 원래 일별 합계와 일치
-- 원래 일별 합계: sum(1..11) = 66
SELECT is(
  (SELECT SUM(monthly_count)::integer FROM tag_usage_monthly
   WHERE tag_id = current_setting('tests.ret_tag_id')::uuid),
  66,
  'monthly total matches original daily total (1+2+...+11 = 66)'
);

-- 6. 멱등성 테스트: 두 번 실행해도 결과 동일
SELECT compress_old_tag_usage_daily();

SELECT is(
  (SELECT SUM(monthly_count)::integer FROM tag_usage_monthly
   WHERE tag_id = current_setting('tests.ret_tag_id')::uuid),
  66,
  'idempotent: running compress twice does not double the monthly count'
);

-- 7. RLS 테스트: tag_usage_monthly 읽기 권한
SELECT tests.create_supabase_user('ret_user', 'ret@test.com');
SELECT tests.authenticate_as('ret_user');

SELECT lives_ok(
  $$SELECT count(*) FROM tag_usage_monthly$$,
  'authenticated can read tag_usage_monthly'
);

SELECT * FROM finish();
ROLLBACK;
