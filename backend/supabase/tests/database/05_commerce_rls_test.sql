BEGIN;
SELECT plan(7);

SELECT tests.create_supabase_user('user_a', 'a@test.com');
SELECT tests.create_supabase_user('user_b', 'b@test.com');

SELECT tests.authenticate_as_service_role();

WITH partner AS (
  INSERT INTO public.partners (name)
  VALUES ('Commerce Partner')
  RETURNING id
)
SELECT set_config('tests.partner_id', id::text, true) FROM partner;

WITH party AS (
  INSERT INTO public.parties (partner_id, title, status)
  SELECT current_setting('tests.partner_id')::uuid, 'Commerce Party', 'active'
  RETURNING id
)
SELECT set_config('tests.party_id', id::text, true) FROM party;

WITH event_row AS (
  INSERT INTO public.events (party_id, title, start_time, end_time, status)
  SELECT current_setting('tests.party_id')::uuid,
    'Commerce Event',
    now() + interval '2 days',
    now() + interval '2 days' + interval '2 hours',
    'scheduled'
  RETURNING id
)
SELECT set_config('tests.event_id', id::text, true) FROM event_row;

WITH ticket_row AS (
  INSERT INTO public.tickets (event_id, name, price, quantity, status)
  SELECT current_setting('tests.event_id')::uuid, 'Ticket A', 5000, 5, 'on_sale'
  RETURNING id
)
SELECT set_config('tests.ticket_id', id::text, true) FROM ticket_row;

WITH verification_a AS (
  INSERT INTO public.verifications (partner_id, category, internal_name, display_name)
  SELECT current_setting('tests.partner_id')::uuid, 'career', 'career_check', 'Career Check'
  RETURNING id
)
SELECT set_config('tests.verification_a', id::text, true) FROM verification_a;

WITH verification_b AS (
  INSERT INTO public.verifications (partner_id, category, internal_name, display_name)
  SELECT current_setting('tests.partner_id')::uuid, 'asset', 'asset_check', 'Asset Check'
  RETURNING id
)
SELECT set_config('tests.verification_b', id::text, true) FROM verification_b;

WITH participant_row AS (
  INSERT INTO public.event_participants (event_id, ticket_id, user_id, status, ticket_code)
  SELECT
    current_setting('tests.event_id')::uuid,
    current_setting('tests.ticket_id')::uuid,
    tests.get_supabase_uid('user_a'),
    'ticket_issued',
    'TICKET-A'
  RETURNING id
)
SELECT set_config('tests.participant_a', id::text, true) FROM participant_row;

INSERT INTO public.user_verifications (user_id, verification_id, data)
VALUES (
  tests.get_supabase_uid('user_a'),
  current_setting('tests.verification_a')::uuid,
  '{"level":"bronze"}'::jsonb
);

SELECT tests.clear_authentication();
SELECT is_empty(
  $$SELECT id
    FROM public.event_participants
    WHERE id = current_setting('tests.participant_a')::uuid$$,
  'anon cannot read event participants'
);

SELECT tests.authenticate_as('user_a');
SELECT results_eq(
  $$SELECT count(*)::int
    FROM public.event_participants
    WHERE id = current_setting('tests.participant_a')::uuid$$,
  $$VALUES (1)$$,
  'users can read their own tickets'
);

SELECT tests.authenticate_as('user_b');
SELECT is_empty(
  $$SELECT id
    FROM public.event_participants
    WHERE id = current_setting('tests.participant_a')::uuid$$,
  'users cannot read others tickets'
);

SELECT tests.authenticate_as('user_a');
SELECT lives_ok(
  $$UPDATE public.user_verifications
      SET data = '{"level":"gold"}'::jsonb
      WHERE user_id = tests.get_supabase_uid('user_a')
        AND verification_id = current_setting('tests.verification_a')::uuid$$,
  'users can update their own verifications'
);
SELECT results_eq(
  $$SELECT data->>'level'
    FROM public.user_verifications
    WHERE user_id = tests.get_supabase_uid('user_a')
      AND verification_id = current_setting('tests.verification_a')::uuid$$,
  $$VALUES ('gold')$$,
  'verification updates persist'
);

SELECT tests.authenticate_as('user_b');
SELECT is_empty(
  $$SELECT id
    FROM public.user_verifications
    WHERE user_id = tests.get_supabase_uid('user_a')
      AND verification_id = current_setting('tests.verification_a')::uuid$$,
  'users cannot read others verifications'
);
SELECT throws_ok(
  $$INSERT INTO public.user_verifications (user_id, verification_id, data)
    VALUES (
      tests.get_supabase_uid('user_a'),
      current_setting('tests.verification_b')::uuid,
      '{"level":"silver"}'::jsonb
    )$$,
  '42501',
  'new row violates row-level security policy for table "user_verifications"',
  'users cannot insert verifications for others'
);

SELECT * FROM finish();
ROLLBACK;
