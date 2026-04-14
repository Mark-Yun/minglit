-- ============================================================
-- location_consent policy — 위치정보 이용약관 v1
-- 위치정보법 제21조에 따른 이용약관 정책 문서 등록.
-- ============================================================

-- 1. policies 테이블에 location_consent 정책 문서 삽입
INSERT INTO public.policies (key, value, version, effective_date, description) VALUES
(
  'location_consent',
  '{
    "content_url": "/location-terms",
    "service": "가까운 이벤트 검색 및 추천, 이벤트 장소까지의 거리 정보 제공",
    "fee": "무료",
    "collection_method": "GPS, Wi-Fi, 기지국 정보",
    "collection_timing": "앱 사용 중(foreground)에만 수집",
    "usage_scope": "가까운 이벤트 검색, 거리순 정렬, 이벤트 장소 안내",
    "retention": "별도 저장하지 않으며, 서비스 제공 목적 달성 후 즉시 파기",
    "refusal_consequence": "위치 기반 기능(거리순 검색 등) 제한"
  }'::jsonb,
  1,
  '2026-04-15'::timestamptz,
  '위치정보 이용약관 v1 (위치정보법 §21)'
);

-- 2. consent_key 컬럼 코멘트 업데이트 (location_consent 추가)
COMMENT ON COLUMN public.user_consents.consent_key IS 'Consent type identifier: terms_of_service, privacy_collection, age_confirmation, third_party_provision, marketing_consent, identity_verification, location_consent';
