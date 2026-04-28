-- pgTAP tests for #2041: 마케팅 동의 2년 재확인 (정보통신망법 §50 ⑧항)
--
-- 검증 항목:
--   1. renewal_notified_at 컬럼 존재 및 인덱스
--   2. retention_policies 등록 확인 (kind, retention_days, enabled, target)
--   3. admin.process_marketing_consent_renewals 함수 존재
--   4. 만료 동의 → 갱신 안내 발송(renewal_notified_at 설정)
--   5. 이미 발송된 사용자 → 재발송 없음 (idempotent)
--   6. 발송 후 7일 이상 미응답 → 자동 철회 (consented=false, withdrawn_at 설정)
--   7. 발송 후 7일 미만 → 철회 없음
--   8. 갱신한 사용자(renewal_notified_at=NULL 리셋) → 자동 철회 없음

BEGIN;

SELECT plan(20);

SELECT tests.authenticate_as_service_role();

-- ── 1. 스키마 확인 ────────────────────────────────────────────────────────────

-- 1. renewal_notified_at 컬럼 존재
SELECT ok(
  EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name   = 'user_consents'
      AND column_name  = 'renewal_notified_at'
  ),
  '#2041: user_consents.renewal_notified_at column exists'
);

-- 2. 인덱스 존재
SELECT ok(
  EXISTS (
    SELECT 1 FROM pg_indexes
    WHERE schemaname = 'public'
      AND tablename  = 'user_consents'
      AND indexname  = 'idx_user_consents_renewal_notified'
  ),
  '#2041: idx_user_consents_renewal_notified index exists'
);

-- ── 2. retention_policies 등록 확인 ──────────────────────────────────────────

-- 3. policy 존재
SELECT ok(
  EXISTS (SELECT 1 FROM admin.retention_policies WHERE id = 'marketing_consent_renewal'),
  '#2041: marketing_consent_renewal policy registered'
);

-- 4. kind = db_custom_fn
SELECT is(
  (SELECT kind::text FROM admin.retention_policies WHERE id = 'marketing_consent_renewal'),
  'db_custom_fn',
  '#2041: policy kind is db_custom_fn'
);

-- 5. retention_days = 730
SELECT is(
  (SELECT retention_days FROM admin.retention_policies WHERE id = 'marketing_consent_renewal'),
  730,
  '#2041: retention_days = 730 (2년)'
);

-- 6. legal_min_days = 730
SELECT is(
  (SELECT legal_min_days FROM admin.retention_policies WHERE id = 'marketing_consent_renewal'),
  730,
  '#2041: legal_min_days = 730 (§50 ⑧항 최소 2년)'
);

-- 7. enabled = true
SELECT ok(
  (SELECT enabled FROM admin.retention_policies WHERE id = 'marketing_consent_renewal'),
  '#2041: policy enabled = true'
);

-- 8. target.fn 설정 확인
SELECT is(
  (SELECT target->>'fn' FROM admin.retention_policies WHERE id = 'marketing_consent_renewal'),
  'admin.process_marketing_consent_renewals',
  '#2041: target.fn = admin.process_marketing_consent_renewals'
);

-- ── 3. 함수 시그니처 확인 ─────────────────────────────────────────────────────

-- 9. 함수 존재
SELECT ok(
  EXISTS (
    SELECT 1 FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname = 'admin'
      AND p.proname = 'process_marketing_consent_renewals'
  ),
  '#2041: admin.process_marketing_consent_renewals function exists'
);

-- ── 4. 핵심 로직 검증 ────────────────────────────────────────────────────────

DO $$
DECLARE
  v_expired_user   uuid;
  v_notified_user  uuid;
  v_renewed_user   uuid;
  v_fresh_user     uuid;
BEGIN
  -- 사용자 생성
  v_expired_user  := tests.create_supabase_user('consent_2041_expired',  'consent_2041_expired@pgtap.local');
  v_notified_user := tests.create_supabase_user('consent_2041_notified', 'consent_2041_notified@pgtap.local');
  v_renewed_user  := tests.create_supabase_user('consent_2041_renewed',  'consent_2041_renewed@pgtap.local');
  v_fresh_user    := tests.create_supabase_user('consent_2041_fresh',    'consent_2041_fresh@pgtap.local');

  -- fixture A: 731일 전 마케팅 동의 (만료) — 갱신 안내 발송 대상
  INSERT INTO public.user_consents
    (user_id, consent_key, consented, consented_at, withdrawn_at, renewal_notified_at)
  VALUES
    (v_expired_user, 'marketing_consent', true, now() - INTERVAL '731 days', NULL, NULL);

  -- fixture B: 731일 전 마케팅 동의 + 이미 갱신 안내 발송됨 (1일 전) — 재발송 없음
  INSERT INTO public.user_consents
    (user_id, consent_key, consented, consented_at, withdrawn_at, renewal_notified_at)
  VALUES
    (v_notified_user, 'marketing_consent', true, now() - INTERVAL '731 days', NULL, now() - INTERVAL '1 day');

  -- fixture C: 731일 전 마케팅 동의 + 8일 전 갱신 안내 + 사용자가 갱신 완료
  --   (갱신 시 앱이 consented_at=now(), renewal_notified_at=NULL로 리셋)
  INSERT INTO public.user_consents
    (user_id, consent_key, consented, consented_at, withdrawn_at, renewal_notified_at)
  VALUES
    (v_renewed_user, 'marketing_consent', true, now(), NULL, NULL);

  -- fixture D: 100일 전 마케팅 동의 (미만료) — 처리 없음
  INSERT INTO public.user_consents
    (user_id, consent_key, consented, consented_at, withdrawn_at, renewal_notified_at)
  VALUES
    (v_fresh_user, 'marketing_consent', true, now() - INTERVAL '100 days', NULL, NULL);

  PERFORM set_config('renewal_test.expired_user',   v_expired_user::text,   true);
  PERFORM set_config('renewal_test.notified_user',  v_notified_user::text,  true);
  PERFORM set_config('renewal_test.renewed_user',   v_renewed_user::text,   true);
  PERFORM set_config('renewal_test.fresh_user',     v_fresh_user::text,     true);
END $$;

-- 10. fixture A: renewal_notified_at IS NULL before run
SELECT ok(
  (SELECT renewal_notified_at IS NULL
     FROM public.user_consents
    WHERE user_id = current_setting('renewal_test.expired_user')::uuid
      AND consent_key = 'marketing_consent'),
  'fixture A: renewal_notified_at is NULL before function call'
);

-- 만료 사용자에 대한 갱신 안내 실행 (730일 cutoff)
SELECT admin.process_marketing_consent_renewals(730);

-- 11. fixture A: renewal_notified_at IS NOT NULL (갱신 안내 발송됨)
SELECT ok(
  (SELECT renewal_notified_at IS NOT NULL
     FROM public.user_consents
    WHERE user_id = current_setting('renewal_test.expired_user')::uuid
      AND consent_key = 'marketing_consent'),
  '#2041: 만료 사용자에게 갱신 안내 발송 — renewal_notified_at 설정됨'
);

-- 12. fixture B: renewal_notified_at 변경 없음 (이미 발송됨, 재발송 없음)
SELECT ok(
  (SELECT renewal_notified_at < now() - INTERVAL '30 minutes'
     FROM public.user_consents
    WHERE user_id = current_setting('renewal_test.notified_user')::uuid
      AND consent_key = 'marketing_consent'),
  '#2041: 이미 발송된 사용자는 재발송 없음 — renewal_notified_at 갱신 안 됨'
);

-- 13. fixture D: fresh user는 renewal_notified_at IS NULL (100일, 미만료)
SELECT ok(
  (SELECT renewal_notified_at IS NULL
     FROM public.user_consents
    WHERE user_id = current_setting('renewal_test.fresh_user')::uuid
      AND consent_key = 'marketing_consent'),
  '#2041: 미만료 사용자(100일)는 갱신 안내 미발송'
);

-- 14. fixture C: renewed user consented=true, withdrawn_at IS NULL (갱신 완료, 철회 없음)
SELECT ok(
  (SELECT consented = true AND withdrawn_at IS NULL
     FROM public.user_consents
    WHERE user_id = current_setting('renewal_test.renewed_user')::uuid
      AND consent_key = 'marketing_consent'),
  '#2041: 갱신 완료 사용자는 철회 없음'
);

-- ── 5. 자동 철회 검증 ─────────────────────────────────────────────────────────

DO $$
DECLARE
  v_overdue_user uuid;
  v_recent_user  uuid;
BEGIN
  -- fixture E: 갱신 안내 8일 전 발송 + 미응답 → 자동 철회 대상
  v_overdue_user := tests.create_supabase_user('consent_2041_overdue', 'consent_2041_overdue@pgtap.local');
  INSERT INTO public.user_consents
    (user_id, consent_key, consented, consented_at, withdrawn_at, renewal_notified_at)
  VALUES
    (v_overdue_user, 'marketing_consent', true, now() - INTERVAL '731 days', NULL,
     now() - INTERVAL '8 days');

  -- fixture F: 갱신 안내 6일 전 발송 → 아직 철회 없음
  v_recent_user := tests.create_supabase_user('consent_2041_recent', 'consent_2041_recent@pgtap.local');
  INSERT INTO public.user_consents
    (user_id, consent_key, consented, consented_at, withdrawn_at, renewal_notified_at)
  VALUES
    (v_recent_user, 'marketing_consent', true, now() - INTERVAL '731 days', NULL,
     now() - INTERVAL '6 days');

  PERFORM set_config('renewal_test.overdue_user', v_overdue_user::text, true);
  PERFORM set_config('renewal_test.recent_user',  v_recent_user::text,  true);
END $$;

SELECT admin.process_marketing_consent_renewals(730);

-- 15. fixture E: consented = false (자동 철회)
SELECT ok(
  (SELECT consented = false
     FROM public.user_consents
    WHERE user_id = current_setting('renewal_test.overdue_user')::uuid
      AND consent_key = 'marketing_consent'),
  '#2041: 8일 미응답 → consented = false (자동 철회)'
);

-- 16. fixture E: withdrawn_at IS NOT NULL
SELECT ok(
  (SELECT withdrawn_at IS NOT NULL
     FROM public.user_consents
    WHERE user_id = current_setting('renewal_test.overdue_user')::uuid
      AND consent_key = 'marketing_consent'),
  '#2041: 8일 미응답 → withdrawn_at 설정됨'
);

-- 17. fixture F: consented = true (6일 미경과, 아직 철회 없음)
SELECT ok(
  (SELECT consented = true AND withdrawn_at IS NULL
     FROM public.user_consents
    WHERE user_id = current_setting('renewal_test.recent_user')::uuid
      AND consent_key = 'marketing_consent'),
  '#2041: 6일 미응답 → 아직 철회 없음 (7일 미만)'
);

-- ── 6. idempotent 확인 ────────────────────────────────────────────────────────

-- 18. 재실행 시 이미 notified_at 설정된 사용자 재처리 없음
-- (fixture A: renewal_notified_at이 설정됐으므로 이제 발송 대상이 아님)
DO $$
DECLARE
  v_before timestamptz;
BEGIN
  SELECT renewal_notified_at INTO v_before
  FROM public.user_consents
  WHERE user_id = current_setting('renewal_test.expired_user')::uuid
    AND consent_key = 'marketing_consent';

  PERFORM set_config('renewal_test.before_ts', v_before::text, true);
END $$;

SELECT admin.process_marketing_consent_renewals(730);

-- 19. fixture A: renewal_notified_at 값이 재실행 후에도 동일 (재발송 없음)
SELECT ok(
  (SELECT renewal_notified_at::text = current_setting('renewal_test.before_ts')
     FROM public.user_consents
    WHERE user_id = current_setting('renewal_test.expired_user')::uuid
      AND consent_key = 'marketing_consent'),
  '#2041 idempotent: 재실행 시 이미 발송된 사용자 renewal_notified_at 변경 없음'
);

-- 20. 반환값이 bigint (0 이상)
SELECT ok(
  (SELECT admin.process_marketing_consent_renewals(730) >= 0),
  '#2041: 함수 반환값은 0 이상 bigint'
);

SELECT * FROM finish();
ROLLBACK;
