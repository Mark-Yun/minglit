-- Fix #2934: remove redundant auth.role() call from the service-role-only
-- notification insert RLS policy. The policy target already limits execution
-- to service_role, so the auth helper only triggers Performance Advisor
-- auth_rls_initplan without adding an access boundary.

DROP POLICY IF EXISTS "Service role can insert notifications"
  ON public.user_notifications;

CREATE POLICY "Service role can insert notifications"
  ON public.user_notifications
  FOR INSERT
  TO service_role
  WITH CHECK (true);
