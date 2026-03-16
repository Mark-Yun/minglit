-- Fix #108: Disambiguate partner_id/user_id in get_partner_members_with_user
--
-- The RETURNS TABLE clause declares partner_id and user_id as output columns,
-- which creates PL/pgSQL variables that clash with the unqualified column
-- references in the EXISTS subquery. Adding table alias resolves the ambiguity.

CREATE OR REPLACE FUNCTION public.get_partner_members_with_user(p_partner_id uuid)
RETURNS TABLE(
  user_id uuid, partner_id uuid, role text, permissions text[],
  joined_at timestamptz, user_name text, user_profile_image text
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF public.has_partner_permission(p_partner_id, 'MEMBER_MANAGE')
     OR EXISTS (
       SELECT 1 FROM public.partner_member_permissions pcheck
       WHERE pcheck.partner_id = p_partner_id AND pcheck.user_id = auth.uid()
     )
  THEN
    RETURN QUERY
      SELECT pmp.user_id, pmp.partner_id, pmp.role, pmp.permissions,
             pmp.joined_at, up.name, up.profile_image_url
      FROM public.partner_member_permissions pmp
      LEFT JOIN public.user_profiles up ON up.id = pmp.user_id
      WHERE pmp.partner_id = p_partner_id
      ORDER BY pmp.joined_at;
  END IF;
END;
$$;
