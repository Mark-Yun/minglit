-- Fix #1564: CUJ 17 migration — settlement RLS by partner role
-- Verifies that only members with SETTLEMENT_VIEW permission can access settlements.
-- owner → SETTLEMENT_VIEW granted (via sync_partner_member_permissions trigger)
-- manager → no SETTLEMENT_VIEW → blocked
-- staff → no SETTLEMENT_VIEW → blocked
BEGIN;
SELECT plan(5);

SELECT tests.create_supabase_user('owner_user', 'owner@test.com');
SELECT tests.create_supabase_user('manager_user', 'manager@test.com');
SELECT tests.create_supabase_user('staff_user', 'staff@test.com');
SELECT tests.create_supabase_user('outsider_user', 'outsider@test.com');

SELECT tests.authenticate_as_service_role();

WITH partner AS (
  INSERT INTO public.partners (name, introduction)
  VALUES ('Settlement Test Partner', 'Test')
  RETURNING id
)
SELECT set_config('tests.partner_id', id::text, true) FROM partner;

-- Insert roles — sync_partner_member_permissions trigger sets permissions array
INSERT INTO public.partner_member_permissions (partner_id, user_id, role)
VALUES
  (current_setting('tests.partner_id')::uuid, tests.get_supabase_uid('owner_user'), 'owner'),
  (current_setting('tests.partner_id')::uuid, tests.get_supabase_uid('manager_user'), 'manager'),
  (current_setting('tests.partner_id')::uuid, tests.get_supabase_uid('staff_user'), 'staff');

INSERT INTO public.partner_settlements (
  partner_id, biz_type, biz_name, biz_number, representative_name,
  bank_name, account_number, account_holder
) VALUES (
  current_setting('tests.partner_id')::uuid,
  'individual', 'Test Biz', '000-00-00000', 'Test Rep',
  'Test Bank', '0000000000', 'Test Holder'
);

-- owner (has SETTLEMENT_VIEW) can read
SELECT tests.authenticate_as('owner_user');
SELECT results_eq(
  $$SELECT count(*)::int FROM public.partner_settlements
    WHERE partner_id = current_setting('tests.partner_id')::uuid$$,
  $$VALUES (1)$$,
  'owner with SETTLEMENT_VIEW can read partner_settlements'
);

-- manager (no SETTLEMENT_VIEW) is blocked
SELECT tests.authenticate_as('manager_user');
SELECT is_empty(
  $$SELECT * FROM public.partner_settlements
    WHERE partner_id = current_setting('tests.partner_id')::uuid$$,
  'manager without SETTLEMENT_VIEW cannot read partner_settlements'
);

-- staff (no SETTLEMENT_VIEW) is blocked
SELECT tests.authenticate_as('staff_user');
SELECT is_empty(
  $$SELECT * FROM public.partner_settlements
    WHERE partner_id = current_setting('tests.partner_id')::uuid$$,
  'staff without SETTLEMENT_VIEW cannot read partner_settlements'
);

-- outsider (not a member) is blocked
SELECT tests.authenticate_as('outsider_user');
SELECT is_empty(
  $$SELECT * FROM public.partner_settlements
    WHERE partner_id = current_setting('tests.partner_id')::uuid$$,
  'outsider (not a partner member) cannot read partner_settlements'
);

-- same isolation on public.settlements table (SETTLEMENT_VIEW guards select)
SELECT tests.authenticate_as('manager_user');
SELECT is_empty(
  $$SELECT * FROM public.settlements
    WHERE partner_id = current_setting('tests.partner_id')::uuid$$,
  'manager without SETTLEMENT_VIEW cannot read settlements'
);

SELECT * FROM finish();
ROLLBACK;
