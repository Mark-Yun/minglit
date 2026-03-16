BEGIN;
SELECT no_plan();

-- ============================================================
-- 1. Schema — table existence + columns + index + RLS
-- ============================================================
SELECT has_table('public', 'policies', 'policies table exists');
SELECT col_is_pk('public', 'policies', 'id', 'policies.id is primary key');
SELECT col_type_is('public', 'policies', 'id', 'uuid', 'policies.id is uuid');
SELECT col_type_is('public', 'policies', 'key', 'text', 'policies.key is text');
SELECT col_type_is('public', 'policies', 'value', 'jsonb', 'policies.value is jsonb');
SELECT col_type_is('public', 'policies', 'version', 'integer', 'policies.version is integer');
SELECT col_type_is('public', 'policies', 'effective_date', 'timestamp with time zone', 'policies.effective_date is timestamptz');
SELECT col_type_is('public', 'policies', 'description', 'text', 'policies.description is text');
SELECT col_type_is('public', 'policies', 'created_at', 'timestamp with time zone', 'policies.created_at is timestamptz');
SELECT has_index('public', 'policies', 'policies_key_effective_date_unique', 'UNIQUE(key, effective_date) index exists');
SELECT tests.rls_enabled('public', 'policies');

-- ============================================================
-- 2. Function existence
-- ============================================================
SELECT has_function('public', 'get_current_policy', 'get_current_policy function exists');

-- ============================================================
-- 3. RLS — anon (no auth): cannot read policies
-- ============================================================
SELECT tests.clear_authentication();

SELECT is_empty(
  $$SELECT * FROM public.policies$$,
  'anon cannot SELECT policies'
);

-- ============================================================
-- 4. RLS — authenticated: can SELECT, cannot write
-- ============================================================
SELECT tests.create_supabase_user('policy_test_user', 'policy_test@test.com');
SELECT tests.authenticate_as('policy_test_user');

SELECT results_eq(
  $$SELECT count(*)::int FROM public.policies WHERE key = 'refund'$$,
  $$VALUES (1)$$,
  'authenticated user can SELECT policies (sees seed data)'
);

SAVEPOINT before_blocked_insert;
SELECT throws_ok(
  $$INSERT INTO public.policies (key, value, version, effective_date)
    VALUES ('test_key', '{"test": true}'::jsonb, 1, now())$$,
  NULL,
  'authenticated user cannot INSERT policies'
);
ROLLBACK TO SAVEPOINT before_blocked_insert;

SELECT is_empty(
  $$UPDATE public.policies SET description = 'hacked' WHERE key = 'refund' RETURNING id$$,
  'authenticated user cannot UPDATE policies'
);

SELECT is_empty(
  $$DELETE FROM public.policies WHERE key = 'refund' RETURNING id$$,
  'authenticated user cannot DELETE policies'
);

-- ============================================================
-- 5. RLS — service_role: full access
-- ============================================================
SELECT tests.authenticate_as_service_role();

SELECT lives_ok(
  $$INSERT INTO public.policies (key, value, version, effective_date, description)
    VALUES ('test_policy', '{"tiers": []}'::jsonb, 1, '2026-06-01T00:00:00Z'::timestamptz, 'test')$$,
  'service_role can INSERT policies'
);

SELECT results_eq(
  $$SELECT count(*)::int FROM public.policies WHERE key = 'test_policy'$$,
  $$VALUES (1)$$,
  'service_role can SELECT inserted row'
);

SELECT lives_ok(
  $$UPDATE public.policies
      SET description = 'updated by service_role'
    WHERE key = 'test_policy'$$,
  'service_role can UPDATE policies'
);

SELECT lives_ok(
  $$DELETE FROM public.policies WHERE key = 'test_policy'$$,
  'service_role can DELETE policies'
);

-- ============================================================
-- 6. RPC — get_current_policy() behavior
-- ============================================================

-- Happy path: returns refund policy JSONB
SELECT isnt(
  public.get_current_policy('refund', '2026-03-16T00:00:00Z'::timestamptz),
  NULL,
  'get_current_policy returns non-null for existing key'
);

SELECT results_eq(
  $$SELECT jsonb_array_length(public.get_current_policy('refund', '2026-03-16T00:00:00Z'::timestamptz) -> 'tiers')$$,
  $$VALUES (4)$$,
  'refund policy has 4 tiers'
);

-- NULL for nonexistent key
SELECT is(
  public.get_current_policy('nonexistent_key', '2026-03-16T00:00:00Z'::timestamptz),
  NULL,
  'get_current_policy returns NULL for nonexistent key'
);

-- p_at before effective_date: seed is effective 2026-01-01, so 2025-12-31 should return NULL
SELECT is(
  public.get_current_policy('refund', '2025-12-31T23:59:59Z'::timestamptz),
  NULL,
  'get_current_policy returns NULL when p_at is before effective_date'
);

-- p_at exactly at effective_date: should return the policy
SELECT isnt(
  public.get_current_policy('refund', '2026-01-01T00:00:00Z'::timestamptz),
  NULL,
  'get_current_policy returns policy when p_at equals effective_date'
);

-- Multiple versions: newer effective_date wins
SELECT tests.authenticate_as_service_role();

INSERT INTO public.policies (key, value, version, effective_date, description)
VALUES (
  'refund',
  '{"tiers": [{"min_days_before": 7, "refund_percentage": 100}, {"min_days_before": 0, "refund_percentage": 0}]}'::jsonb,
  2,
  '2026-02-01T00:00:00Z'::timestamptz,
  'Updated refund policy v2 — 2 tier for testing'
);

SELECT results_eq(
  $$SELECT jsonb_array_length(public.get_current_policy('refund', '2026-03-16T00:00:00Z'::timestamptz) -> 'tiers')$$,
  $$VALUES (2)$$,
  'newer effective_date policy (v2, 2 tiers) is returned over older (v1, 4 tiers)'
);

SELECT results_eq(
  $$SELECT jsonb_array_length(public.get_current_policy('refund', '2026-01-15T00:00:00Z'::timestamptz) -> 'tiers')$$,
  $$VALUES (4)$$,
  'older effective_date policy (v1, 4 tiers) returned when p_at is before v2 effective_date'
);

SELECT * FROM finish();
ROLLBACK;
