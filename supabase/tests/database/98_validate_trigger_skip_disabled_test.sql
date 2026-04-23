-- pgTAP tests for validate_retention_policy_legal_min trigger — enabled=false bypass (fix #1789)
-- migration: 20260424000003_fix_validate_trigger_skip_disabled.sql
BEGIN;

SELECT plan(3);

-- 1. enabled=false 행은 retention_days < whitelist legal_min_days 허용
-- dispute_retention: retention_days=1095, archived_records.legal_min_days=1825 → allowed when disabled
SELECT lives_ok(
  $$INSERT INTO admin.retention_policies
      (id, kind, retention_days, legal_min_days, target, description, enabled, metadata)
    VALUES
      ('_test_disabled_low_retention', 'db_table', 100, 100,
       '{"schema":"public","table":"archived_records","ts_col":"retention_until"}',
       'test: disabled row bypasses whitelist check', false, '{"skip_cleanup":true}')$$,
  'disabled row with retention_days < whitelist legal_min_days is allowed'
);

-- 2. enabled=true 행은 여전히 retention_days < whitelist legal_min_days 차단
SELECT throws_ok(
  $$INSERT INTO admin.retention_policies
      (id, kind, retention_days, legal_min_days, target, description, enabled)
    VALUES
      ('_test_enabled_low_retention', 'db_table', 100, 100,
       '{"schema":"public","table":"archived_records","ts_col":"retention_until"}',
       'test: enabled row rejected by whitelist check', true)$$,
  '23514',
  NULL,
  'enabled row with retention_days < whitelist legal_min_days is rejected'
);

-- 3. 기존 archived_records_expired (enabled=true) 정책 업데이트도 여전히 차단
SELECT throws_ok(
  $$UPDATE admin.retention_policies SET retention_days = 100 WHERE id = 'archived_records_expired'$$,
  '23514',
  NULL,
  'trigger still blocks retention_days update below legal_min for enabled policy'
);

SELECT * FROM finish();
ROLLBACK;
