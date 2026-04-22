-- Migration: #1707 Part 2 — 자격 인증 증빙 1년 보관 정책 (개인정보처리방침 §F6)
--
-- 개인정보처리방침: "자격 인증 증빙 1년 보관"
--
-- 대상:
--   1. public.verification_submissions — 자격 인증 제출 기록 (DB)
--   2. verification-proofs Storage 버킷 — 증빙 파일 (이미지/문서)
--
-- 구현 전략:
--   DB 기록 — 하드 DELETE 불가.
--     verification_submissions(id) ← partner_verified_users(submission_id) ON DELETE CASCADE
--     하드 DELETE 시 현재 유효한 파트너 인증 상태(partner_verified_users)가 연쇄 삭제됨.
--     대신 PII 컬럼(snapshot_data, admin_comment, reviewed_by)만 익명화.
--   Storage 파일 — 원본 이미지/PDF는 하드 삭제 (PIPA §21 파기 의무 핵심).

-- ── 1. PII 익명화 함수 ────────────────────────────────────────────────────────
-- snapshot_data(증빙 원본 JSON), admin_comment, reviewed_by 를 익명화.
-- user_id(NOT NULL), partner_id, verification_id, status, reviewed_at 는 보존
-- (트레이서빌리티 + partner_verified_users FK 무결성 유지).
CREATE OR REPLACE FUNCTION admin.anonymize_old_verification_submissions(
  p_cutoff_days int
)
RETURNS bigint
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, admin, public
AS $$
DECLARE
  v_updated bigint;
BEGIN
  UPDATE public.verification_submissions
  SET snapshot_data  = '{}'::jsonb,
      admin_comment  = NULL,
      reviewed_by    = NULL
  WHERE created_at < now() - p_cutoff_days * INTERVAL '1 day'
    AND snapshot_data != '{}'::jsonb;  -- idempotent: 이미 익명화된 행 스킵

  GET DIAGNOSTICS v_updated = ROW_COUNT;
  RETURN v_updated;
END;
$$;

REVOKE ALL ON FUNCTION admin.anonymize_old_verification_submissions(int)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION admin.anonymize_old_verification_submissions(int)
  TO service_role;

-- ── 2. verification_submissions DB 기록 정책 — db_custom_fn ──────────────────
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
  'verification_submissions_proof',
  'db_custom_fn',
  365,
  365,
  jsonb_build_object('fn', 'admin.anonymize_old_verification_submissions'),
  true,
  '개인정보처리방침 §F6: 자격 인증 제출 기록 PII 1년 후 익명화 '
  '(snapshot_data→{}, admin_comment/reviewed_by→NULL)',
  jsonb_build_object(
    'approach', 'anonymize',
    'reason',   'partner_verified_users.submission_id ON DELETE CASCADE — '
                '하드 DELETE 시 활성 인증 박탈'
  )
);

-- ── 3. verification-proofs Storage 버킷 증빙 파일 1년 후 하드 삭제 ─────────────
-- 원본 이미지/PDF는 반드시 파기해야 PIPA §21 파기 의무를 충족.
INSERT INTO admin.retention_policies (
  id,
  kind,
  retention_days,
  legal_min_days,
  target,
  enabled,
  description
) VALUES (
  'verification_proofs_storage',
  'storage_bucket',
  365,
  365,
  jsonb_build_object(
    'bucket_id',   'verification-proofs',
    'path_prefix', ''
  ),
  true,
  '개인정보처리방침 §F6: 자격 인증 증빙 파일(verification-proofs 버킷) 1년 보관 후 파기'
);
