BEGIN;
SELECT plan(6);

SELECT tests.create_supabase_user('user_a', 'a@test.com');
SELECT tests.create_supabase_user('user_b', 'b@test.com');

SELECT tests.authenticate_as_service_role();

WITH partner AS (
  INSERT INTO public.partners (name)
  VALUES ('Event Partner')
  RETURNING id
)
SELECT set_config('tests.partner_id', id::text, true) FROM partner;

WITH party AS (
  INSERT INTO public.parties (partner_id, title, status)
  SELECT current_setting('tests.partner_id')::uuid, 'Test Party', 'active'
  RETURNING id
)
SELECT set_config('tests.party_id', id::text, true) FROM party;

WITH event_row AS (
  INSERT INTO public.events (party_id, title, start_time, end_time, status)
  SELECT current_setting('tests.party_id')::uuid,
    'Test Event',
    now() + interval '1 day',
    now() + interval '1 day' + interval '2 hours',
    'scheduled'
  RETURNING id
)
SELECT set_config('tests.event_id', id::text, true) FROM event_row;

WITH ticket_row AS (
  INSERT INTO public.tickets (event_id, name, price, quantity, status)
  SELECT current_setting('tests.event_id')::uuid, 'General', 1000, 10, 'on_sale'
  RETURNING id
)
SELECT set_config('tests.ticket_id', id::text, true) FROM ticket_row;

WITH app_row AS (
  INSERT INTO public.event_applications (event_id, ticket_id, user_id, status)
  SELECT
    current_setting('tests.event_id')::uuid,
    current_setting('tests.ticket_id')::uuid,
    tests.get_supabase_uid('user_a'),
    'pending'
  RETURNING id
)
SELECT set_config('tests.app_a', id::text, true) FROM app_row;

SELECT tests.clear_authentication();
SELECT results_eq(
  $$SELECT count(*)::int
    FROM public.parties
    WHERE id = current_setting('tests.party_id')::uuid$$,
  $$VALUES (1)$$,
  'parties are publicly readable'
);
SELECT results_eq(
  $$SELECT count(*)::int
    FROM public.events
    WHERE id = current_setting('tests.event_id')::uuid$$,
  $$VALUES (1)$$,
  'events are publicly readable'
);
SELECT is_empty(
  $$SELECT id
    FROM public.event_applications
    WHERE id = current_setting('tests.app_a')::uuid$$,
  'anon cannot read event applications'
);
SELECT throws_ok(
  $$INSERT INTO public.event_applications (event_id, ticket_id, user_id, status)
    VALUES (
      current_setting('tests.event_id')::uuid,
      current_setting('tests.ticket_id')::uuid,
      tests.get_supabase_uid('user_b'),
      'pending'
    )$$,
  '42501',
  'new row violates row-level security policy for table "event_applications"',
  'anon cannot create event applications'
);

SELECT tests.authenticate_as('user_a');
SELECT results_eq(
  $$SELECT count(*)::int
    FROM public.event_applications
    WHERE id = current_setting('tests.app_a')::uuid$$,
  $$VALUES (1)$$,
  'users can read their own applications'
);

SELECT tests.authenticate_as('user_b');
SELECT is_empty(
  $$SELECT id
    FROM public.event_applications
    WHERE id = current_setting('tests.app_a')::uuid$$,
  'users cannot read others applications'
);

SELECT * FROM finish();
ROLLBACK;
