BEGIN;
SELECT plan(8);

SELECT tests.create_supabase_user('user_a', 'ha@test.com');
SELECT tests.create_supabase_user('user_b', 'hb@test.com');

SELECT tests.authenticate_as_service_role();

WITH partner AS (
  INSERT INTO public.partners (name, introduction) VALUES ('Hardening Partner', 'Test') RETURNING id
)
SELECT set_config('tests.partner_id', id::text, true) FROM partner;

INSERT INTO public.social_interactions (user_id, target_id, target_type, interaction_type)
VALUES (tests.get_supabase_uid('user_a'), gen_random_uuid(), 'party', 'like');

WITH party AS (
  INSERT INTO public.parties (partner_id, title, status)
  SELECT current_setting('tests.partner_id')::uuid, 'Hardening Party', 'active'
  RETURNING id
)
SELECT set_config('tests.party_id', id::text, true) FROM party;

WITH event_row AS (
  INSERT INTO public.events (party_id, title, start_time, end_time, status)
  SELECT current_setting('tests.party_id')::uuid, 'Hardening Event',
    now() + interval '1 day', now() + interval '1 day' + interval '2 hours', 'scheduled'
  RETURNING id
)
SELECT set_config('tests.event_id', id::text, true) FROM event_row;

WITH ticket_row AS (
  INSERT INTO public.tickets (event_id, name, price, quantity, status)
  SELECT current_setting('tests.event_id')::uuid, 'H Ticket', 1000, 10, 'on_sale'
  RETURNING id
)
SELECT set_config('tests.ticket_id', id::text, true) FROM ticket_row;

WITH participant_row AS (
  INSERT INTO public.event_participants (event_id, ticket_id, user_id, status, ticket_code, display_name)
  SELECT current_setting('tests.event_id')::uuid,
    current_setting('tests.ticket_id')::uuid,
    tests.get_supabase_uid('user_a'),
    'ticket_issued', 'HTEST-A', 'User A Display'
  RETURNING id
)
SELECT set_config('tests.participant_id', id::text, true) FROM participant_row;

SELECT tests.authenticate_as('user_a');
SELECT results_eq(
  $$SELECT count(*)::int FROM public.user_profiles WHERE id = tests.get_supabase_uid('user_a')$$,
  $$VALUES (1)$$,
  'user_a can read own profile'
);

SELECT is_empty(
  $$SELECT id FROM public.user_profiles WHERE id = tests.get_supabase_uid('user_b')$$,
  'user_a cannot read user_b profile (self-only)'
);

SELECT tests.authenticate_as('user_b');
SELECT set_config('request.jwt.claims', (current_setting('request.jwt.claims', true)::jsonb || '{"role":"authenticated"}')::text, true);
SELECT results_eq(
  $$SELECT count(*)::int FROM public.event_participants
    WHERE id = current_setting('tests.participant_id')::uuid$$,
  $$VALUES (1)$$,
  'authenticated user_b can read user_a participant record'
);

SELECT tests.clear_authentication();
SELECT is_empty(
  $$SELECT id FROM public.event_participants
    WHERE id = current_setting('tests.participant_id')::uuid$$,
  'anon cannot read event participants'
);

SELECT tests.clear_authentication();
SELECT is_empty(
  $$SELECT id FROM public.user_profiles WHERE id = tests.get_supabase_uid('user_a')$$,
  'anon cannot read any user profile'
);
SELECT tests.authenticate_as('user_b');
SELECT is_empty(
  $$SELECT user_id FROM public.social_interactions
    WHERE user_id = tests.get_supabase_uid('user_a')$$,
  'user_b cannot read user_a social interactions (self-only)'
);

SELECT tests.authenticate_as('user_a');
SELECT is_empty(
  $$SELECT * FROM get_matched_user_info(
    tests.get_supabase_uid('user_b'),
    current_setting('tests.event_id')::uuid
  )$$,
  'get_matched_user_info returns empty when no match'
);
SELECT set_config('request.jwt.claims', (current_setting('request.jwt.claims', true)::jsonb || '{"role":"authenticated"}')::text, true);

SELECT results_eq(
  $$SELECT display_name FROM public.event_participants
    WHERE id = current_setting('tests.participant_id')::uuid$$,
  $$VALUES ('User A Display')$$,
  'event_participants display_name column works'
);

SELECT * FROM finish();
ROLLBACK;
