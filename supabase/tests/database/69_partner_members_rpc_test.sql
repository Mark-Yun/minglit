BEGIN;
SELECT plan(2);

SELECT tests.create_supabase_user('partner_members_owner', 'owner@test.com');
SELECT tests.authenticate_as_service_role();

WITH partner AS (
  INSERT INTO public.partners (name)
  VALUES ('Partner Members RPC Test')
  RETURNING id
)
SELECT set_config('tests.partner_members_partner_id', id::text, true)
FROM partner;

INSERT INTO public.user_profiles (id, name, username)
VALUES (
  tests.get_supabase_uid('partner_members_owner'),
  'Partner Members Owner',
  'partner_members_owner'
)
ON CONFLICT (id) DO UPDATE
SET name = EXCLUDED.name,
    username = EXCLUDED.username;

INSERT INTO public.partner_member_permissions (
  partner_id,
  user_id,
  role,
  permissions
)
VALUES (
  current_setting('tests.partner_members_partner_id')::uuid,
  tests.get_supabase_uid('partner_members_owner'),
  'owner',
  ARRAY['MEMBER_MANAGE']::text[]
);

SELECT tests.authenticate_as('partner_members_owner');

-- Fix #1269: partner_role enum must be cast to text so PostgREST can materialize the RPC result.
SELECT lives_ok(
  $$SELECT * FROM public.get_partner_members_with_user(
      current_setting('tests.partner_members_partner_id')::uuid
    )$$,
  'get_partner_members_with_user returns without enum/text mismatch'
);

SELECT results_eq(
  $$SELECT role FROM public.get_partner_members_with_user(
      current_setting('tests.partner_members_partner_id')::uuid
    )$$,
  $$VALUES ('owner'::text)$$,
  'get_partner_members_with_user exposes role as text'
);

SELECT * FROM finish();
ROLLBACK;
