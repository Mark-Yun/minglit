BEGIN;
SELECT no_plan();

-- ============================================================
-- 테스트 데이터 세팅 (service_role)
-- 파트너 A: user_a가 owner, user_b는 권한 없음
-- 파트너 B: user_c가 owner (다른 파트너)
-- ============================================================
SELECT tests.create_supabase_user('rr_user_a', 'rr_a@test.com');
SELECT tests.create_supabase_user('rr_user_b', 'rr_b@test.com');
SELECT tests.create_supabase_user('rr_user_c', 'rr_c@test.com');

SELECT tests.authenticate_as_service_role();

-- Partner A
WITH p AS (
  INSERT INTO public.partners (name, introduction)
  VALUES ('Partner A (RLS)', 'for RLS test')
  RETURNING id
)
SELECT set_config('tests.rr_partner_a_id', id::text, true) FROM p;

INSERT INTO public.partner_member_permissions (partner_id, user_id, role)
VALUES (
  current_setting('tests.rr_partner_a_id')::uuid,
  tests.get_supabase_uid('rr_user_a'),
  'owner'
);

-- Location for Partner A
WITH loc AS (
  INSERT INTO public.locations (partner_id, name, address)
  VALUES (
    current_setting('tests.rr_partner_a_id')::uuid,
    'Venue A',
    'Seoul'
  )
  RETURNING id
)
SELECT set_config('tests.rr_loc_a_id', id::text, true) FROM loc;

-- Party for Partner A
WITH party AS (
  INSERT INTO public.parties (
    partner_id, location_id, title, description
  ) VALUES (
    current_setting('tests.rr_partner_a_id')::uuid,
    current_setting('tests.rr_loc_a_id')::uuid,
    'Party A',
    '"Test"'::jsonb
  )
  RETURNING id
)
SELECT set_config('tests.rr_party_a_id', id::text, true) FROM party;

-- Partner B
WITH p AS (
  INSERT INTO public.partners (name, introduction)
  VALUES ('Partner B (RLS)', 'for RLS test')
  RETURNING id
)
SELECT set_config('tests.rr_partner_b_id', id::text, true) FROM p;

INSERT INTO public.partner_member_permissions (partner_id, user_id, role)
VALUES (
  current_setting('tests.rr_partner_b_id')::uuid,
  tests.get_supabase_uid('rr_user_c'),
  'owner'
);

-- Location for Partner B
WITH loc AS (
  INSERT INTO public.locations (partner_id, name, address)
  VALUES (
    current_setting('tests.rr_partner_b_id')::uuid,
    'Venue B',
    'Busan'
  )
  RETURNING id
)
SELECT set_config('tests.rr_loc_b_id', id::text, true) FROM loc;

-- Party for Partner B
WITH party AS (
  INSERT INTO public.parties (
    partner_id, location_id, title, description
  ) VALUES (
    current_setting('tests.rr_partner_b_id')::uuid,
    current_setting('tests.rr_loc_b_id')::uuid,
    'Party B',
    '"Test"'::jsonb
  )
  RETURNING id
)
SELECT set_config('tests.rr_party_b_id', id::text, true) FROM party;

-- Recurrence rule for Party A (service_role로 직접 삽입)
WITH rule AS (
  INSERT INTO public.recurrence_rules (
    party_id, pattern, start_time, end_time
  ) VALUES (
    current_setting('tests.rr_party_a_id')::uuid,
    'weekly',
    '10:00',
    '11:00'
  )
  RETURNING id
)
SELECT set_config('tests.rr_rule_a_id', id::text, true) FROM rule;

-- ============================================================
-- 1. anon — recurrence_rules 조회 불가
-- ============================================================
SELECT tests.clear_authentication();

SELECT is_empty(
  $$SELECT * FROM public.recurrence_rules$$,
  'anon cannot SELECT recurrence_rules'
);

SAVEPOINT before_anon_insert;
SELECT throws_ok(
  format(
    $$
      INSERT INTO public.recurrence_rules (
        party_id, pattern, start_time, end_time
      ) VALUES ('%s', 'weekly', '10:00', '11:00')
    $$,
    current_setting('tests.rr_party_a_id')
  ),
  NULL,
  NULL,
  'anon cannot INSERT recurrence_rules'
);
ROLLBACK TO SAVEPOINT before_anon_insert;

-- ============================================================
-- 2. user_a (Party A owner) — 자기 파티의 규칙 조회 가능
-- ============================================================
SELECT tests.authenticate_as('rr_user_a');

SELECT results_eq(
  $$SELECT count(*)::int FROM public.recurrence_rules$$,
  $$VALUES (1)$$,
  'user_a sees own party rule'
);

-- ============================================================
-- 3. user_a — 자기 파티에 규칙 INSERT 가능
-- (현재 active 규칙이 있으므로 먼저 취소 후 추가)
-- ============================================================
SELECT tests.authenticate_as_service_role();
UPDATE public.recurrence_rules
SET status = 'cancelled'
WHERE id = current_setting('tests.rr_rule_a_id')::uuid;

SELECT tests.authenticate_as('rr_user_a');

SELECT lives_ok(
  format(
    $$
      INSERT INTO public.recurrence_rules (
        party_id, pattern, start_time, end_time
      ) VALUES ('%s', 'biweekly', '14:00', '15:00')
    $$,
    current_setting('tests.rr_party_a_id')
  ),
  'user_a can INSERT rule for own party'
);

-- ============================================================
-- 4. user_a — 자기 파티의 규칙 UPDATE (status 변경) 가능
-- ============================================================
SELECT lives_ok(
  format(
    $$
      UPDATE public.recurrence_rules
      SET status = 'paused'
      WHERE party_id = '%s' AND status = 'active'
    $$,
    current_setting('tests.rr_party_a_id')
  ),
  'user_a can UPDATE own rule status'
);

-- ============================================================
-- 5. user_b (권한 없음) — 다른 파티 규칙 조회 불가
-- ============================================================
SELECT tests.authenticate_as('rr_user_b');

SELECT is_empty(
  $$SELECT * FROM public.recurrence_rules$$,
  'user_b (no permission) cannot see recurrence_rules'
);

SAVEPOINT before_b_insert;
SELECT throws_ok(
  format(
    $$
      INSERT INTO public.recurrence_rules (
        party_id, pattern, start_time, end_time
      ) VALUES ('%s', 'weekly', '10:00', '11:00')
    $$,
    current_setting('tests.rr_party_a_id')
  ),
  NULL,
  NULL,
  'user_b cannot INSERT rule for partner_a party'
);
ROLLBACK TO SAVEPOINT before_b_insert;

-- ============================================================
-- 6. user_c (Partner B owner) — Partner A 규칙 조회 불가
-- ============================================================
SELECT tests.authenticate_as('rr_user_c');

SELECT is_empty(
  format(
    $$SELECT * FROM public.recurrence_rules WHERE party_id = '%s'$$,
    current_setting('tests.rr_party_a_id')
  ),
  'user_c (different partner) cannot see partner_a rules'
);

-- user_c는 자기 파티에 규칙 INSERT 가능
SELECT lives_ok(
  format(
    $$
      INSERT INTO public.recurrence_rules (
        party_id, pattern, start_time, end_time
      ) VALUES ('%s', 'monthly', '09:00', '10:00')
    $$,
    current_setting('tests.rr_party_b_id')
  ),
  'user_c can INSERT rule for own party_b'
);

-- ============================================================
-- 7. service_role — 전체 접근 가능
-- ============================================================
SELECT tests.authenticate_as_service_role();

SELECT results_eq(
  $$SELECT count(*)::int FROM public.recurrence_rules$$,
  $$VALUES (3)$$,
  'service_role sees all 3 recurrence_rules'
);

SELECT lives_ok(
  format(
    $$
      UPDATE public.recurrence_rules
      SET status = 'cancelled'
      WHERE party_id = '%s'
    $$,
    current_setting('tests.rr_party_a_id')
  ),
  'service_role can UPDATE any rule'
);

SELECT * FROM finish();
ROLLBACK;
