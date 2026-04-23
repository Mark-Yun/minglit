-- pgTAP tests for retention table whitelist + partial unique index + legal_min_days trigger (fix #1749)
BEGIN;

SELECT plan(16);

-- 1. retention_allowed_targets table exists with expected columns
SELECT has_table('admin', 'retention_allowed_targets', 'retention_allowed_targets table exists');
SELECT has_column('admin', 'retention_allowed_targets', 'schema_name',    'has schema_name column');
SELECT has_column('admin', 'retention_allowed_targets', 'table_name',     'has table_name column');
SELECT has_column('admin', 'retention_allowed_targets', 'ts_col',         'has ts_col column');
SELECT has_column('admin', 'retention_allowed_targets', 'legal_min_days', 'has legal_min_days column');

-- 2. validate_retention_policy_legal_min trigger function exists
SELECT has_function(
  'admin', 'validate_retention_policy_legal_min', ARRAY[]::text[],
  'validate_retention_policy_legal_min function exists'
);

-- 3. delete_old_rows rejects table not in whitelist
SELECT throws_like(
  $$SELECT admin.delete_old_rows('public', 'users', 'created_at', 30)$$,
  '%not in retention whitelist%',
  'delete_old_rows rejects public.users (not in whitelist)'
);

-- 4. delete_expired_rows rejects table not in whitelist
SELECT throws_like(
  $$SELECT admin.delete_expired_rows('public', 'users', 'created_at')$$,
  '%not in retention whitelist%',
  'delete_expired_rows rejects public.users (not in whitelist)'
);

-- 5. delete_old_rows rejects disallowed schema even if ts_col matches
SELECT throws_like(
  $$SELECT admin.delete_old_rows('storage', 'objects', 'created_at', 7)$$,
  '%Disallowed schema%',
  'delete_old_rows rejects disallowed schema'
);

-- 6. Partial unique index blocks second enabled db_table policy for same target
SELECT throws_like(
  $$
    INSERT INTO admin.retention_policies (id, kind, retention_days, target, description)
    VALUES (
      'duplicate_cron_test',
      'db_table',
      30,
      '{"schema":"cron","table":"job_run_details","ts_col":"end_time"}',
      'duplicate test policy'
    )
  $$,
  '%duplicate key value%',
  'unique index blocks second enabled policy for same (schema, table)'
);

-- 7. legal_min_days trigger blocks retention_days below whitelist minimum
SELECT throws_like(
  $$
    INSERT INTO admin.retention_policies (id, kind, retention_days, target, description)
    VALUES (
      'location_log_too_short',
      'db_table',
      1,
      '{"schema":"public","table":"location_access_log","ts_col":"accessed_at"}',
      'test — retention_days below 180'
    )
  $$,
  '%below table legal_min_days%',
  'trigger blocks retention_days < legal_min_days (180) for location_access_log'
);

-- 8. legal_min_days trigger blocks archived_records below 1825 days
SELECT throws_like(
  $$
    INSERT INTO admin.retention_policies (id, kind, retention_days, target, description)
    VALUES (
      'archived_records_too_short',
      'db_table',
      365,
      '{"schema":"public","table":"archived_records","ts_col":"retention_until"}',
      'test — retention_days below 1825'
    )
  $$,
  '%below table legal_min_days%',
  'trigger blocks retention_days < legal_min_days (1825) for archived_records'
);

-- 9. Non-db_table kind skips legal_min_days trigger
SELECT lives_ok(
  $$
    INSERT INTO admin.retention_policies (id, kind, retention_days, target, description)
    VALUES (
      'test_pgmq_short',
      'pgmq_archive',
      1,
      '{"queue_name":"test_queue"}',
      'short pgmq retention — trigger should not block'
    )
  $$,
  'pgmq_archive kind skips legal_min_days check'
);
DELETE FROM admin.retention_policies WHERE id = 'test_pgmq_short';

-- 10. Whitelist seed covers the 4 expected targets
SELECT ok(
  (SELECT count(*) FROM admin.retention_allowed_targets) >= 4,
  'at least 4 entries in retention_allowed_targets'
);

-- 11. location_access_log entry has legal_min_days = 180
SELECT is(
  (SELECT legal_min_days FROM admin.retention_allowed_targets
   WHERE schema_name = 'public' AND table_name = 'location_access_log'),
  180,
  'location_access_log has legal_min_days = 180'
);

-- 12. archived_records entry has legal_min_days = 1825
SELECT is(
  (SELECT legal_min_days FROM admin.retention_allowed_targets
   WHERE schema_name = 'public' AND table_name = 'archived_records'),
  1825,
  'archived_records has legal_min_days = 1825'
);

SELECT * FROM finish();
ROLLBACK;
