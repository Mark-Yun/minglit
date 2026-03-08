BEGIN;
SELECT plan(9);

SELECT tests.authenticate_as_service_role();

CREATE TEMP TABLE updated_at_results (
  before_at timestamptz,
  after_at timestamptz
);

DO $$
DECLARE
  v_partner_id uuid;
  v_before timestamptz;
  v_after timestamptz;
BEGIN
  INSERT INTO public.partners (name, updated_at)
  VALUES ('Updated At Partner', '2000-01-01T00:00:00Z')
  RETURNING id, updated_at INTO v_partner_id, v_before;

  PERFORM tests.freeze_time('2000-01-01T00:00:00Z');

  UPDATE public.partners
  SET name = 'Updated At Partner v2'
  WHERE id = v_partner_id;

  SELECT updated_at INTO v_after
  FROM public.partners
  WHERE id = v_partner_id;

  PERFORM tests.unfreeze_time();

  INSERT INTO updated_at_results (before_at, after_at)
  VALUES (v_before, v_after);
END $$;

SELECT ok(
  (SELECT after_at > before_at FROM updated_at_results),
  'updated_at updates on change'
);

CREATE TEMP TABLE capacity_setup (
  partner_id uuid,
  party_id uuid,
  event_id uuid
);

DO $$
DECLARE
  v_partner_id uuid;
  v_party_id uuid;
  v_event_id uuid;
BEGIN
  INSERT INTO public.partners (name)
  VALUES ('Capacity Partner')
  RETURNING id INTO v_partner_id;

  INSERT INTO public.parties (partner_id, title, min_confirmed_count, max_participants)
  VALUES (v_partner_id, 'Capacity Party', 0, 0)
  RETURNING id INTO v_party_id;

  INSERT INTO public.events (party_id, start_time, end_time, min_confirmed_count, max_participants)
  VALUES (v_party_id, now() + interval '4 days', now() + interval '4 days 2 hours', 0, 1)
  RETURNING id INTO v_event_id;

  INSERT INTO capacity_setup (partner_id, party_id, event_id)
  VALUES (v_partner_id, v_party_id, v_event_id);
END $$;

INSERT INTO public.ticket_templates (party_id, name, quantity, price)
VALUES ((SELECT party_id FROM capacity_setup), 'Capacity Template', 5, 1000);

SELECT is(
  (SELECT max_participants FROM public.parties WHERE id = (SELECT party_id FROM capacity_setup)),
  5,
  'Party capacity syncs to ticket templates'
);

UPDATE public.ticket_templates
SET quantity = 8
WHERE party_id = (SELECT party_id FROM capacity_setup);

SELECT is(
  (SELECT max_participants FROM public.parties WHERE id = (SELECT party_id FROM capacity_setup)),
  8,
  'Party capacity updates when templates change'
);

INSERT INTO public.tickets (event_id, name, quantity, price)
VALUES ((SELECT event_id FROM capacity_setup), 'Capacity Ticket', 3, 1000);

SELECT is(
  (SELECT max_participants FROM public.events WHERE id = (SELECT event_id FROM capacity_setup)),
  3,
  'Event capacity syncs to tickets'
);

UPDATE public.tickets
SET quantity = 6
WHERE event_id = (SELECT event_id FROM capacity_setup);

SELECT is(
  (SELECT max_participants FROM public.events WHERE id = (SELECT event_id FROM capacity_setup)),
  6,
  'Event capacity updates when tickets change'
);

CREATE TEMP TABLE auto_approval_setup (
  user_id uuid,
  partner_id uuid,
  party_id uuid,
  event_id uuid,
  ticket_id uuid,
  verification_id uuid,
  application_id uuid,
  submission_id uuid
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
BEGIN
  v_user_id := tests.create_supabase_user('auto_approval_user');

  INSERT INTO public.partners (name)
  VALUES ('Auto Approval Partner')
  RETURNING id INTO v_partner_id;

  INSERT INTO public.parties (partner_id, title, min_confirmed_count, max_participants)
  VALUES (v_partner_id, 'Auto Approval Party', 0, 10)
  RETURNING id INTO v_party_id;

  INSERT INTO public.events (party_id, start_time, end_time, min_confirmed_count, max_participants)
  VALUES (v_party_id, now() + interval '5 days', now() + interval '5 days 2 hours', 0, 10)
  RETURNING id INTO v_event_id;

  INSERT INTO public.tickets (event_id, name, quantity, price)
  VALUES (v_event_id, 'Auto Approval Ticket', 10, 1000)
  RETURNING id INTO v_ticket_id;

  INSERT INTO public.verifications (partner_id, category, internal_name, display_name)
  VALUES (v_partner_id, 'career', 'auto_approval_verification', 'Auto Approval Verification')
  RETURNING id INTO v_verification_id;

  PERFORM tests.authenticate_as('auto_approval_user');

  INSERT INTO public.event_applications (event_id, ticket_id, user_id, status)
  VALUES (v_event_id, v_ticket_id, v_user_id, 'pending_review')
  RETURNING id INTO v_application_id;

  PERFORM tests.authenticate_as_service_role();

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
    '{"proof":"auto"}'::jsonb
  )
  RETURNING id INTO v_submission_id;

  INSERT INTO auto_approval_setup (
    user_id,
    partner_id,
    party_id,
    event_id,
    ticket_id,
    verification_id,
    application_id,
    submission_id
  )
  VALUES (
    v_user_id,
    v_partner_id,
    v_party_id,
    v_event_id,
    v_ticket_id,
    v_verification_id,
    v_application_id,
    v_submission_id
  );
END $$;

UPDATE public.verification_submissions
SET status = 'approved'
WHERE id = (SELECT submission_id FROM auto_approval_setup);

SELECT is(
  (SELECT status FROM public.event_applications WHERE id = (SELECT application_id FROM auto_approval_setup)),
  'approved',
  'Application auto-approves on verification approval'
);

SELECT ok(
  (
    SELECT exists (
      SELECT 1
      FROM public.partner_verified_users
      WHERE submission_id = (SELECT submission_id FROM auto_approval_setup)
    )
  ),
  'Verified user record created'
);

SELECT ok(
  (
    SELECT exists (
      SELECT 1
      FROM public.event_participants
      WHERE application_id = (SELECT application_id FROM auto_approval_setup)
    )
  ),
  'Ticket issued on application approval'
);

UPDATE public.verification_submissions
SET status = 'rejected',
    admin_comment = 'Auto revoke'
WHERE id = (SELECT submission_id FROM auto_approval_setup);

SELECT ok(
  (
    SELECT not exists (
      SELECT 1
      FROM public.partner_verified_users
      WHERE submission_id = (SELECT submission_id FROM auto_approval_setup)
    )
  ),
  'Verified user removed on rejection'
);

SELECT * FROM finish();
ROLLBACK;
