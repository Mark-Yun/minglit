BEGIN;
SELECT no_plan();

-- ============================================================
-- 1. Schema — soft-delete column and account deletion tables
-- ============================================================
SELECT has_column('public', 'user_profiles', 'deleted_at', 'user_profiles.deleted_at exists');
SELECT col_type_is('public', 'user_profiles', 'deleted_at', 'timestamp with time zone', 'user_profiles.deleted_at is timestamptz');
SELECT has_index('public', 'user_profiles', 'idx_user_profiles_deleted_at', 'idx_user_profiles_deleted_at exists');

SELECT has_table('public', 'withdrawal_reasons', 'withdrawal_reasons table exists');
SELECT col_is_pk('public', 'withdrawal_reasons', 'id', 'withdrawal_reasons.id is primary key');
SELECT col_type_is('public', 'withdrawal_reasons', 'id', 'bigint', 'withdrawal_reasons.id is bigint');
SELECT col_type_is('public', 'withdrawal_reasons', 'reason_code', 'text', 'withdrawal_reasons.reason_code is text');
SELECT col_type_is('public', 'withdrawal_reasons', 'reason_text', 'text', 'withdrawal_reasons.reason_text is text');
SELECT col_type_is('public', 'withdrawal_reasons', 'created_at', 'timestamp with time zone', 'withdrawal_reasons.created_at is timestamptz');
SELECT col_not_null('public', 'withdrawal_reasons', 'reason_code', 'withdrawal_reasons.reason_code is NOT NULL');
SELECT tests.rls_enabled('public', 'withdrawal_reasons');

SELECT has_table('public', 'blocked_dis', 'blocked_dis table exists');
SELECT col_is_pk('public', 'blocked_dis', 'di_hash', 'blocked_dis.di_hash is primary key');
SELECT col_type_is('public', 'blocked_dis', 'di_hash', 'text', 'blocked_dis.di_hash is text');
SELECT col_type_is('public', 'blocked_dis', 'blocked_until', 'timestamp with time zone', 'blocked_dis.blocked_until is timestamptz');
SELECT col_type_is('public', 'blocked_dis', 'created_at', 'timestamp with time zone', 'blocked_dis.created_at is timestamptz');
SELECT col_not_null('public', 'blocked_dis', 'blocked_until', 'blocked_dis.blocked_until is NOT NULL');
SELECT has_index('public', 'blocked_dis', 'idx_blocked_dis_blocked_until', 'idx_blocked_dis_blocked_until exists');
SELECT tests.rls_enabled('public', 'blocked_dis');

SELECT has_table('public', 'archived_records', 'archived_records table exists');
SELECT col_is_pk('public', 'archived_records', 'id', 'archived_records.id is primary key');
SELECT col_type_is('public', 'archived_records', 'id', 'bigint', 'archived_records.id is bigint');
SELECT col_type_is('public', 'archived_records', 'user_id_hash', 'text', 'archived_records.user_id_hash is text');
SELECT col_type_is('public', 'archived_records', 'record_type', 'text', 'archived_records.record_type is text');
SELECT col_type_is('public', 'archived_records', 'record_data', 'jsonb', 'archived_records.record_data is jsonb');
SELECT col_type_is('public', 'archived_records', 'retention_until', 'timestamp with time zone', 'archived_records.retention_until is timestamptz');
SELECT col_type_is('public', 'archived_records', 'created_at', 'timestamp with time zone', 'archived_records.created_at is timestamptz');
SELECT col_not_null('public', 'archived_records', 'user_id_hash', 'archived_records.user_id_hash is NOT NULL');
SELECT col_not_null('public', 'archived_records', 'record_type', 'archived_records.record_type is NOT NULL');
SELECT col_not_null('public', 'archived_records', 'record_data', 'archived_records.record_data is NOT NULL');
SELECT col_not_null('public', 'archived_records', 'retention_until', 'archived_records.retention_until is NOT NULL');
SELECT has_index('public', 'archived_records', 'idx_archived_records_retention_until', 'idx_archived_records_retention_until exists');
SELECT tests.rls_enabled('public', 'archived_records');

SELECT results_eq(
  $$
    SELECT count(*)::int
    FROM pg_constraint c
    JOIN pg_class t ON t.oid = c.conrelid
    JOIN pg_namespace n ON n.oid = t.relnamespace
    WHERE n.nspname = 'public'
      AND t.relname = 'archived_records'
      AND c.conname = 'archived_records_record_type_check'
  $$,
  $$VALUES (1)$$,
  'archived_records_record_type_check exists'
);

-- ============================================================
-- 2. service_role can manage account deletion tables
-- ============================================================
SELECT tests.authenticate_as_service_role();

SELECT lives_ok(
  $$INSERT INTO public.withdrawal_reasons (reason_code, reason_text)
    VALUES ('privacy', 'privacy concern')$$,
  'service_role can INSERT withdrawal_reasons'
);

SELECT lives_ok(
  $$INSERT INTO public.blocked_dis (di_hash, blocked_until)
    VALUES ('hash-1', now() + interval '30 days')$$,
  'service_role can INSERT blocked_dis'
);

SELECT lives_ok(
  $$INSERT INTO public.archived_records (user_id_hash, record_type, record_data, retention_until)
    VALUES ('user-hash-1', 'payment', '{"amount": 10000}'::jsonb, now() + interval '5 years')$$,
  'service_role can INSERT archived_records'
);

SELECT results_eq(
  $$SELECT count(*)::int FROM public.withdrawal_reasons WHERE reason_code = 'privacy'$$,
  $$VALUES (1)$$,
  'service_role can SELECT withdrawal_reasons'
);

SELECT results_eq(
  $$SELECT count(*)::int FROM public.blocked_dis WHERE di_hash = 'hash-1'$$,
  $$VALUES (1)$$,
  'service_role can SELECT blocked_dis'
);

SELECT results_eq(
  $$SELECT count(*)::int FROM public.archived_records WHERE user_id_hash = 'user-hash-1'$$,
  $$VALUES (1)$$,
  'service_role can SELECT archived_records'
);

SELECT lives_ok(
  $$UPDATE public.blocked_dis
      SET blocked_until = now() + interval '31 days'
    WHERE di_hash = 'hash-1'$$,
  'service_role can UPDATE blocked_dis'
);

SELECT lives_ok(
  $$DELETE FROM public.withdrawal_reasons WHERE reason_code = 'privacy'$$,
  'service_role can DELETE withdrawal_reasons'
);

-- ============================================================
-- 3. authenticated and anon cannot read service-role-only tables
-- ============================================================
SELECT tests.create_supabase_user('account_deletion_rls_user', 'account_deletion_rls@test.com');
SELECT tests.authenticate_as('account_deletion_rls_user');

SELECT throws_ok(
  $$SELECT * FROM public.withdrawal_reasons$$,
  '42501',
  NULL,
  'authenticated user cannot SELECT withdrawal_reasons'
);

SELECT throws_ok(
  $$SELECT * FROM public.blocked_dis$$,
  '42501',
  NULL,
  'authenticated user cannot SELECT blocked_dis'
);

SELECT throws_ok(
  $$SELECT * FROM public.archived_records$$,
  '42501',
  NULL,
  'authenticated user cannot SELECT archived_records'
);

SELECT tests.clear_authentication();

SELECT throws_ok(
  $$SELECT * FROM public.withdrawal_reasons$$,
  '42501',
  NULL,
  'anon cannot SELECT withdrawal_reasons'
);

SELECT throws_ok(
  $$SELECT * FROM public.blocked_dis$$,
  '42501',
  NULL,
  'anon cannot SELECT blocked_dis'
);

SELECT throws_ok(
  $$SELECT * FROM public.archived_records$$,
  '42501',
  NULL,
  'anon cannot SELECT archived_records'
);

SELECT * FROM finish();
ROLLBACK;
