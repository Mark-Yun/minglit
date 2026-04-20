-- Regression tests for Fix #1660: INV-01 + INV-05
--
-- INV-01: approved/paid apps without participant record
--   Root cause: issue_ticket_on_approval trigger skipped INSERT (OLD IS NULL → falsy)
--   Fix: Added `OLD IS NULL` guard in trigger condition
--
-- INV-05: paid apps with NULL payment_id
--   Root cause: apply_event RPC set status='paid' for free events (payment_id=NULL)
--   Fix: apply_event uses status='approved' when payment_id IS NULL
--
-- Cases:
--   1. apply_event(payment_id=NULL, amount=0) → status='approved' (not 'paid')
--   2. apply_event(payment_id=NULL, amount=0) → participant record created by trigger
--   3. Direct INSERT with status='approved' → participant record created by trigger
--   4. apply_event(payment_id='some_id', amount=1000) → status='paid' (unchanged)

BEGIN;
SELECT plan(5);

SELECT tests.authenticate_as_service_role();

-- ============================================================
-- Shared setup
-- ============================================================
CREATE TEMP TABLE inv_test_results (
  test_case  text,
  int_value  int,
  text_value text
);

DO $$
DECLARE
  v_user1_id   uuid;
  v_user2_id   uuid;
  v_user3_id   uuid;
  v_partner_id uuid;
  v_party_id   uuid;
  v_event1_id  uuid;
  v_event2_id  uuid;
  v_ticket1_id uuid;
  v_ticket2_id uuid;
  v_app_id     uuid;
BEGIN
  -- Users
  v_user1_id := tests.create_supabase_user('inv_test_free_user_1');
  v_user2_id := tests.create_supabase_user('inv_test_free_user_2');
  v_user3_id := tests.create_supabase_user('inv_test_paid_user_1');

  INSERT INTO public.user_profiles (id, name, birth_date, gender, username)
  VALUES
    (v_user1_id, 'INV Test User 1', '2000-01-01', 'male',   'inv_test_free_user_1'),
    (v_user2_id, 'INV Test User 2', '2001-02-02', 'female', 'inv_test_free_user_2'),
    (v_user3_id, 'INV Test User 3', '2000-03-03', 'male',   'inv_test_paid_user_1')
  ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, birth_date = EXCLUDED.birth_date;

  -- Partner / Party
  INSERT INTO public.partners (name)
  VALUES ('INV Test Partner')
  RETURNING id INTO v_partner_id;

  INSERT INTO public.parties (partner_id, title, min_confirmed_count, max_participants)
  VALUES (v_partner_id, 'INV Test Party', 0, 10)
  RETURNING id INTO v_party_id;

  -- Free event
  INSERT INTO public.events (party_id, start_time, end_time, min_confirmed_count, max_participants, status)
  VALUES (v_party_id, now() + interval '1 day', now() + interval '1 day 2 hours', 0, 10, 'scheduled')
  RETURNING id INTO v_event1_id;

  INSERT INTO public.tickets (event_id, name, quantity, price)
  VALUES (v_event1_id, 'Free Ticket', 10, 0)
  RETURNING id INTO v_ticket1_id;

  -- Paid event
  INSERT INTO public.events (party_id, start_time, end_time, min_confirmed_count, max_participants, status)
  VALUES (v_party_id, now() + interval '2 days', now() + interval '2 days 2 hours', 0, 10, 'scheduled')
  RETURNING id INTO v_event2_id;

  INSERT INTO public.tickets (event_id, name, quantity, price)
  VALUES (v_event2_id, 'Paid Ticket', 10, 10000)
  RETURNING id INTO v_ticket2_id;

  -- ──────────────────────────────────────────────────────────
  -- Case 1 + 2: apply_event with NULL payment_id (free event)
  --   Expected: status='approved', participant created by trigger
  -- ──────────────────────────────────────────────────────────
  SELECT public.apply_event(v_event1_id, v_ticket1_id, v_user1_id, NULL, 0, NULL)
  INTO v_app_id;

  INSERT INTO inv_test_results (test_case, text_value)
  SELECT 'free_apply_status', a.status
  FROM public.event_applications a
  WHERE a.id = v_app_id;

  INSERT INTO inv_test_results (test_case, int_value)
  SELECT 'free_apply_participant_count', count(*)::int
  FROM public.event_participants
  WHERE event_id = v_event1_id AND user_id = v_user1_id;

  -- ──────────────────────────────────────────────────────────
  -- Case 3: Direct INSERT with status='approved' → trigger must create participant
  -- ──────────────────────────────────────────────────────────
  INSERT INTO public.event_applications (event_id, ticket_id, user_id, status, payment_id, payment_amount)
  VALUES (v_event1_id, v_ticket1_id, v_user2_id, 'approved', NULL, 0)
  RETURNING id INTO v_app_id;

  INSERT INTO inv_test_results (test_case, int_value)
  SELECT 'direct_insert_approved_participant', count(*)::int
  FROM public.event_participants
  WHERE event_id = v_event1_id AND user_id = v_user2_id;

  -- ──────────────────────────────────────────────────────────
  -- Case 4: apply_event with non-null payment_id (paid event)
  --   Expected: status='paid' (unchanged behavior)
  -- ──────────────────────────────────────────────────────────
  SELECT public.apply_event(v_event2_id, v_ticket2_id, v_user3_id, 'pay_test_001', 10000, NULL)
  INTO v_app_id;

  INSERT INTO inv_test_results (test_case, text_value)
  SELECT 'paid_apply_status', a.status
  FROM public.event_applications a
  WHERE a.id = v_app_id;
END $$;

-- Test 1: free event apply → status='approved' (INV-05 fix)
SELECT results_eq(
  $$SELECT text_value FROM inv_test_results WHERE test_case = 'free_apply_status'$$,
  $$VALUES ('approved')$$,
  'INV-05 fix: apply_event(payment_id=NULL) → status=approved (not paid)'
);

-- Test 2: free event apply → participant created by trigger (INV-01 fix)
SELECT results_eq(
  $$SELECT int_value FROM inv_test_results WHERE test_case = 'free_apply_participant_count'$$,
  $$SELECT 1::int$$,
  'INV-01 fix: apply_event(payment_id=NULL) → trigger creates participant on INSERT'
);

-- Test 3: direct INSERT with status='approved' → trigger fires (INV-01 trigger fix)
SELECT results_eq(
  $$SELECT int_value FROM inv_test_results WHERE test_case = 'direct_insert_approved_participant'$$,
  $$SELECT 1::int$$,
  'INV-01 fix: direct INSERT with status=approved → trigger creates participant'
);

-- Test 4: paid event apply → status='paid' (existing behavior preserved)
SELECT results_eq(
  $$SELECT text_value FROM inv_test_results WHERE test_case = 'paid_apply_status'$$,
  $$VALUES ('paid')$$,
  'apply_event(payment_id NOT NULL) → status=paid (behavior preserved)'
);

-- Test 5: check_db_invariants passes after all operations above
SELECT ok(
  (SELECT (check_db_invariants())::json->>'passed' = 'true'),
  'check_db_invariants() passes after INV-01/INV-05 fix'
);

SELECT * FROM finish();
ROLLBACK;
