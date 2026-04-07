BEGIN;
SELECT no_plan();

-- ============================================================
-- 테스트 데이터 세팅 (service_role)
-- ============================================================
SELECT tests.create_supabase_user('rpc_user_a', 'rpc_a@test.com');
SELECT tests.create_supabase_user('rpc_user_b', 'rpc_b@test.com');

SELECT tests.authenticate_as_service_role();

-- 파트너 + 로케이션 + 파티
WITH p AS (
  INSERT INTO public.partners (name, introduction)
  VALUES ('RPC Test Partner', 'for RPC test')
  RETURNING id
)
SELECT set_config('tests.rpc_partner_id', id::text, true) FROM p;

WITH loc AS (
  INSERT INTO public.locations (partner_id, name, address)
  VALUES (current_setting('tests.rpc_partner_id')::uuid, 'RPC Venue', 'Seoul')
  RETURNING id
)
SELECT set_config('tests.rpc_loc_id', id::text, true) FROM loc;

WITH party AS (
  INSERT INTO public.parties (partner_id, location_id, title, description)
  VALUES (
    current_setting('tests.rpc_partner_id')::uuid,
    current_setting('tests.rpc_loc_id')::uuid,
    'RPC Test Party', '"Test"'::jsonb
  )
  RETURNING id
)
SELECT set_config('tests.rpc_party_id', id::text, true) FROM party;

-- 미래 이벤트 (scheduled) — 태그별 파티 조회 대상
WITH evt AS (
  INSERT INTO public.events (party_id, title, status, start_time, end_time)
  VALUES (
    current_setting('tests.rpc_party_id')::uuid,
    'Future Event',
    'scheduled',
    now() + interval '1 day',
    now() + interval '2 days'
  )
  RETURNING id
)
SELECT set_config('tests.rpc_event_id', id::text, true) FROM evt;

-- 과거 이벤트 (scheduled, start_time이 과거) — 태그별 조회에서 제외되어야 함
INSERT INTO public.events (party_id, title, status, start_time, end_time)
VALUES (
  current_setting('tests.rpc_party_id')::uuid,
  'Past Event',
  'scheduled',
  now() - interval '2 days',
  now() - interval '1 day'
);

-- 취소된 이벤트 (cancelled) — 태그별 조회에서 제외되어야 함
INSERT INTO public.events (party_id, title, status, start_time, end_time)
VALUES (
  current_setting('tests.rpc_party_id')::uuid,
  'Cancelled Event',
  'cancelled',
  now() + interval '3 days',
  now() + interval '4 days'
);

-- 태그 생성 (featured + non-featured)
WITH t1 AS (
  INSERT INTO public.tags (name, is_featured, usage_count)
  VALUES ('rpc_featured_tag', true, 10)
  RETURNING id
)
SELECT set_config('tests.rpc_featured_tag_id', id::text, true) FROM t1;

WITH t2 AS (
  INSERT INTO public.tags (name, is_featured, usage_count)
  VALUES ('rpc_nonfeatured_tag', false, 5)
  RETURNING id
)
SELECT set_config('tests.rpc_nonfeatured_tag_id', id::text, true) FROM t2;

WITH t3 AS (
  INSERT INTO public.tags (name, is_featured, usage_count)
  VALUES ('소개팅rpc', true, 20)
  RETURNING id
)
SELECT set_config('tests.rpc_tag3_id', id::text, true) FROM t3;

-- party_tags 연결 (featured_tag → rpc_party)
INSERT INTO public.party_tags (party_id, tag_id)
VALUES (
  current_setting('tests.rpc_party_id')::uuid,
  current_setting('tests.rpc_featured_tag_id')::uuid
);

-- tag_usage_daily 직접 삽입 (트렌딩 테스트용)
-- ON CONFLICT 사용: party_tags INSERT 트리거가 이미 (rpc_featured_tag_id, CURRENT_DATE) 레코드를 생성하므로
-- 원하는 테스트 값으로 upsert한다.
INSERT INTO public.tag_usage_daily (tag_id, date, daily_count)
VALUES
  (current_setting('tests.rpc_featured_tag_id')::uuid, CURRENT_DATE, 50),
  (current_setting('tests.rpc_featured_tag_id')::uuid, CURRENT_DATE - 1, 30),
  (current_setting('tests.rpc_nonfeatured_tag_id')::uuid, CURRENT_DATE, 100)
ON CONFLICT (tag_id, date) DO UPDATE SET daily_count = EXCLUDED.daily_count;

-- rpc_user_a의 관심 태그 설정
INSERT INTO public.user_interest_tags (user_id, tag_id)
VALUES (tests.get_supabase_uid('rpc_user_a'), current_setting('tests.rpc_featured_tag_id')::uuid);

-- search_tags LIMIT 10 검증용: '소' prefix 태그 9개 추가
-- 기존: '소개팅'(시드), '소규모'(시드), '소개팅rpc'(위) = 3개
-- 추가 9개 → 총 12개로 LIMIT 10 회귀 감지 가능
INSERT INTO public.tags (name, is_featured)
VALUES
  ('소셜', true), ('소풍', false), ('소그룹', false),
  ('소통', false), ('소모임', false), ('소연', false),
  ('소확행', false), ('소주', false), ('소비자', false);

-- ============================================================
-- 1. get_featured_tags() — is_featured = true 태그만 반환
-- ============================================================

-- anon도 호출 가능
SELECT tests.clear_authentication();

SELECT results_eq(
  $$SELECT count(*)::int FROM get_featured_tags()$$,
  -- 시드 데이터 25개 + 테스트에서 추가한 featured 2개 (rpc_featured_tag, 소개팅rpc)
  -- 단, 시드 데이터의 '소개팅'과 다른 태그. 총 27개
  (SELECT (count(*)::int)::text || '::int' FROM tags WHERE is_featured = true)::text,
  'get_featured_tags returns all featured tags'
);

-- is_featured = false 태그는 포함되지 않음
SELECT results_eq(
  $$
    SELECT count(*)::int FROM get_featured_tags()
    WHERE name = 'rpc_nonfeatured_tag'
  $$,
  $$VALUES (0)$$,
  'get_featured_tags excludes non-featured tags'
);

-- usage_count 내림차순 정렬 확인: 소개팅rpc(20)이 rpc_featured_tag(10)보다 먼저 나와야 함
-- 외부 ORDER BY 없이 함수 출력 순서 자체를 직접 검증하여 내부 정렬 회귀를 잡음
SELECT results_eq(
  $$
    SELECT name
    FROM (
      SELECT name, row_number() OVER () AS rn
      FROM get_featured_tags()
      WHERE name IN ('rpc_featured_tag', '소개팅rpc')
    ) sub
    ORDER BY rn
  $$,
  $$VALUES ('소개팅rpc'), ('rpc_featured_tag')$$,
  'get_featured_tags ordered by usage_count DESC: 소개팅rpc(20) before rpc_featured_tag(10)'
);

-- ============================================================
-- 2. get_trending_tags(p_limit, p_days) — 최근 N일 트렌딩
-- ============================================================
SELECT tests.clear_authentication();

-- rpc_nonfeatured_tag가 recent_count=100으로 1위여야 함
SELECT results_eq(
  $$
    SELECT name FROM get_trending_tags(1, 7)
  $$,
  $$VALUES ('rpc_nonfeatured_tag')$$,
  'get_trending_tags top-1 is rpc_nonfeatured_tag (daily_count=100)'
);

-- p_limit=2이면 2개 반환
SELECT results_eq(
  $$SELECT count(*)::int FROM get_trending_tags(2, 7)$$,
  $$VALUES (2)$$,
  'get_trending_tags respects p_limit'
);

-- p_days=0이면 오늘 이전 날짜가 없으므로 daily_count가 0인 태그가 상단 X (어제 데이터 제외)
-- p_days=1이면 CURRENT_DATE만 포함 (오늘만)
SELECT results_eq(
  $$
    SELECT (recent_count > 0)::bool FROM get_trending_tags(1, 1)
    LIMIT 1
  $$,
  $$VALUES (true)$$,
  'get_trending_tags p_days=1 includes today data'
);

-- ============================================================
-- 3. get_parties_by_tag(p_tag_id, p_limit, p_offset)
--    활성 이벤트 (scheduled + start_time > now()) 만 반환
-- ============================================================
SELECT tests.clear_authentication();

SELECT results_eq(
  format(
    $$
      SELECT count(*)::int FROM get_parties_by_tag('%s'::uuid, 10, 0)
    $$,
    current_setting('tests.rpc_featured_tag_id')
  ),
  $$VALUES (1)$$,
  'get_parties_by_tag returns only future scheduled events'
);

SELECT results_eq(
  format(
    $$
      SELECT id::text FROM get_parties_by_tag('%s'::uuid, 10, 0)
    $$,
    current_setting('tests.rpc_featured_tag_id')
  ),
  format(
    $$VALUES ('%s')$$,
    current_setting('tests.rpc_event_id')
  ),
  'get_parties_by_tag returns the correct future event'
);

-- p_offset이 결과를 건너뜀 확인
SELECT results_eq(
  format(
    $$
      SELECT count(*)::int FROM get_parties_by_tag('%s'::uuid, 10, 1)
    $$,
    current_setting('tests.rpc_featured_tag_id')
  ),
  $$VALUES (0)$$,
  'get_parties_by_tag respects p_offset'
);

-- ============================================================
-- 4. get_tag_recommendations(p_limit) — 관심 태그 기반 추천
-- ============================================================

-- rpc_user_a는 rpc_featured_tag에 관심이 있고 해당 태그가 rpc_party에 연결되어 있음
SELECT tests.authenticate_as('rpc_user_a');

SELECT results_eq(
  $$SELECT count(*)::int FROM get_tag_recommendations(10)$$,
  $$VALUES (1)$$,
  'get_tag_recommendations returns matched event for rpc_user_a'
);

SELECT results_eq(
  $$
    SELECT id::text FROM get_tag_recommendations(10)
  $$,
  format(
    $$VALUES ('%s')$$,
    current_setting('tests.rpc_event_id')
  ),
  'get_tag_recommendations returns correct event id'
);

-- 관심 태그 없는 user_b는 빈 결과
SELECT tests.authenticate_as('rpc_user_b');

SELECT results_eq(
  $$SELECT count(*)::int FROM get_tag_recommendations(10)$$,
  $$VALUES (0)$$,
  'get_tag_recommendations returns empty for user with no interest tags'
);

-- ============================================================
-- 5. search_tags(p_query) — PGroonga prefix match
-- ============================================================
SELECT tests.clear_authentication();

-- 'rpc' prefix로 rpc_featured_tag, rpc_nonfeatured_tag 조회
SELECT results_eq(
  $$SELECT count(*)::int FROM search_tags('rpc')$$,
  $$VALUES (2)$$,
  'search_tags finds 2 tags with prefix "rpc"'
);

-- 존재하지 않는 prefix는 0건
SELECT results_eq(
  $$SELECT count(*)::int FROM search_tags('zzz_no_match')$$,
  $$VALUES (0)$$,
  'search_tags returns 0 for non-matching prefix'
);

-- LIMIT 10 적용 확인: '소' prefix 태그가 12개(시드 2 + 소개팅rpc 1 + 위 9개 추가) → 정확히 10개 반환
SELECT results_eq(
  $$SELECT count(*)::int FROM search_tags('소')$$,
  $$VALUES (10)$$,
  'search_tags respects LIMIT 10: returns exactly 10 when 12 matching tags exist'
);

-- ============================================================
-- 6. upsert_user_interest_tags(p_tag_ids) — 관심 태그 교체
-- ============================================================
SELECT tests.authenticate_as('rpc_user_b');

-- 초기: user_b 관심 태그 없음
SELECT results_eq(
  format(
    $$SELECT count(*)::int FROM user_interest_tags WHERE user_id = '%s'$$,
    tests.get_supabase_uid('rpc_user_b')
  ),
  $$VALUES (0)$$,
  'rpc_user_b has no interest tags initially'
);

-- 3개 태그 등록
SELECT lives_ok(
  format(
    $$
      SELECT upsert_user_interest_tags(ARRAY['%s','%s','%s']::uuid[])
    $$,
    current_setting('tests.rpc_featured_tag_id'),
    current_setting('tests.rpc_nonfeatured_tag_id'),
    current_setting('tests.rpc_tag3_id')
  ),
  'upsert_user_interest_tags with 3 tags succeeds'
);

SELECT results_eq(
  format(
    $$SELECT count(*)::int FROM user_interest_tags WHERE user_id = '%s'$$,
    tests.get_supabase_uid('rpc_user_b')
  ),
  $$VALUES (3)$$,
  'user_b now has 3 interest tags'
);

-- 태그를 1개로 교체
SELECT lives_ok(
  format(
    $$SELECT upsert_user_interest_tags(ARRAY['%s']::uuid[])$$,
    current_setting('tests.rpc_featured_tag_id')
  ),
  'upsert_user_interest_tags replace with 1 tag succeeds'
);

SELECT results_eq(
  format(
    $$SELECT count(*)::int FROM user_interest_tags WHERE user_id = '%s'$$,
    tests.get_supabase_uid('rpc_user_b')
  ),
  $$VALUES (1)$$,
  'user_b now has 1 interest tag after upsert'
);

-- 빈 배열로 전체 제거
SELECT lives_ok(
  $$SELECT upsert_user_interest_tags(ARRAY[]::uuid[])$$,
  'upsert_user_interest_tags with empty array succeeds'
);

SELECT results_eq(
  format(
    $$SELECT count(*)::int FROM user_interest_tags WHERE user_id = '%s'$$,
    tests.get_supabase_uid('rpc_user_b')
  ),
  $$VALUES (0)$$,
  'user_b has 0 interest tags after empty upsert'
);

-- 6개 태그는 에러
SAVEPOINT before_6_tags;
SELECT throws_ok(
  format(
    $$
      SELECT upsert_user_interest_tags(
        ARRAY['%s','%s','%s',
          gen_random_uuid(),gen_random_uuid(),gen_random_uuid()
        ]::uuid[]
      )
    $$,
    current_setting('tests.rpc_featured_tag_id'),
    current_setting('tests.rpc_nonfeatured_tag_id'),
    current_setting('tests.rpc_tag3_id')
  ),
  'P0001',
  'A user can have at most 5 interest tags',
  'upsert_user_interest_tags rejects more than 5 tags'
);
ROLLBACK TO SAVEPOINT before_6_tags;

SELECT * FROM finish();
ROLLBACK;
