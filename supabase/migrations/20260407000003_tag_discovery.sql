-- Tag Discovery — Phase 1 MVP
-- Issue #1136, #558
-- 4 tables + RLS + triggers + PGroonga index + seed data 25 tags + 6 RPC functions

-- ============================================================
-- 1. tags 테이블
-- ============================================================
CREATE TABLE tags (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL UNIQUE,
  is_featured boolean NOT NULL DEFAULT false,
  usage_count integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- PGroonga 인덱스 (태그 검색용 prefix match)
CREATE INDEX idx_tags_name_pgroonga ON tags USING pgroonga (name pgroonga_text_term_search_ops_v2);

-- ============================================================
-- 2. party_tags 테이블
-- ============================================================
CREATE TABLE party_tags (
  party_id uuid NOT NULL REFERENCES parties(id) ON DELETE CASCADE,
  tag_id uuid NOT NULL REFERENCES tags(id) ON DELETE CASCADE,
  PRIMARY KEY (party_id, tag_id)
);

-- tag_id 인덱스: get_parties_by_tag() 등 tag_id 기반 필터링 성능 보장
CREATE INDEX idx_party_tags_tag_id ON party_tags (tag_id);

-- party_tags 최대 5개 제한
-- advisory lock으로 동일 party_id에 대한 동시 INSERT를 직렬화하여 race condition 방지
CREATE OR REPLACE FUNCTION check_party_tags_limit()
RETURNS TRIGGER AS $$
BEGIN
  PERFORM pg_advisory_xact_lock(hashtext(NEW.party_id::text));
  IF (SELECT count(*) FROM party_tags WHERE party_id = NEW.party_id) >= 5 THEN
    RAISE EXCEPTION 'A party can have at most 5 tags';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_party_tags_limit
  BEFORE INSERT ON party_tags
  FOR EACH ROW EXECUTE FUNCTION check_party_tags_limit();

-- ============================================================
-- 3. user_interest_tags 테이블
-- ============================================================
CREATE TABLE user_interest_tags (
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  tag_id uuid NOT NULL REFERENCES tags(id) ON DELETE CASCADE,
  PRIMARY KEY (user_id, tag_id)
);

-- tag_id 인덱스: get_tag_recommendations() 등 tag_id 기반 필터링 성능 보장
CREATE INDEX idx_user_interest_tags_tag_id ON user_interest_tags (tag_id);

-- user_interest_tags 최대 5개 제한
-- advisory lock으로 동일 user_id에 대한 동시 INSERT를 직렬화하여 race condition 방지
CREATE OR REPLACE FUNCTION check_user_interest_tags_limit()
RETURNS TRIGGER AS $$
BEGIN
  PERFORM pg_advisory_xact_lock(hashtext(NEW.user_id::text));
  IF (SELECT count(*) FROM user_interest_tags WHERE user_id = NEW.user_id) >= 5 THEN
    RAISE EXCEPTION 'A user can have at most 5 interest tags';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_user_interest_tags_limit
  BEFORE INSERT ON user_interest_tags
  FOR EACH ROW EXECUTE FUNCTION check_user_interest_tags_limit();

-- ============================================================
-- 4. tag_usage_daily 테이블 (트렌딩 계산용)
-- ============================================================
CREATE TABLE tag_usage_daily (
  tag_id uuid NOT NULL REFERENCES tags(id) ON DELETE CASCADE,
  date date NOT NULL DEFAULT CURRENT_DATE,
  daily_count integer NOT NULL DEFAULT 0,
  PRIMARY KEY (tag_id, date)
);

-- ============================================================
-- 5. usage_count 자동 증감 트리거 (party_tags INSERT/DELETE)
-- ============================================================
CREATE OR REPLACE FUNCTION update_tag_usage_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE tags SET usage_count = usage_count + 1 WHERE id = NEW.tag_id;
    INSERT INTO tag_usage_daily (tag_id, date, daily_count)
    VALUES (NEW.tag_id, CURRENT_DATE, 1)
    ON CONFLICT (tag_id, date) DO UPDATE SET daily_count = tag_usage_daily.daily_count + 1;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE tags SET usage_count = GREATEST(usage_count - 1, 0) WHERE id = OLD.tag_id;
    UPDATE tag_usage_daily
    SET daily_count = GREATEST(daily_count - 1, 0)
    WHERE tag_id = OLD.tag_id AND date = CURRENT_DATE;
    RETURN OLD;
  END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_tag_usage
  AFTER INSERT OR DELETE ON party_tags
  FOR EACH ROW EXECUTE FUNCTION update_tag_usage_count();

-- ============================================================
-- 6. RLS
-- ============================================================
ALTER TABLE tags ENABLE ROW LEVEL SECURITY;
ALTER TABLE party_tags ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_interest_tags ENABLE ROW LEVEL SECURITY;
ALTER TABLE tag_usage_daily ENABLE ROW LEVEL SECURITY;

-- Fix #1149: direct table SELECT restricted to authenticated only.
-- Anonymous users access tag data through SECURITY DEFINER RPC functions
-- (get_featured_tags, search_tags, etc.) which bypass RLS.
-- tags: authenticated 읽기, super_admin만 쓰기
CREATE POLICY tags_read ON tags FOR SELECT TO authenticated USING (true);
CREATE POLICY tags_admin_insert ON tags FOR INSERT WITH CHECK (public.is_super_admin());
CREATE POLICY tags_admin_update ON tags FOR UPDATE USING (public.is_super_admin());
CREATE POLICY tags_admin_delete ON tags FOR DELETE USING (public.is_super_admin());

-- party_tags: authenticated 읽기, EF가 service_role로 처리
CREATE POLICY party_tags_read ON party_tags FOR SELECT TO authenticated USING (true);
CREATE POLICY party_tags_service ON party_tags FOR ALL USING (
  (SELECT current_setting('role', true)) = 'service_role'
);

-- user_interest_tags: 본인만 읽기 가능, 쓰기는 upsert_user_interest_tags() RPC(SECURITY DEFINER)로만 허용
CREATE POLICY user_interest_tags_read_own ON user_interest_tags FOR SELECT USING (auth.uid() = user_id);

-- tag_usage_daily: authenticated 읽기, service_role/트리거만 쓰기
CREATE POLICY tag_usage_daily_read ON tag_usage_daily FOR SELECT TO authenticated USING (true);
CREATE POLICY tag_usage_daily_service ON tag_usage_daily FOR ALL USING (
  (SELECT current_setting('role', true)) = 'service_role'
);

-- ============================================================
-- 7. 시드 데이터: 인기 태그 25개
-- ============================================================
INSERT INTO tags (name, is_featured) VALUES
  ('소개팅', true), ('미팅', true), ('네트워킹', true),
  ('운동', true), ('러닝', true), ('등산', true),
  ('맛집', true), ('와인', true), ('커피', true),
  ('파티', true), ('클럽', true), ('루프탑', true),
  ('스터디', true), ('독서', true), ('영화', true),
  ('음악', true), ('공연', true), ('전시', true),
  ('여행', true), ('캠핑', true), ('야외', true),
  ('소규모', true), ('대규모', true), ('20대', true), ('30대', true);

-- ============================================================
-- 8. RPC 함수
-- ============================================================

-- 8-1. get_featured_tags(): 인기 태그 목록 (usage_count DESC)
CREATE OR REPLACE FUNCTION get_featured_tags()
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
  SELECT id, name, is_featured, usage_count, created_at
  FROM tags
  WHERE is_featured = true
  ORDER BY usage_count DESC, name ASC;
$$;

-- 8-2. get_trending_tags(p_limit, p_days): 최근 N일 트렌딩 태그
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
    AND tud.date >= CURRENT_DATE - (p_days - 1)
  GROUP BY t.id, t.name, t.is_featured, t.usage_count, t.created_at
  ORDER BY recent_count DESC, t.usage_count DESC
  LIMIT p_limit;
$$;

-- 8-3. get_parties_by_tag(p_tag_id, p_limit, p_offset): 태그별 활성 이벤트 목록
-- 활성 이벤트: events.status = 'scheduled' AND start_time > now()
-- RETURNS SETOF events: Dart Event.fromJson과 컬럼 일치
CREATE OR REPLACE FUNCTION get_parties_by_tag(
  p_tag_id uuid,
  p_limit int DEFAULT 10,
  p_offset int DEFAULT 0
)
RETURNS SETOF events
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public
AS $$
  SELECT e.*
  FROM events e
  JOIN party_tags pt ON pt.party_id = e.party_id
  WHERE pt.tag_id = p_tag_id
    AND e.status = 'scheduled'
    AND e.start_time > now()
  ORDER BY e.start_time ASC
  LIMIT p_limit
  OFFSET p_offset;
$$;

-- 8-4. get_tag_recommendations(p_limit): 유저 관심 태그 기반 이벤트 추천
-- auth.uid() 기반, 매칭 태그 수 DESC 정렬
-- RETURNS SETOF events: Dart Event.fromJson과 컬럼 일치
CREATE OR REPLACE FUNCTION get_tag_recommendations(
  p_limit int DEFAULT 10
)
RETURNS SETOF events
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public
AS $$
  SELECT e.*
  FROM events e
  JOIN party_tags pt ON pt.party_id = e.party_id
  JOIN user_interest_tags uit ON uit.tag_id = pt.tag_id
  WHERE uit.user_id = auth.uid()
    AND e.status = 'scheduled'
    AND e.start_time > now()
  GROUP BY e.id
  ORDER BY COUNT(DISTINCT uit.tag_id) DESC, e.start_time ASC
  LIMIT p_limit;
$$;

-- 8-5. search_tags(p_query): PGroonga prefix match 태그 검색
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
  SELECT id, name, is_featured, usage_count, created_at
  FROM tags
  WHERE name &^~ p_query
  ORDER BY is_featured DESC, usage_count DESC, name ASC
  LIMIT 10;
$$;

-- 8-6. upsert_user_interest_tags(p_tag_ids): 관심 태그 교체 (최대 5개)
CREATE OR REPLACE FUNCTION upsert_user_interest_tags(
  p_tag_ids uuid[]
)
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
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
