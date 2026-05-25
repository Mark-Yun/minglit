-- Issue #2798: consolidate overlapping permissive SELECT RLS policies reported
-- by Supabase Performance Advisor while preserving existing access semantics.

set search_path to public, extensions;

-- ============================================================
-- Public read + admin/owner write policies
-- ============================================================

DROP POLICY IF EXISTS "Admin/Owner partners all access" ON public.partners;
CREATE POLICY "Admin/Owner partners insert access" ON public.partners
  FOR INSERT TO authenticated
  WITH CHECK (public.is_super_admin() OR public.has_partner_permission(id, 'PARTNER_EDIT'));
CREATE POLICY "Admin/Owner partners update access" ON public.partners
  FOR UPDATE TO authenticated
  USING (public.is_super_admin() OR public.has_partner_permission(id, 'PARTNER_EDIT'))
  WITH CHECK (public.is_super_admin() OR public.has_partner_permission(id, 'PARTNER_EDIT'));
CREATE POLICY "Admin/Owner partners delete access" ON public.partners
  FOR DELETE TO authenticated
  USING (public.is_super_admin() OR public.has_partner_permission(id, 'PARTNER_EDIT'));

DROP POLICY IF EXISTS "Admin/Owner locations all access" ON public.locations;
CREATE POLICY "Admin/Owner locations insert access" ON public.locations
  FOR INSERT TO authenticated
  WITH CHECK (public.is_super_admin() OR public.has_partner_permission(partner_id, 'PARTY_MANAGE'));
CREATE POLICY "Admin/Owner locations update access" ON public.locations
  FOR UPDATE TO authenticated
  USING (public.is_super_admin() OR public.has_partner_permission(partner_id, 'PARTY_MANAGE'))
  WITH CHECK (public.is_super_admin() OR public.has_partner_permission(partner_id, 'PARTY_MANAGE'));
CREATE POLICY "Admin/Owner locations delete access" ON public.locations
  FOR DELETE TO authenticated
  USING (public.is_super_admin() OR public.has_partner_permission(partner_id, 'PARTY_MANAGE'));

DROP POLICY IF EXISTS "Admin/Owner verifications all access" ON public.verifications;
CREATE POLICY "Admin/Owner verifications insert access" ON public.verifications
  FOR INSERT TO authenticated
  WITH CHECK (
    public.is_super_admin() OR
    (partner_id IS NOT NULL AND public.has_partner_permission(partner_id, 'PARTNER_EDIT'))
  );
CREATE POLICY "Admin/Owner verifications update access" ON public.verifications
  FOR UPDATE TO authenticated
  USING (
    public.is_super_admin() OR
    (partner_id IS NOT NULL AND public.has_partner_permission(partner_id, 'PARTNER_EDIT'))
  )
  WITH CHECK (
    public.is_super_admin() OR
    (partner_id IS NOT NULL AND public.has_partner_permission(partner_id, 'PARTNER_EDIT'))
  );
CREATE POLICY "Admin/Owner verifications delete access" ON public.verifications
  FOR DELETE TO authenticated
  USING (
    public.is_super_admin() OR
    (partner_id IS NOT NULL AND public.has_partner_permission(partner_id, 'PARTNER_EDIT'))
  );

DROP POLICY IF EXISTS "Admin/Owner parties all access" ON public.parties;
CREATE POLICY "Admin/Owner parties insert access" ON public.parties
  FOR INSERT TO authenticated
  WITH CHECK (public.is_super_admin() OR public.has_partner_permission(partner_id, 'PARTY_MANAGE'));
CREATE POLICY "Admin/Owner parties update access" ON public.parties
  FOR UPDATE TO authenticated
  USING (public.is_super_admin() OR public.has_partner_permission(partner_id, 'PARTY_MANAGE'))
  WITH CHECK (public.is_super_admin() OR public.has_partner_permission(partner_id, 'PARTY_MANAGE'));
CREATE POLICY "Admin/Owner parties delete access" ON public.parties
  FOR DELETE TO authenticated
  USING (public.is_super_admin() OR public.has_partner_permission(partner_id, 'PARTY_MANAGE'));

DROP POLICY IF EXISTS "Admin/Owner events all access" ON public.events;
CREATE POLICY "Admin/Owner events insert access" ON public.events
  FOR INSERT TO authenticated
  WITH CHECK (
    public.is_super_admin() OR
    EXISTS (
      SELECT 1 FROM public.parties p
      WHERE p.id = party_id
        AND public.has_partner_permission(p.partner_id, 'PARTY_MANAGE')
    )
  );
CREATE POLICY "Admin/Owner events update access" ON public.events
  FOR UPDATE TO authenticated
  USING (
    public.is_super_admin() OR
    EXISTS (
      SELECT 1 FROM public.parties p
      WHERE p.id = party_id
        AND public.has_partner_permission(p.partner_id, 'PARTY_MANAGE')
    )
  )
  WITH CHECK (
    public.is_super_admin() OR
    EXISTS (
      SELECT 1 FROM public.parties p
      WHERE p.id = party_id
        AND public.has_partner_permission(p.partner_id, 'PARTY_MANAGE')
    )
  );
CREATE POLICY "Admin/Owner events delete access" ON public.events
  FOR DELETE TO authenticated
  USING (
    public.is_super_admin() OR
    EXISTS (
      SELECT 1 FROM public.parties p
      WHERE p.id = party_id
        AND public.has_partner_permission(p.partner_id, 'PARTY_MANAGE')
    )
  );

DROP POLICY IF EXISTS "Admin/Owner entry_group_templates all access" ON public.entry_group_templates;
CREATE POLICY "Admin/Owner entry_group_templates insert access" ON public.entry_group_templates
  FOR INSERT TO authenticated
  WITH CHECK (
    public.is_super_admin() OR
    EXISTS (
      SELECT 1 FROM public.parties p
      WHERE p.id = party_id
        AND public.has_partner_permission(p.partner_id, 'PARTY_MANAGE')
    )
  );
CREATE POLICY "Admin/Owner entry_group_templates update access" ON public.entry_group_templates
  FOR UPDATE TO authenticated
  USING (
    public.is_super_admin() OR
    EXISTS (
      SELECT 1 FROM public.parties p
      WHERE p.id = party_id
        AND public.has_partner_permission(p.partner_id, 'PARTY_MANAGE')
    )
  )
  WITH CHECK (
    public.is_super_admin() OR
    EXISTS (
      SELECT 1 FROM public.parties p
      WHERE p.id = party_id
        AND public.has_partner_permission(p.partner_id, 'PARTY_MANAGE')
    )
  );
CREATE POLICY "Admin/Owner entry_group_templates delete access" ON public.entry_group_templates
  FOR DELETE TO authenticated
  USING (
    public.is_super_admin() OR
    EXISTS (
      SELECT 1 FROM public.parties p
      WHERE p.id = party_id
        AND public.has_partner_permission(p.partner_id, 'PARTY_MANAGE')
    )
  );

DROP POLICY IF EXISTS "Admin/Owner entry_groups all access" ON public.entry_groups;
CREATE POLICY "Admin/Owner entry_groups insert access" ON public.entry_groups
  FOR INSERT TO authenticated
  WITH CHECK (
    public.is_super_admin() OR
    EXISTS (
      SELECT 1 FROM public.events e
      JOIN public.parties p ON p.id = e.party_id
      WHERE e.id = event_id
        AND public.has_partner_permission(p.partner_id, 'PARTY_MANAGE')
    )
  );
CREATE POLICY "Admin/Owner entry_groups update access" ON public.entry_groups
  FOR UPDATE TO authenticated
  USING (
    public.is_super_admin() OR
    EXISTS (
      SELECT 1 FROM public.events e
      JOIN public.parties p ON p.id = e.party_id
      WHERE e.id = event_id
        AND public.has_partner_permission(p.partner_id, 'PARTY_MANAGE')
    )
  )
  WITH CHECK (
    public.is_super_admin() OR
    EXISTS (
      SELECT 1 FROM public.events e
      JOIN public.parties p ON p.id = e.party_id
      WHERE e.id = event_id
        AND public.has_partner_permission(p.partner_id, 'PARTY_MANAGE')
    )
  );
CREATE POLICY "Admin/Owner entry_groups delete access" ON public.entry_groups
  FOR DELETE TO authenticated
  USING (
    public.is_super_admin() OR
    EXISTS (
      SELECT 1 FROM public.events e
      JOIN public.parties p ON p.id = e.party_id
      WHERE e.id = event_id
        AND public.has_partner_permission(p.partner_id, 'PARTY_MANAGE')
    )
  );

DROP POLICY IF EXISTS "Admin/Owner ticket_templates all access" ON public.ticket_templates;
CREATE POLICY "Admin/Owner ticket_templates insert access" ON public.ticket_templates
  FOR INSERT TO authenticated
  WITH CHECK (
    public.is_super_admin() OR
    EXISTS (
      SELECT 1 FROM public.parties p
      WHERE p.id = party_id
        AND public.has_partner_permission(p.partner_id, 'PARTY_MANAGE')
    )
  );
CREATE POLICY "Admin/Owner ticket_templates update access" ON public.ticket_templates
  FOR UPDATE TO authenticated
  USING (
    public.is_super_admin() OR
    EXISTS (
      SELECT 1 FROM public.parties p
      WHERE p.id = party_id
        AND public.has_partner_permission(p.partner_id, 'PARTY_MANAGE')
    )
  )
  WITH CHECK (
    public.is_super_admin() OR
    EXISTS (
      SELECT 1 FROM public.parties p
      WHERE p.id = party_id
        AND public.has_partner_permission(p.partner_id, 'PARTY_MANAGE')
    )
  );
CREATE POLICY "Admin/Owner ticket_templates delete access" ON public.ticket_templates
  FOR DELETE TO authenticated
  USING (
    public.is_super_admin() OR
    EXISTS (
      SELECT 1 FROM public.parties p
      WHERE p.id = party_id
        AND public.has_partner_permission(p.partner_id, 'PARTY_MANAGE')
    )
  );

DROP POLICY IF EXISTS "Admin/Owner tickets all access" ON public.tickets;
CREATE POLICY "Admin/Owner tickets insert access" ON public.tickets
  FOR INSERT TO authenticated
  WITH CHECK (
    public.is_super_admin() OR
    EXISTS (
      SELECT 1 FROM public.events e
      JOIN public.parties p ON p.id = e.party_id
      WHERE e.id = event_id
        AND public.has_partner_permission(p.partner_id, 'PARTY_MANAGE')
    )
  );
CREATE POLICY "Admin/Owner tickets update access" ON public.tickets
  FOR UPDATE TO authenticated
  USING (
    public.is_super_admin() OR
    EXISTS (
      SELECT 1 FROM public.events e
      JOIN public.parties p ON p.id = e.party_id
      WHERE e.id = event_id
        AND public.has_partner_permission(p.partner_id, 'PARTY_MANAGE')
    )
  )
  WITH CHECK (
    public.is_super_admin() OR
    EXISTS (
      SELECT 1 FROM public.events e
      JOIN public.parties p ON p.id = e.party_id
      WHERE e.id = event_id
        AND public.has_partner_permission(p.partner_id, 'PARTY_MANAGE')
    )
  );
CREATE POLICY "Admin/Owner tickets delete access" ON public.tickets
  FOR DELETE TO authenticated
  USING (
    public.is_super_admin() OR
    EXISTS (
      SELECT 1 FROM public.events e
      JOIN public.parties p ON p.id = e.party_id
      WHERE e.id = event_id
        AND public.has_partner_permission(p.partner_id, 'PARTY_MANAGE')
    )
  );

-- ============================================================
-- Merge overlapping SELECT predicates
-- ============================================================

DROP POLICY IF EXISTS "Partner staff can view applications" ON public.event_applications;
DROP POLICY IF EXISTS "Users can read own applications" ON public.event_applications;
CREATE POLICY "Users can read own applications" ON public.event_applications
  FOR SELECT TO authenticated
  USING (
    (SELECT auth.uid()) = user_id OR
    EXISTS (
      SELECT 1 FROM public.events e
      JOIN public.parties p ON p.id = e.party_id
      WHERE e.id = event_id
        AND public.has_partner_permission(p.partner_id, 'PARTY_MANAGE')
    )
  );

DROP POLICY IF EXISTS "Partner staff can view submissions" ON public.verification_submissions;
DROP POLICY IF EXISTS "Users can read own submissions" ON public.verification_submissions;
CREATE POLICY "Users can read own submissions" ON public.verification_submissions
  FOR SELECT TO authenticated
  USING (
    (SELECT auth.uid()) = user_id OR
    public.has_partner_permission(partner_id, 'VERIFY_LIST_VIEW')
  );

DROP POLICY IF EXISTS "Partners can read applicant profiles" ON public.user_profiles;
DROP POLICY IF EXISTS "Users can read own profile" ON public.user_profiles;
CREATE POLICY "Users can read own profile" ON public.user_profiles
  FOR SELECT TO authenticated
  USING (
    (SELECT auth.uid()) = id OR
    EXISTS (
      SELECT 1 FROM public.event_applications ea
      JOIN public.events e ON e.id = ea.event_id
      JOIN public.parties p ON p.id = e.party_id
      WHERE ea.user_id = user_profiles.id
        AND public.has_partner_permission(p.partner_id, 'PARTY_MANAGE')
    )
  );

DROP POLICY IF EXISTS "Users can view granted files" ON public.minglit_files;
DROP POLICY IF EXISTS "Users can view own files" ON public.minglit_files;
CREATE POLICY "Users can view own files" ON public.minglit_files
  FOR SELECT TO authenticated
  USING (
    (SELECT auth.uid()) = owner_id OR
    EXISTS (
      SELECT 1 FROM public.file_access_grants
      WHERE file_id = minglit_files.id
        AND viewer_id = (SELECT auth.uid())
        AND (expires_at IS NULL OR expires_at > now())
    )
  );

-- ============================================================
-- Self-management write policy split
-- ============================================================

DROP POLICY IF EXISTS "Users can manage own interactions" ON public.social_interactions;
CREATE POLICY "Users can create own interactions" ON public.social_interactions
  FOR INSERT TO authenticated
  WITH CHECK ((SELECT auth.uid()) = user_id);
CREATE POLICY "Users can update own interactions" ON public.social_interactions
  FOR UPDATE TO authenticated
  USING ((SELECT auth.uid()) = user_id)
  WITH CHECK ((SELECT auth.uid()) = user_id);
CREATE POLICY "Users can delete own interactions" ON public.social_interactions
  FOR DELETE TO authenticated
  USING ((SELECT auth.uid()) = user_id);

-- ============================================================
-- Service-role/read policy role targeting
-- ============================================================

DROP POLICY IF EXISTS "business_calendar_select_all" ON public.business_calendar;
CREATE POLICY "business_calendar_select_all" ON public.business_calendar
  FOR SELECT TO anon, authenticated
  USING (true);

DROP POLICY IF EXISTS "business_calendar_write_service_role" ON public.business_calendar;
CREATE POLICY "business_calendar_write_service_role" ON public.business_calendar
  FOR ALL TO service_role
  USING ((SELECT auth.role()) = 'service_role')
  WITH CHECK ((SELECT auth.role()) = 'service_role');

DROP POLICY IF EXISTS "authenticated_read_policies" ON public.policies;
CREATE POLICY "authenticated_read_policies" ON public.policies
  FOR SELECT TO authenticated
  USING ((SELECT auth.uid()) IS NOT NULL);

DROP POLICY IF EXISTS "service_role_all_policies" ON public.policies;
CREATE POLICY "service_role_all_policies" ON public.policies
  FOR ALL TO service_role
  USING ((SELECT auth.role()) = 'service_role')
  WITH CHECK ((SELECT auth.role()) = 'service_role');

DROP POLICY IF EXISTS party_tags_service ON public.party_tags;
CREATE POLICY party_tags_service ON public.party_tags
  FOR ALL TO service_role
  USING ((SELECT auth.role()) = 'service_role')
  WITH CHECK ((SELECT auth.role()) = 'service_role');

DROP POLICY IF EXISTS tag_usage_daily_service ON public.tag_usage_daily;
CREATE POLICY tag_usage_daily_service ON public.tag_usage_daily
  FOR ALL TO service_role
  USING ((SELECT auth.role()) = 'service_role')
  WITH CHECK ((SELECT auth.role()) = 'service_role');

DROP POLICY IF EXISTS tag_usage_monthly_service ON public.tag_usage_monthly;
CREATE POLICY tag_usage_monthly_service ON public.tag_usage_monthly
  FOR ALL TO service_role
  USING ((SELECT auth.role()) = 'service_role')
  WITH CHECK ((SELECT auth.role()) = 'service_role');
