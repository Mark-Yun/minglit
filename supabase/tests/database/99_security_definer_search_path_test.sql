BEGIN;

SELECT plan(7);

-- Fix #1954: Verify all SECURITY DEFINER functions have SET search_path
-- to prevent schema injection attacks.
--
-- proconfig stores function-level SET options as text[] in pg_proc.
-- 'search_path=...' is present only when SET search_path is declared.

SELECT ok(
  (SELECT proconfig::text[] @> ARRAY['search_path=analytics, public']
   FROM pg_proc p
   JOIN pg_namespace n ON n.oid = p.pronamespace
   WHERE n.nspname = 'analytics' AND p.proname = 'aggregate_daily_active_users'),
  'aggregate_daily_active_users has SET search_path = analytics, public'
);

SELECT ok(
  (SELECT proconfig::text[] @> ARRAY['search_path=analytics, public']
   FROM pg_proc p
   JOIN pg_namespace n ON n.oid = p.pronamespace
   WHERE n.nspname = 'analytics' AND p.proname = 'aggregate_daily_events'),
  'aggregate_daily_events has SET search_path = analytics, public'
);

SELECT ok(
  (SELECT proconfig::text[] @> ARRAY['search_path=analytics, public']
   FROM pg_proc p
   JOIN pg_namespace n ON n.oid = p.pronamespace
   WHERE n.nspname = 'analytics' AND p.proname = 'aggregate_daily_revenue'),
  'aggregate_daily_revenue has SET search_path = analytics, public'
);

SELECT ok(
  (SELECT proconfig::text[] @> ARRAY['search_path=analytics, public']
   FROM pg_proc p
   JOIN pg_namespace n ON n.oid = p.pronamespace
   WHERE n.nspname = 'analytics' AND p.proname = 'aggregate_funnel_daily'),
  'aggregate_funnel_daily has SET search_path = analytics, public'
);

SELECT ok(
  (SELECT proconfig::text[] @> ARRAY['search_path=analytics, pgmq, public']
   FROM pg_proc p
   JOIN pg_namespace n ON n.oid = p.pronamespace
   WHERE n.nspname = 'analytics' AND p.proname = 'check_infra_alert'),
  'check_infra_alert has SET search_path = analytics, pgmq, public'
);

SELECT ok(
  (SELECT proconfig::text[] @> ARRAY['search_path=analytics, public']
   FROM pg_proc p
   JOIN pg_namespace n ON n.oid = p.pronamespace
   WHERE n.nspname = 'analytics' AND p.proname = 'send_weekly_report'),
  'send_weekly_report has SET search_path = analytics, public'
);

SELECT ok(
  (SELECT proconfig::text[] @> ARRAY['search_path=public']
   FROM pg_proc p
   JOIN pg_namespace n ON n.oid = p.pronamespace
   WHERE n.nspname = 'public' AND p.proname = 'replace_match_rules'),
  'replace_match_rules has SET search_path = public'
);

SELECT * FROM finish();
ROLLBACK;
