-- Phase 3: Drop legacy plaintext ci/di columns
-- Fix #809: CI/DI 레거시 평문 컬럼 제거

-- Safety check: ensure all rows have been migrated
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM user_profiles WHERE ci IS NOT NULL AND ci_encrypted IS NULL) THEN
    RAISE EXCEPTION 'Unmigrated rows exist — abort column drop';
  END IF;
END $$;

-- Drop legacy columns
ALTER TABLE user_profiles DROP COLUMN IF EXISTS ci;
ALTER TABLE user_profiles DROP COLUMN IF EXISTS di;
