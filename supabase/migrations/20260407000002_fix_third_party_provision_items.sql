-- Fix #1141: third_party_provision 동의서 제공 항목을 앱 동의서와 동기화
-- 성별 제거, 자격 인증 정보 추가 — signup_consent_page.dart와 일치시킴
UPDATE public.policies
SET
  value = jsonb_set(
    jsonb_set(
      value,
      '{items}',
      '["이름","연령대","자격 인증 정보(직업/소속 — 본인인증 완료 유저만)"]'
    ),
    '{refusal_consequence}',
    '"기본 서비스 이용은 가능하나, 파트너 승인/확인이 필요한 이벤트 참여가 제한될 수 있습니다"'
  )
WHERE key = 'third_party_provision';
