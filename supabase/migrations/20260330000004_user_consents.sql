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
  CONSTRAINT user_consents_user_key_unique UNIQUE(user_id, consent_key)
);

COMMENT ON TABLE public.user_consents IS 'Per-user consent records for legal compliance (개인정보보호법 §15/§22)';
COMMENT ON COLUMN public.user_consents.consent_key IS 'Consent type identifier: terms_of_service, privacy_collection, age_confirmation, third_party_provision, marketing_consent, identity_verification';
COMMENT ON COLUMN public.user_consents.policy_version IS 'Version of the policy document the user consented to (references policies.version)';
COMMENT ON COLUMN public.user_consents.withdrawn_at IS 'Non-null when consent has been withdrawn; consented should be false';

-- ============================================================
-- 2. Indexes
-- ============================================================
CREATE INDEX idx_user_consents_user_id ON public.user_consents(user_id);

-- ============================================================
-- 3. RLS
-- ============================================================
ALTER TABLE public.user_consents ENABLE ROW LEVEL SECURITY;

CREATE POLICY "user_read_own_consents" ON public.user_consents
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "user_insert_own_consents" ON public.user_consents
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "user_update_own_consents" ON public.user_consents
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "service_role_all_consents" ON public.user_consents
  FOR ALL USING (auth.role() = 'service_role');

-- ============================================================
-- 4. GRANT
-- ============================================================
GRANT SELECT, INSERT, UPDATE ON public.user_consents TO authenticated;
GRANT ALL ON public.user_consents TO service_role;

-- ============================================================
-- 5. has_required_consents() RPC — route guard helper
-- Returns true only when all three required consents
-- (terms_of_service, privacy_collection, age_confirmation)
-- exist with consented = true for the calling user.
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
  )
  AND EXISTS (
    SELECT 1 FROM public.user_consents
    WHERE user_id = auth.uid()
      AND consent_key = 'privacy_collection'
      AND consented = true
  )
  AND EXISTS (
    SELECT 1 FROM public.user_consents
    WHERE user_id = auth.uid()
      AND consent_key = 'age_confirmation'
      AND consented = true
  );
$$;

REVOKE EXECUTE ON FUNCTION public.has_required_consents() FROM public;
GRANT EXECUTE ON FUNCTION public.has_required_consents() TO authenticated, service_role;

-- ============================================================
-- 6. policies seed — consent policy documents v1
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
