-- pgTAP tests for archived_records 자동 파기 + delete_expired_rows RPC (feat #1703)
BEGIN;

SELECT plan(10);

-- 1. delete_expired_rows 함수 존재 확인
SELECT has_function('admin', 'delete_expired_rows', ARRAY['text','text','text'], 'delete_expired_rows function exists');

-- 2. service_role은 실행 가능, anon은 불가
SELECT function_privs_are(
  'admin', 'delete_expired_rows', ARRAY['text','text','text'],
  'service_role', ARRAY['EXECUTE'],
  'service_role can execute delete_expired_rows'
);
SELECT function_privs_are(
  'admin', 'delete_expired_rows', ARRAY['text','text','text'],
  'anon', ARRAY[]::text[],
  'anon cannot execute delete_expired_rows'
);

-- 3. archived_records_expired 정책 등록 확인
SELECT ok(
  EXISTS(
    SELECT 1 FROM admin.retention_policies
    WHERE id = 'archived_records_expired'
      AND kind = 'db_table'
      AND enabled = true
  ),
  'archived_records_expired policy exists and is enabled'
);

-- 4. legal_min_days >= 1825 (5년, 전자상거래법 §6)
SELECT ok(
  (SELECT legal_min_days FROM admin.retention_policies WHERE id = 'archived_records_expired') >= 1825,
  'archived_records_expired legal_min_days >= 1825'
);

-- 5. target.use_absolute_ts = true
SELECT ok(
  (SELECT target->>'use_absolute_ts' FROM admin.retention_policies WHERE id = 'archived_records_expired') = 'true',
  'archived_records_expired target.use_absolute_ts = true'
);

-- 6. 트리거: retention_days < legal_min_days 거절
SELECT throws_ok(
  $$UPDATE admin.retention_policies SET retention_days = 100 WHERE id = 'archived_records_expired'$$,
  'P0001',
  NULL,
  'trigger blocks retention_days < legal_min_days for archived_records_expired'
);

-- 7. 기능 테스트: 만료 레코드 삭제 (BEGIN..ROLLBACK 내부)
SAVEPOINT before_functional_test;

-- 만료된 레코드 삽입 (retention_until = 어제)
-- archived_records schema: user_id_hash text, record_data jsonb, record_type IN ('contract','payment','dispute','login')
INSERT INTO public.archived_records (user_id_hash, record_type, record_data, retention_until)
VALUES (
  'test-hash-expired',
  'payment',
  '{"test": "expired"}'::jsonb,
  now() - interval '1 day'
);

SELECT ok(
  (SELECT admin.delete_expired_rows('public', 'archived_records', 'retention_until')) > 0,
  'delete_expired_rows deletes expired rows (retention_until < now)'
);

ROLLBACK TO SAVEPOINT before_functional_test;

-- 8. 기능 테스트: 미만료 레코드 보존
SAVEPOINT before_live_test;

INSERT INTO public.archived_records (user_id_hash, record_type, record_data, retention_until)
VALUES (
  'test-hash-live',
  'payment',
  '{"test": "live"}'::jsonb,
  now() + interval '1 day'
);

SELECT ok(
  (SELECT admin.delete_expired_rows('public', 'archived_records', 'retention_until')) = 0,
  'delete_expired_rows does NOT delete non-expired rows (retention_until > now)'
);

ROLLBACK TO SAVEPOINT before_live_test;

-- 9. 허용되지 않은 schema 거절
SELECT throws_ok(
  $$SELECT admin.delete_expired_rows('private', 'some_table', 'created_at')$$,
  'P0001',
  NULL,
  'delete_expired_rows rejects disallowed schema'
);

SELECT * FROM finish();
ROLLBACK;
