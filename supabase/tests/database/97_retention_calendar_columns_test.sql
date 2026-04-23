-- pgTAP tests for retention_calendar_value/unit columns (feat #1789)
-- migration: 20260424000002_add_retention_calendar_columns.sql
BEGIN;

SELECT plan(23);

-- 1. 신규 컬럼 존재 확인
SELECT has_column('admin', 'retention_policies', 'retention_calendar_value', 'retention_calendar_value column exists');
SELECT has_column('admin', 'retention_policies', 'retention_calendar_unit', 'retention_calendar_unit column exists');

-- 2. 컬럼 타입 확인
SELECT col_type_is('admin', 'retention_policies', 'retention_calendar_value', 'integer', 'retention_calendar_value is integer');
SELECT col_type_is('admin', 'retention_policies', 'retention_calendar_unit', 'text', 'retention_calendar_unit is text');

-- 3. 컬럼 nullable 확인 (둘 다 NULL 허용, information_schema 사용)
SELECT ok(
  (SELECT is_nullable = 'YES' FROM information_schema.columns
   WHERE table_schema = 'admin' AND table_name = 'retention_policies'
   AND column_name = 'retention_calendar_value'),
  'retention_calendar_value is nullable'
);
SELECT ok(
  (SELECT is_nullable = 'YES' FROM information_schema.columns
   WHERE table_schema = 'admin' AND table_name = 'retention_policies'
   AND column_name = 'retention_calendar_unit'),
  'retention_calendar_unit is nullable'
);

-- 4. UPDATE 결과 확인: calendar 컬럼이 올바르게 설정됐는지
SELECT ok(
  (SELECT retention_calendar_value = 5 AND retention_calendar_unit = 'year'
   FROM admin.retention_policies WHERE id = 'contract_retention'),
  'contract_retention: calendar=(5, year)'
);
SELECT ok(
  (SELECT retention_calendar_value = 5 AND retention_calendar_unit = 'year'
   FROM admin.retention_policies WHERE id = 'payment_retention'),
  'payment_retention: calendar=(5, year)'
);
SELECT ok(
  (SELECT retention_calendar_value = 3 AND retention_calendar_unit = 'year'
   FROM admin.retention_policies WHERE id = 'dispute_retention'),
  'dispute_retention: calendar=(3, year)'
);
SELECT ok(
  (SELECT retention_calendar_value = 3 AND retention_calendar_unit = 'month'
   FROM admin.retention_policies WHERE id = 'login_history_retention'),
  'login_history_retention: calendar=(3, month)'
);
SELECT ok(
  (SELECT retention_calendar_value = 2 AND retention_calendar_unit = 'year'
   FROM admin.retention_policies WHERE id = 'consent_retention'),
  'consent_retention: calendar=(2, year)'
);

-- 5. deletion_grace, blocked_di_records는 calendar 컬럼 NULL 유지 (retention_days만 사용)
SELECT ok(
  (SELECT retention_calendar_value IS NULL AND retention_calendar_unit IS NULL
   FROM admin.retention_policies WHERE id = 'deletion_grace'),
  'deletion_grace: calendar columns remain NULL'
);
SELECT ok(
  (SELECT retention_calendar_value IS NULL AND retention_calendar_unit IS NULL
   FROM admin.retention_policies WHERE id = 'blocked_di_records'),
  'blocked_di_records: calendar columns remain NULL'
);

-- 6. CHECK 제약 위반 확인 (SQLSTATE 23514 = check_violation)
SELECT throws_ok(
  $$INSERT INTO admin.retention_policies (id, kind, retention_days, legal_min_days, target, description, enabled, retention_calendar_value, retention_calendar_unit)
    VALUES ('test_chk_zero', 'db_table', 10, 10, '{"schema":"public","table":"t","ts_col":"ts"}', 'test', false, 0, 'day')$$,
  '23514',
  'retention_calendar_value > 0 CHECK prevents zero value'
);
SELECT throws_ok(
  $$INSERT INTO admin.retention_policies (id, kind, retention_days, legal_min_days, target, description, enabled, retention_calendar_value, retention_calendar_unit)
    VALUES ('test_chk_neg', 'db_table', 10, 10, '{"schema":"public","table":"t","ts_col":"ts"}', 'test', false, -1, 'year')$$,
  '23514',
  'retention_calendar_value > 0 CHECK prevents negative value'
);
SELECT throws_ok(
  $$INSERT INTO admin.retention_policies (id, kind, retention_days, legal_min_days, target, description, enabled, retention_calendar_value, retention_calendar_unit)
    VALUES ('test_chk_unit', 'db_table', 10, 10, '{"schema":"public","table":"t","ts_col":"ts"}', 'test', false, 1, 'week')$$,
  '23514',
  'retention_calendar_unit IN CHECK prevents invalid unit'
);
SELECT throws_ok(
  $$INSERT INTO admin.retention_policies (id, kind, retention_days, legal_min_days, target, description, enabled, retention_calendar_value, retention_calendar_unit)
    VALUES ('test_pair1', 'db_table', 10, 10, '{"schema":"public","table":"t","ts_col":"ts"}', 'test', false, 5, NULL)$$,
  '23514',
  'pair check: value without unit is rejected'
);
SELECT throws_ok(
  $$INSERT INTO admin.retention_policies (id, kind, retention_days, legal_min_days, target, description, enabled, retention_calendar_value, retention_calendar_unit)
    VALUES ('test_pair2', 'db_table', 10, 10, '{"schema":"public","table":"t","ts_col":"ts"}', 'test', false, NULL, 'year')$$,
  '23514',
  'pair check: unit without value is rejected'
);

-- 7. constraint 존재 확인
SELECT ok(
  EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'retention_calendar_unit_pair_check'
    AND conrelid = 'admin.retention_policies'::regclass
  ),
  'retention_calendar_unit_pair_check constraint exists'
);

SELECT * FROM finish();
ROLLBACK;
