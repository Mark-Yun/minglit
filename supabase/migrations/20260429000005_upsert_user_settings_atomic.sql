-- Fix #2040: user_settings + user_consents 원자적 갱신 RPC
-- 두 테이블을 단일 트랜잭션으로 처리해 partial write 방지

CREATE OR REPLACE FUNCTION public.upsert_user_settings_with_consent(
  p_user_id             uuid,
  p_marketing_consent   boolean DEFAULT NULL,
  p_service_notification boolean DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_result jsonb;
  v_now    timestamptz := now();
BEGIN
  INSERT INTO public.user_settings (user_id, marketing_consent, service_notification, updated_at)
  VALUES (
    p_user_id,
    COALESCE(p_marketing_consent, false),
    COALESCE(p_service_notification, true),
    v_now
  )
  ON CONFLICT (user_id) DO UPDATE SET
    marketing_consent    = CASE WHEN p_marketing_consent IS NOT NULL
                                THEN p_marketing_consent
                                ELSE user_settings.marketing_consent END,
    service_notification = CASE WHEN p_service_notification IS NOT NULL
                                THEN p_service_notification
                                ELSE user_settings.service_notification END,
    updated_at = v_now
  RETURNING to_jsonb(user_settings.*) INTO v_result;

  IF p_marketing_consent IS NOT NULL THEN
    INSERT INTO public.user_consents (
      user_id, consent_key, consented, consented_at, withdrawn_at
    ) VALUES (
      p_user_id,
      'marketing_consent',
      p_marketing_consent,
      v_now,
      CASE WHEN p_marketing_consent THEN NULL ELSE v_now END
    )
    ON CONFLICT (user_id, consent_key) DO UPDATE SET
      consented    = p_marketing_consent,
      consented_at = CASE WHEN p_marketing_consent THEN v_now
                          ELSE user_consents.consented_at END,
      withdrawn_at = CASE WHEN p_marketing_consent THEN NULL ELSE v_now END;
  END IF;

  RETURN v_result;
END;
$$;

REVOKE ALL ON FUNCTION public.upsert_user_settings_with_consent(uuid, boolean, boolean)
  FROM public, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.upsert_user_settings_with_consent(uuid, boolean, boolean)
  TO service_role;
