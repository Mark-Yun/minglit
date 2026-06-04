BEGIN;

SELECT plan(5);

SELECT is_empty(
  $$
  WITH target(function_oid) AS (
    VALUES
      ('public.get_bulk_eligibility_data(uuid)'::regprocedure),
      ('public.get_personalized_recommendations(uuid, integer)'::regprocedure),
      ('public.get_matched_user_contact(uuid, uuid)'::regprocedure),
      ('public.get_matched_user_info(uuid, uuid)'::regprocedure),
      ('public.get_event_applications_with_user(uuid)'::regprocedure),
      ('public.get_partner_members_with_user(uuid)'::regprocedure),
      ('public.get_pending_verification_requests_with_user(uuid)'::regprocedure),
      ('public.get_event_checkin_stats(uuid)'::regprocedure),
      ('public.get_event_checkin_stats_by_group(uuid)'::regprocedure),
      ('public.get_event_participants_for_checkin(uuid)'::regprocedure),
      ('public.get_ticket_public_key()'::regprocedure)
  )
  SELECT function_oid::regprocedure::text
  FROM target
  WHERE has_function_privilege('anon', function_oid, 'EXECUTE')
  ORDER BY 1
  $$,
  'anon cannot EXECUTE authenticated-only SECURITY DEFINER RPCs'
);

SELECT is_empty(
  $$
  WITH target(function_oid) AS (
    VALUES
      ('public.get_bulk_eligibility_data(uuid)'::regprocedure),
      ('public.get_personalized_recommendations(uuid, integer)'::regprocedure),
      ('public.get_matched_user_contact(uuid, uuid)'::regprocedure),
      ('public.get_matched_user_info(uuid, uuid)'::regprocedure),
      ('public.get_event_applications_with_user(uuid)'::regprocedure),
      ('public.get_partner_members_with_user(uuid)'::regprocedure),
      ('public.get_pending_verification_requests_with_user(uuid)'::regprocedure),
      ('public.get_event_checkin_stats(uuid)'::regprocedure),
      ('public.get_event_checkin_stats_by_group(uuid)'::regprocedure),
      ('public.get_event_participants_for_checkin(uuid)'::regprocedure),
      ('public.get_ticket_public_key()'::regprocedure)
  )
  SELECT function_oid::regprocedure::text
  FROM target
  WHERE NOT has_function_privilege('authenticated', function_oid, 'EXECUTE')
     OR NOT has_function_privilege('service_role', function_oid, 'EXECUTE')
  ORDER BY 1
  $$,
  'authenticated-only SECURITY DEFINER RPCs remain callable by authenticated and service_role'
);

SELECT is_empty(
  $$
  WITH target(function_oid) AS (
    VALUES
      ('admin.log_retention_policy_change()'::regprocedure),
      ('analytics.aggregate_daily_active_users(date)'::regprocedure),
      ('analytics.aggregate_daily_events(date)'::regprocedure),
      ('analytics.aggregate_daily_revenue(date)'::regprocedure),
      ('analytics.aggregate_funnel_daily(date)'::regprocedure),
      ('analytics.check_infra_alert()'::regprocedure),
      ('analytics.send_weekly_report()'::regprocedure),
      ('public.apply_event(uuid, uuid, uuid, text, integer, jsonb)'::regprocedure),
      ('public.check_party_balance(uuid, uuid)'::regprocedure),
      ('public.fan_out_event(text, jsonb)'::regprocedure),
      ('public.fanout_global_event()'::regprocedure),
      ('public.handle_application_rejection()'::regprocedure),
      ('public.handle_event_reschedule()'::regprocedure),
      ('public.handle_new_application_files()'::regprocedure),
      ('public.handle_new_match_vote()'::regprocedure),
      ('public.handle_new_user()'::regprocedure),
      ('public.handle_new_user_settings()'::regprocedure),
      ('public.handle_partner_application_approved()'::regprocedure),
      ('public.handle_storage_object_created()'::regprocedure),
      ('public.handle_verification_approval()'::regprocedure),
      ('public.issue_ticket_on_approval()'::regprocedure),
      ('public.process_manual_checkin(uuid, uuid)'::regprocedure),
      ('public.process_qr_checkin(uuid, uuid, uuid)'::regprocedure),
      ('public.process_reconciliation_kill_switch(uuid)'::regprocedure),
      ('public.produce_event()'::regprocedure),
      ('public.produce_event(public.event_type_name, text, uuid, jsonb)'::regprocedure),
      ('public.protect_user_profile_fields()'::regprocedure),
      ('public.request_retry_payout(uuid, uuid)'::regprocedure),
      ('public.remove_participant_on_cancel()'::regprocedure),
      ('public.replace_match_rules(uuid, jsonb)'::regprocedure),
      ('public.save_user_consents(uuid, jsonb)'::regprocedure),
      ('public.send_event_reminders()'::regprocedure),
      ('public.set_social_interaction(text, text, text, boolean)'::regprocedure),
      ('public.sync_max_participants()'::regprocedure),
      ('public.trigger_produce_event_application()'::regprocedure),
      ('public.trigger_produce_event_events()'::regprocedure),
      ('public.trigger_produce_event_verification()'::regprocedure),
      ('public.trigger_settlement_notification()'::regprocedure),
      ('public.update_event_participation_stats()'::regprocedure),
      ('public.upsert_user_settings_with_consent(uuid, boolean, boolean)'::regprocedure),
      ('public.user_event_feed(uuid, text, boolean, boolean, double precision, double precision, double precision, integer, text, uuid)'::regprocedure)
  )
  SELECT function_oid::regprocedure::text
  FROM target
  WHERE has_function_privilege('anon', function_oid, 'EXECUTE')
     OR has_function_privilege('authenticated', function_oid, 'EXECUTE')
  ORDER BY 1
  $$,
  'publishable roles cannot EXECUTE EF/cron/trigger-only SECURITY DEFINER functions'
);

SELECT is_empty(
  $$
  WITH target(function_oid) AS (
    VALUES
      ('admin.log_retention_policy_change()'::regprocedure),
      ('analytics.aggregate_daily_active_users(date)'::regprocedure),
      ('analytics.aggregate_daily_events(date)'::regprocedure),
      ('analytics.aggregate_daily_revenue(date)'::regprocedure),
      ('analytics.aggregate_funnel_daily(date)'::regprocedure),
      ('analytics.check_infra_alert()'::regprocedure),
      ('analytics.send_weekly_report()'::regprocedure),
      ('public.apply_event(uuid, uuid, uuid, text, integer, jsonb)'::regprocedure),
      ('public.check_party_balance(uuid, uuid)'::regprocedure),
      ('public.fan_out_event(text, jsonb)'::regprocedure),
      ('public.fanout_global_event()'::regprocedure),
      ('public.handle_application_rejection()'::regprocedure),
      ('public.handle_event_reschedule()'::regprocedure),
      ('public.handle_new_application_files()'::regprocedure),
      ('public.handle_new_match_vote()'::regprocedure),
      ('public.handle_new_user()'::regprocedure),
      ('public.handle_new_user_settings()'::regprocedure),
      ('public.handle_partner_application_approved()'::regprocedure),
      ('public.handle_storage_object_created()'::regprocedure),
      ('public.handle_verification_approval()'::regprocedure),
      ('public.issue_ticket_on_approval()'::regprocedure),
      ('public.process_manual_checkin(uuid, uuid)'::regprocedure),
      ('public.process_qr_checkin(uuid, uuid, uuid)'::regprocedure),
      ('public.process_reconciliation_kill_switch(uuid)'::regprocedure),
      ('public.produce_event()'::regprocedure),
      ('public.produce_event(public.event_type_name, text, uuid, jsonb)'::regprocedure),
      ('public.protect_user_profile_fields()'::regprocedure),
      ('public.request_retry_payout(uuid, uuid)'::regprocedure),
      ('public.remove_participant_on_cancel()'::regprocedure),
      ('public.replace_match_rules(uuid, jsonb)'::regprocedure),
      ('public.save_user_consents(uuid, jsonb)'::regprocedure),
      ('public.send_event_reminders()'::regprocedure),
      ('public.set_social_interaction(text, text, text, boolean)'::regprocedure),
      ('public.sync_max_participants()'::regprocedure),
      ('public.trigger_produce_event_application()'::regprocedure),
      ('public.trigger_produce_event_events()'::regprocedure),
      ('public.trigger_produce_event_verification()'::regprocedure),
      ('public.trigger_settlement_notification()'::regprocedure),
      ('public.update_event_participation_stats()'::regprocedure),
      ('public.upsert_user_settings_with_consent(uuid, boolean, boolean)'::regprocedure),
      ('public.user_event_feed(uuid, text, boolean, boolean, double precision, double precision, double precision, integer, text, uuid)'::regprocedure)
  )
  SELECT function_oid::regprocedure::text
  FROM target
  WHERE NOT has_function_privilege('service_role', function_oid, 'EXECUTE')
  ORDER BY 1
  $$,
  'service_role can EXECUTE EF/cron/trigger-only SECURITY DEFINER functions'
);

SELECT is_empty(
  $$
  SELECT n.nspname || '.' || p.proname || '(' ||
         pg_get_function_identity_arguments(p.oid) || ')' AS function_signature
  FROM pg_proc p
  JOIN pg_namespace n ON n.oid = p.pronamespace
  WHERE p.prosecdef
    AND n.nspname IN ('public', 'analytics', 'admin')
    AND p.proconfig IS NULL
    AND NOT EXISTS (
      SELECT 1
      FROM pg_depend d
      JOIN pg_extension e ON e.oid = d.refobjid
      WHERE d.objid = p.oid
    )
  ORDER BY function_signature
  $$,
  'Minglit-owned SECURITY DEFINER functions have pinned search_path'
);

SELECT * FROM finish();

ROLLBACK;
