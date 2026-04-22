-- pgTAP tests for #1706: 부정 이용 기록 1년 보관 정책 등록 검증
BEGIN;

SELECT plan(10);

SELECT tests.authenticate_as_service_role();

-- ── report_details 정책 확인 ──────────────────────────────────────────────────

-- 1. policy 존재
SELECT ok(
  EXISTS (SELECT 1 FROM admin.retention_policies WHERE id = 'report_details_fraud_record'),
  '#1706: report_details_fraud_record policy registered'
);

-- 2. kind = db_table
SELECT is(
  (SELECT kind::text FROM admin.retention_policies WHERE id = 'report_details_fraud_record'),
  'db_table',
  '#1706: report_details policy kind is db_table'
);

-- 3. retention_days = 365
SELECT is(
  (SELECT retention_days FROM admin.retention_policies WHERE id = 'report_details_fraud_record'),
  365,
  '#1706: report_details retention_days = 365 (1년)'
);

-- 4. legal_min_days = 365
SELECT is(
  (SELECT legal_min_days FROM admin.retention_policies WHERE id = 'report_details_fraud_record'),
  365,
  '#1706: report_details legal_min_days = 365'
);

-- 5. enabled = true
SELECT ok(
  (SELECT enabled FROM admin.retention_policies WHERE id = 'report_details_fraud_record'),
  '#1706: report_details policy enabled = true'
);

-- 6. target 스키마/테이블/컬럼 확인
SELECT ok(
  (SELECT target FROM admin.retention_policies WHERE id = 'report_details_fraud_record')
    @> '{"schema":"public","table":"report_details","ts_col":"created_at"}'::jsonb,
  '#1706: report_details target metadata correct'
);

-- ── blocked_dis 정책 확인 (비활성, 불일치 추적용) ─────────────────────────────

-- 7. policy 존재
SELECT ok(
  EXISTS (SELECT 1 FROM admin.retention_policies WHERE id = 'blocked_dis_fraud_record'),
  '#1706: blocked_dis_fraud_record policy registered'
);

-- 8. enabled = false (TTL 불일치로 비활성)
SELECT ok(
  NOT (SELECT enabled FROM admin.retention_policies WHERE id = 'blocked_dis_fraud_record'),
  '#1706: blocked_dis policy enabled = false (legal-reviewer 컨설트 전)'
);

-- 9. retention_days = 365
SELECT is(
  (SELECT retention_days FROM admin.retention_policies WHERE id = 'blocked_dis_fraud_record'),
  365,
  '#1706: blocked_dis retention_days = 365 (선언된 보존 기간)'
);

-- 10. metadata에 conflict 정보 포함
SELECT ok(
  (SELECT metadata->>'conflict' FROM admin.retention_policies WHERE id = 'blocked_dis_fraud_record') IS NOT NULL,
  '#1706: blocked_dis metadata documents TTL conflict for legal review'
);

SELECT * FROM finish();
ROLLBACK;
