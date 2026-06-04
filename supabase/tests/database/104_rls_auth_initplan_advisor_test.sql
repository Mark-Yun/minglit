-- Issue #2797: Supabase Performance Advisor auth_rls_initplan regression.
-- The affected policies should use scalar subqueries around auth helpers.
BEGIN;

SELECT plan(2);

CREATE TEMP TABLE expected_auth_initplan_policies (
  schemaname text NOT NULL,
  tablename text NOT NULL,
  policyname text NOT NULL
) ON COMMIT DROP;

INSERT INTO expected_auth_initplan_policies
  (schemaname, tablename, policyname)
VALUES
  ('public', 'archived_records', 'service_role_only'),
  ('public', 'blocked_dis', 'service_role_only'),
  ('public', 'business_calendar', 'business_calendar_write_service_role'),
  ('public', 'dead_letter_queue', 'service_role_only'),
  ('public', 'debug_logs', 'service_role_all'),
  ('public', 'event_applications', 'Users can read own applications'),
  ('public', 'event_change_logs', 'partner_read_own_event_change_logs'),
  ('public', 'event_participants', 'Authenticated users can read visible participants'),
  ('public', 'event_routes', 'service_role_only'),
  ('public', 'fcm_tokens', 'Users can view their own FCM tokens'),
  ('public', 'file_access_grants', 'Viewers can see their grants'),
  ('public', 'location_access_log', 'users read own logs'),
  ('public', 'match_pairs', 'Users can see own matches'),
  ('public', 'match_votes', 'Users can read own votes'),
  ('public', 'minglit_files', 'Users can view own files'),
  ('public', 'partner_applications', 'Users can read own applications'),
  ('public', 'partner_member_permissions', 'Users can read own permissions'),
  ('public', 'partner_verified_users', 'Users can read own verified status'),
  ('public', 'party_tags', 'party_tags_service'),
  ('public', 'policies', 'authenticated_read_policies'),
  ('public', 'policies', 'service_role_all_policies'),
  ('public', 'processed_events', 'service_role_only'),
  ('public', 'reconciliation_results', 'reconciliation_results_service_role_only'),
  ('public', 'reconciliation_runs', 'reconciliation_runs_service_role_only'),
  ('public', 'report_details', 'Users can view own reports'),
  ('public', 'settlement_alarm_results', 'settlement_alarm_results_service_role_only'),
  ('public', 'social_interactions', 'Users can view own interactions'),
  ('public', 'system_settings', 'system_settings_service_role_only'),
  ('public', 'tag_usage_daily', 'tag_usage_daily_service'),
  ('public', 'tag_usage_monthly', 'tag_usage_monthly_service'),
  ('public', 'user_consents', 'user_read_own_consents'),
  ('public', 'user_interest_tags', 'user_interest_tags_read_own'),
  ('public', 'user_notifications', 'Users can view their own notifications'),
  ('public', 'user_profiles', 'Users can read own profile'),
  ('public', 'user_settings', 'Users can view their own settings'),
  ('public', 'user_verifications', 'Users can read own verifications'),
  ('public', 'verification_submissions', 'Users can read own submissions'),
  ('public', 'withdrawal_reasons', 'service_role_only');

SELECT is_empty(
  $$
    SELECT e.*
    FROM expected_auth_initplan_policies e
    LEFT JOIN pg_policies p
      ON p.schemaname = e.schemaname
     AND p.tablename = e.tablename
     AND p.policyname = e.policyname
    WHERE p.policyname IS NULL
  $$,
  'all auth_rls_initplan advisor policies still exist'
);

SELECT is_empty(
  $$
    WITH expressions AS (
      SELECT
        p.schemaname,
        p.tablename,
        p.policyname,
        lower(coalesce(p.qual, '') || ' ' || coalesce(p.with_check, '')) AS expr
      FROM pg_policies p
      JOIN expected_auth_initplan_policies e
        ON e.schemaname = p.schemaname
       AND e.tablename = p.tablename
       AND e.policyname = p.policyname
    )
    SELECT schemaname, tablename, policyname, expr
    FROM expressions
    WHERE expr ~ 'auth\.uid\(\)\s*(=|is)'
       OR expr ~ '=\s*auth\.uid\(\)'
       OR expr ~ 'auth\.role\(\)\s*='
       OR expr ~ 'current_setting\([^)]*\)\s*='
  $$,
  'affected policies do not contain unwrapped auth helper calls'
);

SELECT * FROM finish();
ROLLBACK;
