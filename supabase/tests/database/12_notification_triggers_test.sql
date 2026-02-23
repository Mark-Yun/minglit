-- Tests for notification triggers (T4-T7), CHECK constraint (T0), cron jobs (T3/T8), pgmq_send wrapper
BEGIN;
SELECT plan(15);

SELECT tests.authenticate_as_service_role();

-- ============================================================
-- PART 1: Schema & Infrastructure Tests
-- ============================================================

-- T0: pgmq_send wrapper function exists
SELECT has_function('pgmq_send');

-- T3: process-notifications cron job registered
SET ROLE postgres;
SELECT is(
  (SELECT count(*)::int FROM cron.job WHERE jobname = 'process-notifications'),
  1,
  'process-notifications cron job is registered'
);
-- T8: send-event-reminders cron job registered
SELECT is(
  (SELECT count(*)::int FROM cron.job WHERE jobname = 'send-event-reminders'),
  1,
  'send-event-reminders cron job is registered'
);
RESET ROLE;

-- T8: reminder_sent_at column exists
SELECT has_column('event_participants', 'reminder_sent_at');

-- T8: send_event_reminders function exists
SELECT has_function('send_event_reminders');

-- ============================================================
-- PART 2: Trigger Functional Tests — Setup
-- ============================================================

CREATE TEMP TABLE trigger_test_setup (
  event_id uuid,
  ticket_id uuid,
  partner_id uuid,
  partner_user_id uuid,
  applicant_user_id uuid,
  verification_id uuid
);

DO $$
DECLARE
  v_partner_id uuid;
  v_partner_user_id uuid;
  v_applicant_user_id uuid;
  v_party_id uuid;
  v_event_id uuid;
  v_ticket_id uuid;
  v_verification_id uuid;
BEGIN
  -- Users
  v_partner_user_id := tests.create_supabase_user('trigger_partner_user');
  v_applicant_user_id := tests.create_supabase_user('trigger_applicant_user');

  -- Partner + member permission
  INSERT INTO public.partners (name)
  VALUES ('Trigger Test Partner')
  RETURNING id INTO v_partner_id;

  INSERT INTO public.partner_member_permissions (partner_id, user_id, role)
  VALUES (v_partner_id, v_partner_user_id, 'owner');

  -- Party + Event + Ticket
  INSERT INTO public.parties (partner_id, title, min_confirmed_count, max_participants)
  VALUES (v_partner_id, 'Trigger Test Party', 0, 10)
  RETURNING id INTO v_party_id;

  INSERT INTO public.events (party_id, title, start_time, end_time, min_confirmed_count, max_participants)
  VALUES (v_party_id, 'Trigger Test Event', now() + interval '3 days', now() + interval '3 days 2 hours', 0, 10)
  RETURNING id INTO v_event_id;

  INSERT INTO public.tickets (event_id, name, quantity, price)
  VALUES (v_event_id, 'Trigger Test Ticket', 10, 1000)
  RETURNING id INTO v_ticket_id;

  -- Verification
  INSERT INTO public.verifications (partner_id, category, internal_name, display_name)
  VALUES (v_partner_id, 'career', 'trigger_test_verification', 'Trigger Test Verification')
  RETURNING id INTO v_verification_id;

  INSERT INTO trigger_test_setup
  VALUES (v_event_id, v_ticket_id, v_partner_id, v_partner_user_id, v_applicant_user_id, v_verification_id);
END $$;

-- ============================================================
-- PART 3: T6 — New application triggers partner notification
-- ============================================================

-- Drain queue first (clear seed/setup noise)
CREATE TEMP TABLE _drain AS
SELECT * FROM public.pgmq_read('q_notifications', 60, 1000) AS payload(payload);
DROP TABLE _drain;

INSERT INTO public.event_applications (event_id, ticket_id, user_id, status)
VALUES (
  (SELECT event_id FROM trigger_test_setup),
  (SELECT ticket_id FROM trigger_test_setup),
  (SELECT applicant_user_id FROM trigger_test_setup),
  'pending'
);

CREATE TEMP TABLE t6_messages AS
SELECT * FROM public.pgmq_read('q_notifications', 60, 1000) AS payload(payload);

SELECT ok(
  (SELECT count(*) > 0 FROM t6_messages WHERE payload->'message'->>'type' = 'new_application'),
  'T6: INSERT into event_applications enqueues new_application notification'
);

SELECT is(
  (SELECT payload->'message'->>'user_id' FROM t6_messages WHERE payload->'message'->>'type' = 'new_application' LIMIT 1),
  (SELECT partner_user_id::text FROM trigger_test_setup),
  'T6: new_application notification targets partner member'
);

DROP TABLE t6_messages;

-- ============================================================
-- PART 4: T4 — Application status change triggers
-- ============================================================

-- Drain queue
CREATE TEMP TABLE _drain2 AS
SELECT * FROM public.pgmq_read('q_notifications', 60, 1000) AS payload(payload);
DROP TABLE _drain2;

-- Approve the application
UPDATE public.event_applications
SET status = 'approved'
WHERE event_id = (SELECT event_id FROM trigger_test_setup)
  AND user_id = (SELECT applicant_user_id FROM trigger_test_setup);

CREATE TEMP TABLE t4_approved AS
SELECT * FROM public.pgmq_read('q_notifications', 60, 1000) AS payload(payload);

SELECT ok(
  (SELECT count(*) > 0 FROM t4_approved WHERE payload->'message'->>'type' = 'application_approved'),
  'T4: Approving application enqueues application_approved notification'
);

SELECT is(
  (SELECT payload->'message'->>'user_id' FROM t4_approved WHERE payload->'message'->>'type' = 'application_approved' LIMIT 1),
  (SELECT applicant_user_id::text FROM trigger_test_setup),
  'T4: application_approved targets the applicant user'
);

DROP TABLE t4_approved;

-- Drain and reject
CREATE TEMP TABLE _drain3 AS
SELECT * FROM public.pgmq_read('q_notifications', 60, 1000) AS payload(payload);
DROP TABLE _drain3;

UPDATE public.event_applications
SET status = 'rejected'
WHERE event_id = (SELECT event_id FROM trigger_test_setup)
  AND user_id = (SELECT applicant_user_id FROM trigger_test_setup);

CREATE TEMP TABLE t4_rejected AS
SELECT * FROM public.pgmq_read('q_notifications', 60, 1000) AS payload(payload);

SELECT ok(
  (SELECT count(*) > 0 FROM t4_rejected WHERE payload->'message'->>'type' = 'application_rejected'),
  'T4: Rejecting application enqueues application_rejected notification'
);

DROP TABLE t4_rejected;

-- Drain and test no-op (same status update)
CREATE TEMP TABLE _drain4 AS
SELECT * FROM public.pgmq_read('q_notifications', 60, 1000) AS payload(payload);
DROP TABLE _drain4;

UPDATE public.event_applications
SET status = 'rejected'
WHERE event_id = (SELECT event_id FROM trigger_test_setup)
  AND user_id = (SELECT applicant_user_id FROM trigger_test_setup);

CREATE TEMP TABLE t4_noop AS
SELECT * FROM public.pgmq_read('q_notifications', 60, 1000) AS payload(payload);

SELECT is(
  (SELECT count(*)::int FROM t4_noop WHERE payload->'message'->>'type' IN ('application_approved', 'application_rejected')),
  0,
  'T4: Same-status update does not enqueue notification'
);

DROP TABLE t4_noop;

-- ============================================================
-- PART 5: T5 — Event cancellation triggers
-- ============================================================

-- Reset application to approved for cancellation test
UPDATE public.event_applications
SET status = 'approved'
WHERE event_id = (SELECT event_id FROM trigger_test_setup)
  AND user_id = (SELECT applicant_user_id FROM trigger_test_setup);

CREATE TEMP TABLE _drain5 AS
SELECT * FROM public.pgmq_read('q_notifications', 60, 1000) AS payload(payload);
DROP TABLE _drain5;

-- Cancel the event
UPDATE public.events
SET status = 'cancelled'
WHERE id = (SELECT event_id FROM trigger_test_setup);

CREATE TEMP TABLE t5_messages AS
SELECT * FROM public.pgmq_read('q_notifications', 60, 1000) AS payload(payload);

SELECT ok(
  (SELECT count(*) > 0 FROM t5_messages WHERE payload->'message'->>'type' = 'event_cancelled'),
  'T5: Cancelling event enqueues event_cancelled notification'
);

DROP TABLE t5_messages;

-- ============================================================
-- PART 6: T7 — Verification submission status triggers
-- ============================================================

-- Create a verification submission
DO $$
DECLARE
  v_submission_id uuid;
BEGIN
  INSERT INTO public.verification_submissions (
    partner_id, user_id, verification_id, status, snapshot_data
  )
  VALUES (
    (SELECT partner_id FROM trigger_test_setup),
    (SELECT applicant_user_id FROM trigger_test_setup),
    (SELECT verification_id FROM trigger_test_setup),
    'pending',
    '{"proof":"test"}'::jsonb
  );
END $$;

-- Drain queue
CREATE TEMP TABLE _drain6 AS
SELECT * FROM public.pgmq_read('q_notifications', 60, 1000) AS payload(payload);
DROP TABLE _drain6;

-- Approve verification
UPDATE public.verification_submissions
SET status = 'approved'
WHERE user_id = (SELECT applicant_user_id FROM trigger_test_setup)
  AND verification_id = (SELECT verification_id FROM trigger_test_setup);

CREATE TEMP TABLE t7_approved AS
SELECT * FROM public.pgmq_read('q_notifications', 60, 1000) AS payload(payload);

SELECT ok(
  (SELECT count(*) > 0 FROM t7_approved WHERE payload->'message'->>'type' = 'verification_approved'),
  'T7: Approving verification enqueues verification_approved notification'
);

DROP TABLE t7_approved;

-- Drain and test needs_correction
CREATE TEMP TABLE _drain7 AS
SELECT * FROM public.pgmq_read('q_notifications', 60, 1000) AS payload(payload);
DROP TABLE _drain7;

UPDATE public.verification_submissions
SET status = 'needs_correction'
WHERE user_id = (SELECT applicant_user_id FROM trigger_test_setup)
  AND verification_id = (SELECT verification_id FROM trigger_test_setup);

CREATE TEMP TABLE t7_correction AS
SELECT * FROM public.pgmq_read('q_notifications', 60, 1000) AS payload(payload);

SELECT ok(
  (SELECT count(*) > 0 FROM t7_correction WHERE payload->'message'->>'type' = 'verification_needs_correction'),
  'T7: needs_correction enqueues verification_needs_correction notification'
);

DROP TABLE t7_correction;

-- ============================================================
-- PART 7: T0 — CHECK constraint allows new statuses
-- ============================================================

-- This tests that payment_failed and payment_pending are accepted
-- We use a second user to avoid unique constraint conflicts
DO $$
DECLARE
  v_user2 uuid;
BEGIN
  v_user2 := tests.create_supabase_user('trigger_constraint_user');

  INSERT INTO public.event_applications (event_id, ticket_id, user_id, status)
  VALUES (
    (SELECT event_id FROM trigger_test_setup),
    (SELECT ticket_id FROM trigger_test_setup),
    v_user2,
    'payment_pending'
  );

  UPDATE public.event_applications
  SET status = 'payment_failed'
  WHERE user_id = v_user2;
END $$;

SELECT pass('T0: payment_pending and payment_failed accepted by CHECK constraint');

SELECT * FROM finish();
ROLLBACK;
