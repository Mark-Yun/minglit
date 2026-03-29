-- Fix #807: CI/DI 암호화 저장 (개인정보보호법 제29조)
-- Phase 1: pgcrypto + Vault 하이브리드 암호화
-- - 새 암호화 컬럼 추가 (ci_encrypted, di_encrypted, di_hash)
-- - update_user_identity / get_user_ci_di RPC 생성
-- - 기존 평문 데이터 배치 암호화
-- - protect_user_profile_fields 트리거 업데이트
-- 주의: 기존 ci, di 컬럼은 이 단계에서 제거하지 않음 (Phase 3에서 제거)

SET search_path TO public, extensions;

-- ============================================================
-- 1. Ensure pgcrypto extension
-- ============================================================
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ============================================================
-- 2. Add encrypted columns
-- ============================================================
ALTER TABLE public.user_profiles
  ADD COLUMN IF NOT EXISTS ci_encrypted bytea,
  ADD COLUMN IF NOT EXISTS di_encrypted bytea,
  ADD COLUMN IF NOT EXISTS di_hash text;

-- ============================================================
-- 3. Vault encryption key
-- ============================================================
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM vault.decrypted_secrets WHERE name = 'pii_encryption_key'
  ) THEN
    PERFORM vault.create_secret(
      encode(gen_random_bytes(32), 'hex'),
      'pii_encryption_key',
      'Symmetric key for CI/DI PII encryption (pgp_sym_encrypt)'
    );
    RAISE NOTICE 'vault: pii_encryption_key created with random key';
  ELSE
    RAISE NOTICE 'vault: pii_encryption_key already exists';
  END IF;
END $$;

-- ============================================================
-- 4. update_user_identity RPC (encrypt + store)
-- ============================================================
CREATE OR REPLACE FUNCTION public.update_user_identity(
  p_user_id uuid,
  p_ci text,
  p_di text,
  p_name text DEFAULT NULL,
  p_birth_date date DEFAULT NULL,
  p_gender public.gender DEFAULT NULL,
  p_phone_number text DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_key text;
BEGIN
  -- Retrieve encryption key from vault
  SELECT decrypted_secret INTO v_key
  FROM vault.decrypted_secrets
  WHERE name = 'pii_encryption_key'
  LIMIT 1;

  IF v_key IS NULL THEN
    RAISE EXCEPTION 'pii_encryption_key not found in vault';
  END IF;

  UPDATE public.user_profiles SET
    ci_encrypted = pgp_sym_encrypt(p_ci, v_key),
    di_encrypted = pgp_sym_encrypt(p_di, v_key),
    di_hash = encode(digest(p_di, 'sha256'), 'hex'),
    name = COALESCE(p_name, name),
    birth_date = COALESCE(p_birth_date, birth_date),
    gender = COALESCE(p_gender, gender),
    phone_number = COALESCE(p_phone_number, phone_number),
    is_verified = true
  WHERE id = p_user_id;
END;
$$;

-- Only service_role can call this RPC
REVOKE ALL ON FUNCTION public.update_user_identity(uuid, text, text, text, date, public.gender, text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.update_user_identity(uuid, text, text, text, date, public.gender, text) FROM authenticated;
REVOKE ALL ON FUNCTION public.update_user_identity(uuid, text, text, text, date, public.gender, text) FROM anon;

-- ============================================================
-- 5. get_user_ci_di RPC (decrypt + return)
-- ============================================================
CREATE OR REPLACE FUNCTION public.get_user_ci_di(p_user_id uuid)
RETURNS TABLE(ci text, di text)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_key text;
BEGIN
  SELECT decrypted_secret INTO v_key
  FROM vault.decrypted_secrets
  WHERE name = 'pii_encryption_key'
  LIMIT 1;

  IF v_key IS NULL THEN
    RAISE EXCEPTION 'pii_encryption_key not found in vault';
  END IF;

  RETURN QUERY
  SELECT
    pgp_sym_decrypt(up.ci_encrypted, v_key) AS ci,
    pgp_sym_decrypt(up.di_encrypted, v_key) AS di
  FROM public.user_profiles up
  WHERE up.id = p_user_id
    AND up.ci_encrypted IS NOT NULL;
END;
$$;

-- Only service_role can call this RPC
REVOKE ALL ON FUNCTION public.get_user_ci_di(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.get_user_ci_di(uuid) FROM authenticated;
REVOKE ALL ON FUNCTION public.get_user_ci_di(uuid) FROM anon;

-- ============================================================
-- 6. Batch encrypt existing plaintext data
-- ============================================================
DO $$
DECLARE
  v_key text;
  v_count integer;
BEGIN
  SELECT decrypted_secret INTO v_key
  FROM vault.decrypted_secrets
  WHERE name = 'pii_encryption_key'
  LIMIT 1;

  IF v_key IS NULL THEN
    RAISE EXCEPTION 'pii_encryption_key not found in vault';
  END IF;

  UPDATE public.user_profiles SET
    ci_encrypted = pgp_sym_encrypt(ci, v_key),
    di_encrypted = pgp_sym_encrypt(di, v_key),
    di_hash = encode(digest(di, 'sha256'), 'hex')
  WHERE ci IS NOT NULL AND ci_encrypted IS NULL;

  GET DIAGNOSTICS v_count = ROW_COUNT;
  RAISE NOTICE 'Batch encrypted % existing rows', v_count;
END $$;

-- ============================================================
-- 7. di_hash UNIQUE constraint
-- ============================================================
ALTER TABLE public.user_profiles
  ADD CONSTRAINT user_profiles_di_hash_unique UNIQUE (di_hash);

-- ============================================================
-- 8. Update protect_user_profile_fields trigger
-- ============================================================
CREATE OR REPLACE FUNCTION public.protect_user_profile_fields()
RETURNS trigger
SET search_path = public
AS $$
BEGIN
  -- Fix #807: protect verification status from direct update by non-admin users
  IF (NEW.is_verified IS DISTINCT FROM OLD.is_verified) THEN
    IF (auth.role() = 'authenticated' AND NOT public.is_super_admin()) THEN
      RAISE EXCEPTION 'You cannot update verification status directly. (Access Denied)';
    END IF;
  END IF;

  -- Fix #807: protect encrypted PII columns from direct update by non-service-role
  IF (NEW.ci_encrypted IS DISTINCT FROM OLD.ci_encrypted)
     OR (NEW.di_encrypted IS DISTINCT FROM OLD.di_encrypted)
     OR (NEW.di_hash IS DISTINCT FROM OLD.di_hash) THEN
    IF (auth.role() = 'authenticated' AND NOT public.is_super_admin()) THEN
      RAISE EXCEPTION 'Encrypted identity fields can only be updated via update_user_identity RPC. (Access Denied)';
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
