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
--
--    시드 데이터: 101개 태그, 101개 이벤트 생성으로 실제 캡핑 검증
--    (LEAST() 제거 회귀 시 count > 100이 되어 즉시 실패)
-- ============================================================

-- 시드 데이터 생성 (service_role 권한 필요)
SELECT tests.authenticate_as_service_role();

-- 3-a. 101개 태그 생성 + tag_usage_daily에 최근 7일 데이터 삽입
--      get_trending_tags(200, 7): LEAST(200, 100) = 100 캡핑 검증용
DO $$
DECLARE
  v_tag_id uuid;
  i int;
BEGIN
  FOR i IN 1..101 LOOP
    INSERT INTO public.tags (name, is_featured, usage_count)
    VALUES ('bound_tag_' || i, false, i)
    RETURNING id INTO v_tag_id;

    -- 최근 7일 이내 데이터: get_trending_tags(200, 7) 집계에 포함
    INSERT INTO public.tag_usage_daily (tag_id, date, daily_count)
    VALUES (v_tag_id, CURRENT_DATE, i);
  END LOOP;
END;
$$;

-- 3-b. 101개 (파티 + 이벤트 + party_tag) 생성
--      get_parties_by_tag(..., 200, 0): LEAST(200, 100) = 100 캡핑 검증용
--      get_tag_recommendations(200): LEAST(200, 100) = 100 캡핑 검증용
DO $$
DECLARE
  v_party_id uuid;
  v_event_id uuid;
  i int;
BEGIN
  FOR i IN 1..101 LOOP
    INSERT INTO public.parties (partner_id, location_id, title, description)
    VALUES (
      current_setting('tests.perm_partner_id')::uuid,
      current_setting('tests.perm_loc_id')::uuid,
      'Bound Test Party ' || i,
      ('"Test ' || i || '"')::jsonb
    )
    RETURNING id INTO v_party_id;

    INSERT INTO public.events (party_id, title, status, start_time, end_time)
    VALUES (
      v_party_id,
      'Bound Test Event ' || i,
      'scheduled',
      now() + interval '1 day' + (i || ' hours')::interval,
      now() + interval '2 days' + (i || ' hours')::interval
    );

    -- perm_tag_id에 연결: get_parties_by_tag(perm_tag_id, 200, 0) 결과 100개 캡핑 검증
    INSERT INTO public.party_tags (party_id, tag_id)
    VALUES (v_party_id, current_setting('tests.perm_tag_id')::uuid);
  END LOOP;
END;
$$;

-- 3-c. perm_user_a의 관심 태그 설정 (get_tag_recommendations용)
--      user_interest_tags 한도(5개)가 있으므로 perm_tag_id 1개만 등록
--      이미 섹션 2에서 upsert 성공 확인 완료이므로 직접 insert
INSERT INTO public.user_interest_tags (user_id, tag_id)
VALUES (
  (SELECT id FROM auth.users WHERE email = 'perm_a@test.com'),
  current_setting('tests.perm_tag_id')::uuid
)
ON CONFLICT DO NOTHING;

-- 3-d. 91일 전 tag_usage_daily 데이터: p_days=200 → LEAST(200,90)=90 캡핑 검증용
--      90일 이내 데이터만 집계되어야 하므로 91일 전 데이터는 결과에 미포함되어야 함
INSERT INTO public.tag_usage_daily (tag_id, date, daily_count)
VALUES (current_setting('tests.perm_tag_id')::uuid, CURRENT_DATE - 91, 9999)
ON CONFLICT (tag_id, date) DO UPDATE SET daily_count = 9999;

SELECT tests.authenticate_as('perm_user_a');

-- get_trending_tags: p_limit=200이어도 최대 100개만 반환
SELECT cmp_ok(
  (SELECT count(*)::integer FROM get_trending_tags(200, 7)),
  '<=', 100,
  'get_trending_tags caps result at 100 even when p_limit=200'
);

-- get_trending_tags: p_days=200 캡핑 확인
--   91일 전 데이터(daily_count=9999)가 집계에서 제외되는지 검증
--   perm_tag_id의 recent_count가 9999가 아님을 확인 (90일 캡핑이 올바르게 동작)
SELECT cmp_ok(
  (SELECT recent_count::integer
   FROM get_trending_tags(10, 200)
   WHERE id = current_setting('tests.perm_tag_id')::uuid),
  '<', 9999,
  'get_trending_tags with p_days=200 excludes data older than 90 days (capped at 90)'
);

-- get_parties_by_tag: p_limit=200이어도 최대 100개만 반환
SELECT cmp_ok(
  (SELECT count(*)::integer
   FROM get_parties_by_tag(current_setting('tests.perm_tag_id')::uuid, 200, 0)),
  '<=', 100,
  'get_parties_by_tag caps result at 100 even when p_limit=200'
);

-- get_tag_recommendations: p_limit=200이어도 최대 100개만 반환
SELECT cmp_ok(
  (SELECT count(*)::integer FROM get_tag_recommendations(200)),
  '<=', 100,
  'get_tag_recommendations caps result at 100 even when p_limit=200'
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
