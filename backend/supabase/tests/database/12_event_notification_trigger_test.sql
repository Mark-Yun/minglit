BEGIN;
SELECT plan(5);

SELECT tests.authenticate_as_service_role();

CREATE TEMP TABLE notification_setup (
  event_id uuid,
  ticket_id uuid,
  approved_user_id uuid,
  pending_user_id uuid,
  rejected_user_id uuid
);

DO $$
DECLARE
  v_partner_id uuid;
  v_party_id uuid;
  v_event_id uuid;
  v_ticket_id uuid;
  v_approved_user_id uuid;
  v_pending_user_id uuid;
  v_rejected_user_id uuid;
BEGIN
  v_approved_user_id := tests.create_supabase_user('notify_approved_user');
  v_pending_user_id := tests.create_supabase_user('notify_pending_user');
  v_rejected_user_id := tests.create_supabase_user('notify_rejected_user');

  INSERT INTO public.partners (name)
  VALUES ('Notification Partner')
  RETURNING id INTO v_partner_id;

  INSERT INTO public.parties (partner_id, title, min_confirmed_count, max_participants)
  VALUES (v_partner_id, 'Notification Party', 0, 10)
  RETURNING id INTO v_party_id;

  INSERT INTO public.events (party_id, title, start_time, end_time, min_confirmed_count, max_participants)
  VALUES (
    v_party_id,
    'Notification Event',
    now() + interval '3 days',
    now() + interval '3 days 2 hours',
    0,
    10
  )
  RETURNING id INTO v_event_id;

  INSERT INTO public.tickets (event_id, name, quantity, price)
  VALUES (v_event_id, 'Notification Ticket', 10, 1000)
  RETURNING id INTO v_ticket_id;

  INSERT INTO public.event_applications (event_id, ticket_id, user_id, status)
  VALUES (v_event_id, v_ticket_id, v_approved_user_id, 'approved');

  INSERT INTO public.event_applications (event_id, ticket_id, user_id, status)
  VALUES (v_event_id, v_ticket_id, v_pending_user_id, 'pending');

  INSERT INTO public.event_applications (event_id, ticket_id, user_id, status)
  VALUES (v_event_id, v_ticket_id, v_rejected_user_id, 'rejected');

  INSERT INTO notification_setup (event_id, ticket_id, approved_user_id, pending_user_id, rejected_user_id)
  VALUES (v_event_id, v_ticket_id, v_approved_user_id, v_pending_user_id, v_rejected_user_id);
END $$;

UPDATE public.events
SET title = 'Notification Event Updated'
WHERE id = (SELECT event_id FROM notification_setup);

UPDATE public.events
SET description = '{"note":"no notify"}'::jsonb
WHERE id = (SELECT event_id FROM notification_setup);

CREATE TEMP TABLE notification_messages AS
SELECT *
FROM public.pgmq_read('q_notifications', 60, 1000) AS payload(payload);

SELECT is(
  (
    SELECT count(*)::int
    FROM notification_messages
    WHERE payload->'message'->>'type' = 'event_update'
      AND payload->'message'->'data'->>'event_id' = (SELECT event_id::text FROM notification_setup)
  ),
  2,
  'Event updates notify approved and pending applicants'
);

SELECT is(
  (
    SELECT count(distinct payload->'message'->>'user_id')::int
    FROM notification_messages
    WHERE payload->'message'->'data'->>'event_id' = (SELECT event_id::text FROM notification_setup)
  ),
  2,
  'Notification recipients are unique'
);

SELECT ok(
  (
    SELECT bool_and(
      payload->'message'->>'user_id' IN (
        (SELECT approved_user_id::text FROM notification_setup),
        (SELECT pending_user_id::text FROM notification_setup)
      )
    )
    FROM notification_messages
    WHERE payload->'message'->'data'->>'event_id' = (SELECT event_id::text FROM notification_setup)
  ),
  'Notifications only sent to approved or pending users'
);

SELECT is(
  (
    SELECT count(*)::int
    FROM notification_messages
    WHERE payload->'message'->'data'->>'event_id' = (SELECT event_id::text FROM notification_setup)
      AND payload->'message'->>'user_id' = (SELECT rejected_user_id::text FROM notification_setup)
  ),
  0,
  'Rejected applicants are not notified'
);

SELECT is(
  (
    SELECT count(*)::int
    FROM notification_messages
    WHERE payload->'message'->>'type' = 'event_update'
      AND payload->'message'->'data'->>'event_id' = (SELECT event_id::text FROM notification_setup)
  ),
  2,
  'Non-significant updates do not enqueue notifications'
);

SELECT * FROM finish();
ROLLBACK;
