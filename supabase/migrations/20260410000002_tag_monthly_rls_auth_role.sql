-- Fix #1190: tag_usage_monthly RLS 정책 current_setting('role', true) → auth.role() 교체
-- Issue #1182 Finding #7 (Security Audit #1175): auth.role() 패턴 통일
-- PR #1188에서 신규 생성된 tag_usage_monthly 테이블이 교체 범위에서 누락됨

DROP POLICY IF EXISTS tag_usage_monthly_service ON tag_usage_monthly;

-- Fix #1190: deprecated current_setting('role', true) → auth.role() 패턴으로 통일
CREATE POLICY tag_usage_monthly_service ON tag_usage_monthly FOR ALL USING (
  auth.role() = 'service_role'
);
