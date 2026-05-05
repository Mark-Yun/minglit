BEGIN;
SELECT plan(6);

-- ============================================================
-- Setup
-- ============================================================

SELECT tests.authenticate_as_service_role();

SELECT tests.create_supabase_user('brv_applicant_a');
SELECT tests.create_supabase_user('brv_applicant_b');
SELECT tests.create_supabase_user('brv_applicant_c');

-- issue_ticket_on_approval trigger needs user_profiles rows to insert event_participants,
-- which then fires on_participant_change to increment current_participants.
-- Explicit insert (ON CONFLICT DO NOTHING) ensures trigger chain works even when
-- on_auth_user_created creates sparse rows from test metadata.
INSERT INTO public.user_profiles (id, name, birth_date, gender, username)
VALUES
  (tests.get_supabase_uid('brv_applicant_a'), 'BRV Applicant A', '1995-01-01', 'male',   'brv_applicant_a'),
  (tests.get_supabase_uid('brv_applicant_b'), 'BRV Applicant B', '1995-01-02', 'female', 'brv_applicant_b'),
  (tests.get_supabase_uid('brv_applicant_c'), 'BRV Applicant C', '1995-01-03', 'male',   'brv_applicant_c')
ON CONFLICT (id) DO NOTHING;

DO $$
DECLARE
  v_partner_id  uuid;
  v_party_id    uuid;
  v_event_id    uuid;
  v_ticket_id   uuid;
  v_app_a_id    uuid;
  v_app_b_id    uuid;
  v_app_c_id    uuid;
BEGIN
  INSERT INTO public.partners (name) VALUES ('BRV Test Partner')
  RETURNING id INTO v_partner_id;

  INSERT INTO public.parties (partner_id, title, min_confirmed_count, max_participants)
  VALUES (v_partner_id, 'BRV Party', 0, 1)
  RETURNING id INTO v_party_id;

  INSERT INTO public.events (party_id, start_time, end_time, min_confirmed_count, max_participants, current_participants)
  VALUES (v_party_id, now() + interval '1 day', now() + interval '1 day 2 hours', 0, 1, 0)
  RETURNING id INTO v_event_id;

  INSERT INTO public.tickets (event_id, name, quantity, price)
  VALUES (v_event_id, 'General', 10, 0)
  RETURNING id INTO v_ticket_id;

  INSERT INTO public.event_applications (event_id, ticket_id, user_id, status)
  VALUES (v_event_id, v_ticket_id, tests.get_supabase_uid('brv_applicant_a'), 'pending')
  RETURNING id INTO v_app_a_id;

  INSERT INTO public.event_applications (event_id, ticket_id, user_id, status)
  VALUES (v_event_id, v_ticket_id, tests.get_supabase_uid('brv_applicant_b'), 'pending')
  RETURNING id INTO v_app_b_id;

  INSERT INTO public.event_applications (event_id, ticket_id, user_id, status)
  VALUES (v_event_id, v_ticket_id, tests.get_supabase_uid('brv_applicant_c'), 'pending')
  RETURNING id INTO v_app_c_id;

  PERFORM set_config('tests.brv_event_id',  v_event_id::text,  true);
  PERFORM set_config('tests.brv_app_a_id',  v_app_a_id::text,  true);
  PERFORM set_config('tests.brv_app_b_id',  v_app_b_id::text,  true);
  PERFORM set_config('tests.brv_app_c_id',  v_app_c_id::text,  true);
END $$;

-- ============================================================
-- Test 1: approve + reject in single call
-- ============================================================

SELECT tests.authenticate_as_service_role();

DO $$
DECLARE
  v_result record;
BEGIN
  SELECT * INTO v_result
  FROM public.batch_review_event_applications(
    current_setting('tests.brv_event_id')::uuid,
    ARRAY[current_setting('tests.brv_app_a_id')::uuid],
    ARRAY[ROW(current_setting('tests.brv_app_b_id')::uuid, '조건 미충족')::public.rejection_item]
  );
  PERFORM set_config('tests.brv_approved_count',   array_length(v_result.approved, 1)::text,  true);
  PERFORM set_config('tests.brv_rejected_count',   array_length(v_result.rejected, 1)::text,  true);
  PERFORM set_config('tests.brv_remaining_after',  v_result.remaining_slots_after::text,       true);
END $$;

SELECT is(
  current_setting('tests.brv_approved_count')::integer, 1,
  'batch_review: 1 approved'
);

SELECT is(
  current_setting('tests.brv_rejected_count')::integer, 1,
  'batch_review: 1 rejected'
);

-- ============================================================
-- Test 3: approved application has status = approved
-- ============================================================

SELECT is(
  (SELECT status FROM public.event_applications WHERE id = current_setting('tests.brv_app_a_id')::uuid),
  'approved',
  'batch_review: approved application status = approved'
);

-- ============================================================
-- Test 4: rejected application has status = rejected with reason
-- ============================================================

SELECT is(
  (SELECT rejection_reason FROM public.event_applications WHERE id = current_setting('tests.brv_app_b_id')::uuid),
  '조건 미충족',
  'batch_review: rejected application has rejection_reason'
);

-- ============================================================
-- Test 5: capacity guard skips applicant when event is already full.
-- Creates a fresh partner/party/event pre-seeded at full capacity
-- (current_participants = max_participants = 1) so the RPC capacity-guard
-- is tested independently of the trigger chain that updates current_participants.
-- ============================================================

DO $$
DECLARE
  v_partner_id    uuid;
  v_party_id      uuid;
  v_full_event_id uuid;
  v_ticket_id     uuid;
  v_app_id        uuid;
  v_result        record;
BEGIN
  INSERT INTO public.partners (name) VALUES ('BRV Capacity Test Partner')
  RETURNING id INTO v_partner_id;

  INSERT INTO public.parties (partner_id, title, min_confirmed_count, max_participants)
  VALUES (v_partner_id, 'BRV Capacity Party', 0, 1)
  RETURNING id INTO v_party_id;

  INSERT INTO public.events (party_id, start_time, end_time, min_confirmed_count, max_participants, current_participants)
  VALUES (v_party_id, now() + interval '2 days', now() + interval '2 days 2 hours', 0, 1, 1)
  RETURNING id INTO v_full_event_id;

  -- quantity=1 so sync_max_participants trigger keeps max_participants=1 (matching pre-seeded current_participants)
  INSERT INTO public.tickets (event_id, name, quantity, price)
  VALUES (v_full_event_id, 'General', 1, 0)
  RETURNING id INTO v_ticket_id;

  INSERT INTO public.event_applications (event_id, ticket_id, user_id, status)
  VALUES (v_full_event_id, v_ticket_id, tests.get_supabase_uid('brv_applicant_c'), 'pending')
  RETURNING id INTO v_app_id;

  SELECT * INTO v_result
  FROM public.batch_review_event_applications(
    v_full_event_id,
    ARRAY[v_app_id],
    ARRAY[]::public.rejection_item[]
  );

  PERFORM set_config('tests.brv_skipped_count', COALESCE(array_length(v_result.skipped_due_to_capacity, 1), 0)::text, true);
END $$;

SELECT is(
  current_setting('tests.brv_skipped_count')::integer, 1,
  'batch_review: approval skipped due to capacity (event already full)'
);

-- ============================================================
-- Test 6: already-processed application is in skipped_already_processed
-- ============================================================

DO $$
DECLARE
  v_result record;
BEGIN
  -- Try to approve an already-approved application
  SELECT * INTO v_result
  FROM public.batch_review_event_applications(
    current_setting('tests.brv_event_id')::uuid,
    ARRAY[current_setting('tests.brv_app_a_id')::uuid],
    ARRAY[]::public.rejection_item[]
  );
  PERFORM set_config('tests.brv_processed_count', COALESCE(array_length(v_result.skipped_already_processed, 1), 0)::text, true);
END $$;

SELECT is(
  current_setting('tests.brv_processed_count')::integer, 1,
  'batch_review: already-approved application in skipped_already_processed'
);

SELECT * FROM finish();
ROLLBACK;
