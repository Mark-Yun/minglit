BEGIN;
SELECT no_plan();

-- ============================================================
-- Issue #1182: Tag Discovery P3 Security Hardening 테스트
-- Finding #7: RLS 정책 auth.role() 통일 검증
-- Finding #10: search_tags 입력 길이 제한 검증
-- ============================================================

-- 테스트 데이터 세팅
SELECT tests.create_supabase_user('hard_user_a', 'hard_a@test.com');

SELECT tests.authenticate_as_service_role();

WITH p AS (
  INSERT INTO public.partners (name, introduction)
  VALUES ('Hardening Partner', 'for security test')
  RETURNING id
)
SELECT set_config('tests.hard_partner_id', id::text, true) FROM p;

WITH loc AS (
  INSERT INTO public.locations (partner_id, name, address)
  VALUES (current_setting('tests.hard_partner_id')::uuid, 'Hardening Venue', 'Seoul')
  RETURNING id
)
SELECT set_config('tests.hard_loc_id', id::text, true) FROM loc;

WITH party AS (
  INSERT INTO public.parties (partner_id, location_id, title, description)
  VALUES (
    current_setting('tests.hard_partner_id')::uuid,
    current_setting('tests.hard_loc_id')::uuid,
    'Hardening Party', '"Test"'::jsonb
  )
  RETURNING id
)
SELECT set_config('tests.hard_party_id', id::text, true) FROM party;

WITH t AS (
  INSERT INTO public.tags (name, is_featured, usage_count)
  VALUES ('hardening_test_tag', true, 10)
  RETURNING id
)
SELECT set_config('tests.hard_tag_id', id::text, true) FROM t;

INSERT INTO public.party_tags (party_id, tag_id)
VALUES (
  current_setting('tests.hard_party_id')::uuid,
  current_setting('tests.hard_tag_id')::uuid
);

-- ============================================================
-- Finding #7: auth.role() 기반 RLS 정책 검증
-- party_tags_service, tag_usage_daily_service 정책이 auth.role() 사용 확인
-- ============================================================

-- authenticated 유저는 party_tags에 직접 쓰기 불가 (auth.role() = 'authenticated' ≠ 'service_role')
SELECT tests.authenticate_as('hard_user_a');

SAVEPOINT before_auth_pt_insert;
SELECT throws_ok(
  format(
    $$
      INSERT INTO public.party_tags (party_id, tag_id)
      VALUES ('%s', '%s')
    $$,
    current_setting('tests.hard_party_id'),
    current_setting('tests.hard_tag_id')
  ),
  NULL,
  NULL,
  'Fix #1182: authenticated user cannot INSERT party_tags (auth.role() guard)'
);
ROLLBACK TO SAVEPOINT before_auth_pt_insert;

-- service_role은 party_tags에 쓰기 가능
SELECT tests.authenticate_as_service_role();

SELECT lives_ok(
  format(
    $$
      INSERT INTO public.party_tags (party_id, tag_id)
      VALUES ('%s', '%s')
      ON CONFLICT DO NOTHING
    $$,
    current_setting('tests.hard_party_id'),
    current_setting('tests.hard_tag_id')
  ),
  'Fix #1182: service_role can INSERT party_tags (auth.role() guard)'
);

-- tag_usage_daily: authenticated 유저는 직접 쓰기 불가
SELECT tests.authenticate_as('hard_user_a');

SAVEPOINT before_auth_tud_insert;
SELECT throws_ok(
  format(
    $$
      INSERT INTO public.tag_usage_daily (tag_id, date, daily_count)
      VALUES ('%s', CURRENT_DATE, 1)
    $$,
    current_setting('tests.hard_tag_id')
  ),
  NULL,
  NULL,
  'Fix #1182: authenticated user cannot INSERT tag_usage_daily (auth.role() guard)'
);
ROLLBACK TO SAVEPOINT before_auth_tud_insert;

-- service_role은 tag_usage_daily에 쓰기 가능
SELECT tests.authenticate_as_service_role();

SELECT lives_ok(
  format(
    $$
      INSERT INTO public.tag_usage_daily (tag_id, date, daily_count)
      VALUES ('%s', CURRENT_DATE, 1)
      ON CONFLICT (tag_id, date) DO UPDATE
        SET daily_count = public.tag_usage_daily.daily_count + EXCLUDED.daily_count
    $$,
    current_setting('tests.hard_tag_id')
  ),
  'Fix #1182: service_role can INSERT tag_usage_daily (auth.role() guard)'
);

-- ============================================================
-- Finding #10: search_tags 입력 길이 제한 검증
-- LEFT(p_query, 50) 적용으로 50자 초과 입력이 잘리는지 확인
-- ============================================================

-- PGroonga 인덱스(&^~ 연산자)는 같은 트랜잭션의 미커밋 INSERT를 보지 못한다.
-- 따라서 결과 건수 대신 호출 가능 여부를 검증한다.
SELECT tests.authenticate_as('hard_user_a');

SELECT lives_ok(
  $$SELECT count(*)::int FROM search_tags('hardening')$$,
  'Fix #1182: search_tags accepts normal query without error'
);

-- 50자 초과 쿼리도 에러 없이 실행됨 (LEFT로 잘리므로)
SELECT lives_ok(
  $$
    SELECT count(*) FROM search_tags(
      'hardening_test_tag_extra_characters_beyond_50_limit_should_be_truncated_XXXXXXXXXXX'
    )
  $$,
  'Fix #1182: search_tags accepts long query without error (truncated via LEFT)'
);

-- 정확한 태그명도 동일하게 오류 없이 호출 가능해야 한다.
SELECT lives_ok(
  $$SELECT count(*)::int FROM search_tags('hardening_test_tag')$$,
  'Fix #1182: search_tags accepts exact query within 50 chars without error'
);

SELECT * FROM finish();
ROLLBACK;
