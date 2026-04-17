-- Regression test for Fix #1515:
-- Verifies on_application_cancel trigger correctly removes event_participants
-- when an application status transitions to 'cancelled'.
-- Symmetric to issue_ticket_on_approval which inserts on approval.
--
-- Cases:
--   1. approved → cancelled : event_participants row deleted
--   2. cancelled → cancelled: no-op (WHEN clause OLD.status IS DISTINCT FROM 'cancelled' guards re-fire)
--   3. approved → rejected  : event_participants row preserved (trigger scoped to cancelled only)

BEGIN;
SELECT plan(4);

SELECT tests.authenticate_as_service_role();

-- ============================================================
-- Shared result capture table
-- ============================================================
CREATE TEMP TABLE cancel_trigger_results (
  test_case text,
  participant_count int
);

-- ============================================================
-- Case 1 + 2: approved → cancelled (deletion), then cancelled → cancelled (idempotency)
-- ============================================================
DO $$
DECLARE
  v_user_id    uuid;
  v_partner_id uuid;
  v_party_id   uuid;
  v_event_id   uuid;
  v_ticket_id  uuid;
  v_app_id     uuid;
BEGIN
  v_user_id := tests.create_supabase_user('cancel_trigger_user_1');

  INSERT INTO public.user_profiles (id, name, birth_date, gender, username)
  VALUES (v_user_id, 'Cancel Test User 1', '2000-01-01', 'male', 'cancel_trigger_user_1')
  ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, birth_date = EXCLUDED.birth_date;

  INSERT INTO public.partners (name)
  VALUES ('Cancel Trigger Partner 1')
  RETURNING id INTO v_partner_id;

  INSERT INTO public.parties (partner_id, title, min_confirmed_count, max_participants)
  VALUES (v_partner_id, 'Cancel Party 1', 0, 10)
  RETURNING id INTO v_party_id;

  INSERT INTO public.events (party_id, start_time, end_time, min_confirmed_count, max_participants)
  VALUES (v_party_id, now() + interval '1 day', now() + interval '1 day 2 hours', 0, 10)
  RETURNING id INTO v_event_id;

  INSERT INTO public.tickets (event_id, name, quantity, price)
  VALUES (v_event_id, 'Cancel Ticket 1', 10, 5000)
  RETURNING id INTO v_ticket_id;

  INSERT INTO public.event_applications (event_id, ticket_id, user_id, status)
  VALUES (v_event_id, v_ticket_id, v_user_id, 'pending_review')
  RETURNING id INTO v_app_id;

  -- Approve: issue_ticket_on_approval trigger inserts into event_participants
  UPDATE public.event_applications SET status = 'approved' WHERE id = v_app_id;

  INSERT INTO cancel_trigger_results (test_case, participant_count)
  SELECT 'before_cancel', count(*)::int
  FROM public.event_participants
  WHERE event_id = v_event_id AND user_id = v_user_id;

  -- Cancel: on_application_cancel trigger should delete from event_participants
  UPDATE public.event_applications SET status = 'cancelled' WHERE id = v_app_id;

  INSERT INTO cancel_trigger_results (test_case, participant_count)
  SELECT 'after_cancel', count(*)::int
  FROM public.event_participants
  WHERE event_id = v_event_id AND user_id = v_user_id;

  -- Manually re-insert participant to verify the WHEN guard actually
  -- prevents the trigger function from firing on cancelled → cancelled.
  -- Without this sentinel row, count=0 would be trivially true even if
  -- the trigger fired (nothing to delete), making the idempotency check meaningless.
  INSERT INTO public.event_participants (
    event_id, ticket_id, user_id, application_id, status, ticket_code
  ) VALUES (
    v_event_id, v_ticket_id, v_user_id, v_app_id, 'ticket_issued', 'IDMP0001'
  );

  -- Second cancel: WHEN (OLD.status IS DISTINCT FROM 'cancelled') prevents re-fire.
  -- If the trigger fired, it would delete the sentinel row (count → 0).
  -- If the WHEN guard works correctly, count stays 1.
  UPDATE public.event_applications SET status = 'cancelled' WHERE id = v_app_id;

  INSERT INTO cancel_trigger_results (test_case, participant_count)
  SELECT 'after_second_cancel', count(*)::int
  FROM public.event_participants
  WHERE event_id = v_event_id AND user_id = v_user_id;
END $$;

-- Pre-condition: participant exists after approval
SELECT is(
  (SELECT participant_count FROM cancel_trigger_results WHERE test_case = 'before_cancel'),
  1,
  'Participant row inserted after approval (pre-condition for cancel test)'
);

-- Fix #1515: approved → cancelled deletes participant
SELECT is(
  (SELECT participant_count FROM cancel_trigger_results WHERE test_case = 'after_cancel'),
  0,
  'approved → cancelled: event_participants row deleted by on_application_cancel trigger'
);

-- Idempotency: cancelled → cancelled does not re-fire trigger (sentinel row survives)
SELECT is(
  (SELECT participant_count FROM cancel_trigger_results WHERE test_case = 'after_second_cancel'),
  1,
  'cancelled → cancelled: WHEN clause prevents trigger re-fire, sentinel row preserved (count=1)'
);

-- ============================================================
-- Case 3: approved → rejected preserves event_participants
-- ============================================================
DO $$
DECLARE
  v_user_id    uuid;
  v_partner_id uuid;
  v_party_id   uuid;
  v_event_id   uuid;
  v_ticket_id  uuid;
  v_app_id     uuid;
BEGIN
  v_user_id := tests.create_supabase_user('cancel_trigger_user_2');

  INSERT INTO public.user_profiles (id, name, birth_date, gender, username)
  VALUES (v_user_id, 'Cancel Test User 2', '2001-06-15', 'female', 'cancel_trigger_user_2')
  ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, birth_date = EXCLUDED.birth_date;

  INSERT INTO public.partners (name)
  VALUES ('Cancel Trigger Partner 2')
  RETURNING id INTO v_partner_id;

  INSERT INTO public.parties (partner_id, title, min_confirmed_count, max_participants)
  VALUES (v_partner_id, 'Cancel Party 2', 0, 10)
  RETURNING id INTO v_party_id;

  INSERT INTO public.events (party_id, start_time, end_time, min_confirmed_count, max_participants)
  VALUES (v_party_id, now() + interval '2 days', now() + interval '2 days 2 hours', 0, 10)
  RETURNING id INTO v_event_id;

  INSERT INTO public.tickets (event_id, name, quantity, price)
  VALUES (v_event_id, 'Cancel Ticket 2', 10, 5000)
  RETURNING id INTO v_ticket_id;

  INSERT INTO public.event_applications (event_id, ticket_id, user_id, status)
  VALUES (v_event_id, v_ticket_id, v_user_id, 'pending_review')
  RETURNING id INTO v_app_id;

  -- Approve: issue_ticket_on_approval inserts into event_participants
  UPDATE public.event_applications SET status = 'approved' WHERE id = v_app_id;

  -- Reject: on_application_cancel trigger WHEN clause (NEW.status = 'cancelled') does NOT fire
  UPDATE public.event_applications SET status = 'rejected' WHERE id = v_app_id;

  INSERT INTO cancel_trigger_results (test_case, participant_count)
  SELECT 'after_reject', count(*)::int
  FROM public.event_participants
  WHERE event_id = v_event_id AND user_id = v_user_id;
END $$;

SELECT is(
  (SELECT participant_count FROM cancel_trigger_results WHERE test_case = 'after_reject'),
  1,
  'approved → rejected: event_participants row preserved (trigger scoped to cancelled only)'
);

SELECT * FROM finish();
ROLLBACK;
