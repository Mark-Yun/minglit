-- tag_usage_daily 2년 보유/압축 정책
-- Issue #1180
-- Security Audit #1175 Finding 4: 데이터 최소화 원칙 이행
-- 2년 초과 일별 데이터 → 월별 집계 압축 후 삭제

-- ============================================================
-- 1. tag_usage_monthly 테이블 (월별 집계)
-- ============================================================
CREATE TABLE tag_usage_monthly (
  tag_id uuid NOT NULL REFERENCES tags(id) ON DELETE CASCADE,
  month date NOT NULL,  -- 해당 월의 1일 (예: 2024-01-01)
  monthly_count integer NOT NULL DEFAULT 0,
  PRIMARY KEY (tag_id, month)
);

ALTER TABLE tag_usage_monthly ENABLE ROW LEVEL SECURITY;

-- tag_usage_monthly: authenticated 읽기, service_role/압축 함수만 쓰기
CREATE POLICY tag_usage_monthly_read ON tag_usage_monthly FOR SELECT TO authenticated USING (true);
CREATE POLICY tag_usage_monthly_service ON tag_usage_monthly FOR ALL USING (
  (SELECT current_setting('role', true)) = 'service_role'
);

-- ============================================================
-- 2. 압축 함수: compress_old_tag_usage_daily
-- ============================================================
CREATE OR REPLACE FUNCTION compress_old_tag_usage_daily()
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- 2년 초과 일별 데이터를 월별로 집계하여 tag_usage_monthly에 upsert
  INSERT INTO tag_usage_monthly (tag_id, month, monthly_count)
  SELECT
    tag_id,
    date_trunc('month', date)::date AS month,
    SUM(daily_count) AS monthly_count
  FROM tag_usage_daily
  WHERE date < CURRENT_DATE - interval '2 years'
  GROUP BY tag_id, date_trunc('month', date)
  ON CONFLICT (tag_id, month) DO UPDATE
    SET monthly_count = EXCLUDED.monthly_count;

  -- 압축 완료된 일별 데이터 삭제
  DELETE FROM tag_usage_daily
  WHERE date < CURRENT_DATE - interval '2 years';
END;
$$;

REVOKE EXECUTE ON FUNCTION compress_old_tag_usage_daily() FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION compress_old_tag_usage_daily() FROM anon;
GRANT EXECUTE ON FUNCTION compress_old_tag_usage_daily() TO service_role;

-- ============================================================
-- 3. pg_cron job: 매월 1일 04:00 UTC
-- ============================================================
SELECT cron.schedule(
  'compress-old-tag-usage-daily',
  '0 4 1 * *',
  $$SELECT compress_old_tag_usage_daily()$$
);
