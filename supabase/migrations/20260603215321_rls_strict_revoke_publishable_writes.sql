-- Issue #2991: strict publishable-key write lockdown.
-- Flutter clients are read-only; all writes must go through Edge Functions
-- using service_role.

set search_path to public, extensions;

-- Preserve explicit service_role-only write policies while removing their
-- implicit PUBLIC role target from pg_policies advisor/gate scope.
ALTER POLICY "service_role_only" ON public.archived_records TO service_role;
ALTER POLICY "service_role_only" ON public.blocked_dis TO service_role;
ALTER POLICY "service_role_only" ON public.dead_letter_queue TO service_role;
ALTER POLICY "service_role_all" ON public.debug_logs TO service_role;
ALTER POLICY "service_role_only" ON public.event_routes TO service_role;
ALTER POLICY "service_role_only" ON public.processed_events TO service_role;
ALTER POLICY "reconciliation_results_service_role_only" ON public.reconciliation_results TO service_role;
ALTER POLICY "reconciliation_runs_service_role_only" ON public.reconciliation_runs TO service_role;
ALTER POLICY "settlement_alarm_results_service_role_only" ON public.settlement_alarm_results TO service_role;
ALTER POLICY "system_settings_service_role_only" ON public.system_settings TO service_role;
ALTER POLICY "service_role_only" ON public.withdrawal_reasons TO service_role;
ALTER POLICY "Service role can insert notifications" ON public.user_notifications TO service_role;

-- Drop any remaining public/anon/authenticated write policy in public schema.
-- This intentionally turns the publishable-key DB surface into read-only even
-- for formerly self-owned or partner-admin rows; those writes now live behind
-- Edge Functions.
DO $$
DECLARE
  target_policy record;
BEGIN
  FOR target_policy IN
    SELECT schemaname, tablename, policyname
    FROM pg_policies
    WHERE schemaname = 'public'
      AND cmd IN ('INSERT', 'UPDATE', 'DELETE', 'ALL')
      AND roles && ARRAY['public', 'anon', 'authenticated']::name[]
  LOOP
    EXECUTE format(
      'DROP POLICY IF EXISTS %I ON %I.%I',
      target_policy.policyname,
      target_policy.schemaname,
      target_policy.tablename
    );
  END LOOP;
END $$;

REVOKE INSERT, UPDATE, DELETE, TRUNCATE
  ON ALL TABLES IN SCHEMA public
  FROM anon, authenticated;

-- SECURITY DEFINER write RPCs bypass table-level GRANT/RLS, so they must not
-- remain directly executable through publishable-key roles.
DO $$
DECLARE
  target_function record;
BEGIN
  FOR target_function IN
    SELECT
      n.nspname AS schema_name,
      p.proname AS function_name,
      pg_get_function_identity_arguments(p.oid) AS identity_arguments
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public'
      AND p.prokind = 'f'
      AND p.prosecdef
      AND p.prosrc ~* (
        '(^|[^[:alnum:]_])(' ||
        'insert[[:space:]]+into|' ||
        'update[[:space:]]+[[:alnum:]_".]+[[:space:]]+set|' ||
        'delete[[:space:]]+from|' ||
        'truncate[[:space:]]+table|' ||
        'merge[[:space:]]+into' ||
        ')'
      )
  LOOP
    EXECUTE format(
      'REVOKE EXECUTE ON FUNCTION %I.%I(%s) FROM PUBLIC, anon, authenticated',
      target_function.schema_name,
      target_function.function_name,
      target_function.identity_arguments
    );

    EXECUTE format(
      'GRANT EXECUTE ON FUNCTION %I.%I(%s) TO service_role',
      target_function.schema_name,
      target_function.function_name,
      target_function.identity_arguments
    );
  END LOOP;
END $$;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
  REVOKE INSERT, UPDATE, DELETE, TRUNCATE
  ON TABLES
  FROM anon, authenticated;

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public
  REVOKE INSERT, UPDATE, DELETE, TRUNCATE
  ON TABLES
  FROM anon, authenticated;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
  REVOKE EXECUTE
  ON FUNCTIONS
  FROM PUBLIC, anon, authenticated;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT EXECUTE
  ON FUNCTIONS
  TO service_role;

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public
  REVOKE EXECUTE
  ON FUNCTIONS
  FROM PUBLIC, anon, authenticated;

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public
  GRANT EXECUTE
  ON FUNCTIONS
  TO service_role;
