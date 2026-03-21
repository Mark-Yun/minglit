-- Post-deploy verification: check critical DB objects exist
-- Usage: supabase db execute --project-ref $REF --password $PW --sql "$(cat scripts/verify-db-objects.sql)"

DO $$
DECLARE
  missing text[] := '{}';
BEGIN
  -- ==============================
  -- 1. Critical tables (public)
  -- ==============================

  -- Core
  IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='user_profiles') THEN
    missing := missing || 'table:user_profiles';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='user_embeddings') THEN
    missing := missing || 'table:user_embeddings';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='app_roles') THEN
    missing := missing || 'table:app_roles';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='user_actions') THEN
    missing := missing || 'table:user_actions';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='partners') THEN
    missing := missing || 'table:partners';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='partner_settlements') THEN
    missing := missing || 'table:partner_settlements';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='partner_member_permissions') THEN
    missing := missing || 'table:partner_member_permissions';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='partner_applications') THEN
    missing := missing || 'table:partner_applications';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='locations') THEN
    missing := missing || 'table:locations';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='verifications') THEN
    missing := missing || 'table:verifications';
  END IF;

  -- Events
  IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='parties') THEN
    missing := missing || 'table:parties';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='party_embeddings') THEN
    missing := missing || 'table:party_embeddings';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='events') THEN
    missing := missing || 'table:events';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='entry_group_templates') THEN
    missing := missing || 'table:entry_group_templates';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='entry_groups') THEN
    missing := missing || 'table:entry_groups';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='ticket_templates') THEN
    missing := missing || 'table:ticket_templates';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='tickets') THEN
    missing := missing || 'table:tickets';
  END IF;

  -- Commerce
  IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='event_applications') THEN
    missing := missing || 'table:event_applications';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='verification_submissions') THEN
    missing := missing || 'table:verification_submissions';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='user_verifications') THEN
    missing := missing || 'table:user_verifications';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='partner_verified_users') THEN
    missing := missing || 'table:partner_verified_users';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='event_participants') THEN
    missing := missing || 'table:event_participants';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='verification_comments') THEN
    missing := missing || 'table:verification_comments';
  END IF;

  -- System
  IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='user_notifications') THEN
    missing := missing || 'table:user_notifications';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='fcm_tokens') THEN
    missing := missing || 'table:fcm_tokens';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='user_settings') THEN
    missing := missing || 'table:user_settings';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='social_interactions') THEN
    missing := missing || 'table:social_interactions';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='match_rules') THEN
    missing := missing || 'table:match_rules';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='match_votes') THEN
    missing := missing || 'table:match_votes';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='match_pairs') THEN
    missing := missing || 'table:match_pairs';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='minglit_files') THEN
    missing := missing || 'table:minglit_files';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='file_access_grants') THEN
    missing := missing || 'table:file_access_grants';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='settlements') THEN
    missing := missing || 'table:settlements';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='processed_events') THEN
    missing := missing || 'table:processed_events';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='dead_letter_queue') THEN
    missing := missing || 'table:dead_letter_queue';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='event_routes') THEN
    missing := missing || 'table:event_routes';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='report_details') THEN
    missing := missing || 'table:report_details';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='policies') THEN
    missing := missing || 'table:policies';
  END IF;

  -- ==============================
  -- 2. Cron jobs
  -- ==============================
  IF NOT EXISTS (SELECT 1 FROM cron.job WHERE jobname='process-notifications') THEN
    missing := missing || 'cron:process-notifications';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM cron.job WHERE jobname='backend-simulation') THEN
    missing := missing || 'cron:backend-simulation';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM cron.job WHERE jobname='send-event-reminders') THEN
    missing := missing || 'cron:send-event-reminders';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM cron.job WHERE jobname='settlement-status-transition') THEN
    missing := missing || 'cron:settlement-status-transition';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM cron.job WHERE jobname='settlement-stuck-processing-check') THEN
    missing := missing || 'cron:settlement-stuck-processing-check';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM cron.job WHERE jobname='settlement-register-transfers') THEN
    missing := missing || 'cron:settlement-register-transfers';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM cron.job WHERE jobname='settlement-payout-sync') THEN
    missing := missing || 'cron:settlement-payout-sync';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM cron.job WHERE jobname='settlement-payout-assembly') THEN
    missing := missing || 'cron:settlement-payout-assembly';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM cron.job WHERE jobname='settlement-retry-failed') THEN
    missing := missing || 'cron:settlement-retry-failed';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM cron.job WHERE jobname='settlement-reconciliation-daily') THEN
    missing := missing || 'cron:settlement-reconciliation-daily';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM cron.job WHERE jobname='settlement-alarm-check') THEN
    missing := missing || 'cron:settlement-alarm-check';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM cron.job WHERE jobname='delete-old-bug-report-attachments') THEN
    missing := missing || 'cron:delete-old-bug-report-attachments';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM cron.job WHERE jobname='aggregate_daily_active_users') THEN
    missing := missing || 'cron:aggregate_daily_active_users';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM cron.job WHERE jobname='aggregate_daily_events') THEN
    missing := missing || 'cron:aggregate_daily_events';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM cron.job WHERE jobname='aggregate_daily_revenue') THEN
    missing := missing || 'cron:aggregate_daily_revenue';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM cron.job WHERE jobname='aggregate_funnel_daily') THEN
    missing := missing || 'cron:aggregate_funnel_daily';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM cron.job WHERE jobname='check_performance_alert') THEN
    missing := missing || 'cron:check_performance_alert';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM cron.job WHERE jobname='check_business_alert') THEN
    missing := missing || 'cron:check_business_alert';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM cron.job WHERE jobname='send_daily_report') THEN
    missing := missing || 'cron:send_daily_report';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM cron.job WHERE jobname='check_infra_alert') THEN
    missing := missing || 'cron:check_infra_alert';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM cron.job WHERE jobname='send_weekly_report') THEN
    missing := missing || 'cron:send_weekly_report';
  END IF;

  -- ==============================
  -- 3. Result
  -- ==============================
  IF array_length(missing, 1) > 0 THEN
    RAISE EXCEPTION 'Missing DB objects: %', array_to_string(missing, ', ');
  ELSE
    RAISE NOTICE 'All critical DB objects verified ✅';
  END IF;
END $$;
