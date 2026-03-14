BEGIN;
SELECT plan(6);

SELECT tests.authenticate_as_service_role();

-- ============================================================
-- Test 1~4: 승인 시 event_participants 레코드 생성 및 필드 검증
-- ============================================================

CREATE TEMP TABLE ticket_results (
  participant_count int,
  ticket_code text,
  display_name text,
  birth_year int,
  participant_status text
);

DO $$
DECLARE
  v_user_id uuid;
  v_partner_id uuid;
  v_party_id uuid;
  v_event_id uuid;
  v_ticket_id uuid;
  v_app_id uuid;
BEGIN
  v_user_id := tests.create_supabase_user('ticket_test_user_1');

  INSERT INTO public.user_profiles (id, name, birth_date, gender, username)
  VALUES (v_user_id, 'Test User', '2000-01-01', 'male', 'ticket_test_user_1');

  INSERT INTO public.partners (name)
  VALUES ('Ticket Partner 1')
  RETURNING id INTO v_partner_id;

  INSERT INTO public.parties (partner_id, title, min_confirmed_count, max_participants)
  VALUES (v_partner_id, 'Ticket Party 1', 0, 10)
  RETURNING id INTO v_party_id;

  INSERT INTO public.events (party_id, start_time, end_time, min_confirmed_count, max_participants)
  VALUES (v_party_id, now() + interval '1 day', now() + interval '1 day 2 hours', 0, 10)
  RETURNING id INTO v_event_id;

  INSERT INTO public.tickets (event_id, name, quantity, price)
  VALUES (v_event_id, 'Ticket 1', 10, 5000)
  RETURNING id INTO v_ticket_id;

  INSERT INTO public.event_applications (event_id, ticket_id, user_id, status, payment_id, payment_amount)
  VALUES (v_event_id, v_ticket_id, v_user_id, 'pending_review', 'imp_ticket_001', 5000)
  RETURNING id INTO v_app_id;

  -- 승인으로 상태 변경 → 트리거 발동
  UPDATE public.event_applications SET status = 'approved' WHERE id = v_app_id;

  INSERT INTO ticket_results (participant_count, ticket_code, display_name, birth_year, participant_status)
  SELECT count(*)::int, ticket_code, display_name, birth_year, status
  FROM public.event_participants
  WHERE event_id = v_event_id AND user_id = v_user_id;
END $$;

-- Test 1: 승인 시 event_participants 레코드 생성
SELECT is(
  (SELECT participant_count FROM ticket_results),
  1,
  '승인 시 event_participants 레코드 1개 생성'
);

-- Test 2: ticket_code 길이 8자
SELECT is(
  length((SELECT ticket_code FROM ticket_results)),
  8,
  'ticket_code 길이 8자'
);

-- Test 3: display_name = user_profiles.name
SELECT is(
  (SELECT display_name FROM ticket_results),
  'Test User',
  'display_name = user_profiles.name'
);

-- Test 4: birth_year = 2000 (birth_date에서 추출)
SELECT is(
  (SELECT birth_year FROM ticket_results),
  2000,
  'birth_year = 2000 (birth_date에서 추출)'
);

-- ============================================================
-- Test 5: ticket_code가 8자 대문자 hex 형식 검증
-- ============================================================

SELECT is(
  (SELECT ticket_code FROM ticket_results) ~ '^[0-9A-F]{8}$',
  true,
  'ticket_code가 8자 대문자 hex 형식'
);

-- ============================================================
-- Test 6: 동일 user+event 중복 승인 → ON CONFLICT DO NOTHING (레코드 1개만)
-- ============================================================

CREATE TEMP TABLE duplicate_ticket_results (
  participant_count int
);

DO $$
DECLARE
  v_user_id uuid;
  v_partner_id uuid;
  v_party_id uuid;
  v_event_id uuid;
  v_ticket_id uuid;
  v_app_id_1 uuid;
  v_app_id_2 uuid;
BEGIN
  v_user_id := tests.create_supabase_user('ticket_test_user_2');

  INSERT INTO public.user_profiles (id, name, birth_date, gender, username)
  VALUES (v_user_id, 'Duplicate User', '1995-06-15', 'female', 'ticket_test_user_2');

  INSERT INTO public.partners (name)
  VALUES ('Ticket Partner 2')
  RETURNING id INTO v_partner_id;

  INSERT INTO public.parties (partner_id, title, min_confirmed_count, max_participants)
  VALUES (v_partner_id, 'Ticket Party 2', 0, 10)
  RETURNING id INTO v_party_id;

  INSERT INTO public.events (party_id, start_time, end_time, min_confirmed_count, max_participants)
  VALUES (v_party_id, now() + interval '1 day', now() + interval '1 day 2 hours', 0, 10)
  RETURNING id INTO v_event_id;

  INSERT INTO public.tickets (event_id, name, quantity, price)
  VALUES (v_event_id, 'Ticket 2', 10, 5000)
  RETURNING id INTO v_ticket_id;

  -- 첫 번째 신청 및 승인
  INSERT INTO public.event_applications (event_id, ticket_id, user_id, status, payment_id, payment_amount)
  VALUES (v_event_id, v_ticket_id, v_user_id, 'pending_review', 'imp_ticket_002a', 5000)
  RETURNING id INTO v_app_id_1;

  UPDATE public.event_applications SET status = 'approved' WHERE id = v_app_id_1;

  -- 두 번째 신청 및 승인 (동일 user+event) → ON CONFLICT DO NOTHING
  INSERT INTO public.event_applications (event_id, ticket_id, user_id, status, payment_id, payment_amount)
  VALUES (v_event_id, v_ticket_id, v_user_id, 'pending_review', 'imp_ticket_002b', 5000)
  RETURNING id INTO v_app_id_2;

  UPDATE public.event_applications SET status = 'approved' WHERE id = v_app_id_2;

  INSERT INTO duplicate_ticket_results (participant_count)
  SELECT count(*)::int
  FROM public.event_participants
  WHERE event_id = v_event_id AND user_id = v_user_id;
END $$;

SELECT is(
  (SELECT participant_count FROM duplicate_ticket_results),
  1,
  '동일 user+event 중복 승인 → ON CONFLICT DO NOTHING (레코드 1개만)'
);

SELECT * FROM finish();
ROLLBACK;
