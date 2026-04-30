-- Fix #2054: save_user_consents가 client-supplied timestamptz/policy_version을 신뢰하는 문제 수정.
-- jsonb_to_recordset에서 consented_at/withdrawn_at 컬럼 제거, 항상 서버 now() 사용.
-- policy_version 다운그레이드 방지: GREATEST()로 더 낮은 버전 입력 거부.

CREATE OR REPLACE FUNCTION public.save_user_consents(
  p_user_id uuid,
  p_consents jsonb
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_auth_user_id uuid := auth.uid();
  v_now timestamptz := now();
BEGIN
  IF v_auth_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  IF v_auth_user_id IS DISTINCT FROM p_user_id THEN
    RAISE EXCEPTION 'Cannot write consents for another user';
  END IF;

  IF COALESCE(jsonb_typeof(p_consents), 'null') <> 'array' THEN
    RAISE EXCEPTION 'p_consents must be a JSON array';
  END IF;

  INSERT INTO public.user_consents (
    user_id,
    consent_key,
    consented,
    policy_version,
    consented_at,
    withdrawn_at
  )
  SELECT
    p_user_id,
    entry.consent_key,
    entry.consented,
    entry.policy_version,
    v_now,
    CASE WHEN entry.consented THEN NULL ELSE v_now END
  FROM jsonb_to_recordset(p_consents) AS entry(
    consent_key text,
    consented boolean,
    policy_version integer
    -- consented_at / withdrawn_at 컬럼 제거 — 클라 입력값 무시, v_now 강제
  )
  ON CONFLICT (user_id, consent_key) DO UPDATE
  SET
    consented      = EXCLUDED.consented,
    -- policy_version 다운그레이드 거부: 기존 버전보다 낮은 값은 무시
    policy_version = GREATEST(
      COALESCE(EXCLUDED.policy_version, public.user_consents.policy_version),
      COALESCE(public.user_consents.policy_version, EXCLUDED.policy_version)
    ),
    consented_at   = CASE
      WHEN EXCLUDED.consented THEN v_now
      ELSE public.user_consents.consented_at
    END,
    withdrawn_at   = CASE
      WHEN EXCLUDED.consented THEN NULL
      ELSE v_now
    END;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.save_user_consents(uuid, jsonb) FROM public;
GRANT EXECUTE ON FUNCTION public.save_user_consents(uuid, jsonb) TO authenticated, service_role;
