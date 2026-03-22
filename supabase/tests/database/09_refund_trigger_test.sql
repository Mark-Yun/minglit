BEGIN;
SELECT plan(4);

SELECT tests.authenticate_as_service_role();

CREATE TEMP TABLE refund_results (
  status text,
  rejection_reason text,
  refund_status text
);

DO $$
DECLARE
  v_user_id uuid;
  v_partner_id uuid;
  v_party_id uuid;
  v_event_id uuid;
  v_ticket_id uuid;
  v_verification_id uuid;
  v_application_id uuid;
  v_submission_id uuid;
  v_reason text := 'Invalid ID Proof';
BEGIN
  v_user_id := tests.create_supabase_user('refund_user');

  INSERT INTO public.partners (name)
  VALUES ('Refund Partner')
  RETURNING id INTO v_partner_id;

  INSERT INTO public.parties (partner_id, title, min_confirmed_count, max_participants)
  VALUES (v_partner_id, 'Refund Party', 0, 10)
  RETURNING id INTO v_party_id;

  INSERT INTO public.events (party_id, start_time, end_time, min_confirmed_count, max_participants)
  VALUES (v_party_id, now() + interval '1 day', now() + interval '1 day 2 hours', 0, 10)
  RETURNING id INTO v_event_id;

  INSERT INTO public.tickets (event_id, name, quantity, price)
  VALUES (v_event_id, 'Refund Ticket', 10, 1000)
  RETURNING id INTO v_ticket_id;

  INSERT INTO public.verifications (partner_id, category, internal_name, display_name)
  VALUES (v_partner_id, 'career', 'refund_verification', 'Refund Verification')
  RETURNING id INTO v_verification_id;

  INSERT INTO public.event_applications (
    event_id,
    ticket_id,
    user_id,
    status,
    payment_id,
    payment_amount
  )
  VALUES (
    v_event_id,
    v_ticket_id,
    v_user_id,
    'pending_review',
    'payment_refund_1',
    5000
  )
  RETURNING id INTO v_application_id;

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
    v_user_id,
    v_verification_id,
    v_application_id,
    'pending',
    '{"proof":"test"}'::jsonb
  )
  RETURNING id INTO v_submission_id;

  -- Fix #301: admin_comment column dropped
  UPDATE public.verification_submissions
  SET status = 'rejected'
  WHERE id = v_submission_id;

  INSERT INTO refund_results (status, rejection_reason, refund_status)
  SELECT status, rejection_reason, refund_status
  FROM public.event_applications
  WHERE id = v_application_id;
END $$;

SELECT is(
  (SELECT status FROM refund_results),
  'rejected',
  'Application status synced to rejected'
);

SELECT is(
  (SELECT rejection_reason FROM refund_results),
  'Invalid ID Proof',
  'Rejection reason synced to application'
);

SELECT is(
  (SELECT refund_status FROM refund_results),
  'requested',
  'Refund status requested when payment exists'
);

CREATE TEMP TABLE refund_edge_results (
  refund_status text
);

DO $$
DECLARE
  v_user_id uuid;
  v_partner_id uuid;
  v_party_id uuid;
  v_event_id uuid;
  v_ticket_id uuid;
  v_application_id uuid;
BEGIN
  v_user_id := tests.create_supabase_user('refund_user_no_payment');

  INSERT INTO public.partners (name)
  VALUES ('Refund Partner No Payment')
  RETURNING id INTO v_partner_id;

  INSERT INTO public.parties (partner_id, title, min_confirmed_count, max_participants)
  VALUES (v_partner_id, 'Refund Party No Payment', 0, 10)
  RETURNING id INTO v_party_id;

  INSERT INTO public.events (party_id, start_time, end_time, min_confirmed_count, max_participants)
  VALUES (v_party_id, now() + interval '2 days', now() + interval '2 days 2 hours', 0, 10)
  RETURNING id INTO v_event_id;

  INSERT INTO public.tickets (event_id, name, quantity, price)
  VALUES (v_event_id, 'Refund Ticket No Payment', 10, 1000)
  RETURNING id INTO v_ticket_id;

  INSERT INTO public.event_applications (
    event_id,
    ticket_id,
    user_id,
    status
  )
  VALUES (
    v_event_id,
    v_ticket_id,
    v_user_id,
    'pending_review'
  )
  RETURNING id INTO v_application_id;

  UPDATE public.event_applications
  SET status = 'rejected'
  WHERE id = v_application_id;

  INSERT INTO refund_edge_results (refund_status)
  SELECT refund_status
  FROM public.event_applications
  WHERE id = v_application_id;
END $$;

SELECT is(
  (SELECT refund_status FROM refund_edge_results),
  'none',
  'Refund status remains none without payment_id'
);

SELECT * FROM finish();
ROLLBACK;
