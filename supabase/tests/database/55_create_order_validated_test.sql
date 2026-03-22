BEGIN;
SELECT plan(14);

SELECT tests.authenticate_as_service_role();

-- ============================================================
-- Setup: shared test data
-- ============================================================

DO $$
DECLARE
  v_partner_id uuid;
  v_party_id uuid;
  v_event_id uuid;
  v_ticket_id uuid;
  v_user_id uuid;
BEGIN
  INSERT INTO public.partners (name) VALUES ('COV Partner') RETURNING id INTO v_partner_id;

  INSERT INTO public.parties (partner_id, title, min_confirmed_count, max_participants)
  VALUES (v_partner_id, 'COV Party', 0, 50) RETURNING id INTO v_party_id;

  INSERT INTO public.events (party_id, start_time, end_time, max_participants, status)
  VALUES (v_party_id, now() + interval '1 day', now() + interval '1 day 2 hours', 50, 'scheduled')
  RETURNING id INTO v_event_id;

  INSERT INTO public.tickets (event_id, name, quantity, price)
  VALUES (v_event_id, 'Standard Ticket', 10, 15000)
  RETURNING id INTO v_ticket_id;

  -- Create a verified user
  v_user_id := tests.create_supabase_user('cov_test_user_1');
  UPDATE public.user_profiles SET is_verified = true WHERE id = v_user_id;

  -- Store IDs for later use
  INSERT INTO public.debug_logs (message, payload) VALUES (
    'cov_test_setup',
    jsonb_build_object(
      'partner_id', v_partner_id,
      'party_id', v_party_id,
      'event_id', v_event_id,
      'ticket_id', v_ticket_id,
      'user_id', v_user_id
    )
  );
END $$;

-- ============================================================
-- Test 1: Successful paid order returns success jsonb
-- ============================================================

CREATE TEMP TABLE cov_paid_result (result jsonb);

DO $$
DECLARE
  v_event_id uuid;
  v_ticket_id uuid;
  v_user_id uuid;
  v_result jsonb;
BEGIN
  SELECT (payload->>'event_id')::uuid, (payload->>'ticket_id')::uuid, (payload->>'user_id')::uuid
  INTO v_event_id, v_ticket_id, v_user_id
  FROM public.debug_logs WHERE message = 'cov_test_setup';

  v_result := public.create_order_validated(v_event_id, v_ticket_id, v_user_id);
  INSERT INTO cov_paid_result VALUES (v_result);
END $$;

SELECT is(
  (SELECT result->>'success' FROM cov_paid_result),
  'true',
  'Paid order: success=true returned'
);

SELECT isnt(
  (SELECT result->>'application_id' FROM cov_paid_result),
  null,
  'Paid order: application_id is not null'
);

SELECT is(
  (SELECT (result->>'amount')::int FROM cov_paid_result),
  15000,
  'Paid order: amount equals ticket.price=15000'
);

SELECT is(
  (SELECT result->>'requires_payment' FROM cov_paid_result),
  'true',
  'Paid order: requires_payment=true'
);

-- ============================================================
-- Test 2: Free ticket returns requires_payment=false
-- ============================================================

CREATE TEMP TABLE cov_free_result (result jsonb);

DO $$
DECLARE
  v_partner_id uuid;
  v_party_id uuid;
  v_event_id uuid;
  v_ticket_id uuid;
  v_user_id uuid;
  v_result jsonb;
BEGIN
  INSERT INTO public.partners (name) VALUES ('COV Free Partner') RETURNING id INTO v_partner_id;
  INSERT INTO public.parties (partner_id, title, min_confirmed_count, max_participants)
  VALUES (v_partner_id, 'COV Free Party', 0, 50) RETURNING id INTO v_party_id;
  INSERT INTO public.events (party_id, start_time, end_time, max_participants, status)
  VALUES (v_party_id, now() + interval '1 day', now() + interval '1 day 2 hours', 50, 'scheduled')
  RETURNING id INTO v_event_id;
  INSERT INTO public.tickets (event_id, name, quantity, price)
  VALUES (v_event_id, 'Free Ticket', 10, 0) RETURNING id INTO v_ticket_id;

  v_user_id := tests.create_supabase_user('cov_free_user');
  UPDATE public.user_profiles SET is_verified = true WHERE id = v_user_id;

  v_result := public.create_order_validated(v_event_id, v_ticket_id, v_user_id);
  INSERT INTO cov_free_result VALUES (v_result);
END $$;

SELECT is(
  (SELECT result->>'requires_payment' FROM cov_free_result),
  'false',
  'Free ticket: requires_payment=false'
);

SELECT is(
  (SELECT (result->>'amount')::int FROM cov_free_result),
  0,
  'Free ticket: amount=0'
);

-- ============================================================
-- Test 3: ALREADY_APPLIED returned on duplicate
-- ============================================================

CREATE TEMP TABLE cov_dup_result (result jsonb);

DO $$
DECLARE
  v_event_id uuid;
  v_ticket_id uuid;
  v_user_id uuid;
  v_result jsonb;
BEGIN
  SELECT (payload->>'event_id')::uuid, (payload->>'ticket_id')::uuid, (payload->>'user_id')::uuid
  INTO v_event_id, v_ticket_id, v_user_id
  FROM public.debug_logs WHERE message = 'cov_test_setup';

  -- Second attempt on same event+user (first was done in test 1)
  v_result := public.create_order_validated(v_event_id, v_ticket_id, v_user_id);
  INSERT INTO cov_dup_result VALUES (v_result);
END $$;

SELECT is(
  (SELECT result->>'error' FROM cov_dup_result),
  'ALREADY_APPLIED',
  'Duplicate application returns ALREADY_APPLIED'
);

-- ============================================================
-- Test 4: TICKET_SOLD_OUT when sold_count >= quantity
-- ============================================================

CREATE TEMP TABLE cov_soldout_result (result jsonb);

DO $$
DECLARE
  v_partner_id uuid;
  v_party_id uuid;
  v_event_id uuid;
  v_ticket_id uuid;
  v_user_id uuid;
  v_result jsonb;
BEGIN
  INSERT INTO public.partners (name) VALUES ('COV Soldout Partner') RETURNING id INTO v_partner_id;
  INSERT INTO public.parties (partner_id, title, min_confirmed_count, max_participants)
  VALUES (v_partner_id, 'COV Soldout Party', 0, 50) RETURNING id INTO v_party_id;
  INSERT INTO public.events (party_id, start_time, end_time, max_participants, status)
  VALUES (v_party_id, now() + interval '1 day', now() + interval '1 day 2 hours', 50, 'scheduled')
  RETURNING id INTO v_event_id;
  -- quantity=1, sold_count will be set to 1 directly (bypassing constraint via service_role)
  INSERT INTO public.tickets (event_id, name, quantity, price, sold_count)
  VALUES (v_event_id, 'Soldout Ticket', 1, 5000, 1) RETURNING id INTO v_ticket_id;

  v_user_id := tests.create_supabase_user('cov_soldout_user');
  UPDATE public.user_profiles SET is_verified = true WHERE id = v_user_id;

  v_result := public.create_order_validated(v_event_id, v_ticket_id, v_user_id);
  INSERT INTO cov_soldout_result VALUES (v_result);
END $$;

SELECT is(
  (SELECT result->>'error' FROM cov_soldout_result),
  'TICKET_SOLD_OUT',
  'sold_count >= quantity returns TICKET_SOLD_OUT'
);

-- ============================================================
-- Test 5: EVENT_NOT_FOUND for nonexistent event
-- ============================================================

SELECT is(
  (SELECT public.create_order_validated(gen_random_uuid(), gen_random_uuid(), gen_random_uuid())->>'error'),
  'EVENT_NOT_FOUND',
  'Nonexistent event returns EVENT_NOT_FOUND'
);

-- ============================================================
-- Test 6: TICKET_NOT_FOUND when ticket.event_id != p_event_id
-- ============================================================

CREATE TEMP TABLE cov_wrongticket_result (result jsonb);

DO $$
DECLARE
  v_partner_id uuid;
  v_party_id uuid;
  v_event_id_a uuid;
  v_event_id_b uuid;
  v_ticket_id_b uuid;
  v_user_id uuid;
  v_result jsonb;
BEGIN
  INSERT INTO public.partners (name) VALUES ('COV WrongTicket Partner') RETURNING id INTO v_partner_id;
  INSERT INTO public.parties (partner_id, title, min_confirmed_count, max_participants)
  VALUES (v_partner_id, 'COV WrongTicket Party', 0, 50) RETURNING id INTO v_party_id;
  INSERT INTO public.events (party_id, start_time, end_time, max_participants, status)
  VALUES (v_party_id, now() + interval '1 day', now() + interval '1 day 2 hours', 50, 'scheduled')
  RETURNING id INTO v_event_id_a;
  INSERT INTO public.events (party_id, start_time, end_time, max_participants, status)
  VALUES (v_party_id, now() + interval '1 day', now() + interval '1 day 2 hours', 50, 'scheduled')
  RETURNING id INTO v_event_id_b;
  INSERT INTO public.tickets (event_id, name, quantity, price)
  VALUES (v_event_id_b, 'Wrong Ticket', 10, 5000) RETURNING id INTO v_ticket_id_b;

  v_user_id := tests.create_supabase_user('cov_wrongticket_user');
  UPDATE public.user_profiles SET is_verified = true WHERE id = v_user_id;

  -- Pass event_id_a but ticket belongs to event_id_b
  v_result := public.create_order_validated(v_event_id_a, v_ticket_id_b, v_user_id);
  INSERT INTO cov_wrongticket_result VALUES (v_result);
END $$;

SELECT is(
  (SELECT result->>'error' FROM cov_wrongticket_result),
  'TICKET_NOT_FOUND',
  'Ticket from different event returns TICKET_NOT_FOUND'
);

-- ============================================================
-- Test 7: EVENT_NOT_ACTIVE when event.status != scheduled
-- ============================================================

CREATE TEMP TABLE cov_inactive_result (result jsonb);

DO $$
DECLARE
  v_partner_id uuid;
  v_party_id uuid;
  v_event_id uuid;
  v_ticket_id uuid;
  v_user_id uuid;
  v_result jsonb;
BEGIN
  INSERT INTO public.partners (name) VALUES ('COV Inactive Partner') RETURNING id INTO v_partner_id;
  INSERT INTO public.parties (partner_id, title, min_confirmed_count, max_participants)
  VALUES (v_partner_id, 'COV Inactive Party', 0, 50) RETURNING id INTO v_party_id;
  INSERT INTO public.events (party_id, start_time, end_time, max_participants, status)
  VALUES (v_party_id, now() + interval '1 day', now() + interval '1 day 2 hours', 50, 'cancelled')
  RETURNING id INTO v_event_id;
  INSERT INTO public.tickets (event_id, name, quantity, price)
  VALUES (v_event_id, 'Inactive Ticket', 10, 5000) RETURNING id INTO v_ticket_id;

  v_user_id := tests.create_supabase_user('cov_inactive_user');
  UPDATE public.user_profiles SET is_verified = true WHERE id = v_user_id;

  v_result := public.create_order_validated(v_event_id, v_ticket_id, v_user_id);
  INSERT INTO cov_inactive_result VALUES (v_result);
END $$;

SELECT is(
  (SELECT result->>'error' FROM cov_inactive_result),
  'EVENT_NOT_ACTIVE',
  'Cancelled event returns EVENT_NOT_ACTIVE'
);

-- ============================================================
-- Test 8: EVENT_FULL when current_participants >= max_participants
-- ============================================================

CREATE TEMP TABLE cov_full_result (result jsonb);

DO $$
DECLARE
  v_partner_id uuid;
  v_party_id uuid;
  v_event_id uuid;
  v_ticket_id uuid;
  v_user_id uuid;
  v_result jsonb;
BEGIN
  INSERT INTO public.partners (name) VALUES ('COV Full Partner') RETURNING id INTO v_partner_id;
  INSERT INTO public.parties (partner_id, title, min_confirmed_count, max_participants)
  VALUES (v_partner_id, 'COV Full Party', 0, 1) RETURNING id INTO v_party_id;
  INSERT INTO public.events (party_id, start_time, end_time, max_participants, current_participants, status)
  VALUES (v_party_id, now() + interval '1 day', now() + interval '1 day 2 hours', 1, 1, 'scheduled')
  RETURNING id INTO v_event_id;
  INSERT INTO public.tickets (event_id, name, quantity, price)
  VALUES (v_event_id, 'Full Event Ticket', 1, 5000) RETURNING id INTO v_ticket_id;

  v_user_id := tests.create_supabase_user('cov_full_user');
  UPDATE public.user_profiles SET is_verified = true WHERE id = v_user_id;

  v_result := public.create_order_validated(v_event_id, v_ticket_id, v_user_id);
  INSERT INTO cov_full_result VALUES (v_result);
END $$;

SELECT is(
  (SELECT result->>'error' FROM cov_full_result),
  'EVENT_FULL',
  'Full event returns EVENT_FULL'
);

-- ============================================================
-- Test 9: sold_count CHECK constraint prevents sold_count > quantity
-- ============================================================

SELECT throws_ok(
  $$UPDATE public.tickets SET sold_count = quantity + 1 WHERE name = 'Standard Ticket'$$,
  '23514',
  null,
  'CHECK constraint chk_sold_count prevents sold_count > quantity'
);

SELECT * FROM finish();
ROLLBACK;
