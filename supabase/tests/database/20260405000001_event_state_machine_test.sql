BEGIN;
SELECT plan(18);

SELECT tests.authenticate_as_service_role();

-- ============================================================
-- Shared test data setup
-- ============================================================

CREATE TEMP TABLE state_machine_setup (
  partner_id uuid,
  party_id   uuid
);

DO $$
DECLARE
  v_partner_id uuid;
  v_party_id   uuid;
BEGIN
  INSERT INTO public.partners (name)
  VALUES ('State Machine Test Partner')
  RETURNING id INTO v_partner_id;

  INSERT INTO public.parties (partner_id, title, min_confirmed_count, max_participants)
  VALUES (v_partner_id, 'State Machine Test Party', 0, 100)
  RETURNING id INTO v_party_id;

  INSERT INTO state_machine_setup (partner_id, party_id)
  VALUES (v_partner_id, v_party_id);
END $$;

-- ============================================================
-- Section 1: Schema Tests
-- Verify events table accepts all 5 status values and rejects invalid ones
-- ============================================================

-- Test 1: status='scheduled' accepted
SELECT lives_ok(
  format(
    $q$INSERT INTO public.events (party_id, start_time, end_time, min_confirmed_count, max_participants, status)
       VALUES (%L::uuid, now() + interval '1 day', now() + interval '1 day 2 hours', 0, 10, 'scheduled')$q$,
    (SELECT party_id FROM state_machine_setup)
  ),
  'events table: status=scheduled 허용됨'
);

-- Test 2: status='active' accepted
SELECT lives_ok(
  format(
    $q$INSERT INTO public.events (party_id, start_time, end_time, min_confirmed_count, max_participants, status)
       VALUES (%L::uuid, now() - interval '1 hour', now() + interval '1 hour', 0, 10, 'active')$q$,
    (SELECT party_id FROM state_machine_setup)
  ),
  'events table: status=active 허용됨'
);

-- Test 3: status='ongoing' accepted
SELECT lives_ok(
  format(
    $q$INSERT INTO public.events (party_id, start_time, end_time, min_confirmed_count, max_participants, status)
       VALUES (%L::uuid, now() - interval '2 hours', now() + interval '30 minutes', 0, 10, 'ongoing')$q$,
    (SELECT party_id FROM state_machine_setup)
  ),
  'events table: status=ongoing 허용됨'
);

-- Test 4: status='completed' accepted
SELECT lives_ok(
  format(
    $q$INSERT INTO public.events (party_id, start_time, end_time, min_confirmed_count, max_participants, status)
       VALUES (%L::uuid, now() - interval '2 days', now() - interval '1 day', 0, 10, 'completed')$q$,
    (SELECT party_id FROM state_machine_setup)
  ),
  'events table: status=completed 허용됨'
);

-- Test 5: status='cancelled' accepted
SELECT lives_ok(
  format(
    $q$INSERT INTO public.events (party_id, start_time, end_time, min_confirmed_count, max_participants, status)
       VALUES (%L::uuid, now() + interval '2 days', now() + interval '2 days 2 hours', 0, 10, 'cancelled')$q$,
    (SELECT party_id FROM state_machine_setup)
  ),
  'events table: status=cancelled 허용됨'
);

-- Test 6: invalid status rejected
SELECT throws_ok(
  format(
    $q$INSERT INTO public.events (party_id, start_time, end_time, min_confirmed_count, max_participants, status)
       VALUES (%L::uuid, now() + interval '3 days', now() + interval '3 days 2 hours', 0, 10, 'invalid_status')$q$,
    (SELECT party_id FROM state_machine_setup)
  ),
  '23514',
  null,
  'events table: 유효하지 않은 status 값 거부됨 (check constraint)'
);

-- ============================================================
-- Section 2: Cron Job State Transition Tests
-- ============================================================

CREATE TEMP TABLE cron_transition_results (
  label  text,
  status text
);

DO $$
DECLARE
  v_party_id          uuid;
  v_sched_to_active   uuid;
  v_active_to_ongoing uuid;
  v_ongoing_to_comp   uuid;
  v_no_premature      uuid;
BEGIN
  v_party_id := (SELECT party_id FROM state_machine_setup);

  -- Test 7 setup: scheduled → active (start_time within 30-min window, not yet started)
  INSERT INTO public.events (party_id, start_time, end_time, min_confirmed_count, max_participants, status)
  VALUES (v_party_id, now() + interval '10 minutes', now() + interval '2 hours', 0, 10, 'scheduled')
  RETURNING id INTO v_sched_to_active;

  -- Test 8 setup: active → ongoing (start_time in the past, event has started)
  INSERT INTO public.events (party_id, start_time, end_time, min_confirmed_count, max_participants, status)
  VALUES (v_party_id, now() - interval '1 minute', now() + interval '1 hour', 0, 10, 'active')
  RETURNING id INTO v_active_to_ongoing;

  -- Test 9 setup: ongoing → completed (end_time in the past)
  INSERT INTO public.events (party_id, start_time, end_time, min_confirmed_count, max_participants, status)
  VALUES (v_party_id, now() - interval '3 hours', now() - interval '1 minute', 0, 10, 'ongoing')
  RETURNING id INTO v_ongoing_to_comp;

  -- Test 10 setup: no premature transition (start_time far in the future, outside 30-min window)
  INSERT INTO public.events (party_id, start_time, end_time, min_confirmed_count, max_participants, status)
  VALUES (v_party_id, now() + interval '2 hours', now() + interval '4 hours', 0, 10, 'scheduled')
  RETURNING id INTO v_no_premature;

  -- Run cron SQL: scheduled → active (start_time - 30 min reached, not yet started)
  -- Fix #998: added AND start_time > now() upper bound to prevent already-started events
  -- from being set to active (they should go to ongoing instead)
  UPDATE public.events
  SET status = 'active'
  WHERE status = 'scheduled'
    AND start_time - interval '30 minutes' <= now()
    AND start_time > now()
    AND id = v_sched_to_active;

  -- Run cron SQL: active → ongoing (start_time reached)
  UPDATE public.events
  SET status = 'ongoing'
  WHERE status = 'active'
    AND start_time <= now()
    AND id = v_active_to_ongoing;

  -- Run cron SQL: ongoing → completed
  UPDATE public.events
  SET status = 'completed'
  WHERE status = 'ongoing'
    AND end_time < now()
    AND id = v_ongoing_to_comp;

  -- Run activate cron SQL on the far-future event (should not transition)
  -- Fix #998: added AND start_time > now() upper bound (matches production cron)
  UPDATE public.events
  SET status = 'active'
  WHERE status = 'scheduled'
    AND start_time - interval '30 minutes' <= now()
    AND start_time > now()
    AND id = v_no_premature;

  INSERT INTO cron_transition_results (label, status)
  SELECT
    CASE id
      WHEN v_sched_to_active   THEN 'sched_to_active'
      WHEN v_active_to_ongoing THEN 'active_to_ongoing'
      WHEN v_ongoing_to_comp   THEN 'ongoing_to_comp'
      WHEN v_no_premature      THEN 'no_premature'
    END,
    status
  FROM public.events
  WHERE id IN (v_sched_to_active, v_active_to_ongoing, v_ongoing_to_comp, v_no_premature);
END $$;

-- Test 7: scheduled → active
SELECT is(
  (SELECT status FROM cron_transition_results WHERE label = 'sched_to_active'),
  'active',
  '크론 전환: scheduled → active (start_time - 30min <= now())'
);

-- Test 8: active → ongoing
SELECT is(
  (SELECT status FROM cron_transition_results WHERE label = 'active_to_ongoing'),
  'ongoing',
  '크론 전환: active → ongoing (start_time <= now())'
);

-- Test 9: ongoing → completed
SELECT is(
  (SELECT status FROM cron_transition_results WHERE label = 'ongoing_to_comp'),
  'completed',
  '크론 전환: ongoing → completed (end_time < now())'
);

-- Test 10: no premature transition
SELECT is(
  (SELECT status FROM cron_transition_results WHERE label = 'no_premature'),
  'scheduled',
  '크론 전환 없음: start_time이 30분 이상 남은 scheduled 이벤트는 active로 전환되지 않음'
);

-- ============================================================
-- Section 3: apply_event() Status Gate Tests
-- ============================================================

-- Test 11: apply_event() on ongoing event → exception
CREATE TEMP TABLE apply_gate_setup_ongoing (
  event_id  uuid,
  ticket_id uuid,
  user_id   uuid
);

DO $$
DECLARE
  v_user_id   uuid;
  v_party_id  uuid;
  v_event_id  uuid;
  v_ticket_id uuid;
BEGIN
  v_user_id  := tests.create_supabase_user('state_gate_user_ongoing');
  v_party_id := (SELECT party_id FROM state_machine_setup);

  INSERT INTO public.events (party_id, start_time, end_time, min_confirmed_count, max_participants, status)
  VALUES (v_party_id, now() - interval '1 hour', now() + interval '30 minutes', 0, 10, 'ongoing')
  RETURNING id INTO v_event_id;

  INSERT INTO public.tickets (event_id, name, quantity, price)
  VALUES (v_event_id, 'Gate Ongoing Ticket', 10, 1000)
  RETURNING id INTO v_ticket_id;

  INSERT INTO apply_gate_setup_ongoing (event_id, ticket_id, user_id)
  VALUES (v_event_id, v_ticket_id, v_user_id);
END $$;

SELECT throws_ok(
  format(
    $q$SELECT public.apply_event(%L::uuid, %L::uuid, %L::uuid, 'gate_ongoing_001', 1000, null)$q$,
    (SELECT event_id  FROM apply_gate_setup_ongoing),
    (SELECT ticket_id FROM apply_gate_setup_ongoing),
    (SELECT user_id   FROM apply_gate_setup_ongoing)
  ),
  'P0001',
  null,
  'apply_event(): ongoing 상태 이벤트에 신청 시 예외 발생'
);

-- Test 12: apply_event() on completed event → exception
CREATE TEMP TABLE apply_gate_setup_completed (
  event_id  uuid,
  ticket_id uuid,
  user_id   uuid
);

DO $$
DECLARE
  v_user_id   uuid;
  v_party_id  uuid;
  v_event_id  uuid;
  v_ticket_id uuid;
BEGIN
  v_user_id  := tests.create_supabase_user('state_gate_user_completed');
  v_party_id := (SELECT party_id FROM state_machine_setup);

  INSERT INTO public.events (party_id, start_time, end_time, min_confirmed_count, max_participants, status)
  VALUES (v_party_id, now() - interval '2 days', now() - interval '1 day', 0, 10, 'completed')
  RETURNING id INTO v_event_id;

  INSERT INTO public.tickets (event_id, name, quantity, price)
  VALUES (v_event_id, 'Gate Completed Ticket', 10, 1000)
  RETURNING id INTO v_ticket_id;

  INSERT INTO apply_gate_setup_completed (event_id, ticket_id, user_id)
  VALUES (v_event_id, v_ticket_id, v_user_id);
END $$;

SELECT throws_ok(
  format(
    $q$SELECT public.apply_event(%L::uuid, %L::uuid, %L::uuid, 'gate_completed_001', 1000, null)$q$,
    (SELECT event_id  FROM apply_gate_setup_completed),
    (SELECT ticket_id FROM apply_gate_setup_completed),
    (SELECT user_id   FROM apply_gate_setup_completed)
  ),
  'P0001',
  null,
  'apply_event(): completed 상태 이벤트에 신청 시 예외 발생'
);

-- Test 13: apply_event() on active event → succeeds
CREATE TEMP TABLE apply_gate_setup_active (
  event_id  uuid,
  ticket_id uuid,
  user_id   uuid
);

DO $$
DECLARE
  v_user_id   uuid;
  v_party_id  uuid;
  v_event_id  uuid;
  v_ticket_id uuid;
BEGIN
  v_user_id  := tests.create_supabase_user('state_gate_user_active');
  v_party_id := (SELECT party_id FROM state_machine_setup);

  INSERT INTO public.events (party_id, start_time, end_time, min_confirmed_count, max_participants, status)
  VALUES (v_party_id, now() - interval '5 minutes', now() + interval '2 hours', 0, 10, 'active')
  RETURNING id INTO v_event_id;

  INSERT INTO public.tickets (event_id, name, quantity, price)
  VALUES (v_event_id, 'Gate Active Ticket', 10, 1000)
  RETURNING id INTO v_ticket_id;

  INSERT INTO apply_gate_setup_active (event_id, ticket_id, user_id)
  VALUES (v_event_id, v_ticket_id, v_user_id);
END $$;

SELECT lives_ok(
  format(
    $q$SELECT public.apply_event(%L::uuid, %L::uuid, %L::uuid, 'gate_active_001', 1000, null)$q$,
    (SELECT event_id  FROM apply_gate_setup_active),
    (SELECT ticket_id FROM apply_gate_setup_active),
    (SELECT user_id   FROM apply_gate_setup_active)
  ),
  'apply_event(): active 상태 이벤트에 신청 성공'
);

-- Test 14: apply_event() on scheduled event → succeeds
CREATE TEMP TABLE apply_gate_setup_scheduled (
  event_id  uuid,
  ticket_id uuid,
  user_id   uuid
);

DO $$
DECLARE
  v_user_id   uuid;
  v_party_id  uuid;
  v_event_id  uuid;
  v_ticket_id uuid;
BEGIN
  v_user_id  := tests.create_supabase_user('state_gate_user_scheduled');
  v_party_id := (SELECT party_id FROM state_machine_setup);

  INSERT INTO public.events (party_id, start_time, end_time, min_confirmed_count, max_participants, status)
  VALUES (v_party_id, now() + interval '1 day', now() + interval '1 day 2 hours', 0, 10, 'scheduled')
  RETURNING id INTO v_event_id;

  INSERT INTO public.tickets (event_id, name, quantity, price)
  VALUES (v_event_id, 'Gate Scheduled Ticket', 10, 1000)
  RETURNING id INTO v_ticket_id;

  INSERT INTO apply_gate_setup_scheduled (event_id, ticket_id, user_id)
  VALUES (v_event_id, v_ticket_id, v_user_id);
END $$;

SELECT lives_ok(
  format(
    $q$SELECT public.apply_event(%L::uuid, %L::uuid, %L::uuid, 'gate_scheduled_001', 1000, null)$q$,
    (SELECT event_id  FROM apply_gate_setup_scheduled),
    (SELECT ticket_id FROM apply_gate_setup_scheduled),
    (SELECT user_id   FROM apply_gate_setup_scheduled)
  ),
  'apply_event(): scheduled 상태 이벤트에 신청 성공'
);

-- Test 15: apply_event() on cancelled event → exception
CREATE TEMP TABLE apply_gate_setup_cancelled (
  event_id  uuid,
  ticket_id uuid,
  user_id   uuid
);

DO $$
DECLARE
  v_user_id   uuid;
  v_party_id  uuid;
  v_event_id  uuid;
  v_ticket_id uuid;
BEGIN
  v_user_id  := tests.create_supabase_user('state_gate_user_cancelled');
  v_party_id := (SELECT party_id FROM state_machine_setup);

  INSERT INTO public.events (party_id, start_time, end_time, min_confirmed_count, max_participants, status)
  VALUES (v_party_id, now() + interval '2 days', now() + interval '2 days 2 hours', 0, 10, 'cancelled')
  RETURNING id INTO v_event_id;

  INSERT INTO public.tickets (event_id, name, quantity, price)
  VALUES (v_event_id, 'Gate Cancelled Ticket', 10, 1000)
  RETURNING id INTO v_ticket_id;

  INSERT INTO apply_gate_setup_cancelled (event_id, ticket_id, user_id)
  VALUES (v_event_id, v_ticket_id, v_user_id);
END $$;

SELECT throws_ok(
  format(
    $q$SELECT public.apply_event(%L::uuid, %L::uuid, %L::uuid, 'gate_cancelled_001', 1000, null)$q$,
    (SELECT event_id  FROM apply_gate_setup_cancelled),
    (SELECT ticket_id FROM apply_gate_setup_cancelled),
    (SELECT user_id   FROM apply_gate_setup_cancelled)
  ),
  'P0001',
  null,
  'apply_event(): cancelled 상태 이벤트에 신청 시 예외 발생'
);

-- ============================================================
-- Section 4: Event Pipeline Trigger Test
-- Verify event_cancelled is produced in PGMQ when status → cancelled
-- ============================================================

CREATE TEMP TABLE pipeline_setup (
  event_id uuid
);

DO $$
DECLARE
  v_party_id uuid;
  v_event_id uuid;
BEGIN
  v_party_id := (SELECT party_id FROM state_machine_setup);

  INSERT INTO public.events (party_id, start_time, end_time, min_confirmed_count, max_participants, status)
  VALUES (v_party_id, now() + interval '1 day', now() + interval '1 day 2 hours', 0, 10, 'active')
  RETURNING id INTO v_event_id;

  INSERT INTO pipeline_setup (event_id) VALUES (v_event_id);
END $$;

-- Trigger the pipeline by transitioning status to cancelled
UPDATE public.events
SET status = 'cancelled'
WHERE id = (SELECT event_id FROM pipeline_setup);

-- Read messages from q_notifications and check for event_cancelled
CREATE TEMP TABLE pipeline_queue_messages AS
SELECT *
FROM public.pgmq_read('q_notifications', 60, 1000) AS payload(payload);

-- Test 16: event_cancelled message produced in q_notifications
SELECT is(
  (
    SELECT count(*)::int
    FROM pipeline_queue_messages
    WHERE payload->'message'->>'event_type' = 'event_cancelled'
      AND payload->'message'->'metadata'->>'source_id' = (SELECT event_id::text FROM pipeline_setup)
  ),
  1,
  '이벤트 파이프라인: active → cancelled 전환 시 q_notifications에 event_cancelled 메시지 생성됨'
);

-- Test 17: the message source_table is 'events'
SELECT is(
  (
    SELECT payload->'message'->'metadata'->>'source_table'
    FROM pipeline_queue_messages
    WHERE payload->'message'->>'event_type' = 'event_cancelled'
      AND payload->'message'->'metadata'->>'source_id' = (SELECT event_id::text FROM pipeline_setup)
    LIMIT 1
  ),
  'events',
  '이벤트 파이프라인: event_cancelled 메시지의 source_table이 events임'
);

-- Test 18: event_cancelled is NOT produced when status changes from active to ongoing (non-cancel transition)
CREATE TEMP TABLE pipeline_non_cancel_setup (
  event_id uuid
);

DO $$
DECLARE
  v_party_id uuid;
  v_event_id uuid;
BEGIN
  v_party_id := (SELECT party_id FROM state_machine_setup);

  INSERT INTO public.events (party_id, start_time, end_time, min_confirmed_count, max_participants, status)
  VALUES (v_party_id, now() - interval '35 minutes', now() + interval '1 hour', 0, 10, 'active')
  RETURNING id INTO v_event_id;

  INSERT INTO pipeline_non_cancel_setup (event_id) VALUES (v_event_id);
END $$;

UPDATE public.events
SET status = 'ongoing'
WHERE id = (SELECT event_id FROM pipeline_non_cancel_setup);

CREATE TEMP TABLE pipeline_non_cancel_messages AS
SELECT *
FROM public.pgmq_read('q_notifications', 60, 1000) AS payload(payload);

SELECT is(
  (
    SELECT count(*)::int
    FROM pipeline_non_cancel_messages
    WHERE payload->'message'->>'event_type' = 'event_cancelled'
      AND payload->'message'->'metadata'->>'source_id' = (SELECT event_id::text FROM pipeline_non_cancel_setup)
  ),
  0,
  '이벤트 파이프라인: active → ongoing 전환 시 event_cancelled 메시지가 생성되지 않음'
);

SELECT * FROM finish();
ROLLBACK;
