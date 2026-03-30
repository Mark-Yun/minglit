-- ============================================================
-- user_consents — User consent records for privacy compliance
-- Tracks explicit user consents per Korean PIPA (개인정보보호법)
-- Article 15 (collection), Article 22 (consent method).
-- ============================================================

-- ============================================================
-- 1. user_consents table
-- ============================================================
CREATE TABLE public.user_consents (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  consent_key text NOT NULL,
  consented boolean NOT NULL,
  policy_version integer,
  consented_at timestamptz NOT NULL DEFAULT now(),
  withdrawn_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT user_consents_user_key_unique UNIQUE(user_id, consent_key),
  CONSTRAINT user_consents_consented_state_check CHECK (
    (consented = true AND withdrawn_at IS NULL)
    OR (consented = false AND withdrawn_at IS NOT NULL)
  )
);

COMMENT ON TABLE public.user_consents IS 'Per-user consent records for legal compliance (개인정보보호법 §15/§22)';
COMMENT ON COLUMN public.user_consents.consent_key IS 'Consent type identifier: terms_of_service, privacy_collection, age_confirmation, third_party_provision, marketing_consent, identity_verification';
COMMENT ON COLUMN public.user_consents.policy_version IS 'Version of the policy document the user consented to (references policies.version)';
COMMENT ON COLUMN public.user_consents.withdrawn_at IS 'Non-null when consent has been withdrawn; consented should be false';

-- ============================================================
-- 2. Indexes
-- ============================================================
CREATE INDEX idx_user_consents_user_id ON public.user_consents(user_id);
CREATE INDEX idx_user_consents_type_active
  ON public.user_consents(consent_key)
  WHERE withdrawn_at IS NULL;

-- ============================================================
-- 3. RLS
-- ============================================================
ALTER TABLE public.user_consents ENABLE ROW LEVEL SECURITY;

CREATE POLICY "user_read_own_consents" ON public.user_consents
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

-- ============================================================
-- 4. GRANT
-- ============================================================
GRANT SELECT ON public.user_consents TO authenticated;
GRANT ALL ON public.user_consents TO service_role;

-- ============================================================
-- 5. save_user_consents() RPC — authenticated write entrypoint
-- Uses auth.uid() as the source of truth and upserts current consent state.
-- ============================================================
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
    COALESCE(entry.consented_at, now()),
    CASE
      WHEN entry.consented THEN NULL
      ELSE COALESCE(entry.withdrawn_at, now())
    END
  FROM jsonb_to_recordset(p_consents) AS entry(
    consent_key text,
    consented boolean,
    policy_version integer,
    consented_at timestamptz,
    withdrawn_at timestamptz
  )
  ON CONFLICT (user_id, consent_key) DO UPDATE
  SET
    consented = EXCLUDED.consented,
    policy_version = COALESCE(EXCLUDED.policy_version, public.user_consents.policy_version),
    consented_at = CASE
      WHEN EXCLUDED.consented THEN EXCLUDED.consented_at
      ELSE public.user_consents.consented_at
    END,
    withdrawn_at = CASE
      WHEN EXCLUDED.consented THEN NULL
      ELSE COALESCE(EXCLUDED.withdrawn_at, now())
    END;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.save_user_consents(uuid, jsonb) FROM public;
GRANT EXECUTE ON FUNCTION public.save_user_consents(uuid, jsonb) TO authenticated, service_role;

-- ============================================================
-- 6. has_required_consents() RPC — route guard helper
-- Returns true only when all three required consents
-- (terms_of_service, privacy_collection, age_confirmation)
-- exist with active consent rows for the calling user.
-- ============================================================
CREATE OR REPLACE FUNCTION public.has_required_consents()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.user_consents
    WHERE user_id = auth.uid()
      AND consent_key = 'terms_of_service'
      AND consented = true
      AND withdrawn_at IS NULL
  )
  AND EXISTS (
    SELECT 1 FROM public.user_consents
    WHERE user_id = auth.uid()
      AND consent_key = 'privacy_collection'
      AND consented = true
      AND withdrawn_at IS NULL
  )
  AND EXISTS (
    SELECT 1 FROM public.user_consents
    WHERE user_id = auth.uid()
      AND consent_key = 'age_confirmation'
      AND consented = true
      AND withdrawn_at IS NULL
  );
$$;

REVOKE EXECUTE ON FUNCTION public.has_required_consents() FROM public;
GRANT EXECUTE ON FUNCTION public.has_required_consents() TO authenticated, service_role;

-- ============================================================
-- 7. policies seed — consent policy documents v1
-- ============================================================
INSERT INTO public.policies (key, value, version, effective_date, description) VALUES
(
  'terms_of_service',
  '{"content_url": "/terms"}'::jsonb,
  1,
  '2026-03-30'::timestamptz,
  '서비스 이용약관 v1'
),
(
  'privacy_collection',
  '{"items": ["이름","이메일","프로필 사진","관심 태그"], "purpose": "서비스 제공 (계정 관리, 이벤트 매칭, 프로필 표시)", "retention": "회원 탈퇴 시까지", "refusal_consequence": "서비스 이용 불가"}'::jsonb,
  1,
  '2026-03-30'::timestamptz,
  '개인정보 수집·이용 동의서 v1'
),
(
  'third_party_provision',
  '{"recipient": "이벤트 주최 파트너", "items": ["이름","성별","연령대"], "purpose": "이벤트 운영 (참가자 확인, 매칭, 체크인)", "retention": "이벤트 종료 후 30일", "refusal_consequence": "이벤트 신청 시 개별 동의 필요"}'::jsonb,
  1,
  '2026-03-30'::timestamptz,
  '제3자 제공 동의서 v1'
),
(
  'marketing_consent',
  '{"channels": ["push","email"], "purpose": "이벤트/혜택 안내", "refusal_consequence": "없음"}'::jsonb,
  1,
  '2026-03-30'::timestamptz,
  '마케팅 정보 수신 동의서 v1'
);
