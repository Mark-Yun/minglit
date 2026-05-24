BEGIN;

SELECT plan(2);

WITH known_residual_tables(table_name) AS (
  VALUES
    ('moderation_review'),
    ('qrtz_calendars'),
    ('qrtz_fired_triggers'),
    ('qrtz_locks'),
    ('qrtz_paused_trigger_grps'),
    ('qrtz_scheduler_state'),
    ('search_index__gubiadnhjt7zp2k0fwrbv'),
    ('bookmark_ordering'),
    ('card_label'),
    ('label'),
    ('report_cardfavorite'),
    ('collection_permission_graph_revision'),
    ('dashboard_favorite'),
    ('dashboardcard_series'),
    ('report_dashboard'),
    ('report_dashboardcard'),
    ('application_permissions_revision'),
    ('metric_important_field'),
    ('persisted_info'),
    ('qrtz_triggers'),
    ('qrtz_blob_triggers'),
    ('qrtz_cron_triggers'),
    ('qrtz_simple_triggers'),
    ('qrtz_simprop_triggers'),
    ('qrtz_job_details'),
    ('secret'),
    ('sandboxes'),
    ('report_card'),
    ('http_action'),
    ('search_index__s6pfttuvbpxatcpbikdjz'),
    ('implicit_action'),
    ('parameter_card'),
    ('dashboard_tab'),
    ('query_action'),
    ('connection_impersonations'),
    ('table_privileges'),
    ('audit_log'),
    ('recent_views'),
    ('api_key'),
    ('channel'),
    ('cloud_migration'),
    ('cache_config'),
    ('query_table'),
    ('query_field'),
    ('notification'),
    ('notification_handler'),
    ('notification_recipient'),
    ('channel_template'),
    ('notification_subscription'),
    ('search_index_metadata'),
    ('user_key_value'),
    ('notification_card'),
    ('db_router'),
    ('metabot'),
    ('content_translation'),
    ('metabot_prompt'),
    ('metabot_conversation'),
    ('metabot_message'),
    ('semantic_search_token_tracking'),
    ('data_edit_undo_chain'),
    ('sequences'),
    ('document_bookmark'),
    ('document'),
    ('transform_run_cancelation'),
    ('transform_tag'),
    ('transform_transform_tag'),
    ('transform_job_transform_tag'),
    ('transform_job_run'),
    ('transform_job'),
    ('comment_reaction'),
    ('dependency'),
    ('python_library'),
    ('comment'),
    ('support_access_grant_log'),
    ('glossary'),
    ('auth_identity'),
    ('remote_sync_task'),
    ('tenant'),
    ('measure'),
    ('remote_sync_object'),
    ('analysis_finding_error'),
    ('analysis_finding'),
    ('transform'),
    ('task_run'),
    ('workspace'),
    ('workspace_log'),
    ('workspace_transform'),
    ('workspace_input'),
    ('workspace_merge_transform'),
    ('workspace_output'),
    ('workspace_merge'),
    ('workspace_output_external'),
    ('workspace_input_external'),
    ('workspace_graph'),
    ('premium_features_token_cache'),
    ('transform_run'),
    ('search_index__nnshf9k_gbbhi428mytzr'),
    ('search_index__ls1noau6qfwura1z_qy1t')
)
SELECT is(
  (
    SELECT count(*)::int
    FROM known_residual_tables r
    WHERE to_regclass(format('public.%I', r.table_name)) IS NOT NULL
  ),
  0,
  'known Metabase/Quartz/search-index residual tables are absent from public schema'
);

SELECT is(
  (
    SELECT count(*)::int
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public'
      AND c.relkind IN ('r', 'p')
      AND NOT c.relrowsecurity
      AND c.relname <> 'spatial_ref_sys'
  ),
  0,
  'no unexpected public regular table remains with RLS disabled except spatial_ref_sys'
);

SELECT * FROM finish();
ROLLBACK;
