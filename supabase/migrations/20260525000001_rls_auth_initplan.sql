-- Issue #2797: wrap RLS auth helper calls in scalar subqueries so Postgres
-- can evaluate them as initplans instead of per-row expressions.

-- service_role-only system/retention tables
DROP POLICY IF EXISTS "service_role_only" ON public.archived_records;
CREATE POLICY "service_role_only" ON public.archived_records
  FOR ALL USING ((SELECT auth.role()) = 'service_role');

DROP POLICY IF EXISTS "service_role_only" ON public.blocked_dis;
CREATE POLICY "service_role_only" ON public.blocked_dis
  FOR ALL USING ((SELECT auth.role()) = 'service_role');

DROP POLICY IF EXISTS "business_calendar_write_service_role" ON public.business_calendar;
CREATE POLICY "business_calendar_write_service_role"
  ON public.business_calendar FOR ALL
  USING ((SELECT auth.role()) = 'service_role');

DROP POLICY IF EXISTS "service_role_only" ON public.dead_letter_queue;
CREATE POLICY "service_role_only" ON public.dead_letter_queue
  FOR ALL USING ((SELECT auth.role()) = 'service_role');

DROP POLICY IF EXISTS "service_role_all" ON public.debug_logs;
CREATE POLICY "service_role_all" ON public.debug_logs
  FOR ALL
  USING ((SELECT auth.role()) = 'service_role')
  WITH CHECK ((SELECT auth.role()) = 'service_role');

DROP POLICY IF EXISTS "service_role_only" ON public.event_routes;
CREATE POLICY "service_role_only" ON public.event_routes
  FOR ALL USING ((SELECT auth.role()) = 'service_role');

DROP POLICY IF EXISTS "service_role_only" ON public.processed_events;
CREATE POLICY "service_role_only" ON public.processed_events
  FOR ALL USING ((SELECT auth.role()) = 'service_role');

DROP POLICY IF EXISTS "reconciliation_results_service_role_only" ON public.reconciliation_results;
CREATE POLICY "reconciliation_results_service_role_only"
  ON public.reconciliation_results
  USING ((SELECT auth.role()) = 'service_role');

DROP POLICY IF EXISTS "reconciliation_runs_service_role_only" ON public.reconciliation_runs;
CREATE POLICY "reconciliation_runs_service_role_only"
  ON public.reconciliation_runs
  USING ((SELECT auth.role()) = 'service_role');

DROP POLICY IF EXISTS "settlement_alarm_results_service_role_only" ON public.settlement_alarm_results;
CREATE POLICY "settlement_alarm_results_service_role_only"
  ON public.settlement_alarm_results
  USING ((SELECT auth.role()) = 'service_role');

DROP POLICY IF EXISTS "system_settings_service_role_only" ON public.system_settings;
CREATE POLICY "system_settings_service_role_only"
  ON public.system_settings
  USING ((SELECT auth.role()) = 'service_role');

DROP POLICY IF EXISTS "service_role_only" ON public.withdrawal_reasons;
CREATE POLICY "service_role_only" ON public.withdrawal_reasons
  FOR ALL USING ((SELECT auth.role()) = 'service_role');

-- User/application ownership policies
DROP POLICY IF EXISTS "Users can read own applications" ON public.event_applications;
CREATE POLICY "Users can read own applications" ON public.event_applications
  FOR SELECT
  USING ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can create own applications" ON public.event_applications;
CREATE POLICY "Users can create own applications" ON public.event_applications
  FOR INSERT
  WITH CHECK ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can update own applications" ON public.event_applications;
CREATE POLICY "Users can update own applications" ON public.event_applications
  FOR UPDATE
  USING ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "partner_read_own_event_change_logs" ON public.event_change_logs;
CREATE POLICY "partner_read_own_event_change_logs"
  ON public.event_change_logs
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.events e
      JOIN public.parties p ON p.id = e.party_id
      WHERE e.id = event_change_logs.event_id
        AND p.partner_id = (SELECT auth.uid())
    )
  );

DROP POLICY IF EXISTS "Authenticated users can read visible participants" ON public.event_participants;
CREATE POLICY "Authenticated users can read visible participants"
  ON public.event_participants
  FOR SELECT
  USING (
    (SELECT auth.role()) = 'authenticated'
    AND (
      (SELECT auth.uid()) = user_id
      OR public.is_visible_user_profile(user_id)
    )
  );

DROP POLICY IF EXISTS "Users can view their own FCM tokens" ON public.fcm_tokens;
CREATE POLICY "Users can view their own FCM tokens" ON public.fcm_tokens
  FOR SELECT
  USING ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Viewers can see their grants" ON public.file_access_grants;
CREATE POLICY "Viewers can see their grants" ON public.file_access_grants
  FOR SELECT
  USING (viewer_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "users read own logs" ON public.location_access_log;
CREATE POLICY "users read own logs"
  ON public.location_access_log
  FOR SELECT TO authenticated
  USING (user_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "Users can see own matches" ON public.match_pairs;
CREATE POLICY "Users can see own matches" ON public.match_pairs
  FOR SELECT
  USING ((SELECT auth.uid()) = user_lower_id OR (SELECT auth.uid()) = user_higher_id);

DROP POLICY IF EXISTS "Users can cast votes" ON public.match_votes;
CREATE POLICY "Users can cast votes" ON public.match_votes
  FOR INSERT
  WITH CHECK ((SELECT auth.uid()) = voter_id);

DROP POLICY IF EXISTS "Users can read own votes" ON public.match_votes;
CREATE POLICY "Users can read own votes" ON public.match_votes
  FOR SELECT
  USING ((SELECT auth.uid()) = voter_id);

DROP POLICY IF EXISTS "Users can view granted files" ON public.minglit_files;
CREATE POLICY "Users can view granted files" ON public.minglit_files
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.file_access_grants
      WHERE file_id = minglit_files.id
        AND viewer_id = (SELECT auth.uid())
        AND (expires_at IS NULL OR expires_at > now())
    )
  );

DROP POLICY IF EXISTS "Users can view own files" ON public.minglit_files;
CREATE POLICY "Users can view own files" ON public.minglit_files
  FOR SELECT
  USING ((SELECT auth.uid()) = owner_id);

DROP POLICY IF EXISTS "Users can read own applications" ON public.partner_applications;
CREATE POLICY "Users can read own applications" ON public.partner_applications
  FOR SELECT
  USING ((SELECT auth.uid()) = user_id OR public.is_super_admin());

DROP POLICY IF EXISTS "authenticated_can_apply" ON public.partner_applications;
CREATE POLICY "authenticated_can_apply" ON public.partner_applications
  FOR INSERT TO authenticated
  WITH CHECK ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can read own permissions" ON public.partner_member_permissions;
CREATE POLICY "Users can read own permissions" ON public.partner_member_permissions
  FOR SELECT
  USING (
    (SELECT auth.uid()) = user_id
    OR public.is_super_admin()
    OR public.has_partner_permission(partner_id, 'MEMBER_MANAGE')
  );

DROP POLICY IF EXISTS "Users can read own verified status" ON public.partner_verified_users;
CREATE POLICY "Users can read own verified status" ON public.partner_verified_users
  FOR SELECT
  USING ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can insert own reports" ON public.report_details;
CREATE POLICY "Users can insert own reports" ON public.report_details
  FOR INSERT TO authenticated
  WITH CHECK ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can view own reports" ON public.report_details;
CREATE POLICY "Users can view own reports" ON public.report_details
  FOR SELECT TO authenticated
  USING ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can manage own interactions" ON public.social_interactions;
CREATE POLICY "Users can manage own interactions" ON public.social_interactions
  FOR ALL
  USING ((SELECT auth.uid()) = user_id)
  WITH CHECK ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can view own interactions" ON public.social_interactions;
CREATE POLICY "Users can view own interactions" ON public.social_interactions
  FOR SELECT
  USING ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "user_read_own_consents" ON public.user_consents;
CREATE POLICY "user_read_own_consents" ON public.user_consents
  FOR SELECT TO authenticated
  USING ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "user_interest_tags_read_own" ON public.user_interest_tags;
CREATE POLICY "user_interest_tags_read_own" ON public.user_interest_tags
  FOR SELECT
  USING ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can update their own notifications" ON public.user_notifications;
CREATE POLICY "Users can update their own notifications" ON public.user_notifications
  FOR UPDATE
  USING ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can view their own notifications" ON public.user_notifications;
CREATE POLICY "Users can view their own notifications" ON public.user_notifications
  FOR SELECT
  USING ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can read own profile" ON public.user_profiles;
CREATE POLICY "Users can read own profile" ON public.user_profiles
  FOR SELECT
  USING ((SELECT auth.uid()) = id);

DROP POLICY IF EXISTS "Users can update own profile" ON public.user_profiles;
CREATE POLICY "Users can update own profile" ON public.user_profiles
  FOR UPDATE
  USING ((SELECT auth.uid()) = id);

DROP POLICY IF EXISTS "Users can view their own settings" ON public.user_settings;
CREATE POLICY "Users can view their own settings" ON public.user_settings
  FOR SELECT
  USING ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can read own verifications" ON public.user_verifications;
CREATE POLICY "Users can read own verifications" ON public.user_verifications
  FOR SELECT
  USING ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can create own submissions" ON public.verification_submissions;
CREATE POLICY "Users can create own submissions" ON public.verification_submissions
  FOR INSERT
  WITH CHECK ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can read own submissions" ON public.verification_submissions;
CREATE POLICY "Users can read own submissions" ON public.verification_submissions
  FOR SELECT
  USING ((SELECT auth.uid()) = user_id);

-- Policy store and tag usage service policies
DROP POLICY IF EXISTS "authenticated_read_policies" ON public.policies;
CREATE POLICY "authenticated_read_policies" ON public.policies
  FOR SELECT
  USING ((SELECT auth.uid()) IS NOT NULL);

DROP POLICY IF EXISTS "service_role_all_policies" ON public.policies;
CREATE POLICY "service_role_all_policies" ON public.policies
  FOR ALL
  USING ((SELECT auth.role()) = 'service_role');

DROP POLICY IF EXISTS party_tags_service ON public.party_tags;
CREATE POLICY party_tags_service ON public.party_tags
  FOR ALL
  USING ((SELECT auth.role()) = 'service_role');

DROP POLICY IF EXISTS tag_usage_daily_service ON public.tag_usage_daily;
CREATE POLICY tag_usage_daily_service ON public.tag_usage_daily
  FOR ALL
  USING ((SELECT auth.role()) = 'service_role');

DROP POLICY IF EXISTS tag_usage_monthly_service ON public.tag_usage_monthly;
CREATE POLICY tag_usage_monthly_service ON public.tag_usage_monthly
  FOR ALL
  USING ((SELECT auth.role()) = 'service_role');
