-- Issue #2743: remove Security Advisor security_definer_view findings.
--
-- Postgres views run with the view owner's privileges by default. These
-- Minglit runtime views should evaluate with the invoking role so underlying
-- table grants and RLS remain authoritative.

ALTER VIEW public.locations_view SET (security_invoker = true);
ALTER VIEW public.partner_revenue_stats SET (security_invoker = true);
ALTER VIEW public.partner_monthly_revenue SET (security_invoker = true);
ALTER VIEW public.my_matches_view SET (security_invoker = true);
ALTER VIEW public.settlement_metrics SET (security_invoker = true);

-- The advisor artifact also listed three public v_* views from the same
-- Metabase residue family handled by #2742. They are not part of the Minglit
-- runtime schema and should not remain exposed in public.
DROP VIEW IF EXISTS
  public.v_audit_log,
  public.v_dashboardcard,
  public.v_task_runs;
