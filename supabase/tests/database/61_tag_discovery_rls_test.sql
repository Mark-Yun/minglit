BEGIN;
SELECT no_plan();

-- ============================================================
-- 테스트 데이터 세팅 (service_role)
-- user_a: 파트너 A 멤버 (party_a 소유)
-- user_b: 파트너 없음 (일반 유저)
-- admin_user: super_admin (app_roles에 등록)
-- ============================================================
SELECT tests.create_supabase_user('td_user_a', 'td_a@test.com');
SELECT tests.create_supabase_user('td_user_b', 'td_b@test.com');
SELECT tests.create_supabase_user('td_admin', 'td_admin@test.com');

SELECT tests.authenticate_as_service_role();

-- super_admin 등록
INSERT INTO public.app_roles (user_id, role)
VALUES (tests.get_supabase_uid('td_admin'), 'super_admin');

-- 파트너 + 로케이션 + 파티
WITH p AS (
  INSERT INTO public.partners (name, introduction)
  VALUES ('TD Partner A', 'for RLS test')
  RETURNING id
)
SELECT set_config('tests.td_partner_a_id', id::text, true) FROM p;

INSERT INTO public.partner_member_permissions (partner_id, user_id, role)
VALUES (
  current_setting('tests.td_partner_a_id')::uuid,
  tests.get_supabase_uid('td_user_a'),
  'owner'
);

WITH loc AS (
  INSERT INTO public.locations (partner_id, name, address)
  VALUES (current_setting('tests.td_partner_a_id')::uuid, 'Venue A', 'Seoul')
  RETURNING id
)
SELECT set_config('tests.td_loc_a_id', id::text, true) FROM loc;

WITH party AS (
  INSERT INTO public.parties (partner_id, location_id, title, description)
  VALUES (
    current_setting('tests.td_partner_a_id')::uuid,
    current_setting('tests.td_loc_a_id')::uuid,
    'TD Party A', '"Test"'::jsonb
  )
  RETURNING id
)
SELECT set_config('tests.td_party_a_id', id::text, true) FROM party;

-- 태그 생성 (service_role)
WITH t AS (
  INSERT INTO public.tags (name, is_featured)
  VALUES ('td_tag_test', true)
  RETURNING id
)
SELECT set_config('tests.td_tag_id', id::text, true) FROM t;

-- party_tags 삽입 (service_role)
INSERT INTO public.party_tags (party_id, tag_id)
VALUES (
  current_setting('tests.td_party_a_id')::uuid,
  current_setting('tests.td_tag_id')::uuid
);

-- ============================================================
-- 1. tags — anon: 읽기 가능, 쓰기 불가
-- ============================================================
SELECT tests.clear_authentication();

SELECT isnt_empty(
  $$SELECT * FROM public.tags$$,
  'anon can SELECT tags'
);

SAVEPOINT before_anon_tag_insert;
SELECT throws_ok(
  $$INSERT INTO public.tags (name) VALUES ('anon_tag')$$,
  NULL,
  NULL,
  'anon cannot INSERT tags'
);
ROLLBACK TO SAVEPOINT before_anon_tag_insert;

-- ============================================================
-- 2. tags — authenticated user (non-admin): 읽기 가능, 쓰기 불가
-- ============================================================
SELECT tests.authenticate_as('td_user_b');

SELECT isnt_empty(
  $$SELECT * FROM public.tags$$,
  'authenticated user can SELECT tags'
);

SAVEPOINT before_user_tag_insert;
SELECT throws_ok(
  $$INSERT INTO public.tags (name) VALUES ('user_tag')$$,
  NULL,
  NULL,
  'non-admin user cannot INSERT tags'
);
ROLLBACK TO SAVEPOINT before_user_tag_insert;

SAVEPOINT before_user_tag_update;
SELECT throws_ok(
  format(
    $$UPDATE public.tags SET is_featured = false WHERE id = '%s'$$,
    current_setting('tests.td_tag_id')
  ),
  NULL,
  NULL,
  'non-admin user cannot UPDATE tags'
);
ROLLBACK TO SAVEPOINT before_user_tag_update;

SAVEPOINT before_user_tag_delete;
SELECT throws_ok(
  format(
    $$DELETE FROM public.tags WHERE id = '%s'$$,
    current_setting('tests.td_tag_id')
  ),
  NULL,
  NULL,
  'non-admin user cannot DELETE tags'
);
ROLLBACK TO SAVEPOINT before_user_tag_delete;

-- ============================================================
-- 3. tags — super_admin: 읽기 + 쓰기 가능
-- ============================================================
SELECT tests.authenticate_as('td_admin');

SELECT lives_ok(
  $$INSERT INTO public.tags (name) VALUES ('admin_created_tag')$$,
  'super_admin can INSERT tags'
);

SELECT lives_ok(
  format(
    $$UPDATE public.tags SET is_featured = false WHERE id = '%s'$$,
    current_setting('tests.td_tag_id')
  ),
  'super_admin can UPDATE tags'
);

-- ============================================================
-- 4. party_tags — anon: 읽기 가능
-- ============================================================
SELECT tests.clear_authentication();

SELECT isnt_empty(
  $$SELECT * FROM public.party_tags$$,
  'anon can SELECT party_tags'
);

-- ============================================================
-- 5. party_tags — authenticated: 읽기 가능, 직접 쓰기 불가 (EF only)
-- ============================================================
SELECT tests.authenticate_as('td_user_a');

SELECT isnt_empty(
  $$SELECT * FROM public.party_tags$$,
  'authenticated user can SELECT party_tags'
);

SAVEPOINT before_user_pt_insert;
SELECT throws_ok(
  format(
    $$
      INSERT INTO public.party_tags (party_id, tag_id)
      SELECT '%s', id FROM public.tags WHERE name = 'admin_created_tag'
    $$,
    current_setting('tests.td_party_a_id')
  ),
  NULL,
  NULL,
  'authenticated user cannot directly INSERT party_tags (EF only)'
);
ROLLBACK TO SAVEPOINT before_user_pt_insert;

-- ============================================================
-- 6. party_tags — service_role: 쓰기 가능
-- ============================================================
SELECT tests.authenticate_as_service_role();

SELECT lives_ok(
  format(
    $$
      INSERT INTO public.party_tags (party_id, tag_id)
      SELECT '%s', id FROM public.tags WHERE name = 'admin_created_tag'
    $$,
    current_setting('tests.td_party_a_id')
  ),
  'service_role can INSERT party_tags'
);

-- ============================================================
-- 7. user_interest_tags — 본인만 읽기/쓰기 가능
-- ============================================================
SELECT tests.authenticate_as('td_user_a');

SELECT lives_ok(
  format(
    $$
      INSERT INTO public.user_interest_tags (user_id, tag_id)
      VALUES ('%s', '%s')
    $$,
    tests.get_supabase_uid('td_user_a'),
    current_setting('tests.td_tag_id')
  ),
  'user_a can INSERT own user_interest_tags'
);

SELECT results_eq(
  format(
    $$SELECT count(*)::int FROM public.user_interest_tags WHERE user_id = '%s'$$,
    tests.get_supabase_uid('td_user_a')
  ),
  $$VALUES (1)$$,
  'user_a can SELECT own user_interest_tags'
);

-- user_b는 user_a의 관심 태그 못 읽음
SELECT tests.authenticate_as('td_user_b');

SELECT results_eq(
  $$SELECT count(*)::int FROM public.user_interest_tags$$,
  $$VALUES (0)$$,
  'user_b cannot see user_a interest tags'
);

SAVEPOINT before_b_insert_other;
SELECT throws_ok(
  format(
    $$
      INSERT INTO public.user_interest_tags (user_id, tag_id)
      VALUES ('%s', '%s')
    $$,
    tests.get_supabase_uid('td_user_a'),
    current_setting('tests.td_tag_id')
  ),
  NULL,
  NULL,
  'user_b cannot INSERT interest tags for user_a'
);
ROLLBACK TO SAVEPOINT before_b_insert_other;

-- user_b는 자신의 관심 태그 INSERT 가능
SELECT lives_ok(
  format(
    $$
      INSERT INTO public.user_interest_tags (user_id, tag_id)
      VALUES ('%s', '%s')
    $$,
    tests.get_supabase_uid('td_user_b'),
    current_setting('tests.td_tag_id')
  ),
  'user_b can INSERT own user_interest_tags'
);

-- ============================================================
-- 8. tag_usage_daily — anon: 읽기 가능, 직접 쓰기 불가
-- ============================================================
SELECT tests.clear_authentication();

SELECT isnt_empty(
  $$SELECT * FROM public.tag_usage_daily$$,
  'anon can SELECT tag_usage_daily (populated by trigger)'
);

SAVEPOINT before_anon_tud_insert;
SELECT throws_ok(
  format(
    $$
      INSERT INTO public.tag_usage_daily (tag_id, date, daily_count)
      VALUES ('%s', CURRENT_DATE, 99)
    $$,
    current_setting('tests.td_tag_id')
  ),
  NULL,
  NULL,
  'anon cannot directly INSERT tag_usage_daily'
);
ROLLBACK TO SAVEPOINT before_anon_tud_insert;

-- ============================================================
-- 9. service_role: 전체 테이블 접근 가능
-- ============================================================
SELECT tests.authenticate_as_service_role();

SELECT results_eq(
  $$SELECT count(*)::int > 0 FROM public.tags$$,
  $$VALUES (true)$$,
  'service_role can read tags'
);

SELECT results_eq(
  $$SELECT count(*)::int > 0 FROM public.party_tags$$,
  $$VALUES (true)$$,
  'service_role can read party_tags'
);

SELECT * FROM finish();
ROLLBACK;
