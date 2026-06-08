-- Issue #3424: close anon direct RPC access to RLS predicate helpers.
--
-- These helpers are still used by authenticated RLS policies and backend
-- service_role paths, so keep those grants explicit while removing the default
-- PUBLIC/anon execute surface reported by Supabase Security Advisor.

DO $$
DECLARE
  target_policy record;
BEGIN
  FOR target_policy IN
    SELECT schemaname, tablename, policyname
    FROM pg_policies
    WHERE schemaname IN ('public', 'storage')
      AND roles && ARRAY['public', 'anon']::name[]
      AND (
        coalesce(qual, '') || ' ' || coalesce(with_check, '')
      ) ~ '(^|[^[:alnum:]_])((public\.)?(has_partner_permission|is_super_admin|is_visible_user_profile))\('
  LOOP
    EXECUTE format(
      'ALTER POLICY %I ON %I.%I TO authenticated',
      target_policy.policyname,
      target_policy.schemaname,
      target_policy.tablename
    );
  END LOOP;
END $$;

REVOKE EXECUTE ON FUNCTION public.has_partner_permission(uuid, text)
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.has_partner_permission(uuid, text)
  TO authenticated, service_role;

REVOKE EXECUTE ON FUNCTION public.is_super_admin()
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.is_super_admin()
  TO authenticated, service_role;

REVOKE EXECUTE ON FUNCTION public.is_visible_user_profile(uuid)
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.is_visible_user_profile(uuid)
  TO authenticated, service_role;
