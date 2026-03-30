BEGIN;
SELECT plan(7);

SELECT tests.authenticate_as_service_role();

-- ============================================================
-- Test 1: balance_config가 null인 파티 → allowed: true
-- ============================================================

CREATE TEMP TABLE balance_null_config_results (
  allowed boolean,
  reason text
);

DO $$
DECLARE
  v_partner_id uuid;
  v_party_id uuid;
  v_event_id uuid;
  v_ticket_id uuid;
  v_result jsonb;
BEGIN
  INSERT INTO public.partners (name)
  VALUES ('Balance Test Partner 1')
  RETURNING id INTO v_partner_id;

  -- balance_config = null (default)
  INSERT INTO public.parties (partner_id, title, min_confirmed_count, max_participants, balance_config)
  VALUES (v_partner_id, 'Party No Balance Config', 0, 10, null)
  RETURNING id INTO v_party_id;

  INSERT INTO public.events (party_id, start_time, end_time, min_confirmed_count, max_participants)
  VALUES (v_party_id, now() + interval '1 day', now() + interval '1 day 2 hours', 0, 10)
  RETURNING id INTO v_event_id;

  INSERT INTO public.tickets (event_id, name, quantity, price)
  VALUES (v_event_id, 'Ticket No Balance', 10, 1000)
  RETURNING id INTO v_ticket_id;

  v_result := public.check_party_balance(v_event_id, v_ticket_id);

  INSERT INTO balance_null_config_results (allowed, reason)
  VALUES ((v_result->>'allowed')::boolean, v_result->>'reason');
END $$;

SELECT is(
  (SELECT allowed FROM balance_null_config_results),
  true,
  'balance_config null → allowed: true'
);

-- ============================================================
-- Test 2: balance_config.enabled=false인 파티 → allowed: true
-- ============================================================

CREATE TEMP TABLE balance_disabled_results (
  allowed boolean,
  reason text
);

DO $$
DECLARE
  v_partner_id uuid;
  v_party_id uuid;
  v_event_id uuid;
  v_ticket_id uuid;
  v_result jsonb;
BEGIN
  INSERT INTO public.partners (name)
  VALUES ('Balance Test Partner 2')
  RETURNING id INTO v_partner_id;

  -- balance_config.enabled = false
  INSERT INTO public.parties (partner_id, title, min_confirmed_count, max_participants, balance_config)
  VALUES (v_partner_id, 'Party Balance Disabled', 0, 10, '{"enabled": false, "tolerance": 2}'::jsonb)
  RETURNING id INTO v_party_id;

  INSERT INTO public.events (party_id, start_time, end_time, min_confirmed_count, max_participants)
  VALUES (v_party_id, now() + interval '1 day', now() + interval '1 day 2 hours', 0, 10)
  RETURNING id INTO v_event_id;

  INSERT INTO public.tickets (event_id, name, quantity, price)
  VALUES (v_event_id, 'Ticket Balance Disabled', 10, 1000)
  RETURNING id INTO v_ticket_id;

  v_result := public.check_party_balance(v_event_id, v_ticket_id);

  INSERT INTO balance_disabled_results (allowed, reason)
  VALUES ((v_result->>'allowed')::boolean, v_result->>'reason');
END $$;

SELECT is(
  (SELECT allowed FROM balance_disabled_results),
  true,
  'balance_config.enabled=false → allowed: true'
);

-- ============================================================
-- Test 3: entry_group이 없는 티켓 (gender null) → allowed: true
-- ============================================================

CREATE TEMP TABLE balance_no_gender_results (
  allowed boolean,
  reason text
);

DO $$
DECLARE
  v_partner_id uuid;
  v_party_id uuid;
  v_event_id uuid;
  v_ticket_id uuid;
  v_result jsonb;
BEGIN
  INSERT INTO public.partners (name)
  VALUES ('Balance Test Partner 3')
  RETURNING id INTO v_partner_id;

  -- balance_config enabled, but ticket has no entry_group (gender null)
  INSERT INTO public.parties (partner_id, title, min_confirmed_count, max_participants, balance_config)
  VALUES (v_partner_id, 'Party No Entry Group', 0, 10, '{"enabled": true, "tolerance": 2}'::jsonb)
  RETURNING id INTO v_party_id;

  INSERT INTO public.events (party_id, start_time, end_time, min_confirmed_count, max_participants)
  VALUES (v_party_id, now() + interval '1 day', now() + interval '1 day 2 hours', 0, 10)
  RETURNING id INTO v_event_id;

  -- ticket with empty target_entry_group_ids (no gender association)
  INSERT INTO public.tickets (event_id, name, quantity, price, target_entry_group_ids)
  VALUES (v_event_id, 'Ticket No Entry Group', 10, 1000, '{}')
  RETURNING id INTO v_ticket_id;

  v_result := public.check_party_balance(v_event_id, v_ticket_id);

  INSERT INTO balance_no_gender_results (allowed, reason)
  VALUES ((v_result->>'allowed')::boolean, v_result->>'reason');
END $$;

SELECT is(
  (SELECT allowed FROM balance_no_gender_results),
  true,
  'entry_group 없는 티켓 (gender null) → allowed: true'
);

-- ============================================================
-- Test 4: 성별 균형 이내 (male 1명, female 0명, tolerance 2) → allowed: true
-- ============================================================

CREATE TEMP TABLE balance_within_tolerance_results (
  allowed boolean,
  reason text
);

DO $$
DECLARE
  v_user_id uuid;
  v_existing_user_id uuid;
  v_partner_id uuid;
  v_party_id uuid;
  v_event_id uuid;
  v_ticket_male_id uuid;
  v_entry_group_male_id uuid;
  v_result jsonb;
BEGIN
  v_user_id := tests.create_supabase_user('balance_test_user_4a');
  v_existing_user_id := tests.create_supabase_user('balance_test_user_4b');

  INSERT INTO public.partners (name)
  VALUES ('Balance Test Partner 4')
  RETURNING id INTO v_partner_id;

  INSERT INTO public.parties (partner_id, title, min_confirmed_count, max_participants, balance_config)
  VALUES (v_partner_id, 'Party Within Tolerance', 0, 20, '{"enabled": true, "tolerance": 2}'::jsonb)
  RETURNING id INTO v_party_id;

  INSERT INTO public.events (party_id, start_time, end_time, min_confirmed_count, max_participants)
  VALUES (v_party_id, now() + interval '1 day', now() + interval '1 day 2 hours', 0, 20)
  RETURNING id INTO v_event_id;

  -- Create male entry group
  INSERT INTO public.entry_groups (event_id, label, gender)
  VALUES (v_event_id, 'Male Group', 'male'::public.gender)
  RETURNING id INTO v_entry_group_male_id;

  -- Male ticket
  INSERT INTO public.tickets (event_id, name, quantity, price, target_entry_group_ids)
  VALUES (v_event_id, 'Male Ticket', 10, 1000, ARRAY[v_entry_group_male_id])
  RETURNING id INTO v_ticket_male_id;

  -- Add 1 existing male participant
  INSERT INTO public.event_participants (event_id, ticket_id, user_id)
  VALUES (v_event_id, v_ticket_male_id, v_existing_user_id);

  -- Now check if another male can join (male 1 + 1 = 2, female 0, diff = 2, tolerance = 2 → allowed)
  v_result := public.check_party_balance(v_event_id, v_ticket_male_id);

  INSERT INTO balance_within_tolerance_results (allowed, reason)
  VALUES ((v_result->>'allowed')::boolean, v_result->>'reason');
END $$;

SELECT is(
  (SELECT allowed FROM balance_within_tolerance_results),
  true,
  '성별 균형 이내 (male 1명 + 신청 1명, female 0명, tolerance 2) → allowed: true'
);

-- ============================================================
-- Test 5: 성별 균형 초과 (male 3명, female 0명, tolerance 2) → allowed: false
-- ============================================================

CREATE TEMP TABLE balance_exceeded_results (
  allowed boolean,
  reason text
);

DO $$
DECLARE
  v_user1_id uuid;
  v_user2_id uuid;
  v_user3_id uuid;
  v_partner_id uuid;
  v_party_id uuid;
  v_event_id uuid;
  v_ticket_male_id uuid;
  v_entry_group_male_id uuid;
  v_result jsonb;
BEGIN
  v_user1_id := tests.create_supabase_user('balance_test_user_5a');
  v_user2_id := tests.create_supabase_user('balance_test_user_5b');
  v_user3_id := tests.create_supabase_user('balance_test_user_5c');

  INSERT INTO public.partners (name)
  VALUES ('Balance Test Partner 5')
  RETURNING id INTO v_partner_id;

  INSERT INTO public.parties (partner_id, title, min_confirmed_count, max_participants, balance_config)
  VALUES (v_partner_id, 'Party Exceeded Tolerance', 0, 20, '{"enabled": true, "tolerance": 2}'::jsonb)
  RETURNING id INTO v_party_id;

  INSERT INTO public.events (party_id, start_time, end_time, min_confirmed_count, max_participants)
  VALUES (v_party_id, now() + interval '1 day', now() + interval '1 day 2 hours', 0, 20)
  RETURNING id INTO v_event_id;

  -- Create male entry group
  INSERT INTO public.entry_groups (event_id, label, gender)
  VALUES (v_event_id, 'Male Group', 'male'::public.gender)
  RETURNING id INTO v_entry_group_male_id;

  -- Male ticket
  INSERT INTO public.tickets (event_id, name, quantity, price, target_entry_group_ids)
  VALUES (v_event_id, 'Male Ticket Exceeded', 10, 1000, ARRAY[v_entry_group_male_id])
  RETURNING id INTO v_ticket_male_id;

  -- Add 3 existing male participants (male 3, female 0)
  INSERT INTO public.event_participants (event_id, ticket_id, user_id)
  VALUES (v_event_id, v_ticket_male_id, v_user1_id);
  INSERT INTO public.event_participants (event_id, ticket_id, user_id)
  VALUES (v_event_id, v_ticket_male_id, v_user2_id);
  INSERT INTO public.event_participants (event_id, ticket_id, user_id)
  VALUES (v_event_id, v_ticket_male_id, v_user3_id);

  -- Now check if another male can join (male 3 + 1 = 4, female 0, diff = 4, tolerance = 2 → NOT allowed)
  v_result := public.check_party_balance(v_event_id, v_ticket_male_id);

  INSERT INTO balance_exceeded_results (allowed, reason)
  VALUES ((v_result->>'allowed')::boolean, v_result->>'reason');
END $$;

SELECT is(
  (SELECT allowed FROM balance_exceeded_results),
  false,
  '성별 균형 초과 (male 3명 + 신청 1명, female 0명, tolerance 2) → allowed: false'
);

SELECT is(
  (SELECT reason FROM balance_exceeded_results),
  '성비 조절 중',
  '성별 균형 초과 시 reason = 성비 조절 중'
);

-- ============================================================
-- Test 6: 반환 JSON에 allowed 키 존재 확인
-- ============================================================

CREATE TEMP TABLE balance_key_check_results (
  has_allowed_key boolean
);

DO $$
DECLARE
  v_partner_id uuid;
  v_party_id uuid;
  v_event_id uuid;
  v_ticket_id uuid;
  v_result jsonb;
BEGIN
  INSERT INTO public.partners (name)
  VALUES ('Balance Test Partner 6')
  RETURNING id INTO v_partner_id;

  INSERT INTO public.parties (partner_id, title, min_confirmed_count, max_participants, balance_config)
  VALUES (v_partner_id, 'Party Key Check', 0, 10, null)
  RETURNING id INTO v_party_id;

  INSERT INTO public.events (party_id, start_time, end_time, min_confirmed_count, max_participants)
  VALUES (v_party_id, now() + interval '1 day', now() + interval '1 day 2 hours', 0, 10)
  RETURNING id INTO v_event_id;

  INSERT INTO public.tickets (event_id, name, quantity, price)
  VALUES (v_event_id, 'Ticket Key Check', 10, 1000)
  RETURNING id INTO v_ticket_id;

  v_result := public.check_party_balance(v_event_id, v_ticket_id);

  INSERT INTO balance_key_check_results (has_allowed_key)
  VALUES (v_result ? 'allowed');
END $$;

SELECT is(
  (SELECT has_allowed_key FROM balance_key_check_results),
  true,
  '반환 JSON에 allowed 키 존재'
);

SELECT * FROM finish();
ROLLBACK;
