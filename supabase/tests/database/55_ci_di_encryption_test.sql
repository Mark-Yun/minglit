-- Fix #807: CI/DI 암호화 마이그레이션 테스트
BEGIN;
SELECT plan(16);

-- ============================================================
-- 1. Schema: encrypted columns exist
-- ============================================================
SELECT has_column('user_profiles', 'ci_encrypted',
  'user_profiles should have ci_encrypted column');
SELECT col_type_is('user_profiles', 'ci_encrypted', 'bytea',
  'ci_encrypted should be bytea');

SELECT has_column('user_profiles', 'di_encrypted',
  'user_profiles should have di_encrypted column');
SELECT col_type_is('user_profiles', 'di_encrypted', 'bytea',
  'di_encrypted should be bytea');

SELECT has_column('user_profiles', 'di_hash',
  'user_profiles should have di_hash column');
SELECT col_type_is('user_profiles', 'di_hash', 'text',
  'di_hash should be text');

-- ============================================================
-- 2. di_hash UNIQUE constraint
-- ============================================================
SELECT has_index('user_profiles', 'user_profiles_di_hash_unique',
  'di_hash should have unique constraint');

-- ============================================================
-- 3. RPC functions exist
-- ============================================================
SELECT has_function('update_user_identity',
  'update_user_identity RPC should exist');
SELECT has_function('get_user_ci_di',
  'get_user_ci_di RPC should exist');

-- ============================================================
-- 4. RPC functions are SECURITY DEFINER
-- ============================================================
SELECT function_security_type_is('update_user_identity',
  ARRAY['uuid', 'text', 'text', 'text', 'date', 'gender', 'text'],
  'definer',
  'update_user_identity should be SECURITY DEFINER');
SELECT function_security_type_is('get_user_ci_di',
  ARRAY['uuid'],
  'definer',
  'get_user_ci_di should be SECURITY DEFINER');

-- ============================================================
-- 5. Encrypt/decrypt round-trip via RPC
-- ============================================================

-- Create a test user in auth.users first
INSERT INTO auth.users (id, email) VALUES
  ('a0000000-0000-0000-0000-000000000807', 'test-807@test.com');
-- handle_new_user trigger auto-creates user_profiles row

-- Call update_user_identity to encrypt
SELECT lives_ok($$
  SELECT public.update_user_identity(
    'a0000000-0000-0000-0000-000000000807'::uuid,
    'test_ci_value_807',
    'test_di_value_807',
    'Test User 807',
    '1990-01-01'::date,
    'male'::gender,
    '010-0000-0807'
  )
$$, 'update_user_identity should succeed for test user');

-- Verify encrypted columns are NOT NULL
SELECT isnt(
  (SELECT ci_encrypted FROM public.user_profiles WHERE id = 'a0000000-0000-0000-0000-000000000807'),
  NULL::bytea,
  'ci_encrypted should be populated after update_user_identity');

SELECT isnt(
  (SELECT di_hash FROM public.user_profiles WHERE id = 'a0000000-0000-0000-0000-000000000807'),
  NULL::text,
  'di_hash should be populated after update_user_identity');

-- Verify decrypt round-trip via get_user_ci_di
SELECT results_eq($$
  SELECT ci, di FROM public.get_user_ci_di('a0000000-0000-0000-0000-000000000807'::uuid)
$$, $$
  VALUES ('test_ci_value_807'::text, 'test_di_value_807'::text)
$$, 'get_user_ci_di should return decrypted values matching originals');

-- Verify di_hash is deterministic SHA-256
SELECT is(
  (SELECT di_hash FROM public.user_profiles WHERE id = 'a0000000-0000-0000-0000-000000000807'),
  encode(digest('test_di_value_807', 'sha256'), 'hex'),
  'di_hash should be SHA-256 hex of the DI value');

-- ============================================================
-- Cleanup
-- ============================================================
DELETE FROM auth.users WHERE id = 'a0000000-0000-0000-0000-000000000807';

SELECT * FROM finish();
ROLLBACK;
