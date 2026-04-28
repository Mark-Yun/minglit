-- Fix #2041: 마케팅 동의 2년 재확인 추적 컬럼 추가
-- 정보통신망법 §50 ⑧항 (시행령 §62의3): 마케팅 수신 동의 후 2년마다 재확인 의무

ALTER TABLE public.user_consents
  ADD COLUMN IF NOT EXISTS renewal_notified_at timestamptz;

COMMENT ON COLUMN public.user_consents.renewal_notified_at IS
  '§50 ⑧ 재확인 푸시 발송 시각. NULL이면 미발송, NOT NULL이면 발송됨. '
  '사용자가 동의를 갱신하면 NULL로 리셋.';

CREATE INDEX IF NOT EXISTS idx_user_consents_renewal_notified
  ON public.user_consents(renewal_notified_at)
  WHERE consent_key = 'marketing_consent'
    AND withdrawn_at IS NULL;
