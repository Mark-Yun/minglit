BEGIN;
SELECT plan(24);

-- ===========================================================================
-- SETUP
-- ===========================================================================

SELECT tests.create_supabase_user('user_a', 'a@test.com');
SELECT tests.create_supabase_user('user_b', 'b@test.com');

SELECT tests.authenticate_as_service_role();

-- Create partner_a (user_a is owner → gets SETTLEMENT_VIEW, MEMBER_MANAGE, VERIFY_REVIEW, etc.)
WITH partner AS (
  INSERT INTO public.partners (name, introduction)
  VALUES ('Partner A', 'Intro A')
  RETURNING id
)
SELECT set_config('tests.partner_a_id', id::text, true) FROM partner;

INSERT INTO public.partner_member_permissions (partner_id, user_id, role)
VALUES (current_setting('tests.partner_a_id')::uuid, tests.get_supabase_uid('user_a'), 'owner');

-- Create partner_b (no members — used for INSERT restriction test on partner_settlements)
WITH partner AS (
  INSERT INTO public.partners (name, introduction)
  VALUES ('Partner B', 'Intro B')
  RETURNING id
)
SELECT set_config('tests.partner_b_id', id::text, true) FROM partner;

-- user_a is super_admin
INSERT INTO public.app_roles (user_id, role)
VALUES (tests.get_supabase_uid('user_a'), 'super_admin');

-- partner_settlements row for partner_a
INSERT INTO public.partner_settlements (
  partner_id, biz_type, biz_name, biz_number, representative_name,
  bank_name, account_number, account_holder
) VALUES (
  current_setting('tests.partner_a_id')::uuid,
  'corporate', 'Test Corp', '123-45-67890', 'Test Rep',
  'Test Bank', '1234567890', 'Test Holder'
);

-- partner_application for user_a (so user_b can be tested for cross-isolation)
INSERT INTO public.partner_applications (
  user_id, brand_name, biz_type, biz_name, biz_number,
  representative_name, bank_name, account_number, account_holder,
  biz_registration_path, bankbook_path
) VALUES (
  tests.get_supabase_uid('user_a'),
  'A Brand', 'corporate', 'A Corp', '111-11-11111',
  'A Rep', 'A Bank', '1111111111', 'A Holder',
  '/path/a_biz_reg', '/path/a_bankbook'
);

-- Verification chain for verification_comments tests
WITH v AS (
  INSERT INTO public.verifications (partner_id, category, internal_name, display_name)
  VALUES (current_setting('tests.partner_a_id')::uuid, 'career', 'career_v', 'Career')
  RETURNING id
)
SELECT set_config('tests.verification_id', id::text, true) FROM v;

WITH vs AS (
  INSERT INTO public.verification_submissions (
    partner_id, user_id, verification_id, snapshot_data
  ) VALUES (
    current_setting('tests.partner_a_id')::uuid,
    tests.get_supabase_uid('user_b'),
    current_setting('tests.verification_id')::uuid,
    '{"data": "test"}'::jsonb
  )
  RETURNING id
)
SELECT set_config('tests.submission_id', id::text, true) FROM vs;

-- Fix #301: verification_comments table dropped — comment data now in snapshot_data JSON

-- ===========================================================================
-- app_roles TESTS (assertions 1–5)
-- RLS not yet enabled → rls_enabled FAILS, anon/non-admin SELECT FAIL
-- ===========================================================================

SELECT tests.rls_enabled('public', 'app_roles');

SELECT tests.clear_authentication();
SELECT is_empty(
  $$SELECT user_id FROM public.app_roles$$,
  'anon cannot read app_roles'
);

SELECT tests.authenticate_as('user_b');
SELECT is_empty(
  $$SELECT user_id FROM public.app_roles$$,
  'non-admin cannot read app_roles'
);

SELECT tests.authenticate_as('user_a');
SELECT results_eq(
  $$SELECT count(*)::int FROM public.app_roles
    WHERE user_id = tests.get_supabase_uid('user_a')$$,
  $$VALUES (1)$$,
  'super_admin can read own app_roles entry'
);
SELECT lives_ok(
  $$INSERT INTO public.app_roles (user_id, role)
    VALUES (tests.get_supabase_uid('user_b'), 'moderator')$$,
  'super_admin can insert app_roles'
);

-- ===========================================================================
-- debug_logs TESTS (assertions 6–9)
-- Has GRANT ALL to anon/authenticated but RLS not yet enabled
-- ===========================================================================

SELECT tests.rls_enabled('public', 'debug_logs');

SELECT tests.clear_authentication();
SELECT throws_ok(
  $$SELECT id FROM public.debug_logs LIMIT 1$$,
  '42501',
  null,
  'anon cannot read debug_logs'
);

SELECT tests.authenticate_as('user_b');
SELECT throws_ok(
  $$SELECT id FROM public.debug_logs LIMIT 1$$,
  '42501',
  null,
  'authenticated user cannot read debug_logs'
);
SELECT throws_ok(
  $$INSERT INTO public.debug_logs (message) VALUES ('test-log')$$,
  '42501',
  null,
  'authenticated user cannot insert debug_logs'
);

-- ===========================================================================
-- partner_settlements TESTS (assertions 10–14)
-- Policies exist but RLS not yet enabled on this table
-- ===========================================================================

SELECT tests.rls_enabled('public', 'partner_settlements');

SELECT tests.clear_authentication();
SELECT is_empty(
  $$SELECT partner_id FROM public.partner_settlements$$,
  'anon cannot read partner_settlements'
);

SELECT tests.authenticate_as('user_b');
SELECT is_empty(
  $$SELECT partner_id FROM public.partner_settlements$$,
  'non-member cannot read partner_settlements'
);
SELECT throws_ok(
  $$INSERT INTO public.partner_settlements (
      partner_id, biz_type, biz_name, biz_number, representative_name,
      bank_name, account_number, account_holder
    ) VALUES (
      current_setting('tests.partner_b_id')::uuid,
      'individual', 'B Corp', '999-99-99999', 'B Rep',
      'B Bank', '9999999999', 'B Holder'
    )$$,
  '42501',
  null,
  'non-member cannot insert partner_settlements'
);

SELECT tests.authenticate_as('user_a');
SELECT results_eq(
  $$SELECT count(*)::int FROM public.partner_settlements
    WHERE partner_id = current_setting('tests.partner_a_id')::uuid$$,
  $$VALUES (1)$$,
  'partner owner with SETTLEMENT_VIEW can read own settlements'
);

-- ===========================================================================
-- partner_member_permissions TESTS (assertions 15–19)
-- Policy "Users can read own permissions" exists but RLS not yet enabled
-- ===========================================================================

SELECT tests.rls_enabled('public', 'partner_member_permissions');

SELECT tests.clear_authentication();
SELECT is_empty(
  $$SELECT id FROM public.partner_member_permissions LIMIT 1$$,
  'anon cannot read partner_member_permissions'
);

SELECT tests.authenticate_as('user_a');
SELECT results_eq(
  $$SELECT count(*)::int FROM public.partner_member_permissions
    WHERE user_id = tests.get_supabase_uid('user_a')$$,
  $$VALUES (1)$$,
  'member can read own permissions'
);
SELECT results_eq(
  $$SELECT count(*)::int FROM public.partner_member_permissions
    WHERE partner_id = current_setting('tests.partner_a_id')::uuid$$,
  $$VALUES (1)$$,
  'owner with MEMBER_MANAGE can read all partner members'
);

SELECT tests.authenticate_as('user_b');
SELECT is_empty(
  $$SELECT id FROM public.partner_member_permissions
    WHERE user_id = tests.get_supabase_uid('user_a')$$,
  'non-member cannot read others partner_member_permissions'
);

-- ===========================================================================
-- partner_applications TESTS (assertions 20–24)
-- Policy "Users can read own applications" exists but RLS not yet enabled
-- No INSERT policy yet (to be added in Task 2 migration)
-- ===========================================================================

SELECT tests.rls_enabled('public', 'partner_applications');

SELECT tests.clear_authentication();
SELECT throws_ok(
  $$INSERT INTO public.partner_applications (
      user_id, brand_name, biz_type, biz_name, biz_number,
      representative_name, bank_name, account_number, account_holder,
      biz_registration_path, bankbook_path
    ) VALUES (
      tests.get_supabase_uid('user_a'),
      'Anon Brand', 'individual', 'Anon Biz', '000-00-00000',
      'Anon Rep', 'Anon Bank', '0000000000', 'Anon Holder',
      '/path/anon_biz_reg', '/path/anon_bankbook'
    )$$,
  '42501',
  null,
  'anon cannot insert partner_applications'
);

SELECT tests.authenticate_as('user_b');
SELECT lives_ok(
  $$INSERT INTO public.partner_applications (
      user_id, brand_name, biz_type, biz_name, biz_number,
      representative_name, bank_name, account_number, account_holder,
      biz_registration_path, bankbook_path
    ) VALUES (
      tests.get_supabase_uid('user_b'),
      'B Brand', 'individual', 'B Biz', '222-22-22222',
      'B Rep', 'B Bank', '2222222222', 'B Holder',
      '/path/b_biz_reg', '/path/b_bankbook'
    )$$,
  'authenticated user can insert own partner_application'
);
SELECT results_eq(
  $$SELECT count(*)::int FROM public.partner_applications
    WHERE user_id = tests.get_supabase_uid('user_b')$$,
  $$VALUES (1)$$,
  'applicant can read own partner_application'
);
SELECT is_empty(
  $$SELECT id FROM public.partner_applications
    WHERE user_id = tests.get_supabase_uid('user_a')$$,
  'non-applicant cannot read others partner_applications'
);

-- Fix #301: verification_comments table dropped — tests removed

SELECT * FROM finish();
ROLLBACK;
