-- pgTAP tests for admin.retention_policies seed data (feat #1789)
-- migration: 20260424000001_process_pending_deletions_retention_seed.sql
BEGIN;

SELECT plan(50);

-- 1. 7개 행이 모두 존재하는지 확인
SELECT ok(
  EXISTS (SELECT 1 FROM admin.retention_policies WHERE id = 'deletion_grace'),
  'deletion_grace row exists'
);
SELECT ok(
  EXISTS (SELECT 1 FROM admin.retention_policies WHERE id = 'blocked_di_records'),
  'blocked_di_records row exists'
);
SELECT ok(
  EXISTS (SELECT 1 FROM admin.retention_policies WHERE id = 'contract_retention'),
  'contract_retention row exists'
);
SELECT ok(
  EXISTS (SELECT 1 FROM admin.retention_policies WHERE id = 'payment_retention'),
  'payment_retention row exists'
);
SELECT ok(
  EXISTS (SELECT 1 FROM admin.retention_policies WHERE id = 'dispute_retention'),
  'dispute_retention row exists'
);
SELECT ok(
  EXISTS (SELECT 1 FROM admin.retention_policies WHERE id = 'login_history_retention'),
  'login_history_retention row exists'
);
SELECT ok(
  EXISTS (SELECT 1 FROM admin.retention_policies WHERE id = 'consent_retention'),
  'consent_retention row exists'
);

-- 2. kind='db_table', enabled=false 확인
SELECT ok(
  (SELECT kind = 'db_table' AND enabled = false FROM admin.retention_policies WHERE id = 'deletion_grace'),
  'deletion_grace: kind=db_table, enabled=false'
);
SELECT ok(
  (SELECT kind = 'db_table' AND enabled = false FROM admin.retention_policies WHERE id = 'blocked_di_records'),
  'blocked_di_records: kind=db_table, enabled=false'
);
SELECT ok(
  (SELECT kind = 'db_table' AND enabled = false FROM admin.retention_policies WHERE id = 'contract_retention'),
  'contract_retention: kind=db_table, enabled=false'
);
SELECT ok(
  (SELECT kind = 'db_table' AND enabled = false FROM admin.retention_policies WHERE id = 'login_history_retention'),
  'login_history_retention: kind=db_table, enabled=false'
);
SELECT ok(
  (SELECT kind = 'db_table' AND enabled = false FROM admin.retention_policies WHERE id = 'payment_retention'),
  'payment_retention: kind=db_table, enabled=false'
);
SELECT ok(
  (SELECT kind = 'db_table' AND enabled = false FROM admin.retention_policies WHERE id = 'dispute_retention'),
  'dispute_retention: kind=db_table, enabled=false'
);
SELECT ok(
  (SELECT kind = 'db_table' AND enabled = false FROM admin.retention_policies WHERE id = 'consent_retention'),
  'consent_retention: kind=db_table, enabled=false'
);

-- 3. metadata.skip_cleanup=true — 이 행들은 cleanup-retention 엔진이 실행하지 않는다
SELECT ok(
  (SELECT (metadata->>'skip_cleanup')::boolean = true FROM admin.retention_policies WHERE id = 'deletion_grace'),
  'deletion_grace: metadata.skip_cleanup=true'
);
SELECT ok(
  (SELECT (metadata->>'skip_cleanup')::boolean = true FROM admin.retention_policies WHERE id = 'blocked_di_records'),
  'blocked_di_records: metadata.skip_cleanup=true'
);
SELECT ok(
  (SELECT (metadata->>'skip_cleanup')::boolean = true FROM admin.retention_policies WHERE id = 'contract_retention'),
  'contract_retention: metadata.skip_cleanup=true'
);
SELECT ok(
  (SELECT (metadata->>'skip_cleanup')::boolean = true FROM admin.retention_policies WHERE id = 'payment_retention'),
  'payment_retention: metadata.skip_cleanup=true'
);
SELECT ok(
  (SELECT (metadata->>'skip_cleanup')::boolean = true FROM admin.retention_policies WHERE id = 'dispute_retention'),
  'dispute_retention: metadata.skip_cleanup=true'
);
SELECT ok(
  (SELECT (metadata->>'skip_cleanup')::boolean = true FROM admin.retention_policies WHERE id = 'login_history_retention'),
  'login_history_retention: metadata.skip_cleanup=true'
);
SELECT ok(
  (SELECT (metadata->>'skip_cleanup')::boolean = true FROM admin.retention_policies WHERE id = 'consent_retention'),
  'consent_retention: metadata.skip_cleanup=true'
);

-- 4. retention_days = legal_min_days 확인
SELECT ok(
  (SELECT retention_days = legal_min_days FROM admin.retention_policies WHERE id = 'deletion_grace'),
  'deletion_grace: retention_days = legal_min_days'
);
SELECT ok(
  (SELECT retention_days = legal_min_days FROM admin.retention_policies WHERE id = 'blocked_di_records'),
  'blocked_di_records: retention_days = legal_min_days'
);
SELECT ok(
  (SELECT retention_days = legal_min_days FROM admin.retention_policies WHERE id = 'contract_retention'),
  'contract_retention: retention_days = legal_min_days'
);
SELECT ok(
  (SELECT retention_days = legal_min_days FROM admin.retention_policies WHERE id = 'payment_retention'),
  'payment_retention: retention_days = legal_min_days'
);
SELECT ok(
  (SELECT retention_days = legal_min_days FROM admin.retention_policies WHERE id = 'dispute_retention'),
  'dispute_retention: retention_days = legal_min_days'
);
SELECT ok(
  (SELECT retention_days = legal_min_days FROM admin.retention_policies WHERE id = 'login_history_retention'),
  'login_history_retention: retention_days = legal_min_days'
);
SELECT ok(
  (SELECT retention_days = legal_min_days FROM admin.retention_policies WHERE id = 'consent_retention'),
  'consent_retention: retention_days = legal_min_days'
);

-- 5. target JSONB 필수 키 확인 (schema, table, ts_col)
SELECT ok(
  (SELECT target ? 'schema' AND target ? 'table' AND target ? 'ts_col' FROM admin.retention_policies WHERE id = 'deletion_grace'),
  'deletion_grace: target has schema, table, ts_col'
);
SELECT ok(
  (SELECT target ? 'schema' AND target ? 'table' AND target ? 'ts_col' FROM admin.retention_policies WHERE id = 'blocked_di_records'),
  'blocked_di_records: target has schema, table, ts_col'
);
SELECT ok(
  (SELECT target ? 'schema' AND target ? 'table' AND target ? 'ts_col' FROM admin.retention_policies WHERE id = 'contract_retention'),
  'contract_retention: target has schema, table, ts_col'
);

-- 6. archive 타입 행: target이 archived_records를 가리키며 record_type 키를 보유
SELECT ok(
  (SELECT target->>'table' = 'archived_records' AND target ? 'record_type' FROM admin.retention_policies WHERE id = 'contract_retention'),
  'contract_retention: target=archived_records, has record_type'
);
SELECT ok(
  (SELECT target->>'table' = 'archived_records' AND target ? 'record_type' FROM admin.retention_policies WHERE id = 'payment_retention'),
  'payment_retention: target=archived_records, has record_type'
);
SELECT ok(
  (SELECT target->>'table' = 'archived_records' AND target ? 'record_type' FROM admin.retention_policies WHERE id = 'dispute_retention'),
  'dispute_retention: target=archived_records, has record_type'
);
SELECT ok(
  (SELECT target->>'table' = 'archived_records' AND target ? 'record_type' FROM admin.retention_policies WHERE id = 'login_history_retention'),
  'login_history_retention: target=archived_records, has record_type'
);
SELECT ok(
  (SELECT target->>'table' = 'archived_records' AND target ? 'record_type' FROM admin.retention_policies WHERE id = 'consent_retention'),
  'consent_retention: target=archived_records, has record_type'
);

-- 7. record_type 값 정확성 확인 (archive 타입 5개 + deletion_grace target 검증)
SELECT ok(
  (SELECT target->>'schema' = 'public' AND target->>'table' = 'user_profiles' FROM admin.retention_policies WHERE id = 'deletion_grace'),
  'deletion_grace: target schema=public, table=user_profiles'
);
SELECT ok(
  (SELECT target->>'record_type' = 'contract' FROM admin.retention_policies WHERE id = 'contract_retention'),
  'contract_retention: record_type=contract'
);
SELECT ok(
  (SELECT target->>'record_type' = 'payment' FROM admin.retention_policies WHERE id = 'payment_retention'),
  'payment_retention: record_type=payment'
);
SELECT ok(
  (SELECT target->>'record_type' = 'dispute' FROM admin.retention_policies WHERE id = 'dispute_retention'),
  'dispute_retention: record_type=dispute'
);
SELECT ok(
  (SELECT target->>'record_type' = 'login' FROM admin.retention_policies WHERE id = 'login_history_retention'),
  'login_history_retention: record_type=login'
);
SELECT ok(
  (SELECT target->>'record_type' = 'consent' FROM admin.retention_policies WHERE id = 'consent_retention'),
  'consent_retention: record_type=consent'
);

-- 8. ON CONFLICT DO NOTHING 확인: 재실행 시 기존 행 덮어쓰지 않음
DO $$
DECLARE
  orig_days integer;
BEGIN
  SELECT retention_days INTO orig_days FROM admin.retention_policies WHERE id = 'deletion_grace';

  INSERT INTO admin.retention_policies
    (id, kind, retention_days, legal_min_days, target, description, enabled)
  VALUES
    ('deletion_grace', 'db_table', 9999, 9999, '{"schema":"public","table":"user_profiles","ts_col":"deleted_at"}', 'test', false)
  ON CONFLICT (id) DO NOTHING;

  IF (SELECT retention_days FROM admin.retention_policies WHERE id = 'deletion_grace') != orig_days THEN
    RAISE EXCEPTION 'ON CONFLICT DO NOTHING did not preserve original value';
  END IF;
END;
$$;
SELECT ok(true, 'ON CONFLICT DO NOTHING preserves original values on re-run');

-- 9. retention_days 정확한 값 확인
SELECT ok(
  (SELECT retention_days = 7 FROM admin.retention_policies WHERE id = 'deletion_grace'),
  'deletion_grace: retention_days=7'
);
SELECT ok(
  (SELECT retention_days = 30 FROM admin.retention_policies WHERE id = 'blocked_di_records'),
  'blocked_di_records: retention_days=30'
);
SELECT ok(
  (SELECT retention_days = 1825 FROM admin.retention_policies WHERE id = 'contract_retention'),
  'contract_retention: retention_days=1825'
);
SELECT ok(
  (SELECT retention_days = 1825 FROM admin.retention_policies WHERE id = 'payment_retention'),
  'payment_retention: retention_days=1825'
);
SELECT ok(
  (SELECT retention_days = 1095 FROM admin.retention_policies WHERE id = 'dispute_retention'),
  'dispute_retention: retention_days=1095'
);
SELECT ok(
  (SELECT retention_days = 90 FROM admin.retention_policies WHERE id = 'login_history_retention'),
  'login_history_retention: retention_days=90'
);
SELECT ok(
  (SELECT retention_days = 730 FROM admin.retention_policies WHERE id = 'consent_retention'),
  'consent_retention: retention_days=730'
);

SELECT * FROM finish();
ROLLBACK;
