BEGIN;
SELECT plan(8);

SELECT tests.authenticate_as_service_role();

-- ============================================================
-- Test 1+2: verification_data=null → status='paid', 반환값이 UUID
-- ============================================================

CREATE TEMP TABLE apply_no_verify_results (
  app_id uuid,
  status text,
  payment_id text,
  payment_amount int
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
  v_user_id := tests.create_supabase_user('apply_test_user_1');

  INSERT INTO public.partners (name)
  VALUES ('Apply Partner 1')
  RETURNING id INTO v_partner_id;

  INSERT INTO public.parties (partner_id, title, min_confirmed_count, max_participants)
  VALUES (v_partner_id, 'Apply Party 1', 0, 10)
  RETURNING id INTO v_party_id;

  INSERT INTO public.events (party_id, start_time, end_time, min_confirmed_count, max_participants)
  VALUES (v_party_id, now() + interval '1 day', now() + interval '1 day 2 hours', 0, 10)
  RETURNING id INTO v_event_id;

  INSERT INTO public.tickets (event_id, name, quantity, price)
  VALUES (v_event_id, 'Apply Ticket 1', 10, 5000)
  RETURNING id INTO v_ticket_id;

  v_app_id := public.apply_event(v_event_id, v_ticket_id, v_user_id, 'imp_test_001', 5000, null);

  INSERT INTO apply_no_verify_results (app_id, status, payment_id, payment_amount)
  SELECT id, status, payment_id, payment_amount
  FROM public.event_applications
  WHERE id = v_app_id;
END $$;

SELECT is(
  (SELECT status FROM apply_no_verify_results),
  'paid',
  'verification_data=null → status=paid'
);

SELECT isnt(
  (SELECT app_id FROM apply_no_verify_results),
  null,
  'verification_data=null → 반환값이 UUID (not null)'
);

-- ============================================================
-- Test 3+4: payment_id, payment_amount가 올바르게 저장됨
-- ============================================================

SELECT is(
  (SELECT payment_id FROM apply_no_verify_results),
  'imp_test_001',
  'payment_id가 올바르게 저장됨'
);

SELECT is(
  (SELECT payment_amount FROM apply_no_verify_results),
  5000,
  'payment_amount가 올바르게 저장됨'
);

-- ============================================================
-- Test 5: verification_data 포함 신청 → status='pending_review'
-- ============================================================

CREATE TEMP TABLE apply_with_verify_results (
  app_id uuid,
  status text
);

DO $$
DECLARE
  v_user_id uuid;
  v_partner_id uuid;
  v_party_id uuid;
  v_event_id uuid;
  v_ticket_id uuid;
  v_verification_id uuid;
  v_app_id uuid;
  v_verification_data jsonb;
BEGIN
  v_user_id := tests.create_supabase_user('apply_test_user_2');

  INSERT INTO public.partners (name)
  VALUES ('Apply Partner 2')
  RETURNING id INTO v_partner_id;

  INSERT INTO public.parties (partner_id, title, min_confirmed_count, max_participants)
  VALUES (v_partner_id, 'Apply Party 2', 0, 10)
  RETURNING id INTO v_party_id;

  INSERT INTO public.events (party_id, start_time, end_time, min_confirmed_count, max_participants)
  VALUES (v_party_id, now() + interval '1 day', now() + interval '1 day 2 hours', 0, 10)
  RETURNING id INTO v_event_id;

  INSERT INTO public.tickets (event_id, name, quantity, price)
  VALUES (v_event_id, 'Apply Ticket 2', 10, 5000)
  RETURNING id INTO v_ticket_id;

  INSERT INTO public.verifications (partner_id, category, internal_name, display_name)
  VALUES (v_partner_id, 'career', 'apply_verification_2', 'Apply Verification 2')
  RETURNING id INTO v_verification_id;

  v_verification_data := jsonb_build_object(
    'verification_id', v_verification_id,
    'partner_id', v_partner_id,
    'data', '{"company": "Acme Corp"}'::jsonb
  );

  v_app_id := public.apply_event(v_event_id, v_ticket_id, v_user_id, 'imp_test_002', 5000, v_verification_data);

  INSERT INTO apply_with_verify_results (app_id, status)
  SELECT id, status
  FROM public.event_applications
  WHERE id = v_app_id;
END $$;

SELECT is(
  (SELECT status FROM apply_with_verify_results),
  'pending_review',
  'verification_data 포함 신청 → status=pending_review'
);

-- ============================================================
-- Test 6: verification_data 포함 신청 → verification_submissions에 레코드 생성됨
-- ============================================================

CREATE TEMP TABLE apply_submission_results (
  submission_count bigint,
  submission_status text
);

DO $$
DECLARE
  v_user_id uuid;
  v_partner_id uuid;
  v_party_id uuid;
  v_event_id uuid;
  v_ticket_id uuid;
  v_verification_id uuid;
  v_app_id uuid;
  v_verification_data jsonb;
BEGIN
  v_user_id := tests.create_supabase_user('apply_test_user_3');

  INSERT INTO public.partners (name)
  VALUES ('Apply Partner 3')
  RETURNING id INTO v_partner_id;

  INSERT INTO public.parties (partner_id, title, min_confirmed_count, max_participants)
  VALUES (v_partner_id, 'Apply Party 3', 0, 10)
  RETURNING id INTO v_party_id;

  INSERT INTO public.events (party_id, start_time, end_time, min_confirmed_count, max_participants)
  VALUES (v_party_id, now() + interval '1 day', now() + interval '1 day 2 hours', 0, 10)
  RETURNING id INTO v_event_id;

  INSERT INTO public.tickets (event_id, name, quantity, price)
  VALUES (v_event_id, 'Apply Ticket 3', 10, 5000)
  RETURNING id INTO v_ticket_id;

  INSERT INTO public.verifications (partner_id, category, internal_name, display_name)
  VALUES (v_partner_id, 'career', 'apply_verification_3', 'Apply Verification 3')
  RETURNING id INTO v_verification_id;

  v_verification_data := jsonb_build_object(
    'verification_id', v_verification_id,
    'partner_id', v_partner_id,
    'data', '{"company": "Beta Corp"}'::jsonb
  );

  v_app_id := public.apply_event(v_event_id, v_ticket_id, v_user_id, 'imp_test_003', 5000, v_verification_data);

  INSERT INTO apply_submission_results (submission_count, submission_status)
  SELECT COUNT(*), MAX(status)
  FROM public.verification_submissions
  WHERE application_id = v_app_id;
END $$;

SELECT is(
  (SELECT submission_count FROM apply_submission_results),
  1::bigint,
  'verification_data 포함 신청 → verification_submissions에 레코드 1개 생성됨'
);

-- ============================================================
-- Test 7: 반환값이 event_applications.id와 일치
-- ============================================================

CREATE TEMP TABLE apply_id_match_results (
  returned_id uuid,
  db_id uuid
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
  v_user_id := tests.create_supabase_user('apply_test_user_4');

  INSERT INTO public.partners (name)
  VALUES ('Apply Partner 4')
  RETURNING id INTO v_partner_id;

  INSERT INTO public.parties (partner_id, title, min_confirmed_count, max_participants)
  VALUES (v_partner_id, 'Apply Party 4', 0, 10)
  RETURNING id INTO v_party_id;

  INSERT INTO public.events (party_id, start_time, end_time, min_confirmed_count, max_participants)
  VALUES (v_party_id, now() + interval '1 day', now() + interval '1 day 2 hours', 0, 10)
  RETURNING id INTO v_event_id;

  INSERT INTO public.tickets (event_id, name, quantity, price)
  VALUES (v_event_id, 'Apply Ticket 4', 10, 5000)
  RETURNING id INTO v_ticket_id;

  v_app_id := public.apply_event(v_event_id, v_ticket_id, v_user_id, 'imp_test_004', 5000, null);

  INSERT INTO apply_id_match_results (returned_id, db_id)
  SELECT v_app_id, id
  FROM public.event_applications
  WHERE id = v_app_id;
END $$;

SELECT is(
  (SELECT returned_id FROM apply_id_match_results),
  (SELECT db_id FROM apply_id_match_results),
  '반환값이 event_applications.id와 일치'
);

-- ============================================================
-- Test 8: 동일 user+event 중복 신청 → UNIQUE 제약 위반 예외 발생
-- ============================================================

CREATE TEMP TABLE apply_duplicate_setup (
  event_id uuid,
  ticket_id uuid,
  user_id uuid
);

DO $$
DECLARE
  v_user_id uuid;
  v_partner_id uuid;
  v_party_id uuid;
  v_event_id uuid;
  v_ticket_id uuid;
BEGIN
  v_user_id := tests.create_supabase_user('apply_test_user_5');

  INSERT INTO public.partners (name)
  VALUES ('Apply Partner 5')
  RETURNING id INTO v_partner_id;

  INSERT INTO public.parties (partner_id, title, min_confirmed_count, max_participants)
  VALUES (v_partner_id, 'Apply Party 5', 0, 10)
  RETURNING id INTO v_party_id;

  INSERT INTO public.events (party_id, start_time, end_time, min_confirmed_count, max_participants)
  VALUES (v_party_id, now() + interval '1 day', now() + interval '1 day 2 hours', 0, 10)
  RETURNING id INTO v_event_id;

  INSERT INTO public.tickets (event_id, name, quantity, price)
  VALUES (v_event_id, 'Apply Ticket 5', 10, 5000)
  RETURNING id INTO v_ticket_id;

  PERFORM public.apply_event(v_event_id, v_ticket_id, v_user_id, 'imp_test_005a', 5000, null);

  INSERT INTO apply_duplicate_setup (event_id, ticket_id, user_id)
  VALUES (v_event_id, v_ticket_id, v_user_id);
END $$;

SELECT throws_ok(
  format(
    $q$SELECT public.apply_event(%L::uuid, %L::uuid, %L::uuid, 'imp_test_005b', 5000, null)$q$,
    (SELECT event_id FROM apply_duplicate_setup),
    (SELECT ticket_id FROM apply_duplicate_setup),
    (SELECT user_id FROM apply_duplicate_setup)
  ),
  '23505',
  null,
  '동일 user+event 중복 신청 → UNIQUE 제약 위반 예외 발생'
);

SELECT * FROM finish();
ROLLBACK;
