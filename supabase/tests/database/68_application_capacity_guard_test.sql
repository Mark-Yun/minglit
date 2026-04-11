BEGIN;
SELECT plan(9);

SELECT tests.authenticate_as_service_role();

CREATE TEMP TABLE approval_guard_results (
  test_name text,
  result_text text,
  result_int integer
);

DO $$
DECLARE
  v_partner_id uuid;
  v_party_id uuid;
  v_event_id uuid;
  v_ticket_id uuid;
  v_user_1 uuid;
  v_user_2 uuid;
  v_user_3 uuid;
  v_user_4 uuid;
  v_verification_id uuid;
  v_app_1 uuid;
  v_app_2 uuid;
  v_app_3 uuid;
  v_app_4 uuid;
  v_verification_submission_id uuid;
  v_single_status text;
  v_bulk record;
BEGIN
  v_user_1 := tests.create_supabase_user('capacity_guard_user_1');
  v_user_2 := tests.create_supabase_user('capacity_guard_user_2');
  v_user_3 := tests.create_supabase_user('capacity_guard_user_3');
  v_user_4 := tests.create_supabase_user('capacity_guard_user_4');

  INSERT INTO public.user_profiles (id, name, birth_date, gender, username)
  VALUES
    (v_user_1, 'Capacity User 1', '1995-01-01', 'male', 'capacity_guard_user_1'),
    (v_user_2, 'Capacity User 2', '1995-01-02', 'female', 'capacity_guard_user_2'),
    (v_user_3, 'Capacity User 3', '1995-01-03', 'male', 'capacity_guard_user_3'),
    (v_user_4, 'Capacity User 4', '1995-01-04', 'female', 'capacity_guard_user_4')
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO public.partners (name)
  VALUES ('Capacity Guard Partner')
  RETURNING id INTO v_partner_id;

  INSERT INTO public.parties (partner_id, title, min_confirmed_count, max_participants)
  VALUES (v_partner_id, 'Capacity Guard Party', 0, 2)
  RETURNING id INTO v_party_id;

  INSERT INTO public.events (party_id, start_time, end_time, min_confirmed_count, max_participants, current_participants)
  VALUES (v_party_id, now() + interval '1 day', now() + interval '1 day 2 hours', 0, 2, 0)
  RETURNING id INTO v_event_id;

  INSERT INTO public.tickets (event_id, name, quantity, price)
  VALUES (v_event_id, 'Capacity Guard Ticket', 2, 1000)
  RETURNING id INTO v_ticket_id;

  INSERT INTO public.event_applications (event_id, ticket_id, user_id, status, created_at)
  VALUES (v_event_id, v_ticket_id, v_user_1, 'pending_review', now() - interval '3 minutes')
  RETURNING id INTO v_app_1;

  INSERT INTO public.event_applications (event_id, ticket_id, user_id, status, created_at)
  VALUES (v_event_id, v_ticket_id, v_user_2, 'pending_review', now() - interval '2 minutes')
  RETURNING id INTO v_app_2;

  INSERT INTO public.event_applications (event_id, ticket_id, user_id, status, created_at)
  VALUES (v_event_id, v_ticket_id, v_user_3, 'pending_review', now() - interval '1 minute')
  RETURNING id INTO v_app_3;

  SELECT result_status
  INTO v_single_status
  FROM public.approve_event_application_with_capacity_guard(v_app_1);

  INSERT INTO approval_guard_results (test_name, result_text)
  VALUES ('single_status', v_single_status);

  INSERT INTO approval_guard_results (test_name, result_int)
  SELECT 'participants_after_single', current_participants
  FROM public.events
  WHERE id = v_event_id;

  SELECT *
  INTO v_bulk
  FROM public.bulk_approve_event_applications_with_capacity_guard(v_event_id);

  INSERT INTO approval_guard_results (test_name, result_text)
  VALUES ('bulk_status', v_bulk.result_status);

  INSERT INTO approval_guard_results (test_name, result_int)
  VALUES
    ('bulk_approved_count', v_bulk.approved_count),
    ('bulk_skipped_count', v_bulk.skipped_due_to_capacity),
    ('participants_after_bulk', (SELECT current_participants FROM public.events WHERE id = v_event_id));

  INSERT INTO approval_guard_results (test_name, result_text)
  VALUES
    ('bulk_second_application_status', (SELECT status FROM public.event_applications WHERE id = v_app_2)),
    ('bulk_third_application_status', (SELECT status FROM public.event_applications WHERE id = v_app_3));

  INSERT INTO public.verifications (partner_id, category, internal_name, display_name)
  VALUES (v_partner_id, 'career', 'capacity_guard_verification', 'Capacity Guard Verification')
  RETURNING id INTO v_verification_id;

  INSERT INTO public.event_applications (event_id, ticket_id, user_id, status)
  VALUES (v_event_id, v_ticket_id, v_user_4, 'pending_review')
  RETURNING id INTO v_app_4;

  INSERT INTO public.verification_submissions (
    partner_id,
    user_id,
    verification_id,
    application_id,
    status,
    snapshot_data
  )
  VALUES (
    v_partner_id,
    v_user_4,
    v_verification_id,
    v_app_4,
    'pending',
    '{"proof":"capacity"}'::jsonb
  )
  RETURNING id INTO v_verification_submission_id;

  UPDATE public.verification_submissions
  SET status = 'approved'
  WHERE id = v_verification_submission_id;

  INSERT INTO approval_guard_results (test_name, result_text)
  SELECT 'verification_application_status', status
  FROM public.event_applications
  WHERE id = v_app_4;
END $$;

SELECT is(
  (SELECT result_text FROM approval_guard_results WHERE test_name = 'single_status'),
  'approved',
  'single approval helper approves when capacity remains'
);

SELECT is(
  (SELECT result_int FROM approval_guard_results WHERE test_name = 'participants_after_single'),
  1,
  'single approval helper issues one participant via existing trigger'
);

SELECT is(
  (SELECT result_text FROM approval_guard_results WHERE test_name = 'bulk_status'),
  'approved',
  'bulk approval helper returns approved status when some capacity remains'
);

SELECT is(
  (SELECT result_int FROM approval_guard_results WHERE test_name = 'bulk_approved_count'),
  1,
  'bulk approval helper only approves up to the last remaining slot'
);

SELECT is(
  (SELECT result_int FROM approval_guard_results WHERE test_name = 'bulk_skipped_count'),
  1,
  'bulk approval helper reports skipped pending applications once capacity is exhausted'
);

SELECT is(
  (SELECT result_text FROM approval_guard_results WHERE test_name = 'bulk_second_application_status'),
  'approved',
  'bulk approval helper approves the oldest remaining pending application first'
);

SELECT is(
  (SELECT result_text FROM approval_guard_results WHERE test_name = 'bulk_third_application_status'),
  'pending_review',
  'bulk approval helper leaves the newest pending application untouched when capacity is exhausted'
);

SELECT is(
  (SELECT result_int FROM approval_guard_results WHERE test_name = 'participants_after_bulk'),
  2,
  'bulk approval helper leaves current_participants capped at max_participants'
);

SELECT is(
  (SELECT result_text FROM approval_guard_results WHERE test_name = 'verification_application_status'),
  'pending_review',
  'verification auto-approval leaves the application pending_review when the event is already full'
);

SELECT * FROM finish();
ROLLBACK;
