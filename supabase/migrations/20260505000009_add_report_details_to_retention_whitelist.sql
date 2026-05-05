-- Fix #2203: public.report_details가 retention_allowed_targets whitelist에 누락되어
-- report_details_fraud_record 정책 실행 시 "Table not in retention whitelist" 예외 발생.
-- 기존 정책(20260422000005)은 이미 enabled=true, retention_days=365, legal_min_days=365으로
-- 올바르게 정의되어 있으므로 whitelist 등록만 추가.
INSERT INTO admin.retention_allowed_targets (
  schema_name,
  table_name,
  ts_col,
  legal_min_days,
  description
) VALUES (
  'public',
  'report_details',
  'created_at',
  365,
  '부정 이용 신고 기록 — 개인정보처리방침 §F5: 1년 보관'
) ON CONFLICT (schema_name, table_name) DO NOTHING;
