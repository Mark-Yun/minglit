BEGIN;
SELECT plan(7);

SELECT tests.create_supabase_user('deleted_user', 'deleted@test.com');
SELECT tests.create_supabase_user('viewer_user', 'viewer@test.com');

SELECT tests.authenticate_as_service_role();

UPDATE public.user_profiles
SET
  name = 'Deleted User',
  phone_number = '010-1111-1111',
  deleted_at = now()
WHERE id = tests.get_supabase_uid('deleted_user');

UPDATE public.user_profiles
SET name = 'Viewer User'
WHERE id = tests.get_supabase_uid('viewer_user');

WITH partner AS (
  INSERT INTO public.partners (name)
  VALUES ('Deleted Visibility Partner')
  RETURNING id
),
party AS (
  INSERT INTO public.parties (partner_id, title, status)
  SELECT id, 'Deleted Visibility Party', 'active'
  FROM partner
  RETURNING id
),
event_row AS (
  INSERT INTO public.events (party_id, title, start_time, end_time, status)
  SELECT id, 'Deleted Visibility Event', now() + interval '1 day', now() + interval '1 day' + interval '2 hours', 'scheduled'
  FROM party
  RETURNING id
),
ticket_row AS (
  INSERT INTO public.tickets (event_id, name, price, quantity, status)
  SELECT id, 'Deleted Visibility Ticket', 1000, 10, 'on_sale'
  FROM event_row
  RETURNING id
),
participant_row AS (
  INSERT INTO public.event_participants (event_id, ticket_id, user_id, status, ticket_code, display_name)
  SELECT event_row.id, ticket_row.id, tests.get_supabase_uid('deleted_user'), 'ticket_issued', 'DELETED-TICKET', 'Deleted User'
  FROM event_row, ticket_row
  RETURNING id, event_id
),
visible_participant_row AS (
  INSERT INTO public.event_participants (event_id, ticket_id, user_id, status, ticket_code, display_name)
  SELECT event_row.id, ticket_row.id, tests.get_supabase_uid('viewer_user'), 'ticket_issued', 'VISIBLE-TICKET', 'Viewer User'
  FROM event_row, ticket_row
  RETURNING id
),
match_pair AS (
  INSERT INTO public.match_pairs (event_id, user_lower_id, user_higher_id)
  SELECT
    participant_row.event_id,
    least(tests.get_supabase_uid('deleted_user'), tests.get_supabase_uid('viewer_user')),
    greatest(tests.get_supabase_uid('deleted_user'), tests.get_supabase_uid('viewer_user'))
  FROM participant_row
  RETURNING event_id
)
SELECT
  set_config('tests.participant_id', participant_row.id::text, true),
  set_config('tests.visible_participant_id', visible_participant_row.id::text, true),
  set_config('tests.event_id', participant_row.event_id::text, true)
FROM participant_row
CROSS JOIN visible_participant_row;

SELECT tests.authenticate_as('deleted_user');
SELECT set_config('request.jwt.claims', (current_setting('request.jwt.claims', true)::jsonb || '{"role":"authenticated"}')::text, true);

SELECT results_eq(
  $$SELECT count(*)::int FROM public.user_profiles WHERE id = tests.get_supabase_uid('deleted_user')$$,
  $$VALUES (1)$$,
  'soft-deleted user can still read own profile during grace period'
);

SELECT results_eq(
  $$SELECT count(*)::int FROM public.event_participants WHERE id = current_setting('tests.participant_id')::uuid$$,
  $$VALUES (1)$$,
  'soft-deleted user can still read own participant row'
);

SELECT tests.authenticate_as('viewer_user');
SELECT set_config('request.jwt.claims', (current_setting('request.jwt.claims', true)::jsonb || '{"role":"authenticated"}')::text, true);

SELECT results_eq(
  $$SELECT count(*)::int FROM public.event_participants WHERE id = current_setting('tests.visible_participant_id')::uuid$$,
  $$VALUES (1)$$,
  'visible participant rows remain readable cross-user'
);

SELECT is_empty(
  $$SELECT id FROM public.event_participants WHERE id = current_setting('tests.participant_id')::uuid$$,
  'other users cannot read soft-deleted participant rows'
);

SELECT is_empty(
  $$SELECT partner_id FROM public.my_matches_view WHERE partner_id = tests.get_supabase_uid('deleted_user')$$,
  'my_matches_view excludes soft-deleted matched users'
);

SELECT is_empty(
  $$SELECT * FROM public.get_matched_user_info(
      tests.get_supabase_uid('deleted_user'),
      current_setting('tests.event_id')::uuid
    )$$,
  'get_matched_user_info hides soft-deleted matched users'
);

SELECT results_eq(
  $$SELECT public.get_matched_user_contact(
      tests.get_supabase_uid('deleted_user'),
      current_setting('tests.event_id')::uuid
    ) is null$$,
  $$VALUES (true)$$,
  'get_matched_user_contact returns null for soft-deleted matched users'
);

SELECT * FROM finish();
ROLLBACK;
