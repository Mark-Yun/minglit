-- Fix #2118 regression test: partner can read applicant user_profiles
-- Verifies the "Partners can read applicant profiles" RLS policy added in
-- 20260505000001_user_profiles_partner_read_policy.sql.
BEGIN;
SELECT plan(4);

SELECT tests.create_supabase_user('partner_user', 'partner@test.com');
SELECT tests.create_supabase_user('applicant', 'applicant@test.com');
SELECT tests.create_supabase_user('other_user', 'other@test.com');

SELECT tests.authenticate_as_service_role();

UPDATE public.user_profiles
  SET name = 'Applicant User'
  WHERE id = tests.get_supabase_uid('applicant');

WITH partner AS (
  INSERT INTO public.partners (name) VALUES ('Test Partner') RETURNING id
)
SELECT set_config('tests.partner_id', id::text, true) FROM partner;

INSERT INTO public.partner_member_permissions (partner_id, user_id, role)
VALUES (
  current_setting('tests.partner_id')::uuid,
  tests.get_supabase_uid('partner_user'),
  'owner'
);

WITH party AS (
  INSERT INTO public.parties (partner_id, title, status)
  SELECT current_setting('tests.partner_id')::uuid, 'Test Party', 'active'
  RETURNING id
)
SELECT set_config('tests.party_id', id::text, true) FROM party;

WITH event_row AS (
  INSERT INTO public.events (party_id, title, start_time, end_time, status)
  SELECT
    current_setting('tests.party_id')::uuid,
    'Test Event',
    now() + interval '1 day',
    now() + interval '1 day' + interval '2 hours',
    'scheduled'
  RETURNING id
)
SELECT set_config('tests.event_id', id::text, true) FROM event_row;

WITH ticket_row AS (
  INSERT INTO public.tickets (event_id, name, price, quantity, status)
  SELECT current_setting('tests.event_id')::uuid, 'General', 0, 10, 'on_sale'
  RETURNING id
)
SELECT set_config('tests.ticket_id', id::text, true) FROM ticket_row;

INSERT INTO public.event_applications (event_id, ticket_id, user_id, status)
SELECT
  current_setting('tests.event_id')::uuid,
  current_setting('tests.ticket_id')::uuid,
  tests.get_supabase_uid('applicant'),
  'approved';

-- Test 1: partner can read profile of user who applied to their event
SELECT tests.authenticate_as('partner_user');
SELECT results_eq(
  $$SELECT name FROM public.user_profiles
    WHERE id = tests.get_supabase_uid('applicant')$$,
  $$VALUES ('Applicant User')$$,
  'partner can read applicant user_profiles'
);

-- Test 2: partner cannot read profile of user who did NOT apply to their event
SELECT is_empty(
  $$SELECT id FROM public.user_profiles
    WHERE id = tests.get_supabase_uid('other_user')$$,
  'partner cannot read non-applicant profiles'
);

-- Test 3: non-partner user cannot read another user's profile via old RLS
SELECT tests.authenticate_as('other_user');
SELECT is_empty(
  $$SELECT id FROM public.user_profiles
    WHERE id = tests.get_supabase_uid('applicant')$$,
  'non-partner user cannot read applicant profile'
);

-- Test 4: self-read still works for applicant
SELECT tests.authenticate_as('applicant');
SELECT results_eq(
  $$SELECT count(*)::int FROM public.user_profiles
    WHERE id = tests.get_supabase_uid('applicant')$$,
  $$VALUES (1)$$,
  'applicant can still read own profile'
);

SELECT * FROM finish();
ROLLBACK;
