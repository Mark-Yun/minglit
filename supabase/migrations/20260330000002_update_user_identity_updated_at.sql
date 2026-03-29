-- Fix #808: update_user_identity RPC에 updated_at 추가
-- EF에서 별도 UPDATE 없이 RPC 하나로 모든 필드를 처리하기 위함
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
    is_verified = true,
    updated_at = now()
  WHERE id = p_user_id;
END;
$$;
