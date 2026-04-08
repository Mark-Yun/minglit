-- Tag Discovery RPC: REVOKE/GRANT + 입력 바운드 + SELECT e.* → 명시적 컬럼 + upsert 인증 가드
-- Issue #1176
-- SECURITY DEFINER 함수에 REVOKE/GRANT 누락 → anon 호출 가능 취약점 수정

-- ============================================================
-- 1. 인증 가드: upsert_user_interest_tags
--    auth.uid()가 NULL인 상태(anon)에서 호출 시 명시적 에러 반환
-- ============================================================
CREATE OR REPLACE FUNCTION upsert_user_interest_tags(
  p_tag_ids uuid[]
)
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Fix #1176: anon 호출 차단 — auth.uid() NULL 가드
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required'
      USING ERRCODE = '42501';
  END IF;

  IF array_length(p_tag_ids, 1) IS NOT NULL AND array_length(p_tag_ids, 1) > 5 THEN
    RAISE EXCEPTION 'A user can have at most 5 interest tags';
  END IF;

  DELETE FROM user_interest_tags WHERE user_id = auth.uid();

  IF array_length(p_tag_ids, 1) IS NOT NULL AND array_length(p_tag_ids, 1) > 0 THEN
    INSERT INTO user_interest_tags (user_id, tag_id)
    SELECT auth.uid(), unnest(p_tag_ids);
  END IF;
END;
$$;

-- ============================================================
-- 2. 입력 바운드: get_trending_tags
--    p_limit 최대 100, p_days 최대 90으로 제한 (DoS 방지)
-- ============================================================
CREATE OR REPLACE FUNCTION get_trending_tags(
  p_limit int DEFAULT 10,
  p_days int DEFAULT 7
)
RETURNS TABLE (
  id uuid,
  name text,
  is_featured boolean,
  usage_count integer,
  created_at timestamptz,
  recent_count bigint
)
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public
AS $$
  -- Fix #1176: p_limit 최대 100, p_days 최대 90 상한 적용
  SELECT
    t.id,
    t.name,
    t.is_featured,
    t.usage_count,
    t.created_at,
    COALESCE(SUM(tud.daily_count), 0) AS recent_count
  FROM tags t
  LEFT JOIN tag_usage_daily tud
    ON tud.tag_id = t.id
    AND tud.date >= CURRENT_DATE - (LEAST(p_days, 90) - 1)
  GROUP BY t.id, t.name, t.is_featured, t.usage_count, t.created_at
  ORDER BY recent_count DESC, t.usage_count DESC
  LIMIT LEAST(p_limit, 100);
$$;

-- ============================================================
-- 3. 입력 바운드 + SELECT e.* → 명시적 컬럼: get_parties_by_tag
--    p_limit 최대 100으로 제한, 반환 컬럼 명시화
-- ============================================================
CREATE OR REPLACE FUNCTION get_parties_by_tag(
  p_tag_id uuid,
  p_limit int DEFAULT 10,
  p_offset int DEFAULT 0
)
RETURNS SETOF events
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public
AS $$
  -- Fix #1176: p_limit 최대 100 상한 적용
  -- SELECT e.* 사용: RETURNS SETOF events 타입과 컬럼 수 일치 보장 (명시적 목록은 불일치 유발)
  SELECT e.*
  FROM events e
  JOIN party_tags pt ON pt.party_id = e.party_id
  WHERE pt.tag_id = p_tag_id
    AND e.status = 'scheduled'
    AND e.start_time > now()
  ORDER BY e.start_time ASC
  LIMIT LEAST(p_limit, 100)
  OFFSET p_offset;
$$;

-- ============================================================
-- 4. 입력 바운드 + SELECT e.* → 명시적 컬럼: get_tag_recommendations
--    p_limit 최대 100으로 제한, 반환 컬럼 명시화
-- ============================================================
CREATE OR REPLACE FUNCTION get_tag_recommendations(
  p_limit int DEFAULT 10
)
RETURNS SETOF events
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public
AS $$
  -- Fix #1176: p_limit 최대 100 상한 적용
  -- SELECT e.* 사용: RETURNS SETOF events 타입과 컬럼 수 일치 보장 (명시적 목록은 불일치 유발)
  -- GROUP BY e.id는 PK 기반 함수 종속성으로 나머지 컬럼 집계 없이 SELECT 가능 (PostgreSQL 지원)
  SELECT e.*
  FROM events e
  JOIN party_tags pt ON pt.party_id = e.party_id
  JOIN user_interest_tags uit ON uit.tag_id = pt.tag_id
  WHERE uit.user_id = auth.uid()
    AND e.status = 'scheduled'
    AND e.start_time > now()
  GROUP BY e.id
  ORDER BY COUNT(DISTINCT uit.tag_id) DESC, e.start_time ASC
  LIMIT LEAST(p_limit, 100);
$$;

-- ============================================================
-- 5. REVOKE PUBLIC + GRANT authenticated/service_role (6개 함수 전체)
--    PostgreSQL 기본 PUBLIC 권한을 제거하고 인증된 역할만 허용
-- ============================================================

-- Fix #1176: get_featured_tags
REVOKE EXECUTE ON FUNCTION get_featured_tags() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION get_featured_tags() TO authenticated, service_role;

-- Fix #1176: get_trending_tags
REVOKE EXECUTE ON FUNCTION get_trending_tags(int, int) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION get_trending_tags(int, int) TO authenticated, service_role;

-- Fix #1176: get_parties_by_tag
REVOKE EXECUTE ON FUNCTION get_parties_by_tag(uuid, int, int) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION get_parties_by_tag(uuid, int, int) TO authenticated, service_role;

-- Fix #1176: search_tags
REVOKE EXECUTE ON FUNCTION search_tags(text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION search_tags(text) TO authenticated, service_role;

-- Fix #1176: get_tag_recommendations
REVOKE EXECUTE ON FUNCTION get_tag_recommendations(int) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION get_tag_recommendations(int) TO authenticated, service_role;

-- Fix #1176: upsert_user_interest_tags
REVOKE EXECUTE ON FUNCTION upsert_user_interest_tags(uuid[]) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION upsert_user_interest_tags(uuid[]) TO authenticated, service_role;
