-- pgTAP tests for admin schema + retention_policies (feat #1692)
BEGIN;

SELECT plan(23);

-- 1. admin schema exists
SELECT has_schema('admin', 'admin schema exists');

-- 2. admin schema not accessible by anon/authenticated
SELECT schema_privs_are('admin', 'anon', ARRAY[]::text[], 'anon has no admin schema privs');
SELECT schema_privs_are('admin', 'authenticated', ARRAY[]::text[], 'authenticated has no admin schema privs');

-- 3. retention_policies table exists with required columns
SELECT has_table('admin', 'retention_policies', 'retention_policies table exists');
SELECT has_column('admin', 'retention_policies', 'id', 'has id column');
SELECT has_column('admin', 'retention_policies', 'kind', 'has kind column');
SELECT has_column('admin', 'retention_policies', 'retention_days', 'has retention_days column');
SELECT has_column('admin', 'retention_policies', 'target', 'has target column');
SELECT has_column('admin', 'retention_policies', 'enabled', 'has enabled column');
SELECT has_column('admin', 'retention_policies', 'last_run_at', 'has last_run_at column');

-- 4. retention_policy_audit table exists
SELECT has_table('admin', 'retention_policy_audit', 'retention_policy_audit table exists');
SELECT has_column('admin', 'retention_policy_audit', 'policy_id', 'audit has policy_id column');
SELECT has_column('admin', 'retention_policy_audit', 'action', 'audit has action column');
SELECT has_column('admin', 'retention_policy_audit', 'rows_deleted', 'audit has rows_deleted column');

-- 5. RLS is enabled
SELECT ok(
  (SELECT rowsecurity FROM pg_tables WHERE schemaname = 'admin' AND tablename = 'retention_policies'),
  'RLS enabled on retention_policies'
);
SELECT ok(
  (SELECT rowsecurity FROM pg_tables WHERE schemaname = 'admin' AND tablename = 'retention_policy_audit'),
  'RLS enabled on retention_policy_audit'
);

-- 6. SECURITY DEFINER functions exist
SELECT has_function('admin', 'delete_old_rows', ARRAY['text','text','text','integer'], 'delete_old_rows function exists');
SELECT has_function('admin', 'archive_old_pgmq_messages', ARRAY['text','integer'], 'archive_old_pgmq_messages function exists');
SELECT has_function('admin', 'log_retention_policy_change', ARRAY[]::text[], 'log_retention_policy_change function exists');

-- 7. EXECUTE privilege on admin functions: service_role can execute, anon/authenticated cannot
SELECT function_privs_are(
  'admin', 'delete_old_rows', ARRAY['text','text','text','integer'],
  'service_role', ARRAY['EXECUTE'],
  'service_role can execute delete_old_rows'
);
SELECT function_privs_are(
  'admin', 'delete_old_rows', ARRAY['text','text','text','integer'],
  'anon', ARRAY[]::text[],
  'anon cannot execute delete_old_rows'
);
SELECT function_privs_are(
  'admin', 'archive_old_pgmq_messages', ARRAY['text','integer'],
  'service_role', ARRAY['EXECUTE'],
  'service_role can execute archive_old_pgmq_messages'
);
SELECT function_privs_are(
  'admin', 'archive_old_pgmq_messages', ARRAY['text','integer'],
  'anon', ARRAY[]::text[],
  'anon cannot execute archive_old_pgmq_messages'
);

SELECT * FROM finish();
ROLLBACK;
