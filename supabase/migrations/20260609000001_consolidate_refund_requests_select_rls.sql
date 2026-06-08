-- Issue #3442: remove Supabase Performance Advisor
-- multiple_permissive_policies WARN for refund_requests SELECT access.

DROP POLICY IF EXISTS "Partner staff can read refund requests" ON public.refund_requests;
DROP POLICY IF EXISTS "Users can read own refund requests" ON public.refund_requests;

CREATE POLICY "Users can read own refund requests" ON public.refund_requests
  FOR SELECT TO authenticated
  USING (
    (SELECT auth.uid()) = user_id
    OR public.has_partner_permission(partner_id, 'PARTY_MANAGE')
  );
