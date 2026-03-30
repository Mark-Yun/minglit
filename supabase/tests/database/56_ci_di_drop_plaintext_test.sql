-- Fix #809: CI/DI 평문 컬럼 제거 검증 (Phase 3)
BEGIN;
SELECT plan(4);

-- ============================================================
-- 1. Plaintext ci/di columns must NOT exist
-- ============================================================
SELECT hasnt_column('user_profiles', 'ci',
  'plaintext ci column should be removed (Phase 3)');
SELECT hasnt_column('user_profiles', 'di',
  'plaintext di column should be removed (Phase 3)');

-- ============================================================
-- 2. Encrypted columns must still exist
-- ============================================================
SELECT has_column('user_profiles', 'ci_encrypted',
  'ci_encrypted column should still exist');
SELECT has_column('user_profiles', 'di_encrypted',
  'di_encrypted column should still exist');

SELECT * FROM finish();
ROLLBACK;
