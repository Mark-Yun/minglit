-- feat #1703: archived_records 자동 파기 + legal_min_days 방어

-- 1. New helper for absolute-expiry deletion (WHERE ts_col < now())
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
  IF p_schema NOT IN ('cron', 'net', 'auth', 'public', 'pgmq') THEN
    RAISE EXCEPTION 'Disallowed schema: %', p_schema;
  END IF;
  EXECUTE format(
    'DELETE FROM %I.%I WHERE %I < now()',
    p_schema, p_table, p_ts_col
  );
  GET DIAGNOSTICS deleted_count = ROW_COUNT;
  RETURN deleted_count;
END;
$$;

REVOKE ALL ON FUNCTION admin.delete_expired_rows(text, text, text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION admin.delete_expired_rows(text, text, text) TO service_role;

-- 2. Register archived_records policy with legal_min_days=1825 (5y PIPA §21 + e-commerce §6)
INSERT INTO admin.retention_policies
  (id, kind, retention_days, legal_min_days, target, description)
VALUES
  (
    'archived_records_expired',
    'db_table',
    1826,
    1825,
    '{"schema":"public","table":"archived_records","ts_col":"retention_until","use_absolute_ts":true}',
    '전자상거래법 §6 + PIPA §21 기반 archive의 retention_until 경과 후 파기'
  )
ON CONFLICT (id) DO NOTHING;
