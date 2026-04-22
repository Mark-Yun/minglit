-- pgTAP tests for #1707: 자격 인증 증빙 1년 보관 정책 등록 검증
BEGIN;

SELECT plan(12);

SELECT tests.authenticate_as_service_role();

-- ── verification_submissions DB 정책 확인 ─────────────────────────────────────

-- 1. policy 존재
SELECT ok(
  EXISTS (SELECT 1 FROM admin.retention_policies WHERE id = 'verification_submissions_proof'),
  '#1707: verification_submissions_proof policy registered'
);

-- 2. kind = db_table
SELECT is(
  (SELECT kind::text FROM admin.retention_policies WHERE id = 'verification_submissions_proof'),
  'db_table',
  '#1707: verification_submissions policy kind is db_table'
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

-- 6. target 스키마/테이블/컬럼 확인
SELECT ok(
  (SELECT target FROM admin.retention_policies WHERE id = 'verification_submissions_proof')
    @> '{"schema":"public","table":"verification_submissions","ts_col":"created_at"}'::jsonb,
  '#1707: verification_submissions target metadata correct'
);

-- ── verification-proofs Storage 정책 확인 ─────────────────────────────────────

-- 7. policy 존재
SELECT ok(
  EXISTS (SELECT 1 FROM admin.retention_policies WHERE id = 'verification_proofs_storage'),
  '#1707: verification_proofs_storage policy registered'
);

-- 8. kind = storage_bucket
SELECT is(
  (SELECT kind::text FROM admin.retention_policies WHERE id = 'verification_proofs_storage'),
  'storage_bucket',
  '#1707: verification_proofs policy kind is storage_bucket'
);

-- 9. retention_days = 365
SELECT is(
  (SELECT retention_days FROM admin.retention_policies WHERE id = 'verification_proofs_storage'),
  365,
  '#1707: verification_proofs retention_days = 365 (1년)'
);

-- 10. legal_min_days = 365
SELECT is(
  (SELECT legal_min_days FROM admin.retention_policies WHERE id = 'verification_proofs_storage'),
  365,
  '#1707: verification_proofs legal_min_days = 365 (최소 1년 보존)'
);

-- 11. enabled = true
SELECT ok(
  (SELECT enabled FROM admin.retention_policies WHERE id = 'verification_proofs_storage'),
  '#1707: verification_proofs policy enabled = true'
);

-- 12. target bucket_id 확인
SELECT ok(
  (SELECT target->>'bucket_id' FROM admin.retention_policies WHERE id = 'verification_proofs_storage')
    = 'verification-proofs',
  '#1707: verification_proofs target bucket_id = verification-proofs'
);

SELECT * FROM finish();
ROLLBACK;
