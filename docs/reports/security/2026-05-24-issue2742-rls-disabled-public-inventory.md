Scheduler: arch-codex-gpt55-high-1

# Issue 2742 RLS Disabled Public Inventory

Source: Supabase Security Advisor dev run in #2687 / #2742.

Decision:
- Drop: 98 residual Metabase application database, Quartz scheduler, Metabase search-index, semantic search, and metabot tables that were created in the exposed `public` schema by an external tool and are not referenced by Minglit runtime code.
- Move/extension exception: `public.spatial_ref_sys`, owned by PostGIS extension catalog data. Do not drop or force RLS in this PR.
- Enable RLS: none in this PR. No listed object is a Minglit-owned runtime table based on repo migration/code search.
- Needs human decision: none for this PR. Reintroducing Metabase must use an isolated app database or non-exposed schema instead of `public`.

| Object | Classification | Rationale |
|---|---|---|
| public.analysis_finding | drop | Metabase residue; not Minglit runtime schema |
| public.analysis_finding_error | drop | Metabase residue; not Minglit runtime schema |
| public.api_key | drop | Metabase residue; not Minglit runtime schema |
| public.application_permissions_revision | drop | Metabase residue; not Minglit runtime schema |
| public.audit_log | drop | Metabase residue; not Minglit runtime schema |
| public.auth_identity | drop | Metabase residue; not Minglit runtime schema |
| public.bookmark_ordering | drop | Metabase residue; not Minglit runtime schema |
| public.cache_config | drop | Metabase residue; not Minglit runtime schema |
| public.card_label | drop | Metabase residue; not Minglit runtime schema |
| public.channel | drop | Metabase residue; not Minglit runtime schema |
| public.channel_template | drop | Metabase residue; not Minglit runtime schema |
| public.cloud_migration | drop | Metabase residue; not Minglit runtime schema |
| public.collection_permission_graph_revision | drop | Metabase residue; not Minglit runtime schema |
| public.comment | drop | Metabase residue; not Minglit runtime schema |
| public.comment_reaction | drop | Metabase residue; not Minglit runtime schema |
| public.connection_impersonations | drop | Metabase residue; not Minglit runtime schema |
| public.content_translation | drop | Metabase residue; not Minglit runtime schema |
| public.dashboard_favorite | drop | Metabase residue; not Minglit runtime schema |
| public.dashboard_tab | drop | Metabase residue; not Minglit runtime schema |
| public.dashboardcard_series | drop | Metabase residue; not Minglit runtime schema |
| public.data_edit_undo_chain | drop | Metabase residue; not Minglit runtime schema |
| public.db_router | drop | Metabase residue; not Minglit runtime schema |
| public.dependency | drop | Metabase residue; not Minglit runtime schema |
| public.document | drop | Metabase residue; not Minglit runtime schema |
| public.document_bookmark | drop | Metabase residue; not Minglit runtime schema |
| public.glossary | drop | Metabase residue; not Minglit runtime schema |
| public.http_action | drop | Metabase residue; not Minglit runtime schema |
| public.implicit_action | drop | Metabase residue; not Minglit runtime schema |
| public.label | drop | Metabase residue; not Minglit runtime schema |
| public.measure | drop | Metabase residue; not Minglit runtime schema |
| public.metabot | drop | Metabase residue; not Minglit runtime schema |
| public.metabot_conversation | drop | Metabase residue; not Minglit runtime schema |
| public.metabot_message | drop | Metabase residue; not Minglit runtime schema |
| public.metabot_prompt | drop | Metabase residue; not Minglit runtime schema |
| public.metric_important_field | drop | Metabase residue; not Minglit runtime schema |
| public.moderation_review | drop | Metabase residue; not Minglit runtime schema |
| public.notification | drop | Metabase residue; not Minglit runtime schema |
| public.notification_card | drop | Metabase residue; not Minglit runtime schema |
| public.notification_handler | drop | Metabase residue; not Minglit runtime schema |
| public.notification_recipient | drop | Metabase residue; not Minglit runtime schema |
| public.notification_subscription | drop | Metabase residue; not Minglit runtime schema |
| public.parameter_card | drop | Metabase residue; not Minglit runtime schema |
| public.persisted_info | drop | Metabase residue; not Minglit runtime schema |
| public.premium_features_token_cache | drop | Metabase residue; not Minglit runtime schema |
| public.python_library | drop | Metabase residue; not Minglit runtime schema |
| public.qrtz_blob_triggers | drop | Quartz scheduler residue from Metabase app DB |
| public.qrtz_calendars | drop | Quartz scheduler residue from Metabase app DB |
| public.qrtz_cron_triggers | drop | Quartz scheduler residue from Metabase app DB |
| public.qrtz_fired_triggers | drop | Quartz scheduler residue from Metabase app DB |
| public.qrtz_job_details | drop | Quartz scheduler residue from Metabase app DB |
| public.qrtz_locks | drop | Quartz scheduler residue from Metabase app DB |
| public.qrtz_paused_trigger_grps | drop | Quartz scheduler residue from Metabase app DB |
| public.qrtz_scheduler_state | drop | Quartz scheduler residue from Metabase app DB |
| public.qrtz_simple_triggers | drop | Quartz scheduler residue from Metabase app DB |
| public.qrtz_simprop_triggers | drop | Quartz scheduler residue from Metabase app DB |
| public.qrtz_triggers | drop | Quartz scheduler residue from Metabase app DB |
| public.query_action | drop | Metabase residue; not Minglit runtime schema |
| public.query_field | drop | Metabase residue; not Minglit runtime schema |
| public.query_table | drop | Metabase residue; not Minglit runtime schema |
| public.recent_views | drop | Metabase residue; not Minglit runtime schema |
| public.remote_sync_object | drop | Metabase residue; not Minglit runtime schema |
| public.remote_sync_task | drop | Metabase residue; not Minglit runtime schema |
| public.report_card | drop | Metabase residue; not Minglit runtime schema |
| public.report_cardfavorite | drop | Metabase residue; not Minglit runtime schema |
| public.report_dashboard | drop | Metabase residue; not Minglit runtime schema |
| public.report_dashboardcard | drop | Metabase residue; not Minglit runtime schema |
| public.sandboxes | drop | Metabase residue; not Minglit runtime schema |
| public.search_index__gubiadnhjt7zp2k0fwrbv | drop | Metabase generated search-index residue |
| public.search_index__ls1noau6qfwura1z_qy1t | drop | Metabase generated search-index residue |
| public.search_index__nnshf9k_gbbhi428mytzr | drop | Metabase generated search-index residue |
| public.search_index__s6pfttuvbpxatcpbikdjz | drop | Metabase generated search-index residue |
| public.search_index_metadata | drop | Metabase search-index residue |
| public.secret | drop | Metabase residue; not Minglit runtime schema |
| public.semantic_search_token_tracking | drop | Metabase semantic search residue |
| public.sequences | drop | Metabase residue; not Minglit runtime schema |
| public.spatial_ref_sys | move/extension_exception | PostGIS extension catalog table |
| public.support_access_grant_log | drop | Metabase residue; not Minglit runtime schema |
| public.table_privileges | drop | Metabase residue; not Minglit runtime schema |
| public.task_run | drop | Metabase residue; not Minglit runtime schema |
| public.tenant | drop | Metabase residue; not Minglit runtime schema |
| public.transform | drop | Metabase transform residue |
| public.transform_job | drop | Metabase transform residue |
| public.transform_job_run | drop | Metabase transform residue |
| public.transform_job_transform_tag | drop | Metabase transform residue |
| public.transform_run | drop | Metabase transform residue |
| public.transform_run_cancelation | drop | Metabase transform residue |
| public.transform_tag | drop | Metabase transform residue |
| public.transform_transform_tag | drop | Metabase transform residue |
| public.user_key_value | drop | Metabase residue; not Minglit runtime schema |
| public.workspace | drop | Metabase workspace residue |
| public.workspace_graph | drop | Metabase workspace residue |
| public.workspace_input | drop | Metabase workspace residue |
| public.workspace_input_external | drop | Metabase workspace residue |
| public.workspace_log | drop | Metabase workspace residue |
| public.workspace_merge | drop | Metabase workspace residue |
| public.workspace_merge_transform | drop | Metabase workspace residue |
| public.workspace_output | drop | Metabase workspace residue |
| public.workspace_output_external | drop | Metabase workspace residue |
| public.workspace_transform | drop | Metabase workspace residue |

Regression:
- `supabase/tests/database/101_public_rls_disabled_inventory_test.sql` asserts the known residual table list is absent.
- The same test asserts no `public` regular/partitioned table remains with RLS disabled except `spatial_ref_sys`.
