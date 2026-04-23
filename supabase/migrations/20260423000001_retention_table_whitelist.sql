-- refactor #1749: admin retention 테이블 레벨 화이트리스트 + partial unique index + legal_min_days 트리거

-- 1. 허용 테이블 목록 (테이블 레벨 화이트리스트)
CREATE TABLE admin.retention_allowed_targets (
  schema_name    text NOT NULL,
  table_name     text NOT NULL,
  ts_col         text NOT NULL,
  legal_min_days int  CHECK (legal_min_days IS NULL OR legal_min_days > 0),
  description    text,
  PRIMARY KEY (schema_name, table_name)
);

-- 기존 retention_policies에 등록된 db_table 대상 허용 목록 초기화
INSERT INTO admin.retention_allowed_targets (schema_name, table_name, ts_col, legal_min_days, description) VALUES
  ('cron',   'job_run_details',     'end_time',        NULL, 'pg_cron 실행 이력'),
  ('net',    '_http_response',      'created',         NULL, 'net.http_post 응답 로그'),
  ('public', 'location_access_log', 'accessed_at',     180,  '위치정보법 §16 6개월'),
  ('public', 'archived_records',    'retention_until', 1825, '전자상거래법 §6 + PIPA §21 5년');

REVOKE ALL ON TABLE admin.retention_allowed_targets FROM PUBLIC, anon, authenticated;
GRANT SELECT ON TABLE admin.retention_allowed_targets TO service_role;

-- 2. delete_old_rows — 테이블 레벨 화이트리스트 검증 추가
CREATE OR REPLACE FUNCTION admin.delete_old_rows(
  p_schema      text,
  p_table       text,
  p_ts_col      text,
  p_cutoff_days int
)
RETURNS bigint
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, admin, cron, net, auth, public, pgmq
AS $$
DECLARE
  deleted_count bigint;
BEGIN
  -- 스키마 화이트리스트 (defence-in-depth)
  IF p_schema NOT IN ('cron', 'net', 'auth', 'public', 'pgmq') THEN
    RAISE EXCEPTION 'Disallowed schema: %', p_schema;
  END IF;

  -- Fix #1749: 테이블 레벨 화이트리스트 검증
  IF NOT EXISTS (
    SELECT 1 FROM admin.retention_allowed_targets
    WHERE schema_name = p_schema
      AND table_name  = p_table
      AND ts_col      = p_ts_col
  ) THEN
    RAISE EXCEPTION 'Table not in retention whitelist: %.% (ts_col=%)', p_schema, p_table, p_ts_col;
  END IF;

  EXECUTE format(
    'DELETE FROM %I.%I WHERE %I < now() - $1 * interval ''1 day''',
    p_schema, p_table, p_ts_col
  ) USING p_cutoff_days;
  GET DIAGNOSTICS deleted_count = ROW_COUNT;
  RETURN deleted_count;
END;
$$;

-- 3. delete_expired_rows — 테이블 레벨 화이트리스트 검증 추가
CREATE OR REPLACE FUNCTION admin.delete_expired_rows(
  p_schema text,
  p_table  text,
  p_ts_col text
)
RETURNS bigint
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, admin, cron, net, auth, public, pgmq
AS $$
DECLARE
  deleted_count bigint;
BEGIN
  -- 스키마 화이트리스트 (defence-in-depth)
  IF p_schema NOT IN ('cron', 'net', 'auth', 'public', 'pgmq') THEN
    RAISE EXCEPTION 'Disallowed schema: %', p_schema;
  END IF;

  -- Fix #1749: 테이블 레벨 화이트리스트 검증
  IF NOT EXISTS (
    SELECT 1 FROM admin.retention_allowed_targets
    WHERE schema_name = p_schema
      AND table_name  = p_table
      AND ts_col      = p_ts_col
  ) THEN
    RAISE EXCEPTION 'Table not in retention whitelist: %.% (ts_col=%)', p_schema, p_table, p_ts_col;
  END IF;

  EXECUTE format(
    'DELETE FROM %I.%I WHERE %I < now()',
    p_schema, p_table, p_ts_col
  );
  GET DIAGNOSTICS deleted_count = ROW_COUNT;
  RETURN deleted_count;
END;
$$;

-- 4. Fix #1749: 동일 (schema, table)에 enabled=true db_table 정책 1개만 허용
CREATE UNIQUE INDEX retention_policies_one_enabled_per_target
  ON admin.retention_policies ((target->>'schema'), (target->>'table'))
  WHERE enabled AND kind = 'db_table';

-- 5. Fix #1749: legal_min_days 미만 retention_days 차단 트리거
CREATE OR REPLACE FUNCTION admin.validate_retention_policy_legal_min()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  min_days int;
BEGIN
  IF NEW.kind = 'db_table' THEN
    SELECT legal_min_days INTO min_days
      FROM admin.retention_allowed_targets
      WHERE schema_name = NEW.target->>'schema'
        AND table_name  = NEW.target->>'table';
    IF min_days IS NOT NULL AND NEW.retention_days < min_days THEN
      RAISE EXCEPTION
        'retention_days (%) below table legal_min_days (%) for %.%',
        NEW.retention_days, min_days,
        NEW.target->>'schema', NEW.target->>'table';
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER retention_policies_validate_legal_min
  BEFORE INSERT OR UPDATE ON admin.retention_policies
  FOR EACH ROW EXECUTE FUNCTION admin.validate_retention_policy_legal_min();
