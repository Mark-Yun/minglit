-- Issue #2995: residual DB hardening after the initial RLS strict work.
--
-- Keep publishable-key callers read-only for notification settings storage and
-- remove direct client EXECUTE from SECURITY DEFINER functions that are owned
-- by Edge Functions, cron jobs, or triggers.

-- user-manage-settings is the write path for both tables. Clients may read
-- their own settings/tokens through RLS, but writes go through service_role EF.
REVOKE ALL ON public.fcm_tokens FROM anon, authenticated;
GRANT SELECT ON public.fcm_tokens TO authenticated;

DROP POLICY IF EXISTS "Users can view their own FCM tokens" ON public.fcm_tokens;
CREATE POLICY "Users can view their own FCM tokens"
  ON public.fcm_tokens
  FOR SELECT
  TO authenticated
  USING ((SELECT auth.uid()) = user_id);

REVOKE ALL ON public.user_settings FROM anon, authenticated;
GRANT SELECT ON public.user_settings TO authenticated;

DROP POLICY IF EXISTS "Users can view their own settings" ON public.user_settings;
CREATE POLICY "Users can view their own settings"
  ON public.user_settings
  FOR SELECT
  TO authenticated
  USING ((SELECT auth.uid()) = user_id);

-- Authenticated client RPCs. Revoke the default PUBLIC/anon execute surface and
-- re-grant only the roles that actually call them.
REVOKE EXECUTE ON FUNCTION public.get_bulk_eligibility_data(uuid)
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_bulk_eligibility_data(uuid)
  TO authenticated, service_role;

REVOKE EXECUTE ON FUNCTION public.get_personalized_recommendations(uuid, integer)
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_personalized_recommendations(uuid, integer)
  TO authenticated, service_role;

REVOKE EXECUTE ON FUNCTION public.get_matched_user_contact(uuid, uuid)
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_matched_user_contact(uuid, uuid)
  TO authenticated, service_role;

REVOKE EXECUTE ON FUNCTION public.get_matched_user_info(uuid, uuid)
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_matched_user_info(uuid, uuid)
  TO authenticated, service_role;

REVOKE EXECUTE ON FUNCTION public.get_event_applications_with_user(uuid)
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_event_applications_with_user(uuid)
  TO authenticated, service_role;

REVOKE EXECUTE ON FUNCTION public.get_partner_members_with_user(uuid)
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_partner_members_with_user(uuid)
  TO authenticated, service_role;

REVOKE EXECUTE ON FUNCTION public.get_pending_verification_requests_with_user(uuid)
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_pending_verification_requests_with_user(uuid)
  TO authenticated, service_role;

REVOKE EXECUTE ON FUNCTION public.get_event_checkin_stats(uuid)
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_event_checkin_stats(uuid)
  TO authenticated, service_role;

REVOKE EXECUTE ON FUNCTION public.get_event_checkin_stats_by_group(uuid)
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_event_checkin_stats_by_group(uuid)
  TO authenticated, service_role;

REVOKE EXECUTE ON FUNCTION public.get_event_participants_for_checkin(uuid)
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_event_participants_for_checkin(uuid)
  TO authenticated, service_role;

REVOKE EXECUTE ON FUNCTION public.process_manual_checkin(uuid, uuid)
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.process_manual_checkin(uuid, uuid)
  TO authenticated, service_role;

REVOKE EXECUTE ON FUNCTION public.process_qr_checkin(uuid, uuid, uuid)
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.process_qr_checkin(uuid, uuid, uuid)
  TO authenticated, service_role;

REVOKE EXECUTE ON FUNCTION public.get_ticket_public_key()
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_ticket_public_key()
  TO authenticated, service_role;

REVOKE EXECUTE ON FUNCTION public.request_retry_payout(uuid, uuid)
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.request_retry_payout(uuid, uuid)
  TO authenticated, service_role;

REVOKE EXECUTE ON FUNCTION public.save_user_consents(uuid, jsonb)
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.save_user_consents(uuid, jsonb)
  TO authenticated, service_role;

REVOKE EXECUTE ON FUNCTION public.set_social_interaction(text, text, text, boolean)
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.set_social_interaction(text, text, text, boolean)
  TO authenticated, service_role;

-- Edge Function, cron, and trigger internals. Trigger execution does not depend
-- on client-role EXECUTE privileges; direct RPC access should stay closed.
REVOKE EXECUTE ON FUNCTION admin.log_retention_policy_change()
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION admin.log_retention_policy_change()
  TO service_role;

REVOKE EXECUTE ON FUNCTION analytics.aggregate_daily_active_users(date)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION analytics.aggregate_daily_active_users(date)
  TO service_role;

REVOKE EXECUTE ON FUNCTION analytics.aggregate_daily_events(date)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION analytics.aggregate_daily_events(date)
  TO service_role;

REVOKE EXECUTE ON FUNCTION analytics.aggregate_daily_revenue(date)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION analytics.aggregate_daily_revenue(date)
  TO service_role;

REVOKE EXECUTE ON FUNCTION analytics.aggregate_funnel_daily(date)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION analytics.aggregate_funnel_daily(date)
  TO service_role;

REVOKE EXECUTE ON FUNCTION analytics.check_infra_alert()
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION analytics.check_infra_alert()
  TO service_role;

REVOKE EXECUTE ON FUNCTION analytics.send_weekly_report()
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION analytics.send_weekly_report()
  TO service_role;

REVOKE EXECUTE ON FUNCTION public.apply_event(uuid, uuid, uuid, text, integer, jsonb)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.apply_event(uuid, uuid, uuid, text, integer, jsonb)
  TO service_role;

REVOKE EXECUTE ON FUNCTION public.check_party_balance(uuid, uuid)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.check_party_balance(uuid, uuid)
  TO service_role;

REVOKE EXECUTE ON FUNCTION public.fan_out_event(text, jsonb)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.fan_out_event(text, jsonb)
  TO service_role;

REVOKE EXECUTE ON FUNCTION public.fanout_global_event()
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.fanout_global_event()
  TO service_role;

REVOKE EXECUTE ON FUNCTION public.handle_application_rejection()
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.handle_application_rejection()
  TO service_role;

REVOKE EXECUTE ON FUNCTION public.handle_event_reschedule()
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.handle_event_reschedule()
  TO service_role;

REVOKE EXECUTE ON FUNCTION public.handle_new_application_files()
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.handle_new_application_files()
  TO service_role;

REVOKE EXECUTE ON FUNCTION public.handle_new_match_vote()
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.handle_new_match_vote()
  TO service_role;

REVOKE EXECUTE ON FUNCTION public.handle_new_user()
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.handle_new_user()
  TO service_role;

REVOKE EXECUTE ON FUNCTION public.handle_new_user_settings()
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.handle_new_user_settings()
  TO service_role;

REVOKE EXECUTE ON FUNCTION public.handle_partner_application_approved()
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.handle_partner_application_approved()
  TO service_role;

REVOKE EXECUTE ON FUNCTION public.handle_storage_object_created()
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.handle_storage_object_created()
  TO service_role;

REVOKE EXECUTE ON FUNCTION public.handle_verification_approval()
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.handle_verification_approval()
  TO service_role;

REVOKE EXECUTE ON FUNCTION public.issue_ticket_on_approval()
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.issue_ticket_on_approval()
  TO service_role;

REVOKE EXECUTE ON FUNCTION public.process_reconciliation_kill_switch(uuid)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.process_reconciliation_kill_switch(uuid)
  TO service_role;

REVOKE EXECUTE ON FUNCTION public.produce_event()
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.produce_event()
  TO service_role;

REVOKE EXECUTE ON FUNCTION public.produce_event(public.event_type_name, text, uuid, jsonb)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.produce_event(public.event_type_name, text, uuid, jsonb)
  TO service_role;

REVOKE EXECUTE ON FUNCTION public.protect_user_profile_fields()
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.protect_user_profile_fields()
  TO service_role;

REVOKE EXECUTE ON FUNCTION public.remove_participant_on_cancel()
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.remove_participant_on_cancel()
  TO service_role;

REVOKE EXECUTE ON FUNCTION public.replace_match_rules(uuid, jsonb)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.replace_match_rules(uuid, jsonb)
  TO service_role;

REVOKE EXECUTE ON FUNCTION public.send_event_reminders()
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.send_event_reminders()
  TO service_role;

REVOKE EXECUTE ON FUNCTION public.sync_max_participants()
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.sync_max_participants()
  TO service_role;

REVOKE EXECUTE ON FUNCTION public.trigger_produce_event_application()
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.trigger_produce_event_application()
  TO service_role;

REVOKE EXECUTE ON FUNCTION public.trigger_produce_event_events()
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.trigger_produce_event_events()
  TO service_role;

REVOKE EXECUTE ON FUNCTION public.trigger_produce_event_verification()
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.trigger_produce_event_verification()
  TO service_role;

REVOKE EXECUTE ON FUNCTION public.trigger_settlement_notification()
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.trigger_settlement_notification()
  TO service_role;

REVOKE EXECUTE ON FUNCTION public.update_event_participation_stats()
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.update_event_participation_stats()
  TO service_role;

REVOKE EXECUTE ON FUNCTION public.user_event_feed(
  uuid, text, boolean, boolean, double precision, double precision,
  double precision, integer, text, uuid
) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.user_event_feed(
  uuid, text, boolean, boolean, double precision, double precision,
  double precision, integer, text, uuid
) TO service_role;
