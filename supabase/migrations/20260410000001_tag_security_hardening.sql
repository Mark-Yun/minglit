-- Tag Discovery P3 Security Hardening
-- Issue #1182 (Security Audit Report #1175 Findings #7, #10)

-- ============================================================
-- Finding #7: RLS 정책 current_setting('role') → auth.role() 통일
-- 기존 current_setting('role', true) 대신 auth.role() 패턴으로 일원화
-- ============================================================

-- party_tags: 기존 정책 삭제 후 auth.role()로 재생성
DROP POLICY IF EXISTS party_tags_service ON party_tags;
CREATE POLICY party_tags_service ON party_tags FOR ALL USING (
  auth.role() = 'service_role'
);

-- tag_usage_daily: 기존 정책 삭제 후 auth.role()로 재생성
DROP POLICY IF EXISTS tag_usage_daily_service ON tag_usage_daily;
CREATE POLICY tag_usage_daily_service ON tag_usage_daily FOR ALL USING (
  auth.role() = 'service_role'
);

-- ============================================================
-- Finding #10: search_tags 입력 길이 제한
-- p_query를 LEFT(p_query, 50)으로 잘라 과도한 입력 방지
-- ============================================================
CREATE OR REPLACE FUNCTION search_tags(
  p_query text
)
RETURNS TABLE (
  id uuid,
  name text,
  is_featured boolean,
  usage_count integer,
  created_at timestamptz
)
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public
AS $$
  -- Fix #1182: p_query를 50자로 제한하여 과도한 입력으로 인한 부하 방지
  SELECT id, name, is_featured, usage_count, created_at
  FROM tags
  WHERE name &^~ LEFT(p_query, 50)
  ORDER BY is_featured DESC, usage_count DESC, name ASC
  LIMIT 10;
$$;
