-- Regression test for #1679: seed reset logic must always restore
-- partner_apply_pending application status to 'pending', even when it was
-- manually changed to 'approved'. Without the fix, an admin test corrupts
-- the account and it routes to / instead of /apply/status in QA smoke runs.
--
-- Self-contained: creates its own fixtures — does NOT rely on dev seed data.
BEGIN;

SELECT plan(5);

SELECT tests.authenticate_as_service_role();

-- ── fixtures ──────────────────────────────────────────────────────────────────
DO $$
DECLARE
  v_user_id uuid;
BEGIN
  -- Create test user with a unique identifier; email is auto-generated.
  v_user_id := tests.create_supabase_user(
    'regression_apply_pending_1679',
    'regression_apply_pending_1679@pgtap.local'
  );

  -- Insert a partner_applications row in 'pending' state (mirrors seed logic).
  INSERT INTO public.partner_applications (
    user_id, status, brand_name, biz_type, biz_name, biz_number,
    representative_name, bank_name, account_number, account_holder,
    biz_registration_path, bankbook_path
  ) VALUES (
    v_user_id, 'pending', '심사 대기 브랜드', 'individual', '심사 대기 사업자',
    '888-88-88888', '심사 대기 대표', '신한은행', '110-888-888880', '심사 대기 대표',
    'seed/biz_registration.png', 'seed/bankbook.png'
  );
END $$;

-- ── helper: mirrors seed.dev.sql Fix #1679 reset logic ───────────────────────
CREATE OR REPLACE FUNCTION _regression_reset_apply_pending()
RETURNS void AS $$
DECLARE
  apply_user_id uuid;
BEGIN
  SELECT id INTO apply_user_id
  FROM auth.users
  WHERE email = 'regression_apply_pending_1679@pgtap.local';

  IF apply_user_id IS NOT NULL THEN
    -- INSERT if somehow missing (mirrors seed idempotency guard).
    INSERT INTO public.partner_applications (
      user_id, status, brand_name, biz_type, biz_name, biz_number,
      representative_name, bank_name, account_number, account_holder,
      biz_registration_path, bankbook_path
    )
    SELECT apply_user_id, 'pending', '심사 대기 브랜드', 'individual', '심사 대기 사업자',
           '888-88-88888', '심사 대기 대표', '신한은행', '110-888-888880', '심사 대기 대표',
           'seed/biz_registration.png', 'seed/bankbook.png'
    WHERE NOT EXISTS (
      SELECT 1 FROM public.partner_applications WHERE user_id = apply_user_id
    );
    -- Force-reset status to 'pending' (the Fix #1679 invariant).
    UPDATE public.partner_applications
    SET status = 'pending'
    WHERE id = (
      SELECT id FROM public.partner_applications
      WHERE user_id = apply_user_id
      ORDER BY created_at DESC
      LIMIT 1
    );
  END IF;
END;
$$ LANGUAGE plpgsql;

-- 1. Fixture user was created successfully
SELECT ok(
  EXISTS(SELECT 1 FROM auth.users WHERE email = 'regression_apply_pending_1679@pgtap.local'),
  'fixture user regression_apply_pending_1679@pgtap.local exists'
);

-- 2. After fixture insert: status is 'pending'
SELECT ok(
  EXISTS(
    SELECT 1
    FROM public.partner_applications pa
    JOIN auth.users u ON u.id = pa.user_id
    WHERE u.email = 'regression_apply_pending_1679@pgtap.local'
      AND pa.status = 'pending'
  ),
  'initial fixture: most-recent application has status=pending'
);

-- 3. Simulate contamination: admin changes status to 'approved'
UPDATE public.partner_applications
SET status = 'approved'
WHERE user_id = (
  SELECT id FROM auth.users WHERE email = 'regression_apply_pending_1679@pgtap.local'
)
AND id = (
  SELECT pa.id FROM public.partner_applications pa
  JOIN auth.users u ON u.id = pa.user_id
  WHERE u.email = 'regression_apply_pending_1679@pgtap.local'
  ORDER BY pa.created_at DESC
  LIMIT 1
);

SELECT ok(
  EXISTS(
    SELECT 1
    FROM public.partner_applications pa
    JOIN auth.users u ON u.id = pa.user_id
    WHERE u.email = 'regression_apply_pending_1679@pgtap.local'
      AND pa.status = 'approved'
  ),
  'contamination simulated: status changed to approved'
);

-- 4. Re-run seed reset (reproduces what seed.dev.sql does on next run)
SELECT _regression_reset_apply_pending();

-- 5. After re-seed: status is back to 'pending'
SELECT ok(
  EXISTS(
    SELECT 1
    FROM public.partner_applications pa
    JOIN auth.users u ON u.id = pa.user_id
    WHERE u.email = 'regression_apply_pending_1679@pgtap.local'
      AND pa.status = 'pending'
  ),
  'after re-seed: status reset to pending even when previously approved'
);

SELECT * FROM finish();
ROLLBACK;
