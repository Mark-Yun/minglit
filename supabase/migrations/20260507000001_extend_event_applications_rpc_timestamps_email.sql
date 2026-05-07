-- Fix #2272: extend get_event_applications_with_user to surface paid_at,
-- refunded_at, and user_email so the Flutter client can:
--   1. Sort 승인됨/거절됨/환불 tabs by terminal timestamp (most recent first)
--   2. Display relative date in card trailing ("결제 N일 전", "N일 전")
--   3. Show masked email in 환불 tab instead of masked name (avoids
--      same-surname collisions like "김***" appearing for multiple applicants)
--
-- DROP + CREATE required: PostgreSQL's CREATE OR REPLACE cannot change
-- the return type (SQLSTATE 42P13). Must drop the old signature first.
DROP FUNCTION IF EXISTS public.get_event_applications_with_user(uuid);
CREATE FUNCTION public.get_event_applications_with_user(p_event_id uuid)
RETURNS TABLE(
  application_id uuid, event_id uuid, ticket_id uuid, user_id uuid,
  payment_id text, payment_amount int, status text,
  created_at timestamptz, updated_at timestamptz,
  paid_at timestamptz, refunded_at timestamptz,
  user_name text, user_phone text, user_email text,
  ticket_name text, ticket_created_at timestamptz, ticket_updated_at timestamptz,
  target_entry_group_ids uuid[]
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM public.events e
    JOIN public.parties p ON p.id = e.party_id
    WHERE e.id = p_event_id
      AND public.has_partner_permission(p.partner_id, 'PARTY_MANAGE')
  ) THEN
    RETURN QUERY
      SELECT ea.id, ea.event_id, ea.ticket_id, ea.user_id,
             ea.payment_id, ea.payment_amount, ea.status,
             ea.created_at, ea.updated_at,
             ea.paid_at, ea.refunded_at,
             up.name, up.phone_number, au.email::text,
             t.name, t.created_at, t.updated_at,
             COALESCE(t.target_entry_group_ids, ARRAY[]::uuid[])
      FROM public.event_applications ea
      LEFT JOIN public.user_profiles up ON up.id = ea.user_id
      LEFT JOIN auth.users au ON au.id = ea.user_id
      LEFT JOIN public.tickets t ON t.id = ea.ticket_id
      WHERE ea.event_id = p_event_id
      ORDER BY ea.created_at DESC;
  END IF;
END;
$$;

-- Fix #2272: DROP FUNCTION removes all existing GRANTs — must re-apply.
-- Original grant was in 20260301000007_07_rls_grants.sql line 427.
GRANT EXECUTE ON FUNCTION public.get_event_applications_with_user(uuid)
  TO authenticated;
