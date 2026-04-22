-- pgTAP tests for #1707: 자격 인증 증빙 1년 보관 정책 검증
--
-- 검증 항목:
--   1. retention_policies 등록 확인 (kind, retention_days, enabled, target)
--   2. anonymize_old_verification_submissions 함수 존재
--   3. 익명화 로직: snapshot_data → {}, admin_comment/reviewed_by → NULL
--   4. CASCADE 회귀: 익명화 후 partner_verified_users 행 유지 (자격 박탈 없음)
--   5. verification-proofs Storage 정책 등록
BEGIN;

SELECT plan(17);

SELECT tests.authenticate_as_service_role();

-- ── 1. verification_submissions DB 정책 확인 ──────────────────────────────────

-- 1. policy 존재
SELECT ok(
  EXISTS (SELECT 1 FROM admin.retention_policies WHERE id = 'verification_submissions_proof'),
  '#1707: verification_submissions_proof policy registered'
);

-- 2. kind = db_custom_fn (하드 DELETE 아닌 익명화 방식)
SELECT is(
  (SELECT kind::text FROM admin.retention_policies WHERE id = 'verification_submissions_proof'),
  'db_custom_fn',
  '#1707: verification_submissions policy kind is db_custom_fn (not db_table)'
);

-- 3. retention_days = 365
SELECT is(
  (SELECT retention_days FROM admin.retention_policies WHERE id = 'verification_submissions_proof'),
  365,
  '#1707: verification_submissions retention_days = 365 (1년)'
);

-- 4. legal_min_days = 365
SELECT is(
  (SELECT legal_min_days FROM admin.retention_policies WHERE id = 'verification_submissions_proof'),
  365,
  '#1707: verification_submissions legal_min_days = 365 (최소 1년 보존)'
);

-- 5. enabled = true
SELECT ok(
  (SELECT enabled FROM admin.retention_policies WHERE id = 'verification_submissions_proof'),
  '#1707: verification_submissions policy enabled = true'
);

-- 6. target.fn = 'admin.anonymize_old_verification_submissions'
SELECT is(
  (SELECT target->>'fn' FROM admin.retention_policies WHERE id = 'verification_submissions_proof'),
  'admin.anonymize_old_verification_submissions',
  '#1707: verification_submissions target.fn = admin.anonymize_old_verification_submissions'
);

-- ── 2. 함수 시그니처 확인 ─────────────────────────────────────────────────────

-- 7. 함수 존재
SELECT ok(
  EXISTS(
    SELECT 1 FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname = 'admin'
      AND p.proname = 'anonymize_old_verification_submissions'
  ),
  '#1707: admin.anonymize_old_verification_submissions function exists'
);

-- ── 3. 익명화 로직 + CASCADE 회귀 검증 ───────────────────────────────────────

DO $$
DECLARE
  v_user_id       uuid;
  v_partner_id    uuid;
  v_verif_id      uuid;
  v_submission_id uuid;
BEGIN
  -- Create test user (auth.users via pgtap helper)
  v_user_id := tests.create_supabase_user(
    'vs_retention_1707',
    'vs_retention_1707@pgtap.local'
  );

  -- Create partner + verification definition
  INSERT INTO public.partners (name) VALUES ('Test Partner 1707') RETURNING id INTO v_partner_id;

  INSERT INTO public.verifications (partner_id, category, internal_name, display_name)
  VALUES (v_partner_id, 'career', 'career_proof', 'Career Proof')
  RETURNING id INTO v_verif_id;

  -- Create a submission older than 365 days with PII in snapshot_data
  INSERT INTO public.verification_submissions (
    partner_id, user_id, verification_id, status, snapshot_data, admin_comment,
    reviewed_by, created_at, updated_at
  ) VALUES (
    v_partner_id, v_user_id, v_verif_id,
    'approved',
    '{"id_number_last4": "1234", "name": "홍길동"}'::jsonb,
    'Admin note 1707',
    v_user_id,
    now() - INTERVAL '366 days',
    now() - INTERVAL '366 days'
  ) RETURNING id INTO v_submission_id;

  -- Create partner_verified_users referencing the submission
  -- (ON DELETE CASCADE: 하드 DELETE시 이 행이 사라지는 것이 버그)
  INSERT INTO public.partner_verified_users (
    partner_id, user_id, verification_id, submission_id
  ) VALUES (v_partner_id, v_user_id, v_verif_id, v_submission_id);

  PERFORM set_config('vs_test.submission_id', v_submission_id::text, true);
  PERFORM set_config('vs_test.partner_id', v_partner_id::text, true);
  PERFORM set_config('vs_test.user_id', v_user_id::text, true);
  PERFORM set_config('vs_test.verif_id', v_verif_id::text, true);
END $$;

-- 8. fixture: snapshot_data contains PII before anonymization
SELECT ok(
  (SELECT snapshot_data != '{}'::jsonb
     FROM public.verification_submissions
    WHERE id = current_setting('vs_test.submission_id')::uuid),
  'fixture: snapshot_data has PII before anonymization'
);

-- run anonymization (365-day cutoff)
SELECT admin.anonymize_old_verification_submissions(365);

-- 9. snapshot_data → '{}'::jsonb (PII 파기)
SELECT is(
  (SELECT snapshot_data FROM public.verification_submissions
    WHERE id = current_setting('vs_test.submission_id')::uuid),
  '{}'::jsonb,
  '#1707 PIPA §21: snapshot_data anonymized to {} after 365 days'
);

-- 10. admin_comment → NULL
SELECT ok(
  (SELECT admin_comment IS NULL FROM public.verification_submissions
    WHERE id = current_setting('vs_test.submission_id')::uuid),
  '#1707 PIPA §21: admin_comment NULLed after anonymization'
);

-- 11. reviewed_by → NULL
SELECT ok(
  (SELECT reviewed_by IS NULL FROM public.verification_submissions
    WHERE id = current_setting('vs_test.submission_id')::uuid),
  '#1707 PIPA §21: reviewed_by NULLed after anonymization'
);

-- 12. submission row 자체는 유지 (하드 삭제 아님)
SELECT ok(
  EXISTS(
    SELECT 1 FROM public.verification_submissions
     WHERE id = current_setting('vs_test.submission_id')::uuid
  ),
  '#1707: verification_submissions row preserved (anonymize, not delete)'
);

-- 13. CASCADE 회귀: partner_verified_users row 유지 (활성 자격 박탈 없음)
SELECT ok(
  EXISTS(
    SELECT 1 FROM public.partner_verified_users
     WHERE submission_id = current_setting('vs_test.submission_id')::uuid
  ),
  '#1707 cascade-regression: partner_verified_users row intact after anonymization'
);

-- 14. idempotent: 재실행해도 0 rows updated
SELECT is(
  admin.anonymize_old_verification_submissions(365),
  0::bigint,
  '#1707: anonymize function is idempotent (0 rows updated on re-run)'
);

-- ── 4. verification-proofs Storage 정책 확인 ──────────────────────────────────

-- 15. policy 존재
SELECT ok(
  EXISTS (SELECT 1 FROM admin.retention_policies WHERE id = 'verification_proofs_storage'),
  '#1707: verification_proofs_storage policy registered'
);

-- 16. kind = storage_bucket
SELECT is(
  (SELECT kind::text FROM admin.retention_policies WHERE id = 'verification_proofs_storage'),
  'storage_bucket',
  '#1707: verification_proofs policy kind is storage_bucket'
);

-- 17. retention_days = 365
SELECT is(
  (SELECT retention_days FROM admin.retention_policies WHERE id = 'verification_proofs_storage'),
  365,
  '#1707: verification_proofs retention_days = 365 (1년)'
);

SELECT * FROM finish();
ROLLBACK;
