BEGIN;

SELECT plan(8);

-- Fix #1954: Verify all SECURITY DEFINER functions have SET search_path
-- to prevent schema injection attacks.
--
-- proconfig stores function-level SET options as text[] in pg_proc.
-- 'search_path=...' is present only when SET search_path is declared.

SELECT ok(
  (SELECT proconfig::text[] @> ARRAY['search_path=analytics, public']
   FROM pg_proc p
   JOIN pg_namespace n ON n.oid = p.pronamespace
   WHERE n.nspname = 'analytics' AND p.proname = 'aggregate_daily_active_users'),
  'aggregate_daily_active_users has SET search_path = analytics, public'
);

SELECT ok(
  (SELECT proconfig::text[] @> ARRAY['search_path=analytics, public']
   FROM pg_proc p
   JOIN pg_namespace n ON n.oid = p.pronamespace
   WHERE n.nspname = 'analytics' AND p.proname = 'aggregate_daily_events'),
  'aggregate_daily_events has SET search_path = analytics, public'
);

SELECT ok(
  (SELECT proconfig::text[] @> ARRAY['search_path=analytics, public']
   FROM pg_proc p
   JOIN pg_namespace n ON n.oid = p.pronamespace
   WHERE n.nspname = 'analytics' AND p.proname = 'aggregate_daily_revenue'),
  'aggregate_daily_revenue has SET search_path = analytics, public'
);

SELECT ok(
  (SELECT proconfig::text[] @> ARRAY['search_path=analytics, public']
   FROM pg_proc p
   JOIN pg_namespace n ON n.oid = p.pronamespace
   WHERE n.nspname = 'analytics' AND p.proname = 'aggregate_funnel_daily'),
  'aggregate_funnel_daily has SET search_path = analytics, public'
);

SELECT ok(
  (SELECT proconfig::text[] @> ARRAY['search_path=analytics, pgmq, public']
   FROM pg_proc p
   JOIN pg_namespace n ON n.oid = p.pronamespace
   WHERE n.nspname = 'analytics' AND p.proname = 'check_infra_alert'),
  'check_infra_alert has SET search_path = analytics, pgmq, public'
);

SELECT ok(
  (SELECT proconfig::text[] @> ARRAY['search_path=analytics, public']
   FROM pg_proc p
   JOIN pg_namespace n ON n.oid = p.pronamespace
   WHERE n.nspname = 'analytics' AND p.proname = 'send_weekly_report'),
  'send_weekly_report has SET search_path = analytics, public'
);

SELECT ok(
  (SELECT proconfig::text[] @> ARRAY['search_path=public']
   FROM pg_proc p
   JOIN pg_namespace n ON n.oid = p.pronamespace
   WHERE n.nspname = 'public' AND p.proname = 'replace_match_rules'),
  'replace_match_rules has SET search_path = public'
);

WITH expected_functions(schema_name, function_name, identity_arguments, expected_search_path) AS (
  VALUES
    ('admin', 'validate_retention_policy_legal_min', '', 'search_path=pg_catalog, admin, public'),
    ('public', 'cast_match_vote', 'p_event_id uuid, p_voter_id uuid, p_candidate_id uuid, p_max_vote_count integer', 'search_path=public'),
    ('public', 'check_party_tags_limit', '', 'search_path=public'),
    ('public', 'check_tag_name_sensitivity', '', 'search_path=public'),
    ('public', 'check_user_interest_tags_limit', '', 'search_path=public'),
    ('public', 'commit_match_likes', 'p_event_id uuid, p_voter_id uuid, p_candidate_ids uuid[], p_max_vote_count integer', 'search_path=public'),
    ('public', 'fn_clear_recurrence_date_on_rule_delete', '', 'search_path=public'),
    ('public', 'get_matched_user_contact', 'target_user_id uuid, target_event_id uuid', 'search_path=public'),
    ('public', 'handle_event_reschedule', '', 'search_path=public'),
    ('public', 'handle_fcm_token_update', '', 'search_path=public'),
    ('public', 'handle_new_application_files', '', 'search_path=public'),
    ('public', 'handle_new_match_vote', '', 'search_path=public'),
    ('public', 'handle_new_user_settings', '', 'search_path=public'),
    ('public', 'handle_new_user', '', 'search_path=public'),
    ('public', 'handle_storage_object_created', '', 'search_path=public'),
    ('public', 'handle_updated_at', '', 'search_path=public'),
    ('public', 'has_partner_permission', 'p_id uuid, p_key text', 'search_path=public'),
    ('public', 'is_super_admin', '', 'search_path=public'),
    ('public', 'normalize_for_filter', 'input text', 'search_path=public'),
    ('public', 'search_events_pgroonga', 'query text', 'search_path=public, extensions'),
    ('public', 'search_parties_pgroonga', 'query text', 'search_path=public, extensions'),
    ('public', 'sync_max_participants', '', 'search_path=public'),
    ('public', 'sync_partner_member_permissions', '', 'search_path=public'),
    ('public', 'update_event_participation_stats', '', 'search_path=public'),
    ('public', 'update_single_settlement_ready_status', 'p_settlement_id uuid', 'search_path=public'),
    ('public', 'update_tag_usage_count', '', 'search_path=public')
),
missing AS (
  SELECT e.schema_name, e.function_name, e.identity_arguments, e.expected_search_path
  FROM expected_functions e
  LEFT JOIN pg_namespace n ON n.nspname = e.schema_name
  LEFT JOIN pg_proc p
    ON p.pronamespace = n.oid
   AND p.proname = e.function_name
   AND pg_get_function_identity_arguments(p.oid) = e.identity_arguments
  WHERE p.oid IS NULL
     OR NOT COALESCE(p.proconfig::text[] @> ARRAY[e.expected_search_path], false)
)
SELECT is(
  (SELECT count(*) FROM missing),
  0::bigint,
  'Issue #2744 function_search_path_mutable targets have pinned search_path'
);

SELECT * FROM finish();
ROLLBACK;
