-- Regression test for #1679: seed reset logic must always restore
-- partner_apply_pending application status to 'pending', even when it was
-- manually changed to 'approved'. Without the fix, an admin test corrupts
-- the account and it routes to / instead of /apply/status in QA smoke runs.
--
-- Self-contained: creates its own fixtures — does NOT rely on dev seed data.
BEGIN;

SELECT plan(5);

SELECT tests.authenticate_as_service_role();

-- TEMP TABLE to pass user_id between DO blocks without querying auth.users directly
CREATE TEMP TABLE _regression_1679_state (
  user_id uuid
) ON COMMIT DROP;

-- ── fixtures ──────────────────────────────────────────────────────────────────
DO $$
DECLARE
  v_user_id uuid;
BEGIN
  v_user_id := tests.create_supabase_user(
    'regression_apply_pending_1679',
    'regression_apply_pending_1679@pgtap.local'
  );

  INSERT INTO _regression_1679_state (user_id) VALUES (v_user_id);

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
-- pg_temp schema: session always has CREATE privilege (no public schema ownership needed)
CREATE OR REPLACE FUNCTION pg_temp._regression_reset_apply_pending()
RETURNS void AS $$
DECLARE
  apply_user_id uuid;
BEGIN
  SELECT user_id INTO apply_user_id FROM _regression_1679_state LIMIT 1;

  IF apply_user_id IS NOT NULL THEN
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
  (SELECT count(*) FROM _regression_1679_state) = 1,
  'fixture user created successfully'
);

-- 2. After fixture insert: status is 'pending'
SELECT ok(
  EXISTS(
    SELECT 1
    FROM public.partner_applications pa
    WHERE pa.user_id = (SELECT user_id FROM _regression_1679_state LIMIT 1)
      AND pa.status = 'pending'
  ),
  'initial fixture: most-recent application has status=pending'
);

-- 3. Simulate contamination: admin changes status to 'approved'
UPDATE public.partner_applications
SET status = 'approved'
WHERE user_id = (SELECT user_id FROM _regression_1679_state LIMIT 1)
AND id = (
  SELECT id FROM public.partner_applications
  WHERE user_id = (SELECT user_id FROM _regression_1679_state LIMIT 1)
  ORDER BY created_at DESC
  LIMIT 1
);

SELECT ok(
  EXISTS(
    SELECT 1
    FROM public.partner_applications pa
    WHERE pa.user_id = (SELECT user_id FROM _regression_1679_state LIMIT 1)
      AND pa.status = 'approved'
  ),
  'contamination simulated: status changed to approved'
);

-- 4. Re-run seed reset (reproduces what seed.dev.sql does on next run)
SELECT pg_temp._regression_reset_apply_pending();

-- 5. After re-seed: status is back to 'pending'
SELECT ok(
  EXISTS(
    SELECT 1
    FROM public.partner_applications pa
    WHERE pa.user_id = (SELECT user_id FROM _regression_1679_state LIMIT 1)
      AND pa.status = 'pending'
  ),
  'after re-seed: status reset to pending even when previously approved'
);

SELECT * FROM finish();
ROLLBACK;
