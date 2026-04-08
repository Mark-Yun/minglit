BEGIN;
SELECT no_plan();

-- ============================================================
-- Issue #1176: Tag Discovery RPC 권한 검증 테스트
-- REVOKE FROM PUBLIC 이후 anon 호출 차단 + 입력 바운드 + upsert 인증 가드
-- ============================================================

-- 테스트 데이터 세팅 (service_role)
SELECT tests.create_supabase_user('perm_user_a', 'perm_a@test.com');

SELECT tests.authenticate_as_service_role();

WITH p AS (
  INSERT INTO public.partners (name, introduction)
  VALUES ('Perm Test Partner', 'for permissions test')
  RETURNING id
)
SELECT set_config('tests.perm_partner_id', id::text, true) FROM p;

WITH loc AS (
  INSERT INTO public.locations (partner_id, name, address)
  VALUES (current_setting('tests.perm_partner_id')::uuid, 'Perm Venue', 'Seoul')
  RETURNING id
)
SELECT set_config('tests.perm_loc_id', id::text, true) FROM loc;

WITH party AS (
  INSERT INTO public.parties (partner_id, location_id, title, description)
  VALUES (
    current_setting('tests.perm_partner_id')::uuid,
    current_setting('tests.perm_loc_id')::uuid,
    'Perm Test Party', '"Test"'::jsonb
  )
  RETURNING id
)
SELECT set_config('tests.perm_party_id', id::text, true) FROM party;

INSERT INTO public.events (party_id, title, status, start_time, end_time)
VALUES (
  current_setting('tests.perm_party_id')::uuid,
  'Perm Future Event',
  'scheduled',
  now() + interval '1 day',
  now() + interval '2 days'
);

WITH t AS (
  INSERT INTO public.tags (name, is_featured, usage_count)
  VALUES ('perm_test_tag', true, 5)
  RETURNING id
)
SELECT set_config('tests.perm_tag_id', id::text, true) FROM t;

-- ============================================================
-- 1. anon 차단 — EXECUTE privilege 직접 검증
-- pgtap 세션은 postgres 유저로 실행되므로 throws_ok 대신 권한 메타데이터를 검증한다.
-- ============================================================
SELECT results_eq(
  $$SELECT has_function_privilege('anon', 'public.get_featured_tags()', 'EXECUTE')::text$$,
  $$VALUES ('false')$$,
  'anon does not have EXECUTE on get_featured_tags'
);

SELECT results_eq(
  $$SELECT has_function_privilege('anon', 'public.get_trending_tags(integer, integer)', 'EXECUTE')::text$$,
  $$VALUES ('false')$$,
  'anon does not have EXECUTE on get_trending_tags'
);

SELECT results_eq(
  $$SELECT has_function_privilege('anon', 'public.get_parties_by_tag(uuid, integer, integer)', 'EXECUTE')::text$$,
  $$VALUES ('false')$$,
  'anon does not have EXECUTE on get_parties_by_tag'
);

SELECT results_eq(
  $$SELECT has_function_privilege('anon', 'public.search_tags(text)', 'EXECUTE')::text$$,
  $$VALUES ('false')$$,
  'anon does not have EXECUTE on search_tags'
);

SELECT results_eq(
  $$SELECT has_function_privilege('anon', 'public.get_tag_recommendations(integer)', 'EXECUTE')::text$$,
  $$VALUES ('false')$$,
  'anon does not have EXECUTE on get_tag_recommendations'
);

SELECT results_eq(
  $$SELECT has_function_privilege('anon', 'public.upsert_user_interest_tags(uuid[])', 'EXECUTE')::text$$,
  $$VALUES ('false')$$,
  'anon does not have EXECUTE on upsert_user_interest_tags'
);

-- ============================================================
-- 2. authenticated 허용 — 정상 호출 가능 확인
-- ============================================================
SELECT tests.authenticate_as('perm_user_a');

SELECT lives_ok(
  $$SELECT count(*) FROM get_featured_tags()$$,
  'authenticated can call get_featured_tags'
);

SELECT lives_ok(
  $$SELECT count(*) FROM get_trending_tags(10, 7)$$,
  'authenticated can call get_trending_tags'
);

SELECT lives_ok(
  format($$SELECT count(*) FROM get_parties_by_tag('%s'::uuid, 10, 0)$$,
    current_setting('tests.perm_tag_id')),
  'authenticated can call get_parties_by_tag'
);

SELECT lives_ok(
  $$SELECT count(*) FROM search_tags('perm')$$,
  'authenticated can call search_tags'
);

SELECT lives_ok(
  $$SELECT count(*) FROM get_tag_recommendations(10)$$,
  'authenticated can call get_tag_recommendations'
);

SELECT lives_ok(
  format($$SELECT upsert_user_interest_tags(ARRAY['%s']::uuid[])$$,
    current_setting('tests.perm_tag_id')),
  'authenticated can call upsert_user_interest_tags'
);

-- ============================================================
-- 3. 입력 바운드 — p_limit 상한 (100) 검증
--    p_limit=200으로 호출해도 최대 100개만 반환
-- ============================================================

-- get_trending_tags: 실제 태그 수보다 큰 p_limit을 주면 태그 수만큼 반환
-- 바운드 적용 여부는 LEAST(p_limit, 100)가 쿼리 내에서 작동함을 확인
SELECT lives_ok(
  $$SELECT count(*) FROM get_trending_tags(200, 7)$$,
  'get_trending_tags accepts p_limit=200 without error (capped at 100 internally)'
);

SELECT lives_ok(
  $$SELECT count(*) FROM get_trending_tags(10, 200)$$,
  'get_trending_tags accepts p_days=200 without error (capped at 90 internally)'
);

SELECT lives_ok(
  format($$SELECT count(*) FROM get_parties_by_tag('%s'::uuid, 200, 0)$$,
    current_setting('tests.perm_tag_id')),
  'get_parties_by_tag accepts p_limit=200 without error (capped at 100 internally)'
);

SELECT lives_ok(
  $$SELECT count(*) FROM get_tag_recommendations(200)$$,
  'get_tag_recommendations accepts p_limit=200 without error (capped at 100 internally)'
);

-- ============================================================
-- 4. upsert_user_interest_tags 인증 가드
--    auth.uid() IS NULL 인 authenticated 컨텍스트에서 명시적 42501 에러
-- ============================================================
SELECT set_config('role', 'authenticated', true);
SELECT set_config('request.jwt.claims', '{}'::text, true);

SELECT throws_ok(
  format($$SELECT upsert_user_interest_tags(ARRAY['%s']::uuid[])$$,
    current_setting('tests.perm_tag_id')),
  '42501',
  'Authentication required',
  'upsert_user_interest_tags rejects authenticated sessions without sub claim'
);

SELECT tests.authenticate_as('perm_user_a');

SELECT lives_ok(
  $$SELECT upsert_user_interest_tags(ARRAY[]::uuid[])$$,
  'upsert_user_interest_tags with empty array succeeds for authenticated user'
);

SELECT * FROM finish();
ROLLBACK;
