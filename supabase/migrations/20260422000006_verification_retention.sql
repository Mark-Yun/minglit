-- Migration: #1707 자격 인증 증빙 1년 보관 정책 (개인정보처리방침 §F6)
--
-- 개인정보처리방침: "자격 인증 증빙 1년 보관"
--
-- 대상:
--   1. public.verification_submissions — 자격 인증 제출 기록 (DB)
--   2. verification-proofs Storage 버킷 — 증빙 파일 (이미지/문서)
--
-- 두 대상 모두 제출일(created_at) 기준 365일 후 파기.

-- ── 1. verification_submissions: DB 기록 1년 후 파기 ─────────────────────────
INSERT INTO admin.retention_policies (
  id,
  kind,
  retention_days,
  legal_min_days,
  target,
  enabled,
  description
) VALUES (
  'verification_submissions_proof',
  'db_table',
  365,
  365,
  jsonb_build_object(
    'schema', 'public',
    'table',  'verification_submissions',
    'ts_col', 'created_at'
  ),
  true,
  '개인정보처리방침 §F6: 자격 인증 제출 기록 1년 보관 후 파기'
);

-- ── 2. verification-proofs: Storage 버킷 증빙 파일 1년 후 파기 ───────────────
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
