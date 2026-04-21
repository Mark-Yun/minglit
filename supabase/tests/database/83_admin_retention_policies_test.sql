BEGIN;
SELECT no_plan();

-- ============================================================
-- Issue #1692: admin.retention_policies 스키마/RLS/함수 테스트
-- ============================================================

SELECT tests.authenticate_as_service_role();

-- 1. admin 스키마 존재 확인
SELECT has_schema('admin', 'admin schema exists');

-- 2. 테이블 존재 확인
SELECT has_table('admin', 'retention_policies', 'retention_policies table exists');
SELECT has_table('admin', 'retention_policy_audit', 'retention_policy_audit table exists');

-- 3. ENUM 타입 존재 확인
SELECT has_type('admin', 'retention_kind', 'retention_kind enum exists');

-- 4. 함수 존재 확인
SELECT has_function('admin', 'delete_old_rows', 'delete_old_rows function exists');
SELECT has_function('admin', 'archive_old_pgmq_messages', 'archive_old_pgmq_messages function exists');

-- 5. 초기 seed 6개 확인
SELECT is(
  (SELECT count(*)::integer FROM admin.retention_policies),
  6,
  'retention_policies has 6 seed rows'
);

-- 6. seed 정책 종류 확인
SELECT results_eq(
  $$SELECT kind::text FROM admin.retention_policies ORDER BY id$$,
  $$VALUES ('db_table'), ('db_table'), ('pgmq_archive'), ('pgmq_archive'), ('pgmq_archive'), ('storage_bucket')$$,
  'seed policies have correct kinds (sorted by id)'
);

-- 7. CHECK: retention_days > 0 검증
SELECT throws_ok(
  $$INSERT INTO admin.retention_policies (id, kind, retention_days, target)
    VALUES ('_test_bad', 'db_table', 0, '{}')$$,
  'P0001',
  NULL,
  'retention_days=0 violates CHECK constraint'
);

-- 8. CHECK: retention_above_legal_min 검증
SELECT throws_ok(
  $$INSERT INTO admin.retention_policies (id, kind, retention_days, legal_min_days, target)
    VALUES ('_test_legal', 'db_table', 7, 30, '{}')$$,
  'P0001',
  NULL,
  'retention_days < legal_min_days violates CHECK constraint'
);

-- 9. 감사 트리거: INSERT → audit 행 생성
INSERT INTO admin.retention_policies (id, kind, retention_days, target, description)
VALUES ('_test_audit', 'db_table', 10, '{"schema":"public","table":"test","ts_col":"created_at"}', 'test');

SELECT is(
  (SELECT action FROM admin.retention_policy_audit
   WHERE policy_id = '_test_audit' ORDER BY acted_at DESC LIMIT 1),
  'create',
  'INSERT triggers create audit entry'
);

-- 10. 감사 트리거: UPDATE → audit 행 생성
UPDATE admin.retention_policies SET description = 'updated' WHERE id = '_test_audit';

SELECT is(
  (SELECT action FROM admin.retention_policy_audit
   WHERE policy_id = '_test_audit' ORDER BY acted_at DESC LIMIT 1),
  'update',
  'UPDATE triggers update audit entry'
);

-- 11. 감사 트리거: DELETE → audit 행 생성
DELETE FROM admin.retention_policies WHERE id = '_test_audit';

SELECT is(
  (SELECT action FROM admin.retention_policy_audit
   WHERE policy_id = '_test_audit' ORDER BY acted_at DESC LIMIT 1),
  'delete',
  'DELETE triggers delete audit entry'
);

-- 12. delete_old_rows: 허용된 스키마만 통과
SELECT lives_ok(
  $$SELECT admin.delete_old_rows('public', 'nonexistent_table_xyz', 'created_at', 1)$$,
  'delete_old_rows accepts public schema (may fail on missing table — that is ok)'
);

-- 13. delete_old_rows: 허용되지 않은 스키마 차단
SELECT throws_ok(
  $$SELECT admin.delete_old_rows('information_schema', 'tables', 'created', 1)$$,
  'P0001',
  'Disallowed schema: information_schema',
  'delete_old_rows blocks disallowed schemas'
);

-- 14. 스키마 권한: anon/authenticated는 admin USAGE 없음
SELECT results_eq(
  $$SELECT has_schema_privilege('anon', 'admin', 'USAGE')::text$$,
  $$VALUES ('false')$$,
  'anon has no USAGE on admin schema'
);

SELECT results_eq(
  $$SELECT has_schema_privilege('authenticated', 'admin', 'USAGE')::text$$,
  $$VALUES ('false')$$,
  'authenticated has no USAGE on admin schema'
);

SELECT * FROM finish();
ROLLBACK;
