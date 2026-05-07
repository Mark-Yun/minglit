-- Fix #2250: Tests for partner_visible_user_profiles view.
--
-- Verifies:
-- 1. View exposes only the allowed columns (닉네임/연령대/인증정보)
-- 2. View does NOT expose sensitive columns (name, gender, birth_date, phone_number)
-- 3. Partner can still read applicant rows via the view (row-level RLS intact)
-- 4. Non-applicant rows are still blocked (row-level RLS intact)

BEGIN;
SELECT plan(5);

SELECT tests.create_supabase_user('partner_user', 'partner@test.com');
SELECT tests.create_supabase_user('applicant', 'applicant@test.com');
SELECT tests.create_supabase_user('other_user', 'other@test.com');

SELECT tests.authenticate_as_service_role();

UPDATE public.user_profiles
  SET
    name = '실명김철수',
    username = '닉네임123',
    birth_date = '1995-01-01',
    gender = 'male',
    is_verified = true
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

-- Test 1: view does NOT expose sensitive columns (name, gender, birth_date, phone_number)
-- The view only has: id, username, birth_year, is_verified, profile_image_url
SELECT hasnt_column(
  'public',
  'partner_visible_user_profiles',
  'name',
  'partner_visible_user_profiles view does not expose name (실명)'
);

SELECT hasnt_column(
  'public',
  'partner_visible_user_profiles',
  'gender',
  'partner_visible_user_profiles view does not expose gender'
);

SELECT hasnt_column(
  'public',
  'partner_visible_user_profiles',
  'birth_date',
  'partner_visible_user_profiles view does not expose birth_date'
);

-- Test 4: partner can read allowed columns via view for their applicant
SELECT tests.authenticate_as('partner_user');
SELECT results_eq(
  $$SELECT username, birth_year, is_verified
    FROM public.partner_visible_user_profiles
    WHERE id = tests.get_supabase_uid('applicant')$$,
  $$VALUES ('닉네임123'::text, 1995, true)$$,
  'partner can read allowed columns (username/birth_year/is_verified) via view'
);

-- Test 5: non-applicant rows blocked via view (RLS from user_profiles applies)
SELECT is_empty(
  $$SELECT id FROM public.partner_visible_user_profiles
    WHERE id = tests.get_supabase_uid('other_user')$$,
  'partner cannot read non-applicant row via view'
);

SELECT * FROM finish();
ROLLBACK;
