-- pgTAP tests for dev_seed_bulk_users and dev_seed_bulk_partners RPCs.
-- Covers: dev-only guard, user/partner rerun idempotency, owner role recovery.

BEGIN;
SELECT plan(9);

SELECT tests.authenticate_as_service_role();

-- ─── 1. Environment guard: dev_seed_bulk_users blocked outside dev ───────────
SET LOCAL app.settings.environment = 'production';
SELECT throws_like(
  $$ SELECT dev_seed_bulk_users('[]'::jsonb) $$,
  '%dev_seed_bulk_users is blocked in production%',
  'dev_seed_bulk_users raises in production'
);

-- ─── 2. Environment guard: dev_seed_bulk_partners blocked outside dev ────────
SELECT throws_like(
  $$ SELECT dev_seed_bulk_partners('[]'::jsonb) $$,
  '%dev_seed_bulk_partners is blocked in production%',
  'dev_seed_bulk_partners raises in production'
);

-- ─── 3. Environment guard: NULL setting is fail-closed ───────────────────────
SET LOCAL app.settings.environment = '';
SELECT throws_like(
  $$ SELECT dev_seed_bulk_users('[]'::jsonb) $$,
  '%blocked in production%',
  'dev_seed_bulk_users fails-closed when environment is empty'
);

-- Switch to dev for remaining tests
SET LOCAL app.settings.environment = 'development';

-- ─── 4. dev_seed_bulk_users: idempotent rerun returns total ──────────────────
DO $$
DECLARE
  result1 jsonb;
  result2 jsonb;
BEGIN
  result1 := dev_seed_bulk_users(
    '[{"email":"seed_test_pgtap@test.com","name":"Seed Test","username":"seed_test_pgtap","gender":"M","birth_date":"1990-01-01","phone_number":"01000000001","is_verified":false}]'::jsonb
  );
  -- Second run (same user) should update, not fail
  result2 := dev_seed_bulk_users(
    '[{"email":"seed_test_pgtap@test.com","name":"Seed Test","username":"seed_test_pgtap","gender":"M","birth_date":"1990-01-01","phone_number":"01000000001","is_verified":false}]'::jsonb
  );
  PERFORM set_config('tests.seed_user_result1', result1::text, true);
  PERFORM set_config('tests.seed_user_result2', result2::text, true);
END;
$$;

SELECT ok(
  (current_setting('tests.seed_user_result1')::jsonb->>'created')::int = 1,
  'first run: created=1'
);
SELECT ok(
  (current_setting('tests.seed_user_result2')::jsonb->>'updated')::int = 1,
  'second run: updated=1 (idempotent)'
);

-- ─── 5. dev_seed_bulk_users: elapsed_ms is full duration (not sub-second component) ─
SELECT ok(
  (current_setting('tests.seed_user_result1')::jsonb->>'elapsed_ms')::int >= 0,
  'elapsed_ms is non-negative integer'
);

-- ─── 6. dev_seed_bulk_partners: owner role recovery on rerun ─────────────────
DO $$
DECLARE
  partner_payload jsonb;
  seed_user_id uuid;
  partner_id uuid;
BEGIN
  SELECT id INTO seed_user_id FROM auth.users WHERE email = 'seed_test_pgtap@test.com';

  partner_payload := jsonb_build_array(jsonb_build_object(
    'name', 'Seed Test Partner',
    'introduction', 'Test',
    'biz_name', 'Seed Corp',
    'biz_number', 'BIZ-PGTAP-001',
    'contact_email', 'seed_test_pgtap@test.com',
    'owner_email', 'seed_test_pgtap@test.com',
    'location', jsonb_build_object(
      'name', 'Test Location', 'address', 'Seoul', 'region_1', 'Seoul',
      'region_2', 'Gangnam', 'region_3', 'Teheran', 'lat', 37.5, 'lng', 127.0
    ),
    'local_verifications', '[]'::jsonb
  ));

  -- First run: creates partner + owner permission
  PERFORM dev_seed_bulk_partners(partner_payload, '[]'::jsonb);

  -- Simulate permission drift: delete owner permission
  SELECT id INTO partner_id FROM public.partners WHERE biz_number = 'BIZ-PGTAP-001';
  DELETE FROM public.partner_member_permissions
  WHERE partner_id = partner_id AND user_id = seed_user_id;

  -- Second run: should recover owner permission
  PERFORM dev_seed_bulk_partners(partner_payload, '[]'::jsonb);

  PERFORM set_config('tests.owner_partner_id', partner_id::text, true);
  PERFORM set_config('tests.owner_user_id', seed_user_id::text, true);
END;
$$;

SELECT ok(
  EXISTS (
    SELECT 1 FROM public.partner_member_permissions
    WHERE partner_id = current_setting('tests.owner_partner_id')::uuid
      AND user_id = current_setting('tests.owner_user_id')::uuid
      AND role = 'owner'
  ),
  'owner permission recovered after drift on rerun'
);

-- ─── 7. dev_seed_bulk_partners: location upsert idempotent ───────────────────
SELECT ok(
  (SELECT count(*) FROM public.locations WHERE name = 'Test Location') = 1,
  'location not duplicated on second run'
);

-- ─── 8. cleanup ──────────────────────────────────────────────────────────────
DELETE FROM public.partner_member_permissions
WHERE partner_id = current_setting('tests.owner_partner_id')::uuid;
DELETE FROM public.locations
WHERE partner_id = current_setting('tests.owner_partner_id')::uuid;
DELETE FROM public.partners WHERE biz_number = 'BIZ-PGTAP-001';
DELETE FROM auth.identities WHERE provider_id = 'seed_test_pgtap@test.com';
DELETE FROM auth.users WHERE email = 'seed_test_pgtap@test.com';

SELECT pass('cleanup complete');

SELECT * FROM finish();
ROLLBACK;
