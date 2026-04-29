-- Fix #2041: 마케팅 동의 2년 재확인 cron 함수 + retention_policies 등록
-- 정보통신망법 §50 ⑧항: 수신 동의 후 2년마다 재확인. 미응답 7일 후 자동 철회.
--
-- 처리 순서 (매일 03:00 UTC = 12:00 KST, cleanup-retention cron과 동일):
--   1. renewal_notified_at < now() - 7일 → consented=false, withdrawn_at=now() (자동 철회)
--   2. consented_at < now() - p_cutoff_days일
--      AND (renewal_notified_at IS NULL OR consented_at >= renewal_notified_at)
--      → pgmq_send(service 카테고리 갱신 안내) + renewal_notified_at=now()
--      ※ consented_at >= renewal_notified_at: 안내 후 사용자가 동의를 갱신한 경우
--        새 2년 주기가 시작됐으므로 다시 만료 시 재알림 대상이 됨

CREATE OR REPLACE FUNCTION admin.process_marketing_consent_renewals(
  p_cutoff_days int
)
RETURNS bigint
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, admin, public
AS $$
DECLARE
  v_withdrawn bigint := 0;
  v_notified  bigint := 0;
  v_user_id   uuid;
BEGIN
  -- 1. 갱신 안내 7일 이상 미응답 → 자동 철회
  --    consented_at < renewal_notified_at: 발송 후 앱에서 동의를 갱신한 경우 제외
  --    (consented_at이 renewal_notified_at보다 크면 사용자가 안내 후 동의를 갱신한 것)
  UPDATE public.user_consents
  SET withdrawn_at = now(),
      consented    = false
  WHERE consent_key          = 'marketing_consent'
    AND consented             = true
    AND withdrawn_at          IS NULL
    AND renewal_notified_at   IS NOT NULL
    AND renewal_notified_at   < now() - INTERVAL '7 days'
    AND consented_at          < renewal_notified_at;  -- Fix #2041: 발송 후 동의 갱신한 경우 제외

  GET DIAGNOSTICS v_withdrawn = ROW_COUNT;

  -- 2. 동의 만료(p_cutoff_days 이상) + 미알림 → 갱신 안내 푸시 발송
  FOR v_user_id IN
    SELECT uc.user_id
    FROM   public.user_consents uc
    WHERE  uc.consent_key        = 'marketing_consent'
      AND  uc.consented           = true
      AND  uc.withdrawn_at        IS NULL
      AND  (uc.renewal_notified_at IS NULL OR uc.consented_at >= uc.renewal_notified_at)
      AND  uc.consented_at        < now() - p_cutoff_days * INTERVAL '1 day'
  LOOP
    -- 서비스 카테고리 알림 — 광고성 아님, §50 마케팅 가드 면제
    PERFORM public.pgmq_send(
      'q_notifications',
      jsonb_build_object(
        'user_id',   v_user_id::text,
        'title',     '마케팅 수신 동의 갱신 안내',
        'body',      '마케팅 정보 수신 동의 기간(2년)이 만료되었습니다. '
                     '설정에서 동의를 갱신하지 않으시면 7일 후 자동으로 철회됩니다.',
        'category',  'service',
        'deep_link', null,
        'data',      '{}'::jsonb
      )
    );

    UPDATE public.user_consents
    SET    renewal_notified_at = now()
    WHERE  user_id    = v_user_id
      AND  consent_key = 'marketing_consent';

    v_notified := v_notified + 1;
  END LOOP;

  RETURN v_withdrawn + v_notified;
END;
$$;

REVOKE ALL ON FUNCTION admin.process_marketing_consent_renewals(int)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION admin.process_marketing_consent_renewals(int)
  TO service_role;

-- retention_policies 등록 (cleanup-retention cron이 매일 자동 실행)
INSERT INTO admin.retention_policies (
  id,
  kind,
  retention_days,
  legal_min_days,
  target,
  enabled,
  description,
  metadata
) VALUES (
  'marketing_consent_renewal',
  'db_custom_fn',
  730,
  730,
  jsonb_build_object('fn', 'admin.process_marketing_consent_renewals'),
  true,
  '정보통신망법 §50 ⑧항: 마케팅 동의 2년 재확인 — 만료 시 갱신 안내 푸시, 7일 미응답 시 자동 철회',
  jsonb_build_object(
    'auto_withdraw_days', 7,
    'notification_category', 'service'
  )
)
ON CONFLICT (id) DO NOTHING;
