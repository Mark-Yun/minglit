-- pgTAP RLS tests for admin.retention_policies + audit (feat #1692)
BEGIN;

SELECT plan(6);

-- Insert test policy as service_role (bypasses RLS)
INSERT INTO admin.retention_policies (id, kind, retention_days, target, description)
VALUES ('_rls_test_policy', 'db_table', 7, '{"schema":"public","table":"test","ts_col":"created_at"}', 'RLS test')
ON CONFLICT (id) DO NOTHING;

-- 1. service_role can SELECT retention_policies (RLS bypass)
SET LOCAL ROLE service_role;
SELECT ok(
  EXISTS (SELECT 1 FROM admin.retention_policies WHERE id = '_rls_test_policy'),
  'service_role can select from retention_policies'
);

-- 2. anon cannot SELECT retention_policies (no policy grants access)
SET LOCAL ROLE anon;
SELECT ok(
  NOT EXISTS (SELECT 1 FROM admin.retention_policies WHERE id = '_rls_test_policy'),
  'anon cannot select from retention_policies'
);

-- 3. authenticated non-admin cannot SELECT retention_policies
SET LOCAL ROLE authenticated;
SELECT ok(
  NOT EXISTS (SELECT 1 FROM admin.retention_policies WHERE id = '_rls_test_policy'),
  'authenticated non-admin cannot select from retention_policies'
);

-- Reset to superuser to clean up and check audit
RESET ROLE;

-- 4. audit trigger fires on INSERT: retention_policy_audit gets a record
SELECT ok(
  EXISTS (
    SELECT 1 FROM admin.retention_policy_audit
    WHERE policy_id = '_rls_test_policy' AND action = 'create'
  ),
  'audit trigger fires on retention_policies INSERT'
);

-- 5. audit trigger fires on UPDATE
UPDATE admin.retention_policies SET retention_days = 14 WHERE id = '_rls_test_policy';
SELECT ok(
  EXISTS (
    SELECT 1 FROM admin.retention_policy_audit
    WHERE policy_id = '_rls_test_policy' AND action = 'update'
  ),
  'audit trigger fires on retention_policies UPDATE'
);

-- 6. audit trigger fires on DELETE
DELETE FROM admin.retention_policies WHERE id = '_rls_test_policy';
SELECT ok(
  EXISTS (
    SELECT 1 FROM admin.retention_policy_audit
    WHERE policy_id = '_rls_test_policy' AND action = 'delete'
  ),
  'audit trigger fires on retention_policies DELETE'
);

SELECT * FROM finish();
ROLLBACK;
