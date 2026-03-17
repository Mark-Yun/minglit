BEGIN;
SELECT plan(8);

SELECT tests.authenticate_as_service_role();

-- ============================================================
-- 1. analytics schema exists
-- ============================================================
SELECT has_schema('analytics', 'analytics schema exists');

-- ============================================================
-- 2. analytics_reader role exists
-- ============================================================
SELECT has_role('analytics_reader', 'analytics_reader role exists');

-- ============================================================
-- 3. Aggregation tables exist
-- ============================================================
SELECT has_table('analytics', 'daily_active_users', 'daily_active_users table exists');
SELECT has_table('analytics', 'daily_events', 'daily_events table exists');
SELECT has_table('analytics', 'daily_revenue', 'daily_revenue table exists');
SELECT has_table('analytics', 'funnel_daily', 'funnel_daily table exists');

-- ============================================================
-- 4. analytics_reader can SELECT from analytics tables
-- ============================================================
SELECT ok(
  has_table_privilege('analytics_reader', 'analytics.daily_active_users', 'SELECT'),
  'analytics_reader can SELECT from daily_active_users'
);

-- ============================================================
-- 5. analytics_reader cannot SELECT from public.user_profiles
-- ============================================================
SELECT ok(
  NOT has_table_privilege('analytics_reader', 'public.user_profiles', 'SELECT'),
  'analytics_reader cannot SELECT from public.user_profiles'
);

SELECT * FROM finish();
ROLLBACK;
