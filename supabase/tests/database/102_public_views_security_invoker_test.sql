BEGIN;

SELECT plan(19);

-- Runtime view contracts remain present.
SELECT has_view('public', 'locations_view', 'locations_view exists');
SELECT has_view('public', 'partner_revenue_stats', 'partner_revenue_stats exists');
SELECT has_view('public', 'partner_monthly_revenue', 'partner_monthly_revenue exists');
SELECT has_view('public', 'my_matches_view', 'my_matches_view exists');
SELECT has_view('public', 'settlement_metrics', 'settlement_metrics exists');

-- Security Advisor should no longer classify these views as SECURITY DEFINER.
SELECT ok(
  (
    SELECT coalesce(c.reloptions, ARRAY[]::text[]) @> ARRAY['security_invoker=true']
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public'
      AND c.relkind = 'v'
      AND c.relname = 'locations_view'
  ),
  'locations_view is security_invoker'
);

SELECT ok(
  (
    SELECT coalesce(c.reloptions, ARRAY[]::text[]) @> ARRAY['security_invoker=true']
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public'
      AND c.relkind = 'v'
      AND c.relname = 'partner_revenue_stats'
  ),
  'partner_revenue_stats is security_invoker'
);

SELECT ok(
  (
    SELECT coalesce(c.reloptions, ARRAY[]::text[]) @> ARRAY['security_invoker=true']
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public'
      AND c.relkind = 'v'
      AND c.relname = 'partner_monthly_revenue'
  ),
  'partner_monthly_revenue is security_invoker'
);

SELECT ok(
  (
    SELECT coalesce(c.reloptions, ARRAY[]::text[]) @> ARRAY['security_invoker=true']
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public'
      AND c.relkind = 'v'
      AND c.relname = 'my_matches_view'
  ),
  'my_matches_view is security_invoker'
);

SELECT ok(
  (
    SELECT coalesce(c.reloptions, ARRAY[]::text[]) @> ARRAY['security_invoker=true']
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public'
      AND c.relkind = 'v'
      AND c.relname = 'settlement_metrics'
  ),
  'settlement_metrics is security_invoker'
);

-- Existing external contracts remain granted to the expected roles.
SELECT ok(
  has_table_privilege('anon', 'public.locations_view', 'SELECT'),
  'anon keeps SELECT on locations_view'
);
SELECT ok(
  has_table_privilege('authenticated', 'public.locations_view', 'SELECT'),
  'authenticated keeps SELECT on locations_view'
);
SELECT ok(
  has_table_privilege('authenticated', 'public.partner_revenue_stats', 'SELECT'),
  'authenticated keeps SELECT on partner_revenue_stats'
);
SELECT ok(
  has_table_privilege('authenticated', 'public.partner_monthly_revenue', 'SELECT'),
  'authenticated keeps SELECT on partner_monthly_revenue'
);
SELECT ok(
  has_table_privilege('authenticated', 'public.my_matches_view', 'SELECT'),
  'authenticated keeps SELECT on my_matches_view'
);
SELECT ok(
  has_table_privilege('service_role', 'public.settlement_metrics', 'SELECT'),
  'service_role keeps SELECT on settlement_metrics'
);

-- Metabase residual views from the advisor artifact are not Minglit runtime
-- schema and should not remain exposed in public.
SELECT is(to_regclass('public.v_audit_log')::text, NULL::text, 'v_audit_log residual view is absent');
SELECT is(to_regclass('public.v_dashboardcard')::text, NULL::text, 'v_dashboardcard residual view is absent');
SELECT is(to_regclass('public.v_task_runs')::text, NULL::text, 'v_task_runs residual view is absent');

SELECT * FROM finish();
ROLLBACK;
